#2/ Install LAMP & dependencies
#------------------------------
#Once the system is installed you can perform the following steps:

# Install the dependencies: (some might already be installed)
sudo apt-get -y install curl gcc git gnupg-agent make python python3 openssl redis-server sudo vim zip

# Install MariaDB (a MySQL fork/alternative)
sudo apt-get -y install mariadb-client mariadb-server

# Secure the MariaDB installation (especially by setting a strong root password)
sudo mysql_secure_installation

read -rsp $'Press any key to continue...\n' -n1 key
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
read -rsp $'Press any key to continue...\n' -n1 key