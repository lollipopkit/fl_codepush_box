package main

import "time"

type Organization struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"created_at,omitempty"`
}

type OrgMember struct {
	OrgID     string    `json:"org_id"`
	UserID    int64     `json:"user_id"`
	Username  string    `json:"username,omitempty"`
	Role      string    `json:"role"`
	CreatedAt time.Time `json:"created_at,omitempty"`
}

type OrgMemberRequest struct {
	Username string `json:"username"`
	UserID   int64  `json:"user_id"`
	Role     string `json:"role"`
}

type OrgMemberUpdateRequest struct {
	Role string `json:"role"`
}

type App struct {
	ID        string        `json:"id"`
	OrgID     string        `json:"org_id,omitempty"`
	Name      string        `json:"name"`
	Channel   string        `json:"channel"`
	PublicKey string        `json:"public_key"`
	Platforms []AppPlatform `json:"platforms,omitempty"`
	CreatedAt time.Time     `json:"created_at,omitempty"`
	UpdatedAt time.Time     `json:"updated_at,omitempty"`
}

type AppPlatform struct {
	Platform string   `json:"platform"`
	Enabled  bool     `json:"enabled"`
	Backend  string   `json:"backend"`
	ABI      []string `json:"abi"`
}

type ReleaseManifest struct {
	SchemaVersion  int    `json:"schema_version"`
	AppID          string `json:"app_id"`
	ReleaseVersion string `json:"release_version"`
	Channel        string `json:"channel"`
	Platform       string `json:"platform"`
	Arch           string `json:"arch"`
	Backend        string `json:"backend"`
	ArtifactHash   string `json:"artifact_hash"`
	ArtifactSize   uint64 `json:"artifact_size"`
}

type PatchManifest struct {
	SchemaVersion  int             `json:"schema_version"`
	AppID          string          `json:"app_id"`
	ReleaseVersion string          `json:"release_version"`
	PatchNumber    int             `json:"patch_number"`
	Channel        string          `json:"channel"`
	CreatedAt      string          `json:"created_at"`
	Backend        string          `json:"backend"`
	Platform       string          `json:"platform"`
	Arch           string          `json:"arch"`
	Payload        PayloadManifest `json:"payload"`
	Policy         PatchPolicy     `json:"policy"`
	Signature      PatchSignature  `json:"signature"`
	Active         bool            `json:"active"`
	ActiveChannel  string          `json:"active_channel,omitempty"`
	ActiveRollout  int             `json:"active_rollout_percentage,omitempty"`
}

type CreatePatchRequest struct {
	Manifest   PatchManifest `json:"manifest"`
	PayloadB64 string        `json:"payload_b64"`
}

type PatchManifestWire struct {
	SchemaVersion  int             `json:"schema_version"`
	AppID          string          `json:"app_id"`
	ReleaseVersion string          `json:"release_version"`
	PatchNumber    int             `json:"patch_number"`
	Channel        string          `json:"channel"`
	CreatedAt      string          `json:"created_at"`
	Backend        string          `json:"backend"`
	Platform       string          `json:"platform"`
	Arch           string          `json:"arch"`
	Payload        PayloadManifest `json:"payload"`
	Policy         PatchPolicy     `json:"policy"`
	Signature      PatchSignature  `json:"signature"`
}

type PayloadManifest struct {
	Kind          string `json:"kind"`
	Compression   string `json:"compression"`
	Hash          string `json:"hash"`
	Size          uint64 `json:"size"`
	DownloadURL   string `json:"download_url"`
	DiffAlgorithm string `json:"diff_algorithm,omitempty"`
	BaseHash      string `json:"base_hash,omitempty"`
	OutputHash    string `json:"output_hash,omitempty"`
}

type PatchPolicy struct {
	RolloutPercentage int  `json:"rollout_percentage"`
	AllowDowngrade    bool `json:"allow_downgrade"`
}

type PatchSignature struct {
	Algorithm string `json:"algorithm"`
	KeyID     string `json:"key_id"`
	Value     string `json:"value"`
}

type PromotePatchRequest struct {
	AppID             string `json:"app_id"`
	ReleaseVersion    string `json:"release_version"`
	Platform          string `json:"platform"`
	Arch              string `json:"arch"`
	PatchNumber       int    `json:"patch_number"`
	Channel           string `json:"channel"`
	RolloutPercentage int    `json:"rollout_percentage"`
}

type CheckResponse struct {
	PatchAvailable bool        `json:"patch_available"`
	Patch          *PatchCheck `json:"patch,omitempty"`
}

type PatchCheck struct {
	PatchNumber  int    `json:"patch_number"`
	ManifestURL  string `json:"manifest_url"`
	PayloadURL   string `json:"payload_url"`
	ManifestHash string `json:"manifest_hash"`
	PayloadHash  string `json:"payload_hash"`
}

type SetupRequest struct {
	Username  string `json:"username"`
	Password  string `json:"password"`
	TokenName string `json:"token_name"`
}

type SetupResponse struct {
	Status string `json:"status"`
	Token  string `json:"token"`
}

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type TokenRequest struct {
	Name string `json:"name"`
}

type TokenResponse struct {
	ID        int64     `json:"id"`
	OrgID     string    `json:"org_id,omitempty"`
	Name      string    `json:"name"`
	Token     string    `json:"token,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

type PatchStatsResponse struct {
	AppID          string              `json:"app_id"`
	ReleaseVersion string              `json:"release_version,omitempty"`
	Platform       string              `json:"platform,omitempty"`
	Arch           string              `json:"arch,omitempty"`
	PatchNumber    int                 `json:"patch_number"`
	Totals         map[string]int      `json:"totals"`
	Last7Days      []PatchStatsDay     `json:"last_7_days"`
	TopFailures    []PatchFailureStats `json:"top_failures"`
}

type PatchStatsDay struct {
	Date   string         `json:"date"`
	Counts map[string]int `json:"counts"`
}

type PatchFailureStats struct {
	Reason string `json:"reason"`
	Count  int    `json:"count"`
}
