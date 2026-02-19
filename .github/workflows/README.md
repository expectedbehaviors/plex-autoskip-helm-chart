# CI/CD: GitHub Actions and publishing

This repo automates the release cycle for the **plex-auto-skip** Helm chart: **merge to main** → auto-release (tag + GitHub Release) → **Helm** package and upload.

## Workflows

| Workflow file | Trigger | Purpose |
|---------------|---------|---------|
| [release-on-merge.yml](release-on-merge.yml) | Push to `main` (chart files only) | Run `helm lint`, then bump patch version, create tag (e.g. `v0.1.1`) and publish GitHub Release |
| [helm-publish.yml](helm-publish.yml) | **Release published** or *Release on merge* completes (on success) | Package chart and upload `plex-auto-skip-<version>.tgz` to the GitHub Release |
| [release-notes.yml](release-notes.yml) | **Release published** or *Release on merge* completes (on success) | Populate release notes from the merged PR (OpenAI-summarized bullet points) |

All use reusable actions from **expectedbehaviors/github-actions**. To pin a version, replace `@main` with `@v1` (or another tag) in the workflow files.

## What runs when

- **Merge a PR into `main`** that touches `Chart.yaml`, `Chart.lock`, `values.yaml`, `README.md`, or `.helmignore`: **Release on merge** runs → creates the next `v*` tag and a GitHub Release. That triggers **Helm chart publish** (package and upload).
- **Manually create a release** (tag + publish in the UI or `gh release create`): **Helm chart publish** runs.
- **Manual run:** From the Actions tab, run **Helm chart publish** with optional input `release_tag` (e.g. `v0.1.0`).

## Required

- **GITHUB_TOKEN** is provided by GitHub Actions; no extra secrets needed for packaging and upload.
- **Release notes workflow:** add repository secret **OPENAI_API_KEY** if you want release notes auto-populated from the merged PR (see [release-notes.yml](release-notes.yml)).

## Helm chart publishing

- Chart **version** and **appVersion** are set from the release tag. The packaged chart’s default image tag is set to that version.
- **From Git (Argo CD / Helm):** use this repo URL and path `.` (repo root).
- **Helm repo:** Publish the release tarballs to GitHub Pages or another host and run `helm repo index` to serve the chart by version.
