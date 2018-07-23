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
read -rsp $'Press any key to continue...\n' -n1 key

#5/ Set the permissions
#----------------------

# Check if the permissions are set correctly using the following commands:
sudo chown -R www-data:www-data /var/www/MISP
sudo chmod -R 750 /var/www/MISP
sudo chmod -R g+ws /var/www/MISP/app/tmp
sudo chmod -R g+ws /var/www/MISP/app/files
sudo chmod -R g+ws /var/www/MISP/app/files/scripts/tmp
read -rsp $'Press any key to continue...\n' -n1 key