#!/bin/bash
# Unit Tests for Dependabot Configuration Scanner

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCANNER="$SCRIPT_DIR/../scripts/scan-dependabot.sh"
FIXTURES="$SCRIPT_DIR/fixtures"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

assert_pass() {
  local test_name="$1"
  local fixture="$2"

  output=$("$SCANNER" "$fixture" 2>&1) || true

  if echo "$output" | grep -q "Result: PASS"; then
    echo -e "${GREEN}PASS${NC}: $test_name"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}: $test_name - expected PASS"
    echo "  Output: $(echo "$output" | tail -5)"
    FAIL=$((FAIL + 1))
  fi
}

assert_fail() {
  local test_name="$1"
  local fixture="$2"
  local missing_count="$3"

  output=$("$SCANNER" "$fixture" 2>&1) || true

  if echo "$output" | grep -q "Result: FAIL"; then
    actual_missing=$(echo "$output" | grep "^Missing:" | awk '{print $NF}')
    if [[ "$actual_missing" == "$missing_count" ]]; then
      echo -e "${GREEN}PASS${NC}: $test_name"
      PASS=$((PASS + 1))
    else
      echo -e "${RED}FAIL${NC}: $test_name - expected $missing_count missing, got $actual_missing"
      FAIL=$((FAIL + 1))
    fi
  else
    echo -e "${RED}FAIL${NC}: $test_name - expected FAIL"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  local test_name="$1"
  fixture="$2"
  expected="$3"

  output=$("$SCANNER" "$fixture" 2>&1) || true

  if echo "$output" | grep -q "$expected"; then
    echo -e "${GREEN}PASS${NC}: $test_name"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}: $test_name - expected to find '$expected'"
    FAIL=$((FAIL + 1))
  fi
}

assert_detects_ecosystem() {
  local test_name="$1"
  fixture="$2"
  ecosystem="$3"

  output=$("$SCANNER" "$fixture" 2>&1) || true

  if echo "$output" | grep -q "$ecosystem"; then
    echo -e "${GREEN}PASS${NC}: $test_name"
    PASS=$((PASS + 1))
  else
    echo -e "${RED}FAIL${NC}: $test_name - expected to detect '$ecosystem'"
    FAIL=$((FAIL + 1))
  fi
}

echo "=============================================="
echo "  Dependabot Scanner Unit Tests"
echo "=============================================="
echo ""

# Test 1: Empty repo should pass with 0 ecosystems
echo "--- Basic Tests ---"
output=$("$SCANNER" "$FIXTURES/empty-repo" 2>&1) || true
if echo "$output" | grep -q "No supported project ecosystems detected"; then
  echo -e "${GREEN}PASS${NC}: Empty repo detected correctly"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${NC}: Empty repo not detected correctly"
  FAIL=$((FAIL + 1))
fi

# Test 2: Configured npm should pass
assert_pass "Configured npm ecosystem" "$FIXTURES/npm-configured"

# Test 3: Missing config should fail with 1 missing
assert_fail "Missing npm config" "$FIXTURES/missing-config" "1"

# Test 4: Scanner detects npm in fixture
assert_detects_ecosystem "Detects npm in npm-configured" "$FIXTURES/npm-configured" "npm"

# Test 5: Scanner detects missing npm in missing-config
assert_contains "Reports missing npm" "$FIXTURES/missing-config" "Missing"

# Test 6: Multi-ecosystem detection
assert_detects_ecosystem "Detects docker in multi-dir" "$FIXTURES/multi-dir" "docker"
assert_detects_ecosystem "Detects npm in multi-dir" "$FIXTURES/multi-dir" "npm"

# Test 7: Test directory (the actual test fixture)
assert_pass "Test directory passes (all configured)" "$SCRIPT_DIR/../test/"

# Test 8: Verify scanner output has PASS/FAIL
output=$("$SCANNER" "$FIXTURES/npm-configured" 2>&1) || true
if echo "$output" | grep -qE "Result: (PASS|FAIL)"; then
  echo -e "${GREEN}PASS${NC}: Output contains Result: PASS/FAIL"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${NC}: Output missing Result: PASS/FAIL"
  FAIL=$((FAIL + 1))
fi

# Test 9: Verify scanner output has ecosystem counts
output=$("$SCANNER" "$FIXTURES/multi-dir" 2>&1) || true
if echo "$output" | grep -q "Total ecosystems found:"; then
  echo -e "${GREEN}PASS${NC}: Output contains ecosystem count"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${NC}: Output missing ecosystem count"
  FAIL=$((FAIL + 1))
fi

echo ""
echo "=============================================="
echo "  Test Results: $PASS passed, $FAIL failed"
echo "=============================================="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
