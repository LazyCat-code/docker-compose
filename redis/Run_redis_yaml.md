# 1.启动yaml文件\
docker-compose -f docker-compose.yml up -d\
# 2.进入主\
redis docker exec -it redis-master /bin/bash\
# 3.连接redis 数据库\ 
redis-cli -h 127.0.0.1 -p 6379 -a 123456\
# 4.创建数据\
SET mykey "Hello world" &  GET mykey\
# 5.进入从\
redis docker exec -it redis-slave1 /bin/bash\
# 6.查看数据是否同步\
GET mykey