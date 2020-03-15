#!/bin/bash

####################################################
###
### CONFIGURATION VARIABLES
###

TIME_FORMAT="+%Y-%m-%dT%H:%M:%S" # Format for "date" command
TIME_RUN_START=$( date ${TIME_FORMAT} ) # Grab run start time

# Suffix for backup files can use this time for good name
# No joining separators used later, include any needed here
BACKUP_SUFFIX=".bak_${TIME_RUN_START}"

# CB defaults
CB_INBOX_DIR="/opt/couchbase/var/lib/couchbase/inbox"
CB_KEY_FILE="${CB_INBOX_DIR}/pkey.key"
CB_CHAIN_FILE="${CB_INBOX_DIR}/chain.pem"
CB_CA_FILE="${CB_INBOX_DIR}/ca.pem"
CB_USER="couchbase" # Username that Couchbase Server runs as
CB_GROUP="couchbase" # Group that Couchbase Server runs as
CB_ADMIN_USER="Administrator" # Couchbase Server cluster admin username
CB_ADMIN_PASSWORD="password" # Couchbase Server cluster admin password
CB_CONNECT_TIMEOUT=10 # Max time to wait after cert gen to import them

# SSL defaults
SSL_DIR="/vagrant/node_ssl" # Put outside vagrant vm on the host so the nodes can share it
SSL_CONFIG="${SSL_DIR}/config.cnf"
SSL_CA_CONFIG="${SSL_DIR}/config-ca.cnf"
SSL_DAYS="365" # Number of days all certificates should last
SSL_BITS="2048" # Decent number of SSL key bits

# SSL distinguishedName default values
SSL_DN_O="Couchbase"
SSL_DN_OU="Technical Support"
SSL_DN_L="Santa Clara"
SSL_DN_ST="California"
SSL_DN_C="US"

# CB cert auth user certificate parameters, made to be RBAC flexible
# Format: SSL_USER_HEAD + SSL_USER_PREFIX + i + SSL_USER_TAIL
# Default: cbssl-user1@cb.local
# No joining separators used later, include any needed here
SSL_USER_HEAD="cbssl-" # Stuff for before the parsed RBAC name
SSL_USER_PREFIX="user" # The RBAC name we want to end up with, will have a number appended
SSL_USER_TAIL="@cb.local" # Delimiter and stuff after it
SSL_USER_COUNT=2 # Number of SSL user certificates to make

# Intermediate Cluster CA Details
# Name of the Intermediate Cluster CA
SSL_INT_CA_CN="Couchbase Cluster CA ${TIME_RUN_START}"

# Root CA Details
# Where can we find the Root CA on this machine
SSL_ROOT_CA_DIR="/vmhost_home/.node_ssl"
SSL_ROOT_CA_KEY="${SSL_ROOT_CA_DIR}/ca.key"
SSL_ROOT_CA_CERT="${SSL_ROOT_CA_DIR}/ca.pem"
SSL_ROOT_CA_SERIAL="${SSL_ROOT_CA_DIR}/serial.srl"

# Name of the Root CA if we generate it
SSL_ROOT_CA_CN="Couchbase Vagrant Root CA ${TIME_RUN_START}"

####################################################
###
### PROGRAM LIVES BELOW HERE
###

### HELPER FUNCTIONS

# mv_backup < $1= SRC >
mv_backup () {
    if [ -f "$1" ]
    then
        echo "Found '$1', backing this up"
        mv -v "$1" "$1${BACKUP_SUFFIX}"
    fi
}

# cp_with_backup < $1= SRC > < $2= DST >
cp_with_backup () {
    mv_backup $2 # Backup DST if exists
    cp -v "$1" "$2"
}

### MAIN PROGRAM START

echo <<<"
Couchbase Vagrant SSL Generator
=======================================

Asked to generate SSL certificates through VAGRANT_GENSSL env var
"

# Check the script is running on the vagrant vm
if [ ! -d "/vagrant" ]
then
    echo "ERROR Needs to be run from within vagrant machine"
    exit 1
else
    echo "Here goes..."
fi

### GATHER FACTS FROM NODE

# Gather Facts
DNS_FQDN=$(hostname -f) # FQDN of the Vagrant
DNS_ALIASES=( $(hostname -a) ) # All other aliases, usally just the shortname
IP_ADDRESSES=( $(hostname -I) ) # All IPs, not just primary

