class coe::ceph::combined(
  $iscompute = false,
  $fsid = $::ceph_monitor_fsid,
) {

  if !$iscompute {
    package { 'libvirt-bin':
      ensure => present,
    }
  }

  file { '/etc/ceph/secret.xml':
    content => template('coe/secret.xml-compute.erb'),
  }

  exec { 'copy the admin key to make cinder work':
    command => 'cp /etc/ceph/keyring /etc/ceph/client.admin',
    creates => '/etc/ceph/client.admin',
    unless  => 'test -e /etc/ceph/client.admin',
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

  exec { 'get-or-set virsh secret':
    command => '/usr/bin/virsh secret-define --file /etc/ceph/secret.xml | /usr/bin/awk \'{print $2}\' | sed \'/^$/d\' > /etc/ceph/virsh.secret',
    creates => "/etc/ceph/virsh.secret",
    unless  => "test -e /etc/ceph/virsh.secret",
    require => File['/etc/ceph/secret.xml'],
  }

  exec { 'set-secret-value virsh':
    command => "/usr/bin/virsh secret-set-value --secret $(cat /etc/ceph/virsh.secret) --base64 $(ceph auth get-key client.admin)",
    require => Exec['get-or-set virsh secret'],
  }

  # if cinder_ceph_enabled then create cinde rpool, same for glance

  if $::cinder_ceph_enabled {
    exec { 'create the cinder pool':
      command => "/usr/bin/ceph osd pool create volumes 128",
      unless  => "/usr/bin/rados lspools | grep -sq volumes",
      require => Exec['set-secret-value virsh'],
    }
  }

  if $::glance_ceph_enabled {
    exec { 'create the glance pool':
      command => "/usr/bin/ceph osd pool create images 128",
      unless  => "/usr/bin/rados lspools | grep -sq images",
      require => Exec['set-secret-value virsh'],
    }
  }


}
