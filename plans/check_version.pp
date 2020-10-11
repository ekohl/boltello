# == Plan boltello::check_version
#
plan boltello::check_version(
  TargetSpec $nodes,
  String $boltdir = boltello::get_boltdir(),
  Boolean $force = false,
  Enum['plan', 'user'] $caller = 'user'
) {
  # If user request, print versions for each node and exit
  if $caller == 'user' {
    get_targets($nodes).each |TargetSpec $node| {

      # Get versions from Facter
      $facter_query = run_command("/opt/puppetlabs/bin/facter --custom-dir=$boltdir/lib/facter boltello", 
        $node, 
        'retrieve installed versions from facter', 
        _catch_errors => true
      )

      if $facter_query.ok {
        $versions = $facter_query.first.value['stdout']

        out::message("Versions from node ${node.name}: ${versions}")
      } else {
        err("Critical: could not fetch version on ${node.name}")
      }
    }
  } else {

    # Get versions from packaging
    $katello_query = run_command('/bin/rpm -q --queryformat "%{version}" katello', 
      $nodes, 
      'check installed katello rpm version', 
      _catch_errors => true
    )

    # $foreman_query = run_command('/bin/rpm -q --queryformat "%{version}" foreman', 
      # $nodes, 
      # 'check installed foreman rpm version', 
      # _catch_errors => true
    # )
  
    $katello_rpm_version = $katello_query.first.value['stdout']
    # $foreman_rpm_version = $foreman_query.first.value['stdout']
  
    $installed_katello = $katello_rpm_version ? {
      /[0-9]/ => Float($katello_rpm_version.regsubst('(.*)\..*', '\1')),
      default => Float('0.0')
    }

    # $installed_foreman = $foreman_rpm_version ? {
      # /[0-9]/ => Float($foreman_rpm_version.regsubst('(.*)\..*', '\1')),
      # default => Float('0.0')
    # }

    # Get foreman/katello version from hiera yaml
    $katello_version = Float(lookup('boltello::katello_version'))
    # $foreman_version = Float(lookup('boltello::foreman_version'))

    $installed = ($installed_katello > Float('0.0'))
    $threshold = $installed and ($katello_version - $installed_katello > Float('0.009'))
    $staledata = $installed and ($installed_katello - $katello_version > Float('0.02'))

    # A discrepancy of more than one version
    if $threshold {
      warning("Advisory: use the 'boltello::katello_upgrade' plan")
      return true
    } elsif $staledata {
      warning("Advisory: use the 'boltello::update_metadata' plan")
      return true
    }

    if ($installed_katello >= $katello_version) {
      if !$force {
        warning("Advisory: katello ${$installed_katello} is installed on ${nodes.name}")
        warning("  use argument 'force=true' to skip this check")
        warning("  run plan 'boltello::check_version' to check version")
        return true
      } else {
        if ($installed_katello == $katello_version) {
          warning("Advisory: katello ${$installed_katello} is installed on ${nodes.name}; argument 'force=true' provided, continuing...")
          return false
        }
      }
    }
  }
}
