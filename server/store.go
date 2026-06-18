package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"sort"
	"strings"
	"time"

	"gorm.io/gorm"
)

const defaultOrgID = "default"

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
		{version: 3, name: "patch_event_payload", fn: migratePatchEventPayload},
		{version: 4, name: "default_org_multitenancy", fn: migrateDefaultOrgMultitenancy},
		{version: 5, name: "org_scoped_app_ids", fn: migrateOrgScopedAppIDs},
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

func migrateDefaultOrgMultitenancy(tx *gorm.DB) error {
	stmts := []string{
		`create table if not exists organizations (
			id text primary key,
			name text not null,
			created_at text not null default current_timestamp
		)`,
		`create table if not exists org_memberships (
			org_id text not null references organizations(id) on delete cascade,
			user_id integer not null references users(id) on delete cascade,
			role text not null default 'owner',
			created_at text not null default current_timestamp,
			primary key(org_id, user_id)
		)`,
		`insert or ignore into organizations(id, name) values('default', 'Default')`,
	}
	for _, stmt := range stmts {
		if err := tx.Exec(stmt).Error; err != nil {
			return err
		}
	}
	if !tx.Migrator().HasColumn("apps", "org_id") {
		if err := tx.Exec(`alter table apps add column org_id text not null default 'default'`).Error; err != nil {
			return err
		}
	}
	if !tx.Migrator().HasColumn("cli_tokens", "org_id") {
		if err := tx.Exec(`alter table cli_tokens add column org_id text not null default 'default'`).Error; err != nil {
			return err
		}
	}
	for _, stmt := range []string{
		`update apps set org_id = 'default' where org_id = '' or org_id is null`,
		`update cli_tokens set org_id = 'default' where org_id = '' or org_id is null`,
		`insert or ignore into org_memberships(org_id, user_id, role)
		 select 'default', id, 'owner' from users
		`,
	} {
		if err := tx.Exec(stmt).Error; err != nil {
			return err
		}
	}
	return nil
}

func migratePatchEventPayload(tx *gorm.DB) error {
	if !tx.Migrator().HasColumn("patch_events", "payload") {
		return tx.Exec(`alter table patch_events add column payload text`).Error
	}
	return nil
}

