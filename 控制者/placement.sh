#!/bin/bash
source /root/controller/evn.sh
source /root/admin-openrc
mysql -uroot -p$password -e "CREATE DATABASE placement;"
mysql -uroot -p$password -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost'  \
  IDENTIFIED BY \"$password\";"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' \
IDENTIFIED BY \"$password\";"
/usr/bin/expect <<EOF
spawn  openstack user create --domain default --password-prompt placement
expect {
             "User Password:" { send "$password\r"; exp_continue }
             "Repeat User Password:" { send "$password\r"}
        }
        expect eof
EOF
openstack role add --project service --user placement admin
openstack service create --name placement \
  --description "Placement API" placement
openstack endpoint create --region RegionOne \
  placement public http://controller:8778
openstack endpoint create --region RegionOne \
  placement internal http://controller:8778
openstack endpoint create --region RegionOne \
  placement admin http://controller:8778
yum install openstack-placement-api -y
cat>/etc/placement/placement.conf<<EOF
[placement_database]
# ...
connection = mysql+pymysql://placement:$password@controller/placement
[api]
# ...
auth_strategy = keystone

[keystone_authtoken]
# ...
auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = $password
EOF
su -s /bin/sh -c "placement-manage db sync" placement
sed -i '104s/Require all denied/Require all granted/g' /etc/httpd/conf/httpd.conf
systemctl restart httpd
