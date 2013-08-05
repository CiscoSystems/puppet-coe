class coe::ceph::glance(
  $fsid = $::ceph_monitor_fsid,
) {

  exec { 'create the pool':
    command => "/usr/bin/ceph osd pool create ${::glance_ceph_pool} 128",
    unless  => "/usr/bin/rados lspools | grep -sq ${::glance_ceph_pool}",
    require => Exec['ceph-admin-key'],
    notify  => [ Service['glance-api'], Service['glance-registry'] ],
  }

  file {'/etc/ceph/keyring':
    mode => 0644,
  }

}
