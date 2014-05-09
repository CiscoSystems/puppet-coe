class coe::cobbler::distro (
  $distros = hiera(cobbler_distros),
){

  create_resources(cobbler::add_distro, $distros)

}
