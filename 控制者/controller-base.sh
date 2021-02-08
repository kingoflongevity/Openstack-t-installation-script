#！bin/bash
systemctl disable firewalld && systemctl stop firewalld
sed -i '7s/enforcing/disabled/g'  /etc/selinux/config
yum install epel-release -y
yum install vim crudini expect net-tools ntpdate -y
ntpdate ntp1.aliyun.com
source /root/evn.sh
yum install chrony -y
sed -i 's/^server/#&/g' /etc/chrony.conf
sed -i '7iserver controller iburst' /etc/chrony.conf
sed -i 's/\#allow.*/allow 192.168.100.0\/24/g' /etc/chrony.conf
systemctl enable chronyd.service && systemctl start chronyd.service
yum install centos-release-openstack-train -y
yum upgrade -y
yum install python-openstackclient -y
yum install openstack-selinux -y
yum install mariadb mariadb-server python2-PyMySQL -y
echo -e "[mysqld]">> /etc/my.cnf.d/openstack.cnf
echo -e "bind-address = $in_network_ip">> /etc/my.cnf.d/openstack.cnf
echo -e "default-storage-engine = innodb">> /etc/my.cnf.d/openstack.cnf
echo -e "innodb_file_per_table = on">> /etc/my.cnf.d/openstack.cnf
echo -e "max_connections = 4096">> /etc/my.cnf.d/openstack.cnf
echo -e "collation-server = utf8_general_ci">> /etc/my.cnf.d/openstack.cnf
echo -e "character-set-server = utf8">> /etc/my.cnf.d/openstack.cnf
systemctl enable mariadb.service && systemctl start mariadb.service
/usr/bin/expect <<EOF
spawn  mysql_secure_installation
expect {
             "Enter current password" { send "\r"; exp_continue }
             "Y/n" { send "Y\r"; exp_continue }
             "New password" { send "$password\r"; exp_continue }
             "Re-enter new password" { send "$password\r"; exp_continue }
             "Remove anonymous users" { send "Y\r"; exp_continue }
             "Disallow root login remotely" { send "N\r"; exp_continue }
             "Remove test database and access to it" { send "Y\r"; exp_continue }
             "Reload privilege tables now" { send "Y\r" }
        }
        expect eof
EOF
yum install rabbitmq-server -y
systemctl enable rabbitmq-server.service &&  systemctl start rabbitmq-server.service
rabbitmqctl add_user openstack 000000
rabbitmqctl set_permissions openstack ".*" ".*" ".*".
yum install memcached python-memcached -y
sed -i '$s/::1/::1\,controller/g' /etc/sysconfig/memcached
systemctl enable memcached.service && systemctl start memcached.service
yum install etcd -y
echo -e '#[Member]'>/etc/etcd/etcd.conf
echo -e 'ETCD_DATA_DIR="/var/lib/etcd/default.etcd'>>/etc/etcd/etcd.conf
echo -e "ETCD_LISTEN_PEER_URLS=\"http://$in_network_ip:2380\"">>/etc/etcd/etcd.conf
echo -e "ETCD_LISTEN_CLIENT_URLS=\"http://$in_network_ip:2379\"">>/etc/etcd/etcd.conf
echo -e 'ETCD_NAME="controller"'>>/etc/etcd/etcd.conf
echo -e '#[Clustering]'>>/etc/etcd/etcd.conf
echo -e "ETCD_INITIAL_ADVERTISE_PEER_URLS=\"http://$in_network_ip:2380\"">>/etc/etcd/etcd.conf
echo -e "ETCD_ADVERTISE_CLIENT_URLS=\"http://$in_network_ip:2379\"">>/etc/etcd/etcd.conf
echo -e "ETCD_INITIAL_CLUSTER=\"controller=http://$in_network_ip:2380\"">>/etc/etcd/etcd.conf
echo -e 'ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"'>>/etc/etcd/etcd.conf
echo -e 'ETCD_INITIAL_CLUSTER_STATE="new"'>>/etc/etcd/etcd.conf
systemctl enable etcd && systemctl start etcd
