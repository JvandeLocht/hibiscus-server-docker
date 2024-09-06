
FROM ubuntu:20.04

ENV HIBISCUS_VERSION=2.10.20

RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install default-jre
RUN apt-get -y install postgresql-client
RUN apt-get -y install mysql-server

RUN apt-get -y install wget unzip 
RUN wget https://www.willuhn.de/products/hibiscus-server/releases/hibiscus-server-${HIBISCUS_VERSION}.zip
RUN unzip hibiscus-server-${HIBISCUS_VERSION}.zip -d / && rm hibiscus-server-${HIBISCUS_VERSION}.zip

ADD wrap.sh /wrap
RUN ["chmod", "+x", "/wrap"]
ENTRYPOINT ["/wrap"]

EXPOSE 8080 
VOLUME [ "/hibiscus-server" ]
