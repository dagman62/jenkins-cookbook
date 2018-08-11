node.default['portnum'] = '8080'
platform = node['platform']
if platform == 'fedora'
  node.default['distro'] = 'rhel'
else
  node.default['distro'] = node['platform']
end
