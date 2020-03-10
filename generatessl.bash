#!/bin/bash

####################################################
###
### CONFIGURATION VARIABLES
###

# Suffix for backup files
# No joining separators used later, include any needed here
BACKUP_SUFFIX=".bak_$(date +%Y-%m-%dT%H:%M:%S)"

# CB defaults
CB_INBOX_DIR="/opt/couchbase/var/lib/couchbase/inbox"
CB_KEY_FILE="${CB_INBOX_DIR}/pkey.key"
CB_CHAIN_FILE="${CB_INBOX_DIR}/chain.pem"
CB_CA_FILE="${CB_INBOX_DIR}/ca.pem"
CB_USER="couchbase"
CB_GROUP="couchbase"

# SSL defaults
SSL_DIR="/vagrant/node_ssl" # Put outside vagrant vm on the host so the nodes can share it
SSL_CONFIG="${SSL_DIR}/config.cnf"
SSL_DAYS="365"

SSL_CA_CN="Couchbase Cluster CA"
SSL_DN_O="Couchbase"
SSL_DN_OU="Technical Support"
SSL_DN_L="Santa Clara"
SSL_DN_ST="California"
SSL_DN_C="US"

SSL_BITS="2048"

# CB cert auth user certificate parameters, made to be RBAC flexible
# Format: SSL_USER_HEAD + SSL_USER_PREFIX + i + SSL_USER_TAIL
# Default: cbssl-user1@cb.local
# No joining separators used later, include any needed here
SSL_USER_HEAD="cbssl-" # Stuff for before the parsed RBAC name
SSL_USER_PREFIX="user" # The RBAC name we want to end up with, will have a number appended
SSL_USER_TAIL="@cb.local" # Delimiter and stuff after it

SSL_USER_COUNT=2 # Number of SSL user certificates to make

####################################################
###
### PROGRAM LIVES BELOW HERE
###

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
default_bits       = ${SSL_BITS}
distinguished_name = req_dn
req_extensions     = req_ext

[ req_dn ]
countryName                    = Country Name (2 letter code)
countryName_default            = ${SSL_DN_C}
stateOrProvinceName            = State or Province Name
stateOrProvinceName_default    = ${SSL_DN_ST}
localityName                   = Locality Name
localityName_default           = ${SSL_DN_L}
organizationName               = Organization Name
organizationName_default       = ${SSL_DN_O}
organizationalUnitName         = Organization Unit Name
organizationalUnitName_default = ${SSL_DN_OU}
commonName_max                 = 64

[ req_ext ]
subjectKeyIdentifier = hash
keyUsage             = digitalSignature, keyEncipherment
==EOF
# end of heredoc - careful with the heredoc formatting, leave untabbed!
fi

# Generate the CA, if needed
# Set some paths first
SSL_CA_DIR="${SSL_DIR}/ca"
SSL_CA_KEY="${SSL_CA_DIR}/ca.key"
SSL_CA_CERT="${SSL_CA_DIR}/ca.pem"
SSL_CA_SERIAL="${SSL_CA_DIR}/serial.srl"

if [ -f "${SSL_CA_KEY}" ] && [ -f "${SSL_CA_CERT}" ]
then
    echo "Found a private key and cert where I expect CA should be, so will assume this is the CA to use"
    echo -n "Cert found for CA with "
    openssl x509 -in ${SSL_CA_CERT} -noout -subject
else
    echo "Not found the CA's private key and cert, so generating a new CA"
    mkdir -p ${SSL_DIR}/ca
    openssl req -newkey rsa:${SSL_BITS} -nodes -keyout ${SSL_CA_KEY} -x509 -days ${SSL_DAYS} -out ${SSL_CA_CERT} \
    -batch -subj "/CN=${SSL_CA_CN}" -sha256 -config <(cat ${SSL_CONFIG} <(printf "\n%s" "basicConstraints=CA:TRUE"))
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
            -config <(cat ${SSL_CONFIG} <(printf "\n%s" "basicConstraints=CA:FALSE" "extendedKeyUsage=clientAuth"))

            # Sign CSR with CA
            echo "User CSR built at '${SSL_USER_CSR}', signing certificate with CA"
            openssl x509 -req -in ${SSL_USER_CSR} -CA ${SSL_CA_CERT} -CAkey ${SSL_CA_KEY} -CAcreateserial -CAserial ${SSL_CA_SERIAL} \
            -out ${SSL_USER_CERT} -days ${SSL_DAYS} -sha256 -extensions req_ext \
            -extfile <(cat ${SSL_CONFIG} <(printf "\n%s" "basicConstraints=CA:FALSE" "extendedKeyUsage=clientAuth"))

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

