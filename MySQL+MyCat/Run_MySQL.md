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
<a name="XOvMk"></a>
## 4.水平拆分

- 在业务系统中, 有一张表(日志表), 业务系统每天都会产生大量的日志数据 , 单台服务器的数据存储及处理能力是有限的, 可以对数据库表进行拆分。
- 在三台数据库服务器中分表创建一个数据库itcast。
```xml
<schema name="ITCAST" checkSQLschema="true" sqlMaxLimit="100">
  <table name="tb_log" dataNode="dn4,dn5,dn6" primaryKey="id" rule="mod-long" />
</schema>

<dataNode name="dn4" dataHost="dhost1" database="itcast" />
<dataNode name="dn5" dataHost="dhost2" database="itcast" />
<dataNode name="dn6" dataHost="dhost3" database="itcast" />

```
```xml
<user name="root" defaultAccount="true">
	<property name="password">123456</property>
	<property name="schemas">SHOPPING,ITCAST</property>
	<!-- 表级 DML 权限设置 -->
	<!--
	<privileges check="true">
		<schema name="DB01" dml="0110" >
			<table name="TB_ORDER" dml="1110"></table>
		</schema>
	</privileges>
	-->
</user>

```

- 配置root用户既可以访问 SHOPPING 逻辑库，又可以访问ITCAST逻辑库。
- 配置完毕后，重新启动MyCat，然后在mycat的命令行中，执行如下SQL创建表、并插入数据，查看数据分布情况。
```sql
CREATE TABLE tb_log (
  id bigint(20) NOT NULL COMMENT 'ID',
  model_name varchar(200) DEFAULT NULL COMMENT '模块名',
  model_value varchar(200) DEFAULT NULL COMMENT '模块值',
  return_value varchar(200) DEFAULT NULL COMMENT '返回值',
  return_class varchar(200) DEFAULT NULL COMMENT '返回值类型',
  operate_user varchar(20) DEFAULT NULL COMMENT '操作用户',
  operate_time varchar(20) DEFAULT NULL COMMENT '操作时间',
  param_and_value varchar(500) DEFAULT NULL COMMENT '请求参数名及参数值',
  operate_class varchar(200) DEFAULT NULL COMMENT '操作类',
  operate_method varchar(200) DEFAULT NULL COMMENT '操作方法',
  cost_time bigint(20) DEFAULT NULL COMMENT '执行方法耗时, 单位 ms',
  source int(1) DEFAULT NULL COMMENT '来源 : 1 PC , 2 Android , 3 IOS',
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO tb_log (id, model_name, model_value, return_value, return_class,operate_user, operate_time, param_and_value, operate_class,operate_method,cost_time，source) VALUES('1','user','insert','success','java.lang.String','10001','2022-01-06 18:12:28','{\"age\":\"20\",\"name\":\"Tom\",\"gender\":\"1\"}','cn.itcast.controller.UserController','insert','10',1);
INSERT INTO tb_log (id, model_name, model_value, return_value, return_class, operate_user, operate_time, param_and_value, operate_class, operate_method,cost_time，source)VALUES('2','user','insert','success','java.lang.String','10001','2022-01-06 18:12:27','{\"age\":\"20\",\"name\":\"Tom\",\"gender\":\"1\"}','cn.itcast.controller.UserController','insert','23',1);
INSERT INTO tb_log (id, model_name, model_value, return_value, return_class,operate_user, operate_time, param_and_value, operate_class, operate_method,cost_time，source)VALUES('3','user','update','success','java.lang.String','10001','2022-01-06 18:16:45','{\"age\":\"20\",\"name\":\"Tom\",\"gender\":\"1\"}','cn.itcast.controller.UserController','update','34',1);
INSERT INTO tb_log (id, model_name, model_value, return_value, return_class, operate_user, operate_time, param_and_value, operate_class, operate_method, cost_time，source)VALUES('4','user','update','success','java.lang.String','10001','2022-01-06 18:16:45','{\"age\":\"20\",\"name\":\"Tom\",\"gender\":\"1\"}','cn.itcast.controller.UserController','update','13',2);
INSERT INTO tb_log (id, model_name, model_value, return_value, return_class, operate_user, operate_time, param_and_value, operate_class, operate_method, cost_time，source) VALUES('5','user','insert','success','java.lang.String','10001','2022-01-06 18:30:31','{\"age\":\"200\",\"name\":\"TomCat\",\"gender\":\"0\"}','cn.itcast.controller.UserController','insert','29',3);
INSERT INTO tb_log (id, model_name, model_value, return_value, return_class, operate_user, operate_time, param_and_value, operate_class, operate_method, cost_time，source)VALUES('6','user','find','success','java.lang.String','10001','2022-01-06 18:30:31','{\"age\":\"200\",\"name\":\"TomCat\",\"gender\":\"0\"}','cn.itcast.controller.UserController','find','29',2);

```

