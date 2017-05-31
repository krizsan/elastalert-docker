# Elastalert Docker Image
Docker image with Elastalert on Alpine Linux.

Requires a link to a Docker container running Elasticsearch using the "elasticsearchhost" alias.
Assumes the use of port 9200 when communicating with Elasticsearch.<br/>
In order for the time of the container to be synchronized (ntpd), it must be run with the SYS_TIME capability.
In addition you may want to add the SYS_NICE capability, in order for ntpd to be able to modify its priority.

If Elasticsearch requires authentication, then the two environment variables listed below must contain user and password.
In addition, the Elastalert configuration file must also contain login credentials, like in this example:
```
es_username: elastic
es_password: changeme
```

# Volumes
- /opt/logs       - Elastalert and Supervisord logs will be written to this directory.
- /opt/config     - Elastalert (elastalert_config.yaml) and Supervisord (elastalert_supervisord.conf) configuration files.
- /opt/rules      - Contains Elastalert rules.<br/>

# Environment
- SET_CONTAINER_TIMEZONE - Set to "true" (without quotes) to set the tiemzone when starting a container. Default is false.
- CONTAINER_TIMEZONE - Timezone to use in container. Default is Europe/Stockholm.
- ELASTICSEARCH_USER - Name of user to log into Ealsticsearch with. Leave undefined for no authentication.
- ELASTICSEARCH_PASSWORD - Password to log into Elasticsearch with. Leave undefined for no authentication.
