#!/bin/bash
###################################################################################
# Create Docker networks for the V12 genesis nodes
###################################################################################
docker network create --driver overlay --attachable v12_mainnet_external
docker network create --driver overlay --attachable --internal v12_mainnet_internal

docker network create --driver overlay --attachable v12_testnet_external
docker network create --driver overlay --attachable --internal v12_testnet_internal





