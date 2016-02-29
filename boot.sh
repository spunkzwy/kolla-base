#!/bin/bash 

set -x
# define variable
image_id="631e33e1-5fc1-4d60-8c6f-dc62ccd81a64"
management_network_id="e7a245db-12f0-4874-918b-898a871ab67c"
publice_network_id="c131ccbb-3275-453c-ae39-71fe507deee6"
timeout=10

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


boot_control() {
    local instance_name=$1
    local instance_ip=$2

    nova boot --flavor memory-2 --image "${image_id}" \
              --nic net-id="${management_network_id}",v4-fixed-ip="${instance_ip}" \
              ${instance_name}
              
}

boot_compute() {
    local instance_name=$1
    local instance_ip=$2

    nova boot --flavor standard-2 --image "${image_id}" \
              --nic net-id="${management_network_id}",v4-fixed-ip="${instance_ip}" \
              ${instance_name}
              
}

boot_network() {
    local instance_name=$1
    local instance_ip=$2

    nova boot --flavor standard-1 --image "${image_id}" \
              --nic net-id="${management_network_id}",v4-fixed-ip="${instance_ip}" \
              ${instance_name}
              
    instance_id=`get_instance_id $instance_name`
    wait_instance_active $instance_id
    nova interface-attach --net-id "${publice_network_id}" "${instance_id}"
}


boot_storage() {
    local instance_name=$1
    local instance_ip=$2

    nova boot --flavor standard-1 --image "${image_id}" \
              --nic net-id="${management_network_id}",v4-fixed-ip="${instance_ip}" \
              ${instance_name}
    instance_id=`get_instance_id $instance_name`
    cinder create --display-name "${instance_name}" 10
    wait_instance_active $instance_id
    volume_id=`get_volume_id $instance_name`
    nova volume-attach $instance_name $volume_id
}


boot_network "network01" "192.168.20.11"

boot_control "control01" "192.168.20.12"
boot_control "control02" "192.168.20.13"
boot_control "control03" "192.168.20.14"

boot_compute "compute01" "192.168.20.15"

boot_storage "storage01" "192.168.20.16"
boot_storage "storage02" "192.168.20.17"
boot_storage "storage03" "192.168.20.18"






