FROM alpine:3.9 as builder
ARG OPENFORTIVPN_VERSION=v1.9.0
ENV OPENFORTIVPN_VERSION=$OPENFORTIVPN_VERSION
RUN \
  apk update && \
  apk add --no-cache \
    autoconf automake build-base ca-certificates curl git openssl-dev ppp && \
  update-ca-certificates && \
  # build openfortivpn
  mkdir -p /usr/src/openfortivpn && \
  curl -sL https://github.com/adrienverge/openfortivpn/archive/${OPENFORTIVPN_VERSION}.tar.gz \
    | tar xz -C /usr/src/openfortivpn --strip-components=1 && \
  cd /usr/src/openfortivpn && \
  ./autogen.sh && \
  ./configure --prefix=/usr --sysconfdir=/etc && \
  make -j$(nproc) && \
  make install



FROM alpine:3.9
RUN \
  apk update && \
  apk add --no-cache \
    bash ca-certificates openssl ppp \
    rsync openssh-client curl
COPY --from=builder /usr/bin/openfortivpn /usr/bin/
COPY vpn-entrypoint.sh /usr/bin/
RUN chmod 777 /usr/bin/vpn-entrypoint.sh

ENTRYPOINT ["/usr/bin/vpn-entrypoint.sh"]