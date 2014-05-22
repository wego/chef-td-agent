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
  gid      group_name
  home     '/var/run/td-agent'
  shell    '/bin/false'
  password nil
  supports :manage_home => true
  action   [:create, :manage]
end

directory install_dir do
  owner user_name
  group group_name
  mode '0755'
  action :create
end

directory '/var/log/td-agent' do
  owner user_name
  group group_name
end

# all config file will be in conf.d folder
# and to be clear we always use include in the main config
directory "#{install_dir}/conf" do
  mode "0755"
end

include_recipe 'td-agent::install_from_package'

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

service "td-agent" do
  action [ :enable, :start ]
  subscribes :restart, resources(:template => "#{install_dir}/td-agent.conf")
end

node[:td_agent][:sources] && node[:td_agent][:sources].each do |key, attributes|
  template key do
    path      "#{install_dir}/conf/source_#{key}.conf"
    source    "plugin_source.conf.erb"
    variables({ :attributes => attributes })
    notifies :restart, "service[td-agent]", :immediately
  end
end

node[:td_agent][:matches] && node[:td_agent][:matches].each do |key, attributes|
  template key do
    path      "#{install_dir}/conf/match_#{key}.conf"
    source    "plugin_match.conf.erb"
    variables({:attributes => attributes})
    notifies :restart, "service[td-agent]", :immediately
  end
end