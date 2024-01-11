################################################################################
# V12 node builder
#FROM ubuntu:18.04 as builder
#
#ENV EOS_SYSTEM_CONTRACTS_URL https://github.com/eosnetworkfoundation/eos-system-contracts/archive/refs/tags/v3.2.0.tar.gz
#RUN apt-get update
#RUN apt-get install -y wget jq git build-essential cmake

################################################################################
# V12 node base Docker image
FROM ubuntu:20.04 as base_node

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
ENV ANTELOPE_LEAP_PKG_URL=https://github.com/AntelopeIO/leap/releases/download/v5.0.0/leap_5.0.0_amd64.deb
ENV EOS_SYSTEM_CONTRACTS_VERSION=3.2.0
ENV EOS_SYSTEM_CONTRACTS_URL=https://github.com/eosnetworkfoundation/eos-system-contracts/archive/refs/tags/v${EOS_SYSTEM_CONTRACTS_VERSION}.tar.gz
ENV ANTELOPE_CDT_VERSION=4.0.1
ENV ANTELOPEIO_CDT_URL=https://github.com/AntelopeIO/cdt/releases/download/v${ANTELOPE_CDT_VERSION}/cdt_${ANTELOPE_CDT_VERSION}_amd64.deb
ENV BUILD_DIR=/opt/eos/build
ARG ANTELOPE_LEAP_PKG=$BUILD_DIR/antelopeio-leap.deb
ARG ANTELOPE_CDT_PKG=$BUILD_DIR/antelopeio-cdt.deb
ENV EOS_SYSTEM_CONTRACTS_DIR=$BUILD_DIR/eos-system-contracts
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y wget jq git build-essential cmake

# create directories
RUN mkdir -p $INSTALL_DIR
RUN mkdir -p $HOME_DIR
RUN mkdir -p $CONFIG_DIR
RUN mkdir -p $BACKUPS_DIR
RUN mkdir -p $BUILD_DIR

# create user account for V12 service
RUN groupadd -f -g ${V12_GROUP_ID} ${V12_USER}
RUN	useradd -r -s /usr/sbin/nologin \
	-g $V12_USER \
	--uid $V12_USER_ID \
	--home-dir $HOME_DIR \
	--no-create-home \
	$V12_USER

RUN mkdir -p $BUILD_DIR
RUN wget -O $ANTELOPE_LEAP_PKG $ANTELOPE_LEAP_PKG_URL \
  && wget -O $BUILD_DIR/eos-system-contracts.tar.gz $EOS_SYSTEM_CONTRACTS_URL \
  && wget -O $ANTELOPE_CDT_PKG $ANTELOPEIO_CDT_URL
RUN tar xvzf $BUILD_DIR/eos-system-contracts.tar.gz --directory $BUILD_DIR
RUN mv $BUILD_DIR/eos-system-contracts-${EOS_SYSTEM_CONTRACTS_VERSION} $EOS_SYSTEM_CONTRACTS_DIR

RUN apt-get install -y $ANTELOPE_LEAP_PKG
RUN apt-get install -y $ANTELOPE_CDT_PKG

# build & install EOS System Contracts
RUN cd $EOS_SYSTEM_CONTRACTS_DIR \
  && rm -fr build \
  && mkdir build  \
  && cd build \
  && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=OFF .. \
  && make -j $(nproc)

# Remove all of the unnecessary files and apt cache
RUN rm -Rf $ANTELOPE_LEAP_PKG \
  && rm -Rf $ANTELOPE_CDT_PKG \
  && apt-get remove -y wget \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# install Docker entrypoint files to enable use of Docker secrets
RUN mkdir -p /opt/scripts
COPY ./scripts/* /opt/scripts/
RUN chmod ugo+x /opt/scripts/*.sh

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


