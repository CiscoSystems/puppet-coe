class coe::nexus (
$nexus_credentials = undef,
$nexus_config      = undef
) 
{
  package { 'python-ncclient':
    ensure => installed,
  } ~> Service['quantum-server']

  # hack to make sure the directory is created
  Quantum_plugin_cisco<||> ->
  file {'/etc/quantum/plugins/cisco/nexus.ini':
    owner => 'root',
    group => 'root',
    content => template('coe/nexus.ini.erb')
  } ~> Service['quantum-server']

  if !$nexus_credentials {
    fail('No nexus credentials specified')
  }

  if !$nexus_config {
    fail('No nexus config specified')
  }

  file {'/var/lib/quantum/.ssh':
    ensure => directory,
    owner  => 'quantum',
    require => Package['quantum-server']
  }
  nexus_creds{ $nexus_credentials:
    require => File['/var/lib/quantum/.ssh']
  }
}

define nexus_creds {
  $args = split($title, '/')
  quantum_plugin_cisco_credentials {
    "${args[0]}/username": value => $args[1];
    "${args[0]}/password": value => $args[2];
  }
  exec {"${title}":
    unless => "/bin/cat /var/lib/quantum/.ssh/known_hosts | /bin/grep ${args[0]}",
    command => "/usr/bin/ssh-keyscan -t rsa ${args[0]} >> /var/lib/quantum/.ssh/known_hosts",
    user    => 'quantum',
    require => Package['quantum-server']
  }
}

