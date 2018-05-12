#!/bin/bash

# MAKE DIRECTORIES

sudo mkdir -p /data/1
sudo chown `whoami`:`whoami` /data/1
mkdir -p /data/1/apps
mkdir -p /data/1/certs
mkdir -p /data/1/tmp; chmod 1777 /data/1/tmp

# INSTALL JAVA8 / JCE
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get -y install oracle-java8-installer
sudo apt -y install oracle-java8-unlimited-jce-policy
sudo apt install oracle-java8-set-default
java -version
JAVA_HOME=/usr/lib/jvm/java-8-oracle; export JAVA_HOME
$JAVA_HOME/bin/jrunscript -e 'print (javax.crypto.Cipher.getMaxAllowedKeyLength("RC5") >= 256);'

# INSTALL NEXUS

sudo /bin/sh -c 'echo "*      soft nofile 65536" >> /etc/security/limits.conf'
sudo /bin/sh -c 'echo "*      hard nofile 65536" >> /etc/security/limits.conf'
sudo /bin/sh -c 'echo "root   soft nofile 65536" >> /etc/security/limits.conf'
sudo /bin/sh -c 'echo "root   hard nofile 65536" >> /etc/security/limits.conf'
sudo /bin/sh -c 'echo "nexus  soft nofile 65536" >> /etc/security/limits.conf'
sudo /bin/sh -c 'echo "nexus  hard nofile 65536" >> /etc/security/limits.conf'
sudo /bin/sh -c 'echo "session required pam_limits.so" >> /etc/pam.d/common-session'
sudo /bin/sh -c 'echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive'

wget --directory-prefix /data/1/tmp/ https://download.sonatype.com/nexus/3/latest-unix.tar.gz
tar zxvf /data/1/tmp/latest-unix.tar.gz -C /data/1/apps
NEXUSDIR=`ls /data/1/apps | grep nexus`; export NEXUSDIR
ln -s /data/1/apps/`ls /data/1/apps | grep nexus` /data/1/apps/nexus
echo 'run_as_user="nexus"' > /data/1/apps/nexus/bin/nexus.rc

NEXUSPASS=`uuidgen -t`; sudo useradd -p `openssl passwd -1 $NEXUSPASS` nexus
sudo chown -R nexus:nexus /data/1/apps/$NEXUSDIR/
sudo chown -h nexus:nexus /data/1/apps/nexus
sudo chown -R nexus:nexus /data/1/apps/sonatype-work

sudo ln -s /data/1/apps/nexus/bin/nexus /etc/init.d/nexus
sudo update-rc.d nexus defaults
sudo service nexus start

# UPDATE BASHRC

cat >> ~/.bashrc << EOF
# ---- LOCAL VM SETTINGS ----
JAVA_HOME=/usr/lib/jvm/java-8-oracle; export JAVA_HOME
JAVA_TOOL_OPTIONS=-Xss1280k; export JAVA_TOOL_OPTIONS
PATH=\$PATH:\$JAVA_HOME/bin; export PATH
export PS1="\u@\W $ "
EOF
