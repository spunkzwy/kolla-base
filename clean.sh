source libs/common
nova delete control01 &
nova delete control02 &
nova delete control03 &
nova delete storage01 &
nova delete storage02
nova delete storage03
nova delete network01
nova delete compute01
nova delete admin-server
for a in `cinder list | grep available | awk '{printf $2"\n"}'`;do cinder delete $a;done
neutron router-interface-delete public_router api_network
neutron router-delete public_router
neutron net-delete openstack
floatingip_id=`get_floatingip_id`
neutron floatingip-delete $floatingip_id
