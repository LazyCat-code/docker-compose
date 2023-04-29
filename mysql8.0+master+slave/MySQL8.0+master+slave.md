- Master IP:192.168.110.199 (主)
- Slave IP:192.168.110.177 (从)
<a name="YlxRC"></a>
### 1.安装MySQL 8.0.25 (两个服务器)

- MySQL 8.0.25下载地址:`[https://www.aliyundrive.com/s/nNj4UjksUGG](https://www.aliyundrive.com/s/nNj4UjksUGG)`
- 在 `cd /opt` 放mysql安装包
- 主 `hostnamectl set-hostname master` 设置主机名
- 从 `hostnamectl set-hostname slave` 设置从机名
```shell
systemctl stop firewalld;
systemctl disable firewalld;
systemctl status firewalld;
yum update -y
yum install -y vim wget;
```
```bash
rpm -ivh mysql-community-common-8.0.25-1.el7.x86_64.rpm
rpm -ivh mysql-community-client-plugins-8.0.25-1.el7.x86_64.rpm
yum remove -y mysql-libs
rpm -ivh mysql-community-libs-8.0.25-1.el7.x86_64.rpm
rpm -ivh mysql-community-client-8.0.25-1.el7.x86_64.rpm
rpm -ivh mysql-community-server-8.0.25-1.el7.x86_64.rpm
```

<a name="A9tWV"></a>
#### 2.关闭SELINUX

- `vim /etc/selinux/config`

修改内容: `SELINUX=disabled`

<a name="vYPAj"></a>
#### 3.设置MySQL

- 启动MySQL服务 `systemctl start mysqld.service`
- 设置密码
```plsql
ALTER USER 'root'@'%' IDENTIFIED BY '123456' PASSWORD EXPIRE NEVER; 
alter user 'root'@'%' identified by '123456';
grant all privileges  on *.*  to "root"@'%';
flush privileges;


use mysql; 
updateuserset authentication_string=''whereuser='root';--将字段置为空
ALTER user 'root'@'%' IDENTIFIED BY 'root';
flush privileges;
```
  vim /etc/my.cnf `[skip](https://so.csdn.net/so/search?q=skip&spm=1001.2101.3001.7020)-grant-tables` 免密码登入<br /> 
<a name="Scoz1"></a>
### 4.主库配置

- 修改配置文件 `vim /etc/my.cnf`
```plsql
#mysql 服务ID，保证整个集群环境中唯一，取值范围：1 – 232-1，默认为1

server-id=1

#是否只读,1 代表只读, 0 代表读写

read-only=0

#忽略的数据, 指不需要同步的数据库
#binlog-ignore-db=mysql
#指定同步的数据库
#binlog-do-db=db01
```

- 重启MySQL`systemctl restart mysqld`
- 登录mysql，创建远程连接的账号，并授予主从复制权限
```plsql
#创建itcast用户，并设置密码，该用户可在任意主机连接该MySQL服务
CREATE USER 'itcast'@'%' IDENTIFIED WITH mysql_native_password BY 'Root@123456';

#为 'itcast'@'%' 用户分配主从复制权限
GRANT REPLICATION SLAVE ON *.* TO 'itcast'@'%';

```
```plsql
mysql>  show master status;
+---------------+----------+--------------+------------------+-------------------+
| File          | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+---------------+----------+--------------+------------------+-------------------+
| binlog.000019 |      663 |              |                  |                   |
+---------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)

```

- file : 从哪个日志文件开始推送日志文件
- position ： 从哪个位置开始推送日志
- binlog_ignore_db : 指定不需要同步的数据库
<a name="o3WVV"></a>
#### 从库配置
`CHANGE REPLICATION SOURCE TO SOURCE_HOST='192.168.110.199', SOURCE_USER='itcast', SOURCE_PASSWORD='Root@123456', SOURCE_LOG_FILE='binlog.000010', SOURCE_LOG_POS=655;`

- 开启同步操作
- `start replica; `

<a name="jd5l8"></a>
#### 测试

- 创建库，表并且插入数据
```plsql
create database db01;
use db01;
create table tb_user(
	id int(11) primary key not null auto_increment,
	name varchar(50) not null,
	sex varchar(1)
)engine=innodb default charset=utf8mb4;
insert into tb_user(id,name,sex) values(null,'Tom', '1'),(null,'Trigger','0'),(null,'Dawn','1');

```


```sql
change master to 
master_host='mysql-master',  # 主库的IP，由于docker的原因，可以使用容器名来当主机名
master_user='slaver',    # 主库同步的用户
master_password='123456', # 密码
master_port=3306, # 主库的端口
master_log_file='mysql-bin.000003', # 同步的文件 通过show master status来获取
master_log_pos=1769; # 开始从第几行同步 通过show master status来获取

```


```sql
insert into tb_user(id,name,sex) values(null,'Tomcat', '0');
```





