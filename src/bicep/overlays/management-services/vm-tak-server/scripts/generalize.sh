#!/bin/bash

source global_vars.sh

# Don't keep bash history for the rest of the session
export HISTFILESIZE=0
export HISTSIZE=0

# Stop auditd for the rest of the session and turn off swap if applicable
service auditd stop
systemctl disable auditd
swapoff /mnt/resource/swapfile
### Put other services to disable here:
systemctl stop takserver
/sbin/chkconfig takserver off
###

# Delete the swapfile, any CustomData passed by Azure as well as our internal CA
rm -f "${script_home}/install.sh"
rm -f /mnt/resource/swapfile
rm -f /var/lib/waagent/CustomData
rm -f /etc/pki/ca-trust/source/anchors/ca.pem
find /usr/local/scap/* -type d -prune -exec rm -r {} +
### Put other files to delete here:
rm -f "${script_home}/pref/*.zip"
rm -rf /opt/tak/certs/files
rm -f /opt/tak/logs/*
rm -f /opt/tak/CoreConfig.xml
echo "erase" | /opt/tak/db-utils/takserver-setup-db.sh
###

# Truncate all the logs
logs=($(find /var/log -type f))
for log in "${logs[@]}"; do
  cat /dev/null > "$log"
done

# Truncate all audits
audit_logs=($(find /var/log/audit -type f))
for audit_log in "${audit_logs[@]}"; do
  rm -f "$audit_log"
done

# Truncate all history files
homes=($(cat /etc/passwd | awk -F: '{print $6}'))
history_file=".bash_history"
for home in "${homes[@]}"; do
  if [[ -f "${home}/${history_file}" ]]; then
  cat /dev/null > "${home}/${history_file}"
  fi
done

# Deprovision the waagent
/sbin/waagent -deprovision+user

### Put firewall rules to disable here:
firewall-cmd --remove-port=8080/tcp --permanent
firewall-cmd --remove-port=8089/tcp --permanent
firewall-cmd --remove-port=8444/tcp --permanent
firewall-cmd --remove-port=8445/tcp --permanent
###

# Revert the waagent conf to not provision swap space
swap_size=$(grep 'ResourceDisk.SwapSizeMB' /etc/waagent.conf | awk -F= '{print $2}')
sed -i 's/ResourceDisk.EnableSwap=y/ResourceDisk.EnableSwap=n/g' /etc/waagent.conf
sed -i "s/ResourceDisk.SwapSizeMB=${swap_size}/ResourceDisk.SwapSizeMB=0/g" /etc/waagent.conf

# re-enable auditd so it will run on next boot and update ca trust to remove our internal CA
systemctl enable auditd
update-ca-trust enable
update-ca-trust extract
### Put other services to enable here:

###

# Prompt for a shutdown, if "yes" clear root history a final time and shutdown
read -p "shutdown now?" shutdown
if [[ "${shutdown,,}" == "y" ]]; then
  history -w
  history -c && init 0
fi
