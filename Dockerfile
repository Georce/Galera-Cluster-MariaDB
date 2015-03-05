#version 10.0.16

FROM centos:centos6.6

COPY mariadb.repo /etc/yum.repos.d/mariadb.repo

COPY run.sh /run.sh

RUN yum install –y MariaDB-Galera-server galera MariaDB-devel && yum clean all

COPY server.cnf /etc/my.cnf.d/server.cnf

RUN cp /usr/share/mysql/wsrep.cnf /etc/my.cnf.d/wsrep.cnf

RUN sed -i 's*wsrep_provider=none*wsrep_provider=/usr/lib64/galera/libgalera_smm.so*' /etc/my.cnf.d/wsrep.cnf

RUN chmod +x /run.sh

CMD ["/run.sh"]