- 取模，id%(节点总数),结果为0落在第一个节点。结果为1落在第二个节点。结果为2落在第三个节点。
<a name="JpDvR"></a>
## 5.分片规则
<a name="xJXLx"></a>
### 5.1范围分片

- 根据指定的字段及其配置的范围与数据节点的对应情况， 来决定该数据属于哪一个分片。
- schema.xml 逻辑表配置
```xml
<table name="TB_ORDER" dataNode="dn1,dn2,dn3" rule="auto-sharding-long" />

```

- schema.xml数据节点配置
```xml
<dataNode name="dn1" dataHost="dhost1" database="db01" />
<dataNode name="dn2" dataHost="dhost2" database="db01" />
<dataNode name="dn3" dataHost="dhost3" database="db01" />

```

- rule.xml分片规则配置
```xml
<tableRule name="auto-sharding-long">
	<rule>
    <!-- 根据ID字段分片 -->
		<columns>id</columns>
    <!-- 根据rang-long 算法 -->
		<algorithm>rang-long</algorithm>
	</rule>
</tableRule>

<function name="rang-long" class="io.mycat.route.function.AutoPartitionByLong">
  <!--  autopartition-long.txt 配置文件-->
	<property name="mapFile">autopartition-long.txt</property>
	<property name="defaultNode">0</property>
</function>

```

- defaultNode : 默认节点 默认节点的所用:枚举分片时,如果碰到不识别的枚举值, 就让它路由到默认节点 ; 如果没有默认值,碰到不识别的则报错 。
<a name="Uz7nn"></a>
### 5.2取模分片

- 取模，id%(节点总数),结果为0落在第一个节点。结果为1落在第二个节点。结果为2落在第三个节点。
- schema.xml 逻辑表配置
```xml
<table name="tb_log" dataNode="dn4,dn5,dn6" primaryKey="id" rule="mod-long" />

```

- schema.xml数据节点配置
```xml
<dataNode name="dn4" dataHost="dhost1" database="itcast" />
<dataNode name="dn5" dataHost="dhost2" database="itcast" />
<dataNode name="dn6" dataHost="dhost3" database="itcast" />

```

- rule.xml分片规则配置
```xml
<tableRule name="mod-long">
	<rule>
		<columns>id</columns>
		<algorithm>mod-long</algorithm>
	</rule>
</tableRule>

<function name="mod-long" class="io.mycat.route.function.PartitionByMod">
	<property name="count">3</property>
</function>

```

- count : 数据节点的数量
<a name="ivYAy"></a>
### 5.3一致性hash分片

- 所谓一致性哈希，相同的哈希因子计算值总是被划分到相同的分区表中，不会因为分区节点的增加而改变原来数据的分区位置，有效的解决了分布式数据的拓容问题。
- schema.xml 逻辑表配置
```xml
<!-- 一致性hash -->
<table name="tb_order" dataNode="dn4,dn5,dn6" rule="sharding-by-murmur" />

```

- schema.xml数据节点配置
```xml
<dataNode name="dn4" dataHost="dhost1" database="itcast" />
<dataNode name="dn5" dataHost="dhost2" database="itcast" />
<dataNode name="dn6" dataHost="dhost3" database="itcast" />

```

