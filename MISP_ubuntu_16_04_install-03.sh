#Add www-data user to admin user's group and vice versa
username=$(whoami)
sudo usermod -a -G $username www-data
sudo usermod -a -G www-data $username
read -rsp $'Press any key to continue...\n' -n1 key
#3/ MISP code
#------------
# Download MISP using git in the /var/www/ directory.
sudo mkdir /var/www/MISP
sudo chown www-data:www-data /var/www/MISP
cd /var/www/MISP
sudo -u www-data git clone https://github.com/MISP/MISP.git /var/www/MISP
sudo -u www-data git checkout tags/$(git describe --tags `git rev-list --tags --max-count=1`)
# if the last shortcut doesn't work, specify the latest version manually
# example: git checkout tags/v2.4.XY
# the message regarding a "detached HEAD state" is expected behaviour
# (you only have to create a new branch, if you want to change stuff and do a pull request for example)

# Make git ignore filesystem permission differences
sudo -u www-data git config core.filemode false

# install Mitre's STIX and its dependencies by running the following commands:
sudo apt-get -y install python3-dev python3-pip libxml2-dev libxslt1-dev zlib1g-dev python-setuptools
cd /var/www/MISP/app/files/scripts
sudo -u www-data git clone https://github.com/CybOXProject/python-cybox.git
sudo -u www-data git clone https://github.com/STIXProject/python-stix.git
cd /var/www/MISP/app/files/scripts/python-cybox
sudo python3 setup.py install
cd /var/www/MISP/app/files/scripts/python-stix
sudo python3 setup.py install

# install mixbox to accomodate the new STIX dependencies:
cd /var/www/MISP/app/files/scripts/
sudo -u www-data git clone https://github.com/CybOXProject/mixbox.git
cd /var/www/MISP/app/files/scripts/mixbox
sudo python3 setup.py install

# install PyMISP
cd /var/www/MISP/PyMISP
sudo python3 setup.py install

# install support for STIX 2.0
sudo pip3 install stix2
read -rsp $'Press any key to continue...\n' -n1 key