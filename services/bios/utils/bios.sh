#!/usr/bin/env bash

set -e;

EOSIO_CONTRACTS_DIRECTORY=$EOS_SYSTEM_CONTRACTS_DIR/build/contracts
echo "EOSIO_CONTRACTS_DIRECTORY = ${EOSIO_CONTRACTS_DIRECTORY}"

store_secret_on_vault() {
  echo "Unimplemented feature, waiting for vault to store secrets in"
}

unlock_wallet() {
  cleos wallet unlock --password $(cat ${INSTALL_DIR}/secrets/wallet_password.txt) \
    || echo "Wallet has already been unlocked..."
}

create_wallet() {
  echo "Creating wallet ..."
  mkdir -p ${INSTALL_DIR}/secrets
  cleos wallet create --to-console \
    | awk 'FNR > 3 { print $1 }' \
    | tr -d '"' \
    > ${INSTALL_DIR}/secrets/wallet_password.txt;
  cleos wallet open;
  unlock_wallet
  cleos wallet import --private-key $EOS_PRIV_KEY;
  echo "Wallet created."
}

create_system_accounts() {
  echo "Creating system accounts ..."
  system_accounts=( \
    "eosio.msig" \
    "eosio.token" \
    "validator1" \
    "validator2" \
    "validator3" \
  )

  for account in "${system_accounts[@]}"; do
    echo "Creating $account account..."

    keys=($(cleos create key --to-console))
    pub=${keys[5]}
    priv=${keys[2]}

    cleos wallet import --private-key $priv

    cleos create account eosio $account $pub;
  done
  echo "System accounts created."
}

activate_features() {
  echo "Activating features ..."
  echo SKIP NOT RECOGNIZED KV_DATABASE
  #cleos push action eosio activate '["825ee6288fb1373eab1b5187ec2f04f6eacb39cb3a97f356a07c91622dd61d16"]' -p eosio

  echo ACTION_RETURN_VALUE
  cleos push action eosio activate '["c3a6138c5061cf291310887c0b5c71fcaffeab90d5deb50d3b9e687cead45071"]' -p eosio

  echo CONFIGURABLE_WASM_LIMITS2 *
  cleos push action eosio activate '["d528b9f6e9693f45ed277af93474fd473ce7d831dae2180cca35d907bd10cb40"]' -p eosio@active

  echo SKIP NOT RECOGNIZED CONFIGURABLE_WASM_LIMITS
  #cleos push action eosio activate '["bf61537fd21c61a60e542a5d66c3f6a78da0589336868307f94a82bccea84e88"]' -p eosio

  echo BLOCKCHAIN_PARAMETERS
  cleos push action eosio activate '["5443fcf88330c586bc0e5f3dee10e7f63c76c00249c87fe4fbf7f38c082006b4"]' -p eosio

  echo GET_SENDER
  cleos push action eosio activate '["f0af56d2c5a48d60a4a5b5c903edfb7db3a736a94ed589d0b797df33ff9d3e1d"]' -p eosio

  echo FORWARD_SETCODE
  cleos push action eosio activate '["2652f5f96006294109b3dd0bbde63693f55324af452b799ee137a81a905eed25"]' -p eosio

  echo ONLY_BILL_FIRST_AUTHORIZER
  cleos push action eosio activate '["8ba52fe7a3956c5cd3a656a3174b931d3bb2abb45578befc59f283ecd816a405"]' -p eosio

  echo RESTRICT_ACTION_TO_SELF
  cleos push action eosio activate '["ad9e3d8f650687709fd68f4b90b41f7d825a365b02c23a636cef88ac2ac00c43"]' -p eosio

  echo DISALLOW_EMPTY_PRODUCER_SCHEDULE
  cleos push action eosio activate '["68dcaa34c0517d19666e6b33add67351d8c5f69e999ca1e37931bc410a297428"]' -p eosio

   echo FIX_LINKAUTH_RESTRICTION
  cleos push action eosio activate '["e0fb64b1085cc5538970158d05a009c24e276fb94e1a0bf6a528b48fbc4ff526"]' -p eosio

   echo REPLACE_DEFERRED
  cleos push action eosio activate '["ef43112c6543b88db2283a2e077278c315ae2c84719a8b25f25cc88565fbea99"]' -p eosio

  echo NO_DUPLICATE_DEFERRED_ID
  cleos push action eosio activate '["4a90c00d55454dc5b059055ca213579c6ea856967712a56017487886a4d4cc0f"]' -p eosio

  echo ONLY_LINK_TO_EXISTING_PERMISSION
  cleos push action eosio activate '["1a99a59d87e06e09ec5b028a9cbb7749b4a5ad8819004365d02dc4379a8b7241"]' -p eosio

  echo RAM_RESTRICTIONS
  cleos push action eosio activate '["4e7bf348da00a945489b2a681749eb56f5de00b900014e137ddae39f48f69d67"]' -p eosio

  echo WEBAUTHN_KEY
  cleos push action eosio activate '["4fca8bd82bbd181e714e283f83e1b45d95ca5af40fb89ad3977b653c448f78c2"]' -p eosio

  echo WTMSIG_BLOCK_SIGNATURES
  cleos push action eosio activate '["299dcb6af692324b899b39f16d5a530a33062804e41f09dc97e9f156b4476707"]' -p eosio

  echo GET CODE HASH *
  cleos push action eosio activate '["bcd2a26394b36614fd4894241d3c451ab0f6fd110958c3423073621a70826e99"]' -p eosio@active

  echo GET_BLOCK_NUM *
  cleos push action eosio activate '["35c2186cc36f7bb4aeaf4487b36e57039ccf45a9136aa856a5d569ecca55ef2b"]' -p eosio@active

  echo CRYPTO_PRIMITIVES *
  cleos push action eosio activate '["6bcb40a24e49c26d0a60513b6aeb8551d264e4717f306b81a37a5afb3b47cedc"]' -p eosio@active

  sleep 2;
  echo "Features activated."
}

