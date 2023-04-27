for port in $(seq 1 6);
do
docker run -p 637${port}:6379 -p 1637${port}:16379 --name redis-${port}
-v /mydata/redis/node-${port}/data:/data
-v /mydata/redis/node-${port}/conf/redis.conf:/etc/redis/redis.conf
-d --net redis --ip 172.38.0.1${port} redis:5.0.9-alpine3.11 redis-server /etc/redis/redis.conf
done