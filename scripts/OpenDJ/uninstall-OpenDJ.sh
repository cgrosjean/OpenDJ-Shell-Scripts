#!/bin/sh

### Check prerequisites function
PreRequisites()
{
if [ ! -f ./env.properties ] ;
 then
 echo ./env.properties file missing, exiting ..
 exit 1
else
 source ./env.properties
fi

$OPENDJ_JAVA_HOME/bin/java -version 2>/dev/null
if [ $? -ne "0" ] ; then
        echo "Java is not installed or installation/environment incomplete, exiting .."
        exit -1
fi

if [ -z "$BASE_DN" -o -z "$BIND_PASSWORD_FILE" -o -z "$DIR_MANAGER_PASSWORD" -o -z "$IMPORT_FILE" -o -z "$INSTALL_DIR" \
     -o -z "$OPENDJ_JAVA_HOME" -o -z "$LDAP_ADMIN_PORT" -o -z "$LDAP_HOST" -o -z "$LDAP_LOG_DIR" -o -z "$LDAP_PORT" \
     -o -z "$OPENDJ_JAVA_OPTS" -o -z "$OPENDJ_ZIP" -o -z "$OPENDMK_ZIP" ] ; then
  echo "At least one of the environment variable below is missing, exiting .."
  echo "BASE_DN: $BASE_DN"
  echo "BIND_PASSWORD_FILE: $BIND_PASSWORD_FILE"
  echo "DIR_MANAGER_PASSWORD: $DIR_MANAGER_PASSWORD"
  echo "IMPORT_FILE: $IMPORT_FILE"
  echo "INSTALL_DIR: $INSTALL_DIR"
  echo "OPENDJ_JAVA_HOME: $OPENDJ_JAVA_HOME"
  echo "LDAP_ADMIN_PORT: $LDAP_ADMIN_PORT"
  echo "LDAP_HOST: $LDAP_HOST"
  echo "LDAP_LOG_DIR: $LDAP_LOG_DIR"
  echo "LDAP_PORT: $LDAP_PORT"
  echo "OPENDJ_JAVA_OPTS: $OPENDJ_JAVA_OPTS"
  echo "OPENDJ_ZIP: $OPENDJ_ZIP"
  echo "OPENDMK_ZIP: $OPENDMK_ZIP"
  exit 5
fi


}


### OpenDJ stop function
Stop_OpenDJ()
{
status=$(LANG=C && $INSTALL_DIR/bin/status --bindPasswordFile $BIND_PASSWORD_FILE | grep "Server Run Status:" | awk -F: '{print $2}' | sed -e "s/ //g")
if [ ! -z $status ] ; then
 if [ $status != "Stopped" ] ; then
  echo
  echo "Waiting for OpenDJ services to stop ..."
  sudo /sbin/service opendj stop
  echo

  while [ `LANG=C && $INSTALL_DIR/bin/status --bindPasswordFile $BIND_PASSWORD_FILE | grep "Server Run Status:" | awk -F: '{print $2}' | sed -e "s/ //g"` != "Stopped" ]
   do
    sudo /sbin/service opendj stop 2>/dev/null
    echo -n .
   done
 fi
fi

if [ -f $LDAP_LOG_DIR/errors ] ; then
 tail -1 $LDAP_LOG_DIR/errors
elif [ -f $INSTALL_DIR/logs/errors ] ; then
 tail -1 $INSTALL_DIR/logs/errors
fi
echo
}


### Cleanup any previous OpenDJ installation
CleanUp()
{
if [ -x $INSTALL_DIR/uninstall ] ; then
 echo
 echo Uninstalling OpenDJ ..
 echo
 su - opendj -c "$INSTALL_DIR/uninstall --remove-all --cli --no-prompt --forceOnError --verbose --connectTimeout 1000 --adminUID $REPLIC_MANAGER --bindPassword $REPLIC_MANAGER_PASSWORD --trustAll" 2>/dev/null
 
 # If uninstallation failed, try to stop the OpenDJ server at least
 if [ -x $INSTALL_DIR/bin/stop-ds ] ; then
  Stop_OpenDJ
 fi
fi

sudo /bin/rm -f $REJECTED_FILE
sudo /bin/rm -f $SKIPPED_FILE
sudo /bin/rm -f /tmp/opendj*
sudo /bin/rm -rf $LDAP_LOG_DIR/errors
sudo /bin/rm -rf $LDAP_DB_DIR/$BACKEND_ID
sudo /bin/rm -rf $INSTALL_DIR $INSTALL_DIR
if [ -x /etc/init.d/opendj ] ; then
 sudo /sbin/chkconfig --del opendj
 sudo /bin/rm -rf /etc/init.d/opendj
fi
}


################# Main program ######################
PreRequisites
CleanUp
