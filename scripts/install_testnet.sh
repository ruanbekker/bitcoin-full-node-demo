#!/usr/bin/env bash

export ARCH=x86_64
export BITCOIN_VERSION=0.21.1
export BITCOIN_URL=https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz
export BITCOIN_SIGNATURE=01EA5486DE18A882D4C2684590C8019E36C2E964
export BITCOIN_DATA=/blockchain

sudo groupadd -r bitcoin
sudo useradd -r -m -g bitcoin -s /bin/bash bitcoin
sudo apt update && sudo apt install ca-certificates gnupg gpg wget -qq --no-install-recommends -y

cd /tmp
wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc
wget -qO bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz ${BITCOIN_URL}
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ${BITCOIN_SIGNATURE}
gpg --verify SHA256SUMS.asc

grep bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz SHA256SUMS.asc > SHA256SUM
sha256sum -c SHA256SUM
sudo tar -xzvf bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz -C /usr/local --strip-components=1 --exclude=*-qt
sudo rm -rf /tmp/*
sudo mkdir -p ${BITCOIN_DATA}/.bitcoin
sudo ln -sfn ${BITCOIN_DATA} /home/bitcoin/.bitcoin
sudo chown -h bitcoin:bitcoin /home/bitcoin/.bitcoin
sudo chown -R bitcoin:bitcoin ${BITCOIN_DATA}

cat > "bitcoin.conf.tmp" << EOF
datadir=${BITCOIN_DATA}/.bitcoin
printtoconsole=1
#rpcallowip=::/0
rpcallowip=127.0.0.1/32
rpcuser=${BITCOIN_RPC_USER:-bitcoin}
rpcpassword=${BITCOIN_RPC_PASSWORD:-password}
testnet=1
prune=2000
[test]
rpcport=18332
EOF

cat > bitcoind.service <<  EOF
[Unit]
Description=Bitcoin Core Testnet
After=network.target

[Service]
User=bitcoin
Group=bitcoin
WorkingDirectory=/home/bitcoin

Type=simple
ExecStart=/usr/local/bin/bitcoind -conf=/home/bitcoin/.bitcoin/bitcoin.conf

[Install]
WantedBy=multi-user.target
EOF

sudo mv bitcoin.conf.tmp ${BITCOIN_DATA}/.bitcoin/bitcoin.conf
sudo chown -R bitcoin:bitcoin ${BITCOIN_DATA}
sudo mv bitcoind.service /etc/systemd/system/bitcoind.service
sudo systemctl daemon-reload
sudo systemctl enable bitcoind
sudo systemctl restart bitcoind
