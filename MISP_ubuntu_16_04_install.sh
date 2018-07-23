#!/usr/bin/env bash

#INSTALLATION INSTRUCTIONS
#------------------------- for Ubuntu 16.04-server

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
sudo postconf -e 'relayhost = example.com'
sudo postfix reload


#2/ Install LAMP & dependencies
#------------------------------
#Once the system is installed you can perform the following steps:

# Install the dependencies: (some might already be installed)
sudo apt-get -y install curl gcc git gnupg-agent make python python3 openssl redis-server sudo vim zip

# Install MariaDB (a MySQL fork/alternative)
sudo apt-get -y install mariadb-client mariadb-server

# Secure the MariaDB installation (especially by setting a strong root password)
sudo mysql_secure_installation

# Install Apache2
sudo apt-get -y install apache2 apache2-doc apache2-utils

# Enable modules, settings, and default of SSL in Apache
sudo a2dismod status
sudo a2enmod ssl
sudo a2enmod rewrite
sudo a2enmod headers
sudo a2dissite 000-default
sudo a2ensite default-ssl

# Install PHP and dependencies
sudo apt-get -y install libapache2-mod-php php php-cli php-crypt-gpg php-dev php-json php-mysql php-opcache php-readline php-redis php-xml

# Apply all changes
sudo systemctl restart apache2

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

#4/ CakePHP
#-----------
# CakePHP is included as a submodule of MISP, execute the following commands to let git fetch it:
cd /var/www/MISP
sudo -u www-data git submodule init
sudo -u www-data git submodule update
# Make git ignore filesystem permission differences for submodules
sudo -u www-data git submodule foreach git config core.filemode false

# Once done, install CakeResque along with its dependencies if you intend to use the built in background jobs:
cd /var/www/MISP/app
sudo -u www-data php composer.phar require kamisama/cake-resque:4.1.2
sudo -u www-data php composer.phar config vendor-dir Vendor
sudo -u www-data php composer.phar install

# Enable CakeResque with php-redis
sudo phpenmod redis

# To use the scheduler worker for scheduled tasks, do the following:
sudo -u www-data cp -fa /var/www/MISP/INSTALL/setup/config.php /var/www/MISP/app/Plugin/CakeResque/Config/config.php

# If you have multiple MISP instances on the same system, don't forget to have a different Redis per MISP instance for the CakeResque workers
# The default Redis port can be updated in Plugin/CakeResque/Config/config.php

#5/ Set the permissions
#----------------------

# Check if the permissions are set correctly using the following commands:
sudo chown -R www-data:www-data /var/www/MISP
sudo chmod -R 750 /var/www/MISP
sudo chmod -R g+ws /var/www/MISP/app/tmp
sudo chmod -R g+ws /var/www/MISP/app/files
sudo chmod -R g+ws /var/www/MISP/app/files/scripts/tmp


#6/ Create a database and user
#-----------------------------
# Enter the mysql shell
sudo mysql -u root -p

#MariaDB [(none)]> create database misp;
#MariaDB [(none)]> grant usage on *.* to misp@localhost identified by 'XXXXdbpasswordhereXXXXX';
#MariaDB [(none)]> grant all privileges on misp.* to misp@localhost;
#MariaDB [(none)]> flush privileges;
#MariaDB [(none)]> exit

# Import the empty MISP database from MYSQL.sql
sudo -u www-data sh -c "mysql -u misp -p misp < /var/www/MISP/INSTALL/MYSQL.sql"
# enter the password you've set in line 130 when prompted


#7/ Apache configuration
#-----------------------
# Now configure your Apache webserver with the DocumentRoot /var/www/MISP/app/webroot/

# If the apache version is 2.2:
#sudo cp /var/www/MISP/INSTALL/apache.22.misp.ssl /etc/apache2/sites-available/misp-ssl.conf

# If the apache version is 2.4:
sudo cp /var/www/MISP/INSTALL/apache.24.misp.ssl /etc/apache2/sites-available/misp-ssl.conf

# SEE MISP-INSTALL-SSL.TXT

# activate new vhost
sudo a2dissite default-ssl
sudo a2ensite misp-ssl

# Restart apache
sudo systemctl restart apache2

#8/ Log rotation
#---------------
# MISP saves the stdout and stderr of its workers in /var/www/MISP/app/tmp/logs
# To rotate these logs install the supplied logrotate script:

sudo cp /var/www/MISP/INSTALL/misp.logrotate /etc/logrotate.d/misp

#9/ MISP configuration
#---------------------
# There are 4 sample configuration files in /var/www/MISP/app/Config that need to be copied
sudo -u www-data cp -a /var/www/MISP/app/Config/bootstrap.default.php /var/www/MISP/app/Config/bootstrap.php
sudo -u www-data cp -a /var/www/MISP/app/Config/database.default.php /var/www/MISP/app/Config/database.php
sudo -u www-data cp -a /var/www/MISP/app/Config/core.default.php /var/www/MISP/app/Config/core.php
sudo -u www-data cp -a /var/www/MISP/app/Config/config.default.php /var/www/MISP/app/Config/config.php

# Configure the fields in the newly created files:
echo Input sqlDB password:
read pass
sed -i "s/('password' => )'XXXXdbpasswordhereXXXXX',/$1'$pass'" "/var/www/MISP/app/Config/database.php"

