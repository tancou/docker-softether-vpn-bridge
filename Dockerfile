FROM alpine:3.9 as prep

LABEL maintainer="Tomohisa Kusano <siomiz@gmail.com>" \
      contributors="See CONTRIBUTORS file <https://github.com/siomiz/SoftEtherVPN/blob/master/CONTRIBUTORS>"

ENV BUILD_VERSION=4.29-9680-rtm \
    SHA256_SUM=c19cd49835c613cb5551ce66c91f90da3d3496ab3e15e8c61e22b464dc55d9b0

RUN wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/archive/v${BUILD_VERSION}.tar.gz \
    && echo "${SHA256_SUM}  v${BUILD_VERSION}.tar.gz" | sha256sum -c \
    && mkdir -p /usr/local/src \
    && tar -x -C /usr/local/src/ -f v${BUILD_VERSION}.tar.gz \
    && rm v${BUILD_VERSION}.tar.gz


FROM debian:10 as build

COPY --from=prep /usr/local/src /usr/local/src

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    libncurses6 \
    libncurses-dev \
    libreadline7 \
    libreadline-dev \
    libssl1.1 \
    libssl-dev \
    wget \
    zlib1g \
    zlib1g-dev \
    zip \
    && cd /usr/local/src/SoftEtherVPN_Stable-* \
    && ./configure \
    && make \
    && make install \
    && touch /usr/vpnbridge/vpn_bridge.config \
    && zip -r9 /artifacts.zip /usr/vpn* /usr/bin/vpn*

FROM debian:10-slim

COPY --from=build /artifacts.zip /

COPY assets /assets

RUN addgroup softether && adduser -g 'softether' -G softether -s /sbin/nologin -D -H softether && \
    mv /assets/entrypoint.sh / && chmod +x /entrypoint.sh

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libncurses6 \
    libreadline7 \
    libssl1.1 \
    iptables \
    unzip \
    zlib1g \
    && unzip -o /artifacts.zip -d / \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x /entrypoint.sh \
    && rm /artifacts.zip \
    && rm -rf /opt \
    && ln -s /usr/vpnbridge /opt \
    && find /usr/bin/vpn* -type f ! -name vpnbridge \
       -exec bash -c 'ln -s {} /opt/$(basename {})' \;

WORKDIR /usr/vpnbridge/

VOLUME ["/usr/vpnbridge/server_log/"]

EXPOSE 443/tcp 992/tcp 1194/udp 5555/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/vpnbridge", "execsvc"]
