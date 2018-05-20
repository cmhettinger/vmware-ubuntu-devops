#!/bin/bash

cd ~

# CONFIG GIT CLIENT
git config --global user.email "cmhettinger@hotmail.com"
git config --global user.name "cmhettinger"

# CONFIG STARTUP/SHUTDOWN SCRIPTS

cp /data/1/bin/devops.service /etc/systemd/system/devops.service
systemctl enable devops

# MAKE DIRECTORIES

mkdir -p /data/1/apps
mkdir -p /data/1/tmp
chmod 1777 /data/1/tmp

# MISC INSTALLS

apt-get -y install dos2unix
apt-get -y install unix2dos
apt-get -y install tree
apt-get -y install jq

# INSTALL JAVA8 / JCE

add-apt-repository -y ppa:webupd8team/java
apt-get -y update
# https://askubuntu.com/questions/190582/installing-java-automatically-with-silent-option
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
apt-get -y install oracle-java8-installer
apt -y install oracle-java8-unlimited-jce-policy
apt -y install oracle-java8-set-default
java -version
JAVA_HOME=/usr/lib/jvm/java-8-oracle; export JAVA_HOME
$JAVA_HOME/bin/jrunscript -e 'print (javax.crypto.Cipher.getMaxAllowedKeyLength("AES") >= 256);'

# INSTALL NEXUS

/bin/sh -c 'echo "*      soft nofile 65536" >> /etc/security/limits.conf'
/bin/sh -c 'echo "*      hard nofile 65536" >> /etc/security/limits.conf'
/bin/sh -c 'echo "root   soft nofile 65536" >> /etc/security/limits.conf'
/bin/sh -c 'echo "root   hard nofile 65536" >> /etc/security/limits.conf'
/bin/sh -c 'echo "nexus  soft nofile 65536" >> /etc/security/limits.conf'
/bin/sh -c 'echo "nexus  hard nofile 65536" >> /etc/security/limits.conf'
/bin/sh -c 'echo "session required pam_limits.so" >> /etc/pam.d/common-session'
/bin/sh -c 'echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive'

wget --directory-prefix /data/1/tmp/ https://download.sonatype.com/nexus/3/latest-unix.tar.gz
tar zxvf /data/1/tmp/latest-unix.tar.gz -C /data/1/apps
NEXUSDIR=`ls /data/1/apps | grep nexus`; export NEXUSDIR
ln -s /data/1/apps/`ls /data/1/apps | grep nexus` /data/1/apps/nexus
echo 'run_as_user="nexus"' > /data/1/apps/nexus/bin/nexus.rc

NEXUSPASS=`uuidgen -t`; sudo useradd -p `openssl passwd -1 $NEXUSPASS` nexus
chown -R nexus:nexus /data/1/apps/$NEXUSDIR/
chown -h nexus:nexus /data/1/apps/nexus
chown -R nexus:nexus /data/1/apps/sonatype-work

ln -s /data/1/apps/nexus/bin/nexus /etc/init.d/nexus
update-rc.d nexus defaults
service nexus start

# INSTALL NODEJS V8
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
apt-get install -y nodejs
nodejs -v
npm -v

# INSTALL GRADLE
wget --directory-prefix /data/1/tmp/ https://services.gradle.org/distributions/gradle-4.7-bin.zip
unzip -d /data/1/apps/ /data/1/tmp/gradle-4.7-bin.zip
ln -s /data/1/apps/gradle-4.7 /data/1/apps/gradle
mkdir -p /data/1/apps/gradle-user-home
cat >> /data/1/apps/gradle-user-home/gradle.properties << EOF
org.gradle.daemon=true
org.gradle.parallel=true
my_nexus_user=myuser
my_nexus_password=mypassword
EOF

# INSTALL MYSQL

apt-get -y install mysql-server-5.7

# INSTALL AWS CLI

apt-get -y install python-pip
pip install awscli
aws --version

mkdir -p ~/.aws

cat >> ~/.aws/config << EOF
[default]
output = json
region = local
EOF

cat >> ~/.aws/credentials << EOF
[default]
aws_access_key_id = EXAMPLEID
aws_secret_access_key = EXAMPLEKEY
EOF