func migrateOrgScopedAppIDs(tx *gorm.DB) error {
	stmts := []string{
		`pragma foreign_keys = off`,
		`create table apps_scoped (
			org_id text not null default 'default',
			id text not null,
			name text not null,
			channel text not null default 'stable',
			public_key text not null default '',
			created_at text not null default current_timestamp,
			updated_at text not null default current_timestamp,
			primary key(org_id, id)
		)`,
		`insert or ignore into apps_scoped(org_id, id, name, channel, public_key, created_at, updated_at)
		 select coalesce(nullif(org_id, ''), 'default'), id, name, channel, public_key, created_at, updated_at from apps`,
		`drop table apps`,
		`alter table apps_scoped rename to apps`,
		`create table releases_scoped (
			org_id text not null default 'default',
			app_id text not null,
			release_version text not null,
			platform text not null,
			arch text not null,
			channel text not null,
			backend text not null,
			artifact_hash text not null,
			artifact_size integer not null,
			manifest_json text not null,
			created_at text not null default current_timestamp,
			primary key(org_id, app_id, release_version, platform, arch)
		)`,
		`insert or ignore into releases_scoped(org_id, app_id, release_version, platform, arch, channel, backend, artifact_hash, artifact_size, manifest_json, created_at)
		 select coalesce(nullif(apps.org_id, ''), 'default'), releases.app_id, releases.release_version, releases.platform, releases.arch,
		        releases.channel, releases.backend, releases.artifact_hash, releases.artifact_size, releases.manifest_json, releases.created_at
		   from releases join apps on apps.id = releases.app_id`,
		`drop table releases`,
		`alter table releases_scoped rename to releases`,
		`create table patches_scoped (
			org_id text not null default 'default',
			app_id text not null,
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
			primary key(org_id, app_id, release_version, platform, arch, patch_number)
		)`,
		`insert or ignore into patches_scoped(org_id, app_id, release_version, platform, arch, patch_number, channel, active_channel,
		 active_rollout_percentage, active, payload_key, payload_hash, manifest_json, created_at, updated_at)
		 select coalesce(nullif(apps.org_id, ''), 'default'), patches.app_id, patches.release_version, patches.platform, patches.arch,
		        patches.patch_number, patches.channel, patches.active_channel, patches.active_rollout_percentage, patches.active,
		        patches.payload_key, patches.payload_hash, patches.manifest_json, patches.created_at, patches.updated_at
		   from patches join apps on apps.id = patches.app_id`,
		`drop table patches`,
		`alter table patches_scoped rename to patches`,
		`create table app_platforms_scoped (
			org_id text not null default 'default',
			app_id text not null,
			platform text not null,
			enabled integer not null default 1,
			backend text not null,
			primary key(org_id, app_id, platform)
		)`,
		`insert or ignore into app_platforms_scoped(org_id, app_id, platform, enabled, backend)
		 select coalesce(nullif(apps.org_id, ''), 'default'), app_platforms.app_id, app_platforms.platform, app_platforms.enabled, app_platforms.backend
		   from app_platforms join apps on apps.id = app_platforms.app_id`,
		`drop table app_platforms`,
		`alter table app_platforms_scoped rename to app_platforms`,
		`create table app_platform_abis_scoped (
			org_id text not null default 'default',
			app_id text not null,
			platform text not null,
			abi text not null,
			sort_order integer not null default 0,
			primary key(org_id, app_id, platform, abi)
		)`,
		`insert or ignore into app_platform_abis_scoped(org_id, app_id, platform, abi, sort_order)
		 select coalesce(nullif(apps.org_id, ''), 'default'), app_platform_abis.app_id, app_platform_abis.platform, app_platform_abis.abi, app_platform_abis.sort_order
		   from app_platform_abis join apps on apps.id = app_platform_abis.app_id`,
		`drop table app_platform_abis`,
		`alter table app_platform_abis_scoped rename to app_platform_abis`,
		`create table patch_events_scoped (
			id integer primary key autoincrement,
			org_id text not null default 'default',
			app_id text not null,
			release_version text not null,
			platform text not null,
			arch text not null,
			patch_number integer,
			event_type text not null,
			client_id_hash text,
			payload text,
			created_at text not null default current_timestamp
		)`,
		`insert into patch_events_scoped(id, org_id, app_id, release_version, platform, arch, patch_number, event_type, client_id_hash, payload, created_at)
		 select id, 'default', app_id, release_version, platform, arch, patch_number, event_type, client_id_hash, payload, created_at from patch_events`,
		`drop table patch_events`,
		`alter table patch_events_scoped rename to patch_events`,
		`pragma foreign_keys = on`,
	}
	for _, stmt := range stmts {
		if err := tx.Exec(stmt).Error; err != nil {
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
			payload text,
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

func validateOrgID(orgID string) (string, error) {
	orgID = strings.TrimSpace(orgID)
	if orgID == "" {
		return defaultOrgID, nil
	}
	for _, r := range orgID {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '-' || r == '_' {
			continue
		}
		return "", fmt.Errorf("invalid org id")
	}
	return orgID, nil
}

func (s *Server) putOrganization(org Organization) error {
	id, err := validateOrgID(org.ID)
	if err != nil {
		return err
	}
	if org.Name == "" {
		org.Name = id
	}
	_, err = s.db.Exec(
		`insert into organizations(id, name, created_at)
		 values(?, ?, current_timestamp)
		 on conflict(id) do update set name=excluded.name`,
		id, org.Name,
	)
	return err
}

func (s *Server) getOrganization(orgID string) (Organization, error) {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return Organization{}, err
	}
	var org Organization
	var created string
	err = s.db.QueryRow(`select id, name, created_at from organizations where id = ?`, orgID).
		Scan(&org.ID, &org.Name, &created)
	if err != nil {
		return Organization{}, err
	}
	org.CreatedAt = parseDBTime(created)
	return org, nil
}

func (s *Server) listOrganizations() ([]Organization, error) {
	rows, err := s.db.Query(`select id, name, created_at from organizations order by id`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	orgs := []Organization{}
	for rows.Next() {
		var org Organization
		var created string
		if err := rows.Scan(&org.ID, &org.Name, &created); err != nil {
			return nil, err
		}
		org.CreatedAt = parseDBTime(created)
		orgs = append(orgs, org)
	}
	return orgs, rows.Err()
}

func (s *Server) listOrganizationsForUser(userID int64) ([]Organization, error) {
	rows, err := s.db.Query(
		`select organizations.id, organizations.name, organizations.created_at
		 from organizations
		 join org_memberships on org_memberships.org_id = organizations.id
		 where org_memberships.user_id = ?
		 order by organizations.id`,
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	orgs := []Organization{}
	for rows.Next() {
		var org Organization
		var created string
		if err := rows.Scan(&org.ID, &org.Name, &created); err != nil {
			return nil, err
		}
		org.CreatedAt = parseDBTime(created)
		orgs = append(orgs, org)
	}
	return orgs, rows.Err()
}

func normalizeOrgRole(role string) string {
	switch strings.TrimSpace(role) {
	case "", "member":
		return "member"
	case "admin":
		return "admin"
	case "owner":
		return "owner"
	default:
		return ""
	}
}

func roleRank(role string) int {
	switch role {
	case "owner":
		return 3
	case "admin":
		return 2
	case "member":
		return 1
	default:
		return 0
	}
}

func (s *Server) orgRoleForUser(orgID string, userID int64) (string, error) {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return "", err
	}
	var role string
	err = s.db.QueryRow(`select role from org_memberships where org_id = ? and user_id = ?`, orgID, userID).Scan(&role)
	if err != nil {
		return "", err
	}
	return role, nil
}

func (s *Server) userHasOrgRole(orgID string, userID int64, minRole string) (bool, error) {
	role, err := s.orgRoleForUser(orgID, userID)
	if err != nil {
		if notFound(err) {
			return false, nil
		}
		return false, err
	}
	return roleRank(role) >= roleRank(minRole), nil
}

func (s *Server) addOrgMember(orgID string, req OrgMemberRequest) error {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return err
	}
	role := normalizeOrgRole(req.Role)
	if role == "" {
		return fmt.Errorf("invalid org role")
	}
	userID := req.UserID
	if userID == 0 {
		if strings.TrimSpace(req.Username) == "" {
			return fmt.Errorf("missing username or user_id")
		}
		if err := s.db.QueryRow(`select id from users where username = ?`, req.Username).Scan(&userID); err != nil {
			return err
		}
	}
	if _, err := s.getOrganization(orgID); err != nil {
		return err
	}
	_, err = s.db.Exec(
		`insert into org_memberships(org_id, user_id, role, created_at)
		 values(?, ?, ?, current_timestamp)
		 on conflict(org_id, user_id) do update set role=excluded.role`,
		orgID, userID, role,
	)
	return err
}

func (s *Server) orgOwnerCount(orgID string) (int, error) {
	var count int
	err := s.db.QueryRow(`select count(*) from org_memberships where org_id = ? and role = 'owner'`, orgID).Scan(&count)
	return count, err
}

func (s *Server) updateOrgMemberRole(orgID string, userID int64, role string) error {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return err
	}
	role = normalizeOrgRole(role)
	if role == "" {
		return fmt.Errorf("invalid org role")
	}
	currentRole, err := s.orgRoleForUser(orgID, userID)
	if err != nil {
		return err
	}
	if currentRole == "owner" && role != "owner" {
		count, err := s.orgOwnerCount(orgID)
		if err != nil {
			return err
		}
		if count <= 1 {
			return fmt.Errorf("cannot remove the last owner")
		}
	}
	result, err := s.db.Exec(`update org_memberships set role = ? where org_id = ? and user_id = ?`, role, orgID, userID)
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

func (s *Server) removeOrgMember(orgID string, userID int64) error {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return err
	}
	currentRole, err := s.orgRoleForUser(orgID, userID)
	if err != nil {
		return err
	}
	if currentRole == "owner" {
		count, err := s.orgOwnerCount(orgID)
		if err != nil {
			return err
		}
		if count <= 1 {
			return fmt.Errorf("cannot remove the last owner")
		}
	}
	result, err := s.db.Exec(`delete from org_memberships where org_id = ? and user_id = ?`, orgID, userID)
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

func (s *Server) listOrgMembers(orgID string) ([]OrgMember, error) {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return nil, err
	}
	rows, err := s.db.Query(
		`select org_memberships.org_id, users.id, users.username, org_memberships.role, org_memberships.created_at
		 from org_memberships
		 join users on users.id = org_memberships.user_id
		 where org_memberships.org_id = ?
		 order by users.username`,
		orgID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	members := []OrgMember{}
	for rows.Next() {
		var member OrgMember
		var created string
		if err := rows.Scan(&member.OrgID, &member.UserID, &member.Username, &member.Role, &created); err != nil {
			return nil, err
		}
		member.CreatedAt = parseDBTime(created)
		members = append(members, member)
	}
	return members, rows.Err()
}

func (s *Server) putApp(app App) error {
	return s.putAppInOrg(defaultOrgID, app)
}

func (s *Server) putAppInOrg(orgID string, app App) error {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return err
	}
	if _, err := s.getOrganization(orgID); err != nil {
		return err
	}
	normalizeApp(&app)
	app.OrgID = orgID
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	_, err = tx.Exec(
		`insert into apps(id, org_id, name, channel, public_key, created_at, updated_at)
		 values(?, ?, ?, ?, ?, current_timestamp, current_timestamp)
		 on conflict(org_id, id) do update set name=excluded.name, channel=excluded.channel, public_key=excluded.public_key, updated_at=current_timestamp`,
		app.ID, app.OrgID, app.Name, app.Channel, app.PublicKey,
	)
	if err != nil {
		return err
	}
	if _, err := tx.Exec(`delete from app_platform_abis where org_id = ? and app_id = ?`, orgID, app.ID); err != nil {
		return err
	}
	if _, err := tx.Exec(`delete from app_platforms where org_id = ? and app_id = ?`, orgID, app.ID); err != nil {
		return err
	}
	for _, platform := range app.Platforms {
		enabled := 0
		if platform.Enabled {
			enabled = 1
		}
		if _, err := tx.Exec(
			`insert into app_platforms(org_id, app_id, platform, enabled, backend)
			 values(?, ?, ?, ?, ?)
			 on conflict(org_id, app_id, platform) do update set enabled=excluded.enabled, backend=excluded.backend`,
			orgID, app.ID, platform.Platform, enabled, platform.Backend,
		); err != nil {
			return err
		}
		for i, abi := range platform.ABI {
			if _, err := tx.Exec(
				`insert into app_platform_abis(org_id, app_id, platform, abi, sort_order)
				 values(?, ?, ?, ?, ?)
				 on conflict(org_id, app_id, platform, abi) do update set sort_order=excluded.sort_order`,
				orgID, app.ID, platform.Platform, abi, i,
			); err != nil {
				return err
			}
		}
	}
	return tx.Commit()
}

func (s *Server) getApp(id string) (App, error) {
	return s.getAppInOrg(defaultOrgID, id)
}

func (s *Server) getAppInOrg(orgID, id string) (App, error) {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return App{}, err
	}
	var app App
	var created, updated string
	err = s.db.QueryRow(`select id, org_id, name, channel, public_key, created_at, updated_at from apps where org_id = ? and id = ?`, orgID, id).
		Scan(&app.ID, &app.OrgID, &app.Name, &app.Channel, &app.PublicKey, &created, &updated)
	if err != nil {
		return App{}, err
	}
	app.CreatedAt = parseDBTime(created)
	app.UpdatedAt = parseDBTime(updated)
	app.Platforms, err = s.listAppPlatforms(orgID, id)
	if err != nil {
		return App{}, err
	}
	normalizeApp(&app)
	return app, nil
}

