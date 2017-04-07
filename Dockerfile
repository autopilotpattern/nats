FROM alpine:3.5

RUN apk update && \
    apk add curl \
            unzip \
            bash \
            jq \
            ca-certificates && \
    rm -rf /var/cache/apk/*


# Add Consul agent
ENV CONSUL_VERSION=0.7.0 \
    CONSUL_CHECKSUM=b350591af10d7d23514ebaa0565638539900cdb3aaa048f077217c4c46653dd8
RUN curl --retry 7 --fail -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_CHECKSUM}  /tmp/consul.zip" | sha256sum -c \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    && mkdir -p /opt/consul/config

# Add Consul-CLI
ENV CONSUL_CLI_VER=0.3.1 \
    CONSUL_CLI_SHA256=037150d3d689a0babf4ba64c898b4497546e2fffeb16354e25cef19867e763f1
RUN curl -Lso /tmp/consul-cli.tgz "https://github.com/CiscoCloud/consul-cli/releases/download/v${CONSUL_CLI_VER}/consul-cli_${CONSUL_CLI_VER}_linux_amd64.tar.gz" \
    && echo "${CONSUL_CLI_SHA256}  /tmp/consul-cli.tgz" | sha256sum -c \
    && tar zxf /tmp/consul-cli.tgz -C /usr/local/bin --strip-components 1 \
    && rm /tmp/consul-cli.tgz

# Add Consul-Template
ENV CONSUL_TEMPLATE_VER=0.18.2 \
    CONSUL_TEMPLATE_SHA256=6fee6ab68108298b5c10e01357ea2a8e4821302df1ff9dd70dd9896b5c37217c
RUN curl -Lso /tmp/consul-template.zip "https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VER}/consul-template_${CONSUL_TEMPLATE_VER}_linux_amd64.zip" \
    && echo "${CONSUL_TEMPLATE_SHA256}  /tmp/consul-template.zip" | sha256sum -c \
    && unzip -d /usr/local/bin /tmp/consul-template.zip \
    && rm /tmp/consul-template.zip

# Add ContainerPilot and set its configuration file path
ENV CONTAINERPILOT_VER=2.7.2 \
    CONTAINERPILOT=file:///etc/containerpilot.json \
    CONTAINERPILOT_CHECKSUM=e886899467ced6d7c76027d58c7f7554c2fb2bcc
RUN curl -Lso /tmp/containerpilot.tar.gz \
        "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

# Add NATS
ENV GNATSD_VERSION=0.9.6 \
    GNATSD_CHECKSUM=00815d521261e23dfc752dd23a00bc12997a5991
RUN curl -Lso /tmp/gnatsd.zip \
        "https://github.com/nats-io/gnatsd/releases/download/v${GNATSD_VERSION}/gnatsd-v${GNATSD_VERSION}-linux-386.zip" \
    && echo "${GNATSD_CHECKSUM}  /tmp/gnatsd.zip" | sha1sum -c \
    && unzip -j /tmp/gnatsd.zip -d /tmp

RUN mv /tmp/gnatsd /usr/local/bin/gnatsd \
    && rm /tmp/gnatsd.zip

# COPY ContainerPilot configuration and NATS manage.sh
COPY etc/* /etc/
COPY bin/* /usr/local/bin/

RUN chmod 500 /usr/local/bin/manage.sh

EXPOSE 4222 8222 6222

ENTRYPOINT ["containerpilot"]
CMD ["manage.sh", "onStart"]
