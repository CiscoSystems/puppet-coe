class coe::ceph::control(
  $fsid = $::ceph_monitor_fsid,
) {

  include 'ceph::package'

  Package['ceph'] -> Ceph::Key <<| title == 'admin' |>>

  class { 'ceph::apt::ceph': release => $::ceph_release }

  package { 'ceph-common':
    ensure  => present,
    require => Apt::Source['ceph'],
  }

  if !$::controller_has_mon {
      class { 'ceph::conf': fsid => $fsid }
  }

  $ceph_admin_key = $::controller_has_mon ? {
    true    => 'ceph-admin-key',
    false   => 'copy the admin key',
    default => 'copy the admin key',
  }

  file { '/etc/ceph/client.admin':
    ensure  => present,
    mode    => 0644,
    require => Exec[$ceph_admin_key],
  }

  file { '/etc/ceph/keyring':
    mode    => 0644,
    require => Exec[$ceph_admin_key],
  }

  exec { 'copy the admin key':
    command => 'cp /etc/ceph/keyring /etc/ceph/client.admin',
    creates => '/etc/ceph/client.admin',
    require => Package['ceph'],
  }

  if $::glance_ceph_enabled {
    exec { 'create the pool':
      command => "/usr/bin/ceph osd pool create ${::glance_ceph_pool} 128",
      unless  => "/usr/bin/rados lspools | grep -sq ${::glance_ceph_pool}",
      require => Exec[$ceph_admin_key],
      notify  => [ Service['glance-api'], Service['glance-registry'] ],
    }
  }

}