- rule.xml分片规则配置
```xml
<tableRule name="sharding-by-murmur">
	<rule>
		<columns>id</columns>
		<algorithm>murmur</algorithm>
	</rule>
</tableRule>

<function name="murmur" class="io.mycat.route.function.PartitionByMurmurHash">
	<property name="seed">0</property><!-- 默认是0 -->
	<property name="count">3</property>
	<property name="virtualBucketTimes">160</property>
</function>

```

- seed : 创建murmur_hash对象的种子，默认0
- count : 要分片的数据库节点数量，必须指定，否则没法分片
- virtualBucketTimes : 一个实际的数据库节点被映射为这么多虚拟节点，默认是160倍，也就是虚拟节点数是物理节点数的160倍;virtualBucketTimes*count就是虚拟结点数量 ;
- weightMapFile : 节点的权重，没有指定权重的节点默认是1。以properties文件的格式填写，以从0开始到count-1的整数值也就是节点索引为key，以节点权重值为值。所有权重值必须是正整数，否则以1代替
- bucketMapPath : 用于测试时观察各物理节点与虚拟节点的分布情况，如果指定了这个属性，会把虚拟节点的murmur hash值与物理节点的映射按行输出到这个文件，没有默认值，如果不指定，就不会输出任何东西
<a name="JJ0NM"></a>
#### 测试

- 配置完毕后，重新启动MyCat，然后在mycat的命令行中，执行如下SQL创建表、并插入数据，查看数据分布情况。
```sql
create table tb_order(
  id varchar(100) not null primary key,
  money int null,
  content varchar(200) null
);
INSERT INTO tb_order (id, money, content) VALUES ('b92fdaaf-6fc4-11ec-b831- 482ae33c4a2d', 10, 'b92fdaf8-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b93482b6-6fc4-11ec-b831-482ae33c4a2d', 20, 'b93482d5-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b937e246-6fc4-11ec-b831-482ae33c4a2d', 50, 'b937e25d-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b93be2dd-6fc4-11ec-b831-482ae33c4a2d', 100, 'b93be2f9-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b93f2d68-6fc4-11ec-b831-482ae33c4a2d', 130, 'b93f2d7d-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b9451b98-6fc4-11ec-b831-482ae33c4a2d', 30, 'b9451bcc-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b9488ec1-6fc4-11ec-b831-482ae33c4a2d', 560, 'b9488edb-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b94be6e6-6fc4-11ec-b831-482ae33c4a2d', 10, 'b94be6ff-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b94ee10d-6fc4-11ec-b831-482ae33c4a2d', 123, 'b94ee12c-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b952492a-6fc4-11ec-b831-482ae33c4a2d', 145, 'b9524945-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b95553ac-6fc4-11ec-b831-482ae33c4a2d', 543, 'b95553c8-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b9581cdd-6fc4-11ec-b831-482ae33c4a2d', 17, 'b9581cfa-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b95afc0f-6fc4-11ec-b831-482ae33c4a2d', 18, 'b95afc2a-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b95daa99-6fc4-11ec-b831-482ae33c4a2d', 134, 'b95daab2-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b9667e3c-6fc4-11ec-b831-482ae33c4a2d', 156, 'b9667e60-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b96ab489-6fc4-11ec-b831-482ae33c4a2d', 175, 'b96ab4a5-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b96e2942-6fc4-11ec-b831-482ae33c4a2d', 180, 'b96e295b-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b97092ec-6fc4-11ec-b831-482ae33c4a2d', 123, 'b9709306-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b973727a-6fc4-11ec-b831-482ae33c4a2d', 230, 'b9737293-6fc4-11ec-b831-482ae33c4a2d');
INSERT INTO tb_order (id, money, content) VALUES ('b978840f-6fc4-11ec-b831-482ae33c4a2d', 560, 'b978843c-6fc4-11ec-b831-482ae33c4a2d');

```
<a name="Gn7YQ"></a>
### 5.4枚举分片

- 通过在配置文件中配置可能的枚举值, 指定数据分布到不同数据节点上, 本规则适用于按照省份、性别、状态拆分数据等业务 。
- schema.xml 逻辑表配置
```xml
<!-- 枚举 -->
<table name="tb_user" dataNode="dn4,dn5,dn6" rule="sharding-by-intfile-enumstatus"/>

```

