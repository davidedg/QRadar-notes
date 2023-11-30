# Restore a Config backup to a new system, without the original AppHost

- Prepare a new Console (3199), same patch level of the backup file
- Upload the backup tar file (See [this article](https://www.ibm.com/support/pages/qradar-cannot-import-configuration-backups-due-invalid-backup-archive) if bigger than 512MB)
- Restore Everything (or leave out what you don't need)
- Wait :D
- Go to Admin - System and License Management and remove all the hosts except the AppHost
- Try the first full deploy, it will fail on the missing AppHost but should otherwise complete
- Force stop all apps (see [this](https://www.ibm.com/support/pages/qradar-changing-status-application-fails-error-application-instance-not-required-state) article)
- Get the Console managed host id: `psql -U qradar -c "SELECT id FROM managedhost WHERE isconsole;"`
- Update `installed_application_host_type_property` to point the app instances to the Console

      UPDATE installed_application_host_type_property SET value = <CONSOLE_ID> WHERE key = 'managed_host_id';
- Edit `/store/qapp/appdefaultserver.cache` to contain the Console managed host id

- Go to Admin - System and License Management and remove the AppHost
- Run a Full Deploy
