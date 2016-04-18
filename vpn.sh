#!/bin/bash
######################################
###### Script install Openstack ######
###### Version 1.0              ######
###### VuTH                     ######
######################################

source prepareServer.sh
source config.cfg

hostName=VPN

######## Basic config ##########
prepareServer #run function in prepareServer.sh

######## Config Openvpn with mode bridge ##########
yum install openvpn easy-rsa bridge-utils -y

#Config bridge network
cat > /etc/sysconfig/network-scripts/ifcfg-$interfacevpnlan <<EOF
TYPE=Ethernet
BOOTPROTO=none
NAME=$interfacevpnlan
DEVICE=$interfacevpnlan
ONBOOT=yes
BRIDGE=br0
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-br0 <<EOF
TYPE=Bridge
BOOTPROTO=none
NAME=br0
DEVICE=br0
ONBOOT=yes
IPADDR=$ipVPNlan
PREFIX=$netmask
EOF

ifup br0
ifup $interfacevpnlan


#Config OpenVPN
vpn_config=/etc/openvpn/server.conf

cat > $vpn_config.orig <<EOF
#################################################
# Sample OpenVPN 2.0 config file for            #
# multi-client server.                          #
#                                               #
# This file is for the server side              #
# of a many-clients <-> one-server              #
# OpenVPN configuration.                        #
#                                               #
# OpenVPN also supports                         #
# single-machine <-> single-machine             #
# configurations (See the Examples page         #
# on the web site for more info).               #
#                                               #
# This config should work on Windows            #
# or Linux/BSD systems.  Remember on            #
# Windows to quote pathnames and use            #
# double backslashes, e.g.:                     #
# "C:\\Program Files\\OpenVPN\\config\\foo.key" #
#                                               #
# Comments are preceded with '#' or ';'         #
#################################################

# Which local IP address should OpenVPN
# listen on? (optional)
;local a.b.c.d

# Which TCP/UDP port should OpenVPN listen on?
# If you want to run multiple OpenVPN instances
# on the same machine, use a different port
# number for each one.  You will need to
# open up this port on your firewall.
port 1194

# TCP or UDP server?
;proto tcp
proto udp

# "dev tun" will create a routed IP tunnel,
# "dev tap" will create an ethernet tunnel.
# Use "dev tap0" if you are ethernet bridging
# and have precreated a tap0 virtual interface
# and bridged it with your ethernet interface.
# If you want to control access policies
# over the VPN, you must create firewall
# rules for the the TUN/TAP interface.
# On non-Windows systems, you can give
# an explicit unit number, such as tun0.
# On Windows, use "dev-node" for this.
# On most systems, the VPN will not function
# unless you partially or fully disable
# the firewall for the TUN/TAP interface.
;dev tap
dev tun

# Windows needs the TAP-Win32 adapter name
# from the Network Connections panel if you
# have more than one.  On XP SP2 or higher,
# you may need to selectively disable the
# Windows firewall for the TAP adapter.
# Non-Windows systems usually don't need this.
;dev-node MyTap

# SSL/TLS root certificate (ca), certificate
# (cert), and private key (key).  Each client
# and the server must have their own cert and
# key file.  The server and all clients will
# use the same ca file.
#
# See the "easy-rsa" directory for a series
# of scripts for generating RSA certificates
# and private keys.  Remember to use
# a unique Common Name for the server
# and each of the client certificates.
#
# Any X509 key management system can be used.
# OpenVPN can also use a PKCS #12 formatted key file
# (see "pkcs12" directive in man page).
ca ca.crt
cert server.crt
key server.key  # This file should be kept secret

# Diffie hellman parameters.
# Generate your own with:
#   openssl dhparam -out dh2048.pem 2048
dh dh2048.pem

# Network topology
# Should be subnet (addressing via IP)
# unless Windows clients v2.0.9 and lower have to
# be supported (then net30, i.e. a /30 per client)
# Defaults to net30 (not recommended)
;topology subnet

# Configure server mode and supply a VPN subnet
# for OpenVPN to draw client addresses from.
# The server will take 10.8.0.1 for itself,
# the rest will be made available to clients.
# Each client will be able to reach the server
# on 10.8.0.1. Comment this line out if you are
# ethernet bridging. See the man page for more info.
server 10.8.0.0 255.255.255.0

# Maintain a record of client <-> virtual IP address
# associations in this file.  If OpenVPN goes down or
# is restarted, reconnecting clients can be assigned
# the same virtual IP address from the pool that was
# previously assigned.
ifconfig-pool-persist ipp.txt

# Configure server mode for ethernet bridging.
# You must first use your OS's bridging capability
# to bridge the TAP interface with the ethernet
# NIC interface.  Then you must manually set the
# IP/netmask on the bridge interface, here we
# assume 10.8.0.4/255.255.255.0.  Finally we
# must set aside an IP range in this subnet
# (start=10.8.0.50 end=10.8.0.100) to allocate
# to connecting clients.  Leave this line commented
# out unless you are ethernet bridging.
;server-bridge 10.8.0.4 255.255.255.0 10.8.0.50 10.8.0.100

# Configure server mode for ethernet bridging
# using a DHCP-proxy, where clients talk
# to the OpenVPN server-side DHCP server
# to receive their IP address allocation
# and DNS server addresses.  You must first use
# your OS's bridging capability to bridge the TAP
# interface with the ethernet NIC interface.
# Note: this mode only works on clients (such as
# Windows), where the client-side TAP adapter is
# bound to a DHCP client.
;server-bridge

