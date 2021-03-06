def initialize_repo_on_host(host, os, use_nightlies)
  case os
  when :debian
    if options[:type] == 'aio' then
      if use_nightlies
        on host, "curl -o /etc/apt/sources.list.d/pl-puppetserver-latest-$(lsb_release -sc).list http://nightlies.puppetlabs.com/puppetserver-latest/repo_configs/deb/pl-puppetserver-latest-$(lsb_release -sc).list"
        on host, "curl -o /etc/apt/sources.list.d/pl-puppet-agent-latest-$(lsb_release -sc).list http://nightlies.puppetlabs.com/puppet-agent-latest/repo_configs/deb/pl-puppet-agent-latest-$(lsb_release -sc).list"
      else
        on host, "curl -O http://apt.puppetlabs.com/puppetlabs-release-pc1-$(lsb_release -sc).deb"
        on host, "dpkg -i puppetlabs-release-pc1-$(lsb_release -sc).deb"
      end
    else
      on host, "curl -O http://apt.puppetlabs.com/puppetlabs-release-$(lsb_release -sc).deb"
      on host, "dpkg -i puppetlabs-release-$(lsb_release -sc).deb"
    end
      on host, "apt-get install debian-archive-keyring"
      on host, "apt-get update"
  when :redhat
    if options[:type] == 'aio' then
      /^(el|centos)-(\d+)-(.+)$/.match(host.platform)
      variant = ($1 == 'centos') ? 'el' : $1
      version = $2
      arch = $3

      if use_nightlies
        on host, "curl -o /etc/yum.repos.d/pl-puppetserver-latest-#{variant}-#{version}-#{arch}.repo http://nightlies.puppetlabs.com/puppetserver-latest/repo_configs/rpm/pl-puppetserver-latest-#{variant}-#{version}-#{arch}.repo"
        on host, "curl -o /etc/yum.repos.d/pl-puppet-agent-latest-#{variant}-#{version}-#{arch}.repo http://nightlies.puppetlabs.com/puppet-agent-latest/repo_configs/rpm/pl-puppet-agent-latest-#{variant}-#{version}-#{arch}.repo"
      else
        on host, "curl -O http://yum.puppetlabs.com/puppetlabs-release-pc1-#{variant}-#{version}.noarch.rpm"
        on host, "rpm -i puppetlabs-release-pc1-#{variant}-#{version}.noarch.rpm"
      end
    else
      on host, "yum clean all -y"
      on host, "yum upgrade -y"
      create_remote_file host, '/etc/yum.repos.d/puppetlabs-dependencies.repo', <<-REPO.gsub(' '*8, '')
[puppetlabs-dependencies]
name=Puppet Labs Dependencies - $basearch
baseurl=http://yum.puppetlabs.com/el/$releasever/dependencies/$basearch
gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1
      REPO

      create_remote_file host, '/etc/yum.repos.d/puppetlabs-products.repo', <<-REPO.gsub(' '*8, '')
[puppetlabs-products]
name=Puppet Labs Products - $basearch
baseurl=http://yum.puppetlabs.com/el/$releasever/products/$basearch
gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1
      REPO

      create_remote_file host, '/etc/yum.repos.d/epel.repo', <<-REPO
[epel]
name=Extra Packages for Enterprise Linux $releasever - $basearch
baseurl=http://download.fedoraproject.org/pub/epel/$releasever/$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-$releasever&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=0
      REPO
    end
  when :fedora
    create_remote_file host, '/etc/yum.repos.d/puppetlabs-dependencies.repo', <<-REPO.gsub(' '*8, '')
[puppetlabs-dependencies]
name=Puppet Labs Dependencies - $basearch
baseurl=http://yum.puppetlabs.com/fedora/f$releasever/dependencies/$basearch
gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1
    REPO

    create_remote_file host, '/etc/yum.repos.d/puppetlabs-products.repo', <<-REPO.gsub(' '*8, '')
[puppetlabs-products]
name=Puppet Labs Products - $basearch
baseurl=http://yum.puppetlabs.com/fedora/f$releasever/products/$basearch
gpgkey=http://yum.puppetlabs.com/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1
    REPO
  else
    raise ArgumentError, "Unsupported OS '#{os}'"
  end
end

unless (test_config[:skip_presuite_provisioning])
  step "Install Puppet Labs repositories" do
    hosts.each do |host|
      initialize_repo_on_host(host, test_config[:os_families][host.name], test_config[:use_nightlies])
    end
  end
end
