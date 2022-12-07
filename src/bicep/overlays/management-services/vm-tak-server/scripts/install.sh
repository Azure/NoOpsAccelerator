#!/bin/bash

# source global_vars.sh
project="TakImage"

# Add crontab entries to remove CentOS default repos on reboot and add init script
if [[ -z $(crontab -l | grep 'init_server.sh') ]]; then
  (crontab -l ; echo "@reboot /bin/bash ${script_home}/init_server.sh") | crontab -
fi
if [[ -z $(crontab -l | grep '/bin/rm -f /etc/yum.repos.d/CentOS*') ]]; then
  (crontab -l ; echo "@reboot /bin/rm -f /etc/yum.repos.d/CentOS*") | crontab -
fi

echo 'cd ~' >> /root/.bashrc
### Add other setup commands / scripts here:
# GitHub Personal Access Token (pat) should be passed as custom data to VM 
pat=$(base64 -d /var/lib/waagent/CustomData | awk -F[/@] '{print $3}')

# Download the codebase from github
# The idea is that you would pass your PAT as custom data, copy and paste this script, then download everything else. Not perfect, but ¯\_(ツ)_/¯
curl -fskSL -o "${script_home}/install.zip" "https://${pat}@dev.s2va.us/Workloads/${project}/archive/refs/heads/main.zip"

[[ ! -f "${script_home}/install.zip" ]] && echo "install.zip not found!" && exit 1

unzip "${script_home}/install.zip"

rm -f "${script_home}/${project}-main/install.sh" || exit 1
rm -f "${script_home}/${project}-main/README.md" || exit 1

mv ${script_home}/${project}-main/* ${script_home}
chmod u+x ${script_home}/*.sh

# Remove default repos and add the Azure ones
rm -f /etc/yum.repos.d/CentOS*
cp "${script_home}/centos.repo" /etc/yum.repos.d
yum clean all

# Install postgres
yum -y install postgresql10-server unzip

# TakServer version 4.6.26 is attached to the GitHub repo as a release
# As long as your pat has read permissions to the repo, takserver will be downloaded
curl -fskSL -o "${script_home}/takserver.rpm" "https://${pat}@media.dev.s2va.us/releases/8/files/2"

[[ ! -f "${script_home}/takserver.rpm" ]] && exit 1

yum -y localinstall "${script_home}/takserver.rpm" --nogpgcheck
/bin/bash /opt/tak/db-utils/takserver-setup-db.sh

grep -m1 'keystorePass' /opt/tak/CoreConfig.example.xml | awk -F\" '{print $6}' > "${script_home}/.jks"
echo "ftpuser:ftpuser$(seq -s. 4 | tr -d '.')" > "${script_home}/.ftp"
echo "$(openssl $(openssl / 2>&1 | head -9 | tail -1 | awk '{print $3}') --help 2>&1 | head -1 | awk '{print substr($2,1,4)}' | sed 's/.*/\u&/')4marti$(seq -s. 4 | tr -d '.')"'!' > "${script_home}/.marti"

sed -i "s/#DBP/$(grep connection /opt/tak/CoreConfig.example.xml | awk -F\" '{print $6}')/g" "${script_home}/CoreConfig.xml"
sed -i "s/#SS/$(hostname -A | awk -F. '{print $2}')/g" "${script_home}/CoreConfig.xml"
sed -i "s/#JKS/$(cat ${script_home}/.jks)/g" "${script_home}/CoreConfig.xml"

rm -f ${script_home}/install.zip
rm -f ${script_home}/takserver.rpm
rm -rf ${script_home}/${project}-main

yum -y update
###