# Push routes to the client to allow it
# to reach other private subnets behind
# the server.  Remember that these
# private subnets will also need
# to know to route the OpenVPN client
# address pool (10.8.0.0/255.255.255.0)
# back to the OpenVPN server.
;push "route 192.168.10.0 255.255.255.0"
;push "route 192.168.20.0 255.255.255.0"

# To assign specific IP addresses to specific
# clients or if a connecting client has a private
# subnet behind it that should also have VPN access,
# use the subdirectory "ccd" for client-specific
# configuration files (see man page for more info).

# EXAMPLE: Suppose the client
# having the certificate common name "Thelonious"
# also has a small subnet behind his connecting
# machine, such as 192.168.40.128/255.255.255.248.
# First, uncomment out these lines:
;client-config-dir ccd
;route 192.168.40.128 255.255.255.248
# Then create a file ccd/Thelonious with this line:
#   iroute 192.168.40.128 255.255.255.248
# This will allow Thelonious' private subnet to
# access the VPN.  This example will only work
# if you are routing, not bridging, i.e. you are
# using "dev tun" and "server" directives.

# EXAMPLE: Suppose you want to give
# Thelonious a fixed VPN IP address of 10.9.0.1.
# First uncomment out these lines:
;client-config-dir ccd
;route 10.9.0.0 255.255.255.252
# Then add this line to ccd/Thelonious:
#   ifconfig-push 10.9.0.1 10.9.0.2

# Suppose that you want to enable different
# firewall access policies for different groups
# of clients.  There are two methods:
# (1) Run multiple OpenVPN daemons, one for each
#     group, and firewall the TUN/TAP interface
#     for each group/daemon appropriately.
# (2) (Advanced) Create a script to dynamically
#     modify the firewall in response to access
#     from different clients.  See man
#     page for more info on learn-address script.
;learn-address ./script

# If enabled, this directive will configure
# all clients to redirect their default
# network gateway through the VPN, causing
# all IP traffic such as web browsing and
# and DNS lookups to go through the VPN
# (The OpenVPN server machine may need to NAT
# or bridge the TUN/TAP interface to the internet
# in order for this to work properly).
;push "redirect-gateway def1 bypass-dhcp"

# Certain Windows-specific network settings
# can be pushed to clients, such as DNS
# or WINS server addresses.  CAVEAT:
# http://openvpn.net/faq.html#dhcpcaveats
# The addresses below refer to the public
# DNS servers provided by opendns.com.
;push "dhcp-option DNS 208.67.222.222"
;push "dhcp-option DNS 208.67.220.220"

# Uncomment this directive to allow different
# clients to be able to "see" each other.
# By default, clients will only see the server.
# To force clients to only see the server, you
# will also need to appropriately firewall the
# server's TUN/TAP interface.
;client-to-client

# Uncomment this directive if multiple clients
# might connect with the same certificate/key
# files or common names.  This is recommended
# only for testing purposes.  For production use,
# each client should have its own certificate/key
# pair.
#
# IF YOU HAVE NOT GENERATED INDIVIDUAL
# CERTIFICATE/KEY PAIRS FOR EACH CLIENT,
# EACH HAVING ITS OWN UNIQUE "COMMON NAME",
# UNCOMMENT THIS LINE OUT.
;duplicate-cn

# The keepalive directive causes ping-like
# messages to be sent back and forth over
# the link so that each side knows when
# the other side has gone down.
# Ping every 10 seconds, assume that remote
# peer is down if no ping received during
# a 120 second time period.
keepalive 10 120

# For extra security beyond that provided
# by SSL/TLS, create an "HMAC firewall"
# to help block DoS attacks and UDP port flooding.
#
# Generate with:
#   openvpn --genkey --secret ta.key
#
# The server and each client must have
# a copy of this key.
# The second parameter should be '0'
# on the server and '1' on the clients.
;tls-auth ta.key 0 # This file is secret

# Select a cryptographic cipher.
# This config item must be copied to
# the client config file as well.
;cipher BF-CBC        # Blowfish (default)
;cipher AES-128-CBC   # AES
;cipher DES-EDE3-CBC  # Triple-DES

# Enable compression on the VPN link.
# If you enable it here, you must also
# enable it in the client config file.
comp-lzo

# The maximum number of concurrently connected
# clients we want to allow.
;max-clients 100

# It's a good idea to reduce the OpenVPN
# daemon's privileges after initialization.
#
# You can uncomment this out on
# non-Windows systems.
;user nobody
;group nobody

# The persist options will try to avoid
# accessing certain resources on restart
# that may no longer be accessible because
# of the privilege downgrade.
persist-key
persist-tun

# Output a short status file showing
# current connections, truncated
# and rewritten every minute.
status openvpn-status.log

# By default, log messages will go to the syslog (or
# on Windows, if running as a service, they will go to
# the "\Program Files\OpenVPN\log" directory).
# Use log or log-append to override this default.
# "log" will truncate the log file on OpenVPN startup,
# while "log-append" will append to it.  Use one
# or the other (but not both).
;log         openvpn.log
;log-append  openvpn.log

# Set the appropriate level of log
# file verbosity.
#
# 0 is silent, except for fatal errors
# 4 is reasonable for general usage
# 5 and 6 can help to debug connection problems
# 9 is extremely verbose
verb 3

# Silence repeating messages.  At most 20
# sequential messages of the same message
# category will be output to the log.
;mute 20
EOF

