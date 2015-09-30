#!/bin/sh
if [ ! -f ./env.properties ] ;
 then
 echo ./env.properties file missing, exiting ..
 exit 1
else
 source ./env.properties
fi

echo "
# Set log file names and directories
set-log-publisher-prop --publisher-name \"File-Based Access Logger\" --set log-file:$LDAP_LOG_DIR/access
set-log-publisher-prop --publisher-name \"File-Based Audit Logger\" --set log-file:$LDAP_LOG_DIR/audit
set-log-publisher-prop --publisher-name \"File-Based Error Logger\" --set log-file:$LDAP_LOG_DIR/errors
set-log-publisher-prop --publisher-name \"File-Based Debug Logger\" --set log-file:$LDAP_LOG_DIR/debug
set-log-publisher-prop --publisher-name \"Replication Repair Logger\" --set log-file:$LDAP_LOG_DIR/replication

# Set access log files rotation and retention policies
create-log-retention-policy --set number-of-files:186 --type file-count --policy-name \"Customer File Count Retention Policy\"
set-log-publisher-prop --publisher-name \"File-Based Access Logger\" --set retention-policy:\"Customer File Count Retention Policy\"
set-log-publisher-prop --publisher-name \"File-Based Access Logger\" --remove rotation-policy:\"Size Limit Rotation Policy\"

# Set error log files rotation and retention policies
set-log-publisher-prop --publisher-name \"File-Based Error Logger\" --set retention-policy:\"Customer File Count Retention Policy\"
set-log-publisher-prop --publisher-name \"File-Based Error Logger\" --remove rotation-policy:\"Size Limit Rotation Policy\"

# Set audit log files rotation and retention policies
set-log-publisher-prop --publisher-name \"File-Based Audit Logger\" --set enabled:true
set-log-publisher-prop --publisher-name \"File-Based Error Logger\" --set retention-policy:\"Customer File Count Retention Policy\"

# Create a log for administrative operations
create-log-publisher --publisher-name \"File-Based Admin Logger\" --type file-based-access --set log-file:$LDAP_LOG_DIR/admin --set enabled:true \
 --set filtering-policy:inclusive --set rotation-policy:\"7 Days Time Limit Rotation Policy\" \
 --set retention-policy:\"Customer File Count Retention Policy\" 

# Create a log to filter out load balancer health check requests
create-log-publisher --publisher-name \"File-Based Health Check Logger\" --type file-based-access --set log-file:$LDAP_LOG_DIR/health-check --set enabled:true \
 --set filtering-policy:inclusive --set rotation-policy:\"7 Days Time Limit Rotation Policy\" \
 --set retention-policy:\"Customer File Count Retention Policy\" 

# Create filters to apply on the log files
create-access-log-filtering-criteria --publisher-name \"File-Based Access Logger\" --criteria-name \"Admin. Operations\" --set connection-port-equal-to:$LDAP_ADMIN_PORT
create-access-log-filtering-criteria --publisher-name \"File-Based Access Logger\" --criteria-name \"Health check operations\" --set user-dn-equal-to:\"uid=F5-monitoring,ou=comptes techniques,$BASE_DN\"
create-access-log-filtering-criteria --publisher-name \"File-Based Admin Logger\" --criteria-name \"Admin. Operations\" --set connection-port-equal-to:$LDAP_ADMIN_PORT
create-access-log-filtering-criteria --publisher-name \"File-Based Health Check Logger\" --criteria-name \"Health check operations\" --set user-dn-equal-to:\"uid=F5-monitoring,ou=comptes techniques,$BASE_DN\"

# Set filtering policies
set-log-publisher-prop --publisher-name \"File-Based Access Logger\" --set filtering-policy:exclusive
set-log-publisher-prop --publisher-name \"File-Based Admin Logger\" --set filtering-policy:inclusive
set-log-publisher-prop --publisher-name \"File-Based Health Check Logger\" --set filtering-policy:inclusive

# Set default size limit (maximum number of entries to return from a search)
set-global-configuration-prop --set size-limit:5000

# Set uid uniqueness plugin configuration
set-plugin-prop --plugin-name \"UID Unique Attribute\" --set base-dn:\"ou=people,$BASE_DN\" --set enabled:false

# Set directory server database location
set-backend-prop --backend-name userRoot --set db-directory:$LDAP_DB_DIR

# Index creation
set-local-db-index-prop --backend-name userRoot --index-name cn --set index-type:presence --set index-type:equality
set-local-db-index-prop --backend-name userRoot --index-name givenName --set index-type:presence --set index-type:equality
set-local-db-index-prop --backend-name userRoot --index-name mail --set index-type:presence --set index-type:equality
set-local-db-index-prop --backend-name userRoot --index-name sn --set index-type:presence --set index-type:equality
#create-local-db-index --backend-name userRoot --index-name uid  --set index-type:equality

# Set default password policy configuration
set-password-policy-prop --policy-name \"Default Password Policy\" --set allow-pre-encoded-passwords:true --no-prompt

# Enable JMX access for the directory manager
set-root-dn-prop --add default-root-privilege-name:jmx-notify --add default-root-privilege-name:jmx-read --add default-root-privilege-name:jmx-write  

# Enable SNMP
set-connection-handler-prop --handler-name \"SNMP Connection Handler\" --set enabled:true --set opendmk-jarfile:$INSTALL_DIR/openDMK/lib/jdmkrt.jar \
 --set listen-port:$SNMP_LISTEN_PORT --set trap-port:$SNMP_TRAP_PORT

" >./config-OpenDJ.cfg
