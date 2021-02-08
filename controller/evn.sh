#!/bin/bash
ens33=$(ifconfig|grep flags|grep -o "[a-z].*:"|grep -o "[a-z].*[a-z,0-9]"|sed -n 1p)
ens34=$(ifconfig|grep flags|grep -o "[a-z].*:"|grep -o "[a-z].*[a-z,0-9]"|sed -n 2p)
ping -I  $ens33 -c 3  baidu.com>/dev/null
if [ $? -eq 0 ]
then 
export ext_network_name=$ens33
export ext_network_ip=$(ifconfig $ens33|grep -o inet.*net|grep -o [0-9].*[0-9])
export in_network_name=$ens34
export in_network_ip=$(ifconfig $ens34|grep -o inet.*net|grep -o [0-9].*[0-9])
export controller_ip=$(ifconfig $ens34|grep -o inet.*net|grep -o [0-9].*[0-9])
else 
export ext_network_name=$ens33
export ext_network_ip=$(ifconfig $ens33|grep -o inet.*net|grep -o [0-9].*[0-9])
export in_network_name=$ens34
export in_network_ip=$(ifconfig $ens34|grep -o inet.*net|grep -o [0-9].*[0-9])	
export controller_ip=$(ifconfig $ens34|grep -o inet.*net|grep -o [0-9].*[0-9])
fi

export password=000000
export OS_USERNAME=admin
export OS_PASSWORD=$password
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