cat > $vpn_config <<EOF
local $ipVPNwan
port 1194
proto udp
plugin /usr/lib64/openvpn/plugins/openvpn-plugin-auth-pam.so /etc/pam.d/login
dev tap19
ca /etc/openvpn/easy-rsa/keys/ca.crt
cert /etc/openvpn/easy-rsa/keys/server.crt
key /etc/openvpn/easy-rsa/keys/server.key
dh /etc/openvpn/easy-rsa/keys/dh2048.pem
;ifconfig-pool-persist ipp.txt
;push "route 192.168.1.0 255.255.255.0 10.200.0.1"
server-bridge $ipVPNlan $netmask $rangeVPN
client-to-client
duplicate-cn
keepalive 10 120
comp-lzo
user nobody
group nobody
persist-key
persist-tun
status openvpn-status.log
log         openvpn.log
log-append  openvpn.log
verb 3
script-security 3 system
EOF

mkdir -p /etc/openvpn/easy-rsa/keys

cat > /etc/openvpn/easy-rsa/keys/ca.crt <<EOF
-----BEGIN CERTIFICATE-----
MIIE3DCCA8SgAwIBAgIJAP5Tfyg/8OiRMA0GCSqGSIb3DQEBCwUAMIGkMQswCQYD
VQQGEwJWTjEMMAoGA1UECBMDSENNMRQwEgYDVQQHEwtIbyBDaGkgTWluaDEUMBIG
A1UEChMLRlBUIFRlbGVjb20xGDAWBgNVBAsTD1N5c3RlbSBFbmdpbmVlcjEPMA0G
A1UEAxMGY2xpZW50MQ8wDQYDVQQpEwZzZXJ2ZXIxHzAdBgkqhkiG9w0BCQEWEHZ1
dGg2QGZwdC5jb20udm4wHhcNMTYwNDE3MDYzODAwWhcNMjYwNDE1MDYzODAwWjCB
pDELMAkGA1UEBhMCVk4xDDAKBgNVBAgTA0hDTTEUMBIGA1UEBxMLSG8gQ2hpIE1p
bmgxFDASBgNVBAoTC0ZQVCBUZWxlY29tMRgwFgYDVQQLEw9TeXN0ZW0gRW5naW5l
ZXIxDzANBgNVBAMTBmNsaWVudDEPMA0GA1UEKRMGc2VydmVyMR8wHQYJKoZIhvcN
AQkBFhB2dXRoNkBmcHQuY29tLnZuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAn2fjNKCeXmPGblRtDzgvOhXcynmGTmU8q8JP4mHlzZcxQMbPsf+Vj9oV
UyfR4py1boqoyxGoNiuvlgfjDvwJwzWuohsmslYiVG+jk1QGrE3jKig6Sd2IxnwO
PS4ooHxMP4U5mFsaKCV+PqlhraeePyAUg5Op+YqAhjxEgDY+8QxrPRG59Je5PjJO
In+qwf0yR67Rvi175fqzvctpcau2usEoyHpquawpWk/ZmvpuzBzN4KdOT2ODJHtl
vMWmGVTQyrr5wpEh4dPjW5SajwfIh0Peety7BwkjOllQBQ7L3etKwVC+R59kCDu3
mCWNJuWC773mqCUIQXb/Xk6yr6pi8wIDAQABo4IBDTCCAQkwHQYDVR0OBBYEFMgi
UthlBILwuf6eZrfA7WFZVsQUMIHZBgNVHSMEgdEwgc6AFMgiUthlBILwuf6eZrfA
7WFZVsQUoYGqpIGnMIGkMQswCQYDVQQGEwJWTjEMMAoGA1UECBMDSENNMRQwEgYD
VQQHEwtIbyBDaGkgTWluaDEUMBIGA1UEChMLRlBUIFRlbGVjb20xGDAWBgNVBAsT
D1N5c3RlbSBFbmdpbmVlcjEPMA0GA1UEAxMGY2xpZW50MQ8wDQYDVQQpEwZzZXJ2
ZXIxHzAdBgkqhkiG9w0BCQEWEHZ1dGg2QGZwdC5jb20udm6CCQD+U38oP/DokTAM
BgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQA8XvaFUl8CR5nSNQmtzSnY
lq3wl47JYBM8w4kA8gC1LpuD2u2MTk9hOm09A7t4hKGuYJpgB5PMsLZ0ZTSxPPzT
OBeCgzAS+xW7LxkgzJmb3iu2yU8g8338Lr+eyGQ5ac4R1HHhkgp+fI0/7wUCGlWg
A2LTbfj13pHGVWOpP0y8/oGVHKdowvfGAlriBolpnnjbkW51HuREZAC34fy4r8tB
AzObMtscNn/CKu8AoMX6sHFufMtyvICygan7qd0rJ3Gf/ILj+zJqb0felrF3mjdC
QEwZqqwcxYpySfBzV3EdP5SXaomWRlTDql0yxRswT/uEjdRBVUAJcfEEXCml4lkd
-----END CERTIFICATE-----
EOF

