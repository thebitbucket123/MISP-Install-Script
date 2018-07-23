#6/ Create a database and user
#-----------------------------

echo Input mysql root account password:
read pass

# Enter the mysql shell
sudo mysql -u root -p


#MariaDB [(none)]> create database misp;
#MariaDB [(none)]> grant usage on *.* to misp@localhost identified by 'XXXXdbpasswordhereXXXXX';
#MariaDB [(none)]> grant all privileges on misp.* to misp@localhost;
#MariaDB [(none)]> flush privileges;
#MariaDB [(none)]> exit

read -rsp $'Press any key to continue...\n' -n1 key

# Import the empty MISP database from MYSQL.sql
sudo -u www-data sh -c "mysql -u misp -p misp < /var/www/MISP/INSTALL/MYSQL.sql"
# enter the password you've set in line 130 when prompted

read -rsp $'Press any key to continue...\n' -n1 key