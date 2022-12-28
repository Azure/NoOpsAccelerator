# !/bin/bash
echo "Running script (from GHx1228a) to begin the install process for TAK Server, it will take a while so please be patient."


# source global_vars.sh add var here since global_var can not be read from vm extention 
project="TakImage"
DATE_NOW=$(date -Ru | sed 's/\+0000/GMT/')
AZ_VERSION="2022-12-12"
AZ_BLOB_URL="https://noopsblobstorage.blob.core.usgovcloudapi.net"
AZ_BLOB_CONTAINER="anoatak"
AZ_BLOB_SOURCEDIR="rpm_source_files"
AZ_BLOB_TARGET="${AZ_BLOB_URL}/${AZ_BLOB_CONTAINER}/${AZ_BLOB_SOURCEDIR}/"
AZ_SAS_TOKEN="sp=r&st=2022-12-20T18:13:17Z&se=2022-12-30T02:13:17Z&spr=https&sv=2021-06-08&sr=c&sig=SPPo8fOZ7RW1%2FpgH4ypzpebB%2BKbPN%2Bgnws4uerk2fBM%3D"

script_home=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

echo 'cd ~' >> /root/.bashrc

# increase system limit for number of concurrent TCP connections
echo -e "* soft nofile 32768\n* hard nofile 32768" | sudo tee --append /etc/security/limits.conf > /dev/null
echo "Running script Line 21."
 
# install epel
sudo yum install epel-release -y
echo "Running script Line 25 epel-release install."

# Install postgresql
# curl "${AZ_BLOB_TARGET}postgresql14-14.6-1PGDG.rhel7.x86_64.rpm?${AZ_SAS_TOKEN}" --output takdb.rpm

# [[ ! -f "${script_home}/takdb.rpm" ]] && exit 1
# sudo chmod +x "takdb.rpm"
# sudo yum -y localinstall "${script_home}/takdb.rpm" --nogpgcheck

sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
echo "Running script Line 34 Install postgres yum repository"

# yum update
# sudo yum update -y
echo "Running line 38 yum update"

# Install Tak server
curl "${AZ_BLOB_TARGET}takserver-4.7-RELEASE20.noarch.rpm?${AZ_SAS_TOKEN}" --output takserver.rpm
# echo "Running line 42 curl takserver

# [[ ! -f "${script_home}/takserver.rpm" ]] && exit 1
sudo chmod +x "takserver.rpm"
sudo yum -y localinstall "${script_home}/takserver.rpm" --nogpgcheck
echo "Running line 46 install takserver"

# configure tak server
echo "Running TAK Server config
sudo /opt/tak/db-utils/takserver-setup-db.sh
sudo systemctl daemon-reload
sudo systemctl start takserver
sudo systemctl enable takserver
sudo systemctl start firewalld
sudo systemctl enable firewalld
exit
