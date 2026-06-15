package main

import (
	"database/sql"
	"encoding/json"
	"errors"
	"time"

	"gorm.io/gorm"
)

func (s *Server) migrate() error {
	if err := s.gormDB.Exec(`create table if not exists schema_migrations (
		version integer primary key,
		name text not null,
		applied_at text not null default current_timestamp
	)`).Error; err != nil {
		return err
	}
	if !s.gormDB.Migrator().HasColumn("schema_migrations", "name") {
		if err := s.gormDB.Exec(`alter table schema_migrations add column name text not null default ''`).Error; err != nil {
			return err
		}
	}
	migrations := []struct {
		version int
		name    string
		fn      func(*gorm.DB) error
	}{
		{version: 1, name: "initial_schema", fn: migrateInitialSchema},
		{version: 2, name: "app_config_relational", fn: migrateAppConfigRelational},
	}
	for _, migration := range migrations {
		var count int64
		if err := s.gormDB.Raw(`select count(*) from schema_migrations where version = ?`, migration.version).Scan(&count).Error; err != nil {
			return err
		}
		if count > 0 {
			continue
		}
		if err := s.gormDB.Transaction(func(tx *gorm.DB) error {
			if err := migration.fn(tx); err != nil {
				return err
			}
			return tx.Exec(
				`insert into schema_migrations(version, name, applied_at) values(?, ?, current_timestamp)`,
				migration.version, migration.name,
			).Error
		}); err != nil {
			return err
		}
	}
	return nil
}

func migrateInitialSchema(tx *gorm.DB) error {
	stmts := []string{
		`create table if not exists schema_migrations (
			version integer primary key,
			name text not null,
			applied_at text not null default current_timestamp
		)`,
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
		if err := tx.Exec(stmt).Error; err != nil {
			return err
		}
	}
	return nil
}

