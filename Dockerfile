FROM debian:buster-slim

ENV BITCOIN_USER  bitcoin
ENV BITCOIN_GROUP bitcoin
ENV BITCOIN_RPC_USER
ENV BITCOIN_RPC_PASSWORD

RUN groupadd -r ${BITCOIN_GROUP} \
    && useradd -r -m -g ${BITCOIN_GROUP} -s /bin/bash ${BITCOIN_USER}

RUN set -ex \
    && apt update \
    && apt install ca-certificates dirmngr gosu gnupg gpg wget --no-install-recommends -y \
    && rm -rf /var/lib/apt/lists/*

ENV ARCH x86_64
ENV BITCOIN_VERSION 0.21.1
ENV BITCOIN_URL https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz
ENV BITCOIN_SIGNATURE 01EA5486DE18A882D4C2684590C8019E36C2E964
ENV BITCOIN_DATA_DIR /blockchain

# install bitcoin binaries
RUN set -ex \
  && cd /tmp \
  && wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc \
  && wget -qO bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz ${BITCOIN_URL} \
  && gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys ${BITCOIN_SIGNATURE} \
  && gpg --verify SHA256SUMS.asc \
  && grep bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz SHA256SUMS.asc > SHA256SUM \
  && sha256sum -c SHA256SUM \
  && tar -xzvf bitcoin-${BITCOIN_VERSION}-${ARCH}-linux-gnu.tar.gz -C /usr/local --strip-components=1 --exclude=*-qt \
  && rm -rf /tmp/*

# create data directory
RUN mkdir -p ${BITCOIN_DATA_DIR} \
  && chown -R ${BITCOIN_USER}:${BITCOIN_GROUP} ${BITCOIN_DATA_DIR} \
  && ln -sfn ${BITCOIN_DATA_DIR} /home/bitcoin/.bitcoin \
  && chown -h ${BITCOIN_USER}:${BITCOIN_GROUP} /home/bitcoin/.bitcoin

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/bin/bitcoind"]
