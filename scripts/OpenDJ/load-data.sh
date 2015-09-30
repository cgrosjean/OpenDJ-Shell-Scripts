#!/bin/sh
if [ ! -f ./env.properties ] ; then
 echo ./env.properties file missing, exiting ..
 exit 1
else
 source ./env.properties
fi

#chgrp opendj $IMPORT_FILE ../../data/ldif/monitoring.ldif

#unset DIR_MANAGER DIR_MANAGER_PASSWORD LDAP_PORT LDAP_ADMIN_PORT LDAP_HOST BIND_PASSWORD_FILE

# Import main LDIF file
env
$INSTALL_DIR/bin/import-ldif --backendID $BACKEND_ID --clearBackend --ldifFile $IMPORT_FILE --skipFile $SKIPPED_FILE --rejectFile $REJECTED_FILE \
 --overwrite --skipSchemaValidation --skipDNValidation --tmpdirectory $TMPFS_DIR --noPropertiesFile

service opendj start

# Import additional file
$INSTALL_DIR/bin/ldapmodify --defaultAdd --fileName ../../data/ldif/monitoring.ldif --bindPasswordFile $BIND_PASSWORD_FILE
