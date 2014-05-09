class coe::cobbler::system (
  $systems = hiera(cobbler_systems),
){

  $defaults = {
    require => Service[$cobbler::service_name]
  }

  create_resources(cobblersystem, $systems, $defaults)

}
