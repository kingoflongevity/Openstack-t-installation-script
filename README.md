# Openstack-t installation script
安装最基本的open stack服务双节点，当然我会继续更新其他组件的安装脚本  
#装前须知  
1.双网卡 自动选择有网络的那张卡为外网网卡  
2.evn.sh 为环境脚本，可以修改管理密码  
3.运行脚本前配置好hosts映射为内网管理网络ip  
4.运行脚本base-controller时修改时钟同步配置sed -i 's/\#allow.*/allow 192.168.100.0\/24/g' /etc/chrony.conf 为你的内网管理网络网段  
5.修改计算节点novncproxy_base_url = http://controller:6080/vnc_auto.html controller为你控制节点ip地址  
6.在执行完2个nova脚本后请在控制节点重复执行命令  
openstack compute service list --service nova-compute(此命令执行后会出现nova节点信息，如未出现，请重启compute节点)  
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova  
7.执行脚本前请赋予脚本可执行权限且均以./脚本名.sh执行  
8.keystone装完记得重启
============================================================================================
Install the most basic open stack service two nodes. Of course, I will continue to update the installation scripts of other components

#Notice before installation

1. The dual network card automatically selects the card with network as the external network card

2. evn.sh For the environment script, you can modify the management password

3. Before running the script, configure hosts to map to intranet management network IP

4. When running the script base controller, modify the clock synchronization configuration sed - I's / # allow. * / allow 192.168.100.0/24/g '/ etc/ chrony.conf Manage network segments for your intranet

5. Modify the computing node novncproxy_ base_ url = http://controller :6080/vnc_ auto.html The controller controls the IP address of the node for you

6. After executing two Nova scripts, please repeat the command in the control node

   Openstack compute service list -- service Nova compute

   su -s /bin/sh -c "nova-manage cell_ v2 discover_ hosts --verbose" nova

7. Before executing the script, please give the script executable permission and execute with. / script name. Sh

8. Remember to restart keystone after installation
