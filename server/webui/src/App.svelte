<script lang="ts">
  type AppPlatform = {
    platform: string;
    enabled: boolean;
    backend: string;
    abi: string[];
  };

  type Organization = {
    id: string;
    name: string;
    created_at?: string;
  };

  type OrgMember = {
    org_id: string;
    user_id: number;
    username: string;
    role: string;
    created_at?: string;
  };

  type AppConfig = {
    id: string;
    org_id?: string;
    name: string;
    channel: string;
    public_key: string;
    platforms?: AppPlatform[];
  };

  type ReleaseManifest = {
    app_id: string;
    release_version: string;
    channel: string;
    platform: string;
    arch: string;
    backend: string;
    artifact_hash: string;
    artifact_size: number;
  };

  type PatchManifest = {
    app_id: string;
    release_version: string;
    patch_number: number;
    channel: string;
    platform: string;
    arch: string;
    backend: string;
    active: boolean;
    active_channel?: string;
    active_rollout_percentage?: number;
    payload: { hash: string; size: number; download_url: string };
  };

  type Token = {
    id: number;
    org_id?: string;
    name: string;
    token?: string;
    created_at: string;
  };

  type PatchStatsDay = {
    date: string;
    counts: Record<string, number>;
  };

  type PatchStats = {
    totals: Record<string, number>;
    last_7_days: PatchStatsDay[];
    top_failures: { reason: string; count: number }[];
  };

  let setupRequired = true;
  let authenticated = false;
  let username = '';
  let orgs: Organization[] = [];
  let selectedOrgId = '';
  let members: OrgMember[] = [];
  let apps: AppConfig[] = [];
  let selectedAppId = '';
  let releases: ReleaseManifest[] = [];
  let patches: PatchManifest[] = [];
  let patchStats: Record<string, PatchStats> = {};
  let tokens: Token[] = [];
  let error = '';
  let setupToken = '';

  let setupUsername = 'admin';
  let setupPassword = '';
  let loginUsername = 'admin';
  let loginPassword = '';
  let newOrgId = '';
  let newOrgName = '';
  let newAppName = '';
  let newAppId = crypto.randomUUID();
  let tokenName = 'local-cli';
  let memberUsername = '';
  let memberRole = 'member';

  // State for config editor
  let showConfig = false;
  let isEditingConfig = false;
  let appNameInput = '';
  let channelInput = 'stable';
  let publicKeyInput = '';
  let androidEnabled = true;
  let androidBackend = 'snapshot_replace';
  let androidAbi = ['arm64-v8a', 'x86_64'];
  let iosEnabled = true;
  let iosBackend = 'bytecode';
  const androidAbiOptions = ['arm64-v8a', 'x86_64', 'armeabi-v7a'];

  // State for app deletion confirmation
  let showDeleteConfirmModal = false;

  // Dictionary for custom rollout percentages of patches
  let promotePercentages: Record<string, number> = {};

  function patchKey(patch: PatchManifest) {
    return `${patch.release_version}-${patch.patch_number}-${patch.platform}-${patch.arch}`;
  }

  // Toast notification
  let successToast = '';
  let toastTimeout: ReturnType<typeof setTimeout>;

  function showToast(message: string) {
    successToast = message;
    if (toastTimeout) clearTimeout(toastTimeout);
    toastTimeout = setTimeout(() => {
      successToast = '';
    }, 4000);
  }

  async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
    const response = await fetch(path, {
      credentials: 'include',
      headers: { 'Content-Type': 'application/json', ...(options.headers ?? {}) },
      ...options
    });
    if (!response.ok) {
      const body = await response.text();
      throw new Error(body || `HTTP ${response.status}`);
    }
    return (await response.json()) as T;
  }

  async function refreshAuth() {
    error = '';
    const status = await request<{ setup_required: boolean }>('/api/auth/setup-status');
    setupRequired = status.setup_required;
    if (!setupRequired) {
      try {
        const me = await request<{ authenticated: boolean; username: string }>('/api/auth/me');
        authenticated = me.authenticated;
        username = me.username;
        await loadOrgs();
      } catch {
        authenticated = false;
      }
    }
  }

  async function run(action: () => Promise<void>) {
    error = '';
    try {
      await action();
    } catch (err) {
      error = err instanceof Error ? err.message : String(err);
      showToast(`Error: ${error}`);
    }
  }

  async function setup() {
    await run(async () => {
      const result = await request<{ token: string }>('/api/auth/setup', {
        method: 'POST',
        body: JSON.stringify({ username: setupUsername, password: setupPassword, token_name: tokenName })
      });
      setupToken = result.token;
      setupRequired = false;
      showToast("Admin account created successfully!");
    });
  }

  async function login() {
    await run(async () => {
      await request('/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ username: loginUsername, password: loginPassword })
      });
      await refreshAuth();
      showToast("Signed in successfully");
    });
  }

  async function logout() {
    await request('/api/auth/logout', { method: 'POST', body: '{}' });
    authenticated = false;
    orgs = [];
    selectedOrgId = '';
    members = [];
    apps = [];
    selectedAppId = '';
    showToast("Signed out successfully");
  }

  function orgBase() {
    return `/api/admin/orgs/${encodeURIComponent(selectedOrgId)}`;
  }

  async function loadOrgs() {
    orgs = (await request<Organization[] | null>('/api/admin/orgs')) ?? [];
    if (!selectedOrgId && orgs.length > 0) {
      selectedOrgId = orgs[0].id;
    }
    if (selectedOrgId && !orgs.some((org) => org.id === selectedOrgId)) {
      selectedOrgId = orgs[0]?.id ?? '';
    }
    await loadOrgScoped();
  }

  async function loadOrgScoped() {
    selectedAppId = '';
    releases = [];
    patches = [];
    patchStats = {};
    if (!selectedOrgId) {
      members = [];
      apps = [];
      tokens = [];
      return;
    }
    await Promise.all([loadMembers(), loadApps(), loadTokens()]);
  }

  async function createOrg() {
    await run(async () => {
      const id = newOrgId.trim();
      if (!id) throw new Error('missing org id');
      await request('/api/admin/orgs', {
        method: 'POST',
        body: JSON.stringify({ id, name: newOrgName || id })
      });
      selectedOrgId = id;
      newOrgId = '';
      newOrgName = '';
      showToast(`Org "${id}" created`);
      await loadOrgs();
    });
  }

  async function loadMembers() {
    members = (await request<OrgMember[] | null>(`${orgBase()}/members`)) ?? [];
  }

  async function addMember() {
    await run(async () => {
      await request(`${orgBase()}/members`, {
        method: 'POST',
        body: JSON.stringify({ username: memberUsername, role: memberRole })
      });
      showToast(`Member "${memberUsername}" added`);
      memberUsername = '';
      memberRole = 'member';
      await loadMembers();
    });
  }

  async function updateMemberRole(member: OrgMember, role: string) {
    await run(async () => {
      await request(`${orgBase()}/members/${member.user_id}`, {
        method: 'PUT',
        body: JSON.stringify({ role })
      });
      showToast(`Member "${member.username || member.user_id}" role updated`);
      await loadMembers();
    });
  }

  async function removeMember(member: OrgMember) {
    await run(async () => {
      await request(`${orgBase()}/members/${member.user_id}`, { method: 'DELETE' });
      showToast(`Member "${member.username || member.user_id}" removed`);
      await loadMembers();
    });
  }

  async function loadApps() {
    apps = (await request<AppConfig[] | null>(`${orgBase()}/apps`)) ?? [];
    if (!selectedAppId && apps.length > 0) {
      selectedAppId = apps[0].id;
    }
    await loadSelected();
  }

  async function loadSelected() {
    if (!selectedAppId) {
      releases = [];
      patches = [];
      return;
    }
    const app = apps.find((app) => app.id === selectedAppId);
    appNameInput = app?.name ?? '';
    hydrateConfigForm(app);

    releases =
      (await request<ReleaseManifest[] | null>(`${orgBase()}/apps/${encodeURIComponent(selectedAppId)}/releases`)) ?? [];
    patches =
      (await request<PatchManifest[] | null>(`${orgBase()}/apps/${encodeURIComponent(selectedAppId)}/patches`)) ?? [];
    patchStats = {};
    await Promise.all(
      patches.map(async (patch) => {
        const key = patchKey(patch);
        const query = new URLSearchParams({
          release_version: patch.release_version,
          platform: patch.platform,
          arch: patch.arch
        });
        patchStats[key] = await request<PatchStats>(
          `${orgBase()}/apps/${encodeURIComponent(selectedAppId)}/patches/${patch.patch_number}/stats?${query}`
        );
      })
    );

    // Initialize custom rollout percentage for each loaded patch
    patches.forEach(patch => {
      const key = patchKey(patch);
      if (promotePercentages[key] === undefined) {
        promotePercentages[key] = patch.active ? (patch.active_rollout_percentage ?? 100) : 100;
      }
    });

  }

  async function loadTokens() {
    tokens = (await request<Token[] | null>(`${orgBase()}/cli-tokens`)) ?? [];
  }

  async function createApp() {
    await run(async () => {
      await request(`${orgBase()}/apps`, {
        method: 'POST',
        body: JSON.stringify({
          id: newAppId,
          name: newAppName || newAppId,
          channel: 'stable',
          public_key: '',
          platforms: defaultPlatforms()
        })
      });
      showToast(`App "${newAppName || newAppId}" created`);
      newAppName = '';
      newAppId = crypto.randomUUID();
      await loadApps();
    });
  }

  async function updateAppConfig() {
    await run(async () => {
      const app = apps.find(a => a.id === selectedAppId);
      const name = appNameInput || app?.name || selectedAppId;

      await request(`${orgBase()}/apps/${encodeURIComponent(selectedAppId)}`, {
        method: 'PUT',
        body: JSON.stringify({
          id: selectedAppId,
          name,
          channel: channelInput || 'stable',
          public_key: publicKeyInput,
          platforms: formPlatforms()
        })
      });

      isEditingConfig = false;
      showToast("App configuration updated successfully");
      await loadApps();
    });
  }

  async function deleteApp() {
    await run(async () => {
      await request(`${orgBase()}/apps/${encodeURIComponent(selectedAppId)}`, {
        method: 'DELETE'
      });
      const deletedId = selectedAppId;
      selectedAppId = '';
      showDeleteConfirmModal = false;
      showToast(`App ${deletedId} deleted successfully`);
      await loadApps();
    });
  }

  async function promote(patch: PatchManifest, rollout: number) {
    await run(async () => {
      await request(`${orgBase()}/patches/promote`, {
        method: 'POST',
        body: JSON.stringify({
          app_id: patch.app_id,
          release_version: patch.release_version,
          platform: patch.platform,
          arch: patch.arch,
          patch_number: patch.patch_number,
          channel: patch.active_channel || patch.channel,
          rollout_percentage: rollout
        })
      });
      showToast(`Patch #${patch.patch_number} promoted to ${rollout}%`);
      await loadSelected();
    });
  }

  async function rollback(patch: PatchManifest) {
    await run(async () => {
      await request(`${orgBase()}/patches/rollback`, {
        method: 'POST',
        body: JSON.stringify({
          app_id: patch.app_id,
          release_version: patch.release_version,
          platform: patch.platform,
          arch: patch.arch,
          patch_number: patch.patch_number
        })
      });
      showToast(`Patch #${patch.patch_number} rolled back`);
      await loadSelected();
    });
  }

  async function createToken() {
    await run(async () => {
      const token = await request<Token>(`${orgBase()}/cli-tokens`, {
        method: 'POST',
        body: JSON.stringify({ name: tokenName })
      });
      setupToken = token.token ?? '';
      showToast(`CLI Token "${tokenName}" created`);
      await loadTokens();
    });
  }

  async function revokeToken(id: number, name: string) {
    await run(async () => {
      await request(`${orgBase()}/cli-tokens/${id}`, { method: 'DELETE' });
      showToast(`CLI Token "${name}" revoked`);
      await loadTokens();
    });
  }

  async function copyToClipboard(text: string, label: string) {
    try {
      await navigator.clipboard.writeText(text);
      showToast(`${label} copied to clipboard`);
    } catch (err) {
      showToast(`Failed to copy ${label}`);
    }
  }

  function defaultPlatforms(): AppPlatform[] {
    return [
      { platform: 'android', enabled: true, backend: 'snapshot_replace', abi: ['arm64-v8a', 'x86_64'] },
      { platform: 'ios', enabled: true, backend: 'bytecode', abi: [] }
    ];
  }

  function platformEntry(app: AppConfig | undefined, name: string): AppPlatform | undefined {
    return app?.platforms?.find(platform => platform.platform === name);
  }

  function hydrateConfigForm(app: AppConfig | undefined) {
    appNameInput = app?.name ?? '';
    channelInput = app?.channel || 'stable';
    publicKeyInput = app?.public_key || '';
    const android = platformEntry(app, 'android') ?? defaultPlatforms()[0];
    const ios = platformEntry(app, 'ios') ?? defaultPlatforms()[1];
    androidEnabled = android.enabled;
    androidBackend = android.backend || 'snapshot_replace';
    androidAbi = android.abi?.length ? [...android.abi] : ['arm64-v8a', 'x86_64'];
    iosEnabled = ios.enabled;
    iosBackend = ios.backend || 'bytecode';
  }

  function formPlatforms(): AppPlatform[] {
    return [
      { platform: 'android', enabled: androidEnabled, backend: androidBackend, abi: androidAbi },
      { platform: 'ios', enabled: iosEnabled, backend: iosBackend, abi: [] }
    ];
  }

  function toggleAndroidAbi(abi: string, checked: boolean) {
    androidAbi = checked
      ? Array.from(new Set([...androidAbi, abi]))
      : androidAbi.filter(item => item !== abi);
  }

  function shortKey(value: string): string {
    if (!value) return 'No public key registered';
    if (value.length <= 24) return value;
    return `${value.slice(0, 12)}...${value.slice(-8)}`;
  }

  function formatBytes(bytes: number): string {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  function statsFailureTotal(stats: PatchStats): number {
    return (stats.totals.launch_failure ?? 0) + (stats.totals.crash_rollback ?? 0);
  }

  function dayMetric(day: PatchStatsDay, metric: 'install' | 'launch_success' | 'failure'): number {
    if (metric === 'failure') {
      return (day.counts.launch_failure ?? 0) + (day.counts.crash_rollback ?? 0);
    }
    return day.counts[metric] ?? 0;
  }

  function maxDailyMetric(stats: PatchStats): number {
    return Math.max(
      1,
      ...stats.last_7_days.flatMap((day) => [
        dayMetric(day, 'install'),
        dayMetric(day, 'launch_success'),
        dayMetric(day, 'failure')
      ])
    );
  }

  function chartHeight(stats: PatchStats, day: PatchStatsDay, metric: 'install' | 'launch_success' | 'failure'): number {
    return Math.max(4, Math.round((dayMetric(day, metric) / maxDailyMetric(stats)) * 100));
  }

  function shortDate(value: string): string {
    const parts = value.split('-');
    if (parts.length === 3) return `${parts[1]}/${parts[2]}`;
    return value;
  }

  refreshAuth();
</script>

{#if setupRequired}
  <main class="auth-shell">
    <section class="auth-panel">
      <h1>FCB Console Setup</h1>
      <p class="subtitle">Initialize your Fl Codepush Box Admin account</p>

      <label>
        Username
        <input bind:value={setupUsername} />
      </label>
      <label>
        Password
        <input type="password" bind:value={setupPassword} placeholder="••••••••" />
      </label>
      <label>
        Initial CLI Token Name
        <input bind:value={tokenName} />
      </label>
      <button on:click={setup}>Create Admin Account</button>

      {#if error}<p class="error mt-4">{error}</p>{/if}
    </section>
  </main>
{:else if !authenticated}
  <main class="auth-shell">
    <section class="auth-panel">
      <h1>FCB Admin Console</h1>
      <p class="subtitle">Sign in to manage your hot updates</p>

      <label>
        Username
        <input bind:value={loginUsername} />
      </label>
      <label>
        Password
        <input type="password" bind:value={loginPassword} placeholder="••••••••" on:keydown={(e) => e.key === 'Enter' && login()} />
      </label>
      <button on:click={login}>Sign In</button>

      {#if error}<p class="error mt-4">{error}</p>{/if}
    </section>
  </main>
{:else}
  <main class="layout">
    <aside>
      <div class="brand">
        <div class="brand-logo">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path><polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline><line x1="12" y1="22.08" x2="12" y2="12"></line></svg>
        </div>
        <span class="brand-text">FCB Console</span>
      </div>

      <div class="user-profile">
        <div class="user-avatar">
          {username.substring(0, 2).toUpperCase()}
        </div>
        <div class="user-info">
          <span class="user-name">{username}</span>
          <span class="user-role">Administrator</span>
        </div>
      </div>

      <div class="create-app-card">
        <h4>
          <span>Organization</span>
        </h4>
        <label>
          Active Org
          <select bind:value={selectedOrgId} on:change={loadOrgScoped}>
            {#each orgs as org}
              <option value={org.id}>{org.name || org.id}</option>
            {/each}
          </select>
        </label>
        <input placeholder="Org ID (e.g. acme)" bind:value={newOrgId} />
        <input placeholder="Org Name" bind:value={newOrgName} />
        <button on:click={createOrg}>
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
          Add Org
        </button>
      </div>

      <div class="create-app-card">
        <h4>
          <span>New Application</span>
        </h4>
        <input placeholder="App Name (e.g. Flutter Demo)" bind:value={newAppName} />
        <input placeholder="App ID (e.g. com.example.app)" bind:value={newAppId} />
        <button on:click={createApp}>
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
          Add App
        </button>
      </div>

      <div class="sidebar-nav-container">
        <div class="sidebar-section-title">Applications</div>
        <nav>
          {#each apps as app}
            <button class:active={app.id === selectedAppId} on:click={() => { selectedAppId = app.id; loadSelected(); }}>
              <span>{app.name}</span>
              <small>{app.id}</small>
            </button>
          {/each}
        </nav>
      </div>

      <button class="secondary" style="margin-top: auto; width: 100%;" on:click={logout}>
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
        Sign Out
      </button>
    </aside>

    <section class="content">
      {#if successToast}
        <div class="alert-banner success">
          <span class="alert-banner-icon">✓</span>
          <span>{successToast}</span>
          <button class="alert-banner-close" on:click={() => successToast = ''}>✕</button>
        </div>
      {/if}

      <header class="content-header">
        <div>
          <h1>
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="var(--color-primary)" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" style="align-self: center;"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line></svg>
            {apps.find((app) => app.id === selectedAppId)?.name ?? 'Apps Console'}
          </h1>
          {#if selectedAppId}
            <div class="app-id-display">
              ID: {selectedAppId}
              <button class="copy-icon-btn" title="Copy App ID" on:click={() => copyToClipboard(selectedAppId, 'App ID')}>
                <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
              </button>
            </div>
          {/if}
        </div>
        <div class="header-actions">
          {#if selectedAppId}
            <button class="danger" on:click={() => showDeleteConfirmModal = true}>
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
              Delete App
            </button>
          {/if}
          <button on:click={loadSelected}>
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 4v6h-6"></path><path d="M1 20v-6h6"></path><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path></svg>
            Refresh
          </button>
        </div>
      </header>

      {#if selectedAppId}
        <section class="stats-grid">
          <div class="stat-card">
            <div class="stat-icon primary">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><ellipse cx="12" cy="5" rx="9" ry="3"></ellipse><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"></path><path d="M3 12c0 1.66 4 3 9 3s9-1.34 9-3"></path></svg>
            </div>
            <div class="stat-info">
              <span class="stat-label">Releases</span>
              <span class="stat-value">{releases.length}</span>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon accent">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z"></path><path d="M12 6v6l4 2"></path></svg>
            </div>
            <div class="stat-info">
              <span class="stat-label">Patches</span>
              <span class="stat-value">{patches.length}</span>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon success">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
            </div>
            <div class="stat-info">
              <span class="stat-label">Active Patches</span>
              <span class="stat-value">{patches.filter(p => p.active).length}</span>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon primary">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M22 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
            </div>
            <div class="stat-info">
              <span class="stat-label">Members</span>
              <span class="stat-value">{members.length}</span>
            </div>
          </div>
        </section>

        <div class="collapsible-card">
          <div
            class="collapsible-header"
            role="button"
            tabindex="0"
            on:click={() => showConfig = !showConfig}
            on:keydown={(e) => e.key === 'Enter' && (showConfig = !showConfig)}
          >
            <h2>
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--color-accent)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="align-self: center;"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>
              App Configuration
            </h2>
            <span class="collapsible-header-indicator" class:open={showConfig}>
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg>
            </span>
          </div>
          {#if showConfig}
            <div class="collapsible-body">
              <div class="config-editor-layout">
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
                  <label>
                    App Display Name
                    <input bind:value={appNameInput} disabled={!isEditingConfig} placeholder="Enter app name" />
                  </label>
                  <label style="justify-content: end;">
                    <span>&nbsp;</span>
                    {#if !isEditingConfig}
                      <button class="secondary" style="width: fit-content; align-self: flex-end;" on:click={() => isEditingConfig = true}>
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 1 1 3 3L12 15l-4 1 1-4z"></path></svg>
                        Edit Config
                      </button>
                    {/if}
                  </label>
                </div>

                <div class="config-form-grid">
                  <label>
                    Channel
                    <input bind:value={channelInput} disabled={!isEditingConfig} placeholder="stable" />
                  </label>

                  <label>
                    Public Key
                    <div class="copyable-field public-key-field">
                      <span class="hash-display" title={publicKeyInput}>{shortKey(publicKeyInput)}</span>
                      {#if publicKeyInput}
                        <button class="copy-icon-btn" title="Copy public key" on:click={() => copyToClipboard(publicKeyInput, 'Public Key')}>
                          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
                        </button>
                      {/if}
                    </div>
                  </label>
                </div>

                <div class="platform-config-grid">
                  <section class="platform-panel">
                    <div class="platform-panel-header">
                      <h3>Android</h3>
                      <label class="toggle-row">
                        <input type="checkbox" bind:checked={androidEnabled} disabled={!isEditingConfig} />
                        Enabled
                      </label>
                    </div>
                    <label>
                      Backend
                      <select bind:value={androidBackend} disabled={!isEditingConfig}>
                        <option value="snapshot_replace">snapshot_replace</option>
                        <option value="bytecode">bytecode</option>
                      </select>
                    </label>
                    <div class="checkbox-group">
                      <span>ABI</span>
                      {#each androidAbiOptions as abi}
                        <label class="checkbox-row">
                          <input
                            type="checkbox"
                            checked={androidAbi.includes(abi)}
                            disabled={!isEditingConfig}
                            on:change={(e) => toggleAndroidAbi(abi, e.currentTarget.checked)}
                          />
                          {abi}
                        </label>
                      {/each}
                    </div>
                  </section>

                  <section class="platform-panel">
                    <div class="platform-panel-header">
                      <h3>iOS</h3>
                      <label class="toggle-row">
                        <input type="checkbox" bind:checked={iosEnabled} disabled={!isEditingConfig} />
                        Enabled
                      </label>
                    </div>
                    <label>
                      Backend
                      <select bind:value={iosBackend} disabled={!isEditingConfig}>
                        <option value="snapshot_replace">snapshot_replace</option>
                        <option value="bytecode">bytecode</option>
                      </select>
                    </label>
                  </section>
                </div>

                {#if isEditingConfig}
                  <div class="config-actions">
                    <button class="secondary" on:click={() => {
                      isEditingConfig = false;
                      const app = apps.find(a => a.id === selectedAppId);
                      hydrateConfigForm(app);
                    }}>Cancel</button>
                    <button on:click={updateAppConfig}>Save Changes</button>
                  </div>
                {/if}
              </div>
            </div>
          {/if}
        </div>

        <section class="dashboard-grid">
          <!-- Patches Card -->
          <article class="glass-card">
            <h2>
              <span class="title-icon">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="align-self: center;"><path d="M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z"></path><path d="M12 6v6l4 2"></path></svg>
                Patches
              </span>
            </h2>

            {#if patches.length === 0}
              <p style="color: var(--text-muted); text-align: center; padding: 24px;">No patches created for this app yet.</p>
            {:else}
              <div class="custom-table patches-table">
                <div class="table-row header">
                  <span>Release</span>
                  <span>Patch</span>
                  <span>Target Info</span>
                  <span>Rollout Progress</span>
                  <span style="text-align: right;">Actions</span>
                </div>
                {#each patches as patch}
                  {@const key = patchKey(patch)}
                  {@const stats = patchStats[key]}
                  <div class="table-row">
                    <div>
                      <span class="badge version" title="Release Version">{patch.release_version}</span>
                    </div>
                    <div>
                      <span class="badge patch-num" title="Patch Number">#{patch.patch_number}</span>
                    </div>
                    <div>
                      <div style="font-weight: 500;">{patch.platform}</div>
                      <div style="font-size: 11px; color: var(--text-muted); font-family: var(--font-mono);">{patch.arch}</div>
                    </div>
                    <div class="rollout-wrapper">
                      <div style="display: flex; justify-content: space-between; font-size: 11px;">
                        {#if patch.active}
                          <span class="text-success" style="font-weight: 600;">Active</span>
                          <span class="badge rollout active">{patch.active_rollout_percentage ?? 0}%</span>
                        {:else}
                          <span class="text-danger" style="font-weight: 600;">Disabled</span>
                          <span class="badge rollout inactive">Off</span>
                        {/if}
                      </div>
                      <div class="rollout-progress-container">
                        <div
                          class="rollout-progress-bar"
                          class:inactive={!patch.active}
                          style="width: {patch.active ? (patch.active_rollout_percentage ?? 0) : 0}%"
                        ></div>
                      </div>
                    </div>
                    <div class="actions-cell" style="flex-wrap: wrap;">
                      <div class="promote-box">
                        <div class="promote-slider-row">
                          <input
                            type="range"
                            min="0"
                            max="100"
                            step="5"
                            bind:value={promotePercentages[key]}
                          />
                          <span>{promotePercentages[key] ?? 100}%</span>
                        </div>
                        <div class="promote-presets">
                          <button on:click={() => { promotePercentages[key] = 10; promote(patch, 10); }}>10%</button>
                          <button on:click={() => { promotePercentages[key] = 50; promote(patch, 50); }}>50%</button>
                          <button on:click={() => { promotePercentages[key] = 100; promote(patch, 100); }}>100%</button>
                          <button class="secondary" on:click={() => promote(patch, promotePercentages[key] ?? 100)}>Set</button>
                        </div>
                      </div>
                      {#if patch.active}
                        <button class="danger" style="min-height: auto; height: 34px; padding: 0 10px;" on:click={() => rollback(patch)}>
                          Rollback
                        </button>
                      {/if}
                      {#if stats}
                        <div class="patch-stats-panel">
                          <div class="patch-stats-totals">
                            <span>install {stats.totals.install ?? 0}</span>
                            <span>success {stats.totals.launch_success ?? 0}</span>
                            <span>failure {statsFailureTotal(stats)}</span>
                          </div>
                          {#if stats.last_7_days.length > 0}
                            <div class="patch-stats-chart" aria-label="Last 7 days patch events">
                              {#each stats.last_7_days as day}
                                <div class="patch-stats-day" title={`${day.date}: install ${dayMetric(day, 'install')}, success ${dayMetric(day, 'launch_success')}, failure ${dayMetric(day, 'failure')}`}>
                                  <div class="patch-stats-bars">
                                    <span class="bar install" style="height: {chartHeight(stats, day, 'install')}%"></span>
                                    <span class="bar success" style="height: {chartHeight(stats, day, 'launch_success')}%"></span>
                                    <span class="bar failure" style="height: {chartHeight(stats, day, 'failure')}%"></span>
                                  </div>
                                  <small>{shortDate(day.date)}</small>
                                </div>
                              {/each}
                            </div>
                          {/if}
                          {#if stats.top_failures.length > 0}
                            <div class="top-failures-list">
                              {#each stats.top_failures as failure}
                                <div>
                                  <span>{failure.reason}</span>
                                  <strong>{failure.count}</strong>
                                </div>
                              {/each}
                            </div>
                          {/if}
                        </div>
                      {/if}
                    </div>
                  </div>
                {/each}
              </div>
            {/if}
          </article>

          <!-- Releases Card -->
          <article class="glass-card">
            <h2>
              <span class="title-icon">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="align-self: center;"><ellipse cx="12" cy="5" rx="9" ry="3"></ellipse><path d="M3 5v14c0 1.66 4 3 9 3s9-1.34 9-3V5"></path><path d="M3 12c0 1.66 4 3 9 3s9-1.34 9-3"></path></svg>
                Releases
              </span>
            </h2>

            {#if releases.length === 0}
              <p style="color: var(--text-muted); text-align: center; padding: 24px;">No releases uploaded for this app.</p>
            {:else}
              <div class="custom-table releases-table">
                <div class="table-row header">
                  <span>Version</span>
                  <span>Target / Arch</span>
                  <span>Backend</span>
                  <span>Hash & Size</span>
                </div>
                {#each releases as release}
                  <div class="table-row">
                    <div>
                      <span class="badge version">{release.release_version}</span>
                    </div>
                    <div>
                      <div style="font-weight: 500;">{release.platform}</div>
                      <div style="font-size: 11px; color: var(--text-muted); font-family: var(--font-mono);">{release.arch}</div>
                    </div>
                    <div>
                      <span class="badge backend">{release.backend}</span>
                    </div>
                    <div>
                      <div class="copyable-field">
                        <span class="hash-display" title={release.artifact_hash}>
                          {release.artifact_hash}
                        </span>
                        <button class="copy-icon-btn" title="Copy full hash" on:click={() => copyToClipboard(release.artifact_hash, 'Artifact Hash')}>
                          <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path></svg>
                        </button>
                      </div>
                      <div style="font-size: 11px; color: var(--text-muted); margin-top: 4px;">
                        {formatBytes(release.artifact_size)}
                      </div>
                    </div>
                  </div>
                {/each}
              </div>
            {/if}
          </article>

          <!-- Org Members Card -->
          <article class="glass-card full-width">
            <h2>
              <span class="title-icon">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="align-self: center;"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><line x1="19" y1="8" x2="19" y2="14"></line><line x1="22" y1="11" x2="16" y2="11"></line></svg>
                Organization Members
              </span>
            </h2>

            <div class="token-tools-modern">
              <label style="flex: 1;">
                Username
                <input bind:value={memberUsername} placeholder="teammate" />
              </label>
              <label style="width: 160px;">
                Role
                <select bind:value={memberRole}>
                  <option value="member">member</option>
                  <option value="admin">admin</option>
                  <option value="owner">owner</option>
                </select>
              </label>
              <button on:click={addMember}>
                Add Member
              </button>
            </div>

            {#if members.length === 0}
              <p style="color: var(--text-muted); text-align: center; padding: 24px;">No members in this org.</p>
            {:else}
              <div class="custom-table tokens-table">
                <div class="table-row header">
                  <span>Username</span>
                  <span>Role</span>
                  <span>Joined</span>
                  <span style="text-align: right;">Action</span>
                </div>
                {#each members as member}
                  <div class="table-row">
                    <div style="font-weight: 600; color: var(--color-accent);">
                      {member.username || member.user_id}
                    </div>
                    <div>
                      <select value={member.role} on:change={(e) => updateMemberRole(member, e.currentTarget.value)}>
                        <option value="member">member</option>
                        <option value="admin">admin</option>
                        <option value="owner">owner</option>
                      </select>
                    </div>
                    <div style="color: var(--text-secondary);">
                      {member.created_at ? new Date(member.created_at).toLocaleString() : ''}
                    </div>
                    <div class="actions-cell">
                      <button class="danger secondary" on:click={() => removeMember(member)}>
                        Remove
                      </button>
                    </div>
                  </div>
                {/each}
              </div>
            {/if}
          </article>

          <!-- CLI Tokens Card -->
          <article class="glass-card full-width">
            <h2>
              <span class="title-icon">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="align-self: center;"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect><path d="M7 11V7a5 5 0 0 1 10 0v4"></path></svg>
                CLI Developer Tokens
              </span>
            </h2>

            <div class="token-tools-modern">
              <label style="flex: 1;">
                New Token Description/Name
                <input bind:value={tokenName} placeholder="local-cli-dev" />
              </label>
              <button on:click={createToken}>
                Create CLI Token
              </button>
            </div>

            {#if tokens.length === 0}
              <p style="color: var(--text-muted); text-align: center; padding: 24px;">No active CLI tokens.</p>
            {:else}
              <div class="custom-table tokens-table">
                <div class="table-row header">
                  <span>Token Name</span>
                  <span>Created Date</span>
                  <span style="text-align: right;">Action</span>
                </div>
                {#each tokens as token}
                  <div class="table-row">
                    <div style="font-weight: 600; color: var(--color-accent);">
                      {token.name}
                    </div>
                    <div style="color: var(--text-secondary);">
                      {new Date(token.created_at).toLocaleString()}
                    </div>
                    <div class="actions-cell">
                      <button class="danger secondary" on:click={() => revokeToken(token.id, token.name)}>
                        Revoke
                      </button>
                    </div>
                  </div>
                {/each}
              </div>
            {/if}
          </article>
        </section>
      {:else}
        <!-- No Apps State -->
        <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 50vh; text-align: center; gap: 16px;">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="var(--text-muted)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect><line x1="8" y1="21" x2="16" y2="21"></line><line x1="12" y1="17" x2="12" y2="21"></line></svg>
          <div>
            <h3>No Application Selected</h3>
            <p style="max-width: 380px; margin-top: 8px;">Create an application in the sidebar or select an existing one to manage updates, releases, and patches.</p>
          </div>
        </div>
      {/if}
    </section>
  </main>
{/if}

<!-- Modals -->

<!-- Delete App confirmation Modal -->
{#if showDeleteConfirmModal}
  <div class="modal-overlay">
    <div class="modal-content">
      <h3 class="modal-title text-danger">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
        Delete Application?
      </h3>
      <p>Are you sure you want to delete the application <strong>{apps.find(a => a.id === selectedAppId)?.name || selectedAppId}</strong>?</p>
      <p style="color: var(--text-muted); font-size: 13px;">This action cannot be undone. All releases and patches for this app will be deleted permanently from the server.</p>
      <div class="modal-actions">
        <button class="secondary" on:click={() => showDeleteConfirmModal = false}>Cancel</button>
        <button class="danger" on:click={deleteApp}>Confirm Delete</button>
      </div>
    </div>
  </div>
{/if}

<!-- Setup Token Presentation Modal -->
{#if setupToken}
  <div class="modal-overlay">
    <div class="modal-content" style="border-color: var(--color-accent);">
      <h3 class="modal-title" style="color: var(--color-accent);">
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path><polyline points="22 4 12 14.01 9 11.01"></polyline></svg>
        Token Generated
      </h3>
      <p>Please copy this CLI access token. <strong>It will not be displayed again!</strong></p>

      <div class="token-presentation-box">
        <h4>Access Token</h4>
        <div class="token-presentation-text">{setupToken}</div>
      </div>

      <div class="modal-actions">
        <button class="secondary" on:click={() => copyToClipboard(setupToken, 'Token')}>
          Copy to Clipboard
        </button>
        <button on:click={() => { setupToken = ''; refreshAuth(); }}>
          Done
        </button>
      </div>
    </div>
  </div>
{/if}