deploy_contract() {
  CONSTRACT_NAME=$1
  set +e;
  result=1;
  while [ "$result" -ne "0" ]; do
    echo "Setting latest ${CONSTRACT_NAME} contract ...";
    cleos set contract eosio \
      $EOSIO_CONTRACTS_DIRECTORY/eosio.${CONSTRACT_NAME}/ \
      -p eosio \
      -x 1000;
    result=$?
    [[ "$result" -ne "0" ]] && echo "Failed, trying again" && sleep 1;
  done
  set -e;
}

deploy_system_contracts() {
  echo "Deploying system contracts ..."
  curl --request POST \
    --url http://127.0.0.1:8888/v1/producer/schedule_protocol_feature_activations \
    -d '{"protocol_features_to_activate": ["0ec7e080177b2c02b278d5088611686b49d739925a92d9bfcacd7fc6b74053bd"]}'
  sleep 2;

  deploy_contract boot
  sleep 2;

  activate_features

  deploy_contract bios
  sleep 2;

  deploy_contract system
  sleep 2;

  deploy_contract wrap
  sleep 2;

  deploy_contract token
#  cleos set contract eosio.token $EOSIO_CONTRACTS_DIRECTORY/eosio.token/
  sleep 2;

  deploy_contract msig
#  cleos set contract eosio.msig $EOSIO_CONTRACTS_DIRECTORY/eosio.msig/
  sleep 2;

  echo "System contracts deployed."
}

set_msig_privileged_account() {
  echo "Setting MSIG priviledged account ..."
  cleos push action eosio setpriv \
    '["eosio.msig", 1]' -p eosio@active
  echo "MSIG priviledged account was set."
}

create_producer_accounts() {
  echo "Creating producer accounts ..."
  # TODO: @danazkari this needs to be in json
  # and in an env variable so that it can be configured
  producer_accounts=( \
    "jonin.prime.1" \
    "jonin.prime.2" \
    "jonin.prime.3" \
    "jonin.prime.4" \
  );

  for account in "${producer_accounts[@]}"; do
    echo "Creating producer account '$account'";

#     keys=($(cleos create key --to-console))
#     pub=${keys[5]}
#     priv=${keys[2]}

#     cleos wallet import --private-key $priv;

    cleos system newaccount eosio \
      --transfer $account \
      $EOS_PUB_KEY \
      --stake-net "100000000.0000 SYS" \
      --stake-cpu "100000000.0000 SYS" \
      --buy-ram-kbytes 8192;

    cleos system regproducer $account;
  done
  echo "Producer accounts created."
}

run_bios() {
  echo 'Initializing BIOS sequence...'
  create_wallet
  create_system_accounts
  deploy_system_contracts
  set_msig_privileged_account
  # create_producer_accounts
}