func migrateAppConfigRelational(tx *gorm.DB) error {
	stmts := []string{
		`create table if not exists app_platforms (
			app_id text not null references apps(id) on delete cascade,
			platform text not null,
			enabled integer not null default 1,
			backend text not null,
			primary key(app_id, platform)
		)`,
		`create table if not exists app_platform_abis (
			app_id text not null,
			platform text not null,
			abi text not null,
			sort_order integer not null default 0,
			primary key(app_id, platform, abi),
			foreign key(app_id, platform) references app_platforms(app_id, platform) on delete cascade
		)`,
	}
	for _, stmt := range stmts {
		if err := tx.Exec(stmt).Error; err != nil {
			return err
		}
	}
	hasConfig := tx.Migrator().HasColumn("apps", "config_json")
	if !tx.Migrator().HasColumn("apps", "channel") {
		if err := tx.Exec(`alter table apps add column channel text not null default 'stable'`).Error; err != nil {
			return err
		}
	}
	if !tx.Migrator().HasColumn("apps", "public_key") {
		if err := tx.Exec(`alter table apps add column public_key text not null default ''`).Error; err != nil {
			return err
		}
	}

	if hasConfig {
		type legacyAppRow struct {
			ID         string
			ConfigJSON string `gorm:"column:config_json"`
		}
		var rows []legacyAppRow
		if err := tx.Raw(`select id, config_json from apps`).Scan(&rows).Error; err != nil {
			return err
		}
		for _, row := range rows {
			app := appFromLegacyConfig(row.ID, row.ConfigJSON)
			if err := tx.Exec(`update apps set channel = ?, public_key = ? where id = ?`, app.Channel, app.PublicKey, row.ID).Error; err != nil {
				return err
			}
			for _, platform := range app.Platforms {
				enabled := 0
				if platform.Enabled {
					enabled = 1
				}
				if err := tx.Exec(
					`insert into app_platforms(app_id, platform, enabled, backend)
				 values(?, ?, ?, ?)
				 on conflict(app_id, platform) do update set enabled=excluded.enabled, backend=excluded.backend`,
					row.ID, platform.Platform, enabled, platform.Backend,
				).Error; err != nil {
					return err
				}
				for i, abi := range platform.ABI {
					if err := tx.Exec(
						`insert into app_platform_abis(app_id, platform, abi, sort_order)
					 values(?, ?, ?, ?)
					 on conflict(app_id, platform, abi) do update set sort_order=excluded.sort_order`,
						row.ID, platform.Platform, abi, i,
					).Error; err != nil {
						return err
					}
				}
			}
		}
	}
	if !hasConfig {
		if err := backfillMissingDefaultPlatforms(tx); err != nil {
			return err
		}
		return nil
	}
	for _, stmt := range []string{
		`create table apps_new (
			id text primary key,
			name text not null,
			channel text not null default 'stable',
			public_key text not null default '',
			created_at text not null default current_timestamp,
			updated_at text not null default current_timestamp
		)`,
		`insert into apps_new(id, name, channel, public_key, created_at, updated_at)
		 select id, name, channel, public_key, created_at, updated_at from apps`,
		`drop table apps`,
		`alter table apps_new rename to apps`,
	} {
		if err := tx.Exec(stmt).Error; err != nil {
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
	normalizeApp(&app)
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	_, err = tx.Exec(
		`insert into apps(id, name, channel, public_key, created_at, updated_at)
		 values(?, ?, ?, ?, current_timestamp, current_timestamp)
		 on conflict(id) do update set name=excluded.name, channel=excluded.channel, public_key=excluded.public_key, updated_at=current_timestamp`,
		app.ID, app.Name, app.Channel, app.PublicKey,
	)
	if err != nil {
		return err
	}
	if _, err := tx.Exec(`delete from app_platform_abis where app_id = ?`, app.ID); err != nil {
		return err
	}
	if _, err := tx.Exec(`delete from app_platforms where app_id = ?`, app.ID); err != nil {
		return err
	}
	for _, platform := range app.Platforms {
		enabled := 0
		if platform.Enabled {
			enabled = 1
		}
		if _, err := tx.Exec(
			`insert into app_platforms(app_id, platform, enabled, backend) values(?, ?, ?, ?)`,
			app.ID, platform.Platform, enabled, platform.Backend,
		); err != nil {
			return err
		}
		for i, abi := range platform.ABI {
			if _, err := tx.Exec(
				`insert into app_platform_abis(app_id, platform, abi, sort_order) values(?, ?, ?, ?)`,
				app.ID, platform.Platform, abi, i,
			); err != nil {
				return err
			}
		}
	}
	return tx.Commit()
}

func (s *Server) getApp(id string) (App, error) {
	var app App
	var created, updated string
	err := s.db.QueryRow(`select id, name, channel, public_key, created_at, updated_at from apps where id = ?`, id).
		Scan(&app.ID, &app.Name, &app.Channel, &app.PublicKey, &created, &updated)
	if err != nil {
		return App{}, err
	}
	app.CreatedAt = parseDBTime(created)
	app.UpdatedAt = parseDBTime(updated)
	app.Platforms, err = s.listAppPlatforms(id)
	if err != nil {
		return App{}, err
	}
	normalizeApp(&app)
	return app, nil
}

func (s *Server) listApps() ([]App, error) {
	rows, err := s.db.Query(`select id, name, channel, public_key, created_at, updated_at from apps order by name, id`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	apps := []App{}
	for rows.Next() {
		var app App
		var created, updated string
		if err := rows.Scan(&app.ID, &app.Name, &app.Channel, &app.PublicKey, &created, &updated); err != nil {
			return nil, err
		}
		app.CreatedAt = parseDBTime(created)
		app.UpdatedAt = parseDBTime(updated)
		app.Platforms, err = s.listAppPlatforms(app.ID)
		if err != nil {
			return nil, err
		}
		normalizeApp(&app)
		apps = append(apps, app)
	}
	return apps, rows.Err()
}

func (s *Server) listAppPlatforms(appID string) ([]AppPlatform, error) {
	rows, err := s.db.Query(
		`select platform, enabled, backend from app_platforms where app_id = ? order by case platform when 'android' then 0 when 'ios' then 1 else 2 end, platform`,
		appID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []AppPlatform{}
	for rows.Next() {
		var platform AppPlatform
		var enabled int
		if err := rows.Scan(&platform.Platform, &enabled, &platform.Backend); err != nil {
			return nil, err
		}
		platform.Enabled = enabled != 0
		abiRows, err := s.db.Query(
			`select abi from app_platform_abis where app_id = ? and platform = ? order by sort_order, abi`,
			appID, platform.Platform,
		)
		if err != nil {
			return nil, err
		}
		for abiRows.Next() {
			var abi string
			if err := abiRows.Scan(&abi); err != nil {
				_ = abiRows.Close()
				return nil, err
			}
			platform.ABI = append(platform.ABI, abi)
		}
		if err := abiRows.Close(); err != nil {
			return nil, err
		}
		out = append(out, platform)
	}
	return out, rows.Err()
}

func backfillMissingDefaultPlatforms(tx *gorm.DB) error {
	type appIDRow struct {
		ID string
	}
	var rows []appIDRow
	if err := tx.Raw(`select id from apps where id not in (select distinct app_id from app_platforms)`).Scan(&rows).Error; err != nil {
		return err
	}
	for _, row := range rows {
		for _, platform := range defaultAppPlatforms() {
			enabled := 0
			if platform.Enabled {
				enabled = 1
			}
			if err := tx.Exec(
				`insert into app_platforms(app_id, platform, enabled, backend) values(?, ?, ?, ?)`,
				row.ID, platform.Platform, enabled, platform.Backend,
			).Error; err != nil {
				return err
			}
			for i, abi := range platform.ABI {
				if err := tx.Exec(
					`insert into app_platform_abis(app_id, platform, abi, sort_order) values(?, ?, ?, ?)`,
					row.ID, platform.Platform, abi, i,
				).Error; err != nil {
					return err
				}
			}
		}
	}
	return nil
}

func normalizeApp(app *App) {
	if app.Channel == "" {
		app.Channel = "stable"
	}
	if app.Name == "" {
		app.Name = app.ID
	}
	if len(app.Platforms) == 0 {
		app.Platforms = defaultAppPlatforms()
		return
	}
	for i := range app.Platforms {
		if app.Platforms[i].Platform == "" {
			app.Platforms[i].Platform = "android"
		}
		if app.Platforms[i].Backend == "" {
			if app.Platforms[i].Platform == "ios" {
				app.Platforms[i].Backend = "bytecode"
			} else {
				app.Platforms[i].Backend = "snapshot_replace"
			}
		}
		if app.Platforms[i].Platform == "android" && len(app.Platforms[i].ABI) == 0 {
			app.Platforms[i].ABI = []string{"arm64-v8a", "x86_64"}
		}
		if app.Platforms[i].Platform == "ios" {
			app.Platforms[i].ABI = []string{}
		}
	}
}

func defaultAppPlatforms() []AppPlatform {
	return []AppPlatform{
		{
			Platform: "android",
			Enabled:  true,
			Backend:  "snapshot_replace",
			ABI:      []string{"arm64-v8a", "x86_64"},
		},
		{
			Platform: "ios",
			Enabled:  true,
			Backend:  "bytecode",
			ABI:      []string{},
		},
	}
}

func appFromLegacyConfig(id, configJSON string) App {
	app := App{ID: id, Channel: "stable", Platforms: defaultAppPlatforms()}
	var raw map[string]any
	if err := json.Unmarshal([]byte(configJSON), &raw); err != nil {
		return app
	}
	if channel, ok := raw["channel"].(string); ok && channel != "" {
		app.Channel = channel
	}
	if publicKey, ok := raw["public_key"].(string); ok {
		app.PublicKey = publicKey
	}
	if security, ok := raw["security"].(map[string]any); ok {
		if publicKey, ok := security["public_key"].(string); ok {
			app.PublicKey = publicKey
		}
	}
	platforms, ok := raw["platforms"].(map[string]any)
	if !ok {
		return app
	}
	for i := range app.Platforms {
		entry, ok := platforms[app.Platforms[i].Platform].(map[string]any)
		if !ok {
			continue
		}
		if enabled, ok := entry["enabled"].(bool); ok {
			app.Platforms[i].Enabled = enabled
		}
		if backend, ok := entry["backend"].(string); ok && backend != "" {
			app.Platforms[i].Backend = backend
		}
		if abiValues, ok := entry["abi"].([]any); ok {
			app.Platforms[i].ABI = app.Platforms[i].ABI[:0]
			for _, value := range abiValues {
				if abi, ok := value.(string); ok && abi != "" {
					app.Platforms[i].ABI = append(app.Platforms[i].ABI, abi)
				}
			}
		}
	}
	return app
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