# Set short DNS short name to either first alias, or fall back to $DNS_FQDN
if [ -z ${DNS_ALIASES[0]} ]
then
    DNS_SHORT=${DNS_FQDN}
else
    DNS_SHORT=${DNS_ALIASES[0]}
fi

### SET UP SSL ENVIRONMENT AND BUILD CA

# Make sure we have a home
if [ -d "${SSL_DIR}" ]
then
    echo "Found SSL directory where I was looking at '${SSL_DIR}', using this"
else
    echo "SSL directory NOT FOUND where I was looking at '${SSL_DIR}', creating this"
    mkdir -p ${SSL_DIR}
fi

# Create the config file, in needed - careful with the heredoc formatting, leave untabbed!
if [ -f "${SSL_CONFIG}" ]
then
    echo "Found SSL config where I was looking at '${SSL_CONFIG}', using this"
else
    echo "SSL config NOT FOUND where I was looking at '${SSL_CONFIG}', creating this"
    cat << ==EOF > ${SSL_CONFIG}
[ req ]
default_bits                    = ${SSL_BITS}
distinguished_name              = req_dn
req_extensions                  = req_ext
x509_extensions                 = req_ext

[ req_dn ]
countryName                     = Country Name (2 letter code)
countryName_default             = ${SSL_DN_C}
stateOrProvinceName             = State or Province Name
stateOrProvinceName_default     = ${SSL_DN_ST}
localityName                    = Locality Name
localityName_default            = ${SSL_DN_L}
organizationName                = Organization Name
organizationName_default        = ${SSL_DN_O}
organizationalUnitName          = Organization Unit Name
organizationalUnitName_default  = ${SSL_DN_OU}
commonName_max                  = 64

[ req_ext ]
subjectKeyIdentifier            = hash
keyUsage                        = digitalSignature, keyEncipherment
==EOF
# end of heredoc - careful with the heredoc formatting, leave untabbed!
fi

# Create the CA config file, in needed - careful with the heredoc formatting, leave untabbed!
if [ -f "${SSL_CA_CONFIG}" ]
then
    echo "Found SSL CA config where I was looking at '${SSL_CA_CONFIG}', using this"
else
    echo "SSL config NOT FOUND where I was looking at '${SSL_CA_CONFIG}', creating this"
    cp ${SSL_CONFIG} ${SSL_CA_CONFIG}
    cat << ==EOF >> ${SSL_CA_CONFIG}
basicConstraints                = CA:TRUE
==EOF
# end of heredoc - careful with the heredoc formatting, leave untabbed!
fi


### BUILD ROOT CA AND INTERMEDIATE CLUSTER CA

# Default search root CA paths set at no need to set here

# Starting with the intermediate CA, we'll check if this exists first
# Set some paths
SSL_INT_CA_DIR="${SSL_DIR}/cluster-ca"
SSL_INT_CA_KEY="${SSL_INT_CA_DIR}/ca.key"
SSL_INT_CA_CSR="${SSL_INT_CA_DIR}/ca.csr"
SSL_INT_CA_CERT="${SSL_INT_CA_DIR}/ca.pem"
SSL_INT_CA_SERIAL="${SSL_INT_CA_DIR}/serial.srl"

if [ -f "${SSL_INT_CA_KEY}" ] && [ -f "${SSL_INT_CA_CERT}" ]
then
    echo "Found a private key and cert where I expect intermediate CA should be, so will assume I'm not the first node this is the CA to use"
    echo -n "Cert found for intermediate cluster CA with "
    openssl x509 -in ${SSL_INT_CA_CERT} -noout -subject