func (s *Server) findAppsByName(name string) ([]App, error) {
	return s.findAppsByNameInOrg(defaultOrgID, name)
}

func (s *Server) findAppsByNameInOrg(orgID, name string) ([]App, error) {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return nil, err
	}
	rows, err := s.db.Query(`select id from apps where org_id = ? and name = ? order by id`, orgID, name)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	ids := []string{}
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	apps := make([]App, 0, len(ids))
	for _, id := range ids {
		app, err := s.getAppInOrg(orgID, id)
		if err != nil {
			return nil, err
		}
		apps = append(apps, app)
	}
	return apps, nil
}

func (s *Server) listApps() ([]App, error) {
	return s.listAppsInOrg(defaultOrgID)
}

func (s *Server) listAppsInOrg(orgID string) ([]App, error) {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return nil, err
	}
	rows, err := s.db.Query(`select id, org_id, name, channel, public_key, created_at, updated_at from apps where org_id = ? order by name, id`, orgID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	apps := []App{}
	for rows.Next() {
		var app App
		var created, updated string
		if err := rows.Scan(&app.ID, &app.OrgID, &app.Name, &app.Channel, &app.PublicKey, &created, &updated); err != nil {
			return nil, err
		}
		app.CreatedAt = parseDBTime(created)
		app.UpdatedAt = parseDBTime(updated)
		app.Platforms, err = s.listAppPlatforms(orgID, app.ID)
		if err != nil {
			return nil, err
		}
		normalizeApp(&app)
		apps = append(apps, app)
	}
	return apps, rows.Err()
}

