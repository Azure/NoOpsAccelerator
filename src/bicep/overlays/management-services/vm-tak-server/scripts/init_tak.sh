#!/bin/bash

[[ -f "/opt/tak/CoreConfig.xml" ]] && exit

source global_vars.sh

export RANDFILE=/root/.rnd

CA_NAME="SVC-CA"
CAPASS=$(cat /root/.jks)

# Setup TAKServer cert stuff
mkdir -p /opt/tak/certs/files
cp ${script_home}/san.txt /opt/tak/certs/san.cnf
cp ${script_home}/CoreConfig.xml /opt/tak/


# Server cert request
host=$(hostname)
fqdn=$(hostname -A | xargs)
ipaddr=$(hostname -I)

xmpp=$(ping -4c 1 ${xmpp_hostname} | head -2 | tail -1 | awk '{print $4}')
while [[ -z "$xmpp" ]]; do
  sleep 10
  xmpp=$(ping -4c 1 ${xmpp_hostname} | head -2 | tail -1 | awk '{print $4}')
done

sed -i "s/#HOST/${host}/g" "/opt/tak/certs/san.cnf"
sed -i "s/#FQDN/${fqdn}/g" "/opt/tak/certs/san.cnf"
sed -i "s/#IPADDR/${ipaddr}/g" "/opt/tak/certs/san.cnf"
sed -i "s/#FQDN/${fqdn}/g" "/opt/tak/CoreConfig.xml"
sed -i "s/#XMPP/${xmpp}/g" "/opt/tak/CoreConfig.xml"

openssl req -out "/opt/tak/certs/files/server.req" \
            -newkey rsa:2048 \
            -nodes \
            -keyout "/opt/tak/certs/files/server.key" \
            -config "/opt/tak/certs/san.cnf" \
            -subj "/C=/ST=/L=/O=/CN=${fqdn}"

