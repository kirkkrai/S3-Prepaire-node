#!/usr/bin/env bash
# ==============================================================================
# Script: install-cephadm.sh
# Purpose: Minimal Setup - Install Podman & Cephadm CLI (Version 20.2.0)
# Lab: kengkobkoy
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

declare -a CHECK_NAMES
declare -a CHECK_STATUS

record_check() {
    local name="$1"
    local status="$2"
    CHECK_NAMES+=("$name")
    CHECK_STATUS+=("$status")
    if [ "$status" == "PASS" ]; then
        echo -e "  ${GREEN}✔ [PASS]${NC} $name"
    else
        echo -e "  ${RED}✘ [FAIL]${NC} $name"
    fi
}

echo -e "${BOLD}${CYAN}==============================================================${NC}"
echo -e "${BOLD}${CYAN}          Ceph Lab: Install Podman & Cephadm (20.2.0)         ${NC}"
echo -e "${BOLD}${CYAN}==============================================================${NC}"
echo -e "Host: $(hostname) | Date: $(date)\n"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run this script as root (sudo bash install-cephadm.sh)${NC}"
    exit 1
fi

# ------------------------------------------------------------------------------
# Step 1: Install Podman Container Runtime
# ------------------------------------------------------------------------------
echo -e "${BOLD}[1/2] Installing Podman...${NC}"
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

apt-get -o DPkg::Lock::Timeout=60 update -y
if apt-get -o DPkg::Lock::Timeout=60 -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y podman curl; then
    record_check "Podman Installation" "PASS"
else
    record_check "Podman Installation" "FAIL"
fi

# ------------------------------------------------------------------------------
# Step 2: Download & Install cephadm binary to /usr/local/bin
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[2/2] Installing cephadm CLI (Version 20.2.0)...${NC}"
CEPH_RELEASE=20.2.0

if curl -fsSL "https://download.ceph.com/rpm-${CEPH_RELEASE}/el9/noarch/cephadm" -o /usr/local/bin/cephadm && chmod +x /usr/local/bin/cephadm; then
    record_check "Install cephadm to /usr/local/bin" "PASS"
else
    record_check "Install cephadm to /usr/local/bin" "FAIL"
fi

# ------------------------------------------------------------------------------
# Verification
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}--- Checking Versions ---${NC}"
if command -v podman > /dev/null 2>&1; then
    echo -e "  Podman Version: ${CYAN}$(podman --version)${NC}"
fi

if command -v cephadm > /dev/null 2>&1; then
    echo -e "  Cephadm Info  : ${CYAN}$(cephadm version 2>/dev/null || echo 'cephadm binary ready')${NC}"
fi

# ------------------------------------------------------------------------------
# Final Checklist Summary
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${CYAN}==============================================================${NC}"
echo -e "${BOLD}${CYAN}                INSTALLATION CHECKLIST SUMMARY                ${NC}"
echo -e "${BOLD}${CYAN}==============================================================${NC}"
TOTAL_PASS=0
TOTAL_FAIL=0
for i in "${!CHECK_NAMES[@]}"; do
    NAME="${CHECK_NAMES[$i]}"
    STATUS="${CHECK_STATUS[$i]}"
    if [ "$STATUS" == "PASS" ]; then
        echo -e " [ ✔ ] ${GREEN}SUCCESS${NC} : $NAME"
        ((TOTAL_PASS++))
    else
        echo -e " [ ✘ ] ${RED}FAILED ${NC} : $NAME"
        ((TOTAL_FAIL++))
    fi
done
echo -e "--------------------------------------------------------------"
echo -e " Results: ${GREEN}${TOTAL_PASS} Passed${NC} | ${RED}${TOTAL_FAIL} Failed${NC}"
if [ "$TOTAL_FAIL" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}>>> PODMAN & CEPHADM INSTALLATION COMPLETED! <<<${NC}"
else
    echo -e "${RED}${BOLD}>>> SOME STEPS FAILED! Please check errors above. <<<${NC}"
fi
echo -e "${BOLD}${CYAN}==============================================================${NC}"