cat > /etc/openvpn/easy-rsa/keys/server.crt <<EOF
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 1 (0x1)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=VN, ST=HCM, L=Ho Chi Minh, O=FPT Telecom, OU=System Engineer, CN=client/name=server/emailAddress=vuth6@fpt.com.vn
        Validity
            Not Before: Apr 17 06:38:31 2016 GMT
            Not After : Apr 15 06:38:31 2026 GMT
        Subject: C=VN, ST=HCM, L=Ho Chi Minh, O=FPT Telecom, OU=System Engineer, CN=server/name=server/emailAddress=vuth6@fpt.com.vn
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:e4:17:9b:40:d3:6d:69:c6:ca:ee:4f:b2:be:9f:
                    32:b1:31:d0:45:27:d1:59:38:d6:4a:a4:4d:da:53:
                    66:bb:c8:57:93:46:8c:ee:89:b0:05:39:42:90:92:
                    0c:d4:86:5e:8b:a4:d9:87:a0:87:0d:1e:f3:21:48:
                    47:42:37:16:7f:56:1f:d8:55:68:bc:86:03:eb:73:
                    1a:c8:c2:03:33:88:33:84:33:69:4f:15:d6:3f:b1:
                    e4:4a:5b:6a:c0:83:91:8f:5e:0b:f4:a7:2c:b0:5f:
                    55:66:76:8f:be:30:41:d7:10:43:96:e0:fb:14:d1:
                    f4:e0:1d:79:5f:7d:a4:26:f2:44:b1:ac:37:9e:c6:
                    ca:5a:22:5b:cc:e5:07:da:42:dc:4e:7e:37:d0:34:
                    ca:be:61:11:ef:4a:7c:7b:d4:1d:54:3a:ca:38:b6:
                    7f:e4:08:f6:6b:c0:0d:cd:6d:18:80:56:73:52:3a:
                    5e:10:35:45:f8:4a:65:50:c7:aa:98:78:3b:5e:6b:
                    f5:36:b3:9c:92:28:c7:79:e7:20:e3:9b:bb:63:fa:
                    bb:68:73:cf:1c:c2:8b:15:dc:76:aa:82:23:1b:df:
                    6c:eb:09:7b:29:c1:64:da:ac:00:2c:a9:2e:8c:78:
                    98:43:99:88:0f:e2:4b:84:e3:7d:95:56:8f:52:da:
                    ec:6d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            Netscape Cert Type:
                SSL Server
            Netscape Comment:
                Easy-RSA Generated Server Certificate
            X509v3 Subject Key Identifier:
                4A:99:7A:6A:FA:92:02:A9:54:44:5C:C7:D8:79:6D:08:E7:06:B5:B9
            X509v3 Authority Key Identifier:
                keyid:C8:22:52:D8:65:04:82:F0:B9:FE:9E:66:B7:C0:ED:61:59:56:C4:14
                DirName:/C=VN/ST=HCM/L=Ho Chi Minh/O=FPT Telecom/OU=System Engineer/CN=client/name=server/emailAddress=vuth6@fpt.com.vn
                serial:FE:53:7F:28:3F:F0:E8:91

            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Key Usage:
                Digital Signature, Key Encipherment
    Signature Algorithm: sha256WithRSAEncryption
         77:4b:27:33:ef:76:6b:e1:b2:69:13:5a:7b:7b:ff:7f:df:f6:
         65:89:37:8c:87:0f:50:08:32:bb:1c:70:e6:d2:10:69:1d:1d:
         85:d9:c6:b1:cf:33:5f:68:95:42:5f:e5:ef:30:53:ed:fe:17:
         8f:e8:5a:00:a9:c3:9c:ed:3c:ff:e4:25:fc:aa:a8:2b:bd:96:
         40:b1:5a:94:9a:97:3e:36:80:bf:56:d4:07:ed:ae:b8:b2:78:
         53:8a:29:c0:6e:b3:6c:03:bf:51:0f:a9:19:9d:50:ab:bc:9f:
         a3:f7:c7:49:2a:af:9d:c8:a5:7a:fc:96:0e:3f:ef:9e:f8:a6:
         ed:5e:9a:f1:4b:2e:7d:55:85:f0:7d:39:ce:95:08:10:ed:35:
         c0:76:58:5f:0e:10:f9:11:6e:ae:fd:62:d3:0f:10:c8:01:1a:
         db:0a:19:5c:52:28:aa:99:6b:fb:53:18:3f:f1:f1:59:c3:44:
         83:94:77:db:c7:31:06:2d:44:d7:3b:33:51:96:c6:c4:b6:9e:
         a1:60:d0:58:da:e8:44:bf:0d:52:d8:d1:f2:de:8e:6e:6b:2a:
         43:37:8c:46:41:52:2b:03:72:d3:82:44:59:fb:e4:bc:61:0a:
         de:50:e9:68:5a:54:21:c0:f0:8b:31:d2:ad:7e:f4:ce:8f:84:
         de:5e:c9:0e
