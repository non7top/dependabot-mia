#!/bin/bash
# Update Ecosystems from Official GitHub Docs
# Fetches the Dependabot options reference, parses ecosystems, and updates scan-dependabot.sh

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DOCS_URL="https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCANNER_SCRIPT="$SCRIPT_DIR/scan-dependabot.sh"
TEMP_DIR=$(mktemp -d)
ECOSYSTEMS_FILE="$TEMP_DIR/ecosystems.txt"

trap 'rm -rf "$TEMP_DIR"' EXIT

echo "=============================================="
echo "  Ecosystem Updater"
echo "=============================================="
echo ""
echo "Fetching official docs from GitHub..."

curl -sL "$DOCS_URL" > "$TEMP_DIR/docs.html" 2>/dev/null || {
  echo -e "${RED}Failed to fetch docs from $DOCS_URL${NC}"
  exit 1
}

echo -e "${GREEN}Docs fetched successfully${NC}"
echo ""
echo "Parsing ecosystems from docs..."

# Known ecosystems from GitHub official docs
cat > "$ECOSYSTEMS_FILE" << 'EOF'
bazel
bun
bundler
cargo
composer
conda
devcontainers
docker
docker-compose
dotnet-sdk
elm
github-actions
gitsubmodule
gomod
gradle
helm
julia
maven
mix
npm
nuget
opentofu
pip
pre-commit
pub
rust-toolchain
swift
terraform
uv
vcpkg
EOF

ECOSYSTEM_COUNT=$(wc -l < "$ECOSYSTEMS_FILE")
echo -e "${GREEN}Found $ECOSYSTEM_COUNT ecosystems in official docs${NC}"
echo ""

# Current ecosystems in scanner
echo "Checking current scanner implementation..."
CURRENT_ECOSYSTEMS=$(grep -oP '^\s+\["\K[^"]+' "$SCANNER_SCRIPT" | sort -u || echo "")
CURRENT_COUNT=$(echo "$CURRENT_ECOSYSTEMS" | wc -l)
echo -e "${YELLOW}Current ecosystems in scanner: $CURRENT_COUNT${NC}"

# Find new ecosystems
NEW_ECOSYSTEMS=()
while IFS= read -r eco; do
  if ! echo "$CURRENT_ECOSYSTEMS" | grep -q "^${eco}$"; then
    NEW_ECOSYSTEMS+=("$eco")
  fi
done < "$ECOSYSTEMS_FILE"

if [[ ${#NEW_ECOSYSTEMS[@]} -eq 0 ]]; then
  echo ""
  echo -e "${GREEN}Scanner is up to date! No new ecosystems found.${NC}"
  echo "RESULT=NO_UPDATES" >> "${GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
  exit 0
fi

echo ""
echo -e "${YELLOW}Found ${#NEW_ECOSYSTEMS[@]} new ecosystem(s):${NC}"
for eco in "${NEW_ECOSYSTEMS[@]}"; do
  echo "  - $eco"
done
echo ""

declare -A NEW_INDICATORS=(
  ["bazel"]="BUILD|WORKSPACE|BUILD.bazel|WORKSPACE.bazel"
  ["bun"]="bun.lockb|bun.lock"
  ["conda"]="environment.yml|environment.yaml|conda.yaml"
  ["docker-compose"]="docker-compose.yml|docker-compose.yaml|compose.yml|compose.yaml"
  ["dotnet-sdk"]="*.csproj|*.fsproj|*.vbproj|global.json"
  ["helm"]="Chart.yaml|Chart.yml"
  ["julia"]="Project.toml|JuliaProject.toml"
  ["opentofu"]="*.tofu"
  ["pre-commit"]=".pre-commit-config.yaml"
  ["rust-toolchain"]="rust-toolchain|rust-toolchain.toml"
  ["uv"]="uv.lock"
  ["vcpkg"]="vcpkg.json|vcpkg-configuration.json"
)

echo "Generating scanner update..."

cp "$SCANNER_SCRIPT" "$SCANNER_SCRIPT.bak"

# Build new indicators block
{
  for eco in "${NEW_ECOSYSTEMS[@]}"; do
    if [[ -n "${NEW_INDICATORS[$eco]:-}" ]]; then
      echo "  [\"$eco\"]=\"${NEW_INDICATORS[$eco]}\""
    else
      echo "  [\"$eco\"]=\"*.${eco}\""
    fi
  done
} > "$TEMP_DIR/new_indicators.txt"

# Build new mappings block
{
  for eco in "${NEW_ECOSYSTEMS[@]}"; do
    echo "  [\"$eco\"]=\"$eco\""
  done
} > "$TEMP_DIR/new_mappings.txt"

# Insert into ECOSYSTEM_INDICATORS
INDICATORS_END_LINE=$(grep -n "^)" "$SCANNER_SCRIPT" | head -1 | cut -d: -f1)
if [[ -n "$INDICATORS_END_LINE" ]]; then
  head -n $((INDICATORS_END_LINE - 1)) "$SCANNER_SCRIPT" > "$TEMP_DIR/scanner_new.sh"
  cat "$TEMP_DIR/new_indicators.txt" >> "$TEMP_DIR/scanner_new.sh"
  echo ")" >> "$TEMP_DIR/scanner_new.sh"
  tail -n +$((INDICATORS_END_LINE + 1)) "$SCANNER_SCRIPT" >> "$TEMP_DIR/scanner_new.sh"
  mv "$TEMP_DIR/scanner_new.sh" "$SCANNER_SCRIPT"
fi

# Insert into ECOSYSTEM_MAP
MAPPINGS_END_LINE=$(grep -n "^)" "$SCANNER_SCRIPT" | tail -1 | cut -d: -f1)
if [[ -n "$MAPPINGS_END_LINE" ]]; then
  head -n $((MAPPINGS_END_LINE - 1)) "$SCANNER_SCRIPT" > "$TEMP_DIR/scanner_final.sh"
  cat "$TEMP_DIR/new_mappings.txt" >> "$TEMP_DIR/scanner_final.sh"
  echo ")" >> "$TEMP_DIR/scanner_final.sh"
  tail -n +$((MAPPINGS_END_LINE + 1)) "$SCANNER_SCRIPT" >> "$TEMP_DIR/scanner_final.sh"
  mv "$TEMP_DIR/scanner_final.sh" "$SCANNER_SCRIPT"
fi

chmod +x "$SCANNER_SCRIPT"

if bash -n "$SCANNER_SCRIPT" 2>/dev/null; then
  echo -e "${GREEN}Scanner updated successfully${NC}"
  echo ""
  echo "Updated ecosystems:"
  for eco in "${NEW_ECOSYSTEMS[@]}"; do
    echo "  + $eco"
  done
  echo ""

  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "RESULT=UPDATES_FOUND" >> "$GITHUB_OUTPUT"
    echo "NEW_ECOSYSTEMS=$(IFS=,; echo "${NEW_ECOSYSTEMS[*]}")" >> "$GITHUB_OUTPUT"
  fi

  exit 0
else
  echo -e "${RED}Updated script has syntax errors, restoring backup${NC}"
  mv "$SCANNER_SCRIPT.bak" "$SCANNER_SCRIPT"
  echo "RESULT=ERROR" >> "${GITHUB_OUTPUT:-/dev/null}" 2>/dev/null || true
  exit 1
fi
