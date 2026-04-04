# Dependabot Configuration Scanner

A **reusable GitHub Action** that automatically scans repositories for missing Dependabot configurations based on detected project files and ecosystems.

![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-Composite-blue)
![License](https://img.shields.io/github/license/non7top/dependabot-mia)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/non7top/dependabot-mia)

## Features

- **30+ supported ecosystems** - From npm to vcpkg
- **Directory-level detection** - Scans subdirectories, not just root
- **Auto issue/PR creation** - Creates issues or PRs with suggested changes
- **Configurable behavior** - Control failure, issue creation, and PR generation
- **Action outputs** - Expose scan results for downstream workflow steps

## Supported Ecosystems

| Ecosystem | Indicator Files |
|-----------|----------------|
| npm | package.json |
| bun | bun.lockb, bun.lock |
| pip | requirements.txt, setup.py, pyproject.toml, Pipfile |
| bundler | Gemfile |
| cargo | Cargo.toml |
| nuget | *.csproj, *.fsproj, packages.config |
| composer | composer.json |
| gomod | go.mod |
| gradle | build.gradle, settings.gradle |
| maven | pom.xml |
| docker | Dockerfile |
| docker-compose | docker-compose.yml |
| github-actions | .github/workflows/*.yml |
| terraform | *.tf |
| opentofu | *.tofu |
| bazel | BUILD, WORKSPACE |
| conda | environment.yml |
| pub | pubspec.yaml |
| swift | Package.swift |
| gitsubmodule | .gitmodules |
| devcontainers | devcontainer.json |
| elm | elm.json |
| mix | mix.exs |
| helm | Chart.yaml |
| julia | Project.toml |
| pre-commit | .pre-commit-config.yaml |
| uv | uv.lock |
| dotnet-sdk | *.csproj, global.json |
| rust-toolchain | rust-toolchain.toml |
| vcpkg | vcpkg.json |

## Usage

### Basic

```yaml
- name: Scan for missing Dependabot configs
  uses: non7top/dependabot-mia@v1
```

### Full Example

```yaml
name: Dependabot Scan

on:
  schedule:
    - cron: '0 8 * * 1'
  workflow_dispatch:

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Run scanner
        id: scanner
        uses: non7top/dependabot-mia@v1
        with:
          fail-on-missing: 'true'
          create-issue: 'true'
          create-pr: 'false'
          labels: 'dependabot-scan,security'
```

### CI Integration

```yaml
- name: Check Dependabot config
  uses: non7top/dependabot-mia@v1
  with:
    fail-on-missing: 'true'
    create-issue: 'false'
    create-pr: 'false'
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `ecosystems` | Comma-separated list to check (empty = auto-detect) | false | `''` |
| `fail-on-missing` | Fail workflow if missing configs detected | false | `'true'` |
| `create-issue` | Create GitHub issue for missing configs | false | `'true'` |
| `create-pr` | Create PR with suggested changes | false | `'false'` |
| `labels` | Labels for created issues | false | `'dependabot-scan,security,good-first-issue'` |
| `branch-name` | Branch name for PR creation | false | `'dependabot-mia/scan-${{ github.run_id }}'` |
| `token` | GitHub token | false | `${{ github.token }}` |

## Outputs

| Output | Description |
|--------|-------------|
| `scan-result` | `PASS` or `FAIL` |
| `found-ecosystems` | Count of detected ecosystems |
| `missing-ecosystems` | Count of missing configurations |
| `scan-output` | Full scanner output |

## Example Output

```
==============================================
  Dependabot Configuration Scanner
==============================================

Scanning repository: .
Date: 2026-04-04

Found .github/dependabot.yml

----------------------------------------------
  Scanning for Project Files
----------------------------------------------

  Configured: github-actions (directory: /)
  Missing: docker (directory: /)
  Missing: npm (directory: /client)

----------------------------------------------
  Scan Summary
----------------------------------------------

Total ecosystems found: 3
Configured: 1
Missing: 2

Result: FAIL
```

## Local Testing

```bash
git clone https://github.com/non7top/dependabot-mia.git
cd dependabot-mia
chmod +x scripts/scan-dependabot.sh
./scripts/scan-dependabot.sh /path/to/repo
```

## License

MIT - see [LICENSE](LICENSE)
