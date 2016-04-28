#!/bin/bash 

# eth0 api-interface
# eth1 neutron_external_interface
# eth2 storage_interface
# eth4 tunel_interface

set -x
source etc/openrc
source libs/common

start_node="True"
# 镜像id，默认不需要改变
image_id="75420fdf-6608-402d-86b5-2da92fc3bbe3"
# 超时时间，创建虚拟机和云硬盘时十秒的超时时间
timeout=10
# 每台存储节点对应的云硬盘数量
volume_num=3


# 创建路由器和子网
neutron router-create public_router
neutron router-gateway-set public_router BGP
neutron net-create openstack --provider:unmanaged_network True 
neutron subnet-create --enable-dhcp --name api_network openstack 192.168.20.0/24
neutron subnet-create --disable-dhcp --name neutron_external openstack 192.168.30.0/24
neutron subnet-create --enable-dhcp openstack --name storage_network 192.168.40.0/24
neutron subnet-create --enable-dhcp openstack --name tunnel_network 192.168.50.0/24
neutron router-interface-add public_router api_network

# 根据上一步创建的网络，获取必要的信息
network_id=`get_network_id openstack`

external_subnet_id=`get_subnet_id neutron_external`
external_network_id=$network_id

api_network_id=$network_id

storage_network_id=$network_id
storage_subnet_id=`get_subnet_id storage_network`

# tunnel config
tunnel_network_id=$network_id
tunnel_subnet_id=`get_subnet_id tunnel_network`

boot_node control01  32 no_storage memory-2 
boot_node control02  33 no_storage memory-2 
boot_node control03  34 no_storage memory-2 
boot_node storage01  35 is_storage standard-1
boot_node storage02  36 is_storage standard-1
boot_node storage03  37 is_storage standard-1
boot_node network01  38 no_storage standard-1
boot_node compute01  39 no_storage standard-1
boot_node admin-server  31 no_storage standard-1 

neutron floatingip-create BGP
floatingip_id=`get_floatingip_id`
admin_port_id=`get_port_id 240`
neutron floatingip-associate $floatingip_id $admin_port_id

set_network 192.168.20.38



#ssh root@42.62.93.71 'yum install git -y &&git clone https://github.com/spunkzwy/kolla-base.git'
