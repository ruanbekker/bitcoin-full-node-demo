# Install Bitcoin Core on Linux

This will demonstrate how to install bitcoin core on Linux

### Note

The following commands will be executed as a non-root user

### Environment Variables

Set the following environment variables, the latest version for `BITCOIN_VERSION` can be retrieved at: https://bitcoincore.org/bin/, execute the following:

```
export ARCH=x86_64
export BITCOIN_VERSION=0.21.1
export BITCOIN_URL=https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz
export BITCOIN_SIGNATURE=01EA5486DE18A882D4C2684590C8019E36C2E964
export BITCOIN_DATA=/data
```

### Installation

Create the user and group for bitcoin:

```
sudo groupadd -r bitcoin
sudo useradd -r -m -g bitcoin -s /bin/bash bitcoin
```

Update the package manager and install the dependencies:

```
sudo apt update && sudo apt install ca-certificates gnupg gpg wget --no-install-recommends -y
```

Download bitcoin-core and verify that the package matches the sha hash:

```
cd /tmp
wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc
wget -qO bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz "${BITCOIN_URL}"
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ${BITCOIN_SIGNATURE}
gpg --verify SHA256SUMS.asc
grep bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz SHA256SUMS.asc > SHA256SUM
sha256sum -c SHA256SUM
```

Extract the package to `/usr/local` and exclude any graphical user interfacing binaries, create the home directory and set the ownership:

```
sudo tar -xzvf bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz -C /usr/local --strip-components=1 --exclude=*-qt
sudo rm -rf /tmp/*
sudo mkdir "$BITCOIN_DATA"
sudo chown -R bitcoin:bitcoin "$BITCOIN_DATA"
sudo ln -sfn "$BITCOIN_DATA" /home/bitcoin/.bitcoin
sudo chown -h bitcoin:bitcoin /home/bitcoin/.bitcoin
```

### Configuration

Create the bitcoin configuration, here you see I am using the testnet and due to storage restrictions for my use-case I am setting `pruning` mode to 1GB, and if you dont set `BITCOIN_RPC_USER` it will use the user `bitcoin` and if you don't set `BITCOIN_RPC_PASSWORD` it will generate a password for the json-rpc interface: 

```
cat > "bitcoin.conf.tmp" << EOF
datadir=/home/bitcoin/.bitcoin
printtoconsole=1
rpcallowip=127.0.0.1
rpcuser=${BITCOIN_RPC_USER:-bitcoin}
rpcpassword=${BITCOIN_RPC_PASSWORD:-$(openssl rand -hex 24)}
testnet=1
prune=1000
[test]
rpcport=18332
EOF
```

Create the systemd unit-file for bitcoind:

```
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
```

Now move the temporary config files, change the ownership and symlink the bitcoin home directory to the path that we created earlier:

```
sudo mv bitcoin.conf.tmp "$BITCOIN_DATA/bitcoin.conf"
sudo chown bitcoin:bitcoin "$BITCOIN_DATA/bitcoin.conf"
sudo chown -R bitcoin "$BITCOIN_DATA"
sudo ln -sfn "$BITCOIN_DATA" /home/bitcoin/.bitcoin
sudo chown -R bitcoin:bitcoin /home/bitcoin/.bitcoin
```

Move the systemd unit file in place, then reload systemd and start bitcoind:

```
sudo mv bitcoind.service /etc/systemd/system/bitcoind.service
sudo systemctl daemon-reload
sudo systemctl enable bitcoind
sudo systemctl start bitcoind
```

### Test

Once bitcoind has started, the initial block download will start and you can get the progress using the cli:

```
bitcoin-cli -conf=/home/bitcoin/.bitcoin/bitcoin.conf -getinfo
```

### Troubleshooting

If you run into any issues you can see the status of bitcoind using:

```
$ sudo systemctl status bitcoind
```

Or check the logs:

```
sudo journalctl -fu bitcoind
```