-----BEGIN CERTIFICATE-----
MIIFPDCCBCSgAwIBAgIBATANBgkqhkiG9w0BAQsFADCBpDELMAkGA1UEBhMCVk4x
DDAKBgNVBAgTA0hDTTEUMBIGA1UEBxMLSG8gQ2hpIE1pbmgxFDASBgNVBAoTC0ZQ
VCBUZWxlY29tMRgwFgYDVQQLEw9TeXN0ZW0gRW5naW5lZXIxDzANBgNVBAMTBmNs
aWVudDEPMA0GA1UEKRMGc2VydmVyMR8wHQYJKoZIhvcNAQkBFhB2dXRoNkBmcHQu
Y29tLnZuMB4XDTE2MDQxNzA2MzgzMVoXDTI2MDQxNTA2MzgzMVowgaQxCzAJBgNV
BAYTAlZOMQwwCgYDVQQIEwNIQ00xFDASBgNVBAcTC0hvIENoaSBNaW5oMRQwEgYD
VQQKEwtGUFQgVGVsZWNvbTEYMBYGA1UECxMPU3lzdGVtIEVuZ2luZWVyMQ8wDQYD
VQQDEwZzZXJ2ZXIxDzANBgNVBCkTBnNlcnZlcjEfMB0GCSqGSIb3DQEJARYQdnV0
aDZAZnB0LmNvbS52bjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOQX
m0DTbWnGyu5Psr6fMrEx0EUn0Vk41kqkTdpTZrvIV5NGjO6JsAU5QpCSDNSGXouk
2Yeghw0e8yFIR0I3Fn9WH9hVaLyGA+tzGsjCAzOIM4QzaU8V1j+x5EpbasCDkY9e
C/SnLLBfVWZ2j74wQdcQQ5bg+xTR9OAdeV99pCbyRLGsN57GyloiW8zlB9pC3E5+
N9A0yr5hEe9KfHvUHVQ6yji2f+QI9mvADc1tGIBWc1I6XhA1RfhKZVDHqph4O15r
9TaznJIox3nnIOObu2P6u2hzzxzCixXcdqqCIxvfbOsJeynBZNqsACypLox4mEOZ
iA/iS4TjfZVWj1La7G0CAwEAAaOCAXUwggFxMAkGA1UdEwQCMAAwEQYJYIZIAYb4
QgEBBAQDAgZAMDQGCWCGSAGG+EIBDQQnFiVFYXN5LVJTQSBHZW5lcmF0ZWQgU2Vy
dmVyIENlcnRpZmljYXRlMB0GA1UdDgQWBBRKmXpq+pICqVREXMfYeW0I5wa1uTCB
2QYDVR0jBIHRMIHOgBTIIlLYZQSC8Ln+nma3wO1hWVbEFKGBqqSBpzCBpDELMAkG
A1UEBhMCVk4xDDAKBgNVBAgTA0hDTTEUMBIGA1UEBxMLSG8gQ2hpIE1pbmgxFDAS
BgNVBAoTC0ZQVCBUZWxlY29tMRgwFgYDVQQLEw9TeXN0ZW0gRW5naW5lZXIxDzAN
BgNVBAMTBmNsaWVudDEPMA0GA1UEKRMGc2VydmVyMR8wHQYJKoZIhvcNAQkBFhB2
dXRoNkBmcHQuY29tLnZuggkA/lN/KD/w6JEwEwYDVR0lBAwwCgYIKwYBBQUHAwEw
CwYDVR0PBAQDAgWgMA0GCSqGSIb3DQEBCwUAA4IBAQB3Sycz73Zr4bJpE1p7e/9/
3/ZliTeMhw9QCDK7HHDm0hBpHR2F2caxzzNfaJVCX+XvMFPt/heP6FoAqcOc7Tz/
5CX8qqgrvZZAsVqUmpc+NoC/VtQH7a64snhTiinAbrNsA79RD6kZnVCrvJ+j98dJ
Kq+dyKV6/JYOP++e+KbtXprxSy59VYXwfTnOlQgQ7TXAdlhfDhD5EW6u/WLTDxDI
ARrbChlcUiiqmWv7Uxg/8fFZw0SDlHfbxzEGLUTXOzNRlsbEtp6hYNBY2uhEvw1S
2NHy3o5uaypDN4xGQVIrA3LTgkRZ++S8YQreUOloWlQhwPCLMdKtfvTOj4TeXskO
-----END CERTIFICATE-----
EOF

cat > /etc/openvpn/easy-rsa/keys/server.key <<EOF
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDkF5tA021pxsru
T7K+nzKxMdBFJ9FZONZKpE3aU2a7yFeTRozuibAFOUKQkgzUhl6LpNmHoIcNHvMh
SEdCNxZ/Vh/YVWi8hgPrcxrIwgMziDOEM2lPFdY/seRKW2rAg5GPXgv0pyywX1Vm
do++MEHXEEOW4PsU0fTgHXlffaQm8kSxrDeexspaIlvM5QfaQtxOfjfQNMq+YRHv
Snx71B1UOso4tn/kCPZrwA3NbRiAVnNSOl4QNUX4SmVQx6qYeDtea/U2s5ySKMd5
5yDjm7tj+rtoc88cwosV3HaqgiMb32zrCXspwWTarAAsqS6MeJhDmYgP4kuE432V
Vo9S2uxtAgMBAAECggEAS3CzXOGREqc5f1DE4d9tuMWtCPJ+f3AZEF7/kPJ8zCcb
MA7plgvcOB4UMhTcQX6fzrgbaoxhnqlZ6OwrBW+K9Vra9YZqOdBpg3pypWvl+ylV
QKhwcEPctPx1cVKDIGFjx3NnqOeSFFOzv0v/hvwXCrbKZCDNarl2sJmPB1Ja9LYU
oqucZjCPp3ZxLfpeclCktt7bdmQSSh6xUE6b2Kb9r4AIVXm6ZqVnkF0IRLhAB9cJ
EaXSNXrPvHoQj3DciZtY3RvwKp+2KsYa/jyFsmM02IIqc6I/S3JXH/gC83d5yg2k
RNl1kaHE3glZpL9zRvpf90gQ2HonlSEagWiKdPBh0QKBgQD7NvmERu+xBbTyZRVU
N+Qlt0x+CuJQ05jSBsGj0lJRHqc9iFgocdLWvMPxmdD1KDZlVk2aW8++BrejpUmG
+aW5V+Wh9rDs+aevipGi0PZkert+nC0Ga+5uaionj6ffRHKmcC+GAeTb9DniNcD4
IjFcTZfpyCQdAr80SXQgmG/p3wKBgQDob+B8/pcc00re78bc0gwNeQ82SKh+kXAC
gbD/4Yx+a73hL4R3eKN2BQEECmjTRPTRdcXi/JGv6whf9RPk2t4BbfkzYRSs671y
ZdIRemyQjHocv0bkHiwvupZzD8T92/d+yRwRFgMZ7tQZW3h8olWDdu1ZrfwRIf9x
R7D4/FVLMwKBgDoxANmISQubg8/GZItuqvWloR1tTgFlEnhMQly9Yn4R+LGDPNCZ
lTpS3ZzAgavYVclhlXZVICknizBoIEEY4S+u0a2T5GXwasx578RkXT7nQzlP2gor
xD5lb0BcwYkxZNFzGT8UfzwINcRVqU6RNRfpjXAFAYCK21m0TiciyIHHAoGBAMrl
nhh+RHqtFpY0yGrKECtSmazREAQsAJKvk0pKINHaSw3e5MtFS6siAxj73TVO5EZT
gEH8J1Bg4hahYJRNWa31yarH+7xWrDDIIO+Q5mPnvFCLx94pWHjxb5NRGKxg71KF
SzK+/EYO7KaV6j8hlXQExHucHIT4IHtKEXnHCs1xAoGBALVRJMbzffzMzgPaSVPw
risxh2v1U6+lAA/w0CXJdE2vBgJBfPxmRftBZimk5ySdwaDHXk69x9GsWzI+Vd1a
w2/w6EFYe0CXTBfqQTMtu2yA/ih68HHKK/kb3IBS3t8+N3g/n7Pm4LB0yyuR7mTL
32mC956Uf5nJkQwz7VhPMo0q
-----END PRIVATE KEY-----
EOF

