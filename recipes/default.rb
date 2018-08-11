#
# Cookbook:: jenkins
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.
platform = node['platform']

if platform == "centos" || platform == "fedora"
  bash 'Give Jenkins Permissions to use Nginx' do
    code <<-EOH
    setsebool -P httpd_can_network_relay 1
    setsebool -P httpd_can_network_connect 1
    setsebool -P httpd_can_network_connect_db 1
    setsebool -P allow_user_mysql_connect 1
    touch /tmp/setsebool
    EOH
    action :run
    not_if { File.exist?('/tmp/setsebool') }
  end
end

if platform == 'centos' || platform == 'fedora'
  bash 'Install Jenkins Repo and update the Repo' do
    code <<-EOH
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat/jenkins.io.key
    yum mackecache && yum update -y
    touch /tmp/repo-installed
    EOH
    action :run
    not_if { File.exist?('/tmp/repo-installed') }
  end

  package 'jenkins' do
    action :install
  end

  service 'jenkins' do
    action [:start, :enable]
  end
end

if platform == 'centos' || platform == 'fedora'
  template '/etc/yum.repos.d/nginx.repo' do
    source 'nginx.repo.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
      :distro => node['distro'],
    })
    action :create
  end

  bash 'Recreate cache and Update The Repoistory' do
    code <<-EOH
    yum makecache
    yum update -y
    touch /tmp/nginx-update
    EOH
    action :run
    not_if { File.exist?('/tmp/nginx-update') }
  end

  package 'nginx' do
    action :install
  end

  template '/etc/nginx/conf.d/default.conf' do
    source 'jenkins.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
      :fqdn    => node['fqdn'],
      :portnum => node['portnum'],
      :host    => node['hostname'],
    })
    action :create
  end

  service 'nginx' do
    action [:start, :enable]
  end
end

if platform == 'ubuntu' || platform == 'debian'
  bash 'Install Jenkins Repo' do
    code <<-EOH
    wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
    sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    apt-get update
    touch /tmp/jenkins-repo
    EOH
    not_if { File.exist?('/tmp/jenkins-repo') }
    action :run
  end

  package 'jenkins' do
    action :install
  end

  template '/tmp/install-repo.sh' do
    source 'install-repo.sh.erb'
    owner 'root'
    group 'root'
    mode '0755'
    variables ({
      :distro   => node['platform'],
      :codename => node['lsb']['codename'],
    })
    action :create
  end

  cookbook_file '/tmp/nginx.key' do
    source 'nginx.key'
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end

  execute 'Install Nginx Repo' do
    command 'bash /tmp/install-repo.sh | tee -a /tmp/nginx-repo'
    action :run
    not_if { File.exist?('/tmp/nginx-repo') }
  end

  package 'nginx' do
    action :install
  end

  template '/etc/nginx/conf.d/default.conf' do
    source 'jenkins.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
      :fqdn    => node['fqdn'],
      :portnum => node['portnum'],
      :host    => node['hostname'],
    })
    action :create
  end

  service 'nginx' do
    action [:start, :enable]
  end
end

