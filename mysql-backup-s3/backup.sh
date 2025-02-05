#! /bin/sh

set -e
set -o pipefail

if [ "${S3_ACCESS_KEY_ID}" = "**None**" ]; then
  echo "You need to set the S3_ACCESS_KEY_ID environment variable."
  exit 1
fi

if [ "${S3_SECRET_ACCESS_KEY}" = "**None**" ]; then
  echo "You need to set the S3_SECRET_ACCESS_KEY environment variable."
  exit 1
fi

if [ "${S3_BUCKET}" == "**None**" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${MYSQL_HOST}" == "**None**" ]; then
  echo "You need to set the MYSQL_HOST environment variable."
  exit 1
fi

if [ "${MYSQL_USER}" == "**None**" ]; then
  echo "You need to set the MYSQL_USER environment variable."
  exit 1
fi

if [ "${MYSQL_PASSWORD}" == "**None**" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
  exit 1
fi

# env vars needed for aws tools
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

MYSQL_HOST_OPTS="-h $MYSQL_HOST -P $MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD --skip-ssl"
DUMP_START_TIME=$(date +"%Y-%m-%dT%H:%M:%SZ")

copy_s3 () {
  SRC_FILE=$1
  DEST_FILE=$2

  if [ "${S3_ENDPOINT}" == "**None**" ]; then
    AWS_ARGS=""
  else
    AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
  fi

  echo "Uploading $SRC_FILE dump to $S3_ENDPOINT/$S3_BUCKET/$S3_PREFIX$DEST_FILE"

  #cat $SRC_FILE | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/$DEST_FILE || exit 2
  aws $AWS_ARGS s3api put-object --body $SRC_FILE --bucket $S3_BUCKET --key $S3_PREFIX$DEST_FILE || exit 2
  
  if [ $? != 0 ]; then
    >&2 echo "Error uploading ${DEST_FILE} on S3"
  fi

  rm $SRC_FILE
}

# Multi file: yes
if [ ! -z "$(echo $MULTI_FILES | grep -i -E "(yes|true|1)")" ]; then
  if [ "${MYSQLDUMP_DATABASE}" == "--all-databases" ]; then
    DATABASES=`/usr/bin/mariadb $MYSQL_HOST_OPTS -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys|innodb)"`
  else
    DATABASES=$MYSQLDUMP_DATABASE
  fi

  for DB in $DATABASES; do
    echo "Creating individual dump of ${DB} from ${MYSQL_HOST}..."

    DUMP_FILE="/tmp/${DB}.sql.gz"

    /usr/bin/mariadb-dump $MYSQL_HOST_OPTS $MYSQLDUMP_OPTIONS --databases $DB | gzip > $DUMP_FILE

    if [ $? == 0 ]; then
      S3_FILE="${DB}_${DUMP_START_TIME}.sql.gz"
      copy_s3 $DUMP_FILE $S3_FILE
    else
      >&2 echo "Error creating dump of ${DB}"
    fi
  done
# Multi file: no
else
  echo "Creating dump for ${MYSQLDUMP_DATABASE} from ${MYSQL_HOST}..."

  DUMP_FILE="/tmp/dump.sql.gz"
  /usr/bin/mariadb-dump $MYSQL_HOST_OPTS $MYSQLDUMP_OPTIONS $MYSQLDUMP_DATABASE | gzip > $DUMP_FILE

  if [ $? == 0 ]; then
    S3_FILE="mysql_${DUMP_START_TIME}.sql.gz"
    copy_s3 $DUMP_FILE $S3_FILE
  else
    >&2 echo "Error creating dump of all databases"
  fi
fi

echo "SQL backup uploaded successfully"