cat > /etc/openvpn/easy-rsa/keys/dh2048.pem <<EOF
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAgiZ8c7AMPM42bp5fPWFzDamClmQ1Urs5gzyAZzz6OFrVa2OoI26f
vOluDo6dtE+IgIYjBMwzviJnpa+yma3OddFeZGCGD5cfqV4K/n8LKckfAyjTDwvl
JlsSB2cbMC0oPiKjUVFnDE3EPgQzb78K4i24WwxOvhQMAiaTGWR8UcK7e0JyFIuU
L/Vp99Uuez+2bSFl5ihKiv9UbcQS3ela0MdVPqtCF2R5eSywsm8kZMlUDkYX86zY
Ps/ZwM4SYHQrwSm0oSFD+LBySMm27qamgjH5d0qySgAsJMYP0HVyeDeY2zrhBgxi
IUoQPA9QO9uw6P9rNU977TJ8/wWp5AXDIwIBAg==
-----END DH PARAMETERS-----
EOF

cat > /etc/openvpn/easy-rsa/keys/client.crt <<EOF
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 2 (0x2)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=VN, ST=HCM, L=Ho Chi Minh, O=FPT Telecom, OU=System Engineer, CN=client/name=server/emailAddress=vuth6@fpt.com.vn
        Validity
            Not Before: Apr 17 06:51:33 2016 GMT
            Not After : Apr 15 06:51:33 2026 GMT
        Subject: C=VN, ST=HCM, L=Ho Chi Minh, O=FPT Telecom, OU=System Engineer, CN=client/name=server/emailAddress=vuth6@fpt.com.vn
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:cc:84:34:92:08:56:e7:de:01:8e:5f:17:c0:4a:
                    71:c0:36:62:2d:a7:d5:aa:c2:22:40:8b:06:73:2c:
                    4f:67:f6:fb:7b:80:ac:e1:07:fa:8c:9e:cb:0c:a1:
                    03:fc:d8:b9:bb:62:c7:72:08:33:51:54:f3:4c:18:
                    3d:88:e7:af:cd:a2:3d:61:49:b6:3f:a7:5f:47:a8:
                    f5:e7:78:c2:4a:c1:06:6c:a4:c8:6c:7a:01:ad:6a:
                    53:76:9b:83:67:37:3e:54:be:73:f9:eb:7b:b7:98:
                    0e:a0:6f:82:c6:30:2b:2c:67:ea:2b:54:0e:13:61:
                    a6:76:b1:2b:b9:8c:11:61:dd:12:24:1d:01:6b:75:
                    aa:32:2f:91:cb:f4:cf:96:aa:95:21:0a:e4:ad:43:
                    6b:12:9c:13:d8:08:7a:e7:82:dd:c5:4f:5a:ba:27:
                    7a:ca:0f:54:7b:10:76:0d:ee:ac:c1:03:e0:15:26:
                    0a:f9:fc:0a:af:7d:e5:08:8d:10:a0:4a:8b:21:bb:
                    32:cf:b5:a7:50:c9:aa:c1:79:65:87:3f:82:7a:05:
                    46:1b:81:05:f5:e2:b2:d7:04:96:94:3a:b2:43:a1:
                    29:06:e6:b2:2a:47:3a:bd:10:3b:ac:5c:6d:44:a7:
                    fa:49:e2:e9:4b:56:c9:44:1d:48:35:de:e6:ae:5f:
                    fb:e1
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints:
                CA:FALSE
            Netscape Comment:
                Easy-RSA Generated Certificate
            X509v3 Subject Key Identifier:
                69:68:5D:49:7B:7A:05:D4:D8:F9:94:16:DB:76:D2:F0:94:0E:D7:68
            X509v3 Authority Key Identifier:
                keyid:C8:22:52:D8:65:04:82:F0:B9:FE:9E:66:B7:C0:ED:61:59:56:C4:14
                DirName:/C=VN/ST=HCM/L=Ho Chi Minh/O=FPT Telecom/OU=System Engineer/CN=client/name=server/emailAddress=vuth6@fpt.com.vn
                serial:FE:53:7F:28:3F:F0:E8:91

            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Key Usage:
                Digital Signature
    Signature Algorithm: sha256WithRSAEncryption
         1e:a0:a6:d7:7f:62:9e:bb:b1:2e:c2:14:c4:90:2d:ff:3f:60:
         ef:58:fb:ce:de:7c:f5:68:4f:ab:14:35:b7:b9:0e:8b:d0:6a:
         57:cb:62:ba:3d:fa:81:9a:18:52:e1:38:af:7e:2b:10:84:af:
         46:11:97:10:d6:cf:59:ee:4a:15:be:a7:7d:44:09:04:fc:5b:
         1f:9c:2e:3f:31:60:5c:b3:06:78:b3:b4:46:d4:42:21:34:33:
         e1:45:d3:92:8b:55:ec:f6:3d:c6:ec:5d:cc:84:18:e7:ab:9c:
         78:36:dc:df:3a:4c:e9:47:81:d5:ad:a1:94:67:8c:05:a7:bd:
         5e:46:79:c5:d1:c3:59:39:d7:45:cb:b5:0c:17:88:7a:3c:c5:
         ab:31:4c:32:c8:cf:17:13:06:dc:b8:d1:31:da:d7:f3:0d:46:
         e6:27:51:04:cf:af:8d:41:5d:bb:0a:ea:d2:84:07:e0:95:25:
         9e:2f:00:b3:1e:54:c9:a3:10:b7:4c:37:5e:b9:1c:78:10:83:
         0b:e5:bf:f0:60:f8:92:63:21:58:53:b2:b0:fd:3f:8f:d2:24:
         98:2b:e8:b0:46:7c:21:b8:29:5c:6f:b7:ce:18:da:fc:ce:6e:
         73:4c:32:f9:95:59:fa:03:1f:86:ac:af:44:77:9d:d0:55:af:
         0c:7f:f5:ba
