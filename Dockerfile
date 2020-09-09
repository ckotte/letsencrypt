FROM ckotte/jobber:1.4.4
MAINTAINER Christian Kotte

# Image Build Date By Buildsystem
ARG BUILD_DATE=undefined

USER root

ENV CERTBOT_VERSION=1.4.0-r0

RUN export CERTBOT_HOME=/opt/certbot && \
    export PATH="${CERTBOT_HOME}:${PATH}"

RUN if  [ "${CERTBOT_VERSION}" = "latest" ]; \
      then apk add certbot ; \
      else apk add "certbot=${CERTBOT_VERSION}" ; \
    fi && \
    # Clean caches and tmps
    rm -rf /var/cache/apk/* && \
    rm -rf /tmp/* && \
    rm -rf /var/log/*

VOLUME ["/etc/letsencrypt"]
EXPOSE 80

# Image Metadata
LABEL com.opencontainers.image.builddate.letsencrypt=${BUILD_DATE}

COPY imagescripts /opt/letsencrypt
ENTRYPOINT ["/opt/letsencrypt/docker-entrypoint.sh"]
CMD ["jobberd"]
