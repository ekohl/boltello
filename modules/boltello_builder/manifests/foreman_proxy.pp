# == Class boltello_builder::foreman_proxy
#
class boltello_builder::foreman_proxy (
  Boolean $puppetca = lookup('foreman_proxy::puppetca'),
  Boolean $enable_remote_execution,
  String $katello_server,
  String $foreman_proxy_dir,
  Integer $ssl_port,
  String $ssh_identity_dir,
  String $ssh_identity_file,
){
  # require ::foreman
  include ::foreman_proxy

  if $enable_remote_execution {
    include ::foreman_proxy::plugin::remote_execution::ssh

    Exec {
      require => Class['::foreman_proxy::plugin::remote_execution::ssh'],
    }

    exec { 'ensure_ssh_identity_dirs':
      command => "/bin/mkdir -p {'${ssh_identity_dir}','${foreman_proxy_dir}'} && /bin/chown foreman-proxy:foreman-proxy {'${ssh_identity_dir}','${foreman_proxy_dir}'}",
      creates => ["${ssh_identity_dir}", "${foreman_proxy_dir}"],
    }

    # https://access.redhat.com/solutions/4282171
    file { 'ensure_ssh_hidden_dir':
      path    => "${foreman_proxy_dir}/.ssh",
      ensure  => link,
      target  => "${ssh_identity_dir}",
      notify  => Exec['restorecon_ssh_hidden_dir'],
      require => Exec['ensure_ssh_identity_dirs'],
    }

    exec { 'restorecon_ssh_hidden_dir':
      command     => "/sbin/restorecon -RvF ${foreman_proxy_dir}/.ssh",
      refreshonly => true,
    }

    if $katello_server == $trusted['certname'] {
      exec { 'ensure_ssh_identity_file':
        command => "/bin/sudo -u foreman-proxy ssh-keygen -f ${ssh_identity_dir}/${ssh_identity_file} -N ''",
        creates => "${ssh_identity_dir}/${ssh_identity_file}",
        notify  => Service['foreman-proxy'],
      }
    }

    exec { 'ensure_ca_server_public_key':
      command => "/bin/curl -k https://${katello_server}:${ssl_port}/ssh/pubkey > ${ssh_identity_dir}/${ssh_identity_file}.pub",
      creates => "${ssh_identity_dir}/${ssh_identity_file}.pub",
      notify  => Service['foreman-proxy'],
      require => File['ensure_ssh_hidden_dir'],
    }

    exec { 'add_to_authorized_keys':
      command => "/bin/cat ${ssh_identity_dir}/${ssh_identity_file}.pub >> /root/.ssh/authorized_keys",
      unless  => "/bin/grep foreman-proxy@${katello_server} /root/.ssh/authorized_keys",
      notify  => Service['foreman-proxy'],
    }
  }
}