if [ -f "${SSL_NODE_CSR}" ]
then
    echo "Found node CSR where I was looking at '${SSL_NODE_CSR}', backing this up"
    mv "${SSL_NODE_CSR}" "${SSL_NODE_CSR}.bak_$(date +%Y-%m-%dT%H:%M:%S)"
fi

echo "Building node SAN address list"

# Start with just the FQDN
echo "  adding FQDN SAN to cert: ${DNS_FQDN}"
SAN_LIST="subjectAltName=DNS:${DNS_FQDN}"

# Add DNS SAN Ebt
for dns_san_entry in "${DNS_ALIASES[@]}"
do
    SAN_LIST+=",DNS:${dns_san_entry}"
    echo "  adding DNS SAN to cert: ${dns_san_entry}"
done

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
openssl req -new -sha256 -key ${SSL_NODE_KEY} -subj "/CN=${DNS_FQDN}" -out ${SSL_NODE_CSR} \
-config <(cat ${SSL_CONFIG} <(printf "\n%s" "basicConstraints=CA:FALSE" "extendedKeyUsage=serverAuth" "${SAN_LIST}"))

# Sign CSR with CA
echo "Node CSR built at '${SSL_NODE_CSR}', signing certificate with CA"
openssl x509 -req -in ${SSL_NODE_CSR} -CA ${SSL_CA_CERT} -CAkey ${SSL_CA_KEY} -CAcreateserial -CAserial ${SSL_CA_SERIAL} \
-out ${SSL_NODE_CHAIN} -days ${SSL_DAYS} -sha256 -extensions req_ext \
-extfile <(cat ${SSL_CONFIG} <(printf "\n%s" "basicConstraints=CA:FALSE" "extendedKeyUsage=serverAuth" "${SAN_LIST}"))

echo "Certificate build finished for '${DNS_SHORT}'"
echo

# Move certs to CB inbox
echo "Checking for Couchbase inbox directory"
if [ ! -d "${CB_INBOX_DIR}" ]
then
    echo "Couchbase inbox directory NOT FOUND where I was looking at '${CB_INBOX_DIR}', creating this"
    mkdir -p ${CB_INBOX_DIR}
fi

# Check and backup private key, before copying new one
echo "Checking for Couchbase private key in inbox directory"
if [ -f "${CB_KEY_FILE}" ]
then
    echo "Found old key at '${CB_INBOX_DIR}', backing this up"
    mv "${CB_KEY_FILE}" "${CB_KEY_FILE}${BACKUP_SUFFIX}"
fi
echo "Copying private key to Couchbase inbox directory"
cp -v ${SSL_NODE_KEY} ${CB_KEY_FILE}

# Check and backup node certificate, before copying new one
echo "Checking for Couchbase node certificate chain in inbox directory"
if [ -f "${CB_CHAIN_FILE}" ]
then
    echo "Found old cert at '${CB_CHAIN_FILE}', backing this up"
    mv "${CB_CHAIN_FILE}" "${CB_CHAIN_FILE}${BACKUP_SUFFIX}"
fi
echo "Copying node certificate chain to Couchbase inbox directory"
cp -v ${SSL_NODE_CHAIN} ${CB_CHAIN_FILE}

# Check and backup CA certificate, before copying new one
echo "Checking for Couchbase CA cert in inbox directory"
if [ -f "${CB_CA_FILE}" ]
then
    echo "Found old CA cert at '${CB_CA_FILE}', backing this up"
    mv "${CB_CA_FILE}" "${CB_CA_FILE}${BACKUP_SUFFIX}"
fi
echo "Copying CA certificate to Couchbase inbox directory"
cp -v ${SSL_CA_CERT} ${CB_CA_FILE}

# Fix up permissions just in case they would cause an issue
echo "Changing Couchbase inbox directory ownership to '${CB_USER}:${CB_GROUP}', where required"
chown -Rc ${CB_USER}:${CB_GROUP} ${CB_INBOX_DIR}

echo "All Done!"
exit 0
