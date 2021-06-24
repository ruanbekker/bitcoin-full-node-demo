#!/usr/bin/env bash
set -e

if [[ "${1}" == "bitcoin-cli" || "${1}" == "bitcoin-tx" || "${1}" == "bitcoind" || "${1}" == "test_bitcoin" ]]; 
  then
    mkdir -p ${BITCOIN_DATA_DIR}

    if [[ ! -s "${BITCOIN_DATA_DIR}/bitcoin.conf" ]]; then
      cat <<-EOF > "${BITCOIN_DATA_DIR}/bitcoin.conf"
      printtoconsole=1
      rpcallowip=::/0
      rpcuser=${BITCOIN_RPC_USER:-bitcoin}
      rpcpassword=${BITCOIN_RPC_PASSWORD:-password}
      testnet=1
      prune=1000
      [test]
      rpcport=18332
		  EOF
      
		  chown ${BITCOIN_DATA_DIR}:${BITCOIN_DATA_DIR} ${BITCOIN_DATA_DIR}/bitcoin.conf
	  fi

  chown -R ${BITCOIN_USER}:${BITCOIN_GROUP} ${BITCOIN_DATA_DIR}
  ln -sfn ${BITCOIN_DATA_DIR} /home/bitcoin/.bitcoin
  chown -h ${BITCOIN_USER}:${BITCOIN_GROUP} /home/bitcoin/.bitcoin
  exec gosu ${BITCOIN_USER} "$@"
fi

exec "$@"
