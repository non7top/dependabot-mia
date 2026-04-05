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

# Remove trailing slash if present
REPO_ROOT="${REPO_ROOT%/}"

# Supported ecosystems and their indicator files
declare -A ECOSYSTEM_INDICATORS=(
  ["npm"]="package.json"
  ["bun"]="bun.lockb|bun.lock"
  ["pip"]="requirements.txt|setup.py|setup.cfg|pyproject.toml|Pipfile|Pipfile.lock"
  ["bundler"]="Gemfile|Gemfile.lock"
  ["cargo"]="Cargo.toml|Cargo.lock"
  ["nuget"]="*.csproj|*.fsproj|*.vbproj|packages.config"
  ["composer"]="composer.json|composer.lock"
  ["gomod"]="go.mod|go.sum"
  ["gradle"]="build.gradle|build.gradle.kts|settings.gradle|settings.gradle.kts|gradle.properties"
  ["maven"]="pom.xml"
  ["docker"]="Dockerfile"
  ["docker-compose"]="docker-compose.yml|docker-compose.yaml|compose.yml|compose.yaml"
  ["github-actions"]=".github/workflows/*.yml|.github/workflows/*.yaml"
  ["terraform"]="*.tf"
  ["opentofu"]="*.tofu"
  ["bazel"]="BUILD|WORKSPACE|BUILD.bazel|WORKSPACE.bazel"
  ["conda"]="environment.yml|environment.yaml|conda.yaml"
  ["pub"]="pubspec.yaml|pubspec.lock"
  ["swift"]="Package.swift"
  ["gitsubmodule"]=".gitmodules"
  ["devcontainers"]="devcontainer.json|.devcontainer/devcontainer.json|.devcontainer.json"
  ["elm"]="elm.json"
  ["mix"]="mix.exs"
  ["helm"]="Chart.yaml|Chart.yml"
  ["julia"]="Project.toml|JuliaProject.toml"
  ["pre-commit"]=".pre-commit-config.yaml"
  ["uv"]="uv.lock"
  ["dotnet-sdk"]="*.csproj|*.fsproj|*.vbproj|global.json"
  ["rust-toolchain"]="rust-toolchain|rust-toolchain.toml"
  ["vcpkg"]="vcpkg.json|vcpkg-configuration.json"
)

# Map ecosystem names to dependabot package-ecosystem values
declare -A ECOSYSTEM_MAP=(
  ["npm"]="npm"
  ["bun"]="bun"
  ["pip"]="pip"
  ["bundler"]="bundler"
  ["cargo"]="cargo"
  ["nuget"]="nuget"
  ["composer"]="composer"
  ["gomod"]="gomod"
  ["gradle"]="gradle"
  ["maven"]="maven"
  ["docker"]="docker"
  ["docker-compose"]="docker-compose"
  ["github-actions"]="github-actions"
  ["terraform"]="terraform"
  ["opentofu"]="opentofu"
  ["bazel"]="bazel"
  ["conda"]="conda"
  ["pub"]="pub"
  ["swift"]="swift"
  ["gitsubmodule"]="gitsubmodule"
  ["devcontainers"]="devcontainers"
  ["elm"]="elm"
  ["mix"]="mix"
  ["helm"]="helm"
  ["julia"]="julia"
  ["pre-commit"]="pre-commit"
  ["uv"]="uv"
  ["dotnet-sdk"]="dotnet-sdk"
  ["rust-toolchain"]="rust-toolchain"
  ["vcpkg"]="vcpkg"
)

# Ecosystems that only make sense at root level
ROOT_ONLY_ECOSYSTEMS="github-actions devcontainers gitsubmodule"

# Function to check if ecosystem is root-only
is_root_only() {
  local ecosystem="$1"
  for root_eco in $ROOT_ONLY_ECOSYSTEMS; do
    if [[ "$ecosystem" == "$root_eco" ]]; then
      return 0
    fi
  done
  return 1
}

# Function to check if indicator files exist in a directory
check_ecosystem_in_dir() {
  local ecosystem="$1"
  local indicators="$2"
  local search_dir="$3"
  local IFS='|'

  read -ra PATTERNS <<< "$indicators"

  for pattern in "${PATTERNS[@]}"; do
    if [[ "$pattern" == */* ]]; then
      # Pattern contains path separator, use -wholename
      if find "$search_dir" -maxdepth 3 -wholename "*/$pattern" -type f 2>/dev/null | grep -q .; then
        return 0
      fi
    else
      # Simple filename pattern, use -name
      if find "$search_dir" -maxdepth 1 -name "$pattern" -type f 2>/dev/null | grep -q .; then
        return 0
      fi
    fi
  done

  return 1
}

# Function to check if ecosystem is configured in dependabot.yml for a specific directory
is_configured_for_dir() {
  local ecosystem="$1"
  local dir="$2"
  local dependabot_file="$REPO_ROOT/.github/dependabot.yml"

  if [[ ! -f "$dependabot_file" ]]; then
    return 1
  fi

  local pkg_ecosystem="${ECOSYSTEM_MAP[$ecosystem]:-$ecosystem}"
  if grep -qiE "package-ecosystem:.*['\"]?${pkg_ecosystem}['\"]?" "$dependabot_file" && \
     grep -qiE "directory:.*['\"]?${dir}['\"]?" "$dependabot_file"; then
    return 0
  fi

  return 1
}

# Function to get dependabot config snippet for ecosystem
get_config_snippet() {
  local ecosystem="$1"
  local dir="$2"
  local pkg_ecosystem="${ECOSYSTEM_MAP[$ecosystem]:-$ecosystem}"

  case "$ecosystem" in
    "npm"|"bun")
      cat << EOF
  - package-ecosystem: "${pkg_ecosystem}"
    directory: "${dir}"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
EOF
      ;;
    "pip"|"conda"|"uv")
      cat << EOF
  - package-ecosystem: "${pkg_ecosystem}"
    directory: "${dir}"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
EOF
      ;;
    "gomod")
      cat << EOF
  - package-ecosystem: "gomod"
    directory: "${dir}"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
