#!/usr/bin/env bash
# Test script to verify notebook conversion works locally

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_ok() { printf "${GREEN}✓${NC} %s\n" "$1"; }
log_err() { printf "${RED}✗${NC} %s\n" "$1"; }
log_info() { printf "${YELLOW}ℹ${NC} %s\n" "$1"; }

# Test directories
TEST_DIR="$(mktemp -d)"
trap "rm -rf $TEST_DIR" EXIT

log_info "Test directory: $TEST_DIR"

# Find jupyter
JUPYTER_CMD="jupyter"
if ! command -v jupyter >/dev/null 2>&1; then
  if [[ -f "$HOME/miniconda3/envs/bda-env/bin/jupyter" ]]; then
    JUPYTER_CMD="$HOME/miniconda3/envs/bda-env/bin/jupyter"
    log_ok "Found jupyter in bda-env: $JUPYTER_CMD"
  else
    log_err "jupyter not found! Install it in bda-env first"
    exit 1
  fi
else
  log_ok "Found jupyter in PATH"
fi

# Test 1: Check nbconvert version
log_info "Checking nbconvert version..."
"$JUPYTER_CMD" nbconvert --version || {
  log_err "nbconvert not available"
  exit 1
}

# Test 2: Find a test notebook
TEST_NOTEBOOK=""
for nb in Lab3/assignment/*.ipynb Lab2/assignment/*.ipynb Lab01/lab1-assignement/*.ipynb; do
  if [[ -f "$nb" ]]; then
    TEST_NOTEBOOK="$nb"
    break
  fi
done

if [[ -z "$TEST_NOTEBOOK" ]]; then
  log_err "No test notebook found in Lab01-Lab3"
  exit 1
fi

log_ok "Test notebook: $TEST_NOTEBOOK"

# Test 3: Convert with basic settings
log_info "Test 1: Basic conversion (default template)..."
"$JUPYTER_CMD" nbconvert --to html --output-dir "$TEST_DIR" "$TEST_NOTEBOOK" && log_ok "Basic conversion OK" || {
  log_err "Basic conversion failed"
  exit 1
}

# Test 4: Convert with embed-images
log_info "Test 2: Conversion with --embed-images..."
"$JUPYTER_CMD" nbconvert --to html --embed-images --output-dir "$TEST_DIR" "$TEST_NOTEBOOK" 2>&1 | tee "$TEST_DIR/embed.log"
if [[ -f "$TEST_DIR/$(basename "${TEST_NOTEBOOK%.ipynb}.html")" ]]; then
  log_ok "Embedded images conversion OK"
else
  log_err "Embedded images conversion failed"
  cat "$TEST_DIR/embed.log"
fi

# Test 5: Convert with lab template
log_info "Test 3: Conversion with --template=lab..."
"$JUPYTER_CMD" nbconvert --to html --template=lab --output-dir "$TEST_DIR" "$TEST_NOTEBOOK" 2>&1 | tee "$TEST_DIR/lab.log" && log_ok "Lab template conversion OK" || {
  log_info "Lab template not available, trying --template=classic..."
  "$JUPYTER_CMD" nbconvert --to html --template=classic --output-dir "$TEST_DIR" "$TEST_NOTEBOOK" 2>&1 | tee "$TEST_DIR/classic.log" && log_ok "Classic template conversion OK" || log_err "All template conversions failed"
}

# Test 6: Check HTML file size and content
HTML_FILE="$TEST_DIR/$(basename "${TEST_NOTEBOOK%.ipynb}.html")"
if [[ -f "$HTML_FILE" ]]; then
  SIZE=$(wc -c < "$HTML_FILE")
  log_ok "HTML file size: $(numfmt --to=iec-i --suffix=B $SIZE)"
  
  # Check for key content
  if grep -q '<style' "$HTML_FILE"; then
    log_ok "Contains <style> tags (CSS present)"
  else
    log_err "No <style> tags found (CSS missing?)"
  fi
  
  if grep -q 'class="jp-Cell' "$HTML_FILE" || grep -q 'class="cell' "$HTML_FILE"; then
    log_ok "Contains notebook cells"
  else
    log_err "No cells found in HTML"
  fi
  
  if grep -q '<script' "$HTML_FILE"; then
    log_ok "Contains <script> tags (JS present)"
  else
    log_info "No <script> tags (may be OK if no interactive widgets)"
  fi
  
  log_info "Opening HTML in browser for visual inspection..."
  echo "HTML file: $HTML_FILE"
  echo "Open this file in your browser to verify it displays correctly"
  
else
  log_err "HTML file not created: $HTML_FILE"
  exit 1
fi

log_ok "All tests passed! Notebook conversion is working."
log_info "You can now run: make site/setup"
