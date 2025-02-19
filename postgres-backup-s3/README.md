# postgres-backup-s3

Backup PostgresSQL to S3 (supports periodic backups)

## Usage

Docker:

```sh
$ docker run -e S3_ACCESS_KEY_ID=key -e S3_SECRET_ACCESS_KEY=secret -e S3_BUCKET=my-bucket -e S3_PREFIX=backup -e POSTGRES_DATABASE=dbname -e POSTGRES_USER=user -e POSTGRES_PASSWORD=password -e POSTGRES_HOST=localhost boro/postgres-backup-s3
```

Docker Compose:

```yaml
postgres:
  image: postgres
  environment:
    POSTGRES_USER: user
    POSTGRES_PASSWORD: password

pgbackups3:
  image: boro/postgres-backup-s3
  links:
    - postgres
  environment:
    SCHEDULE: "@daily"
    S3_ENDPOINT: region
    S3_ACCESS_KEY_ID: key
    S3_SECRET_ACCESS_KEY: secret
    S3_BUCKET: my-bucket
    S3_PREFIX: daily/backup
    POSTGRES_DATABASE: dbname
    POSTGRES_HOST: postgres
    POSTGRES_PORT: 5432
    POSTGRES_USER: user
    POSTGRES_PASSWORD: password
    POSTGRES_EXTRA_OPTS: "--schema=public --blobs"
```

### If `POSTGRES_DATABASE` is not set

It will attempt to use the login credentials to find & backup all databases into a single .sql.gz file.

If `MULTI_FILES` is set to `yes`, it'll create a separate gzip backup for each database + a gzip for postgres globals.

### Automatic Periodic Backups

You can additionally set the `SCHEDULE` environment variable like `-e SCHEDULE="@daily"` to run the backup automatically.

More information about the scheduling can be found [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules).

## Environment Variables

The following environment variables can be set to configure the behavior of the `postgres-backup-s3` container:

- **S3_ACCESS_KEY_ID**: Your AWS access key ID. This is required to authenticate with AWS S3.
- **S3_SECRET_ACCESS_KEY**: Your AWS secret access key. This is required to authenticate with AWS S3.
- **S3_BUCKET**: The name of the S3 bucket where backups will be stored. This is required.
- **S3_REGION**: The AWS region where your S3 bucket is located. Defaults to `us-west-1`.
- **S3_PREFIX**: The prefix (or folder path) within the S3 bucket where backups will be stored. Defaults to `backup`.
- **S3_ENDPOINT**: Custom S3 endpoint URL, useful for S3-compatible services. Defaults to `None`.
- **POSTGRES_DATABASE**: The name of the PostgreSQL database to back up. If not set, all databases will be backed up.
- **POSTGRES_HOST**: The hostname or IP address of the PostgreSQL server. This is required.
- **POSTGRES_PORT**: The port number on which the PostgreSQL server is listening. Defaults to `5432`.
- **POSTGRES_USER**: The PostgreSQL user to connect as. This is required.
- **POSTGRES_PASSWORD**: The password for the PostgreSQL user. This is required.
- **POSTGRES_EXTRA_OPTS**: Additional options to pass to the `pg_dump` or `pg_dumpall` command.
- **SCHEDULE**: A cron expression defining the schedule for automatic backups. If not set, backups must be triggered manually.
- **MULTI_FILES**: If set to `yes`, each database will be backed up into a separate file, along with a separate file for PostgreSQL globals.

These environment variables allow you to customize the backup process to suit your needs, including specifying which databases to back up, where to store the backups, and how often to perform the backups automatically.
