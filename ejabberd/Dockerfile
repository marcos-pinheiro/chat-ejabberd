FROM debian:stretch-slim

LABEL maintainer="Marcos Pinheiro"

ARG PUID=666
ARG PGID=666

ENV EJABBERD_ADMIN_PASSWORD=MY_SUPER_SECRET \
    EJABBERD_DOMAIN= \
    EJABBERD_COOKIE_SECRET=COOKIE_SUPER_SUPER_SECRET \
    EJABBERD_HOME=/home/ejabberd \
    TYPE=none \
    ECS_DNS_REGISTRY=

RUN groupadd --gid ${PGID} ejabberd \
    && useradd -m \
       -g ejabberd \
       -d $EJABBERD_HOME \
       --uid ${PUID} \
       ejabberd

WORKDIR $EJABBERD_HOME
COPY ./template.ejabberdctl.cfg $EJABBERD_HOME/ejabberdctl.cfg
COPY ./run.sh $EJABBERD_HOME/run.sh

RUN apt-get update --fix-missing && apt-get install -y \
    coreutils \
    dnsutils \
    libexpat1 \
    watch \
    wget && \ 
    wget 'https://www.process-one.net/downloads/ejabberd/18.09/ejabberd-18.09-linux-x64.run' -O $EJABBERD_HOME/eja.run && \
    chmod +x ./eja.run && \
    chown ejabberd:ejabberd $EJABBERD_HOME --recursive && chmod +x run.sh

USER ejabberd
EXPOSE 4560 5222 5269 5280 5443

ENTRYPOINT ["./run.sh"]