# plex-autoskip Helm chart

Unofficial Helm chart for **[PlexAutoSkip](https://github.com/mdhiggins/PlexAutoSkip)** — automatically skip intros, commercials, and credits in Plex. This chart packages the [official Docker image](https://github.com/mdhiggins/plexautoskip-docker) using the [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/app-template).

## Upstream tooling

- **PlexAutoSkip** (Python): [mdhiggins/PlexAutoSkip](https://github.com/mdhiggins/PlexAutoSkip) — monitors Plex playback and sends skip/seek commands.
- **Docker image**: [ghcr.io/mdhiggins/plexautoskip-docker](https://github.com/mdhiggins/plexautoskip-docker) — headless, no HTTP server.
- **Configuration**: [PlexAutoSkip Configuration wiki](https://github.com/mdhiggins/PlexAutoSkip/wiki/Configuration) — `config.ini`, `custom.json`, and optional `logging.ini`.

## Quick start

```bash
helm repo add <your-repo> https://<your-org>.github.io/<your-repo>
helm install plex-auto-skip <your-repo>/plex-auto-skip -f values.yaml
```

Or from this repo (after clone):

```bash
helm dependency update .
helm install plex-auto-skip . -f values.yaml
```

## Setup and configuration

PlexAutoSkip is headless (no Service/Ingress). It needs a writable **config** directory mounted at `/config` containing:

1. **`config.ini`** — Required. Plex credentials and skip options.
2. **`custom.json`** (optional) — Per-title markers, offsets, and allow/block lists.
3. **`logging.ini`** (optional) — Log level and output.

### 1. Create `config.ini`

Copy the [sample](https://github.com/mdhiggins/PlexAutoSkip/blob/main/setup/config.ini.sample) or create a default (the container can create one on first run). Minimal example:

```ini
[Plex]
username = your_plex_username
password = your_plex_password
# Or use token instead if you use 2FA:
# token = your_plex_token
servername = Your Plex Server Name

[Server]
address = 192.168.1.10
ssl = True
port = 32400

[Skip]
mode = skip
tags = intro, commercial, advertisement, credits
types = movie, episode
last-chapter = 0.9
unwatched = True
```

See the [Configuration wiki](https://github.com/mdhiggins/PlexAutoSkip/wiki/Configuration) for all options (offsets, binge behavior, volume mode, etc.).

### 2. Provide config to the chart

- **Option A — PVC (default)**  
  The chart creates a PVC for `/config`. After install, copy `config.ini` (and optional `custom.json`) into the volume (e.g. via a temporary pod or `kubectl cp` from a generated ConfigMap/Secret).

- **Option B — Existing PVC**  
  Set persistence to use an existing claim:

  ```yaml
  skip:
    persistence:
      config:
        enabled: true
        type: persistentVolumeClaim
        existingClaim: my-plex-autoskip-config
  ```

- **Option C — ConfigMap / Secret (e.g. External Secrets)**  
  Mount config from a Secret or ConfigMap:

  ```yaml
  skip:
    persistence:
      config:
        enabled: true
        type: secret
        name: plex-autoskip-config
  ```

  Ensure the Secret/ConfigMap has a key that mounts as `config.ini` (and optionally `custom.json`) under `/config`.

### 3. Plex requirements

- **Local network discovery (GDM)** should be enabled in Plex Server settings so PlexAutoSkip can discover and control playback.
- **Token**: If using 2FA, use a [Plex token](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/) in `config.ini` instead of password.

## Chart options (values)

| Area | Key | Description |
|------|-----|-------------|
| Image | `skip.controllers.main.containers.main.image` | Default: `ghcr.io/mdhiggins/plexautoskip-docker:latest` (or version-matched on release). |
| Env | `skip.controllers.main.containers.main.env` | `PUID`, `PGID`, `TZ`, `PAS_PATH`, `PAS_UPDATE`, `LSIO_NON_ROOT_USER`. |
| Persistence | `skip.persistence.config` | PVC size, `existingClaim`, or `type: secret` / `type: configMap` with `name`. |
| Resources | `skip.controllers.main.containers.main.resources` | CPU/memory requests and limits. |

The chart runs the container as non-root (e.g. 911/911) with `LSIO_NON_ROOT_USER=true` and no Service/Ingress by default.

## CI/CD and publishing

- **Release on merge**: Pushing to `main` (chart files only) runs `helm lint`, bumps patch version, creates a tag and GitHub Release.
- **Helm publish**: On release, the workflow packages the chart and attaches the tarball to the release.
- See [.github/workflows/README.md](.github/workflows/README.md) for details and manual triggers.

## Links

- [PlexAutoSkip](https://github.com/mdhiggins/PlexAutoSkip)
- [PlexAutoSkip Configuration](https://github.com/mdhiggins/PlexAutoSkip/wiki/Configuration)
- [plexautoskip-docker](https://github.com/mdhiggins/plexautoskip-docker)
- [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/app-template)
