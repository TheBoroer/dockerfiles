FROM alpine:3.21

RUN apk update

# install pg_dump
RUN apk add postgresql

# install s3 tools
RUN apk add aws-cli

# install go-cron
RUN apk add curl && \
    curl -L --insecure https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz | zcat > /usr/local/bin/go-cron && \
    chmod u+x /usr/local/bin/go-cron && \
    apk del curl

# cleanup
RUN rm -rf /var/cache/apk/*

ENV POSTGRES_DATABASE **None**
ENV POSTGRES_HOST **None**
ENV POSTGRES_PORT 5432
ENV POSTGRES_USER **None**
ENV POSTGRES_PASSWORD **None**
ENV POSTGRES_EXTRA_OPTS ''

ENV S3_ACCESS_KEY_ID **None**
ENV S3_SECRET_ACCESS_KEY **None**
ENV S3_BUCKET **None**
ENV S3_REGION us-west-1
ENV S3_PREFIX 'backup'
ENV S3_ENDPOINT **None**
ENV S3_S3V4 no

ENV SCHEDULE **None**
ENV MULTI_FILES no

ADD run.sh run.sh
ADD backup.sh backup.sh

CMD ["sh", "run.sh"]
