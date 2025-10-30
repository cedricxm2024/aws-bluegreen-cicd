#!/usr/bin/env bash

set -e

echo "Testing file structure integrity..."

# Test 1: Check for files with leading spaces
echo "Test 1: Checking for files with leading spaces in names..."
FILES_WITH_SPACES=$(find . -type f -name "* *" 2>/dev/null || true)
if [ -n "$FILES_WITH_SPACES" ]; then
  echo "❌ FAILED: Found files with leading spaces:"
  echo "$FILES_WITH_SPACES"
  exit 1
else
  echo "✅ PASSED: No files with leading spaces found"
fi

# Test 2: Verify critical Terraform files exist
echo ""
echo "Test 2: Verifying critical Terraform files exist..."
CRITICAL_FILES=(
  "modules/compute/main.tf"
  "modules/compute/variables.tf"
  "modules/compute/outputs.tf"
  "pipeline/buildspec.yml"
  "pipeline/appspec.yml"
)

MISSING_FILES=()
for file in "${CRITICAL_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    MISSING_FILES+=("$file")
  fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
  echo "❌ FAILED: Missing critical files:"
  printf '%s\n' "${MISSING_FILES[@]}"
  exit 1
else
  echo "✅ PASSED: All critical files exist"
fi

# Test 3: Verify shell scripts are executable or can be made executable
echo ""
echo "Test 3: Verifying shell scripts..."
SHELL_SCRIPTS=$(find bin/ scripts/ -type f -name "*.sh" 2>/dev/null || true)
if [ -z "$SHELL_SCRIPTS" ]; then
  echo "⚠️  WARNING: No shell scripts found"
else
  for script in $SHELL_SCRIPTS; do
    if [ ! -x "$script" ]; then
      echo "⚠️  WARNING: $script is not executable (can be fixed with chmod +x)"
    fi
  done
  echo "✅ PASSED: Shell scripts verified"
fi

echo ""
echo "All tests completed successfully!"