# Server cert signing
server_cert=$(curl -d "$(cat /opt/tak/certs/files/server.req)" -X POST https://${ca_hostname}:8443/reqs)
sleep 10
curl "https://${ca_hostname}:8443/issued/${server_cert}.crt" > /opt/tak/certs/files/server.crt

[[ $? -gt 0 ]] && rm -f /opt/tak/certs/files/server.crt && exit 1

# Client cert request
openssl req -out "/opt/tak/certs/files/client.req" \
            -newkey rsa:2048 \
            -nodes \
            -keyout "/opt/tak/certs/files/client.key" \
            -subj "/C=/ST=/L=/O=/CN=ATAK"

# Client cert signing
client_cert=$(curl -d "$(cat /opt/tak/certs/files/client.req)" -X POST -H "X-Role: client" https://${ca_hostname}:8443/reqs)
sleep 10
curl "https://${ca_hostname}:8443/issued/${client_cert}.crt" > /opt/tak/certs/files/client.crt

[[ $? -gt 0 ]] && rm -f /opt/tak/certs/files/client.crt && exit 1

# Create truststore p12 and JKS
keytool -import \
        -trustcacerts \
        -file /etc/pki/ca-trust/source/anchors/ca.pem \
        -keystore /opt/tak/certs/files/truststore-root.jks \
        -alias "${CA_NAME}" \
        -storepass "${CAPASS}" \
        -noprompt

openssl pkcs12 -export \
               -in /etc/pki/ca-trust/source/anchors/ca.pem \
               -caname svc-ca \
               -nokeys \
               -out /opt/tak/certs/files/truststore-root.p12 \
               -passout pass:${CAPASS}

cp /opt/tak/certs/files/truststore-root.jks /opt/tak/certs/files/fed-truststore.jks

# Make p12 and JKS for server and client certificates
openssl pkcs12 -export \
               -in /opt/tak/certs/files/server.crt \
               -inkey /opt/tak/certs/files/server.key \
               -out /opt/tak/certs/files/takserver.p12 \
               -name TAKServer \
               -CAfile /etc/pki/ca-trust/source/anchors/ca.pem \
               -passin pass:${CAPASS} \
               -passout pass:${CAPASS}

keytool -importkeystore \
        -deststorepass "${CAPASS}" \
        -destkeypass "${CAPASS}" \
        -destkeystore /opt/tak/certs/files/takserver.jks \
        -srckeystore /opt/tak/certs/files/takserver.p12 \
        -srcstoretype PKCS12 \
        -srcstorepass "${CAPASS}" \
        -alias TAKServer

openssl pkcs12 -export \
               -in /opt/tak/certs/files/client.crt \
               -inkey /opt/tak/certs/files/client.key \
               -out /opt/tak/certs/files/client.p12 \
               -name client \
               -CAfile /etc/pki/ca-trust/source/anchors/ca.pem \
               -passin pass:${CAPASS} \
               -passout pass:${CAPASS}

# Give client cert access to web admin portal
java -jar /opt/tak/utils/UserManager.jar usermod -A -p $(cat "${script_home}/.marti") admin

# Set correct permissions on all the tak files.
chown -R tak:tak /opt/tak
chcon -R -t usr_t /opt/tak

# Create a mission package of prefs for each (30 as of now) xmpp user
for ((i=1;i<31;i++)); do
  mkdir -p "${script_home}/pref/u$(printf '%02d' $i)/MANIFEST"
  cp "${script_home}/pref/google_satellite_only.xml" "${script_home}/pref/u$(printf '%02d' $i)/"
  cp "${script_home}/pref/pref.xml" "${script_home}/pref/u$(printf '%02d' $i)/tak.pref"
  cp "${script_home}/pref/manifest.xml" "${script_home}/pref/u$(printf '%02d' $i)/MANIFEST"
  cp /opt/tak/certs/files/client.p12 "${script_home}/pref/u$(printf '%02d' $i)"
  cp /opt/tak/certs/files/truststore-root.p12 "${script_home}/pref/u$(printf '%02d' $i)"
  sed -i "s/#UUID/$(uuidgen -t)/g" "${script_home}/pref/u$(printf '%02d' $i)/MANIFEST/manifest.xml"
  sed -i "s/#FQDN/${fqdn}/g" "${script_home}/pref/u$(printf '%02d' $i)/tak.pref"
  sed -i "s/#XMPP/${xmpp}/g" "${script_home}/pref/u$(printf '%02d' $i)/tak.pref"
  sed -i "s/#JKS/$(cat ${script_home}/.jks)/g" "${script_home}/pref/u$(printf '%02d' $i)/tak.pref"
  sed -i "s/#UNUM/$(printf '%02d' $i)/g" "${script_home}/pref/u$(printf '%02d' $i)/tak.pref"
  cd "${script_home}/pref/u$(printf '%02d' $i)"
  zip -r "../u$(printf '%02d' $i).zip" *
  cd "${script_home}/pref"
  # Upload tak prefs to ftp and don't stop until we succeed
  curl "ftps://${ftp_hostname}/atak/conf/" \
        --user $(cat "${script_home}/.ftp") \
        --upload-file "${script_home}/pref/u$(printf '%02d' $i).zip" 2>/dev/null
  rc=$?
  while [[ $rc -gt 0 ]]; do
    sleep 15
    curl "ftps://${ftp_hostname}/atak/conf/" \
         --user $(cat "${script_home}/.ftp") \
         --upload-file "${script_home}/pref/u$(printf '%02d' $i).zip" 2>/dev/null
    rc=$?
  done
  # Remove folder
  rm -rf "${script_home}/pref/u$(printf '%02d' $i)"
done

# Add firewall rules
firewall-cmd --add-port=8080/tcp
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --add-port=8089/tcp
firewall-cmd --add-port=8089/tcp --permanent
firewall-cmd --add-port=8444/tcp
firewall-cmd --add-port=8444/tcp --permanent
firewall-cmd --add-port=8445/tcp
firewall-cmd --add-port=8445/tcp --permanent

# Init Tak DB
echo "erase" | /opt/tak/db-utils/takserver-setup-db.sh

# Finally, bounce the tak server
/sbin/chkconfig takserver on
systemctl restart takserver
