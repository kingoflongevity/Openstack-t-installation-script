#！bin/bash
systemctl disable firewalld && systemctl stop firewalld
sed -i '7s/enforcing/disabled/g'  /etc/selinux/config
yum install epel-release -y
yum install crudini expect net-tools vim -y
yum install ntpdate -y
ntpdate ntp1.aliyun.com
yum install chrony -y
source /root/compute/env.sh
sed -i 's/^server/#&/g' /etc/chrony.conf
sed -i '7iserver controller iburst' /etc/chrony.conf
systemctl enable chronyd.service && systemctl start chronyd.service
yum install centos-release-openstack-train -y
yum upgrade -y
yum install python-openstackclient -y
yum install openstack-selinux -y
