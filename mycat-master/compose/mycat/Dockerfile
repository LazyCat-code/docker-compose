# 基于java:8-jre 镜像构建mycat
FROM java:8-jre
ENV mycat-version Mycat-server-1.6.5-release-20180122220033-linux.tar.gz
# 添加组名
USER root
COPY ./Mycat-server-1.6.5-release-20180122220033-linux.tar.gz /
RUN tar -zxf /Mycat-server-1.6.5-release-20180122220033-linux.tar.gz
# 设置容器环境变量
ENV MYCAT_HOME=/mycat
ENV PATH=$PATH:$MYCAT_HOME/bin
# 创建目录
WORKDIR $MYCAT_HOME/bin
RUN chmod u+x ./mycat
# 暴露端口
EXPOSE 8066 9066
# 启动mycat服务
CMD ["./mycat","console"]
