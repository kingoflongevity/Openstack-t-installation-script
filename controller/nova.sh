#!/bin/bash
source $(pwd)/parameter.sh
source $(pwd)/../admin-openrc
mysql -uroot -p$password -e "CREATE DATABASE nova_api;"
mysql -uroot -p$password -e "CREATE DATABASE nova;"
mysql -uroot -p$password -e "CREATE DATABASE nova_cell0;"
mysql -uroot -p$password -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost'  \
  IDENTIFIED BY \"$password\";"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%'  \
IDENTIFIED BY \"$password\";"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost'  \
IDENTIFIED BY \"$password\";"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%'  \
IDENTIFIED BY \"$password\";"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost'  \
IDENTIFIED BY \"$password\";"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%'  \
IDENTIFIED BY \"$password\";"
/usr/bin/expect <<EOF
spawn  openstack user create --domain default --password-prompt nova
expect {
             "User Password:" { send "$password\r"; exp_continue }
             "Repeat User Password:" { send "$password\r"}
        }
        expect eof
EOF
openstack role add --project service --user nova admin
openstack service create --name nova \
  --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2.1
openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2.1
yum install openstack-nova-api openstack-nova-conductor \
  openstack-nova-novncproxy openstack-nova-scheduler -y
cat> /etc/nova/nova.conf<<EOF
[DEFAULT]
# ...
enabled_apis = osapi_compute,metadata
my_ip = $controller_ip
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver
transport_url = rabbit://openstack:$password@controller:5672/
[api_database]
# ...
connection = mysql+pymysql://nova:$password@controller/nova_api
[database]
# ...
connection = mysql+pymysql://nova:$password@controller/nova
[api]
# ...
auth_strategy = keystone
[keystone_authtoken]
auth_url = http://controller:5000/v3
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = $password
[vnc]
enabled = true
# ...
server_listen = \$my_ip
server_proxyclient_address =\$my_ip
[glance]
# ...
api_servers = http://controller:9292
[oslo_concurrency]
# ...
lock_path = /var/lib/nova/tmp
[placement]
# ...
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = http://controller:5000/v3
username = placement
password = $password
[scheduler]
discover_hosts_in_cells_interval = 300
EOF
su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
systemctl enable \
    openstack-nova-api.service \
    openstack-nova-scheduler.service \
    openstack-nova-conductor.service \
    openstack-nova-novncproxy.service
systemctl start \
    openstack-nova-api.service \
    openstack-nova-scheduler.service \
    openstack-nova-conductor.service \
    openstack-nova-novncproxy.service
openstack compute service list --service nova-compute
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

