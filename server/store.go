package main

import (
	"database/sql"
	"encoding/json"
	"errors"
	"time"
)

func (s *Server) migrate() error {
	stmts := []string{
		`create table if not exists schema_migrations (version integer primary key, applied_at text not null)`,
		`create table if not exists apps (
			id text primary key,
			name text not null,
			config_json text not null default '{}',
			created_at text not null default current_timestamp,
			updated_at text not null default current_timestamp
		)`,
		`create table if not exists releases (
			app_id text not null references apps(id) on delete cascade,
			release_version text not null,
			platform text not null,
			arch text not null,
			channel text not null,
			backend text not null,
			artifact_hash text not null,
			artifact_size integer not null,
			manifest_json text not null,
			created_at text not null default current_timestamp,
			primary key(app_id, release_version, platform, arch)
		)`,
		`create table if not exists patches (
			app_id text not null references apps(id) on delete cascade,
			release_version text not null,
			platform text not null,
			arch text not null,
			patch_number integer not null,
			channel text not null,
			active_channel text,
			active_rollout_percentage integer not null default 0,
			active integer not null default 0,
			payload_key text not null,
			payload_hash text not null,
			manifest_json text not null,
			created_at text not null default current_timestamp,
			updated_at text not null default current_timestamp,
			primary key(app_id, release_version, platform, arch, patch_number)
		)`,
		`create table if not exists patch_events (
			id integer primary key autoincrement,
			app_id text not null,
			release_version text not null,
			platform text not null,
			arch text not null,
			patch_number integer,
			event_type text not null,
			client_id_hash text,
			created_at text not null default current_timestamp
		)`,
		`create table if not exists users (
			id integer primary key autoincrement,
			username text not null unique,
			password_hash text not null,
			created_at text not null default current_timestamp
		)`,
		`create table if not exists sessions (
			id text primary key,
			user_id integer not null references users(id) on delete cascade,
			expires_at text not null,
			created_at text not null default current_timestamp
		)`,
		`create table if not exists cli_tokens (
			id integer primary key autoincrement,
			name text not null,
			token_hash text not null unique,
			created_at text not null default current_timestamp,
			revoked_at text
		)`,
	}
	for _, stmt := range stmts {
		if _, err := s.db.Exec(stmt); err != nil {
			return err
		}
	}
	return nil
}

func (s *Server) setupDone() (bool, error) {
	var count int
	if err := s.db.QueryRow(`select count(*) from users`).Scan(&count); err != nil {
		return false, err
	}
	return count > 0, nil
}

func (s *Server) putApp(app App) error {
	if app.Config == nil {
		app.Config = jsonObject{}
	}
	data, err := json.Marshal(app.Config)
	if err != nil {
		return err
	}
	_, err = s.db.Exec(
		`insert into apps(id, name, config_json, created_at, updated_at)
		 values(?, ?, ?, current_timestamp, current_timestamp)
		 on conflict(id) do update set name=excluded.name, config_json=excluded.config_json, updated_at=current_timestamp`,
		app.ID, app.Name, string(data),
	)
	return err
}

func (s *Server) getApp(id string) (App, error) {
	var app App
	var config string
	var created, updated string
	err := s.db.QueryRow(`select id, name, config_json, created_at, updated_at from apps where id = ?`, id).
		Scan(&app.ID, &app.Name, &config, &created, &updated)
	if err != nil {
		return App{}, err
	}
	app.Config = jsonObject{}
	_ = json.Unmarshal([]byte(config), &app.Config)
	app.CreatedAt = parseDBTime(created)
	app.UpdatedAt = parseDBTime(updated)
	return app, nil
}

