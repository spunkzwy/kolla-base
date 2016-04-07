# kolla-base
使用kolla在uos公有云创建一个多节点的openstack集群

安装
===============

1. 创建一个新的project
    要确保是一个全新的project，里面没有任何创建资源

2. 填写openrc
    参照openrc.sample 填写

3. 安装openstackclient
   如果你是centos机器可以执行
   yum install openstackclient

4. 执行 boot.sh
    source boot.sh
    bash boot.sh

5. 你已经有了一个多节点具有高可用功能的openstack集群


架构
===============

