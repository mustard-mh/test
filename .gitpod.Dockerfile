FROM ubuntu
RUN apt update && apt install sudo ca-certificates -y

USER root
RUN sudo echo "%gitpod ALL=PASSWD:ALL" >> /etc/sudoers
