default[:td_agent][:user] = 'td-agent'
default[:td_agent][:group] = 'td-agent'
default[:td_agent][:install_dir] = '/etc/td-agent'
default[:td_agent][:version] = '1.1.19'

default[:td_agent][:plugins] = []
default[:td_agent][:install_package] = true
default[:td_agent][:pid_file] = '/etc/td-agent/pid/td-agent.pid'
default[:td_agent][:log_file] = '/var/log/td-agent/td-agent.log'
