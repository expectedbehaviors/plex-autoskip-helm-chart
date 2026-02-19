# CI/CD: GitHub Actions and publishing

This project automates the release cycle for the **plex-auto-skip** Helm chart: **merge to main** → auto-release (tag + GitHub Release) → **Helm** package and upload → **release notes** from the merged PR (summarized as bullet points via OpenAI).

## Workflows

| Workflow file | Trigger | Purpose |
|---------------|---------|--------|
| [release-on-merge.yml](release-on-merge.yml) | Push to `main` (chart paths only) | Run `helm lint`, then bump patch version, create tag (e.g. `v0.1.1`) and publish GitHub Release |
| [helm-publish.yml](helm-publish.yml) | **Release published** or *Release on merge* completes | Package chart with version from release, upload `.tgz` to GitHub Release, publish index to **gh-pages** |
| [release-notes.yml](release-notes.yml) | **Release published** or *Release on merge* completes | Set release body from merged PR; OpenAI summarizes into bullet points (requires `OPENAI_API_KEY`) |

These workflows call reusable composite actions from the **github-actions** repo. Each workflow uses `expectedbehaviors/github-actions/.github/actions/<name>@main` and passes secrets as inputs (see each workflow's `with:` block). To pin a specific version, replace `@main` with `@v1` or another tag in all workflow files.

### What runs when

- **Merge a PR into `main`** that touches `Chart.yaml`, `Chart.lock`, `values.yaml`, `README.md`, `.helmignore`, or `templates/**`: **Release on merge** runs → creates the next `v*` tag and a GitHub Release. That **release published** event (or workflow_run completion) triggers: **Helm** package/upload and **Release notes** (OpenAI summary).

- **Push to `main`** without those paths (e.g. docs only): no new release.

- **Manually create a release** (tag + publish in the UI or `gh release create`): same as above – Helm and release notes run.

**Note:** Helm publish and Release notes also run when **Release on merge to main** completes (workflow_run fallback). That way they still run even if the `release: published` event doesn’t trigger them (e.g. release created by another workflow).

**Manual run:** You can run **Helm chart publish** and **Release notes from PR** from the Actions tab (**Run workflow**). Optional input: **release_tag** – e.g. `v0.1.0` (default: latest release).

---

## Required secrets

Add these under **Settings → Secrets and variables → Actions** in the repo.

| Credential | Required? | Used by | How to create |
|------------|-----------|---------|----------------|
| **GITHUB_TOKEN** | No (automatic) | All workflows | Provided by GitHub Actions; no setup. |
| **OPENAI_API_KEY** | **Yes** (for release notes) | Release notes from PR | OpenAI API key; workflow fails if unset. New accounts often get free trial credits. See below. |

### OpenAI API key (required for release notes)

1. Sign in at [platform.openai.com](https://platform.openai.com/) (or create an account; new accounts often get free trial credits).
2. Go to [API keys](https://platform.openai.com/api-keys) → **Create new secret key**.
3. Name it (e.g. `github-release-notes`), copy the key once.
4. In your GitHub repo: **Settings → Secrets and variables → Actions** → **New repository secret** → Name: `OPENAI_API_KEY`, Value: paste the key.

The **Release notes from PR** workflow fails if `OPENAI_API_KEY` is not set.

**Security:** GitHub stores secrets encrypted and does not show values in logs. The key is only sent to OpenAI’s API over HTTPS from GitHub’s runners.

---

## Release notes (OpenAI bullet points)

The **Release notes from PR** workflow:

1. Finds the **PR that was merged** for the release commit.
2. Uses that PR’s **description** as input.
3. Calls OpenAI (`gpt-4o-mini`) to summarize it into **2–4 short bullet points** and sets that as the release body.

---

## Automated release cycle (merge → release)

1. You merge a PR into `main` that touches chart-impacting paths (`Chart.yaml`, `Chart.lock`, `values.yaml`, `README.md`, `.helmignore`, `templates/**`).
2. **Release on merge to main** runs: runs `helm lint`, then computes the next patch version (e.g. last tag `v0.1.0` → `v0.1.1`), creates that tag and a GitHub Release with a short placeholder note.
3. The **release published** (or workflow_run) event triggers:
   - **Helm** – package chart with that version, set default image tag to that version, upload the `.tgz` to the release, and publish the chart index to **gh-pages**.
   - **Release notes** – replace the placeholder with OpenAI-generated bullet summary.

No manual tagging or release creation needed for the standard flow.

---

## Helm chart publishing

- On **release published** (or *Release on merge* completion), the **Helm chart publish** workflow sets chart **version** and **appVersion** from the release tag, sets the default **image tag** in the packaged chart to that version (e.g. `ghcr.io/mdhiggins/plexautoskip-docker:0.1.1`), uploads `plex-auto-skip-<version>.tgz` to the GitHub Release, and publishes the chart index to the **gh-pages** branch (Helm repo).
- **Enable GitHub Pages** so the Helm repo is pullable: **Settings → Pages → Source: Deploy from a branch** → Branch: **gh-pages** → Save. After the first publish, the index is at `https://<owner>.github.io/<repo>/index.yaml`. Then: `helm repo add plex-autoskip https://<owner>.github.io/<repo>` and `helm install my-plex-autoskip plex-autoskip/plex-auto-skip`.
- **From GitHub Release:** `helm install <name> https://github.com/<owner>/<repo>/releases/download/vX.Y.Z/plex-auto-skip-X.Y.Z.tgz`.
- **Artifact Hub:** add this GitHub repo as a Helm repository and point it at **GitHub Releases** so the chart and versions appear there.