- schema.xml数据节点配置
```xml
<dataNode name="dn4" dataHost="dhost1" database="itcast" />
<dataNode name="dn5" dataHost="dhost2" database="itcast" />
<dataNode name="dn6" dataHost="dhost3" database="itcast" />

```

- rule.xml分片规则配置
```xml
<tableRule name="sharding-by-intfile">
	<rule>
		<columns>sharding_id</columns>
		<algorithm>hash-int</algorithm>
	</rule>
</tableRule>

<function name="hash-int" class="io.mycat.route.function.PartitionByFileMap">
	<property name="defaultNode">2</property>
	<property name="mapFile">partition-hash-int.txt</property>
</function>

```
<a name="h743T"></a>
#### 测试

- partition-hash-int.txt 文件配置
```
1=0
2=1
3=2

```

- 配置完毕后，重新启动MyCat，然后在mycat的命令行中，执行如下SQL创建表、并插入数据，查看数据分布情况。
```sql
CREATE TABLE tb_user (
  id bigint(20) NOT NULL COMMENT 'ID',
  username varchar(200) DEFAULT NULL COMMENT '姓名',
  status int(2) DEFAULT '1' COMMENT '1: 未启用, 2: 已启用, 3: 已关闭',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

insert into tb_user (id,username ,status) values(1,'Tom',1);
insert into tb_user (id,username ,status) values(2,'Cat',2);
insert into tb_user (id,username ,status) values(3,'Rose',3);
insert into tb_user (id,username ,status) values(4,'Coco',2);
insert into tb_user (id,username ,status) values(5,'Lily',1);
insert into tb_user (id,username ,status) values(6,'Tom',1);
insert into tb_user (id,username ,status) values(7,'Cat',2);
insert into tb_user (id,username ,status) values(8,'Rose',3);
insert into tb_user (id,username ,status) values(9,'Coco',2);
insert into tb_user (id,username ,status) values(10,'Lily',1);

```
<a name="l9oUk"></a>
### 5.5应用指定算法

- 运行阶段由应用自主决定路由到那个分片 , 直接根据**字符子串（必须是数字）**计算分片号。
- schema.xml 逻辑表配置
```xml
<!-- 应用指定算法 -->
<table name="tb_app" dataNode="dn4,dn5,dn6" rule="sharding-by-substring" />

```

- schema.xml数据节点配置
```xml
<dataNode name="dn4" dataHost="dhost1" database="itcast" />
<dataNode name="dn5" dataHost="dhost2" database="itcast" />
<dataNode name="dn6" dataHost="dhost3" database="itcast" />

```

- rule.xml分片规则配置
```xml
<tableRule name="sharding-by-substring">
	<rule>
		<columns>id</columns>
		<algorithm>sharding-by-substring</algorithm>
	</rule>
</tableRule>
<function name="sharding-by-substring" class="io.mycat.route.function.PartitionDirectBySubString">
	<property name="startIndex">0</property> <!-- zero-based -->
	<property name="size">2</property>
	<property name="partitionCount">3</property>
	<property name="defaultPartition">0</property>
</function>

```
<a name="DPbiD"></a>
#### 测试

- id=05-100000002 , 在此配置中代表根据id中从 startIndex=0，开始，截取siz=2位数字即05，05就是获取的分区，如果没找到对应的分片则默认分配到defaultPartition 。
- 配置完毕后，重新启动MyCat，然后在mycat的命令行中，执行如下SQL创建表、并插入数据，查看数据分布情况。
```sql
CREATE TABLE tb_app (
	id varchar(10) NOT NULL COMMENT 'ID',
	name varchar(200) DEFAULT NULL COMMENT '名称',
	PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

insert into tb_app (id,name) values('0000001','Testx00001');
insert into tb_app (id,name) values('0100001','Test100001');
insert into tb_app (id,name) values('0100002','Test200001');
insert into tb_app (id,name) values('0200001','Test300001');
insert into tb_app (id,name) values('0200002','TesT400001');

```
