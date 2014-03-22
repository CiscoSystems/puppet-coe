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
  $openstack_release       = 'havana',
  $openstack_repo_location = false,
  $supplemental_repo       = false,
  $pocket                  = '',
  $ubuntu_repo             = 'updates',
  # optional external services
  $node_gateway            = false,
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
      apt::source { "cisco-openstack-mirror_havana":
        location    => "${openstack_repo_location_real}",
        release     => "${openstack_release}${pocket}",
        repos       => "main",
        key         => "E8CC67053ED3B199",
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
  host { "$controller_hostname.$domain_name":
    ip           => $controller_node_internal,
    host_aliases => $controller_hostname,
  }
}
