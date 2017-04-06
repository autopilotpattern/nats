FROM alpine:3.5

RUN apk update && \
    apk add curl \
            unzip \
            bash \
            ca-certificates && \
    rm -rf /var/cache/apk/*


# Add Consul agent
ENV CONSUL_VERSION=0.7.0
RUN export CONSUL_CHECKSUM=b350591af10d7d23514ebaa0565638539900cdb3aaa048f077217c4c46653dd8 \
    && curl --retry 7 --fail -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_CHECKSUM}  /tmp/consul.zip" | sha256sum -c \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    && mkdir -p /opt/consul/config

# Add ContainerPilot and set its configuration file path
ENV CONTAINERPILOT_VER=2.7.2 \
    CONTAINERPILOT=file:///etc/containerpilot.json
RUN export CONTAINERPILOT_CHECKSUM=e886899467ced6d7c76027d58c7f7554c2fb2bcc \
    && curl -Lso /tmp/containerpilot.tar.gz \
        "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

ENV GNATSD_VERSION=0.9.6
RUN export GNATSD_CHECKSUM=00815d521261e23dfc752dd23a00bc12997a5991 \
    && curl -Lso /tmp/gnatsd.zip \
        "https://github.com/nats-io/gnatsd/releases/download/v${GNATSD_VERSION}/gnatsd-v${GNATSD_VERSION}-linux-386.zip" \
    && echo "${GNATSD_CHECKSUM}  /tmp/gnatsd.zip" | sha1sum -c \
    && unzip -j /tmp/gnatsd.zip -d /tmp

RUN mv /tmp/gnatsd /usr/local/bin/gnatsd \
    && rm /tmp/gnatsd.zip

# COPY ContainerPilot configuration and NATS health check
COPY etc/* /etc/
COPY bin/health.sh /usr/local/bin/health.sh

RUN apk del unzip ca-certificates
RUN chmod 500 /usr/local/bin/health.sh

EXPOSE 4222 8222 6222

ENTRYPOINT ["containerpilot"]
CMD ["gnatsd", "-c", "/etc/gnatsd.conf"]
