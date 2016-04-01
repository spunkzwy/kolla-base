#!/bin/bash 

# eth0 api-interface
# eth1 neutron_external_interface
# eth2 storage_interface
# eth4 tunel_interface

start_node="noTrue"
attach_volume="True"
create_volume="True"
set -x
# define variable
image_id="631e33e1-5fc1-4d60-8c6f-dc62ccd81a64"

# apinetwork config
api_network_id="e7a245db-12f0-4874-918b-898a871ab67c"

# external_network_id
external_network_id="c131ccbb-3275-453c-ae39-71fe507deee6"
external_subnet_id="26087c3f-db83-4d28-9c6d-24c3ddc9c673"

# storage config
storage_network_id="69d4fed8-01ed-4599-aefe-163543e8766e"
storage_subnet_id="3100beb8-e50e-4033-b5e6-ddeb5d8d8cbd"

# tunnel config
tunnel_network_id="c131ccbb-3275-453c-ae39-71fe507deee6"
tunnel_subnet_id="dda9b5cc-c917-4dd4-9a6d-5f79ef503a3c"

timeout=10
volume_num=3

#neutron port-create --fixed-ip subnet_id=dda9b5cc-c917-4dd4-9a6d-5f79ef503a3c,ip_address=192.168.50.11 --name tunnel_01 public

create_port() {
    local network_id=$1
    local subnet_id=$2
    local ip_address=$3
    local port_name=$4
    neutron port-create --fixed-ip subnet_id="${subnet_id}",ip_address="${ip_address}" --name "${port_name}" "$network_id"
}

check_instance_exist() {
    instance_name=$1
    nova list | grep $instance_name
}


wait_instance_active() {
    local instance_id=$1
    
    for i in $( seq 1 $timeout);
    do
        nova show "$instance_id" | grep ACTIVE
        if [ $? == 0 ];then
            break
        fi
    done
    if [ $i == $timeout ];then
        echo "create instance timeout"
        exit 1
    fi
}


get_instance_id() {
    local instance_name=$1
    instance_id=`nova list | grep $instance_name | sed 's/ |.*//g' | sed 's/| //g'`
    echo $instance_id
}


get_volume_id() {
    local volume_name=$1
    volume_id=`cinder list | grep $volume_name | sed 's/ |.*//g' | sed 's/| //g'`
    echo $volume_id
}

get_port_id() {
    local port_name=$1
    port_id=`neutron port-list | grep $port_name | sed 's/ |.*//g' | sed 's/| //g'`
    echo $port_id
}

boot_node() {
    local instance_name=$1
    local instance_ip=$2
    local is_storage=$3
    local flavor=$4

    if [ "$start_node" == "True" ]; then
        nova boot --flavor "${flavor}"  --image "${image_id}" \
                  --nic net-id="${api_network_id}",v4-fixed-ip="192.168.20.${instance_ip}" \
                  ${instance_name}
    fi
    instance_id=`get_instance_id $instance_name`
    wait_instance_active $instance_id

    create_port $external_network_id $external_subnet_id "192.168.30.${instance_ip}" "external_port_for_${instance_name}"
    external_port_id=`get_port_id "external_port_for_${instance_name}"`
    nova interface-attach --port-id $external_port_id $instance_id
              
    create_port $storage_network_id $storage_subnet_id "192.168.40.${instance_ip}" "storage_port_for_${instance_name}"
    storage_port_id=`get_port_id "storage_port_for_${instance_name}"`
    nova interface-attach --port-id $storage_port_id $instance_id
              
    create_port $tunnel_network_id $tunnel_subnet_id "192.168.50.${instance_ip}" "tunnel_port_for_${instance_name}"
    tunnel_port_id=`get_port_id "tunnel_port_for_${instance_name}"`
    nova interface-attach --port-id $tunnel_port_id $instance_id

    if [ "${is_storage}" == "is_storage" ]; then
        for i in $(seq 1 $volume_num); do 
            create_volume "${instance_name}_${i}"
            volume_id=`get_volume_id "${instance_name}_${i}"`
            nova volume-attach $instance_name $volume_id
        done
    fi
}

create_volume() {
    local volume_name=$1

    cinder list | grep $volume_name
    if [ $? != 0 ]; then
            cinder create --display-name "$volume_name" 10
    fi        
}

set_network() {
    local ip_addr=$1
    network_port=`neutron port-list | grep $ip_addr | awk '{printf $2}'`
    neutron port-update $network_port --allowed_address_pairs type=dict list=true ip_address=192.168.20.200 ip_address=192.168.30.151

}

set_network 192.168.20.18
exit 0

boot_node control01  12 no_storage memory-2 &
boot_node control02  13 no_storage memory-2 &
boot_node control03  14 no_storage memory-2 &
boot_node storage01  15 is_storage standard-1 &
boot_node storage02  16 is_storage standard-1 &
boot_node storage03  17 is_storage standard-1 &
boot_node network01  18 no_storage standard-1 &
boot_node compute01  19 no_storage standard-1 &





