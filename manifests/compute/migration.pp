#
# Copyright (C) 2014 Cisco Systems, Inc.
#
# Author: Donald Talton <dotalton@cisco.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: coe::compute::migration
#
# Configures additional storage migration features for Nova
#
# === Parameters:
#
# [*migration_support*]
#   (optional) Enables the ability to configure NFS services.
#   Defaults to false.
#
# [*nfs_mount_path*]
#   (optional) The local path to mount the NFS export to.
#   Defaults to /var/lib/nova/instances
#
# [*nfs_mount_device*]
#   (optional) The remote NFS export (eg nfs.server.com:/instances)
#   Defaults to undefined.

class coe::compute::migration(
  $migration_support = false,
  $nfs_mount_path    = '/var/lib/nova/instances',
  $nfs_mount_device  = undef,
  $nfs_fs_type       = 'nfs',
  $nfs_mount_options = 'auto',
){

  if $migration_support {

    ensure_packages(['nfs-common'])

    if $nfs_mount_path and $nfs_mount_device {
      file { $nfs_mount_path:
        ensure => directory,
        group  => 'nova',
        mode   => '0755',
        owner  => 'nova',
      }

      mount { $nfs_mount_path:
        ensure  => mounted,
        device  => $nfs_mount_device,
        fstype  => $nfs_fs_type,
        options => $nfs_mount_options,
        require => [ Package['nfs-common'], File[$nfs_mount_path] ],
      }

    } else {
      err('You must specify the nfs_mount_path and nfs_mount_device.')
    }

  }

}

