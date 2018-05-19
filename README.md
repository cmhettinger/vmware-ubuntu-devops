# Creating an Ubuntu Devops Server

To create a new Ubuntu Devops Server, follow the steps below.

### PROVISION THE VM

Using VMWare Fusion, create a new virtual machine using a downloaded ISO image
of the latest Ubuntu Server distro.

### RUN ON FIRST LOGIN

* UPDATE SERVER
~~~
sudo apt-get -y update
sudo apt-get -y upgrade
sudo systemctl restart console-setup.service
reboot
~~~

* SETUP SSH DIRECTORY
~~~
sudo su root
mkdir -p ~/.ssh
ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts
echo "Host github.com" > ~/.ssh/config
echo "IdentityFile ~/.ssh/git" >> ~/.ssh/config
~~~

* COPY SSH CREDS

Copy files for GitHub into ~/.ssh
~~~
git
git.pub
~~~

~~~
sudo su root
chmod 600 ~/.ssh/*
~~~

* BOOTSTRAP VM
~~~
sudo su root
mkdir -p /data/1
git clone git@github.com:cmhettinger/vmware-ubuntu-devops.git /data/1/bin
/data/1/bin/bootstrap-vm.sh
~~~

### CLIENT CONFIGURATION

* ADD BROWSER SHORTCUTS

devops-nexus:
~~~
http://w.x.y.z:8081/
~~~

* ADD LOCATION TO GRADLE.PROPERTIES

~~~
nexus_user=myuser
nexus_password=mypassword
nexus_url=http://w.x.y.z:8081/
~~~
