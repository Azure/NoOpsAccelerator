# !/bin/bash
echo "Running script to begin the install process for TAK Server, it will take a while so please be patient."

# source global_vars.sh add var here since global_var can not be read from vm extention 
project="TakImage"
RPM_TAKsource="https://noopsblobstorage.blob.core.usgovcloudapi.net/anoatak/takserver-4.7-RELEASE20.noarch.rpm?sp=r&st=2022-12-07T21:04:48Z&se=2022-12-08T05:04:48Z&spr=https&sv=2021-06-08&sr=b&sig=qJnBj3clNgOv4yqBj4593gEC%2F0DfaV5djZO3NT1acJE%3D"
RPM_DBsource="https://noopsblobstorage.blob.core.usgovcloudapi.net/anoatak/postgresql14-14.6-1PGDG.rhel7.x86_64.rpm?sp=r&st=2022-12-07T21:08:14Z&se=2022-12-08T05:08:14Z&spr=https&sv=2021-06-08&sr=b&sig=Sl1vKdwIDgEkYNq3VLBPTmoqnlZiULzJzLKnue5Z83M%3D"
# new from takimage-main
script_home=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

echo 'cd ~' >> /root/.bashrc

# Install postgresql
curl -fskSL -o "${RPM_DBsource}/postgresql14-14.6-1PGDG.rhel7.x86_64.rpm" "${script_home}/takdb.rpm"

[[ ! -f "${script_home}/takdb.rpm" ]] && exit 1

yum -y localinstall "${script_home}/takdb.rpm" --nogpgcheck

# Install Tak server
curl -fskSL -o "${RPM_TAKsource}/takserver-4.7-RELEASE20.noarch.rpm" "${script_home}/takserver.rpm"

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
