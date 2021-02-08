#!/bin/bash
source /root/controller/evn.sh
source /root/admin-openrc
mysql -uroot -p$password -e "CREATE DATABASE neutron;"
mysql -uroot -p$password -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' \
  IDENTIFIED BY \"$password\";"
mysql -uroot -p$password -e "GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%'  \
  IDENTIFIED BY \"$password\";"
/usr/bin/expect <<EOF
spawn  openstack user create --domain default --password-prompt neutron
expect {
             "User Password:" { send "$password\r"; exp_continue }
             "Repeat User Password:" { send "$password\r"}
        }
        expect eof
EOF
openstack role add --project service --user neutron admin
openstack service create --name neutron \
  --description "OpenStack Networking" network
openstack endpoint create --region RegionOne \
  network public http://controller:9696
openstack endpoint create --region RegionOne \
  network internal http://controller:9696
openstack endpoint create --region RegionOne \
  network admin http://controller:9696
yum install openstack-neutron openstack-neutron-ml2 \
  openstack-neutron-linuxbridge ebtables -y
cat>/etc/neutron/neutron.conf<<EOF
[database]
# ...
connection = mysql+pymysql://neutron:$password@controller/neutron
[DEFAULT]
# ...
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = true
transport_url = rabbit://openstack:$password@controller
auth_strategy = keystone
notify_nova_on_port_status_changes = true
notify_nova_on_port_data_changes = true
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
[nova]
# ...
auth_url = http://controller:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = $password
[oslo_concurrency]
# ...
lock_path = /var/lib/neutron/tmp
EOF
cat >  /etc/neutron/plugins/ml2/ml2_conf.ini<<EOF
[ml2]
# ...
type_drivers = flat,vlan,vxlan
tenant_network_types = vxlan
mechanism_drivers = linuxbridge,l2population
extension_drivers = port_security
[ml2_type_flat]
# ...
flat_networks = provider
[ml2_type_vxlan]
# ...
vni_ranges = 1:1000
[securitygroup]
# ...
enable_ipset = true
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
cat>/etc/neutron/l3_agent.ini<<EOF
[DEFAULT]
# ...
interface_driver = linuxbridge
EOF
cat>/etc/neutron/dhcp_agent.ini<<EOF
[DEFAULT]
# ...
interface_driver = linuxbridge
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
enable_isolated_metadata = true
EOF
cat>/etc/neutron/metadata_agent.ini<<EOF
[DEFAULT]
# ...
nova_metadata_host = controller
metadata_proxy_shared_secret = $password
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
service_metadata_proxy = true
metadata_proxy_shared_secret = $password
EOF
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
systemctl restart openstack-nova-api.service
systemctl enable neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
systemctl start neutron-server.service \
  neutron-linuxbridge-agent.service neutron-dhcp-agent.service \
  neutron-metadata-agent.service
systemctl enable neutron-l3-agent.service
systemctl start neutron-l3-agent.service
