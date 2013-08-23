#
# set up index.html on build node
# with links to various web management interfaces
# installed by COE

class coe::site_index {

  file { '/var/www':
    ensure  => directory,
    mode    => '0755',
  }

    file { "/var/www/index.html":
        ensure  => file,
        mode    => 0644,
        owner   => root,
        group   => root,
        content => template("coe/site_index.erb"),
        require => file['/var/www'],
    }

    file { "/var/www/header-logo.png":
        ensure => file,
        mode   => 0644,
        owner  => root,
        group  => root,
        source => "puppet:///modules/coe/header-logo.png",
        require => file['/var/www'],
    }
}
