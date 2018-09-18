dockerfiles
===========

Collection of ready-to-use docker images

## Images

* **[mysql-backup-s3](https://github.com/TheBoroer/dockerfiles/tree/master/mysql-backup-s3)** - Backup MySQL to S3 (supports periodic backups)
* **[postgres-backup-s3](https://github.com/TheBoroer/dockerfiles/tree/master/postgres-backup-s3)** - Backup PostgresSQL to S3 (supports periodic backups)

## FAQ

##### Why do you use `install.sh` scripts instead of putting the commands in the `Dockerfile`?

Structuring an image this way keeps it much smaller.
