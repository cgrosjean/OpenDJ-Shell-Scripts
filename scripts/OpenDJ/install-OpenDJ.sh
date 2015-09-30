#!/bin/sh

### Create opendj user and group if needed
Create_User_Group()
{
# Create OpenDJ group
grep --quiet opendj /etc/group
if [ $? -ge 1 ] ; then
 sudo /usr/sbin/groupadd opendj
fi

# Create OpenDJ user
grep --quiet opendj /etc/passwd
if [ $? -ge 1 ] ; then
 sudo /usr/sbin/useradd -Md $INSTALL_DIR -g opendj opendj
fi
}


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

if [ ! -f ./.bash_profile ] ;
 then
 echo ./.bash_profile file missing, exiting ..
 exit 2
fi

if [ ! -f ./.bash_aliases ] ;
 then
 echo ./.bash_aliases file missing, exiting ..
 exit 3
fi

if [ ! -d `dirname $INSTALL_DIR` ] ;
 then
 echo $INSTALL_DIR parent directory doesn\'t exist, exiting ..
 exit 4
fi

Create_User_Group

# Make sure logs directory exists and belongs to opendj
if [ ! -d $LDAP_LOG_DIR ] ;
 then
 mkdir -p $LDAP_LOG_DIR
fi
chown -R opendj:opendj $LDAP_LOG_DIR

# Make sure database directory exists and belongs to opendj
if [ ! -d $LDAP_DB_DIR ] ;
 then
 mkdir -p $LDAP_DB_DIR
fi
chown -R opendj:opendj $LDAP_DB_DIR

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

$OPENDJ_JAVA_HOME/bin/java -version 2>/dev/null
if [ $? -ne 0 ] ; then
  echo "Java is not installed or installation/environment incomplete, exiting .."
  exit 6
fi

if [ ! -f $OPENDJ_ZIP ] ; then
 echo File $OPENDJ_ZIP missing, exiting ...
 exit 7
elif
   [ ! -f $OPENDMK_ZIP ] ; then
 echo File $OPENDMK_ZIP missing, exiting ...
 exit 8
fi
}


### OpenDJ installation function
Install_OpenDJ_Base()
{
echo
echo Installing OpenDJ ..
echo

# Unzip OpenDJ software base
unzip -o -qq -d `dirname $INSTALL_DIR` $OPENDJ_ZIP

# Create link to the desired INSTALL_DIR
#if [ ! -L $INSTALL_DIR ] ; then
# pushd `dirname $INSTALL_DIR` >/dev/null
# ln -s OpenDJ-2.5.0-Xpress1 $INSTALL_DIR
# popd >/dev/null
#fi

# Unzip OpenDMK software
unzip -o -qq -d $INSTALL_DIR $OPENDMK_ZIP

# Unzip patches, if any
#unzip -o -qq -d $INSTALL_DIR /logiciels/depot/softs/OPENDJ-882+988.zip

#Prepare opendj user home directory
cp .bash_profile .bash_aliases env.properties ~opendj
if [ ! -d `dirname $BIND_PASSWORD_FILE` ] ; then
 mkdir -p `dirname $BIND_PASSWORD_FILE`
fi

echo $DIR_MANAGER_PASSWORD >$BIND_PASSWORD_FILE
chmod 400 $BIND_PASSWORD_FILE
chmod 600 ~opendj/.bash_profile ~opendj/.bash_aliases ~opendj/env.properties
chown -R opendj:opendj $INSTALL_DIR `dirname $INSTALL_DIR`/opendj
chown opendj:opendj $BIND_PASSWORD_FILE ~opendj/.bash_profile ~opendj/.bash_aliases ~opendj/env.properties


# Run setup program
sudo su - opendj -c "LANG=C && $INSTALL_DIR/setup \
 	--cli \
        --hostName $LDAP_HOST \
        --ldapPort $LDAP_PORT \
        --adminConnectorPort $LDAP_ADMIN_PORT \
        --jmxPort $JMX_PORT \
        --rootUserDN \"$DIR_MANAGER\" \
        --rootUserPasswordFile $BIND_PASSWORD_FILE \
        --baseDN \"$BASE_DN\" \
	--acceptLicense \
        --no-prompt"

# Create and fix init script
if [ ! -x /etc/init.d/opendj ] ; then
 sudo $INSTALL_DIR/bin/create-rc-script -f /etc/init.d/opendj -u opendj -j $OPENDJ_JAVA_HOME
 sudo /sbin/chkconfig --add opendj
 sudo sed -i "/stop-ds/s~--quiet~--quiet --trustAll --bindPasswordFile $BIND_PASSWORD_FILE~" /etc/init.d/opendj
 sudo chmod 750 /etc/init.d/opendj
fi
}


### Default LDAP tools and commands properties setup function
Edit_Properties()
{
# LDAP tools first
sudo sed -i "s~^# bindDN=.*~bindDN=$DIR_MANAGER~" $INSTALL_DIR/config/tools.properties
sudo sed -i "s~^# port=4444~port=$LDAP_ADMIN_PORT~" $INSTALL_DIR/config/tools.properties
sudo sed -i "s~^# ldapcompare.port=389~ldapcompare.port=$LDAP_PORT~" $INSTALL_DIR/config/tools.properties
sudo sed -i "s~^# ldapdelete.port=389~ldapdelete.port=$LDAP_PORT~" $INSTALL_DIR/config/tools.properties
sudo sed -i "s~^# ldapmodify.port=389~ldapmodify.port=$LDAP_PORT~" $INSTALL_DIR/config/tools.properties
sudo sed -i "s~^# ldappasswordmodify.port=389~ldappasswordmodify.port=$LDAP_PORT~" $INSTALL_DIR/config/tools.properties
sudo sed -i "s~^# ldapsearch.port=389~ldapsearch.port=$LDAP_PORT~" $INSTALL_DIR/config/tools.properties

# Then commands
sudo sed -i "s~^start-ds.java-args=.*$~start-ds.java-args=$OPENDJ_JAVA_OPTS~" $INSTALL_DIR/config/java.properties
sudo sed -i "s~^import-ldif.offline.java-args=-server.*$~import-ldif.offline.java-args=$OPENDJ_JAVA_OPTS~" $INSTALL_DIR/config/java.properties
sudo su - opendj -c "$INSTALL_DIR/bin/dsjavaproperties"
}


### OpenDJ stop function
Stop_OpenDJ()
{
status=$(LANG=C && $INSTALL_DIR/bin/status --bindPasswordFile $BIND_PASSWORD_FILE 2>/dev/null | grep "Server Run Status:" | awk -F: '{print $2}' | sed -e "s/ //g")
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

while [ `LANG=C && $INSTALL_DIR/bin/status --bindPasswordFile $BIND_PASSWORD_FILE 2>/dev/null | grep "Server Run Status:" | awk -F: '{print $2}' | sed -e "s/ //g"` != "Started" ]
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


################# Main program #########################
PreRequisites
./uninstall-OpenDJ.sh
Install_OpenDJ_Base
Edit_Properties
Restart_OpenDJ
./config-OpenDJ.sh
Restart_OpenDJ

exit 0
