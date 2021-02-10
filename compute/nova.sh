#!/bin/bash
source /root/compute/evn.sh
yum install openstack-nova-compute -y
cat>/etc/nova/nova.conf<<EOF
[DEFAULT]
# ...
enabled_apis = osapi_compute,metadata
transport_url = rabbit://openstack:$password@controller
my_ip = $controller_ip 
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver
[api]
# ...
auth_strategy = keystone
[keystone_authtoken]
# ...
www_authenticate_uri = http://controller:5000/
auth_url = http://controller:5000/
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = $password
[vnc]
# ...
enabled = true
server_listen = 0.0.0.0
server_proxyclient_address =\$my_ip
novncproxy_base_url = http://controller:6080/vnc_auto.html
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
[libvirt]
# ...
virt_type = qemu
EOF
systemctl enable libvirtd.service openstack-nova-compute.service
systemctl start libvirtd.service openstack-nova-compute.service
