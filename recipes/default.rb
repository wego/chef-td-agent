#
# Cookbook Name:: td-agent
# Recipe:: default
#
# Copyright 2011, Treasure Data, Inc.
#

group_name = node[:td_agent][:group]
user_name = node[:td_agent][:user]
install_dir = node[:td_agent][:install_dir]

group group_name do
  action :create
end

user user_name do
  comment  'td-agent'
  gid  group_name
  action  :create
end

directory install_dir do
  owner user_name
  group group_name
  mode '0755'
  action :create
end

# all config file will be in conf.d folder
# and to be clear we always use include in the main config
directory "#{install_dir}/conf.d" do
  mode "0755"
end

include_recipe 'td-agent::package'

template "#{install_dir}/td-agent.conf" do
  mode "0644"
  source "td-agent.conf.erb"
end

node[:td_agent][:plugins].each do |plugin|
  if plugin.is_a?(Hash)
    plugin_name, plugin_attributes = plugin.first
    td_agent_gem plugin_name do
      plugin true
      %w{action version source options gem_binary}.each do |attr|
        send(attr, plugin_attributes[attr]) if plugin_attributes[attr]
      end
    end
  elsif plugin.is_a?(String)
    td_agent_gem plugin do
      plugin true
    end
  end
end

if node[:td_agent][:source]
  node[:td_agent][:source].each do |config|
    template "#{config[:tag]}" do
      path      "/etc/fluent/config.d/source_#{config[:tag]}.conf"
      source    "plugin_source.conf.erb"
      variables config
      notifies :restart, "service[fluent]", :immediately
    end
  end

  node[:td_agent][:match].each do |config|
    cfg = config.dup
    template "#{cfg[:match]}" do
      path      "/etc/fluent/config.d/match_#{cfg[:match]}.conf"
      source    "plugin_match.conf.erb"
      variables({ :match => cfg.delete(:match), :type => cfg.delete(:type), :attributes => cfg })
      notifies :restart, "service[fluent]", :immediately
    end
  end
end

service "td-agent" do
  action [ :enable, :start ]
  subscribes :restart, resources(:template => "/etc/td-agent/td-agent.conf")
end