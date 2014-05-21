default[:td_agent][:user] = 'root'
default[:td_agent][:group] = 'root'
default[:td_agent][:install_dir] = '/etc/td-agent/'

default[:td_agent][:api_key] = ''

default[:td_agent][:plugins] = []

default[:td_agent][:includes] = false
default[:td_agent][:default_config] = true
default[:td_agent][:version] = '1.1.19'