-----BEGIN CERTIFICATE-----
MIIFIjCCBAqgAwIBAgIBAjANBgkqhkiG9w0BAQsFADCBpDELMAkGA1UEBhMCVk4x
DDAKBgNVBAgTA0hDTTEUMBIGA1UEBxMLSG8gQ2hpIE1pbmgxFDASBgNVBAoTC0ZQ
VCBUZWxlY29tMRgwFgYDVQQLEw9TeXN0ZW0gRW5naW5lZXIxDzANBgNVBAMTBmNs
aWVudDEPMA0GA1UEKRMGc2VydmVyMR8wHQYJKoZIhvcNAQkBFhB2dXRoNkBmcHQu
Y29tLnZuMB4XDTE2MDQxNzA2NTEzM1oXDTI2MDQxNTA2NTEzM1owgaQxCzAJBgNV
BAYTAlZOMQwwCgYDVQQIEwNIQ00xFDASBgNVBAcTC0hvIENoaSBNaW5oMRQwEgYD
VQQKEwtGUFQgVGVsZWNvbTEYMBYGA1UECxMPU3lzdGVtIEVuZ2luZWVyMQ8wDQYD
VQQDEwZjbGllbnQxDzANBgNVBCkTBnNlcnZlcjEfMB0GCSqGSIb3DQEJARYQdnV0
aDZAZnB0LmNvbS52bjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMyE
NJIIVufeAY5fF8BKccA2Yi2n1arCIkCLBnMsT2f2+3uArOEH+oyeywyhA/zYubti
x3IIM1FU80wYPYjnr82iPWFJtj+nX0eo9ed4wkrBBmykyGx6Aa1qU3abg2c3PlS+
c/nre7eYDqBvgsYwKyxn6itUDhNhpnaxK7mMEWHdEiQdAWt1qjIvkcv0z5aqlSEK
5K1DaxKcE9gIeueC3cVPWronesoPVHsQdg3urMED4BUmCvn8Cq995QiNEKBKiyG7
Ms+1p1DJqsF5ZYc/gnoFRhuBBfXistcElpQ6skOhKQbmsipHOr0QO6xcbUSn+kni
6UtWyUQdSDXe5q5f++ECAwEAAaOCAVswggFXMAkGA1UdEwQCMAAwLQYJYIZIAYb4
QgENBCAWHkVhc3ktUlNBIEdlbmVyYXRlZCBDZXJ0aWZpY2F0ZTAdBgNVHQ4EFgQU
aWhdSXt6BdTY+ZQW23bS8JQO12gwgdkGA1UdIwSB0TCBzoAUyCJS2GUEgvC5/p5m
t8DtYVlWxBShgaqkgacwgaQxCzAJBgNVBAYTAlZOMQwwCgYDVQQIEwNIQ00xFDAS
BgNVBAcTC0hvIENoaSBNaW5oMRQwEgYDVQQKEwtGUFQgVGVsZWNvbTEYMBYGA1UE
CxMPU3lzdGVtIEVuZ2luZWVyMQ8wDQYDVQQDEwZjbGllbnQxDzANBgNVBCkTBnNl
cnZlcjEfMB0GCSqGSIb3DQEJARYQdnV0aDZAZnB0LmNvbS52boIJAP5Tfyg/8OiR
MBMGA1UdJQQMMAoGCCsGAQUFBwMCMAsGA1UdDwQEAwIHgDANBgkqhkiG9w0BAQsF
AAOCAQEAHqCm139inruxLsIUxJAt/z9g71j7zt589WhPqxQ1t7kOi9BqV8tiuj36
gZoYUuE4r34rEISvRhGXENbPWe5KFb6nfUQJBPxbH5wuPzFgXLMGeLO0RtRCITQz
4UXTkotV7PY9xuxdzIQY56uceDbc3zpM6UeB1a2hlGeMBae9XkZ5xdHDWTnXRcu1
DBeIejzFqzFMMsjPFxMG3LjRMdrX8w1G5idRBM+vjUFduwrq0oQH4JUlni8Asx5U
yaMQt0w3XrkceBCDC+W/8GD4kmMhWFOysP0/j9IkmCvosEZ8IbgpXG+3zhja/M5u
c0wy+ZVZ+gMfhqyvRHed0FWvDH/1ug==
-----END CERTIFICATE-----
EOF

