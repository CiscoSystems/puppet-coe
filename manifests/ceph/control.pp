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

  file { '/etc/ceph/client.admin':
    ensure  => present,
    mode    => 0644,
    require => Exec['copy the admin key to make glance work'],
  }

  file { '/etc/ceph/keyring':
    mode    => 0644,
    require => Exec['copy the admin key to make glance work'],
  }

  exec { 'copy the admin key to make glance work':
    command => 'cp /etc/ceph/keyring /etc/ceph/client.admin',
    creates => '/etc/ceph/client.admin',
    require => Package['ceph'],
  }

  exec { 'create the pool':
    command => "/usr/bin/ceph osd pool create ${::glance_ceph_pool} 128",
    unless  => "/usr/bin/rados lspools | grep -sq ${::glance_ceph_pool}",
    require => Exec['copy the admin key to make glance work'],
    notify  => [ Service['glance-api'], Service['glance-registry'] ],
  }

}
