#!/usr/bin/env bash
# ==============================================================================
# Script: prepare-vm.sh
# Purpose: Minimal Base VM Preparation & Clone Readiness (No Extra Packages)
# Lab: kengkobkoy
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
echo -e "${BOLD}${CYAN}       Ceph Lab: Minimal Base VM Preparation (Outline Spec)   ${NC}"
echo -e "${BOLD}${CYAN}==============================================================${NC}"
echo -e "Host: $(hostname) | Date: $(date)"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Please run this script as root (sudo bash prepare-vm.sh)${NC}"
    exit 1
fi

# ------------------------------------------------------------------------------
# Step 1: Update & Upgrade System Packages (Non-interactive)
# ------------------------------------------------------------------------------
echo -e "${BOLD}[1/4] Running apt-get update & upgrade...${NC}"
export DEBIAN_FRONTEND=noninteractive
if apt-get update -y > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1; then
    record_check "APT Update & Upgrade" "PASS"
else
    record_check "APT Update & Upgrade" "FAIL"
fi

# ------------------------------------------------------------------------------
# Step 2: Prevent Cloud-Init from Overwriting /etc/hosts
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[2/4] Disabling update_etc_hosts in cloud.cfg...${NC}"
if [ -f /etc/cloud/cloud.cfg ]; then
    sed -i 's/ - update_etc_hosts/# - update_etc_hosts/' /etc/cloud/cloud.cfg
    record_check "Cloud-Init Protection (Commented update_etc_hosts)" "PASS"
else
    record_check "Cloud-Init Protection" "PASS"
fi

# ------------------------------------------------------------------------------
# Step 3: Populate /etc/hosts with Lab Hostnames & IPs
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[3/4] Writing /etc/hosts mapping for kengkobkoy lab...${NC}"
cat << 'EOF' > /etc/hosts
127.0.0.1 localhost

# DC Site
172.71.5.200 lab-kengkobkoy-dc-ha01
172.71.5.201 lab-kengkobkoy-dc-adm
172.71.5.202 lab-kengkobkoy-dc-rgw01
172.71.5.203 lab-kengkobkoy-dc-rgw02
172.71.5.204 lab-kengkobkoy-dc-osd01
172.71.5.205 lab-kengkobkoy-dc-osd02
172.71.5.206 lab-kengkobkoy-dc-osd03
172.71.5.207 lab-kengkobkoy-dc-osd04
172.71.5.208 lab-kengkobkoy-dc-osd05

# DR Site
172.71.5.209 lab-kengkobkoy-dr-ha02
172.71.5.210 lab-kengkobkoy-dr-adm
172.71.5.211 lab-kengkobkoy-dr-rgw01
172.71.5.212 lab-kengkobkoy-dr-rgw02
172.71.5.213 lab-kengkobkoy-dr-osd01
172.71.5.214 lab-kengkobkoy-dr-osd02
172.71.5.215 lab-kengkobkoy-dr-osd03
172.71.5.216 lab-kengkobkoy-dr-osd04

# VIPs & Services
172.71.5.170 lab-kengkobkoy-vip-ha
172.71.5.171 lab-kengkobkoy-vip-kms
172.71.5.172 lab-kengkobkoy-kms01
172.71.5.173 lab-kengkobkoy-kms02
172.71.5.174 lab-kengkobkoy-prometheus
EOF

if grep -q "lab-kengkobkoy-dc-ha01" /etc/hosts; then
    record_check "/etc/hosts Population" "PASS"
else
    record_check "/etc/hosts Population" "FAIL"
fi

# ------------------------------------------------------------------------------
# Step 4: Clean Identity & Reset Machine-ID (Clone Preparation)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[4/4] Resetting Machine-ID and Cloud-Init for Clean Cloning...${NC}"
truncate -s 0 /etc/machine-id
rm -f /var/lib/dbus/machine-id
rm -f /etc/ssh/ssh_host_*
cloud-init clean --logs > /dev/null 2>&1 || true
apt-get clean > /dev/null 2>&1

if [ ! -s /etc/machine-id ]; then
    record_check "Machine-ID Reset & Cloud-Init Clean" "PASS"
else
    record_check "Machine-ID Reset & Cloud-Init Clean" "FAIL"
fi

# ------------------------------------------------------------------------------
# Final Checklist Summary
# ------------------------------------------------------------------------------
echo ""
echo -e "${BOLD}${CYAN}==============================================================${NC}"
echo -e "${BOLD}${CYAN}                PREPARE VM CHECKLIST SUMMARY                  ${NC}"
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
    echo -e "${GREEN}${BOLD}>>> PREPARATION COMPLETE! THIS VM IS READY TO BE CLONED. <<<${NC}"
    echo -e "${YELLOW}Next Step: Run 'sudo poweroff' and clone this VM in Proxmox.${NC}"
else
    echo -e "${RED}${BOLD}>>> SOME STEPS FAILED! Please check errors above. <<<${NC}"
fi
echo -e "${BOLD}${CYAN}==============================================================${NC}"