# INSTALL DYNAMODB LOCAL

wget --directory-prefix /data/1/tmp/ https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz
mkdir -p /data/1/apps/dynamodblocal
tar zxvf /data/1/tmp/dynamodb_local_latest.tar.gz -C /data/1/apps/dynamodblocal

# INSTALL TOMCAT

wget --directory-prefix /data/1/tmp/ http://mirror.cc.columbia.edu/pub/software/apache/tomcat/tomcat-8/v8.5.31/bin/apache-tomcat-8.5.31.tar.gz
tar zxvf /data/1/tmp/apache-tomcat-8.5.31.tar.gz -C /data/1/apps
ln -s /data/1/apps/apache-tomcat-8.5.31 /data/1/apps/apache-tomcat
echo '# FIX ENCODED SLASH' >> /data/1/apps/apache-tomcat/conf/catalina.properties
echo 'org.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true' >> /data/1/apps/apache-tomcat/conf/catalina.properties
sed -i '$ d' /data/1/apps/apache-tomcat/conf/context.xml
echo '<Resources cachingAllowed="true" cacheMaxSize="100000" />' >> /data/1/apps/apache-tomcat/conf/context.xml
echo '</Context>' >> /data/1/apps/apache-tomcat/conf/context.xml

# INSTALL JENKINS

wget --directory-prefix /data/1/apps/apache-tomcat/webapps/ http://mirrors.jenkins.io/war-stable/latest/jenkins.war

# INSTALL RUNDECK

RUNDECK_PASSWORD=admin; export RUNDECK_PASSWORD

wget --directory-prefix /data/1/tmp/ http://download.rundeck.org/war/rundeck-2.11.3.war
unzip /data/1/tmp/rundeck-2.11.3.war -d /data/1/apps/apache-tomcat/webapps/rundeck
echo '' >> /data/1/apps/apache-tomcat/webapps/rundeck/WEB-INF/classes/log4j.properties

sed -i '$ d' /data/1/apps/apache-tomcat/conf/tomcat-users.xml
echo '<!-- RUNDECK -->' >> /data/1/apps/apache-tomcat/conf/tomcat-users.xml
echo '<role rolename="admin"/>' >> /data/1/apps/apache-tomcat/conf/tomcat-users.xml
echo '<role rolename="user"/>' >> /data/1/apps/apache-tomcat/conf/tomcat-users.xml
echo '<user username="admin" password="'"$RUNDECK_PASSWORD"'" roles="admin,user"/>' >> /data/1/apps/apache-tomcat/conf/tomcat-users.xml
echo '</tomcat-users>' >> /data/1/apps/apache-tomcat/conf/tomcat-users.xml

LOCALIP=`hostname --ip-address`; export LOCALIP

mkdir -p /data/1/apps/rundeck-base
cat >> /data/1/apps/rundeck-base/rundeck-config.properties << EOF
grails.serverURL=http://$LOCALIP:8080/rundeck
dataSource.dbCreate = update
dataSource.url = jdbc:h2:file:/data/1/apps/rundeck-base/server/data/grailsdb
rundeck.v14.rdbsupport=false
# ALLOW UNLIMITED DURATION RUNDECK API TOKENS
rundeck.api.tokens.duration.max=0
EOF

# CYCLE TOMCAT TO ALLOW BASE TOOL DIRECTORIES TO BE CREATED

/data/1/bin/tomcat-up
sleep 120
/data/1/bin/tomcat-down
/data/1/bin/tomcat-kill

# INSERT RUNDECK CONFIGURATION AFTER FIRST STARTUP/SHUTDOWN

mkdir -p /data/1/apps/rundeck-base/etc
cat >> /data/1/apps/rundeck-base/etc/framework.properties << EOF
# OVERRIDE TEMP DIRECTORY FOR RUNDECK SCRIPTS
framework.file-copy-destination-dir = /data/1/tmp/
EOF

# CREATE RUNDECK PROJECT

# MAKE RUNDECK PROJECT DIRECTORY

mkdir -p /data/1/apps/rundeck-base/projects/ubuntu-rundeck/etc
mkdir -p /data/1/apps/rundeck-base/projects/ubuntu-rundeck/acls
mkdir -p /data/1/apps/rundeck-base/projects/ubuntu-rundeck/scm

