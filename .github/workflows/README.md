# CI/CD: GitHub Actions and publishing

This project automates the release cycle for the **plex-auto-skip** Helm chart: **merge to main** → validate (lint + template) → auto-release (tag + GitHub Release) → **Helm** package and upload → **release notes** from the merged PR (summarized via OpenAI).

## Single workflow

All of this runs from **one** file, [helm-chart-ci.yml](helm-chart-ci.yml), which calls the reusable workflow `expectedbehaviors/github-actions/.github/workflows/helm-chart-ci.yml@main`. The reusable workflow chains these jobs with event-based gates:

| Job | Action | Runs when |
|-----|--------|-----------|
| **validate** | `helm-chart-validate` (lint → template) | `pull_request`, `push` |
| **release** | `release-on-merge` | `push` to `main` (after validate) |
| **publish** | `helm-publish` | `release: published`, `workflow_run` after push, or `workflow_dispatch` |
| **release-notes** | `release-notes` (OpenAI) | same as publish |

Secrets are passed with `secrets: inherit`. To pin a version, replace `@main` with a tag (e.g. `@v1`) in `helm-chart-ci.yml`.

### What runs when

- **Open a PR** touching chart paths (`Chart.yaml`, `values.yaml`, `templates/**`, `README.md`, `.helmignore`): **validate** lints and renders the chart.
- **Merge a PR into `main`** touching those paths: **validate** then **release** creates the next `v*` tag and GitHub Release. The release (or `workflow_run` completion) triggers **publish** and **release-notes**.
- **Push to `main`** without those paths (e.g. docs only): no new release.
- **Manually create a release** (`gh release create`): triggers publish and release notes.
- **Manual run:** Run **Helm chart CI** from the Actions tab. Optional inputs: `release_tag` (e.g. `v0.1.0`).

---

## Required secrets

Add these under **Settings → Secrets and variables → Actions** in the repo.

| Credential | Required? | Used by | How to create |
|------------|-----------|---------|----------------|
| **GITHUB_TOKEN** | No (automatic) | All jobs | Provided by GitHub Actions; no setup. |
| **OPENAI_API_KEY** | **Yes** (for release notes) | release-notes job | OpenAI API key. See below. |

### OpenAI API key (required for release notes)

1. Sign in at [platform.openai.com](https://platform.openai.com/) (or create an account; new accounts often get free trial credits).
2. Go to [API keys](https://platform.openai.com/api-keys) → **Create new secret key**.
3. Name it (e.g. `github-release-notes`), copy the key once.
4. In your GitHub repo: **Settings → Secrets and variables → Actions** → **New repository secret** → Name: `OPENAI_API_KEY`, Value: paste the key.

**Security:** GitHub stores secrets encrypted and does not show values in logs. The key is only sent to OpenAI’s API over HTTPS from GitHub’s runners.

---

## Helm chart publishing

- The **publish** job sets chart **version** and **appVersion** from the release tag, sets the default **image tag** in the packaged chart to that version (e.g. `ghcr.io/mdhiggins/plexautoskip-docker:0.1.1`), uploads `plex-auto-skip-<version>.tgz` to the GitHub Release, and publishes the chart index to the **gh-pages** branch (Helm repo).
- **Enable GitHub Pages** so the Helm repo is pullable: **Settings → Pages → Source: Deploy from a branch** → Branch: **gh-pages** → Save. After the first publish, the index is at `https://<owner>.github.io/<repo>/index.yaml`. Then: `helm repo add plex-autoskip https://<owner>.github.io/<repo>` and `helm install my-plex-autoskip plex-autoskip/plex-auto-skip`.
- **From GitHub Release:** `helm install <name> https://github.com/<owner>/<repo>/releases/download/vX.Y.Z/plex-auto-skip-X.Y.Z.tgz`.
- **Artifact Hub:** add this GitHub repo as a Helm repository and point it at **GitHub Releases** so the chart and versions appear there.
