################################################################################
# base_node
FROM ubuntu:18.04 as base_node

ENV WORK_DIR /opt/application
ENV DATA_DIR /root/data-dir
ENV CONFIG_DIR $DATA_DIR/config
ENV BACKUPS_DIR /root/backups
ENV EOSIO_PACKAGE_URL https://github.com/eosio/eos/releases/download/v2.0.7/eosio_2.0.7-1-ubuntu-18.04_amd64.deb
ENV EOSIO_CDT_OLD_URL https://github.com/eosio/eosio.cdt/releases/download/v1.6.3/eosio.cdt_1.6.3-1-ubuntu-18.04_amd64.deb
ENV EOSIO_CDT_URL https://github.com/EOSIO/eosio.cdt/releases/download/v1.7.0/eosio.cdt_1.7.0-1-ubuntu-18.04_amd64.deb

RUN apt-get update && apt-get install -y wget jq git build-essential cmake

RUN wget -O /eosio.deb $EOSIO_PACKAGE_URL \
  && wget -O /eosio-cdt-v1.7.0.deb $EOSIO_CDT_URL \
  && wget -O /eosio-cdt-v1.6.3.deb $EOSIO_CDT_OLD_URL

# install EOS package
RUN apt-get install -y /eosio.deb

# install CDT 1.6.3
RUN apt-get install -y /eosio-cdt-v1.6.3.deb \
  && git clone https://github.com/EOSIO/eosio.contracts.git /opt/old-eosio.contracts \
  && cd /opt/old-eosio.contracts \
  && git checkout release/1.8.x \
  && rm -fr build \
  && mkdir build  \
  && cd build \
  && cmake .. \
  && make -j$(sysctl -n hw.ncpu)

# install CDT 1.7.0
RUN apt-get install -y /eosio-cdt-v1.7.0.deb \
  && git clone https://github.com/eoscostarica/eosio.contracts.git /opt/eosio.contracts \
  && cd /opt/eosio.contracts \
  && git checkout release/1.9.x \
  && rm -fr build \
  && mkdir build  \
  && cd build \
  && cmake .. \
  && make -j$(sysctl -n hw.ncpu)

# Remove all of the unnecessary files and apt cache
RUN rm -Rf /eosio*.deb \
  && apt-get remove -y wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# setup directories and files
RUN mkdir -p ${WORK_DIR}
RUN mkdir -p ${DATA_DIR}
RUN mkdir -p ${CONFIG_DIR}
RUN mkdir -p ${BACKUPS_DIR}
COPY ./services/validator_node/genesis.json ${WORK_DIR}/genesis.json
COPY ./scripts/envs-from-secrets.sh /envs-from-secrets.sh
COPY ./scripts/print-functions.sh /print-functions.sh
RUN chmod +x /envs-from-secrets.sh
RUN chmod +x /print-functions.sh
WORKDIR $WORK_DIR


################################################################################
# validator_node
FROM base_node as validator_node
COPY ./services/validator_node/start.sh ${WORK_DIR}/start.sh
RUN chmod +x $WORK_DIR/start.sh
CMD ["/opt/application/start.sh"]


################################################################################
# local_validator_node
FROM validator_node as local_validator_node
RUN apt-get update \
  && apt-get install -y --no-install-recommends jq curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
# RUN chmod +x $WORK_DIR/start.sh
CMD ["/opt/application/start.sh"]














