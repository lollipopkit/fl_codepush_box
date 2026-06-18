package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/smithy-go"
)

type Storage interface {
	Put(ctx context.Context, key string, body io.Reader, size int64) error
	Get(ctx context.Context, key string) (io.ReadCloser, int64, error)
	SignedURL(ctx context.Context, key string, ttl time.Duration) (string, error)
	Delete(ctx context.Context, key string) error
}

type LocalFSStorage struct {
	root string
}

type S3StorageConfig struct {
	Bucket          string
	Region          string
	Endpoint        string
	AccessKeyID     string
	SecretAccessKey string
}

type S3Storage struct {
	bucket  string
	client  *s3.Client
	presign *s3.PresignClient
}

func NewLocalFSStorage(root string) (*LocalFSStorage, error) {
	if err := os.MkdirAll(root, 0o755); err != nil {
		return nil, err
	}
	return &LocalFSStorage{root: root}, nil
}

func (s *LocalFSStorage) Put(_ context.Context, key string, body io.Reader, _ int64) error {
	path, err := s.objectPath(key)
	if err != nil {
		return err
	}
	data, err := io.ReadAll(body)
	if err != nil {
		return err
	}
	return writeFileAtomic(path, data)
}

func (s *LocalFSStorage) Get(_ context.Context, key string) (io.ReadCloser, int64, error) {
	path, err := s.objectPath(key)
	if err != nil {
		return nil, 0, err
	}
	file, err := os.Open(path)
	if err != nil {
		return nil, 0, err
	}
	stat, err := file.Stat()
	if err != nil {
		_ = file.Close()
		return nil, 0, err
	}
	return file, stat.Size(), nil
}

func (s *LocalFSStorage) SignedURL(_ context.Context, key string, _ time.Duration) (string, error) {
	if err := validateObjectKey(key); err != nil {
		return "", err
	}
	q := url.Values{}
	q.Set("key", key)
	return "/v1/patches/payload?" + q.Encode(), nil
}

func (s *LocalFSStorage) Delete(_ context.Context, key string) error {
	path, err := s.objectPath(key)
	if err != nil {
		return err
	}
	return os.Remove(path)
}

func (s *LocalFSStorage) objectPath(key string) (string, error) {
	if err := validateObjectKey(key); err != nil {
		return "", err
	}
	return filepath.Join(s.root, key), nil
}

func validateObjectKey(key string) error {
	clean := filepath.Clean(key)
	if clean == "." || filepath.IsAbs(clean) || clean != key || clean == ".." || strings.HasPrefix(clean, "../") {
		return fmt.Errorf("invalid object key")
	}
	return nil
}

func isObjectNotExist(err error) bool {
	if errors.Is(err, os.ErrNotExist) {
		return true
	}
	var apiError smithy.APIError
	if errors.As(err, &apiError) {
		return apiError.ErrorCode() == "NoSuchKey" || apiError.ErrorCode() == "NotFound"
	}
	return false
}

func NewS3Storage(ctx context.Context, s3Config S3StorageConfig) (*S3Storage, error) {
	if s3Config.Bucket == "" {
		return nil, fmt.Errorf("FCB_S3_BUCKET is required for s3 storage")
	}
	if s3Config.Region == "" {
		s3Config.Region = "us-east-1"
	}
	loadOptions := []func(*config.LoadOptions) error{
		config.WithRegion(s3Config.Region),
	}
	if s3Config.AccessKeyID != "" || s3Config.SecretAccessKey != "" {
		if s3Config.AccessKeyID == "" || s3Config.SecretAccessKey == "" {
			return nil, fmt.Errorf("FCB_S3_ACCESS_KEY_ID and FCB_S3_SECRET_ACCESS_KEY must be set together")
		}
		loadOptions = append(loadOptions, config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(
			s3Config.AccessKeyID,
			s3Config.SecretAccessKey,
			"",
		)))
	}
	awsConfig, err := config.LoadDefaultConfig(ctx, loadOptions...)
	if err != nil {
		return nil, err
	}
	client := s3.NewFromConfig(awsConfig, func(options *s3.Options) {
		if s3Config.Endpoint != "" {
			options.BaseEndpoint = aws.String(s3Config.Endpoint)
			options.UsePathStyle = true
		}
	})
	return &S3Storage{
		bucket:  s3Config.Bucket,
		client:  client,
		presign: s3.NewPresignClient(client),
	}, nil
}

func (s *S3Storage) Put(ctx context.Context, key string, body io.Reader, size int64) error {
	if err := validateObjectKey(key); err != nil {
		return err
	}
	_, err := s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:        aws.String(s.bucket),
		Key:           aws.String(key),
		Body:          body,
		ContentLength: aws.Int64(size),
	})
	return err
}

func (s *S3Storage) Get(ctx context.Context, key string) (io.ReadCloser, int64, error) {
	if err := validateObjectKey(key); err != nil {
		return nil, 0, err
	}
	output, err := s.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return nil, 0, err
	}
	size := int64(-1)
	if output.ContentLength != nil {
		size = *output.ContentLength
	}
	return output.Body, size, nil
}

func (s *S3Storage) SignedURL(ctx context.Context, key string, ttl time.Duration) (string, error) {
	if err := validateObjectKey(key); err != nil {
		return "", err
	}
	if ttl <= 0 {
		ttl = 15 * time.Minute
	}
	result, err := s.presign.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	}, func(options *s3.PresignOptions) {
		options.Expires = ttl
	})
	if err != nil {
		return "", err
	}
	return result.URL, nil
}

func (s *S3Storage) Delete(ctx context.Context, key string) error {
	if err := validateObjectKey(key); err != nil {
		return err
	}
	_, err := s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	})
	return err
}
