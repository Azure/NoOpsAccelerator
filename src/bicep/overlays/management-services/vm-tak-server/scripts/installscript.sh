# !/bin/bash
echo "Running script (from GHx1a) to begin the install process for TAK Server, it will take a while so please be patient."

# source global_vars.sh add var here since global_var can not be read from vm extention 
project="TakImage"
#rpm_source="https://noopsblobstorage.blob.core.usgovcloudapi.net/anoatak?sp=r&st=2022-12-12T19:49:50Z&se=2022-12-13T03:49:50Z&spr=https&sv=2021-06-08&sr=c&sig=g96F343Gw4ZBp%2FlVX3aZj42XOPUclUZgBWH6loQgEIs%3D"

DATE_NOW=$(date -Ru | sed 's/\+0000/GMT/')
AZ_VERSION="2022-12-12"
AZ_BLOB_URL="https://noopsblobstorage.blob.core.usgovcloudapi.net"
AZ_BLOB_CONTAINER="anoatak"
AZ_BLOB_SOURCEDIR="rpm_source_files"
AZ_BLOB_TARGET="${AZ_BLOB_URL}/${AZ_BLOB_CONTAINER}/${AZ_BLOB_SOURCEDIR}/"
AZ_SAS_TOKEN="sp=r&st=2022-12-12T22:18:29Z&se=2022-12-13T06:18:29Z&spr=https&sv=2021-06-08&sr=b&sig=SLHeiHlGmWS9qAM4PSsuBJSEKHRipIBtJfLI1BqfZqo%3D"

script_home=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

echo 'cd ~' >> /root/.bashrc

# Install postgresql
curl "${AZ_BLOB_TARGET}postgresql14-14.6-1PGDG.rhel7.x86_64.rpm?${AZ_SAS_TOKEN}" --output takdb.rpm

[[ ! -f "${script_home}/takdb.rpm" ]] && exit 1

yum install "${script_home}/takdb.rpm" --nogpgcheck

# Install Tak server
curl "${AZ_BLOB_TARGET}takserver-4.7-RELEASE20.noarch.rpm${AZ_SAS_TOKEN}"" --output takserver.rpm

[[ ! -f "${script_home}/takserver.rpm" ]] && exit 1

yum -y localinstall "${script_home}/takserver.rpm" --nogpgcheck

# Configure Tak Server
/bin/bash /opt/tak/db-utils/takserver-setup-db.sh

grep -m1 'keystorePass' /opt/tak/CoreConfig.example.xml | awk -F\" '{print $6}' > "${script_home}/.jks"
echo "ftpuser:ftpuser$(seq -s. 4 | tr -d '.')" > "${script_home}/.ftp"
echo "$(openssl $(openssl / 2>&1 | head -9 | tail -1 | awk '{print $3}') --help 2>&1 | head -1 | awk '{print substr($2,1,4)}' | sed 's/.*/\u&/')4marti$(seq -s. 4 | tr -d '.')"'!' > "${script_home}/.marti"

sed -i "s/#DBP/$(grep connection /opt/tak/CoreConfig.example.xml | awk -F\" '{print $6}')/g" "${script_home}/CoreConfig.xml"
sed -i "s/#SS/$(hostname -A | awk -F. '{print $2}')/g" "${script_home}/CoreConfig.xml"
sed -i "s/#JKS/$(cat ${script_home}/.jks)/g" "${script_home}/CoreConfig.xml"

rm -f ${script_home}/takserver.rpm
rm -rf ${script_home}/${project}-main

yum -y update
###
