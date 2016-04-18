#!/bin/bash
######################################
###### Script install Openstack ######
###### Version 1.0              ######
###### VuTH                     ######
######################################

source prepareServer.sh
source config.cfg

read -n 1 -p "Press 1 to install HA01 or 2 to install HA02:  " choose
echo ""

case $choose in
 1) hostName=HA01
    ipmanagement=$ipHA01
    ipmanagementPeer=$ipHA02
        ;;
 2) hostName=HA02
    ipmanagement=$ipHA02
    ipmanagementPeer=$ipHA01
        ;;
esac


######## Basic config ##########
prepareServer #run function in prepareServer.sh

yum install haproxy keepalived -y
systemctl enable  haproxy keepalived   
systemctl start iptables

grep HA /etc/hosts
if [ $? == 1 ]
then
cat >> /etc/hosts <<EOF 
$ipHA01      HA01
$ipHA02      HA02
EOF
fi

######## Set non-local binding and optimize network ##########
echo "============= Config Sysctl ============="
sysctl_config=/etc/sysctl.conf
test -f $sysctl_config.orig \
|| mv $sysctl_config $sysctl_config.orig
cat > $sysctl_config <<EOF
net.ipv4.ip_forward = 1 
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.tcp_keepalive_time = 7200
net.ipv4.ip_local_port_range = 1024 65023 # increase number of ports
net.ipv4.tcp_tw_reuse = 1 #reuse Time-Wait sockets
net.ipv4.tcp_max_syn_backlog = 40000 #increase the number of outstanding syn requests
net.ipv4.tcp_max_tw_buckets = 400000 #Maximal number of timewait sockets
EOF
sysctl -p

######## Config HAProxy ##########
echo "============= Config HAProxy ============="
haproxy_config=/etc/haproxy/haproxy.cfg
test -f $haproxy_config.orig \
|| mv $haproxy_config $haproxy_config.orig

cat > $haproxy_config <<EOF
global
  chroot  /var/lib/haproxy
  daemon
  group  haproxy
  maxconn  40000
  pidfile  /var/run/haproxy.pid
  user  haproxy

defaults
  log  global
  maxconn  40000
  option  redispatch
  retries  3
  timeout  http-request 1m
  timeout  queue 5m
  timeout  connect 10s
  timeout  client 5m
  timeout  server 5m
  timeout  check 10s

listen webinterface    # Web HAproxy, you can check health service from here
        bind 0.0.0.0:8000
        mode http
        stats enable
        stats uri /
        stats realm Strictly\ Private
        stats auth admin:p@&&vv0rdp@&&vv0rd

listen dashboard_cluster
  bind 0.0.0.0:80
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 $ipCtrl01:80 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:80 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:80 backup check inter 2000 rise 2 fall 5

listen galera_cluster
  bind 0.0.0.0:3306
  balance  source
  option  httpchk # check http return code via port 9200
  timeout client  3h
  timeout server  3h
  server controller01 $ipCtrl01:3306 check port 9200 inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:3306 backup check port 9200 inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:3306 backup check port 9200 inter 2000 rise 2 fall 5

listen glance_api_cluster
  bind 0.0.0.0:9292
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 $ipCtrl01:9292 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:9292 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:9292 backup check inter 2000 rise 2 fall 5

listen glance_registry_cluster
  bind 0.0.0.0:9191
  balance  source
  option  tcpka
  option  tcplog
  server controller01 $ipCtrl01:9191 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:9191 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:9191 backup check inter 2000 rise 2 fall 5

listen keystone_admin_cluster
  bind 0.0.0.0:35357
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 $ipCtrl01:35357 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:35357 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:35357 backup check inter 2000 rise 2 fall 5

listen keystone_public_internal_cluster
  bind 0.0.0.0:5000
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 $ipCtrl01:5000 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:5000 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:5000 backup check inter 2000 rise 2 fall 5

listen nova_ec2_api_cluster
  bind 0.0.0.0:8773
  balance  source
  option  tcpka
  option  tcplog
  server controller01 $ipCtrl01:8773 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:8773 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:8773 backup check inter 2000 rise 2 fall 5
listen nova_compute_api_cluster
  bind 0.0.0.0:8774
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 $ipCtrl01:8774 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:8774 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:8774 backup check inter 2000 rise 2 fall 5

listen nova_metadata_api_cluster
  bind 0.0.0.0:8775
  balance  source
  option  tcpka
  option  tcplog
  server controller01 $ipCtrl01:8775 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:8775 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:8775 backup check inter 2000 rise 2 fall 5

listen cinder_api_cluster
  bind 0.0.0.0:8776
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 $ipCtrl01:8776 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:8776 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:8776 backup check inter 2000 rise 2 fall 5

listen ceilometer_api_cluster
  bind 0.0.0.0:8777
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 $ipCtrl01:8774 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:8774 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:8774 backup check inter 2000 rise 2 fall 5

listen vnc_cluster
  bind 0.0.0.0:6080
  balance  source
  option  tcpka
  option  tcplog
  timeout tunnel 1h 
  server controller01 $ipCtrl01:6080 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:6080 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:6080 backup check inter 2000 rise 2 fall 5

listen neutron_api_cluster
  bind 0.0.0.0:9696
  balance  source
  option  tcpka
  option  httpchk
  option  tcplog
  server controller01 $ipCtrl01:9696 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:9696 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:9696 backup check inter 2000 rise 2 fall 5

listen rabbitmq
  bind 0.0.0.0:5672
  balance  source
  timeout client  3h
  timeout server  3h
  option clitcpka
  mode tcp
  server controller01 $ipCtrl01:5672 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:5672 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:5672 backup check inter 2000 rise 2 fall 5

