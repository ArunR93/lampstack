#!/bin/bash

MYSQL_ROOT_PASSWORD=''

dbconf()
{
#!/bin/sh

# start apache
echo "Starting httpd"
httpd
echo "Done httpd"


# check if mysql data directory is nuked
# if so, install the db
echo "Checking /var/lib/mysql folder"
if [ ! -f /var/lib/mysql/ibdata1 ]; then 
    echo "Installing db"
    mariadb-install-db --user=mysql --ldata=/var/lib/mysql > /dev/null
    echo "Installed"
fi;

# from mysql official docker repo
if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
			echo >&2 'error: database is uninitialized and password option is not specified '
			echo >&2 '  You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_RANDOM_ROOT_PASSWORD'
			exit 1
fi

# random password
if [ ! -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
    echo "Using random password"
    MYSQL_ROOT_PASSWORD="$(pwgen -1 32)"
    echo "GENERATED ROOT PASSWORD: $MYSQL_ROOT_PASSWORD"
    echo "Done"
fi

tfile=`mktemp`
if [ ! -f "$tfile" ]; then
    return 1
fi

cat << EOF > $tfile
    USE mysql;
    DELETE FROM user;
    FLUSH PRIVILEGES;
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
    UPDATE user SET password=PASSWORD("") WHERE user='root' AND host='localhost';
    FLUSH PRIVILEGES;
EOF

echo "Querying user"
/usr/sbin/mysqld --user=root --bootstrap --verbose=0 < $tfile
rm -f $tfile
echo "Done query"

# start mysql
# nohup mysqld_safe --skip-grant-tables --bind-address 0.0.0.0 --user mysql > /dev/null 2>&1 &
echo "Starting mariadb database"
exec /usr/sbin/mysqld --user=root --bind-address=0.0.0.0
}

centos8()
{
dnf install epel-release-8  redhat-release  wget unzip -y
rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module enable php:remi-7.4 -y 
dnf install -y php php-xml php-soap php-cli php-xmlrpc php-mbstring php-pdo php-json php-gd php-mcrypt php-mysql php-fileinfo php-zip  php-curl php-ldap php-intl php-sodium --exclude=php-fpm \
dnf erase -y php-fpm
wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup -O /tmp/mariadb_repo_setup
chmod +x /tmp/mariadb_repo_setup
/tmp/./mariadb_repo_setup
dnf -y install MariaDB-server MariaDB-backup 
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer 
mkdir -p /var/run/mariadb/
chown -R mysql:mysql /var/run/mariadb/ /var/lib/mysql
mkdir -p /var/run/httpd/
chown -R apache:apache /var/run/httpd/
chown -R apache:apache /var/www/html/
sed -i 's#\#LoadModule rewrite_module modules\/mod_rewrite.so#LoadModule rewrite_module modules\/mod_rewrite.so#' /etc/httpd/conf/httpd.conf
sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/my.cnf.d/server.cnf
sed -i "s#\#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so#" /etc/httpd/conf.modules.d/00-mpm.conf
sed -i "s#\LoadModule mpm_event_module modules/mod_mpm_event.so#\#LoadModule mpm_event_module modules/mod_mpm_event.so#" /etc/httpd/conf.modules.d/00-mpm.conf
rm -rf /var/cache/dnf/
rm -rf /var/lib/dnf
rm -rf /var/lib/rpm
      
}

centos7()
{
yum install epel-release -y
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum --enablerepo=remi-php74 -y install php php-xml php-soap php-cli php-xmlrpc php-mbstring php-pdo php-json php-gd php-mcrypt php-mysql php-fileinfo   php-zip  php-curl php-ldap php-intl php-sodium
yum install wget -y
wget https://downloads.mariadb.com/MariaDB/mariadb_repo_setup -O /tmp/mariadb_repo_setup
chmod +x /tmp/mariadb_repo_setup
/tmp/./mariadb_repo_setup
yum install MariaDB-server MariaDB-backup -y
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer 
mkdir -p /var/run/mariadb/
chown -R mysql:mysql /var/run/mariadb/ /var/lib/mysql
mkdir -p /var/run/httpd/
chown -R apache:apache /var/run/httpd/
chown -R apache:apache /var/www/html/
sed -i 's#\#LoadModule rewrite_module modules\/mod_rewrite.so#LoadModule rewrite_module modules\/mod_rewrite.so#' /etc/httpd/conf/httpd.conf
sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/my.cnf.d/server.cnf
sed -i "s#\#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so#LoadModule mpm_prefork_module modules/mod_mpm_prefork.so#" /etc/httpd/conf.modules.d/00-mpm.conf
sed -i "s#\LoadModule mpm_event_module modules/mod_mpm_event.so#\#LoadModule mpm_event_module modules/mod_mpm_event.so#" /etc/httpd/conf.modules.d/00-mpm.conf
rm -rf /var/lib/rpm
}

