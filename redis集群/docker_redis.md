# 1.必须要有docker服务
# 2.创建redis集群网卡
`docker network create redis --subnet 172.38.0.0/16`
# 3.先启动create_redis.sh 脚本，再启动Run_redis.sh 脚本
`chmod +x create_redis.sh && Run_redis.sh`\
`./create_redis.sh`\
`./Run_redis.sh`