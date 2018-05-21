#!/bin/bash
#
# bootstrap.sh - run on boot to check if the system should self-provision
#

# Setup Colors
RESET='\033[0m'     # Reset
RED='\033[0;31m'    # Red
GREEN='\033[0;32m'  # Green
BLUE='\033[0;34m'   # Blue

OUTPUT='/tmp/roles_selected'

if ! [[ $(id -u) = 0 ]]; then
    echo -e "${RED}This script must be run as root${RESET}" 1>&2
    exit 1
fi

if [[ $SUDO_USER ]]; then
    real_user=$SUDO_USER
else
    real_user=$(whoami)
fi

read -r -p "Is $real_user the correct user to install configuration? [y/N] " UPGRADE_RESPONSE
if ! [[ "$UPGRADE_RESPONSE" =~ ^(Y|y)$ ]]; then
    echo -e "${RED}Exiting...${RESET}"
    exit 1
fi

print_heading() {
    local HEADING=$1
    echo ""
    echo -e "${BLUE}=> ${HEADING}${RESET}"
}

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Successful${RESET}"
    else
        echo -e "${RED}Failed${RESET}"
    fi
}

install_package() {
    local PACKAGE=$1
    echo -n "[+] Installing ${PACKAGE}..."
    apt install $PACKAGE -y &> /dev/null
    check_status
}

update_cache() {
    echo -n "[+] Updating package cache..."
    apt update &> /dev/null
    check_status
}

wait_for_apt_lock() {
    print_heading "Waiting for dpkg lock"
    while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock &> /dev/null; do
       sleep 1
    done
    check_status
}

cleanup() {
    rm -f ${OUTPUT}
    print_heading "Restoring playbook.yml"
    git checkout -- playbook.yml
    check_status
}

trap cleanup exit

update_cache
print_heading "Installing Playbook Dependencies"
install_package aptitude
install_package dialog
install_package software-properties-common
install_package apt-transport-https
install_package python
install_package python-pip
install_package git

sudo apt-add-repository ppa:ansible/ansible -y &> /dev/null
update_cache
install_package ansible

wait_for_apt_lock

export ANSIBLE_NOCOWS=1

ROLE_LIST=""
ROLE_ITERATOR=0
for role in $(ls roles); do
    ROLE_ITERATOR=$((${ROLE_ITERATOR}+1))
    ROLES[${ROLE_ITERATOR}]="$role"
    ROLE_LIST="${ROLE_LIST}${ROLE_ITERATOR} '${role}' off "
done

dialog  --backtitle "Select Ansible Roles to Run" \
        --title "Ansible Role Selector" \
        --checklist "Select Ansible Roles to Run:" 15 40 10 \
        $ROLE_LIST 2>$OUTPUT

ROLE_BLOCK="roles:"
for index in $(cat $OUTPUT); do
    ROLE_BLOCK="${ROLE_BLOCK}\n      - ${ROLES[$index]}"
done

sed -i "s/\[ROLES_HERE\]/${ROLE_BLOCK}/" playbook.yml 

print_heading "Running Playbook as $real_user"
sudo -u $real_user ansible-playbook -v playbook.yml -i hosts -c local
if [[ $? -eq 0 ]]; then
    echo ""
    echo ""
    echo -e "${GREEN}Everything ran successfully!${RESET}"
    echo ""
else
    echo ""
    echo ""
    echo -e "${RED}Ansible has failed!${RESET}"
    echo ""
    read -r -p "Would you like to re-run the playbook? [y/N] " RERUN_RESPONSE
    if [[ "$RERUN_RESPONSE" =~ ^(Y|y)$ ]]; then
        sudo -u $real_user ansible-playbook playbook.yml -i hosts -c local
    fi
fi
