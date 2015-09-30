#!/bin/sh

### Load environment function
PreRequisites()
{
if [ ! -f ./env.properties ] ; then
 echo ./env.properties file missing, exiting ..
 exit 1
else
 source ./env.properties
fi
}


PreRequisites

# Configure daily export on first server
$INSTALL_DIR/bin/export-ldif --ldifFile "$INSTALL_DIR/ldif/export.ldif" --backendID $BACKEND_ID --hostName $LDAP_HOST --port $LDAP_ADMIN_PORT --bindDN "$DIR_MANAGER" \
 --bindPasswordFile $BIND_PASSWORD_FILE --trustAll --recurringTask "0 1 * * *"

# Configure daily export on second server
$INSTALL_DIR/bin/export-ldif --ldifFile "$INSTALL_DIR/ldif/export.ldif" --backendID $BACKEND_ID --hostName $LDAP_HOST_2 --port $LDAP_ADMIN_PORT --bindDN "$DIR_MANAGER" \
 --bindPasswordFile $BIND_PASSWORD_FILE --trustAll --recurringTask "0 1 * * *"
