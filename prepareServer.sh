#!/bin/bash
######################################
###### Script install Openstack ######
###### Version 1.0              ######
###### VuTH                     ######
######################################

# This script will setup hostname , disable some services (NetworkManager, firewalld)
#and install some basic package (ntp, collectd,epel-release,iptables, etc.....),
#and config NTP to sync time from global on Node VPN and other nodes will sync time from Node VPN.

prepareServer() {
    echo "============= Basic Config  ============="
    yum update -y
    hostname $hostName
    echo $hostName > /etc/hostname
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    systemctl disable NetworkManager
    systemctl disable firewalld
    systemctl stop firewalld NetworkManager
    yum install bash-completion epel-release vim iptables-services sysstat tcpdump telnet  -y
    yum install ntp collectd iftop -y
    systemctl enable iptables collectd ntpd network
    systemctl start iptables ntpd
    setupNTP
}

setupNTP() {
    echo "============= Config NTP  ============="
    ntp_config=/etc/ntp.conf
    test -f $ntp_config.orig \
    || mv $ntp_config $ntp_config.orig
    cat $ntp_config.orig | grep -v ^# | grep -v ^$ > $ntp_config
    
    if [ `hostname` == "VPN" ]
    then
        sed -i 's!server 0.centos.pool.ntp.org iburst!server 0.vn.pool.ntp.org iburst!g' /etc/ntp.conf 
        sed -i 's!server 1.centos.pool.ntp.org iburst!server 1.asia.pool.ntp.org iburst!g' /etc/ntp.conf 
        sed -i 's!server 2.centos.pool.ntp.org iburst!server 2.asia.pool.ntp.org iburst!g' /etc/ntp.conf
    else
        sed -i 's!server 0.centos.pool.ntp.org iburst!#server 0.centos.pool.ntp.org iburst!g' /etc/ntp.conf
        sed -i 's!server 1.centos.pool.ntp.org iburst!#server 1.centos.pool.ntp.org iburst!g' /etc/ntp.conf
        sed -i 's!server 2.centos.pool.ntp.org iburst!#server 2.centos.pool.ntp.org iburst!g' /etc/ntp.conf
        sed -i 's!server 3.centos.pool.ntp.org iburst!#server 3.centos.pool.ntp.org iburst!g' /etc/ntp.conf
        sed -i 's!restrict default nomodify notrap nopeer noquery!restrict default nomodify notrap!g' /etc/ntp.conf
    fi
    
    systemctl restart ntpd
}