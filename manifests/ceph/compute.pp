class coe::ceph::compute(
  $poolname = 'volumes',
  $fsid = $::ceph_monitor_fsid,
) {

  include 'ceph::package'

  Package['ceph'] -> Ceph::Key <<| title == 'admin' |>>

  class { 'ceph::apt::ceph': release => $::ceph_release }

  package { 'ceph-common':
    ensure => present,
    require => Apt::Source['ceph'],
  }

  package { 'python-ceph':
    ensure => present,
    require => Apt::Source['ceph'],
  }
 
  package { 'sysfsutils':
    ensure => present,
  }

  class { 'ceph::conf':
    fsid      => $fsid,
    conf_owner => 'cinder',
    conf_group => 'cinder',
  }

  file { '/etc/ceph/secret.xml':
    content => template('coe/secret.xml-compute.erb'),
    require => Package['ceph-common'],
  }

  file { '/etc/ceph/uuid_injection.sh':
    content => template('coe/uuid_injection.erb'),
    mode    => 0750,
    require => Exec['set-secret-value virsh'],
  }

  file { '/etc/ceph/client.admin':
    ensure => present,
    owner => 'cinder',
    group => 'cinder',
    mode  => '660',
    require => Exec['copy the admin key to make cinder work'],
  }

  file { '/etc/ceph/keyring':
    owner => 'cinder',
    group => 'cinder',
    mode  => 0600,
  }
  
  exec { 'copy the admin key to make cinder work':
    command => 'cp /etc/ceph/keyring /etc/ceph/client.admin',
    creates => '/etc/ceph/client.admin',
    require => [ Package['ceph'], Ceph::Key['admin'] ],
  }

  exec { 'get-or-set virsh secret':
    command => '/usr/bin/virsh secret-define --file /etc/ceph/secret.xml | /usr/bin/awk \'{print $2}\' | sed \'/^$/d\' > /etc/ceph/virsh.secret',
    creates => "/etc/ceph/virsh.secret",
    require => [ Package['ceph'], Ceph::Key['admin'], File['/etc/ceph/secret.xml'] ],
  }

  exec { 'set-secret-value virsh':
    command => "/usr/bin/virsh secret-set-value --secret $(cat /etc/ceph/virsh.secret) --base64 $(ceph auth get-key client.admin)",
    require => Exec['get-or-set virsh secret'],
  }

  exec { 'create the pool':
    command => "/usr/bin/ceph osd pool create volumes 128",
    unless  => "/usr/bin/rados lspools | grep -sq volumes",
    require => Exec['set-secret-value virsh'],
  }

  exec { 'install key in cinder.conf':
    command => '/etc/ceph/uuid_injection.sh',
    provider => shell,
    require  => [ File['/etc/ceph/uuid_injection.sh'], Exec['create the pool'] ],
    notify  => [ Service['cinder-volume'], Service['nova-compute'] ],
  }

}
