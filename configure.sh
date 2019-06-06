#!/bin/bash
# https://www.thepolyglotdeveloper.com/2017/04/using-couchbase-docker-deploying-containerized-nosql-cluster/

#TODO: Create a different configure.sh file for each desired version of Couchbase
#			 since earlier version don't support the same options as newer versions and
#			 these curl commands may throw errors.

set -m;
echo "Configuring couchbase via the REST API... https://docs.couchbase.com/server/6.0/rest-api/rest-intro.html";
echo "Sleep 15 seconds to give the server time to start...";
/entrypoint.sh couchbase-server & sleep 15;

curl -v -X POST http://${COUCHBASE_HOST_LOCATION}:8091/pools/default \
	-d memoryQuota=8401 \
	-d indexMemoryQuota=512 \
	-d ftsMemoryQuota=512;

# %2C is a URL-encoded comma
curl -v http://${COUCHBASE_HOST_LOCATION}:8091/node/controller/setupServices \
	-d services=kv%2cn1ql%2Cindex%2Cfts;

# # This is for changing admin username and password, so it's optional:
# # TODO: Add support for setting up n users via command line
# # https://docs.couchbase.com/server/6.0/rest-api/rest-node-set-username.html
# curl -v http://${COUCHBASE_HOST_LOCATION}:8091/settings/web \
# 	-u ${COUCHBASE_ADMINISTRATOR_USERNAME}:${COUCHBASE_ADMINISTRATOR_PASSWORD} \
# 	-d port=8091 \
# 	-d username=$NEW_COUCHBASE_ADMIN_USERNAME \
# 	-d password=$NEW_COUCHBASE_ADMIN_PASSWORD;

#did have: -d 'storageMode=memory_optimized'
curl -i -u $COUCHBASE_ADMINISTRATOR_USERNAME:$COUCHBASE_ADMINISTRATOR_PASSWORD \
	-X POST http://${COUCHBASE_HOST_LOCATION}:8091/settings/indexes;

curl -v -u $COUCHBASE_ADMINISTRATOR_USERNAME:$COUCHBASE_ADMINISTRATOR_PASSWORD \
	-X POST http://${COUCHBASE_HOST_LOCATION}:8091/pools/default/buckets \
	-d name=$COUCHBASE_BUCKET_NAME \
	-d bucketType=couchbase \
	-d ramQuotaMB=8401 \
	-d authType=sasl \
	-d saslPassword=$COUCHBASE_BUCKET_PASSWORD;

# couchbase cli setup
echo;
echo "*********************************************************************";
echo "*********************************************************************";
echo "Default clusters - should not exist, and should return 'ERROR: unknown pool'";
couchbase-cli server-list \
	-c ${COUCHBASE_HOST_LOCATION} \
	--username ${COUCHBASE_ADMINISTRATOR_USERNAME} \
	--password ${COUCHBASE_ADMINISTRATOR_PASSWORD};
echo "*********************************************************************";
echo "*********************************************************************";
echo;

echo "cluster-init";
couchbase-cli cluster-init \
	-c $COUCHBASE_HOST_LOCATION \
	--cluster-username $COUCHBASE_ADMINISTRATOR_USERNAME \
	--cluster-password $COUCHBASE_ADMINISTRATOR_PASSWORD \
	--services data,index,query,fts \
	--cluster-ramsize ${CLUSTER_RAMSIZE} \
	--cluster-index-ramsize 512 \
	--cluster-fts-ramsize 2048 \
	--index-storage-setting default;

# This is for setting up buckets via CLI.
# Currently, we do that via REST so this isn't necessary.
# curl -v -u $COUCHBASE_ADMINISTRATOR_USERNAME:$COUCHBASE_ADMINISTRATOR_PASSWORD \
#  -X POST http://${COUCHBASE_HOST_LOCATION}:8091/pools/default/buckets \
#  -d name=$COUCHBASE_BUCKET_NAME \
#  -d bucketType=couchbase \
#  -d ramQuotaMB=8401 \
#  -d authType=sasl \
#  -d saslPassword=$COUCHBASE_BUCKET_PASSWORD;

fg 1;