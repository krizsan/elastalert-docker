#!/bin/sh

set -e

# Wait until Elasticsearch is online since otherwise Elastalert will fail.
rm -f garbage_file
while ! wget -O garbage_file ${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT} 2>/dev/null
do
	echo "Waiting for Elasticsearch..."
	rm -f garbage_file
	sleep 1
done
rm -f garbage_file
sleep 5

# First time a container is started: Create a new Elastalert index.
if [ -e "config.yaml" ]
then
	echo "First-time initialization: Creating Elastalert index"
    elastalert-create-index --index elastalert_status --old-index ""
    rm config.yaml
fi

echo "Starting Elastalert..."
exec supervisord -c ${ELASTALERT_SUPERVISOR_CONF} -n
