FROM tangocs/tango-lib-dependencies:latest as buildenv

ARG TANGO_DISTRIBUTION_VERSION

RUN TANGO_DOWNLOAD_URL=https://github.com/tango-controls/TangoSourceDistribution/releases/download/${TANGO_DISTRIBUTION_VERSION}/tango-${TANGO_DISTRIBUTION_VERSION}.tar.gz \
    # Speed up image builds by adding apt proxy if detected on host
    && DOCKERHOST=`awk '/^[a-z]+[0-9]+\t00000000/ { printf("%d.%d.%d.%d", "0x" substr($3, 7, 2), "0x" substr($3, 5, 2), "0x" substr($3, 3, 2), "0x" substr($3, 1, 2)) }' < /proc/net/route` \
    && /usr/local/bin/wait-for-it.sh --host=$DOCKERHOST --port=3142 --timeout=3 --strict --quiet -- echo "Acquire::http::Proxy \"http://$DOCKERHOST:3142\";" > /etc/apt/apt.conf.d/30proxy \
    && echo "Proxy detected on docker host - using for this build" || echo "No proxy detected on docker host" \
    && buildDeps='build-essential ca-certificates wget file omniidl libomniorb4-dev libcos4-dev libomnithread3-dev libzmq3-dev libmariadbclient-dev libmariadbclient-dev-compat pkg-config python' \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends $buildDeps \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/src/tango \
    && cd /usr/src/tango \
    && wget -O tango.tar.gz "$TANGO_DOWNLOAD_URL"  \
    && tar xf tango.tar.gz -C /usr/src/tango --strip-components=1 \
    && ./configure --with-zmq=/usr/local --with-mysqlclient-prefix=/usr --enable-static=no \
    && make -C /usr/src/tango -j$(nproc) \
    && make -C /usr/src/tango install \
    && ldconfig \
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -r /usr/src/tango

FROM debian:stretch-slim
COPY --from=buildenv /usr/local /usr/local

RUN runtimeDeps='libzmq5 libomniorb4-1 libcos4-1 libmariadbclient18 sudo' \
    && DOCKERHOST=`awk '/^[a-z]+[0-9]+\t00000000/ { printf("%d.%d.%d.%d", "0x" substr($3, 7, 2), "0x" substr($3, 5, 2), "0x" substr($3, 3, 2), "0x" substr($3, 1, 2)) }' < /proc/net/route` \
    && /usr/local/bin/wait-for-it.sh --host=$DOCKERHOST --port=3142 --timeout=3 --strict --quiet -- echo "Acquire::http::Proxy \"http://$DOCKERHOST:3142\";" > /etc/apt/apt.conf.d/30proxy \
    && echo "Proxy detected on docker host - using for this build" || echo "No proxy detected on docker host" \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends $runtimeDeps \
    && rm -f /etc/apt/apt.conf.d/30proxy