cat > /etc/openvpn/easy-rsa/keys/client.key <<EOF
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDMhDSSCFbn3gGO
XxfASnHANmItp9WqwiJAiwZzLE9n9vt7gKzhB/qMnssMoQP82Lm7YsdyCDNRVPNM
GD2I56/Noj1hSbY/p19HqPXneMJKwQZspMhsegGtalN2m4NnNz5UvnP563u3mA6g
b4LGMCssZ+orVA4TYaZ2sSu5jBFh3RIkHQFrdaoyL5HL9M+WqpUhCuStQ2sSnBPY
CHrngt3FT1q6J3rKD1R7EHYN7qzBA+AVJgr5/AqvfeUIjRCgSoshuzLPtadQyarB
eWWHP4J6BUYbgQX14rLXBJaUOrJDoSkG5rIqRzq9EDusXG1Ep/pJ4ulLVslEHUg1
3uauX/vhAgMBAAECggEBAL3GS7XacTIVCqKe0L5JFgaDMFUnMRiTrg7wMpr62fAh
+bffbgweSDrmOopMexPL04TzIxlITL5CssTAlZENVE/fJU+6g5fLaplnSk9w+fE9
7gUwXx5xlE7jo/EiWyuS0o72b03QWmvBeIkdEF9xYQ6CmoN8KteHPF1VB7rUI2kH
fjm7rT462Jv0+XzjAyTWyGf8/WzniV0RYqaLsa5Wjrhyl4g3Exqed3D7HG+JSpHT
cwLKOP6cV+7Q3t1O/A88UcJ77BWTgW5PfT3EmFdQ9NkcedfKCuyNq/kFn85oQiA0
30oKMIl5S56GhYDsdMiJJegwRVgXOp8EZ+GISDwq8nECgYEA8doFF4nInoSdWZxz
gc2rRoUKlKmMWizrCpUCmpCNagj3KkYFu7xaHRZfHPe1tKYFlR+esugg8N/tquvF
UmPRAFy5l/bm06NMgIlkohInZl5nkGN29kB74XOM2IJsVZ6cquGR09DWPZs4qg4L
jepDzRLAldB4QVhK32ULddNpc50CgYEA2HsNQULa1IdNnyqOgmKSvE4GTz2J52z4
DK89BX93jwsluoNrK1SkUqlR6fzizUfJsswEPpoqla694+G2HrydPEpSf7WlifA9
xie5IuX+vwDXamQHPOekGXVpLp0gq6P3FCxOCtV7oEomDY+BsVeHcFUNGD6qPGhq
Atm1IwAngBUCgYBXkx2y50aI9/ZOQ5Oj1giGEZjCOh7DbG5zt39o3p0GX1a4rQBY
eZyb2cT5JU1bq55r4DZEDEAZWMyjzpn1+oTsv6bIuzPcQM5r4NRax34S2G5h31Jt
Wu5AtemzYI6/9h4+1k1KyN07E6DSGyHd8o04jejEludkqgb6m4kp0jLmFQKBgQDT
b8xQc4XckpKD5ULvomuDNAoBly98M/hKG1ZUal1R/ydIdldUKQWeHvZ8vZyft4AO
/CkhI953+AZL7wa8GqjQXB8b0UTv5w/O3Ll8lnsr/xxnM2/GUtD6dKzY9GsWeb03
nNZUypJGymVEVWfs2HrWgpuZlIsdGTaBtjWvC9WIyQKBgCP6RkQfPlWO3BzbdpXB
wRiSVQF82I0V2U1SWuCoktsfHrJJx4vtOm9JAKwlI8M3nLYmOvT3J3TZvF5cxhjq
GjVgCAcRIfe7wIOXpTqEEt63YHvry27c2YoqP2ZsBs/rqtLupvMyaOzRX5+OyVhd
iRFFSxXHvr8dFQYYiT0gJg9U
-----END PRIVATE KEY-----
EOF

######## Config ip forward ##########
sysctl_config=/etc/sysctl.conf
test -f $sysctl_config.orig \
|| mv $sysctl_config $sysctl_config.orig
cat > $sysctl_config <<EOF
net.ipv4.ip_forward = 1
EOF

######## Config IPTABLES ##########
iptables -I INPUT 5 -m state --state NEW -p udp --dport 1194 -m comment --comment "VPN"  -j ACCEPT
iptables -t nat -A POSTROUTING -o $interfacevpnwan -j MASQUERADE
iptables -I FORWARD 1 -i $interfacevpnlan -j ACCEPT
iptables-save > /etc/sysconfig/iptables

######## Start Services ##########
cat > /etc/openvpn/openvpn-startup <<EOF
#!/bin/sh
if ! brctl show | grep -q tap19
then
    openvpn --mktun --dev tap19
    brctl addif br0 tap19
    ifconfig tap19 0.0.0.0 promisc up
fi
/usr/sbin/openvpn --daemon --writepid /var/run/openvpn/server.pid --cd /etc/openvpn/ --config server.conf
EOF

chmod +x /etc/openvpn/openvpn-startup

sed -i 's!ExecStart=.*!ExecStart=/etc/openvpn/openvpn-startup!g' /usr/lib/systemd/system/openvpn@.service
systemctl enable openvpn@server.service
systemctl daemon-reload
systemctl start openvpn@server.service

######## OpenVPN Client ##########
cat > ./openstack.ovpn <<EOF
client
auth-user-pass
dev tap19
proto udp
remote $ipVPNwan 1194
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
comp-lzo
verb 3
EOF

######## Disable SELinux ##########
echo "============= Config SELinux ============="
if ! grep -i SELINUX=disabled /etc/selinux/config
then 
sed -i 's!SELINUX=.*!SELINUX=disabled!g' /etc/selinux/config 
init 6
fi


