# Dependabot Configuration Scanner

A GitHub Action that automatically scans your repository for missing Dependabot configurations based on detected project files and ecosystems.

## Features

- 🔍 **Auto-detection**: Identifies project ecosystems by scanning for indicator files (package.json, requirements.txt, go.mod, etc.)
- ⚠️ **Missing Config Alerts**: Detects when project ecosystems lack Dependabot configuration
- 📋 **Recommended Configs**: Provides ready-to-use dependabot.yml snippets for missing ecosystems
- 🎫 **Auto Issue Creation**: Automatically creates GitHub issues when missing configurations are detected
- 🔄 **Scheduled Scans**: Runs weekly by default, with manual trigger support

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
| ... and more |

## Usage

### Automatic Installation

1. Copy `.github/workflows/dependabot-scan.yml` to your repository
2. The action will run automatically on:
   - Push to main branch
   - Weekly schedule (Monday 8 AM UTC)
   - Manual trigger via Actions tab

### Manual Trigger

Go to **Actions** → **Dependabot Configuration Scanner** → **Run workflow**

Optionally specify ecosystems to check (comma-separated), or leave empty for auto-detection.

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

## Configuration

The scanner supports these package ecosystems (see [GitHub docs](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference#package-ecosystem-) for full list):

- `npm`, `yarn`, `bun` (JavaScript/TypeScript)
- `pip` (Python)
- `go-modules` (Go)
- `bundler` (Ruby)
- `cargo` (Rust)
- `nuget` (.NET)
- `composer` (PHP)
- `gradle`, `maven` (Java)
- `docker` (Docker)
- `github-actions` (GitHub Actions)
- `terraform` (Terraform)
- `pub` (Dart/Flutter)
- `swift` (Swift)
- `submodules` (Git submodules)

## License

MIT License - see [LICENSE](LICENSE) file for details.
