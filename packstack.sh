#!/bin/bash
read -p  "Input SETP:" Setp
echo $Setp
if [ $Setp=="INIT" ]
then
read -p  "Input setting installlment and using for the wxGTK3 (e.g:yum or local):" Install

read -p  "Input install openstack version:" Version

##Set Environment
cat >> /etc/environment <<'EOF'
LANG=en_US.utf-8
LC_ALL=en_US.utf-8
EOF

##Set repo
###Install wxGTK3-media and wxGTK3-gl if it by delted

rm -rf /etc/yum.repos.d/*

cat > /etc/yum.repos.d/Centos-7.repo <<'EOF'
[base]
name=CentOS-$releasever - Base - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-$releasever - Updates - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
EOF

cat > /etc/yum.repos.d/epel.repo <<'EOF'
[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
baseurl=http://mirrors.aliyun.com/epel/7/$basearch
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
EOF

yum clean all

yum makecache

case "$Install" in
"yum" | "YUM" )
cat > /etc/yum.repos.d/wxGTK3-media.repo <<'EOF'
[wxGTK3-media]
name=wxGTK3-media
baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64/
enabled=1
gpgcheck=0
EOF
;;
"local" | "LOCAL" )
for WX in media gl
do
yum localinstall -y ./wxGTK3-$WX-3.0.2-15.el7.x86_64.rpm
done
;;
esac


##Set Linux Network
sudo systemctl disable firewalld
sudo systemctl stop firewalld
sudo systemctl disable NetworkManager
sudo systemctl stop NetworkManager
/sbin/chkconfig network on
sudo systemctl start network

#Install openstack repo
sudo yum install -y centos-release-openstack-$Version

cat <<HERE  > /etc/yum.repos.d/CentOS-OpenStack-$Version.repo
[openstack-$Version]
name=openstack-$Version
baseurl=http://mirrors.aliyun.com/centos/7/cloud/x86_64/openstack-$Version/
enabled=1
gpgcheck=0
HERE

sudo yum update -y
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
echo -e "Restarting ...... "
sudo reboot

else

sudo yum install -y openstack-packstack

packstack --gen-answer-file openstack.ini

sed -i 's/CONFIG_MANILA_INSTALL=n/CONFIG_MANILA_INSTALL=n/g' openstack.ini

sed -i 's/CONFIG_SWIFT_INSTALL=n/CONFIG_SWIFT_INSTALL=n/g' openstack.ini

sed -i 's/CONFIG_CEILOMETER_INSTALL=n/CONFIG_CEILOMETER_INSTALL=n/g' openstack.ini

sed -i 's/CONFIG_AODH_INSTALL=n/CONFIG_AODH_INSTALL=n/g' openstack.ini

sed -i 's/CONFIG_GNOCCHI_INSTALL=n/CONFIG_GNOCCHI_INSTALL=n/g' openstack.ini

sed -i 's/CONFIG_SAHARA_INSTALL=n/CONFIG_SAHARA_INSTALL=n/g' openstack.ini

sed -i 's/CONFIG_HEAT_INSTALL=n/CONFIG_HEAT_INSTALL=n/g' openstack.ini

sed -i 's/CONFIG_TROVE_INSTALL=n/CONFIG_TROVE_INSTALL=n/g' openstack.ini

sed -i 's/CONFIG_IRONIC_INSTALL=n/CONFIG_IRONIC_INSTALL=n/g' openstack.ini

sed -i 's/CONFIG_HEAT_CLOUDWATCH_INSTALL=n/CONFIG_HEAT_CLOUDWATCH_INSTALL=n/g' openstack.ini
sed -i 's/CONFIG_NAGIOS_INSTALL=y/CONFIG_NAGIOS_INSTALL=y/g' openstack.ini
sed -i 's/CONFIG_PROVISION_DEMO=n/CONFIG_PROVISION_DEMO=n/g' openstack.ini

sed -i 's/CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=/CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=physnet1:br-eth1/g' openstack.ini

sed -i 's/CONFIG_KEYSTONE_ADMIN_PW=*/CONFIG_KEYSTONE_ADMIN_PW=mtanlee/g' openstack.ini

sed -i 's/CONFIG_NAGIOS_PW=PW_PLACEHOLDER/CONFIG_NAGIOS_PW=mtanlee/g' openstack.ini

packstack --asswer-file openstack.ini

cat > /etc/sysconfig/network-scripts/ifcfg-br-ex <<'EOF'
DEVICE=br-ex
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=static
IPADDR=172.16.158.7
NETMASK=255.255.255.0
GATEWAY=172.16.158.2
DNS1=172.16.158.2
DNS2=210.21.196.6
ONBOOT=yes
EOF

cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<'EOF'
DEVICE=eth0
TYPE=OVSPort
DEVICETYPE=ovs
OVS_BRIDGE=br-ex
ONBOOT=yes
EOF
fi
