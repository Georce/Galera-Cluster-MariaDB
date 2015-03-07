#version 10.0.16

FROM centos:centos6.6

COPY mariadb.repo /etc/yum.repos.d/mariadb.repo

COPY run.sh /run.sh

RUN yum install -y MariaDB-Galera-server galera MariaDB-devel && yum clean all && rm -rf /var/lib/mysql/*

COPY server.cnf /etc/my.cnf.d/server.cnf

RUN chmod +x /run.sh

CMD ["/run.sh"]
