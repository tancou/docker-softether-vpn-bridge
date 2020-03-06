FROM alpine:3.5
LABEL maintainer "Antoine Mary <antoinee.mary@gmail.com>"

### SET ENVIRONNEMENT
ENV LANG="en_US.UTF-8" \
    SOFTETHER_VERSION="4.29-9680-rtm"

### SETUP
COPY assets /assets
RUN apk --no-cache add wget make gcc musl-dev readline-dev openssl-dev ncurses-dev libcap su-exec && \
    addgroup softether && adduser -g 'softether' -G softether -s /sbin/nologin -D -H softether && \
    mv /assets/entrypoint.sh / && chmod +x /entrypoint.sh && \

    # Fetch sources
    wget --no-check-certificate -O - https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/archive/v${SOFTETHER_VERSION}.tar.gz | tar xzf - && \
    cd SoftEtherVPN_Stable-${SOFTETHER_VERSION} && \
    # Compile and Install
    cp src/makefiles/linux_64bit.mak Makefile && \
    make && make install && make clean && \

    # Cleanning
    apk del wget make gcc musl-dev readline-dev openssl-dev ncurses-dev && \
    # Reintroduce necessary libraries
    apk --no-cache add libssl1.0	libcrypto1.0 readline ncurses-libs && \
    # Removing vpnclient, vpncmd vpnserver and build files
    cd .. && rm -rf /usr/vpnclient /usr/bin/vpnclient /usr/vpncmd /usr/bin/vpncmd /usr/vpnserver /usr/bin/vpnserver /usr/bin/vpnbridge \
    /assets SoftEtherVPN_Stable-${SOFTETHER_VERSION}

EXPOSE 443/tcp 992/tcp 1194/udp 5555/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/vpnbridge/vpnbridge", "execsvc"]
