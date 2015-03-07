#!/bin/bash
set -e

DB_USER=${DB_USER:-}
DB_PASS=${DB_PASS:-}
gcomm=${gcomm:-"//"}

# fix permissions and ownership of /var/lib/mysql
mkdir -p -m 700 /var/lib/mysql
chown -R mysql:mysql /var/lib/mysql

# initialize MySQL data directory
if [ ! -d /var/lib/mysql/mysql ]; then
  echo "Installing database..."
  mysql_install_db --user=mysql >/dev/null 2>&1
  
  # start mysql server
  echo "Starting MySQL server..."
  /usr/bin/mysqld_safe >/dev/null 2>&1 &
  
   # wait for mysql server to start (max 30 seconds)
  timeout=30
  echo -n "Waiting for database server to accept connections"
  while ! /usr/bin/mysqladmin -u root status >/dev/null 2>&1
  do
    timeout=$(($timeout - 1))
    if [ $timeout -eq 0 ]; then
      echo -e "\nCould not connect to database server. Aborting..."
      exit 1
    fi
    echo -n "."
    sleep 1
  done
  echo
  
  /usr/bin/mysqladmin shutdown
fi

# create new user
if [ -n "${DB_USER}" -o -n "${DB_PASS}" ]; then
  /usr/bin/mysqld_safe >/dev/null 2>&1 &
  
  # wait for mysql server to start (max 30 seconds)
  timeout=30
  while ! /usr/bin/mysqladmin -u root status >/dev/null 2>&1
  do
    timeout=$(($timeout - 1))
    if [ $timeout -eq 0 ]; then
      echo "Could not connect to mysql server. Aborting..."
      exit 1
    fi
    sleep 1
  done
  
	  if [ -n "${DB_USER}" ]; then
          echo "Granting access to database * for user \"${DB_USER}\"..."
		  mysql -e "GRANT USAGE ON *.* TO '${DB_USER}' IDENTIFIED BY '${DB_PASS}';"
		  mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}' IDENTIFIED BY '${DB_PASS}';"
		  mysql -e "GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@"localhost" IDENTIFIED BY '${DB_PASS}';"
        fi
        
  /usr/bin/mysqladmin shutdown
fi

# wsrep_cluster_address
if [ -n "${gcomm}" ]; then
	sed -i 's*#wsrep_cluster_address="dummy://"*wsrep_cluster_address="dummy://"*' /usr/share/mysql/wsrep.cnf
	sed -i 's*dummy://*gcomm:'${gcomm}'*' /usr/share/mysql/wsrep.cnf
	sed -i 's*wsrep_provider=none*wsrep_provider=/usr/lib64/galera/libgalera_smm.so*' /usr/share/mysql/wsrep.cnf
fi	

# wsrep_sst_auth
if [ -n "${DB_USER}" -o -n "${DB_PASS}" ]; then
sed -i 's*wsrep_sst_auth=root:*wsrep_sst_auth='${DB_USER}':'${DB_PASS}'*' /usr/share/mysql/wsrep.cnf
fi

cp /usr/share/mysql/wsrep.cnf /etc/my.cnf.d/.

service mysql start

ping 127.0.0.1 >> /dev/null