EOF
      ;;
    "docker"|"docker-compose")
      cat << EOF
  - package-ecosystem: "${pkg_ecosystem}"
    directory: "${dir}"
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
    "terraform"|"opentofu")
      cat << EOF
  - package-ecosystem: "${pkg_ecosystem}"
    directory: "${dir}"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
EOF
      ;;
    *)
      cat << EOF
  - package-ecosystem: "${pkg_ecosystem}"
    directory: "${dir}"
    schedule:
      interval: "weekly"
EOF
      ;;
  esac
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
  echo -e "${GREEN}Found${NC} .github/dependabot.yml"
  echo ""
else
  echo -e "${YELLOW}Missing${NC} .github/dependabot.yml"
  echo ""
fi

echo "----------------------------------------------"
echo "  Scanning for Project Files"
echo "----------------------------------------------"
echo ""

# Track results
declare -a FOUND_RESULTS=()
declare -a MISSING_RESULTS=()
TOTAL_ECOSYSTEMS=0
MISSING_COUNT=0

# First check root directory
for ecosystem in "${!ECOSYSTEM_INDICATORS[@]}"; do
  if check_ecosystem_in_dir "$ecosystem" "${ECOSYSTEM_INDICATORS[$ecosystem]}" "$REPO_ROOT"; then
    TOTAL_ECOSYSTEMS=$((TOTAL_ECOSYSTEMS + 1))
    local_dir="/"

    if is_configured_for_dir "$ecosystem" "$local_dir"; then
      FOUND_RESULTS+=("  ${GREEN}Configured${NC}: $ecosystem (directory: $local_dir)")
    else
      MISSING_RESULTS+=("  ${RED}Missing${NC}: $ecosystem (directory: $local_dir)")
      MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
  fi
done

# Then scan subdirectories (depth 1)
for dir in "$REPO_ROOT"/*/; do
  [[ -d "$dir" ]] || continue
  dir_name=$(basename "$dir")
  [[ "$dir_name" == .* ]] && continue
  [[ "$dir_name" == "node_modules" ]] && continue
  [[ "$dir_name" == ".git" ]] && continue
  [[ "$dir_name" == "vendor" ]] && continue
  [[ "$dir_name" == "target" ]] && continue

  rel_path="${dir#"$REPO_ROOT"}"

  for ecosystem in "${!ECOSYSTEM_INDICATORS[@]}"; do
    # Skip root-only ecosystems when scanning subdirectories
    if is_root_only "$ecosystem"; then
      continue
    fi

    if check_ecosystem_in_dir "$ecosystem" "${ECOSYSTEM_INDICATORS[$ecosystem]}" "$dir"; then
      TOTAL_ECOSYSTEMS=$((TOTAL_ECOSYSTEMS + 1))

      if is_configured_for_dir "$ecosystem" "$rel_path"; then
        FOUND_RESULTS+=("  ${GREEN}Configured${NC}: $ecosystem (directory: $rel_path)")
      else
        MISSING_RESULTS+=("  ${RED}Missing${NC}: $ecosystem (directory: $rel_path)")
        MISSING_COUNT=$((MISSING_COUNT + 1))
      fi
    fi
  done
done

# Print results
if [[ $TOTAL_ECOSYSTEMS -eq 0 ]]; then
  echo -e "${BLUE}No supported project ecosystems detected${NC}"
  echo ""
  echo "----------------------------------------------"
  echo "  Scan Summary"
  echo "----------------------------------------------"
  echo ""
  echo "Total ecosystems found: 0"
  echo "Result: PASS"
  exit 0
fi

for result in "${FOUND_RESULTS[@]}"; do
  echo -e "$result"
done

for result in "${MISSING_RESULTS[@]}"; do
  echo -e "$result"
done

echo ""
echo "----------------------------------------------"
echo "  Scan Summary"
echo "----------------------------------------------"
echo ""
echo "Total ecosystems found: $TOTAL_ECOSYSTEMS"
echo "Configured: $((TOTAL_ECOSYSTEMS - MISSING_COUNT))"
echo "Missing: $MISSING_COUNT"

if [[ $MISSING_COUNT -gt 0 ]]; then
  echo ""
  echo -e "${RED}Result: FAIL${NC}"
  echo ""
  echo "Recommended dependabot.yml additions:"
  echo ""

  for result in "${MISSING_RESULTS[@]}"; do
    eco=$(echo "$result" | grep -oP 'Missing.: \K[^ ]+')
    dir=$(echo "$result" | grep -oP 'directory: \K[^)]+')

    get_config_snippet "$eco" "$dir"
    echo ""
  done
  exit 1
else
  echo ""
  echo -e "${GREEN}Result: PASS${NC}"
  echo "All detected ecosystems are configured in dependabot.yml"
  exit 0
fi
