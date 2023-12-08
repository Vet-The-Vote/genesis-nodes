#!/usr/bin/env bash
echo "Starting API Node...";
set -e;
ulimit -n 65535
ulimit -s 64000

mkdir -p $CONFIG_DIR
cp $INSTALL_DIR/config.ini $CONFIG_DIR/config.ini

pid=0;

nodeos=$"nodeos \
  --config-dir $CONFIG_DIR \
  --data-dir $HOME_DIR \
  --blocks-dir $HOME_DIR/blocks" ;

term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid";
    wait "$pid";
  fi
  exit 0;
}

start_nodeos() {
  $nodeos &
  sleep 10;
  if [ -z "$(pidof nodeos)" ]; then
    $nodeos --hard-replay-blockchain &
  fi
}

start_fresh_nodeos() {
  echo 'Starting new chain from genesis JSON'
  $nodeos --delete-all-blocks --genesis-json $INSTALL_DIR/genesis.json &
}

trap 'echo "Shutdown of EOSIO service...";kill ${!}; term_handler' 2 15;

if [ ! -d $HOME_DIR/blocks ]; then
  start_fresh_nodeos &
elif [ -d $HOME_DIR/blocks ]; then
  start_nodeos &
fi

pid="$(pidof nodeos)"

while true
do
  tail -f /dev/null & wait ${!}
done
