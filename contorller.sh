#!/bin/bash
######################################
###### Script install Openstack ######
###### Version 1.0              ######
###### VuTH                     ######
######################################

source config.cfg
source prepareServer.sh


read -n 1 -p "Press [1,2,3] to install Node Controller :  " choose
echo ""

case $choose in
 1) hostName=CONTROLLER01
    ipmanagement=$ipCtrl01
    
        ;;
 2) hostName=CONTROLLER02
    ipmanagement=$ipCtrl02
    
        ;;
 3) hostName=CONTROLLER03
    ipmanagement=$ipCtrl03
    
        ;;
esac

######## Basic config ##########
prepareServer #run function in prepareServer.sh

######## Optimize Sysctl ##########
echo "============= Config Sysctl ============="
sysctl_config=/etc/sysctl.conf
test -f $sysctl_config.orig \
|| mv $sysctl_config $sysctl_config.orig
cat > $sysctl_config <<EOF
net.ipv4.tcp_keepalive_time = 7200
net.ipv4.ip_local_port_range = 1024 65023 # increase number of ports
net.ipv4.tcp_tw_reuse = 1 #reuse Time-Wait sockets
net.ipv4.tcp_max_syn_backlog = 40000 #increase the number of outstanding syn requests
net.ipv4.tcp_max_tw_buckets = 400000 #Maximal number of timewait sockets
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.all.rp_filter=0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
net.bridge.bridge-nf-call-ip6tables = 0
net.bridge.bridge-nf-call-iptables = 0
net.bridge.bridge-nf-call-arptables = 0
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
vm.dirty_background_ratio = 50
vm.dirty_ratio = 80
vm.swappiness = 1
net.netfilter.nf_conntrack_max = 231072
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_max_tw_buckets = 400000
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_wmem = 4096 65536 16777216
vm.min_free_kbytes = 65536
vm.overcommit_memory = 1
net.core.rmem_max = 2621440
net.core.wmem_max = 2621440
net.core.rmem_default = 2621440
net.core.wmem_default = 2621440
net.core.optmem_max = 2621440
net.core.netdev_max_backlog = 300000
net.core.somaxconn = 40960
EOF
sysctl -p

######## ADD HOST ##########
tmp=$ipFirstcompute
for ((i=1; i <= $numberOfcompute; i++))
do

done

cat >> /etc/hosts <<EOF 
$ipHA01      HA01
$ipHA02      HA02
$ipCtrl01      CONTROLLER01
$ipCtrl02      CONTROLLER02
$ipCtrl03      CONTROLLER03
$ipNetwork01      NETWORK01
$ipNetwork02      NETWORK02
10.200.1.1      COMPUTE01
10.200.1.2      COMPUTE02
10.200.1.3      COMPUTE03
10.200.1.4      COMPUTE04
10.200.1.5      COMPUTE05
10.200.1.6      COMPUTE06
10.200.1.7      COMPUTE07
10.200.1.8      COMPUTE08
10.200.1.9      COMPUTE09
10.200.1.10      COMPUTE10
EOF

######## Prepare Openstack ##########
yum install $repoOpenstack -y

## Config MaraDB Galera ##
yum install -y mariadb-galera-server xinetd rsync





