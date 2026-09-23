<div align="center">
  <a href="https://vertracloud.app">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://vertracloud.app/brand/github-banner.png">
      <source media="(prefers-color-scheme: light)" srcset="https://vertracloud.app/brand/github-banner-light.png">
      <img src="https://vertracloud.app/brand/github-banner-light.png" alt="Vertra Cloud" width="1200">
    </picture>
  </a>
</div>

# Vertra Cloud Deploy Action

[![Test](https://github.com/vertracloud/github-action/actions/workflows/test.yml/badge.svg)](https://github.com/vertracloud/github-action/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Deploy your repository to [Vertra Cloud](https://vertracloud.app) on every push.

- Uses the official [Vertra CLI](https://github.com/vertracloud/cli) binary, pinned to a release and verified by SHA-256.
- Uploads your project (respecting `.vertraignore`) and restarts the application.
- Works on Linux and macOS runners, x64 and ARM64.

## Usage

```yaml
name: Deploy

on:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: vertracloud/github-action@v1
        with:
          api-key: ${{ secrets.VERTRA_API_KEY }}
          app-id: ${{ secrets.VERTRA_APP_ID }}
```

The application must already exist — this Action updates it, it does not create one.

## Setup

1. Create an API key in the Vertra Cloud dashboard with permission to manage the application's files.
2. In your repository, open **Settings → Secrets and variables → Actions** and add:

| Secret | Value |
|---|---|
| `VERTRA_API_KEY` | Your Vertra Cloud API key |
| `VERTRA_APP_ID` | The ID of the application to deploy |

Never write the API key in the workflow file. The Action also masks it in the logs.

## Inputs

| Input | Required | Default | Description |
|---|:---:|---|---|
| `api-key` | yes | — | Vertra Cloud API key. Pass it from a secret. |
| `app-id` | yes | — | ID of the existing application. |
| `path` | no | `.` | Directory to upload, relative to the repository root. |
| `restart` | no | `true` | Restart the application after the upload. |
| `cli-version` | no | `v0.1.0` | Vertra CLI release tag to use. |

The Action has no outputs: the step succeeds when the deploy succeeds and fails otherwise.

## Examples

**Monorepo** — upload a single directory:

```yaml
      - uses: vertracloud/github-action@v1
        with:
          api-key: ${{ secrets.VERTRA_API_KEY }}
          app-id: ${{ secrets.VERTRA_APP_ID }}
          path: apps/api
```

**Upload without restarting:**

```yaml
      - uses: vertracloud/github-action@v1
        with:
          api-key: ${{ secrets.VERTRA_API_KEY }}
          app-id: ${{ secrets.VERTRA_APP_ID }}
          restart: false
```

## How it works

- **Files are merged.** Uploaded files overwrite the ones already in the application; files that exist only in the application are kept.
- **Ignored by default:** `node_modules`, `.git`, `.github`, `.vscode`, `.venv`, `venv`, `vendor`, `target`, `.next`, `__pycache__` and the `.gitignore`, `.vertraignore` and `.vertracloudignore` files themselves. Add more patterns in a `.vertraignore` at the root of `path`.
- **Limits:** your plan's upload and storage limits apply.

## Links

- [Documentation](https://docs.vertracloud.app)
- [Vertra CLI](https://github.com/vertracloud/cli)
- [Dashboard](https://vertracloud.app)

## License

[MIT](LICENSE)
