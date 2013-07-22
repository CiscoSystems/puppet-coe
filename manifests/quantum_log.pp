#
# Add overriding rsyslog config file suppressing overzealous sudo logs
# from the Ubuntu default quantum rootwrap configuration

class coe::quantum_log {

    package { 'rsyslog':
        ensure  => 'installed',
    }

    file { '/etc/rsyslog.d/00-quantum_sudo.conf':
        ensure  => 'file',
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        require => Package['rsyslog'],
        content => template('coe/quantum_sudo_ubuntu.erb'),
        notify  => Service['rsyslog'],
    }

    service { 'rsyslog':
        ensure  => 'running',
        enable  => true,
        require => Package['rsyslog'],
    }

    file_line { 'quantum_sudoers_loglevels':
        ensure    => 'present',
        line      => 'Defaults:quantum syslog_badpri=err, syslog_goodpri=info',
        path      => '/etc/sudoers.d/quantum_sudoers',
        subscribe => Package['quantum'],
    }

}
