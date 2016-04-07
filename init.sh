#!/bin/bash

TOPDIR=$(cd $(dirname "$0") && pwd)

# 安装必要的包
yum install -y epel-release 
yum install -y python-devel libffi-devel openssl-devel gcc git python-pip ansible
pip install -U python-openstackclient
pip install -U ansible==1.9.4

# 获取kolla代码
pushd "${TOPDIR}" > /dev/null
git clone https://github.com/openstack/kolla.git
pushd "${TOPDIR}/kolla" > /dev/null
git fetch origin stable/mitaka:mitaka
git checkout mitaka
cp -r etc/kolla /etc/
popd > /dev/null

# 安装kolla
pip install kolla/

# 配置kolla
pushd "${TOPDIR}/kolla-base" > /dev/null
\cp config/* /etc/kolla/
\cp ansible_hosts /etc/ansible/hosts
\cp hosts /etc/hosts
\cp ansible.cfg /etc/ansible/ansible.cfg
# 初始化目标节点
ansible-playbook -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml ansible/site.yml

# 部署openstack集群
kolla-ansible deploy -i /etc/ansible/hosts
