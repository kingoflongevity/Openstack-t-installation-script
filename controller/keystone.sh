#!/bin/bash
source /root/controller/evn.sh
mysql -uroot -p$password -e "CREATE DATABASE keystone;"
mysql -uroot -p$password -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY \"$password\";"
mysql -uroot -p000000 -e "GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY \"$password\";"
yum install openstack-keystone httpd mod_wsgi -y
echo -e '[database]'>/etc/keystone/keystone.conf
echo -e "connection = mysql+pymysql://keystone:$password@controller/keystone">>/etc/keystone/keystone.conf
echo -e '[token]'>>/etc/keystone/keystone.conf
echo -e 'provider = fernet'>>/etc/keystone/keystone.conf
su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
 keystone-manage bootstrap --bootstrap-password $password \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne
sed -i 's/\#ServerName.*/ServerName controller/g'  /etc/httpd/conf/httpd.conf
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable httpd.service && systemctl start httpd.service
openstack domain create --description "An Example Domain" example
openstack project create --domain default \
--description "Service Project" service
openstack project create --domain default \
--description "Demo Project" myproject
/usr/bin/expect <<EOF
spawn  openstack user create --domain default \
  --password-prompt myuser
expect {
             "User Password:" { send "$password\r"; exp_continue }
             "Repeat User Password:" { send "$password\r"}
        }
        expect eof
EOF
openstack role create myrole
openstack role add --project myproject --user myuser myrole
cat >/root/admin-openrc<<EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=$password
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
cat >/root/demo-openrc<<EOF
export OS_PROJECT_DOMAIN_NAME=Default
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_NAME=myproject
export OS_USERNAME=myuser
export OS_PASSWORD=$password
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
