#!/bin/bash
source /root/controller/evn.sh
source /root/admin-openrc
mysql -uroot -p$password -e "CREATE DATABASE glance;"
mysql -uroot -p$password -e " GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' \
  IDENTIFIED BY \"$password\";"
mysql -uroot -p000000 -e " GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' \
IDENTIFIED BY \"$password\";"
/usr/bin/expect <<EOF
spawn  openstack user create --domain default --password-prompt glance
expect {
             "User Password:" { send "$password\r"; exp_continue }
             "Repeat User Password:" { send "$password\r"}
        }
        expect eof
EOF
openstack role add --project service --user glance admin
openstack service create --name glance \
  --description "OpenStack Image" image
openstack endpoint create --region RegionOne \
  image public http://controller:9292
openstack endpoint create --region RegionOne \
  image internal http://controller:9292
openstack endpoint create --region RegionOne \
  image admin http://controller:9292
yum install openstack-glance -y
cat>/etc/glance/glance-api.conf<<EOF
[database]
# ...
connection = mysql+pymysql://glance:$password@controller/glance
[keystone_authtoken]
# ...
www_authenticate_uri  = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = $password
[paste_deploy]
# ...
flavor = keystone
[glance_store]
# ...
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/
EOF
su -s /bin/sh -c "glance-manage db_sync" glance
systemctl enable openstack-glance-api.service && systemctl start openstack-glance-api.service
