#/usr/share/puppet/modules/coe/manifests/
define coe::ovs(
  $module      = 'module',
  $facility    = 'facility',
  $log_level   = 'log_level',
){
  exec {'$name':
    command  => "ovs-appctl vlog/set ${module}:${facility}:${log_level}",
    path     => '/bin:/usr/bin:/sbin:/usr/sbin',
    require  => Service['openvswitch'],
  }
}
