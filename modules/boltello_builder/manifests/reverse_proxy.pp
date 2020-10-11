# == Class boltello_builder::reverse_proxy
#
class boltello_builder::reverse_proxy (
  Boolean $enable_remote_agent_install,
  Boolean $puppetca = lookup('foreman_proxy::puppetca')
){
  # Fail unless proxy.yaml is used
  unless $facts['boltello_role'] == 'proxy' {
    fail('nginx only available with the proxy profile')
  }

  include ::nginx

  if $enable_remote_agent_install {
    file { '/usr/share/nginx':
      ensure  => directory,
      require => Class['::nginx'],
    }

    file { '/usr/share/nginx/install':
      ensure  => present,
      require => File['/usr/share/nginx'],
      content => template('boltello_builder/install.erb'),
    }
  }
}
