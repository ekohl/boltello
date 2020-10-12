# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#  puppet apply -e 'include boltello'
#
class boltello_builder (
  String[1] $message,
  Array[String] $classes,
) {
  # Greeting/server profile
  notice("${message}: ${facts['networking']['fqdn']}")

  # Source classes from Hiera
  $classes.unique.include

  # Ensure nginx
  unless $facts['boltello_role'] == 'proxy' {
    package { 'nginx':
      ensure => absent,
    }
  }
}
