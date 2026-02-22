# plex-autoskip Helm chart

Unofficial Helm chart for **[PlexAutoSkip](https://github.com/mdhiggins/PlexAutoSkip)** — automatically skip intros, commercials, and credits in Plex. This chart packages the [official Docker image](https://github.com/mdhiggins/plexautoskip-docker) using the [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/app-template).

## Upstream tooling

- **PlexAutoSkip** (Python): [mdhiggins/PlexAutoSkip](https://github.com/mdhiggins/PlexAutoSkip) — monitors Plex playback and sends skip/seek commands.
- **Docker image**: [ghcr.io/mdhiggins/plexautoskip-docker](https://github.com/mdhiggins/plexautoskip-docker) — headless, no HTTP server.
- **Configuration**: [PlexAutoSkip Configuration wiki](https://github.com/mdhiggins/PlexAutoSkip/wiki/Configuration) — `config.ini`, `custom.json`, and optional `logging.ini`.

## HA (multiple replicas)

When `skip.controllers.main.replicas` is set to 2 or more, the chart applies **soft pod anti-affinity** (preferred, `topologyKey: kubernetes.io/hostname`) so pods prefer different nodes. Same pattern as nextcloud, reloader, and nginx. Override `skip.defaultPodOptions.affinity` if you need different scheduling.

## Requirements (when using External Secrets)

| Dependency | Notes |
|------------|--------|
| **External Secrets Operator** | ClusterSecretStore (e.g. **onepassword-connect**) in the cluster. |
| **1Password item** | Item (default title **plex**) with a field **token** (Plex auth token). Use `op item get "plex" --vault Kubernetes` to add or verify. |

## Argo CD

Deploy via Argo CD. Example Application (adjust repo/path/namespace):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: plex-autoskip
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/expectedbehaviors/plex-autoskip-helm-chart
    path: .
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: media-server
  syncPolicy:
    automated: { prune: true, selfHeal: true }
```

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

### Config from 1Password (External Secrets)

When **`externalSecrets.enabled: true`** (default), the chart creates an **ExternalSecret** that fetches your Plex token from 1Password (item **plex**, property **token**) and generates config.ini, logging.ini, and custom.json into Secret **plex-auto-skip** at `/config`. Requires ESO and ClusterSecretStore (e.g. onepassword-connect). In 1Password add item **plex** with field **token** (Plex auth token). Set `externalSecrets.enabled: false` to use PVC or parent-provided config.

### Skip rules (defaults)

Always skipped: advertisements, episode previews, commercials, intro, credits, outro. TV Binge: first episode of session shows intro, then skip (session-based). Movies: same tags; typically only ads/preview/FBI.

### This chart: PVC or Secret

This chart can generate config (when ExternalSecret enabled) or use a volume. It only runs the app and mounts a **volume at `/config`**. By default that volume is a **PersistentVolumeClaim** (100Mi, ReadWriteOnce). **Volumes are defined in Longhorn** when using PVC; or override `persistence.config` to mount a ConfigMap or Secret (e.g. when used as a subchart and the parent provides config).

- **As a subchart of the plex chart:** The **parent** (`homelab/helm/plex`) creates the config (ConfigMap, Secret, or ExternalSecret) from file templates and overrides `skip.persistence.config` (e.g. `type: secret`, `name: plex-auto-skip`) so this chart mounts that resource at `/config`. See the **plex** chart’s values and README for `skip.plexAutoskipConfig`, `skip.config`, `skip.logging`, `skip.customJson`, and Reloader.
- **Standalone:** Provide config yourself. Either use the default PVC and copy `config.ini` (and optional `logging.ini`, `custom.json`) into the volume (e.g. via a job or `kubectl cp`), or set `persistence.config` to an existing ConfigMap/Secret that you create elsewhere.

### Default persistence

When `externalSecrets.enabled: true`, default `persistence.config` is `type: secret`, `name: plex-auto-skip`. When disabled, use `type: persistentVolumeClaim` (100Mi) or override to mount your own ConfigMap/Secret.

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
| Persistence | `skip.persistence.config` | Volume at `/config`. With ExternalSecret: `type: secret`, `name: plex-auto-skip`. Else PVC or override. |
| Image | `skip.controllers.main.containers.main.image` | Default: `ghcr.io/mdhiggins/plexautoskip-docker:latest` (or version-matched on release). |
| Env | `skip.controllers.main.containers.main.env` | `PUID`, `PGID`, `TZ`, `PAS_PATH`, `PAS_UPDATE`, `LSIO_NON_ROOT_USER`. |
| Pod options | `skip.defaultPodOptions` | Affinity, annotations (e.g. Reloader). Parent chart may set Reloader for the config resource it mounts. |
| Resources | `skip.controllers.main.containers.main.resources` | CPU/memory requests and limits. |

The chart runs the container as non-root (e.g. 911/911) with `LSIO_NON_ROOT_USER=true` and no Service/Ingress by default. When `externalSecrets.enabled: true`, this chart generates config (ExternalSecret → Secret). When used under the **plex** chart, the parent can provide config instead.

## CI/CD and publishing

- **Release on merge**: Pushing to `main` (chart files only) runs `helm lint`, bumps patch version, creates a tag and GitHub Release.
- **Helm publish**: On release, the workflow packages the chart and attaches the tarball to the release.
- See [.github/workflows/README.md](.github/workflows/README.md) for details and manual triggers.

## Links

- [PlexAutoSkip](https://github.com/mdhiggins/PlexAutoSkip)
- [PlexAutoSkip Configuration](https://github.com/mdhiggins/PlexAutoSkip/wiki/Configuration)
- [plexautoskip-docker](https://github.com/mdhiggins/plexautoskip-docker)
- [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts/tree/main/charts/app-template)
