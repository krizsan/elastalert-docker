#!/bin/sh

set -e

case "${ELASTICSEARCH_TLS}:${ELASTICSEARCH_TLS_VERIFY}" in
  true:true)
    WGET_SCHEMA='https://'
    CREATE_EA_OPTIONS='--ssl --verify-certs'
  ;;
  true:false)
    WGET_SCHEMA='https://'
    CREATE_EA_OPTIONS='--ssl --no-verify-certs'
  ;;
  *)
    WGET_SCHEMA='http://'
    CREATE_EA_OPTIONS='--no-ssl'
  ;;
esac

# Set the timezone.
if [ "$SET_CONTAINER_TIMEZONE" = "true" ]; then
        cp /usr/share/zoneinfo/${CONTAINER_TIMEZONE} /etc/localtime && \
	echo "${CONTAINER_TIMEZONE}" >  /etc/timezone && \
	echo "Container timezone set to: $CONTAINER_TIMEZONE"
else
	echo "Container timezone not modified"
fi

# Force immediate synchronisation of the time and start the time-synchronization service.
# In order to be able to use ntpd in the container, it must be run with the SYS_TIME capability.
# In addition you may want to add the SYS_NICE capability, in order for ntpd to be able to modify its priority.
ntpd -s

# Wait until Elasticsearch is online since otherwise Elastalert will fail.
if [ -n "$ELASTICSEARCH_USER" ] && [ -n "$ELASTICSEARCH_PASSWORD" ]; then
    WGET_AUTH="$ELASTICSEARCH_USER:$ELASTICSEARCH_PASSWORD@"
else
    WGET_AUTH=""
fi
while ! wget -q -T 3 -O - "${WGET_SCHEMA}${WGET_AUTH}${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}" 2>/dev/null
do
	echo "Waiting for Elasticsearch..."
	sleep 1
done
sleep 5

# Check if the Elastalert index exists in Elasticsearch and create it if it does not.
if ! wget -q -T 3 -O - "${WGET_SCHEMA}${WGET_AUTH}${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/elastalert_status" 2>/dev/null
then
    echo "Creating Elastalert index in Elasticsearch..."
    elastalert-create-index ${CREATE_EA_OPTIONS} --host "${ELASTICSEARCH_HOST}" --port "${ELASTICSEARCH_PORT}" --config "${ELASTALERT_CONFIG}" --index elastalert_status --old-index ""
else
    echo "Elastalert index already exists in Elasticsearch."
fi

echo "Starting Elastalert..."
exec supervisord -c "${ELASTALERT_SUPERVISOR_CONF}" -n
