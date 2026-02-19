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

PlexAutoSkip is headless (no Service/Ingress). It needs a **config** directory mounted at `/config` containing:

1. **`config.ini`** — Required. Plex credentials and skip options.
2. **`custom.json`** (optional) — Per-title markers, offsets, and allow/block lists.
3. **`logging.ini`** (optional) — Log level and output.

### This chart: PVC mount only

This **base chart** does **not** generate config files. It only runs the app and mounts a **volume at `/config`**. By default that volume is a **PersistentVolumeClaim** (100Mi, ReadWriteOnce). You can override `persistence.config` to mount a ConfigMap or Secret instead (e.g. when used as a subchart and the parent provides config).

- **As a subchart of the plex chart:** The **parent** (`homelab/helm/plex`) creates the config (ConfigMap, Secret, or ExternalSecret) from file templates and overrides `skip.persistence.config` (e.g. `type: secret`, `name: plex-auto-skip`) so this chart mounts that resource at `/config`. See the **plex** chart’s values and README for `skip.plexAutoskipConfig`, `skip.config`, `skip.logging`, `skip.customJson`, and Reloader.
- **Standalone:** Provide config yourself. Either use the default PVC and copy `config.ini` (and optional `logging.ini`, `custom.json`) into the volume (e.g. via a job or `kubectl cp`), or set `persistence.config` to an existing ConfigMap/Secret that you create elsewhere.

### Default: PVC at /config

Default `persistence.config`:

- `type: persistentVolumeClaim`
- `accessMode: ReadWriteOnce`
- `size: 100Mi`
- Mount path: `/config`

Override `skip.persistence.config` in your values (or from the parent chart) to use a ConfigMap or Secret instead.

### Using an existing PVC (standalone)

Use an existing PVC and put your config files in it (e.g. via a job or `kubectl cp`):

```yaml
skip:
  persistence:
    config:
      enabled: true
      type: persistentVolumeClaim
      existingClaim: my-plex-autoskip-config
```

### Plex requirements

- **Local network discovery (GDM)** should be enabled in Plex Server settings so PlexAutoSkip can discover and control playback.
- **Token**: If using 2FA, use a [Plex token](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/) in `config.ini` instead of password.

## Chart options (values)

| Area | Key | Description |
|------|-----|-------------|
| Persistence | `skip.persistence.config` | Volume at `/config`. Default: PVC (100Mi, ReadWriteOnce). Override with `type: configMap` or `type: secret` and `name` when the parent (or you) provides config via ConfigMap/Secret. |
| Image | `skip.controllers.main.containers.main.image` | Default: `ghcr.io/mdhiggins/plexautoskip-docker:latest` (or version-matched on release). |
| Env | `skip.controllers.main.containers.main.env` | `PUID`, `PGID`, `TZ`, `PAS_PATH`, `PAS_UPDATE`, `LSIO_NON_ROOT_USER`. |
| Pod options | `skip.defaultPodOptions` | Affinity, annotations (e.g. Reloader). Parent chart may set Reloader for the config resource it mounts. |
| Resources | `skip.controllers.main.containers.main.resources` | CPU/memory requests and limits. |

The chart runs the container as non-root (e.g. 911/911) with `LSIO_NON_ROOT_USER=true` and no Service/Ingress by default. Config file generation (ConfigMap/Secret/ExternalSecret) is **not** in this chart; when used under the **plex** chart, the parent provides config and overrides `skip.persistence.config`.

## CI/CD and publishing

- **Release on merge**: Pushing to `main` (chart files only) runs `helm lint`, bumps patch version, creates a tag and GitHub Release.
- **Helm publish**: On release, the workflow packages the chart and attaches the tarball to the release.
- See [.github/workflows/README.md](.github/workflows/README.md) for details and manual triggers.

## Links

- [PlexAutoSkip](https://github.com/mdhiggins/PlexAutoSkip)
- [PlexAutoSkip Configuration](https://github.com/mdhiggins/PlexAutoSkip/wiki/Configuration)
- [plexautoskip-docker](https://github.com/mdhiggins/plexautoskip-docker)
- [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/app-template)
