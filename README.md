# openstackT
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
