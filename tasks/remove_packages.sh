# Task boltello::remove_packages
#
packages=$PT_packages
packages=($(echo $packages))

# Check for package and remove if present
for package in "${packages[@]}"; do
    [[ $(rpm -q $package) ]] && /bin/yum -y remove $package
done

 
