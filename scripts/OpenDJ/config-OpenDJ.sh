#!/bin/sh

### Check prerequisites function
PreRequisites()
{
if [ -r ./env.properties ] ; then
 source ./env.properties
else echo "./env.properties file missing or unreadable, exiting .."
     exit 1
fi

$OPENDJ_JAVA_HOME/bin/java -version 2>/dev/null
if [ $? -ne "0" ] ; then
        echo "Java is not installed or installation/environment incomplete, exiting .."
        exit 2
fi

if [ -z "$BASE_DN" -o -z "$BIND_PASSWORD_FILE" -o -z "$BIND_PASSWORD_FILE" -o -z "$IMPORT_FILE" -o -z "$INSTALL_DIR" -o -z "$OPENDJ_JAVA_HOME" \
     -o -z "$LDAP_ADMIN_PORT" -o -z "$LDAP_HOST" -o -z "$LDAP_LOG_DIR" -o -z "$LDAP_PORT" -o -z "$OPENDJ_JAVA_OPTS" ] ; then
        echo "At least one of the environment variable below is missing, exiting .."
        echo "BASE_DN: $BASE_DN"
        echo "BIND_PASSWORD_FILE: $BIND_PASSWORD_FILE"
        echo "IMPORT_FILE: $IMPORT_FILE"
        echo "INSTALL_DIR: $INSTALL_DIR"
        echo "OPENDJ_JAVA_HOME: $OPENDJ_JAVA_HOME"
        echo "LDAP_ADMIN_PORT:$LDAP_ADMIN_PORT"
        echo "LDAP_HOST: $LDAP_HOST"
        echo "LDAP_LOG_DIR: $LDAP_LOG_DIR"
        echo "LDAP_PORT: $LDAP_PORT"
        echo "OPENDJ_JAVA_OPTS: $OPENDJ_JAVA_OPTS"
        exit 3
fi
}


### OpenDJ configuration function
Config_OpenDJ()
{
#Generate OpenDJ configuration file (that is dsconfig batch file)
./generate-OpenDJ-config.sh

#Load dsconfig batch file
sudo su opendj -c "$INSTALL_DIR/bin/dsconfig --bindPasswordFile $BIND_PASSWORD_FILE --trustAll --no-prompt --batchFilePath ./config-OpenDJ.cfg --script-friendly"

#Create indexes (unuseful if no data's been loaded)
#sudo su - opendj -c "cd $INSTALL_DIR/bin ; ./rebuild-index --bindPasswordFile $BIND_PASSWORD_FILE --trustAll --rebuildAll --baseDN $BASE_DN ; ./verify-index --baseDN $BASE_DN"
}


################# Main program #########################

PreRequisites;
Config_OpenDJ;
