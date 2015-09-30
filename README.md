# OpenDJ-Shell-Scripts
A set of scripts to install, configure, load and replicate OpenDJ servers

Prerequisites on each server to install:
- Operation system must be ready and networked (for example, replication port open between the servers if multiple nodes)
- JRE installed
- OpenDJ distribution (zip file) downloaded
- These scripts downloaded

Proposed modus operandi:

On the 1st OpenDJ server:

- Edit the env.properties file for the first server according to your environment
- Review and edit the generate-OpenDJ-config.sh according to your needs
- Run the install-OpenDJ.sh script to install and configure OpenDJ
- Edit the data/ldif/project.template file if needed, to customize the template file used to generate LDIF data
- Run the make-ldif.sh script to generate LDIF data if needed
- Run the load-data.sh script to load an LDIF file into the first OpenDJ server

On the 2nd OpenDJ server:

- Only copy the scripts/OpenDJ files from the 1st server
- Copy the env.properties file from the first server over the one for the second server
- Edit the env.properties file by exchanging LDAP_HOST and LDAP_HOST_2 variable values
- Change the env.properties link to point to the env.properties file for the second server
- Run the init-replic.sh file (be careful to specify the right source and target servers !)

Note: Each OpenDJ installation on a server will erase any previous installation before moving on, and will also
remove any trace of the server to uninstall in the remaining ones
