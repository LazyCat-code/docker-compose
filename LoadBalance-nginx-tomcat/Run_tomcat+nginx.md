<a name="dUAev"></a>
## 1.环境搭建(3台容器服务)
Nginx  1.18 : IP`172.11.0.8`<br />Tomcat1  8.5.24 : IP`172.11.0.9`<br />Tomcat2  8.5.24 : IP`172.11.0.10`
<a name="r5y8z"></a>
### 1.1项目介绍

- 项目结构
```
LoadBalance-nginx-tomcat/
├── docker-compose.yaml
├── nginx
│   └── nginx.conf
├── tomcat1
│   └── webapp
│       └── ROOT
│           ├── asf-logo-wide.svg
│           ├── bg-button.png
│           ├── bg-middle.png
│           ├── bg-nav-item.png
│           ├── bg-nav.png
│           ├── bg-upper.png
│           ├── favicon.ico
│           ├── index.jsp
│           ├── RELEASE-NOTES.txt
│           ├── tomcat.css
│           ├── tomcat.gif
│           ├── tomcat.png
│           ├── tomcat-power.gif
│           ├── tomcat.svg
│           └── WEB-INF
│               └── web.xml
└── tomcat2
    └── webapp
        └── ROOT
            ├── asf-logo-wide.svg
            ├── bg-button.png
            ├── bg-middle.png
            ├── bg-nav-item.png
            ├── bg-nav.png
            ├── bg-upper.png
            ├── favicon.ico
            ├── index.jsp
            ├── RELEASE-NOTES.txt
            ├── tomcat.css
            ├── tomcat.gif
            ├── tomcat.png
            ├── tomcat-power.gif
            ├── tomcat.svg
            └── WEB-INF
                └── web.xml
```

- docker-compose.yaml 文件配置
```yaml
version: "3"
services:
  nginx:
    image: nginx:1.18
    container_name: nginx
    ports:
      - "88:80"
      - "443:443"
    # 将./nginx/nginx.conf 文件映射到容器/etc/nginx/conf.d/default.conf 文件中
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - tomcat1
      - tomcat2
    networks:
      app-network:
        ipv4_address: 172.11.0.8  # IP 地址

  tomcat1:
    image: tomcat:8.5.24
    container_name: tomcat1
    ports:
      - "8088:8080"
    # 将./tomcat1/webapp 文件映射到容器/usr/local/tomcat/webapps 文件中
    volumes:
      - ./tomcat1/webapp:/usr/local/tomcat/webapps
    networks:
      app-network:
        ipv4_address: 172.11.0.9   # IP 地址
  
  tomcat2:
    image: tomcat:8.5.24
    container_name: tomcat2
    ports:
      - "8089:8080"
    # 将./tomcat1/webapp 文件映射到容器/usr/local/tomcat/webapps 文件中
    volumes:
      - ./tomcat2/webapp:/usr/local/tomcat/webapps
    networks:
      app-network:
        ipv4_address: 172.11.0.10   # IP 地址
# 添加容器网络用于连接tomcat
networks:
  app-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.11.0.0/16   # 网段
          gateway: 172.11.0.1    # 网关
```
nginx.conf 文件配置
```
# 添加tomcat服务组
upstream tomcat {
    server 172.11.0.9:8080; # tomcat IP:port
    server 172.11.0.10:8080; # tomcat IP:port
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://tomcat;
    }
}

```

- tomcat配置文件只改了主页文件分别为tomcat1和tomcat2
<a name="Zx4V2"></a>
## 2.项目部署
在 LoadBalance-nginx-tomcat 目录下:

- 启动服务
```bash
docker-compose -f docker-compose.yaml up -d
```

- 访问 http://IP:88 测试是否在tomcat1和tomcat2中来回变化
