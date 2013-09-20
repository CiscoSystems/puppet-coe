class coe::ceph::compute(
  $poolname = 'volumes',
  $fsid = $::ceph_monitor_fsid,
) {

  include 'ceph::package'

  Package['ceph'] -> Ceph::Key <<| title == 'admin' |>>

  package { 'ceph-common':
    ensure  => present,
  }

  package { 'python-ceph':
    ensure  => present,
  }
 
  package { 'sysfsutils':
    ensure => present,
  }
  
  if ( (!$::osd_on_compute) and (!$::computes_have_mons) and (!$::ceph_combo) ) {
    class { 'ceph::conf': fsid => $fsid }
  }

  file { '/etc/ceph/secret.xml':
    content => template('coe/secret.xml-compute.erb'),
    require => Package['ceph-common'],
  }

  file { '/etc/ceph/client.admin':
    ensure  => present,
    mode    => 0644,
    require => Exec['copy the admin key to make cinder work'],
  }

   file { '/etc/ceph/keyring':
    mode    => 0644,
    require => Exec['copy the admin key to make cinder work'],
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

}
