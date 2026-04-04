#!/bin/bash
# Dependabot Configuration Scanner
# Scans repository for project files and detects missing Dependabot configurations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository root (default: current directory)
REPO_ROOT="${1:-.}"

# Supported ecosystems and their indicator files
declare -A ECOSYSTEM_INDICATORS=(
  ["npm"]="package.json"
  ["yarn"]="package.json"
  ["pip"]="requirements.txt|setup.py|setup.cfg|pyproject.toml|Pipfile"
  ["bundler"]="Gemfile"
  ["cargo"]="Cargo.toml"
  ["nuget"]="*.csproj|*.fsproj|*.vbproj|packages.config"
  ["composer"]="composer.json"
  ["go-modules"]="go.mod"
  ["gradle"]="build.gradle|build.gradle.kts|settings.gradle|settings.gradle.kts"
  ["maven"]="pom.xml"
  ["docker"]="Dockerfile|docker-compose.yml|docker-compose.yaml"
  ["github-actions"]=".github/workflows/*.yml|.github/workflows/*.yaml"
  ["terraform"]="*.tf"
  ["bun"]="package.json|bun.lockb"
  ["devcontainers"]="devcontainer.json|.devcontainer/devcontainer.json"
  ["pub"]="pubspec.yaml"
  ["elm"]="elm.json"
  ["hex"]="mix.exs"
  ["swift"]="Package.swift"
  ["submodules"]=".gitmodules"
)

# Function to check if indicator files exist
check_ecosystem() {
  local ecosystem="$1"
  local indicators="$2"
  local IFS='|'

  read -ra PATTERNS <<< "$indicators"

  for pattern in "${PATTERNS[@]}"; do
    # Search recursively in repo root
    if find "$REPO_ROOT" -name "$pattern" -type f 2>/dev/null | grep -q .; then
      return 0
    fi
  done

  return 1
}

# Function to check if ecosystem is in dependabot.yml
is_configured() {
  local ecosystem="$1"
  local dependabot_file="$REPO_ROOT/.github/dependabot.yml"

  if [[ ! -f "$dependabot_file" ]]; then
    return 1
  fi

  # Check if ecosystem is mentioned in dependabot.yml
  if grep -qi "package-ecosystem.*$ecosystem" "$dependabot_file"; then
    return 0
  fi

  return 1
}

echo "=============================================="
echo "  Dependabot Configuration Scanner"
echo "=============================================="
echo ""
echo "Scanning repository: $REPO_ROOT"
echo "Date: $(date -u)"
echo ""

# Check if dependabot.yml exists
if [[ -f "$REPO_ROOT/.github/dependabot.yml" ]]; then
  echo -e "${GREEN}✓${NC} Found .github/dependabot.yml"
  echo ""
else
  echo -e "${YELLOW}⚠${NC} No .github/dependabot.yml found"
  echo ""
fi

echo "----------------------------------------------"
echo "  Scanning for Project Files"
echo "----------------------------------------------"
echo ""

# Track found ecosystems
declare -a FOUND_ECOSYSTEMS=()
declare -a MISSING_ECOSYSTEMS=()

for ecosystem in "${!ECOSYSTEM_INDICATORS[@]}"; do
  if check_ecosystem "$ecosystem" "${ECOSYSTEM_INDICATORS[$ecosystem]}"; then
    FOUND_ECOSYSTEMS+=("$ecosystem")

    if is_configured "$ecosystem"; then
      echo -e "${GREEN}✓${NC} $ecosystem - Configured in dependabot.yml"
    else
      echo -e "${RED}✗${NC} $ecosystem - MISSING Dependabot configuration"
      MISSING_ECOSYSTEMS+=("$ecosystem")
    fi
  fi
done

echo ""
echo "----------------------------------------------"
echo "  Scan Summary"
echo "----------------------------------------------"
echo ""

if [[ ${#FOUND_ECOSYSTEMS[@]} -eq 0 ]]; then
  echo -e "${BLUE}ℹ${NC} No supported project ecosystems detected"
  exit 0
fi

echo "Found ${#FOUND_ECOSYSTEMS[@]} ecosystem(s): ${FOUND_ECOSYSTEMS[*]}"
echo ""

if [[ ${#MISSING_ECOSYSTEMS[@]} -gt 0 ]]; then
  echo -e "${RED}MISSING configurations for: ${MISSING_ECOSYSTEMS[*]}${NC}"
  echo ""
  echo "Recommended dependabot.yml additions:"
  for ecosystem in "${MISSING_ECOSYSTEMS[@]}"; do
    echo ""
    case "$ecosystem" in
      "npm"|"yarn"|"bun")
        cat << EOF
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
EOF
        ;;
      "pip")
        cat << EOF
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
EOF
        ;;
      "go-modules")
        cat << EOF
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
EOF
        ;;
      "docker")
        cat << EOF
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
EOF
        ;;
      "github-actions")
        cat << EOF
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
EOF
        ;;
      *)
        echo "  - package-ecosystem: \"$ecosystem\""
        echo "    directory: \"/\""
        echo "    schedule:"
        echo "      interval: \"weekly\""
        ;;
    esac
  done
  echo ""
  echo "MISSING: ${MISSING_ECOSYSTEMS[*]}"
  exit 1
else
  echo -e "${GREEN}✓${NC} All detected ecosystems are configured in dependabot.yml"
  exit 0
fi
