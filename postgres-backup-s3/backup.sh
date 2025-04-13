#! /bin/sh

set -e
set -o pipefail

copy_s3() {
  SRC_FILE=$1
  DEST_FILE=$2

  if [ "${S3_ENDPOINT}" == "**None**" ]; then
    AWS_ARGS=""
  else
    AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
  fi

  echo "Uploading $SRC_FILE to $S3_ENDPOINT/$S3_BUCKET/$S3_PREFIX$DEST_FILE"

  #cat $SRC_FILE | aws $AWS_ARGS s3 cp - s3://$S3_BUCKET/$S3_PREFIX/$DEST_FILE || exit 2
  aws $AWS_ARGS s3api put-object --body $SRC_FILE --bucket $S3_BUCKET --key $S3_PREFIX$DEST_FILE || exit 2

  if [ $? != 0 ]; then
    echo >&2 "Error uploading ${DEST_FILE} on S3"
  fi

  rm $SRC_FILE
}

# Check for required env vars
if [ "${S3_ACCESS_KEY_ID}" = "**None**" ]; then
  echo "You need to set the S3_ACCESS_KEY_ID environment variable."
  exit 1
fi

if [ "${S3_SECRET_ACCESS_KEY}" = "**None**" ]; then
  echo "You need to set the S3_SECRET_ACCESS_KEY environment variable."
  exit 1
fi

if [ "${S3_BUCKET}" = "**None**" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  echo "You need to set the POSTGRES_HOST environment variable."
  exit 1
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi

if [ "${S3_ENDPOINT}" == "**None**" ]; then
  AWS_ARGS=""
else
  AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi

# Set default values
if [ -z "${POSTGRES_PORT}" ]; then
  POSTGRES_PORT=5432
fi

if [ "${POSTGRES_DATABASE}" = "**None**" ]; then
  echo "POSTGRES_DATABASE environment variable isn't set, defaulting to backing up all databases."
fi

# env vars needed for aws tools
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER $POSTGRES_EXTRA_OPTS"
DUMP_START_TIME=$(date +"%Y-%m-%dT%H:%M:%SZ")

if [ "${POSTGRES_DATABASE}" != "**None**" ]; then
  # Backup single specified database
  BACKUP_FILENAME="${POSTGRES_DATABASE}.sql.gz"
  echo "Creating dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST} to ${BACKUP_FILENAME}..."
  pg_dump $POSTGRES_HOST_OPTS $POSTGRES_DATABASE | gzip >"${BACKUP_FILENAME}"
  copy_s3 $BACKUP_FILENAME $BACKUP_FILENAME
else
  # Backup all databases

  # Multi file: yes
  if [ ! -z "$(echo $MULTI_FILES | grep -i -E "(yes|true|1)")" ]; then
    # backup globals
    BACKUP_FILENAME="globals.sql.gz"
    echo "Creating dump of globals from ${POSTGRES_HOST}:${POSTGRES_PORT}..."
    pg_dumpall $POSTGRES_HOST_OPTS --globals-only | gzip >"${BACKUP_FILENAME}"
    copy_s3 $BACKUP_FILENAME $BACKUP_FILENAME

    # backup each database into a separate file
    for DB in $(psql $POSTGRES_HOST_OPTS -l -t | cut -d'|' -f1 | sed -e 's/ //g' -e '/^$/d' | grep -v -E "(template0|template1)"); do
      BACKUP_FILENAME="${DB}.sql.gz"
      echo "Creating dump of ${DB} from ${POSTGRES_HOST}:${POSTGRES_PORT}..."
      pg_dump $POSTGRES_HOST_OPTS --create $DB | gzip >"${BACKUP_FILENAME}"
      copy_s3 $BACKUP_FILENAME $BACKUP_FILENAME
    done
  else
    # backup all databases into a single dump file
    BACKUP_FILENAME="${POSTGRES_HOST}_${POSTGRES_PORT}_${DUMP_START_TIME}.sql.gz"
    echo "Creating dump of all databases from ${POSTGRES_HOST}:${POSTGRES_PORT}..."
    pg_dumpall $POSTGRES_HOST_OPTS --clean --if-exists | gzip >"${BACKUP_FILENAME}"
    copy_s3 $BACKUP_FILENAME $BACKUP_FILENAME
  fi
fi

echo "Backup complete."
