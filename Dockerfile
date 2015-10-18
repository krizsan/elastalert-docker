# Elastalert Docker image running on Ubuntu 15.04.
# Build image with: docker build -t ivankrizsan/elastalert:v1 .

FROM ubuntu:15.04

MAINTAINER Ivan Krizsan, https://github.com/krizsan

# URL from which to download Elastalert.
ENV ELASTALERT_URL https://github.com/Yelp/elastalert/archive/v0.0.63.zip
# Directory holding configuration for Elastalert and Supervisor.
ENV CONFIG_DIR /opt/config
# Elastalert rules directory.
ENV RULES_DIRECTORY /opt/rules
# Elastalert configuration file path in configuration directory.
ENV ELASTALERT_CONFIG ${CONFIG_DIR}/elastalert_config.yaml
# Directory to which Elastalert and Supervisor logs are written.
ENV LOG_DIR /opt/logs
# Elastalert home directory name.
ENV ELASTALERT_DIRECTORY_NAME elastalert
# Elastalert home directory full path.
ENV ELASTALERT_HOME /opt/${ELASTALERT_DIRECTORY_NAME}
# Supervisor configuration file for Elastalert.
ENV ELASTALERT_SUPERVISOR_CONF ${CONFIG_DIR}/elastalert_supervisord.conf
# Alias, DNS or IP of Elasticsearch host to be queried by Elastalert. Set in default Elasticsearch configuration file.
ENV ELASTICSEARCH_HOST elasticsearch_host
# Port on above Elasticsearch host. Set in default Elasticsearch configuration file.
ENV ELASTICSEARCH_PORT 9200

WORKDIR /opt

# Copy the script used to launch the Elastalert when a container is started.
COPY ./start-elastalert.sh /opt/

# Install software required for Elastalert.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y wget python python-dev unzip gcc && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
# Install pip - required for installation of Elastalert.
    wget https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py && \
# Download and unpack Elastalert.
    wget ${ELASTALERT_URL} && \
    unzip *.zip && \
    rm *.zip && \
    mv e* ${ELASTALERT_DIRECTORY_NAME}

WORKDIR ${ELASTALERT_HOME}

# Install Elastalert.
RUN python setup.py install && \
    pip install -e . && \

# Install Supervisor.
    easy_install supervisor && \

# Make the start-script executable.
    chmod +x /opt/start-elastalert.sh && \

# Create directories.
    mkdir ${CONFIG_DIR} && \
    mkdir ${RULES_DIRECTORY} && \
    mkdir ${LOG_DIR} && \

# Copy deafult configuration files to configuration directory.
    cp ${ELASTALERT_HOME}/config.yaml.example ${ELASTALERT_CONFIG} && \
    cp ${ELASTALERT_HOME}/supervisord.conf.example ${ELASTALERT_SUPERVISOR_CONF} && \

# Elastalert configuration:
    # Set the rule directory in the Elastalert config file to external rules directory.
    sed -i -e"s|rules_folder: [[:print:]]*|rules_folder: ${RULES_DIRECTORY}|g" ${ELASTALERT_CONFIG} && \
    # Set the Elasticsearch host that Elastalert is to query.
    sed -i -e"s|es_host: [[:print:]]*|es_host: ${ELASTICSEARCH_HOST}|g" ${ELASTALERT_CONFIG} && \
    # Set the port used by Elasticsearch at the above address.
    sed -i -e"s|es_port: [0-9]*|es_port: ${ELASTICSEARCH_PORT}|g" ${ELASTALERT_CONFIG} && \

# Elastalert Supervisor configuration:
    # Redirect Supervisor log output to a file in the designated logs directory.
    sed -i -e"s|logfile=.*log|logfile=${LOG_DIR}/elastalert_supervisord.log|g" ${ELASTALERT_SUPERVISOR_CONF} && \
    # Redirect Supervisor stderr output to a file in the designated logs directory.
    sed -i -e"s|stderr_logfile=.*log|stderr_logfile=${LOG_DIR}/elastalert_stderr.log|g" ${ELASTALERT_SUPERVISOR_CONF} && \
    # Modify the start-command.
    sed -i -e"s|python elastalert.py|python -m elastalert.elastalert --config ${ELASTALERT_CONFIG}|g" ${ELASTALERT_SUPERVISOR_CONF} && \

# Copy the Elastalert configuration file to Elastalert home directory to be used when creating index first time an Elastalert container is launched.
    cp ${ELASTALERT_CONFIG} ${ELASTALERT_HOME}/config.yaml && \

# Add Elastalert to Supervisord.
    supervisord -c ${ELASTALERT_SUPERVISOR_CONF}

# Define mount points.
VOLUME [ "${CONFIG_DIR}", "${RULES_DIRECTORY}", "${LOG_DIR}"]

# Launch Elastalert when a container is started.
CMD ["/opt/start-elastalert.sh"]