else
    echo "Not found the cluster CA's private key and cert, so will make a new cluster CA"
    
    # ROOT CA HANDLING

    # Check if we have a root CA on this host
    echo "Checking for a local overall user-level root CA in '${SSL_ROOT_CA_DIR}'"

    if [ -f "${SSL_ROOT_CA_KEY}" ] && [ -f "${SSL_ROOT_CA_CERT}" ]
    then
        echo "Found a private key and cert where I expect root CA should be, so will assume this is the CA to use"
        echo -n "Cert found for root CA with "
        openssl x509 -in ${SSL_ROOT_CA_CERT} -noout -subject
    else
        echo "Not found at the local user level, looking locally within this version"

        # Revert to making a new, temporary root CA for this version
        SSL_ROOT_CA_DIR="${SSL_DIR}/root-ca"
        SSL_ROOT_CA_KEY="${SSL_ROOT_CA_DIR}/ca.key"
        SSL_ROOT_CA_CERT="${SSL_ROOT_CA_DIR}/ca.pem"
        SSL_ROOT_CA_SERIAL="${SSL_ROOT_CA_DIR}/serial.srl"

        if [ -f "${SSL_ROOT_CA_KEY}" ] && [ -f "${SSL_ROOT_CA_CERT}" ]
        then
            echo "Found a private key and cert where I expect a version-level root CA should be, so will assume this is the CA to use"
            echo -n "Cert found for root CA with "
            openssl x509 -in ${SSL_ROOT_CA_CERT} -noout -subject
        else
            echo "Not found the CA's private key and cert, so generating a new root CA"

            # Make root CA directory
            mkdir -p ${SSL_ROOT_CA_DIR}

            # Make our root CA
            openssl req -newkey rsa:${SSL_BITS} -nodes -keyout ${SSL_ROOT_CA_KEY} -x509 -days ${SSL_DAYS} -out ${SSL_ROOT_CA_CERT} \
            -batch -subj "/CN=${SSL_ROOT_CA_CN}" -sha256 \
            -config <(cat ${SSL_CA_CONFIG} <(printf "\n%s" "keyUsage=digitalSignature,keyEncipherment,keyCertSign" ))

            echo "Created root CA at '${SSL_ROOT_CA_CERT}'"
        fi
    fi

    # Now build the intermediate cluster CA certificate
    # First, make our directory
    mkdir -p ${SSL_INT_CA_DIR}

    # Generate our intermediate CA private key
    echo "Generating Cluster CA private key at '${SSL_INT_CA_KEY}'"
    openssl genrsa -out ${SSL_INT_CA_KEY} ${SSL_BITS}

    # Generate Cluster CA CSR
    echo "Generating Cluster CA CSR at '${SSL_INT_CA_CSR}'"
    openssl req -new -sha256 -key ${SSL_INT_CA_KEY} -subj "/CN=${SSL_INT_CA_CN}" -out ${SSL_INT_CA_CSR} \
    -config  <(cat ${SSL_CA_CONFIG} <(printf "\n%s" "keyUsage=digitalSignature,keyEncipherment,keyCertSign"))

    # Sign Cluster CA CSR with Root CA
    echo "Cluster CA CSR built at '${SSL_INT_CA_CSR}', signing certificate with rott CA"
    openssl x509 -req -in ${SSL_INT_CA_CSR} -CA ${SSL_ROOT_CA_CERT} -CAkey ${SSL_ROOT_CA_KEY} -CAcreateserial -CAserial ${SSL_ROOT_CA_SERIAL} \
    -out ${SSL_INT_CA_CERT} -days ${SSL_DAYS} -sha256  -extensions req_ext \
    -extfile <(cat ${SSL_CA_CONFIG} <(printf "\n%s" "authorityKeyIdentifier=keyid,issuer" "keyUsage=digitalSignature,keyEncipherment,keyCertSign" ))
    echo "Done. Cluster CA built at '${SSL_INT_CA_CERT}'"
fi

### USER CERTIFICATES

# Make user certificate signing request
# Set some paths first
SSL_USER_DIR="${SSL_DIR}/user"

# Only make user certs if user certs dir not found, likely an additional node
if [ -d "${SSL_USER_DIR}" ]
then
    echo "Found user certificate directory where I was looking at '${SSL_USER_DIR}', skipping creation"
