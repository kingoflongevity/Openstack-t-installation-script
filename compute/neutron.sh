#!/bin/bash
source /root/compute/evn.sh
yum install openstack-neutron-linuxbridge ebtables ipset -y
cat>/etc/neutron/neutron.conf<<EOF
[DEFAULT]
# ...
transport_url = rabbit://openstack:$password@controller
auth_strategy = keystone
[keystone_authtoken]
# ...
www_authenticate_uri = http://controller:5000
auth_url = http://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = $password
[oslo_concurrency]
# ...
lock_path = /var/lib/neutron/tmp
EOF
cat> /etc/neutron/plugins/ml2/linuxbridge_agent.ini<<EOF
[linux_bridge]
physical_interface_mappings = provider:$ext_network_name
[vxlan]
enable_vxlan = true
local_ip = $in_network_ip
l2_population = true
[securitygroup]
# ...
enable_security_group = true
firewall_driver = neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
EOF
cat>>/etc/nova/nova.conf<<EOF
[neutron]
# ...
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = neutron
password = $password
EOF
systemctl restart openstack-nova-compute.service
systemctl enable neutron-linuxbridge-agent.service
systemctl start neutron-linuxbridge-agent.service
