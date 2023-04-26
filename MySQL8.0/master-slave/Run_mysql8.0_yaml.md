# 1.容器配置
cd /var/lib/docker/volumes/mysql-master/_data

-编写配置文件\
[mysqld]\
- 以下是增加的配置\
`vim my.cnf`\
-主服务器唯一ID\
server-id=1\
-这里是列表文本启用二进制日志，指名路径。比如：自己本地的路径/log/mysqlbin\
log-bin=binlog\
binlog_format=STATEMEN

# 2.进入 MySQL 的主机容器实例，创建账户，并进行授权：
`docker exec -it mysql-master /bin/bash`\
`mysql -uroot -p123456`\
`CREATE USER 'slave1'@'%' IDENTIFIED BY '123456';`\
`GRANT REPLICATION SLAVE ON *.* TO 'slave1'@'%';`\
`ALTER USER 'slave1'@'%' IDENTIFIED WITH mysql_native_password BY '123456';`\
`FLUSH PRIVILEGES;`

# 3.查看 Master 的状态，并记录 File 和 Position 的值：
show master status;

# 4.配置slave 节点
CHANGE MASTER TO\
MASTER_HOST='主机的IP地址',\
MASTER_USER='主机用户名',\
MASTER_PORT='主机的端口号',\
MASTER_PASSWORD='主机用户名的密码',\
MASTER_LOG_FILE='binlog.具体数字',\
MASTER_LOG_POS=具体值;

# 5.启动同步(在slave 容器上)
START SLAVE;
