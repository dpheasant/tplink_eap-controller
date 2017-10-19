FROM centos:centos7

## eap-controller package url and home directory
ENV EAP_PACKAGE_URL='http://static.tp-link.com/EAP_Controller_v2.4.8_linux_x64.tar.gz'
ENV EAP_HOME=/opt/tplink/EAP_Controller

## install prereq software
##    curl for getting the software via http
##    net-tools for netstat (required by EAP Controller)
RUN yum -y install curl net-tools

## dowload software, extract, and install...
RUN mkdir  -p ${EAP_HOME} &&\
    curl   -o ${EAP_HOME}/EAP_Controller.tgz ${EAP_PACKAGE_URL} &&\
    tar xvzpf ${EAP_HOME}/EAP_Controller.tgz -C ${EAP_HOME}/

## install the runContainer script and make it executable
COPY runContainer.sh /runContainer
RUN  chmod +x /runContainer

CMD /runContainer