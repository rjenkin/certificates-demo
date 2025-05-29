#!/bin/bash


# Check if 'go' command exists
if ! command -v go &> /dev/null; then
    echo "Error: Go is not installed or not in your PATH"
    echo "Please install Go from https://golang.org/doc/install"
    exit 1
fi


# Find the submodules directory relative to this file
cd $(dirname "$0")
cd ../
REPO_ROOT=$( pwd )
cd ./submodules
GIT_HOME=$( pwd )

# Check if this root CA exists and use that in the log server
CA_CERT="$REPO_ROOT/ssl/chain-of-trust/ca.pem"

# Start the trillian instance and the database:
cd ${GIT_HOME}/certificate-transparency-go/trillian/examples/deployment/docker/ctfe/
docker compose up -d


# Wait for database
while true; do
  if [ "$(docker exec -i ctfe-db mariadb -pzaphod -Dtest -e 'SELECT NOW();' 2>/dev/null)" ]; then
    echo "ctfe-db container is running!"
    break
  fi
  echo "Waiting for ctfe-db container..."
  sleep 1
done


# Now to provision the logs:
docker exec -i ctfe-db mariadb -pzaphod -Dtest < ${GIT_HOME}/trillian/storage/mysql/schema/storage.sql
docker exec -i ctfe-db mariadb -pzaphod -Dtest < ${GIT_HOME}/certificate-transparency-go/trillian/ctfe/storage/mysql/schema.sql


# Configure CTFE
cd $GIT_HOME
CTFE_CONF_DIR="$REPO_ROOT/docker/ctfe_config"
mkdir -p ${CTFE_CONF_DIR}
echo "CTFE configuration directory created at ${CTFE_CONF_DIR}"

TREE_ID=$(go run github.com/google/trillian/cmd/createtree@master --admin_server=localhost:8090)
if [ -z "$TREE_ID" ]; then
    echo "Failed to create tree or retrieve TREE_ID."
    echo "If behind a corporate proxy, set the Go package proxy environment variable: export GOPROXY=https://your-internal-proxy/api/go/proxy"
    exit 1
fi

# Copy config from the git repository
sed "s/@TREE_ID@/${TREE_ID}/" ${GIT_HOME}/certificate-transparency-go/trillian/examples/deployment/docker/ctfe/ct_server.cfg > ${CTFE_CONF_DIR}/ct_server.cfg

# Rename the log  
sed -i '' "s/testlog/logs/" ${CTFE_CONF_DIR}/ct_server.cfg

# Use CA if it exists, otherwise use default fake CA
if [ -f "$CA_CERT" ]; then
  cp $CA_CERT ${CTFE_CONF_DIR}
  sed -i '' "s/fake-ca.cert/$(basename $CA_CERT)/" ${CTFE_CONF_DIR}/ct_server.cfg
else
  cp ${GIT_HOME}/certificate-transparency-go/trillian/testdata/fake-ca.cert ${CTFE_CONF_DIR}
fi

# Check if the volume exists
VOLUME_NAME="ctfe_config"
if docker volume ls -q | grep -q "^${VOLUME_NAME}$"; then
    echo "Volume '${VOLUME_NAME}' exists. Deleting..."
    docker volume rm "${VOLUME_NAME}"
    echo "Volume deleted successfully."
fi

docker volume create --driver local --opt type=none --opt device=${CTFE_CONF_DIR} --opt o=bind $VOLUME_NAME


# Bring up the CTFE
cd ${GIT_HOME}/certificate-transparency-go/trillian/examples/deployment/docker/ctfe/
docker compose --profile frontend up -d

# Test CTFE
cd ${GIT_HOME}/certificate-transparency-go
while true; do
  if [ "$(go run ./client/ctclient get-sth --log_uri http://localhost:8080/logs 2>/dev/null)" ]; then
    echo "ctfe container is running!"
    break
  fi
  echo "Waiting for ctfe..."
  sleep 1
done
