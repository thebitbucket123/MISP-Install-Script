#1/ Minimal Ubuntu install
#-------------------------

# Install a minimal Ubuntu 16.04-server system with the software:
# - OpenSSH server
sudo apt-get -y install openssh-server

# Make sure your system is up2date:
sudo apt-get update
sudo apt-get -y upgrade

# install postfix, there will be some questions.
sudo apt-get -y install postfix
# Postfix Configuration: Satellite system
# change the relay server later with:
#sudo postconf -e 'relayhost = example.com'
#sudo postfix reload
read -rsp $'Press any key to continue...\n' -n1 key