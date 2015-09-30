#!/bin/sh

### OpenDJ stop function
Stop_OpenDJ()
{
status=$(LANG=C && $INSTALL_DIR/bin/status --bindPasswordFile $BIND_PASSWORD_FILE | grep "Server Run Status:" | awk -F: '{print $2}' | sed -e "s/ //g")
if [ $status != "Stopped" ] ; then
 echo
 echo "Waiting for OpenDJ services to stop ..."
 sudo /sbin/service opendj stop
 echo

 while [ `LANG=C && $INSTALL_DIR/bin/status --bindPasswordFile $BIND_PASSWORD_FILE 2>/dev/null | grep "Server Run Status:" | awk -F: '{print $2}' | sed -e "s/ //g"` != "Stopped" ]
  do
   sudo /sbin/service opendj stop 2>/dev/null
   echo -n .
  done

fi

if [ -f $LDAP_LOG_DIR/errors ] ; then
 tail -1 $LDAP_LOG_DIR/errors
elif [ -f $INSTALL_DIR/logs/errors ] ; then
 tail -1 $INSTALL_DIR/logs/errors
fi
echo
}

### OpenDJ start function
Start_OpenDJ()
{
echo
echo "Waiting for OpenDJ services to start ..."
echo
sudo /sbin/service opendj start 2>/dev/null

while [ `LANG=C && $INSTALL_DIR/bin/status --bindPasswordFile $BIND_PASSWORD_FILE | grep "Server Run Status:" | awk -F: '{print $2}' | sed -e "s/ //g"` != "Started" ]
do
 sudo /sbin/service opendj start 2>/dev/null
 echo -n .
done

if [ -f $LDAP_LOG_DIR/errors ] ; then
 tail -1 $LDAP_LOG_DIR/errors
elif [ -f $INSTALL_DIR/logs/errors ] ; then
 tail -1 $INSTALL_DIR/logs/errors
fi
echo
}


### OpenDJ restart function
Restart_OpenDJ()
{
Stop_OpenDJ
Start_OpenDJ
}


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


### Create replication topology function
CreateTopology()
{
sudo su - opendj -c "$INSTALL_DIR/bin/dsreplication enable \
          --host1 $LDAP_HOST \
          --port1 $LDAP_ADMIN_PORT \
          --bindDN1 \"$DIR_MANAGER\" \
          --bindPassword1 $DIR_MANAGER_PASSWORD \
          --host2 $LDAP_HOST_2 \
          --port2 $LDAP_ADMIN_PORT \
          --bindDN2 \"$DIR_MANAGER\" \
          --bindPassword2 $DIR_MANAGER_PASSWORD \
          --replicationPort1 $REPLICATION_PORT \
          --replicationPort2 $REPLICATION_PORT \
          --baseDN $BASE_DN \
          --adminUID $REPLIC_MANAGER \
          --adminPassword $REPLIC_MANAGER_PASSWORD \
          --trustAll \
          --no-prompt"
}


### Disable the external changelog on each LDAP server function
DisableExternalChangelog()
{
sudo su - opendj -c "$INSTALL_DIR/bin/dsconfig \
 set-external-changelog-domain-prop \
 --provider-name \"Multimaster Synchronization\" \
 --domain-name $BASE_DN \
 --set enabled:false \
 --bindPasswordFile $BIND_PASSWORD_FILE \
 --trustAll \
 --no-prompt"

sudo su - opendj -c "$INSTALL_DIR/bin/dsconfig \
 set-external-changelog-domain-prop \
 --provider-name \"Multimaster Synchronization\" \
 --domain-name $BASE_DN \
 --set enabled:false \
 --bindPasswordFile $BIND_PASSWORD_FILE \
 --hostname $LDAP_HOST_2 \
 --trustAll \
 --no-prompt"
}


### Set assured replication on each server
SetAssuredReplication()
{
sudo su - opendj -c "$INSTALL_DIR/bin/dsconfig \
 set-replication-domain-prop \
 --provider-name \"Multimaster Synchronization\" \
 --domain-name $BASE_DN \
 --set assured-type:safe-read \
 --bindPasswordFile $BIND_PASSWORD_FILE \
 --trustAll \
 --no-prompt"

sudo su - opendj -c "$INSTALL_DIR/bin/dsconfig \
 set-replication-domain-prop \
 --provider-name \"Multimaster Synchronization\" \
 --domain-name $BASE_DN \
 --set assured-type:safe-read \
 --bindPasswordFile $BIND_PASSWORD_FILE \
 --hostname $LDAP_HOST_2 \
 --trustAll \
 --no-prompt"
}


### Initialize servers function
Initialize_Servers()
{
sudo su - opendj -c "$INSTALL_DIR/bin/dsreplication initialize-all \
          --hostname $LDAP_HOST \
          --port $LDAP_ADMIN_PORT \
          --baseDN $BASE_DN \
          --adminUID $REPLIC_MANAGER \
          --adminPassword $REPLIC_MANAGER_PASSWORD \
          --trustAll \
          --no-prompt"
}


#### Main Program ####
PreRequisites
CreateTopology
DisableExternalChangelog
SetAssuredReplication
Initialize_Servers
Restart_OpenDJ
