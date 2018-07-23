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
sudo sed -i "s/('password' => )'XXXXdbpasswordhereXXXXX',/$1'$pass'/" "/var/www/MISP/app/Config/database.php"

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
read -rsp $'Press any key to continue...\n' -n1 key

# The admin user account will be generated on the first login, make sure that the salt is changed before you create that user
# If you forget to do this step, and you are still dealing with a fresh installation, just alter the salt,
# you can reset the admin password with the following command

#### THIS NEEDS TO BE TESTED ####
echo Input new admin account password:
read pass
/var/www/MISP/app/Console/cake Password admin@admin.test $pass
#################################
read -rsp $'Press any key to continue...\n' -n1 key

#### THIS NEEDS TO BE TESTED ####
# Change baseurl
echo Input BaseURL:
read base_url
/var/www/MISP/app/Console/cake Baseurl $base_url
#################################
read -rsp $'Press any key to continue...\n' -n1 key
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

read -rsp $'Press any key to continue...\n' -n1 key

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
