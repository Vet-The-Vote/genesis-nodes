################################################################################
# V12 node base Docker image
FROM ubuntu:18.04 as base_node

ARG V12_USER=${V12_USER:-v12node}
ENV V12_USER=${V12_USER:-v12node}
ARG V12_USER_ID=${V12_USER_ID:-2024}
ARG V12_GROUP_ID=${V12_GROUP_ID:-2024}
ARG INSTALL_DIR=/opt/application
ENV INSTALL_DIR=${INSTALL_DIR:-/opt/application}
ARG HOME_DIR=/home/v12node
ENV HOME_DIR=${HOME_DIR:-/home/v12node}
ARG DATA_DIR=/home/v12node
ENV DATA_DIR=${DATA_DIR:-/home/v12node}
ARG CONFIG_DIR=$DATA_DIR/config
ENV CONFIG_DIR=$DATA_DIR/config
ARG BACKUPS_DIR=$HOME_DIR/backups
ENV BACKUPS_DIR=${HOME_DIR:-$HOME_DIR/backups}
ENV EOSIO_PACKAGE_URL https://github.com/eosio/eos/releases/download/v2.0.7/eosio_2.0.7-1-ubuntu-18.04_amd64.deb
ENV EOSIO_CDT_OLD_URL https://github.com/eosio/eosio.cdt/releases/download/v1.6.3/eosio.cdt_1.6.3-1-ubuntu-18.04_amd64.deb
ENV EOSIO_CDT_URL https://github.com/EOSIO/eosio.cdt/releases/download/v1.7.0/eosio.cdt_1.7.0-1-ubuntu-18.04_amd64.deb

RUN apt-get update && apt-get install -y wget jq git build-essential cmake

RUN wget -O /eosio.deb $EOSIO_PACKAGE_URL \
  && wget -O /eosio-cdt-v1.7.0.deb $EOSIO_CDT_URL \
  && wget -O /eosio-cdt-v1.6.3.deb $EOSIO_CDT_OLD_URL

RUN apt-get install -y /eosio.deb

RUN apt-get install -y /eosio-cdt-v1.6.3.deb \
  && git clone https://github.com/EOSIO/eosio.contracts.git /opt/old-eosio.contracts \
  && cd /opt/old-eosio.contracts && git checkout release/1.8.x \
  && rm -fr build \
  && mkdir build  \
  && cd build \
  && cmake .. \
  && make -j$(sysctl -n hw.ncpu)

RUN apt-get install -y /eosio-cdt-v1.7.0.deb \
  && git clone https://github.com/eoscostarica/eosio.contracts.git /opt/eosio.contracts \
  && cd /opt/eosio.contracts && git checkout release/1.9.x \
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

# create directories
RUN mkdir -p $INSTALL_DIR
RUN mkdir -p $HOME_DIR
RUN mkdir -p $CONFIG_DIR
RUN mkdir -p $BACKUPS_DIR

# create user account for V12 service
RUN groupadd -f -g ${V12_GROUP_ID} ${V12_USER}
RUN	useradd -r -s /usr/sbin/nologin \
	-g $V12_USER \
	--uid $V12_USER_ID \
	--home-dir $HOME_DIR \
	--no-create-home \
	$V12_USER

# install Docker entrypoint files to enable use of Docker secrets
RUN mkdir -p /opt/scripts
COPY ./scripts/* /opt/scripts/
RUN chmod ug+x /opt/scripts/*.sh

# change ownership of files and directories
RUN chown -R $V12_USER:$V12_USER $INSTALL_DIR
RUN chown -R $V12_USER:$V12_USER $HOME_DIR
RUN chown -R $V12_USER:$V12_USER $CONFIG_DIR
RUN chown -R $V12_USER:$V12_USER $BACKUPS_DIR

# Define working directory
WORKDIR $INSTALL_DIR

CMD ["/opt/application/start.sh"]
ENTRYPOINT ["/opt/scripts/docker-entrypoint.sh"]

################################################################################
# V12 node release build
FROM base_node as v12_node
# RUN chmod +x $INSTALL_DIR/start.sh
USER $V12_USER


################################################################################
# V12 node debug build
FROM base_node as v12_debug_node
RUN apt-get update && apt-get install -y --no-install-recommends jq curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
# RUN chmod +x $INSTALL_DIR/start.sh

USER $V12_USER


