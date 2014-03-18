#
# class coe::base
#
# This class contains configuraiton that must be
# performed on every openstack node configured
# as a part of the COSI solution.
#
class coe::base(
  $build_node_name,
  $controller_hostname,
  $controller_node_internal,
  $domain_name,
  $package_repo            = 'cisco_repo',
  $puppet_repo             = 'cisco_repo',
  $openstack_release       = 'havana',
  $openstack_repo_location = false,
  $supplemental_repo       = false,
  $puppet_repo_location    = false,
  $pocket                  = '',
  $ubuntu_repo             = 'updates',
  # optional external services
  $node_gateway            = false,
  $proxy                   = false,
) {

  # Disable pipelining to avoid unfortunate interactions between apt and
  # upstream network gear that does not properly handle http pipelining
  # See https://bugs.launchpad.net/ubuntu/+source/apt/+bug/996151 for details
  if ($::osfamily == 'debian') {
    file { '/etc/apt/apt.conf.d/00no_pipelining':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => 'Acquire::http::Pipeline-Depth "0";'
    }

    $cisco_key_content = '-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.11 (GNU/Linux)

mQENBE/oXVkBCACcjAcV7lRGskECEHovgZ6a2robpBroQBW+tJds7B+qn/DslOAN
1hm0UuGQsi8pNzHDE29FMO3yOhmkenDd1V/T6tHNXqhHvf55nL6anlzwMmq3syIS
uqVjeMMXbZ4d+Rh0K/rI4TyRbUiI2DDLP+6wYeh1pTPwrleHm5FXBMDbU/OZ5vKZ
67j99GaARYxHp8W/be8KRSoV9wU1WXr4+GA6K7ENe2A8PT+jH79Sr4kF4uKC3VxD
BF5Z0yaLqr+1V2pHU3AfmybOCmoPYviOqpwj3FQ2PhtObLs+hq7zCviDTX2IxHBb
Q3mGsD8wS9uyZcHN77maAzZlL5G794DEr1NLABEBAAG0NU9wZW5TdGFja0BDaXNj
byBBUFQgcmVwbyA8b3BlbnN0YWNrLWJ1aWxkZEBjaXNjby5jb20+iQE4BBMBAgAi
BQJP6F1ZAhsDBgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRDozGcFPtOxmXcK
B/9WvQrBwxmIMV2M+VMBhQqtipvJeDX2Uv34Ytpsg2jldl0TS8XheGlUNZ5djxDy
u3X0hKwRLeOppV09GVO3wGizNCV1EJjqQbCMkq6VSJjD1B/6Tg+3M/XmNaKHK3Op
zSi+35OQ6xXc38DUOrigaCZUU40nGQeYUMRYzI+d3pPlNd0+nLndrE4rNNFB91dM
BTeoyQMWd6tpTwz5MAi+I11tCIQAPCSG1qR52R3bog/0PlJzilxjkdShl1Cj0RmX
7bHIMD66uC1FKCpbRaiPR8XmTPLv29ZTk1ABBzoynZyFDfliRwQi6TS20TuEj+ZH
xq/T6MM6+rpdBVz62ek6/KBcuQENBE/oXVkBCACgzyyGvvHLx7g/Rpys1WdevYMH
THBS24RMaDHqg7H7xe0fFzmiblWjV8V4Yy+heLLV5nTYBQLS43MFvFbnFvB3ygDI
IdVjLVDXcPfcp+Np2PE8cJuDEE4seGU26UoJ2pPK/IHbnmGWYwXJBbik9YepD61c
NJ5XMzMYI5z9/YNupeJoy8/8uxdxI/B66PL9QN8wKBk5js2OX8TtEjmEZSrZrIuM
rVVXRU/1m732lhIyVVws4StRkpG+D15Dp98yDGjbCRREzZPeKHpvO/Uhn23hVyHe
PIc+bu1mXMQ+N/3UjXtfUg27hmmgBDAjxUeSb1moFpeqLys2AAY+yXiHDv57ABEB
AAGJAR8EGAECAAkFAk/oXVkCGwwACgkQ6MxnBT7TsZng+AgAnFogD90f3ByTVlNp
Sb+HHd/cPqZ83RB9XUxRRnkIQmOozUjw8nq8I8eTT4t0Sa8G9q1fl14tXIJ9szzz
BUIYyda/RYZszL9rHhucSfFIkpnp7ddfE9NDlnZUvavnnyRsWpIZa6hJq8hQEp92
IQBF6R7wOws0A0oUmME25Rzam9qVbywOh9ZQvzYPpFaEmmjpCRDxJLB1DYu8lnC4
h1jP1GXFUIQDbcznrR2MQDy5fNt678HcIqMwVp2CJz/2jrZlbSKfMckdpbiWNns/
xKyLYs5m34d4a0it6wsMem3YCefSYBjyLGSd/kCI/CgOdGN1ZY1HSdLmmjiDkQPQ
UcXHbA==
=v6jg
-----END PGP PUBLIC KEY BLOCK-----'

    $puppet_key_content = '-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.11 (GNU/Linux)

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
ykz5a/8840rWqc7sLA7lKA==
=HVuX
-----END PGP PUBLIC KEY BLOCK-----'

    # A commit in h.1 rationalized how the URL's for the supplemental
    # and main repos were specified.  For backward compatibility
    # purposes (due to bug #1269856 which enables people using h.0
    # to wind up using an unexpected repository), we need to at least
    # provide a URL that doesn't break without for those without
    # the necessary change.
    if ($openstack_repo_location == 'http://openstack-repo.cisco.com/openstack') {
      $openstack_repo_location_real = "${openstack_repo_location}/cisco"
      warning("openstack_repo_location has changed format and was set to a known bad value (see bug #1269856), setting to $openstck_repo_location_real")
    }
    else {
      $openstack_repo_location_real = $openstack_repo_location
    }

    # Load apt prerequisites.  This is only valid on Ubuntu systmes
    if($package_repo == 'cisco_repo') {
      apt::source { "cisco-openstack-mirror_${openstack_release}":
        location    => "${openstack_repo_location_real}",
        release     => "${openstack_release}${pocket}",
        repos       => "main",
        key         => "E8CC67053ED3B199",
        proxy       => $proxy,
        key_content => $cisco_key_content,
      }

      apt::pin { "cisco":
        priority   => '990',
        originator => 'Cisco'
      }

      if $supplemental_repo {
        apt::source { "cisco_supplemental-openstack-mirror_havana":
          location    => $supplemental_repo,
          release     => "${openstack_release}${pocket}",
          repos       => "main",
          key         => "E8CC67053ED3B199",
          proxy       => $proxy,
          key_content => $cisco_key_content,
        }
        apt::pin { "cisco_supplemental":
          priority   => '990',
          originator => 'Cisco_Supplemental'
        }
      }

    } elsif($package_repo == 'cloud_archive') {
      if $openstack_release == 'havana' {
        class { 'openstack::repo::uca':
          release =>  $openstack_release,
          repo    =>  $ubuntu_repo,
        }
      } else {
        class { 'openstack::repo::uca':
          release =>  $openstack_release,
        }
      }
    } else {
      fail("Unsupported package repo ${package_repo}")
    }

    # Set up the puppet module repo.
    if($puppet_repo == 'cisco_repo') {
      apt::source { "cisco-openstack-puppet-mirror_${openstack_release}":
        location    => $puppet_repo_location,
        release     => "${openstack_release}${pocket}",
        repos       => 'main',
        key         => 'EEE88720',
        proxy       => $proxy,
        key_content => $puppet_key_content,
      }

      apt::pin { 'cisco_puppet':
        priority   => '991',
        originator => 'Cisco'
      }
    }
  } elsif ($osfamily == 'redhat') {

    if($package_repo == 'cisco_repo') {
      if ! $openstack_repo_location_real {
        fail("Parameter openstack_repo_location must be set when package_repo is cisco_repo")
      }
      # A cisco yum repo to carry any custom patched rpms
      yumrepo { 'cisco-openstack-mirror':
        descr    => 'Cisco Openstack Repository',
        baseurl  => $openstack_repo_location_real,
        enabled  => '1',
        gpgcheck => '1',
        gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-Cisco',
      }

      file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-Cisco':
        source => 'puppet:///modules/coi/RPM-GPG-KEY-Cisco',
        owner  => root,
        group  => root,
        mode   => 644,
      }
    }

    # include epel to satisfy necessary dependencies
    include openstack::repo::epel

    # includes RDO openstack upstream repo
    include openstack::repo::rdo

    # add a resource dependency so yumrepo loads before package
    Yumrepo <| |> -> Package <| |>

  }

  # /etc/hosts entries for the controller nodes
  ensure_resource ( 'host', "$controller_hostname.$domain_name", {
    ip           => $controller_node_internal,
    host_aliases => $controller_hostname,
    }
  )

  include collectd
}
