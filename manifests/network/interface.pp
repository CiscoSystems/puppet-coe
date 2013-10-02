# == Class: coe::network::interface
#
# Allows users to dynamicly create and manage network interfaces.
#
# === Parameters
#
# [ipaddress] IP address of $interface_name. Required.
# [netmask] Netmask of $interface_name. Required.
# [interface_name] Name of interface.  This is typically eth<interface_number>.
#   If VLAN package is installed, the name can also be
#   eth<interface_number>.<vlan_number>. Defaults to 'eth1'.
# [ensure] Whether the $interface_name should be present or absent.
#   Defaults to 'present'.
# [hotplug] Whether to start the interface $interface_name when the kernel detects
#   a hotplug event from the interface.  Defaults to 'false'.
# [family] Interface family. Defaults to 'inet'.
# [method] How to assign an IP address to the $interface_name.
#   Defaults to 'static'.
# [onboot] Whether to bring the interface up during the boot-up process.
#   Defaults to 'true'.
#
# === Example
#
# class {'coe::network::interface':
#   ipaddress      => '10.10.10.10',
#   netmask        => '255.255.255.0',
#   interface_name => 'eth3',
# }

class coe::network::interface(
  $ipaddress,
  $netmask,
  $interface_name = 'eth1',
  $ensure         = 'present',
  $hotplug        = 'false',
  $family         = 'inet',
  $method         = 'static',
  $onboot         = 'true'
) {

  include network

  network_config { $interface_name:
    ensure     => $ensure,
    hotplug    => $hotplug,
    family     => $fmaily,
    method     => $method,
    ipaddress  => $ipaddress,
    netmask    => $netmask,
    onboot     => $onboot,
    notify     => Exec['network-restart']
  }

  # Changed from service to exec due to Ubuntu bug #440179
  exec { 'network-restart':
    command     => '/etc/init.d/networking restart',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true
  }
}