#sudo -u www-data vim /var/www/MISP/app/Config/database.php
# DATABASE_CONFIG has to be filled
# With the default values provided in section 6, this would look like:
# class DATABASE_CONFIG {
#   public $default = array(
#       'datasource' => 'Database/Mysql',
#       'persistent' => false,
#       'host' => 'localhost',
#       'login' => 'misp', // grant usage on *.* to misp@localhost
#       'port' => 3306,
#       'password' => 'XXXXdbpasswordhereXXXXX', // identified by 'XXXXdbpasswordhereXXXXX';
#       'database' => 'misp', // create database misp;
#       'prefix' => '',
#       'encoding' => 'utf8',
#   );
#}

# Important! Change the salt key in /var/www/MISP/app/Config/config.php
# The salt key must be a string at least 32 bytes long.

#### THIS NEEDS TO BE TESTED ####
salt_str=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)
file=/var/www/MISP/app/Config/config.php
sed -i "s/('salt'\s+=> )'',/$1'$salt_str',/" "$file"
#################################

# The admin user account will be generated on the first login, make sure that the salt is changed before you create that user
# If you forget to do this step, and you are still dealing with a fresh installation, just alter the salt,
# you can reset the admin password with the following command

#### THIS NEEDS TO BE TESTED ####
echo Input new admin account password:
read pass
/var/www/MISP/app/Console/cake Password admin@admin.test $pass
#################################

#### THIS NEEDS TO BE TESTED ####
# Change baseurl
echo Input BaseURL:
read base_url
/var/www/MISP/app/Console/cake Baseurl $base_url
#################################
# alternatively, you can leave this field empty if you would like to use relative pathing in MISP.
# This however is highly advised against.

# and make sure the file permissions are still OK
sudo chown -R www-data:www-data /var/www/MISP/app/Config
sudo chmod -R 750 /var/www/MISP/app/Config

#Generate randomness for encryption key
sudo apt-get -y install rng-tools
rngd -r /dev/urandom

# Generate a GPG encryption key.
sudo -u www-data mkdir /var/www/MISP/.gnupg
sudo chmod 700 /var/www/MISP/.gnupg
sudo -u www-data gpg --homedir /var/www/MISP/.gnupg --gen-key
# The email address should match the one set in the config.php / set in the configuration menu in the administration menu configuration file

# NOTE: if entropy is not high enough, you can install rng-tools and then run rngd -r /dev/urandom do fix it quickly

# And export the public key to the webroot
sudo -u www-data sh -c "gpg --homedir /var/www/MISP/.gnupg --export --armor YOUR-KEYS-EMAIL-HERE > /var/www/MISP/app/webroot/gpg.asc"

# To make the background workers start on boot
sudo chmod +x /var/www/MISP/app/Console/worker/start.sh
sudo vim /etc/rc.local
# Add the following line before the last line (exit 0). Make sure that you replace www-data with your apache user:
sudo sed -i "s/exit 0/sudo -u www-data bash \/var\/www\/MISP\/app\/Console\/worker\/start.sh\nexit 0/" "/etc/rc.local"

sudo -u www-data bash /var/www/MISP/app/Console/worker/start.sh

# Now log in using the webinterface:
# The default user/pass = admin@admin.test/admin

# Using the server settings tool in the admin interface (Administration -> Server Settings), set MISP up to your preference
# It is especially vital that no critical issues remain!
# start the workers by navigating to the workers tab and clicking restart all workers

# Don't forget to change the email, password and authentication key after installation.

# Once done, have a look at the diagnostics

# If any of the directories that MISP uses to store files is not writeable to the apache user, change the permissions
# you can do this by running the following commands:

sudo chmod -R 750 /var/www/MISP/<directory path with an indicated issue>
sudo chown -R www-data:www-data /var/www/MISP/<directory path with an indicated issue>

# Make sure that the STIX libraries and GnuPG work as intended, if not, refer to INSTALL.txt's paragraphs dealing with these two items

# If anything goes wrong, make sure that you check MISP's logs for errors:
# /var/www/MISP/app/tmp/logs/error.log
# /var/www/MISP/app/tmp/logs/resque-worker-error.log
# /var/www/MISP/app/tmp/logs/resque-scheduler-error.log
# /var/www/MISP/app/tmp/logs/resque-2015-01-01.log // where the actual date is the current date


#Recommended actions
#-------------------
#- By default CakePHP exposes its name and version in email headers. Apply a patch to remove this behavior.

#- You should really harden your OS
#- You should really harden the configuration of Apache
#- You should really harden the configuration of MySQL/MariaDB
#- Keep your software up2date (OS, MISP, CakePHP and everything else)
#- Log and audit


#Optional features
#-----------------
# MISP has a new pub/sub feature, using ZeroMQ. To enable it, simply run the following command
sudo pip3 install pyzmq
# ZeroMQ depends on the Python client for Redis
sudo pip3 install redis

# For the experimental ssdeep correlations, run the following installation:
# installing ssdeep
cd ~/
wget https://github.com/ssdeep-project/ssdeep/releases/download/release-2.14.1/ssdeep-2.14.1.tar.gz
tar zxvf ssdeep-2.14.1.tar.gz
cd ssdeep-2.14.1
./configure
make
sudo make install
ssdeep -h # test

#installing ssdeep_php
sudo pecl install ssdeep

# You should add "extension=ssdeep.so" to mods-available - Check /etc/php for your current version
echo "extension=ssdeep.so" | sudo tee /etc/php/7.2/mods-available/ssdeep.ini
sudo phpenmod ssdeep
sudo service apache2 restart

#Optional features: misp-modules
#-------------------------------
# If you want to add the misp modules functionality, follow the setup procedure described in misp-modules:
# https://github.com/MISP/misp-modules#how-to-install-and-start-misp-modules
# Then the enrichment, export and import modules can be enabled in MISP via the settings.