func (s *Server) listApps() ([]App, error) {
	rows, err := s.db.Query(`select id, name, config_json, created_at, updated_at from apps order by name, id`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	apps := []App{}
	for rows.Next() {
		var app App
		var config, created, updated string
		if err := rows.Scan(&app.ID, &app.Name, &config, &created, &updated); err != nil {
			return nil, err
		}
		app.Config = jsonObject{}
		_ = json.Unmarshal([]byte(config), &app.Config)
		app.CreatedAt = parseDBTime(created)
		app.UpdatedAt = parseDBTime(updated)
		apps = append(apps, app)
	}
	return apps, rows.Err()
}

func (s *Server) putRelease(manifest ReleaseManifest) error {
	data, err := json.Marshal(manifest)
	if err != nil {
		return err
	}
	_, err = s.db.Exec(
		`insert into releases(app_id, release_version, platform, arch, channel, backend, artifact_hash, artifact_size, manifest_json, created_at)
		 values(?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp)
		 on conflict(app_id, release_version, platform, arch) do update set
		 channel=excluded.channel, backend=excluded.backend, artifact_hash=excluded.artifact_hash,
		 artifact_size=excluded.artifact_size, manifest_json=excluded.manifest_json`,
		manifest.AppID, manifest.ReleaseVersion, manifest.Platform, manifest.Arch, manifest.Channel,
		manifest.Backend, manifest.ArtifactHash, manifest.ArtifactSize, string(data),
	)
	return err
}

func (s *Server) listReleases(appID string) ([]ReleaseManifest, error) {
	rows, err := s.db.Query(`select manifest_json from releases where app_id = ? order by created_at desc`, appID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []ReleaseManifest{}
	for rows.Next() {
		var data string
		if err := rows.Scan(&data); err != nil {
			return nil, err
		}
		var manifest ReleaseManifest
		if err := json.Unmarshal([]byte(data), &manifest); err != nil {
			return nil, err
		}
		out = append(out, manifest)
	}
	return out, rows.Err()
}

func (s *Server) putPatch(manifest PatchManifest) error {
	data, err := json.Marshal(manifest)
	if err != nil {
		return err
	}
	active := 0
	if manifest.Active {
		active = 1
	}
	_, err = s.db.Exec(
		`insert into patches(app_id, release_version, platform, arch, patch_number, channel, active_channel,
		 active_rollout_percentage, active, payload_key, payload_hash, manifest_json, created_at, updated_at)
		 values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, current_timestamp)
		 on conflict(app_id, release_version, platform, arch, patch_number) do update set
		 channel=excluded.channel, active_channel=excluded.active_channel,
		 active_rollout_percentage=excluded.active_rollout_percentage, active=excluded.active,
		 payload_key=excluded.payload_key, payload_hash=excluded.payload_hash,
		 manifest_json=excluded.manifest_json, updated_at=current_timestamp`,
		manifest.AppID, manifest.ReleaseVersion, manifest.Platform, manifest.Arch, manifest.PatchNumber,
		manifest.Channel, nullString(manifest.ActiveChannel), manifest.ActiveRollout, active,
		manifest.Payload.DownloadURL, manifest.Payload.Hash, string(data),
	)
	return err
}

func (s *Server) getPatch(appID, releaseVersion, platform, arch string, patchNumber int) (PatchManifest, error) {
	var data string
	err := s.db.QueryRow(
		`select manifest_json from patches where app_id = ? and release_version = ? and platform = ? and arch = ? and patch_number = ?`,
		appID, releaseVersion, platform, arch, patchNumber,
	).Scan(&data)
	if err != nil {
		return PatchManifest{}, err
	}
	var manifest PatchManifest
	if err := json.Unmarshal([]byte(data), &manifest); err != nil {
		return PatchManifest{}, err
	}
	return manifest, nil
}

func (s *Server) bestPatch(appID, releaseVersion, platform, arch, channel, clientID string, current int) (*PatchManifest, error) {
	rows, err := s.db.Query(
		`select manifest_json from patches
		 where app_id = ? and release_version = ? and platform = ? and arch = ? and active = 1 and patch_number > ?
		 order by patch_number desc`,
		appID, releaseVersion, platform, arch, current,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var data string
		if err := rows.Scan(&data); err != nil {
			return nil, err
		}
		var patch PatchManifest
		if err := json.Unmarshal([]byte(data), &patch); err != nil {
			return nil, err
		}
		if activeChannel(patch) == channel && eligible(appID, releaseVersion, patch.PatchNumber, clientID, activeRollout(patch)) {
			return &patch, nil
		}
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return nil, nil
}

func (s *Server) listPatches(appID string) ([]PatchManifest, error) {
	rows, err := s.db.Query(`select manifest_json from patches where app_id = ? order by release_version desc, patch_number desc`, appID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []PatchManifest{}
	for rows.Next() {
		var data string
		if err := rows.Scan(&data); err != nil {
			return nil, err
		}
		var manifest PatchManifest
		if err := json.Unmarshal([]byte(data), &manifest); err != nil {
			return nil, err
		}
		out = append(out, manifest)
	}
	return out, rows.Err()
}

func (s *Server) deleteApp(id string) error {
	result, err := s.db.Exec(`delete from apps where id = ?`, id)
	if err != nil {
		return err
	}
	n, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func nullString(value string) sql.NullString {
	if value == "" {
		return sql.NullString{}
	}
	return sql.NullString{String: value, Valid: true}
}

func parseDBTime(value string) time.Time {
	for _, layout := range []string{time.RFC3339Nano, "2006-01-02 15:04:05"} {
		if t, err := time.Parse(layout, value); err == nil {
			return t
		}
	}
	return time.Time{}
}

func notFound(err error) bool {
	return errors.Is(err, sql.ErrNoRows)
}
