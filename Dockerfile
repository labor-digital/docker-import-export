FROM ubuntu

MAINTAINER LABOR digital <info@labor.digital>

RUN apt-get update
RUN apt-get install -y vim
RUN apt-get install -y mysql-client
RUN apt-get install -y curl
RUN apt-get install -y netcat

COPY import.sh /opt/import.sh
RUN chmod +x /opt/import.sh

ENTRYPOINT ["/opt/import.sh"]