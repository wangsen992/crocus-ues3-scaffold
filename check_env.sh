#!/bin/bash
# ===========================================
# Environment Check Script
# ===========================================
#
# Verifies that the CROCUS-UES3 environment is properly configured
# for container operations.
#
# Usage:
#   source check_env.sh     # Source to use in other scripts
#   ./check_env.sh          # Run standalone with exit code
#   ./check_env.sh --fix    # Auto-create missing directories
#
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Project root - configurable via CROCUS_ROOT env var
if [ -n "${CROCUS_ROOT}" ]; then
    PROJECT_ROOT="${CROCUS_ROOT}"
else
    # Default: assume this script is in containers/*/
    PROJECT_ROOT="${SCRIPT_DIR}/../../"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS() { echo -e "${GREEN}[PASS]${NC} $1"; }
FAIL() { echo -e "${RED}[FAIL]${NC} $1"; }
WARN() { echo -e "${YELLOW}[WARN]${NC} $1"; }
INFO() { echo -e "${BLUE}[INFO]${NC} $1"; }

show_help() {
    cat << EOF
Usage: ./check_env.sh [OPTIONS]

Check CROCUS-UES3 environment configuration for container operations.

Options:
    --fix       Auto-create missing directories
    --verbose   Show detailed output
    --help      Show this help

Environment Variables:
    CROCUS_ROOT     Path to CROCUS-UES3 project root
                    (defaults to ../.. from script location)

Required Bind Mounts:
    \$CROCUS_ROOT/       Project root directory
    \$CROCUS_ROOT/run/   Simulation cases directory
    \$CROCUS_ROOT/cases/ Case symlinks directory

Examples:
    ./check_env.sh               # Check configuration
    ./check_env.sh --fix         # Create missing dirs
    CROCUS_ROOT=/path/to/proj ./check_env.sh
EOF
}

# Check if running standalone or sourced
STANDALONE=1
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    STANDALONE=0
fi

# Options
AUTO_FIX=0
VERBOSE=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix) AUTO_FIX=1; shift ;;
        --verbose) VERBOSE=1; shift ;;
        --help|-h) show_help; exit 0 ;;
        *) shift ;;
    esac
done

# ===========================================
# Checks
# ===========================================

ERRORS=0
WARNINGS=0

INFO "CROCUS-UES3 Environment Check"
INFO "=============================="
INFO ""

# 1. Check CROCUS_ROOT
INFO "Project Root: ${PROJECT_ROOT}"
if [ -z "${CROCUS_ROOT}" ]; then
    WARN "CROCUS_ROOT not set, using default: ${PROJECT_ROOT}"
fi

# 2. Check project root exists
if [ -d "${PROJECT_ROOT}" ]; then
    PASS "Project root exists: ${PROJECT_ROOT}"
else
    FAIL "Project root not found: ${PROJECT_ROOT}"
    INFO "Set CROCUS_ROOT environment variable to point to your project"
    ERRORS=$((ERRORS + 1))
fi

# 3. Check run/ directory
RUN_DIR="${PROJECT_ROOT}/run"
if [ -d "${RUN_DIR}" ]; then
    PASS "run/ directory exists: ${RUN_DIR}"
    if [ -w "${RUN_DIR}" ]; then
        PASS "run/ is writable"
    else
        FAIL "run/ is not writable"
        ERRORS=$((ERRORS + 1))
    fi
else
    if [ ${AUTO_FIX} -eq 1 ]; then
        WARN "Creating run/ directory..."
        mkdir -p "${RUN_DIR}"
        PASS "Created: ${RUN_DIR}"
    else
        FAIL "run/ directory not found: ${RUN_DIR}"
        INFO "Set CROCUS_ROOT to your project root"
        ERRORS=$((ERRORS + 1))
    fi
fi

# 4. Check cases/ directory
CASES_DIR="${PROJECT_ROOT}/cases"
if [ -d "${CASES_DIR}" ]; then
    PASS "cases/ directory exists: ${CASES_DIR}"
else
    if [ ${AUTO_FIX} -eq 1 ]; then
        WARN "Creating cases/ directory..."
        mkdir -p "${CASES_DIR}"
        PASS "Created: ${CASES_DIR}"
    else
        WARN "cases/ directory not found: ${CASES_DIR}"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# 5. Check for essential subdirectories in run/
INFO ""
INFO "Checking simulation cases in run/..."
if [ -d "${RUN_DIR}" ]; then
    CASE_COUNT=0
    for case_dir in "${RUN_DIR}"/*/; do
        if [ -d "${case_dir}" ]; then
            CASE_NAME=$(basename "${case_dir}")
            if [ ${VERBOSE} -eq 1 ]; then
                INFO "  Found case: ${CASE_NAME}"
            fi
            CASE_COUNT=$((CASE_COUNT + 1))
        fi
    done
    if [ ${CASE_COUNT} -gt 0 ]; then
        PASS "Found ${CASE_COUNT} case(s) in run/"
    else
        WARN "No cases found in run/"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# 6. Check Apptainer availability
INFO ""
INFO "Checking Apptainer..."
if command -v apptainer &> /dev/null; then
    APPTAINER_VERSION=$(apptainer --version 2>&1 | head -1)
    PASS "Apptainer available: ${APPTAINER_VERSION}"
else
    FAIL "Apptainer not found in PATH"
    INFO "Install Apptainer or load module: module load apptainer"
    ERRORS=$((ERRORS + 1))
fi

# ===========================================
# Summary
# ===========================================

INFO ""
INFO "=============================="
if [ ${ERRORS} -eq 0 ] && [ ${WARNINGS} -eq 0 ]; then
    PASS "All checks passed!"
    exit 0
elif [ ${ERRORS} -eq 0 ]; then
    WARN "Checks passed with ${WARNINGS} warning(s)"
    exit 0
else
    FAIL "Checks failed with ${ERRORS} error(s)"
    INFO ""
    INFO "To fix, run: export CROCUS_ROOT=/path/to/CROCUS-UES3"
    INFO "         ./check_env.sh --fix"
    exit 1
fi