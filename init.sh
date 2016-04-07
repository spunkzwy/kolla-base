cd /root
git clone https://github.com/openstack/kolla.git
cd kolla 
git fetch origin stable/mitaka:mitaka
git checkout mitaka
yum install epel-release -y
yum install python-pip -y
yum install -y python-devel libffi-devel openssl-devel gcc git
pip install -U python-openstackclient

cd /root
pip install kolla/

cd kolla
cp -r etc/kolla /etc/
yum -y install ansible
pip install -U ansible==1.9.4

cd /root/kolla-base
\cp config/* /etc/kolla/
\cp ansible_hosts /etc/ansible/hosts
\cp hosts /etc/hosts
cd ansible
ansible-playbook -e @/etc/kolla/globals.yml -e action=prechecks -e @/etc/kolla/passwords.yml site.yml

cd /root
kolla-ansible deploy -i /etc/ansible/hosts
