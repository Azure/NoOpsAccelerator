# !/bin/bash
echo "Running script (from GHx1220a) to begin the install process for TAK Server, it will take a while so please be patient."

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

# install epel
sudo yum install epel-release -y

# Install postgresql
# curl "${AZ_BLOB_TARGET}postgresql14-14.6-1PGDG.rhel7.x86_64.rpm?${AZ_SAS_TOKEN}" --output takdb.rpm

# [[ ! -f "${script_home}/takdb.rpm" ]] && exit 1
# sudo chmod +x "takdb.rpm"
# sudo yum -y localinstall "${script_home}/takdb.rpm" --nogpgcheck

sudo yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm -y

# Install Tak server
curl "${AZ_BLOB_TARGET}takserver-4.7-RELEASE20.noarch.rpm?${AZ_SAS_TOKEN}" --output takserver.rpm

# [[ ! -f "${script_home}/takserver.rpm" ]] && exit 1
sudo chmod +x "takserver.rpm"
sudo yum -y localinstall "${script_home}/takserver.rpm" --nogpgcheck

# Configure Tak Server
# /bin/bash /opt/tak/db-utils/takserver-setup-db.sh

#grep -m1 'keystorePass' /opt/tak/CoreConfig.example.xml | awk -F\" '{print $6}' > "${script_home}/.jks"
# echo "ftpuser:ftpuser$(seq -s. 4 | tr -d '.')" > "${script_home}/.ftp"
# echo "$(openssl $(openssl / 2>&1 | head -9 | tail -1 | awk '{print $3}') --help 2>&1 | head -1 | awk '{print substr($2,1,4)}' | sed 's/.*/\u&/')4marti$(seq -s. 4 | tr -d '.')"'!' > "${script_home}/.marti"

# sed -i "s/#DBP/$(grep connection /opt/tak/CoreConfig.example.xml | awk -F\" '{print $6}')/g" "${script_home}/CoreConfig.xml"
# sed -i "s/#SS/$(hostname -A | awk -F. '{print $2}')/g" "${script_home}/CoreConfig.xml"
# sed -i "s/#JKS/$(cat ${script_home}/.jks)/g" "${script_home}/CoreConfig.xml"

# rm -f ${script_home}/takserver.rpm
#rm -rf ${script_home}/${project}-main

yum -y update
###
