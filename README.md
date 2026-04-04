# Dependabot Configuration Scanner

A **reusable GitHub Action** that automatically scans repositories for missing Dependabot configurations based on detected project files and ecosystems.

![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-Composite-blue)
![License](https://img.shields.io/github/license/non7top/dependabot-mia)

## Features

- 🔍 **Auto-detection**: Identifies project ecosystems by scanning for indicator files
- ⚠️ **Missing Config Alerts**: Detects when project ecosystems lack Dependabot configuration
- 📋 **Recommended Configs**: Provides ready-to-use dependabot.yml snippets
- 🎫 **Auto Issue Creation**: Optionally creates GitHub issues for missing configurations
- 📤 **Action Outputs**: Exposes scan results for use in downstream workflow steps
- 🔄 **Flexible Configuration**: Customize behavior with inputs

## Supported Ecosystems

| Ecosystem | Indicator Files |
|-----------|----------------|
| npm/yarn/bun | package.json, bun.lockb |
| pip | requirements.txt, setup.py, pyproject.toml, Pipfile |
| go-modules | go.mod |
| bundler | Gemfile |
| cargo | Cargo.toml |
| nuget | *.csproj, *.fsproj, packages.config |
| composer | composer.json |
| gradle/maven | build.gradle, pom.xml |
| docker | Dockerfile, docker-compose.yml |
| github-actions | .github/workflows/*.yml |
| terraform | *.tf |
| pub | pubspec.yaml |
| swift | Package.swift |
| submodules | .gitmodules |
| devcontainers | devcontainer.json |
| elm | elm.json |
| hex | mix.exs |

## Usage

### Basic Usage

Add this to your workflow:

```yaml
- name: Scan for missing Dependabot configs
  uses: non7top/dependabot-mia@master
```

### Full Example

```yaml
name: Dependabot Scan

on:
  schedule:
    - cron: '0 8 * * 1'  # Weekly on Monday
  workflow_dispatch:      # Manual trigger

permissions:
  contents: read
  issues: write

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Run Dependabot Scanner
        id: scanner
        uses: non7top/dependabot-mia@master
        with:
          # Optional: Comma-separated list of ecosystems to check
          # Leave empty for auto-detection of all supported ecosystems
          ecosystems: ''

          # Whether to fail the workflow if missing configs are detected
          # Set to 'false' to just warn without failing
          fail-on-missing: 'true'

          # Create a GitHub issue when missing configurations are detected
          create-issue: 'true'

          # Labels to add to created issues
          labels: 'dependabot-scan,security'

      - name: Use scan results
        if: always()
        run: |
          echo "Scan result: ${{ steps.scanner.outputs.scan-result }}"
          echo "Found: ${{ steps.scanner.outputs.found-ecosystems }}"
          echo "Missing: ${{ steps.scanner.outputs.missing-ecosystems }}"
```

### Using as Part of CI

```yaml
name: CI

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - name: Check Dependabot configuration
        uses: non7top/dependabot-mia@master
        with:
          fail-on-missing: 'true'
          create-issue: 'false'  # Don't create issues in CI
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `ecosystems` | Comma-separated list of ecosystems to check (empty = auto-detect) | false | `''` |
| `fail-on-missing` | Fail workflow if missing configs detected | false | `'true'` |
| `create-issue` | Create GitHub issue for missing configs | false | `'true'` |
| `labels` | Labels for created issues | false | `'dependabot-scan,security,good-first-issue'` |
| `token` | GitHub token for API access | false | `${{ github.token }}` |

## Outputs

| Output | Description |
|--------|-------------|
| `scan-result` | `PASS` or `FAIL` |
| `found-ecosystems` | Comma-separated list of detected ecosystems |
| `missing-ecosystems` | Comma-separated list of ecosystems missing configuration |
| `scan-output` | Full scanner output text |

## Example Output

```
==============================================
  Dependabot Configuration Scanner
==============================================

Scanning repository: .
Date: 2026-04-04

✓ Found .github/dependabot.yml

----------------------------------------------
  Scanning for Project Files
----------------------------------------------

✓ npm - Configured in dependabot.yml
✗ docker - MISSING Dependabot configuration
✗ github-actions - MISSING Dependabot configuration

----------------------------------------------
  Scan Summary
----------------------------------------------

Found 3 ecosystem(s): npm docker github-actions

MISSING configurations for: docker github-actions
```

## Local Testing

You can test the scanner locally:

```bash
# Clone the repository
git clone https://github.com/non7top/dependabot-mia.git
cd dependabot-mia

# Run the scanner
chmod +x scripts/scan-dependabot.sh
./scripts/scan-dependabot.sh /path/to/your/repo
```

## Development

### Project Structure

```
dependabot-mia/
├── action.yml                     # GitHub Action definition
├── scripts/
│   └── scan-dependabot.sh         # Scanner script
├── .github/
│   ├── workflows/
│   │   ├── dependabot-scan.yml    # Self-test workflow
│   │   └── ci.yml                 # CI validation
│   └── dependabot.yml             # This repo's Dependabot config
├── README.md
└── LICENSE
```

### Creating a Release

```bash
# Tag a release
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
