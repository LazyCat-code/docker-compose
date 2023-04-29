<a name="MVCbX"></a>
## 1.环境搭建(三台服务器)
- master 节点: `192.168.110.155` `MySQL 8.0` `MyCat 1.6`
- slave0 节点: `192.168.110.150` `MySQL 8.0`
- slave1 节点: `192.168.110.151` `MySQL 8.0`
- MySQL  8.0  `[https://www.aliyundrive.com/s/nNj4UjksUGG](https://www.aliyundrive.com/s/nNj4UjksUGG)`
- MyCat + java + MySQL(驱动) `[https://pan.xunlei.com/s/VNTgzBWWlW2maUyu3DQ2_nu_A1?pwd=2pds#](https://pan.xunlei.com/s/VNTgzBWWlW2maUyu3DQ2_nu_A1?pwd=2pds#)`
1. 解压文件
```
tar -zxvf Mycat-server-1.6.7.3-release-20190828135747-linux.tar.gz -C /usr/local
```

2. 由于mycat中的mysql的JDBC驱动包版本比较低，所以我们将它删去，下载8.0版本的
```
cd /usr/local/mycat/lib/
rm -rf mysql-connector-java-5.1.35.jar

# 将下载好的mysql-connector 上传到 /usr/local/mycat/lib/ 下
chmod 777 mysql-connector  
```

3. 安装java 环境
```
mkdir /opt/java1.8 # 放java包

mkdir /usr/local/java
cd /opt/java1.8/
tar -zxvf jdk-8u301-linux-x64.tar.gz -C /usr/local/java

```

4. 修改系统环境变量
```
vim /etc/profile

export JAVA_HOME=/usr/local/java/jdk1.8.0_211
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

source /etc/profile  # 重新加载变量
```
<a name="QGTVN"></a>
## 2.MyCat (配置)

- schema.xml 文件配置
```xml
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">

  <schema name="DB01" checkSQLschema="true" sqlMaxLimit="100">
    <table name="TB_ORDER" dataNode="dn1,dn2,dn3" rule="auto-sharding-long"/>
  </schema>
  <dataNode name="dn1" dataHost="dhost1" database="db01"/>
  <dataNode name="dn2" dataHost="dhost2" database="db01"/>
  <dataNode name="dn3" dataHost="dhost3" database="db01"/>
  <dataHost name="dhost1" maxCon="1000" minCon="10" balance="0" writeType="0" dbType="mysql" dbDriver="jdbc" switchType="1" slaveThreshold="100">
    <heartbeat>select user()</heartbeat>
    <writeHost host="master" url="jdbc:mysql://192.168.110.155:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456"/>
  </dataHost>
  <dataHost name="dhost2" maxCon="1000" minCon="10" balance="0" writeType="0" dbType="mysql" dbDriver="jdbc" switchType="1" slaveThreshold="100">
    <heartbeat>select user()</heartbeat>
    <writeHost host="slave0" url="jdbc:mysql://192.168.110.150:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456"/>
  </dataHost>
  <dataHost name="dhost3" maxCon="1000" minCon="10" balance="0" writeType="0" dbType="mysql" dbDriver="jdbc" switchType="1" slaveThreshold="100">
    <heartbeat>select user()</heartbeat>
    <writeHost host="slave1" url="jdbc:mysql://192.168.110.151:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456"/>
  </dataHost>
</mycat:schema>

```

- server.xml 文件配置
```xml
<user name="root" defaultAccount="true">
  <property name="password">123456</property>
  <property name="schemas">DB01</property>

  <!-- 表级 DML 权限设置 -->
  <!--            
  <privileges check="false">
  <schema name="TESTDB" dml="0110" >
  <table name="tb01" dml="0000"></table>
  <table name="tb02" dml="1111"></table>
</schema>
</privileges>           
  -->
</user>

<user name="user">
  <property name="password">123456</property>
  <property name="schemas">DB01</property>
  <property name="readOnly">true</property>
</user>

```

- 启动MyCat
```
bin/mycat start   # 在mycat 目录下
```

- 连接MyCat
```
mysql -uroot -p -P8066 -h192.168.110.155 --default-auth=mysql_native_password
```

