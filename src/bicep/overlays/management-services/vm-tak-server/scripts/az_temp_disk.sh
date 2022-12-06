#!/bin/bash

source global_vars.sh

# If the swap disk is enabled via waagent, then there is no need to create an initial swap file
[[ -n $(grep "EnableSwap=y" /etc/waagent.conf) ]] && exit

res_disk="/mnt/resource"

# Check if we have an Azure resource disk and continue to do so over a 5 minute period
# If there is no disk after 5 minutes, this machine probably does not have one
mountpoint -q "$res_disk"
has_res_disk=$?
for ((i=0;i<60;i++)); do
  sleep 10
  mountpoint -q "$res_disk"
  has_res_disk=$?
  [[ $has_res_disk -eq 0 ]] && i=61
  [[ $has_res_disk -eq 0 && $i -eq 59 ]] && exit 1
done

# Use half of the disk for a swapfile
disk_size=$(df -m "$res_disk" | sed '1d' | awk '{print $2}')
swap_size=$((disk_size/2))

# Configure waagent to create the swap file for us on reboot
sed -i 's/ResourceDisk.EnableSwap=n/ResourceDisk.EnableSwap=y/g' /etc/waagent.conf
sed -i "s/ResourceDisk.SwapSizeMB=0/ResourceDisk.SwapSizeMB=${swap_size}/g" /etc/waagent.conf

# Create an initial swapfile to use right now (so we don't have to reboot)
dd if=/dev/zero of=${res_disk}/swapfile count=${swap_size} bs=1MiB
chmod 600 ${res_disk}/swapfile

# Make a swap file and keep trying until we succeed
# This is mainly to try again as certain race conditions can cause a failure the first time
# We should not get stuck in this loop forever... but anything is possible
/sbin/mkswap ${res_disk}/swapfile
rc=$?
while [[ $rc -gt 0 ]]; do
  sleep 10
  /sbin/mkswap ${res_disk}/swapfile
  rc=$?
done

# Enable the swap file and keep trying until we succeed
# Again, race conditions....
/sbin/swapon ${res_disk}/swapfile
swap=$(/sbin/swapon -s | grep "${res_disk}/swapfile" | awk '{print $1}')
while [[ "$swap" != "${res_disk}/swapfile" ]]; do
sleep 10
  /sbin/swapon ${res_disk}/swapfile
  swap=$(/sbin/swapon ${res_disk}/swapfile | grep "${res_disk}/swapfile" | awk '{print $1}')
done
