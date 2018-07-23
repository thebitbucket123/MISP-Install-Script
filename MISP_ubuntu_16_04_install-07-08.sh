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
read -rsp $'Press any key to continue...\n' -n1 key