listen memcached
  bind 0.0.0.0:11211
  balance  source
  timeout client  3h
  timeout server  3h
  mode tcp
  server controller01 $ipCtrl01:11211 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:11211 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:11211 backup check inter 2000 rise 2 fall 5

listen api_backup
  bind 0.0.0.0:6970
  balance  source
  option  tcpka
  option  tcplog
  option  forwardfor
  mode tcp
  server controller01 $ipCtrl01:6970 check inter 2000 rise 2 fall 5
  server controller02 $ipCtrl02:6970 backup check inter 2000 rise 2 fall 5
  server controller03 $ipCtrl03:6970 backup check inter 2000 rise 2 fall 5

#listen swift_proxy_cluster
#  bind 0.0.0.0:8080
#  balance  source
# option  tcplog
#  option  tcpka
#  server controller01 $ipCtrl01:8080 check inter 2000 rise 2 fall 5
#  server controller02 $ipCtrl02:8080 backup check inter 2000 rise 2 fall 5
#  server controller03 $ipCtrl03:8080 backup check inter 2000 rise 2 fall 5
EOF


######## Config Keepalived ##########
echo "============= Config Keepalived ============="
keepalived_config=/etc/keepalived/keepalived.conf
test -f $keepalived_config.orig \
|| mv $keepalived_config $keepalived_config.orig

cat > $keepalived_config <<EOF
global_defs {
        lvs_id $hostName
}

vrrp_sync_group SyncGroup01 {
        group {
                HA
        }
}

vrrp_script check_haproxy {
        script "killall -0 haproxy"   # check service
        interval 2
        weight 2
}

vrrp_instance HA {
        state EQUAL
        interface bond0    # card mang su dung IP VIP
        virtual_router_id 10
        priority 100
        advert_int 1
        unicast_src_ip $ipmanagement   # Unicast specific option, this is the IP of the interface keepalived listens on
        unicast_peer {                 # Unicast specific option, this is the IP of the peer instance
                $ipmanagementPeer
        }

        virtual_ipaddress {
                $ipVIP    # ip VIP
        }
        track_script {
                check_haproxy
        }
}
EOF



######## Config IPTABLES ##########
echo "============= Config IPTABLES ============="
iptables -I INPUT 5 -s $ipmanagementPeer/$netmask -p vrrp  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 80 -m comment --comment "Dashboard"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 3306 -m comment --comment "mysql"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 9292 -m comment --comment "Glance API"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 9191 -m comment --comment "Glance Registry"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 35357 -m comment --comment "Keystone ADMIN"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 5000 -m comment --comment "Keystone public"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 8774 -m comment --comment "Nova API"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 8775 -m comment --comment "Nova Metadata API"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 8776 -m comment --comment "Cinder API"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 8777 -m comment --comment "Ceilometer API"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 6080 -m comment --comment "VNC Proxy"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 9696 -m comment --comment "Neutron API"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 11211 -m comment --comment "Memcache"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 5672 -m comment --comment "Rabbitmq"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 6970 -m comment --comment "API Backup"  -j ACCEPT
iptables -I INPUT 5 -s $rangeManagement -m state --state NEW -p tcp --dport 8000 -m comment --comment "HAProxy Dashboard"  -j ACCEPT
iptables-save > /etc/sysconfig/iptables

######## Config Collectd ##########
echo "============= Config Collectd ============="
collectd_config=/etc/collectd.conf
test -f $collectd_config.orig \
|| mv $collectd_config $collectd_config.orig

cat > $collectd_config <<EOF
Hostname    "$hostName"
Interval     30
Timeout      5

<LoadPlugin memory>
      Interval 300
</LoadPlugin>

<LoadPlugin df>
      Interval 300
</LoadPlugin>

LoadPlugin disk
LoadPlugin cpu
LoadPlugin interface
LoadPlugin load
LoadPlugin write_graphite
LoadPlugin aggregation
LoadPlugin "match_regex"
<Chain "PostCache">
  <Rule> # Send "cpu" values to the aggregation plugin.
    <Match regex>
      Plugin "^cpu$"
      PluginInstance "^[0-9]+$"
    </Match>
    <Target write>
      Plugin "aggregation"
    </Target>
    Target stop
  </Rule>
  Target "write"
</Chain>

<Plugin "aggregation">
  <Aggregation>
    Plugin "cpu"
    Type "cpu"
    GroupBy "Host"
    GroupBy "TypeInstance"
    CalculateAverage true
  </Aggregation> 
</Plugin>

<Plugin df>
       MountPoint "/"
       IgnoreSelected false
       ReportByDevice false
       ReportReserved false
       ReportInodes true
       ValuesAbsolute false
       ValuesPercentage true
</Plugin>

<Plugin interface>
       IgnoreSelected false
       Interface "bond0"
</Plugin>

<Plugin write_graphite>
  <Node "Monitor">
    Host "118.69.190.16"
    Port "2003"
    Protocol "tcp"
    LogSendErrors true
    Prefix "PublicCloud.server."
    StoreRates true
    AlwaysAppendDS false
    EscapeCharacter "_"
  </Node>
</Plugin>
EOF

######## Disable SELinux ##########
echo "============= Config SELinux ============="
if ! grep -i SELINUX=disabled /etc/selinux/config
then 
sed -i 's!SELINUX=.*!SELINUX=disabled!g' /etc/selinux/config 
init 6
fi

######## Start Services ##########
echo "============= Starting Services ============="
systemctl restart keepalived haproxy collectd

