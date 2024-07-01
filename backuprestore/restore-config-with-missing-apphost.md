# Restore a Config backup to a new system, without the original AppHost

- Prepare a new Console (3199), same patch level of the backup file
- Upload the backup tar file (See [this article](https://www.ibm.com/support/pages/qradar-cannot-import-configuration-backups-due-invalid-backup-archive) if bigger than 512MB)
- Restore Everything (or leave out what you don't need)
- Wait :D
- (optional): [Change admin password](https://www.ibm.com/support/pages/qradar-changing-admin-account-password-ui-or-cli): `/opt/qradar/support/changePasswd.sh -a`
- Force stop all apps (see [this](https://www.ibm.com/support/pages/qradar-changing-status-application-fails-error-application-instance-not-required-state) article)

      psql -U qradar -c "update installed_application_instance set status='STOPPED',task_status='COMPLETED';"

- Update `installed_application_host_type_property` to point the app instances to the Console:

      echo "
      SELECT * from installed_application_host_type_property;
      UPDATE installed_application_host_type_property 
      SET value = ( SELECT id FROM managedhost WHERE isconsole AND status = 'Active' )
      WHERE key = 'managed_host_id';
      SELECT * from installed_application_host_type_property;
      " | psql -U qradar

- Edit `/store/qapp/appdefaultserver.cache` to contain the Console managed host id:

      $(psql -U qradar -t -A -c "SELECT id FROM managedhost WHERE isconsole AND status = 'Active';") | tee /store/qapp/appdefaultserver.cache

- Go to Admin - System and License Management and remove all the managed hosts, including the AppHost
- (optional) Allow for apps on your Console with [APP_CONSOLE_MEMORY_PERCENT](https://github.com/davidedg/QRadar-notes/tree/main/LAB_EnlargeYour_Apps_Memory_on_AIO_Console)
- Run a Full Deploy
- (optional) Upload AppHost backup archive to `/store/apps/backup/`
- (optional) Restore AppHost container data: `/opt/qradar/bin/app-volume-backup.py`
- Start the apps