cat >> /data/1/apps/rundeck-base/projects/ubuntu-rundeck/etc/project.properties << EOF
project.jobs.gui.groupExpandLevel=1
resources.source.1.config.generateFileAutomatically=true
project.ssh-authentication=privateKey
service.FileCopier.default.provider=jsch-scp
project.nodeCache.delay=30
project.nodeCache.enabled=true
project.disable.executions=false
project.ssh-command-timeout=0
project.ssh-keypath=/home/chris/.ssh/git
resources.source.1.config.writeable=false
resources.source.1.config.includeServerNode=true
service.NodeExecutor.default.provider=jsch-ssh
resources.source.1.config.requireFileExists=false
project.name=ubuntu-rundeck
project.disable.schedule=false
project.ssh-connect-timeout=0
resources.source.1.type=file
resources.source.1.config.file=/data/1/apps/rundeck-base/projects/ubuntu-rundeck/etc/resources.xml
EOF

OSVERSION=`uname -r`
cat >> /data/1/apps/rundeck-base/projects/ubuntu-rundeck/etc/resources.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <node name="localhost" description="Rundeck server node" tags="" hostname="localhost" osArch="amd64" osFamily="unix" osName="Linux" osVersion="$OSVERSION" username="chris"/>
</project>
EOF

cat >> /data/1/apps/rundeck-base/projects/ubuntu-rundeck/etc/scm-import.properties << EOF
#stored config
#Fri Feb 23 15:57:40 EST 2018
scm.import.config.useFilePattern=true
scm.import.config.strictHostKeyChecking=yes
scm.import.config.fetchAutomatically=true
scm.import.enabled=true
scm.import.config.importUuidBehavior=preserve
scm.import.config.gitPasswordPath=
scm.import.config._useFilePattern=
scm.import.config.filePattern=.*\\.yaml
scm.import.config.url=git@github.com\:cmhettinger/ubuntu-rundeck.git
scm.import.roles.1=user
scm.import.type=git-import
scm.import.roles.0=admin
scm.import.username=admin
scm.import.config.format=yaml
scm.import.roles.count=2
scm.import.config.dir=/data/1/apps/rundeck-base/projects/ubuntu-rundeck/scm
scm.import.config.pathTemplate=\${job.group}\${job.name}-\${job.id}.\${config.format}
scm.import.trackedItems.count=0
scm.import.config.sshPrivateKeyPath=
scm.import.config.branch=master
EOF

cat >> /data/1/apps/rundeck-base/projects/ubuntu-rundeck/etc/scm-export.properties << EOF
#stored config
#Fri Feb 23 15:57:10 EST 2018
scm.export.config.format=yaml
scm.export.config.committerEmail=cmhettinger@hotmail.com
scm.export.config.dir=/data/1/apps/rundeck-base/projects/ubuntu-rundeck/scm
scm.export.config.branch=master
scm.export.config.strictHostKeyChecking=yes
scm.export.config.sshPrivateKeyPath=
scm.export.config.committerName=cmhettinger
scm.export.roles.count=2
scm.export.config.fetchAutomatically=true
scm.export.config.pathTemplate=\${job.group}\${job.name}-\${job.id}.\${config.format}
scm.export.enabled=true
scm.export.type=git-export
scm.export.config.gitPasswordPath=
scm.export.config.url=git@github.com\:cmhettinger/ubuntu-rundeck.git
scm.export.username=admin
scm.export.roles.1=user
scm.export.config.exportUuidBehavior=preserve
scm.export.roles.0=admin
EOF


# UPDATE BASHRC

cat >> ~/.bashrc << EOF
# ---- LOCAL VM SETTINGS ----
JAVA_HOME=/usr/lib/jvm/java-8-oracle; export JAVA_HOME
JAVA_TOOL_OPTIONS=-Xss1280k; export JAVA_TOOL_OPTIONS
PATH=\$PATH:\$JAVA_HOME/bin; export PATH
export PS1="\u@\W $ "
EOF

# ALL DONE

/etc/update-motd.d/50-landscape-sysinfo
echo "done.  reboot now..."