- 笔记 [https://frxcat.fun/database/MySQL/MySQL_Mycat](https://frxcat.fun/database/MySQL/MySQL_Mycat)

<a name="dPERU"></a>
## 3.垂直分库

- 先在master、slave0、slave1 节点MySQL数据库创建 shopping 数据库
```xml
CREATE DATABASE shopping;
```

- master 节点的schema.xml 文件配置
```xml
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">
  <!-- checkSQLschema：在SQL语句操作时指定了数据库名称，
  执行时是否自动去除；true：自动去除，false：不自动去除 (不需要use name) -->
  <!-- 逻辑库,逻辑表 配置-->
  <schema name="SHOPPING" checkSQLschema="true" sqlMaxLimit="100">
    <!--  
    name：定义逻辑表表名，在该逻辑库下唯一
    dataNode：定义逻辑表所属的dataNode，该属性需要与dataNode标签中name对应；
    多个dataNode逗号分隔
    rule：分片规则的名字，分片规则名字是在rule.xml中定义的
    primaryKey：逻辑表对应真实表的主键
    type：逻辑表的类型，目前逻辑表只有全局表和普通表，
    如果未配置，就是普通表；全局表，配 置为 global
    -->
    <table name="tb_goods_base" dataNode="dn1" primaryKey="id"/>
    <table name="tb_goods_brand" dataNode="dn1" primaryKey="id"/>
    <table name="tb_goods_cat" dataNode="dn1" primaryKey="id"/>
    <table name="tb_goods_desc" dataNode="dn1" primaryKey="goods_id"/>
    <table name="tb_goods_item" dataNode="dn1" primaryKey="id"/>

    <table name="tb_order_item" dataNode="dn2" primaryKey="id" />
    <table name="tb_order_master" dataNode="dn2" primaryKey="order_id" />
    <table name="tb_order_pay_log" dataNode="dn2" primaryKey="out_trade_no" />
    <table name="tb_user" dataNode="dn3" primaryKey="id" />
    <table name="tb_user_address" dataNode="dn3" primaryKey="id" />

    <table name="tb_areas_provinces" dataNode="dn3" primaryKey="id"/>
    <table name="tb_areas_city" dataNode="dn3" primaryKey="id"/>
    <table name="tb_areas_region" dataNode="dn3" primaryKey="id"/>
  </schema>
  
  <!-- 数据节点配置 -->
  <!-- 
  name：定义数据节点名称
  dataHost：数据库实例主机名称，引用自 dataHost 标签中name属性
  database：定义分片所属数据库
  -->
  <dataNode name="dn1" dataHost="dhost1" database="shopping"/>
  <dataNode name="dn2" dataHost="dhost2" database="shopping"/>
  <dataNode name="dn3" dataHost="dhost3" database="shopping"/>

  <!-- 数据源配置 -->
  <!-- 
  balance：负载均衡策略，取值 0,1,2,3
  writeType：写操作分发方式（0：写操作转发到第一个writeHost，
  第一个挂了，切换到第二个；1：写操作随机分发到配置的writeHost）
  dbDriver：数据库驱动，支持 native、jdbc
  -->
  <dataHost name="dhost1" maxCon="1000" minCon="10" balance="0" writeType="0" dbType="mysql" dbDriver="jdbc" switchType="1" slaveThreshold="100">
    <heartbeat>select user()</heartbeat>
    <writeHost host="master" url="jdbc:mysql://192.168.110.155:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456"/>
  </dataHost>
  <dataHost name="dhost2" maxCon="1000" minCon="10" balance="0" writeType="0" dbType="mysql" dbDriver="jdbc" switchType="1" slaveThreshold="100">
    <heartbeat>select user()</heartbeat>
    <writeHost host="slave0" url="jdbc:mysql://192.168.110.150:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456"/>
  </dataHost>
  <dataHost name="dhost3" maxCon="1000" minCon="10" balance="0" writeType="0" dbType="mysql" dbDriver="jdbc" switchType="1" slaveThreshold="100">
    <heartbeat>select user()</heartbeat>
    <writeHost host="slave1" url="jdbc:mysql://192.168.110.151:3306?useSSL=false&amp;serverTimezone=Asia/Shanghai&amp;characterEncoding=utf8" user="root" password="123456"/>
  </dataHost>
  
</mycat:schema>

```

- master 节点的server.xml 文件配置
```xml
<user name="root" defaultAccount="true">
	<property name="password">123456</property>
	<property name="schemas">SHOPPING</property>
	<!-- 表级 DML 权限设置 -->
	<!--
	<privileges check="true">
		<schema name="DB01" dml="0110" >
			<table name="TB_ORDER" dml="1110"></table>
		</schema>
	</privileges>
-->
</user>
<user name="user">
	<property name="password">123456</property>
	<property name="schemas">SHOPPING</property>
	<property name="readOnly">true</property>
</user>
```

- 在MyCat 节点主机上导入数据sql文件。(shopping-insert.sql+shopping-table.sql）
```
source /root/shopping-table.sql
source /root/shopping-insert.sql
```

- 查询用户的收件人及收件人地址信息(包含省、市、区)。
```sql
select ua.user_id, ua.contact, p.province, c.city, r.area , ua.address 
from tb_user_address ua ,tb_areas_city c , tb_areas_provinces p ,tb_areas_region r 
where ua.province_id = p.provinceid and ua.city_id = c.cityid and ua.town_id = r.areaid ;

```
<a name="eSbiV"></a>
### 3.1全局表

- 对于省、市、区/县表tb_areas_provinces , tb_areas_city , tb_areas_region，是属于数据字典表，在多个业务模块中都可能会遇到，可以将其设置为全局表，利于业务操作。
- master 节点的schema.xml 文件配置(修改)
```xml
<table name="tb_areas_provinces" dataNode="dn1,dn2,dn3" primaryKey="id" type="global"/>
<table name="tb_areas_city" dataNode="dn1,dn2,dn3" primaryKey="id" type="global"/>
<table name="tb_areas_region" dataNode="dn1,dn2,dn3" primaryKey="id" type="global"/>

```

- 配置完毕后，重新启动MyCat。
- 删除原来每一个数据库服务器中的所有表结构
- 通过source指令，导入表及数据
```sql
SELECT order_id , payment ,receiver, province , city , area 
FROM tb_order_master o, tb_areas_provinces p , tb_areas_city c , tb_areas_region r 
WHERE o.receiver_province = p.provinceid AND o.receiver_city = c.cityid AND o.receiver_region = r.areaid ;

```