else
    echo "SSL user directory NOT FOUND where I was looking at '${SSL_USER_DIR}', creating this"
    mkdir -p ${SSL_USER_DIR}

    # Convenience file of all CA certificates
    SSL_USER_CA_CHAIN="${SSL_USER_DIR}/client_ca.pem"
    echo "Creating client CA chain of root and cluster CA certificates"
    cat ${SSL_ROOT_CA_CERT} ${SSL_INT_CA_CERT} ${SSL_USER_CA_CHAIN}

    # Only make user certificates if requested number greater than 0
    if [ ${SSL_USER_COUNT} -gt 0 ]
    then
        for i in $( seq ${SSL_USER_COUNT} )
        do
            # Set up some vars and paths
            SSL_USER_CN="${SSL_USER_HEAD}${SSL_USER_PREFIX}${i}${SSL_USER_TAIL}"
            SSL_USER_KEY="${SSL_USER_DIR}/${SSL_USER_CN}/${SSL_USER_CN}.key"
            SSL_USER_CSR="${SSL_USER_DIR}/${SSL_USER_CN}/${SSL_USER_CN}.csr"
            SSL_USER_CERT="${SSL_USER_DIR}/${SSL_USER_CN}/${SSL_USER_CN}.pem"
            echo "Creating at new user '${SSL_USER_CN}'"
            mkdir -p "${SSL_USER_DIR}/${SSL_USER_CN}"

            # Generate key
            echo "Generating User Key at '${SSL_USER_KEY}'"
            openssl genrsa -out ${SSL_USER_KEY} ${SSL_BITS}

            # Generate CSR
            echo "Generating CSR at '${SSL_USER_CSR}'"
            openssl req -new -sha256 -key ${SSL_USER_KEY} -subj "/CN=${SSL_USER_CN}" -out ${SSL_USER_CSR} \
            -config <(cat ${SSL_CONFIG} <(printf "\n%s" "basicConstraints=CA:FALSE" "extendedKeyUsage=clientAuth" \
            "keyUsage=digitalSignature,keyEncipherment" ))

            # Sign CSR with CA
            echo "User CSR built at '${SSL_USER_CSR}', signing certificate with CA"
            openssl x509 -req -in ${SSL_USER_CSR} -CA ${SSL_INT_CA_CERT} -CAkey ${SSL_INT_CA_KEY} -CAcreateserial -CAserial ${SSL_INT_CA_SERIAL} \
            -out ${SSL_USER_CERT} -days ${SSL_DAYS} -sha256 -extensions req_ext \
            -extfile <(cat ${SSL_CONFIG} <(printf "\n%s" "basicConstraints=CA:FALSE" "extendedKeyUsage=clientAuth" \
            "keyUsage=digitalSignature,keyEncipherment" "authorityKeyIdentifier=keyid,issuer" ))

            echo "Certificate build finished for '${SSL_USER_CN}'"
        done
    fi
fi

### NODE CERTIFICATE

# Make node certificate signing request
# Set some paths first
SSL_NODE_DIR="${SSL_DIR}/node/${DNS_SHORT}"
SSL_NODE_KEY="${SSL_NODE_DIR}/pkey.key"
SSL_NODE_CSR="${SSL_NODE_DIR}/${DNS_SHORT}.csr"
SSL_NODE_CERT="${SSL_NODE_DIR}/${DNS_SHORT}.pem"
SSL_NODE_CHAIN="${SSL_NODE_DIR}/chain.pem"

if [ -d "${SSL_NODE_DIR}" ]
then
    echo "Found node certificate directory where I was looking at '${SSL_NODE_DIR}', using this"
else
    echo "SSL node certificate directory NOT FOUND where I was looking at '${SSL_NODE_DIR}', creating this"
    mkdir -p ${SSL_NODE_DIR}
fi

if [ -f "${SSL_NODE_KEY}" ]
then
    echo "Found node private key where I was looking at '${SSL_NODE_KEY}', using this"
else
    echo "Private key NOT FOUND where I was looking at '${SSL_NODE_DIR}/pkey.key', creating this"
    openssl genrsa -out ${SSL_NODE_KEY} ${SSL_BITS}
fi

echo "Building node SAN address list"

# Start with just the FQDN
echo "  adding FQDN SAN to cert: ${DNS_FQDN}"
SAN_LIST="subjectAltName=DNS:${DNS_FQDN}"

## Add DNS SAN Entries
if [ ! -z ${DNS_ALIASES} ]
then
    for dns_san_entry in "${DNS_ALIASES[@]}"
    do
        SAN_LIST+=",DNS:${dns_san_entry}"
        echo "  adding DNS SAN to cert: ${dns_san_entry}"
    done
fi

#
for ip_san_entry in "${IP_ADDRESSES[@]}"
do
    SAN_LIST+=",IP:${ip_san_entry}"
    echo "  adding IP SAN to cert: ${ip_san_entry}"