func (s *Server) listAppPlatforms(orgID, appID string) ([]AppPlatform, error) {
	rows, err := s.db.Query(
		`select platform, enabled, backend from app_platforms where org_id = ? and app_id = ? order by case platform when 'android' then 0 when 'ios' then 1 else 2 end, platform`,
		orgID, appID,
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
			`select abi from app_platform_abis where org_id = ? and app_id = ? and platform = ? order by sort_order, abi`,
			orgID, appID, platform.Platform,
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
	if !tx.Migrator().HasColumn("app_platforms", "org_id") {
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

	type appIDRow struct {
		OrgID string `gorm:"column:org_id"`
		ID    string
	}
	var rows []appIDRow
	if err := tx.Raw(
		`select org_id, id from apps
		 where not exists (
		   select 1 from app_platforms
		    where app_platforms.org_id = apps.org_id and app_platforms.app_id = apps.id
		 )`,
	).Scan(&rows).Error; err != nil {
		return err
	}
	for _, row := range rows {
		for _, platform := range defaultAppPlatforms() {
			enabled := 0
			if platform.Enabled {
				enabled = 1
			}
			if err := tx.Exec(
				`insert into app_platforms(org_id, app_id, platform, enabled, backend) values(?, ?, ?, ?, ?)`,
				row.OrgID, row.ID, platform.Platform, enabled, platform.Backend,
			).Error; err != nil {
				return err
			}
			for i, abi := range platform.ABI {
				if err := tx.Exec(
					`insert into app_platform_abis(org_id, app_id, platform, abi, sort_order) values(?, ?, ?, ?, ?)`,
					row.OrgID, row.ID, platform.Platform, abi, i,
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
	return s.putReleaseInOrg(defaultOrgID, manifest)
}

func (s *Server) putReleaseInOrg(orgID string, manifest ReleaseManifest) error {
	if _, err := s.getAppInOrg(orgID, manifest.AppID); err != nil {
		return err
	}
	data, err := json.Marshal(manifest)
	if err != nil {
		return err
	}
	_, err = s.db.Exec(
		`insert into releases(org_id, app_id, release_version, platform, arch, channel, backend, artifact_hash, artifact_size, manifest_json, created_at)
		 values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp)
		 on conflict(org_id, app_id, release_version, platform, arch) do update set
		 channel=excluded.channel, backend=excluded.backend, artifact_hash=excluded.artifact_hash,
		 artifact_size=excluded.artifact_size, manifest_json=excluded.manifest_json`,
		orgID, manifest.AppID, manifest.ReleaseVersion, manifest.Platform, manifest.Arch, manifest.Channel,
		manifest.Backend, manifest.ArtifactHash, manifest.ArtifactSize, string(data),
	)
	return err
}

func (s *Server) listReleases(appID string) ([]ReleaseManifest, error) {
	return s.listReleasesInOrg(defaultOrgID, appID)
}

func (s *Server) listReleasesInOrg(orgID, appID string) ([]ReleaseManifest, error) {
	if _, err := s.getAppInOrg(orgID, appID); err != nil {
		return nil, err
	}
	rows, err := s.db.Query(`select manifest_json from releases where org_id = ? and app_id = ? order by created_at desc`, orgID, appID)
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
	return s.putPatchInOrg(defaultOrgID, manifest)
}

func (s *Server) putPatchInOrg(orgID string, manifest PatchManifest) error {
	if _, err := s.getAppInOrg(orgID, manifest.AppID); err != nil {
		return err
	}
	data, err := json.Marshal(manifest)
	if err != nil {
		return err
	}
	active := 0
	if manifest.Active {
		active = 1
	}
	_, err = s.db.Exec(
		`insert into patches(org_id, app_id, release_version, platform, arch, patch_number, channel, active_channel,
		 active_rollout_percentage, active, payload_key, payload_hash, manifest_json, created_at, updated_at)
		 values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, current_timestamp)
		 on conflict(org_id, app_id, release_version, platform, arch, patch_number) do update set
		 channel=excluded.channel, active_channel=excluded.active_channel,
		 active_rollout_percentage=excluded.active_rollout_percentage, active=excluded.active,
		 payload_key=excluded.payload_key, payload_hash=excluded.payload_hash,
		 manifest_json=excluded.manifest_json, updated_at=current_timestamp`,
		orgID, manifest.AppID, manifest.ReleaseVersion, manifest.Platform, manifest.Arch, manifest.PatchNumber,
		manifest.Channel, nullString(manifest.ActiveChannel), manifest.ActiveRollout, active,
		manifest.Payload.DownloadURL, manifest.Payload.Hash, string(data),
	)
	return err
}

func (s *Server) getPatch(appID, releaseVersion, platform, arch string, patchNumber int) (PatchManifest, error) {
	return s.getPatchInOrg(defaultOrgID, appID, releaseVersion, platform, arch, patchNumber)
}

func (s *Server) getPatchInOrg(orgID, appID, releaseVersion, platform, arch string, patchNumber int) (PatchManifest, error) {
	if _, err := s.getAppInOrg(orgID, appID); err != nil {
		return PatchManifest{}, err
	}
	var data string
	err := s.db.QueryRow(
		`select manifest_json from patches where org_id = ? and app_id = ? and release_version = ? and platform = ? and arch = ? and patch_number = ?`,
		orgID, appID, releaseVersion, platform, arch, patchNumber,
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
	return s.bestPatchInOrg(defaultOrgID, appID, releaseVersion, platform, arch, channel, clientID, current)
}

func (s *Server) bestPatchInOrg(orgID, appID, releaseVersion, platform, arch, channel, clientID string, current int) (*PatchManifest, error) {
	if _, err := s.getAppInOrg(orgID, appID); err != nil {
		if notFound(err) {
			return nil, nil
		}
		return nil, err
	}
	rows, err := s.db.Query(
		`select manifest_json from patches
		 where org_id = ? and app_id = ? and release_version = ? and platform = ? and arch = ? and active = 1 and patch_number > ?
		 order by patch_number desc`,
		orgID, appID, releaseVersion, platform, arch, current,
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
		if activeChannel(patch) == channel && eligible(appID, releaseVersion, clientID, activeRollout(patch)) {
			return &patch, nil
		}
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return nil, nil
}

func (s *Server) listPatches(appID string) ([]PatchManifest, error) {
	return s.listPatchesInOrg(defaultOrgID, appID)
}

func (s *Server) listPatchesInOrg(orgID, appID string) ([]PatchManifest, error) {
	if _, err := s.getAppInOrg(orgID, appID); err != nil {
		return nil, err
	}
	rows, err := s.db.Query(`select manifest_json from patches where org_id = ? and app_id = ? order by release_version desc, patch_number desc`, orgID, appID)
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

func (s *Server) patchStats(appID, releaseVersion, platform, arch string, patchNumber int) (PatchStatsResponse, error) {
	return s.patchStatsInOrg(defaultOrgID, appID, releaseVersion, platform, arch, patchNumber)
}

func (s *Server) patchStatsInOrg(orgID, appID, releaseVersion, platform, arch string, patchNumber int) (PatchStatsResponse, error) {
	if _, err := s.getAppInOrg(orgID, appID); err != nil {
		return PatchStatsResponse{}, err
	}
	stats := PatchStatsResponse{
		AppID:          appID,
		ReleaseVersion: releaseVersion,
		Platform:       platform,
		Arch:           arch,
		PatchNumber:    patchNumber,
		Totals:         map[string]int{},
		Last7Days:      []PatchStatsDay{},
		TopFailures:    []PatchFailureStats{},
	}
	rows, err := s.db.Query(
		`select event_type, count(*)
		 from patch_events
		 where org_id = ? and app_id = ? and patch_number = ?
		   and (? = '' or release_version = ?)
		   and (? = '' or platform = ?)
		   and (? = '' or arch = ?)
		 group by event_type`,
		orgID, appID, patchNumber, releaseVersion, releaseVersion, platform, platform, arch, arch,
	)
	if err != nil {
		return stats, err
	}
	for rows.Next() {
		var eventType string
		var count int
		if err := rows.Scan(&eventType, &count); err != nil {
			_ = rows.Close()
			return stats, err
		}
		stats.Totals[eventType] = count
	}
	if err := rows.Close(); err != nil {
		return stats, err
	}

	rows, err = s.db.Query(
		`select date(created_at), event_type, count(*)
		 from patch_events
		 where org_id = ? and app_id = ? and patch_number = ?
		   and (? = '' or release_version = ?)
		   and (? = '' or platform = ?)
		   and (? = '' or arch = ?)
		   and created_at >= datetime('now', '-6 days')
		 group by date(created_at), event_type
		 order by date(created_at) asc`,
		orgID, appID, patchNumber, releaseVersion, releaseVersion, platform, platform, arch, arch,
	)
	if err != nil {
		return stats, err
	}
	daily := map[string]map[string]int{}
	for rows.Next() {
		var date, eventType string
		var count int
		if err := rows.Scan(&date, &eventType, &count); err != nil {
			_ = rows.Close()
			return stats, err
		}
		if daily[date] == nil {
			daily[date] = map[string]int{}
		}
		daily[date][eventType] = count
	}
	if err := rows.Close(); err != nil {
		return stats, err
	}
	dates := make([]string, 0, len(daily))
	for date := range daily {
		dates = append(dates, date)
	}
	sort.Strings(dates)
	for _, date := range dates {
		stats.Last7Days = append(stats.Last7Days, PatchStatsDay{Date: date, Counts: daily[date]})
	}

	rows, err = s.db.Query(
		`select event_type, coalesce(payload, '')
		 from patch_events
		 where org_id = ? and app_id = ? and patch_number = ?
		   and (? = '' or release_version = ?)
		   and (? = '' or platform = ?)
		   and (? = '' or arch = ?)
		   and event_type in ('launch_failure', 'crash_rollback')`,
		orgID, appID, patchNumber, releaseVersion, releaseVersion, platform, platform, arch, arch,
	)
	if err != nil {
		return stats, err
	}
	failures := map[string]int{}
	for rows.Next() {
		var eventType, payload string
		if err := rows.Scan(&eventType, &payload); err != nil {
			_ = rows.Close()
			return stats, err
		}
		failures[failureReason(eventType, payload)]++
	}
	if err := rows.Close(); err != nil {
		return stats, err
	}
	reasons := make([]string, 0, len(failures))
	for reason := range failures {
		reasons = append(reasons, reason)
	}
	sort.Slice(reasons, func(i, j int) bool {
		if failures[reasons[i]] == failures[reasons[j]] {
			return reasons[i] < reasons[j]
		}
		return failures[reasons[i]] > failures[reasons[j]]
	})
	for i, reason := range reasons {
		if i == 10 {
			break
		}
		stats.TopFailures = append(stats.TopFailures, PatchFailureStats{
			Reason: reason,
			Count:  failures[reason],
		})
	}
	return stats, nil
}

func failureReason(eventType, payload string) string {
	var data map[string]any
	if err := json.Unmarshal([]byte(payload), &data); err == nil {
		for _, key := range []string{"error_message", "reason", "last_error"} {
			if value, ok := data[key].(string); ok && value != "" {
				return value
			}
		}
	}
	return eventType
}

func (s *Server) deleteOldPatchEvents(retentionDays int) (int64, error) {
	if retentionDays <= 0 {
		retentionDays = 90
	}
	result, err := s.db.Exec(
		`delete from patch_events where created_at < datetime('now', ?)`,
		fmt.Sprintf("-%d days", retentionDays),
	)
	if err != nil {
		return 0, err
	}
	return result.RowsAffected()
}

func (s *Server) startEventRetentionCleanup(ctx context.Context, retentionDays int, interval time.Duration) {
	if interval <= 0 {
		interval = 24 * time.Hour
	}
	go func() {
		if deleted, err := s.deleteOldPatchEvents(retentionDays); err != nil {
			log.Printf("patch event cleanup failed: %v", err)
		} else if deleted > 0 {
			log.Printf("patch event cleanup removed %d old rows", deleted)
		}
		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				if deleted, err := s.deleteOldPatchEvents(retentionDays); err != nil {
					log.Printf("patch event cleanup failed: %v", err)
				} else if deleted > 0 {
					log.Printf("patch event cleanup removed %d old rows", deleted)
				}
			}
		}
	}()
}

func (s *Server) deleteApp(id string) error {
	return s.deleteAppInOrg(defaultOrgID, id)
}

func (s *Server) deleteAppInOrg(orgID, id string) error {
	orgID, err := validateOrgID(orgID)
	if err != nil {
		return err
	}
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	for _, stmt := range []string{
		`delete from app_platform_abis where org_id = ? and app_id = ?`,
		`delete from app_platforms where org_id = ? and app_id = ?`,
		`delete from patches where org_id = ? and app_id = ?`,
		`delete from releases where org_id = ? and app_id = ?`,
		`delete from patch_events where org_id = ? and app_id = ?`,
	} {
		if _, err := tx.Exec(stmt, orgID, id); err != nil {
			return err
		}
	}
	result, err := tx.Exec(`delete from apps where org_id = ? and id = ?`, orgID, id)
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
	return tx.Commit()
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
