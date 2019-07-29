FROM debian:stretch

MAINTAINER info@tango-controls.org

ARG TANGO_LIB_VER

ARG TANGO_SOURCE_DISTRIBUTION_VER

#get TangoSourceDistribution
RUN apt-get update && apt-get install -y wget

RUN wget https://github.com/tango-controls/TangoSourceDistribution/releases/download/${TANGO_SOURCE_DISTRIBUTION_VER}/tango-${TANGO_SOURCE_DISTRIBUTION_VER}.tar.gz

RUN tar zxvf tango-${TANGO_SOURCE_DISTRIBUTION_VER}.tar.gz

RUN rm tango-${TANGO_SOURCE_DISTRIBUTION_VER}.tar.gz

#install cppzmq
RUN apt-get update && apt-get install -y git build-essential cmake libzmq3-dev pkg-config

RUN git clone -b v4.2.2 https://github.com/zeromq/cppzmq.git cppzmq

RUN cmake -H/cppzmq -B/cppzmq/build  -DCMAKE_INSTALL_PREFIX=/usr

RUN make -C /cppzmq/build install

RUN apt-get update && apt-get install -y omniidl libomniorb4-dev libcos4-dev libomnithread3-dev mysql-client default-libmysqlclient-dev

WORKDIR /tango-${TANGO_LIB_VER}

#RUN ./configure --prefix=/build --disable-java --with-mysql-ho=127.0.0.1 --with-mysql-admin=root --with-mysql-admin-passwd=""

#RUN make && make install