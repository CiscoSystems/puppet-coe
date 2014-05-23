class coe::cobbler::profile (
  $profiles = hiera(cobbler_profiles),
){

  create_resources(cobblerprofile, $profiles)

}
