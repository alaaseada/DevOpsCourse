FROM  ubuntu:24.04
RUN apt-get update 
RUN apt install docker.io -y
RUN systemctl start docker 
RUN systemctl enable docker
RUN docker --version