#!/bin/bash

sudo su root
cd ~

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

add-apt-repository ppa:webupd8team/java
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

# RETURN FROM SUDO

exit

# UPDATE BASHRC

cat >> ~/.bashrc << EOF
# ---- LOCAL VM SETTINGS ----
JAVA_HOME=/usr/lib/jvm/java-8-oracle; export JAVA_HOME
JAVA_TOOL_OPTIONS=-Xss1280k; export JAVA_TOOL_OPTIONS
PATH=\$PATH:\$JAVA_HOME/bin; export PATH
export PS1="\u@\W $ "
EOF
