<script lang="ts">
  type AppConfig = {
    id: string;
    name: string;
    config?: Record<string, unknown>;
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
    name: string;
    token?: string;
    created_at: string;
  };

  let setupRequired = true;
  let authenticated = false;
  let username = '';
  let apps: AppConfig[] = [];
  let selectedAppId = '';
  let releases: ReleaseManifest[] = [];
  let patches: PatchManifest[] = [];
  let tokens: Token[] = [];
  let error = '';
  let setupToken = '';

  let setupUsername = 'admin';
  let setupPassword = '';
  let loginUsername = 'admin';
  let loginPassword = '';
  let newAppName = '';
  let newAppId = crypto.randomUUID();
  let tokenName = 'local-cli';

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
        await loadApps();
        await loadTokens();
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
    });
  }

  async function login() {
    await run(async () => {
      await request('/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ username: loginUsername, password: loginPassword })
      });
      await refreshAuth();
    });
  }

  async function logout() {
    await request('/api/auth/logout', { method: 'POST', body: '{}' });
    authenticated = false;
  }

  async function loadApps() {
    apps = (await request<AppConfig[] | null>('/api/admin/apps')) ?? [];
    if (!selectedAppId && apps.length > 0) selectedAppId = apps[0].id;
    await loadSelected();
  }

  async function loadSelected() {
    if (!selectedAppId) {
      releases = [];
      patches = [];
      return;
    }
    releases =
      (await request<ReleaseManifest[] | null>(`/api/admin/apps/${encodeURIComponent(selectedAppId)}/releases`)) ?? [];
    patches =
      (await request<PatchManifest[] | null>(`/api/admin/apps/${encodeURIComponent(selectedAppId)}/patches`)) ?? [];
  }

  async function loadTokens() {
    tokens = (await request<Token[] | null>('/api/admin/tokens')) ?? [];
  }

  async function createApp() {
    await run(async () => {
      await request('/api/admin/apps', {
        method: 'POST',
        body: JSON.stringify({ id: newAppId, name: newAppName || newAppId, config: {} })
      });
      newAppName = '';
      newAppId = crypto.randomUUID();
      await loadApps();
    });
  }

  async function promote(patch: PatchManifest, rollout: number) {
    await run(async () => {
      await request('/api/admin/patches/promote', {
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
      await loadSelected();
    });
  }

  async function rollback(patch: PatchManifest) {
    await run(async () => {
      await request('/api/admin/patches/rollback', {
        method: 'POST',
        body: JSON.stringify({
          app_id: patch.app_id,
          release_version: patch.release_version,
          platform: patch.platform,
          arch: patch.arch,
          patch_number: patch.patch_number
        })
      });
      await loadSelected();
    });
  }

  async function createToken() {
    await run(async () => {
      const token = await request<Token>('/api/admin/tokens', {
        method: 'POST',
        body: JSON.stringify({ name: tokenName })
      });
      setupToken = token.token ?? '';
      await loadTokens();
    });
  }

  async function revokeToken(id: number) {
    await run(async () => {
      await request(`/api/admin/tokens/${id}`, { method: 'DELETE' });
      await loadTokens();
    });
  }

  refreshAuth();
</script>

{#if setupRequired}
  <main class="auth-shell">
    <section class="auth-panel">
      <h1>FCB Admin Setup</h1>
      <label>Username<input bind:value={setupUsername} /></label>
      <label>Password<input type="password" bind:value={setupPassword} /></label>
      <label>CLI token name<input bind:value={tokenName} /></label>
      <button on:click={setup}>Create admin</button>
      {#if setupToken}<pre class="token">{setupToken}</pre>{/if}
      {#if error}<p class="error">{error}</p>{/if}
    </section>
  </main>
{:else if !authenticated}
  <main class="auth-shell">
    <section class="auth-panel">
      <h1>FCB Admin</h1>
      <label>Username<input bind:value={loginUsername} /></label>
      <label>Password<input type="password" bind:value={loginPassword} /></label>
      <button on:click={login}>Sign in</button>
      {#if setupToken}<pre class="token">{setupToken}</pre>{/if}
      {#if error}<p class="error">{error}</p>{/if}
    </section>
  </main>
{:else}
  <main class="layout">
    <aside>
      <div class="brand">
        <strong>FCB</strong>
        <span>{username}</span>
      </div>
      <div class="create">
        <input placeholder="App name" bind:value={newAppName} />
        <input placeholder="App id" bind:value={newAppId} />
        <button on:click={createApp}>Add app</button>
      </div>
      <nav>
        {#each apps as app}
          <button class:active={app.id === selectedAppId} on:click={() => { selectedAppId = app.id; loadSelected(); }}>
            <span>{app.name}</span>
            <small>{app.id}</small>
          </button>
        {/each}
      </nav>
      <button class="secondary" on:click={logout}>Sign out</button>
    </aside>

    <section class="content">
      {#if error}<p class="error">{error}</p>{/if}
      <header>
        <div>
          <h1>{apps.find((app) => app.id === selectedAppId)?.name ?? 'Apps'}</h1>
          <p>{selectedAppId}</p>
        </div>
        <button on:click={loadSelected}>Refresh</button>
      </header>

      <section class="grid">
        <article>
          <h2>Patches</h2>
          <div class="table">
            <div class="row head"><span>Release</span><span>Patch</span><span>Target</span><span>Rollout</span><span></span></div>
            {#each patches as patch}
              <div class="row">
                <span>{patch.release_version}</span>
                <span>#{patch.patch_number}</span>
                <span>{patch.platform}/{patch.arch}</span>
                <span>{patch.active ? `${patch.active_rollout_percentage ?? 0}%` : 'off'}</span>
                <span class="actions">
                  <button on:click={() => promote(patch, 100)}>100%</button>
                  <button on:click={() => promote(patch, 10)}>10%</button>
                  <button class="secondary" on:click={() => rollback(patch)}>Off</button>
                </span>
              </div>
            {/each}
          </div>
        </article>

        <article>
          <h2>Releases</h2>
          <div class="table">
            <div class="row head"><span>Version</span><span>Target</span><span>Backend</span><span>Size</span></div>
            {#each releases as release}
              <div class="row">
                <span>{release.release_version}</span>
                <span>{release.platform}/{release.arch}</span>
                <span>{release.backend}</span>
                <span>{release.artifact_size}</span>
              </div>
            {/each}
          </div>
        </article>

        <article>
          <h2>CLI Tokens</h2>
          <div class="token-tools">
            <input bind:value={tokenName} />
            <button on:click={createToken}>Create token</button>
          </div>
          {#if setupToken}<pre class="token">{setupToken}</pre>{/if}
          <div class="table">
            {#each tokens as token}
              <div class="row">
                <span>{token.name}</span>
                <span>{new Date(token.created_at).toLocaleString()}</span>
                <span class="actions"><button class="secondary" on:click={() => revokeToken(token.id)}>Revoke</button></span>
              </div>
            {/each}
          </div>
        </article>
      </section>
    </section>
  </main>
{/if}
