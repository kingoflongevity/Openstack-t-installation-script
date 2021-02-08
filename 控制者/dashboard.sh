#!/bin/bash
yum install openstack-dashboard -y
sed  -i 's/OPENSTACK_HOST = "127.0.0.1"/OPENSTACK_HOST = "controller"/g'  /etc/openstack-dashboard/local_settings 
sed -i -e "s/^ALLOWED_HOSTS.*/ALLOWED_HOSTS = ['*']/g" /etc/openstack-dashboard/local_settings
sed -i -e "s/^TIME_ZONE.*/TIME_ZONE = \"Asia\/Shanghai\"/g" /etc/openstack-dashboard/local_settings

cat >>/etc/openstack-dashboard/local_settings<<EOF
ALLOWED_HOSTS = ['*']
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
CACHES = {
    'default': {
         'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
         'LOCATION': 'controller:11211',
    }
}
OPENSTACK_API_VERSIONS = {
    "identity": 3,
    "image": 2,
    "volume": 3,
}
OPENSTACK_KEYSTONE_DEFAULT_DOMAIN = "Default"
OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"
TIME_ZONE = "Asia/Shanghai"
OPENSTACK_KEYSTONE_MULTIDOMAIN_SUPPORT = True
EOF
sed -i '4a WSGIApplicationGroup %{GLOBAL}' /etc/httpd/conf.d/openstack-dashboard.conf
sed -i -e "s/^WEBROOT.*/WEBROOT = \'\/dashboard\/\'/1" /usr/share/openstack-dashboard/openstack_dashboard/defaults.py
sed -i -e "s/^WEBROOT.*/WEBROOT = \'\/dashboard\/\'/1" /usr/share/openstack-dashboard/openstack_dashboard/test/settings.py
systemctl restart httpd.service memcached.service