done

echo "Finished with: ${SAN_LIST}"
echo

# Generate CSR including SANs
echo "Generating Node CSR at '${SSL_NODE_CSR}'"
mv_backup ${SSL_NODE_CSR}
openssl req -new -sha256 -key ${SSL_NODE_KEY} -subj "/CN=${DNS_FQDN}" -out ${SSL_NODE_CSR} \
-config <(cat ${SSL_CONFIG} <(printf "\n%s" "basicConstraints=CA:FALSE" "extendedKeyUsage=serverAuth" "${SAN_LIST}" \
"keyUsage=digitalSignature,keyEncipherment" ))

# Sign CSR with CA
echo "Node CSR built at '${SSL_NODE_CSR}', signing certificate with CA"
openssl x509 -req -in ${SSL_NODE_CSR} -CA ${SSL_INT_CA_CERT} -CAkey ${SSL_INT_CA_KEY} -CAcreateserial -CAserial ${SSL_INT_CA_SERIAL} \
-out ${SSL_NODE_CERT} -days ${SSL_DAYS} -sha256 -extensions req_ext \
-extfile <(cat ${SSL_CONFIG} <(printf "\n%s" "basicConstraints=CA:FALSE" "extendedKeyUsage=serverAuth" "${SAN_LIST}" \
"keyUsage=digitalSignature,keyEncipherment" "authorityKeyIdentifier=keyid,issuer" ))

echo "Certificate build finished for '${DNS_SHORT}'"

echo "Concatenating certificate chain for '${DNS_SHORT}'"
cp ${SSL_NODE_CERT} ${SSL_NODE_CHAIN}
echo "Done!"

### FINISH BY TIDYING UP FILES

# Move certs to CB inbox
echo "Checking for Couchbase inbox directory"
if [ ! -d "${CB_INBOX_DIR}" ]
then
    echo "Couchbase inbox directory NOT FOUND where I was looking at '${CB_INBOX_DIR}', creating this"
    mkdir -p ${CB_INBOX_DIR}
fi

# Check and backup private key, before copying new one
echo "Copying private key to Couchbase inbox directory"
cp_with_backup ${SSL_NODE_KEY} ${CB_KEY_FILE}

# Check and backup node certificate chain, before copying new one
echo "Copying node certificate chain to Couchbase inbox directory"
cp_with_backup ${SSL_NODE_CHAIN} ${CB_CHAIN_FILE}

# Check and backup CA certificate, before copying new one
echo "Copying intermediate cluster CA certificate to Couchbase inbox directory"
cp_with_backup ${SSL_INT_CA_CERT} ${CB_CA_FILE}

# Fix up permissions just in case they would cause an issue
echo "Changing Couchbase inbox directory ownership to '${CB_USER}:${CB_GROUP}', where required"
chown -Rc ${CB_USER}:${CB_GROUP} ${CB_INBOX_DIR}

# Wait to ensure Couchbase Server is up
CB_READY=0
ATTEMPT=0
while [ ${CB_READY} -lt 1 ] && [ ${ATTEMPT} -lt ${CB_CONNECT_TIMEOUT} ]
do
    if [ $(netstat -ntl | grep -c ':8091') -gt 0 ]
    then
        CB_READY=1
        # Import the certificates if possible
        echo -n "Uploading cluster CA to Couchbase Server via REST API...   "
        curl -s -X POST --data-binary "@${SSL_INT_CA_CERT}" http://${CB_ADMIN_USER}:${CB_ADMIN_PASSWORD}@127.0.0.1:8091/controller/uploadClusterCA

        if [ $? -eq 0 ]
        then
            echo "CA Set - OK!"
        else
            echo "CA FAILED!"
        fi

        echo "Reloading node certificate in Couchbase Server via REST API"
        curl -s -X POST  http://${CB_ADMIN_USER}:${CB_ADMIN_PASSWORD}@127.0.0.1:8091/node/controller/reloadCertificate

        if [ $? -eq 0 ]
        then
            echo "Node Reload - OK!"
        else
            echo "NODE FAILED!"
        fi
    else
        echo "Not ready after ${ATTEMPT}s"
        ((ATTEMPT++))
        sleep 1
    fi
done

echo "All Done!"
exit 0
