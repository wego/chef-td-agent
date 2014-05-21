#
# Cookbook Name:: td-agent
# Recipe:: default
#
# Copyright 2011, Treasure Data, Inc.
#

group_name = node[:td_agent][:group]
user_name = node[:td_agent][:user]

group group_name do
  action :create
end

user user_name do
  comment  'td-agent'
  gid  group_name
  action  :create
end

directory '/etc/td-agent/' do
  owner user_name
  group group_name
  mode '0755'
  action :create
end

case node['platform']
when "ubuntu"
  dist = node['lsb']['codename']
  source = (dist == 'precise') ? "http://packages.treasure-data.com/precise/" : "http://packages.treasure-data.com/debian/"
  apt_repository "treasure-data" do
    uri source
    distribution dist
    components ["contrib"]
    action :add
  end
when "centos", "redhat"
  yum_repository "treasure-data" do
    url "http://packages.treasure-data.com/redhat/$basearch"
    gpgkey "http://packages.treasure-data.com/redhat/RPM-GPG-KEY-td-agent"
    action :add
  end
end

template "/etc/td-agent/td-agent.conf" do
  mode "0644"
  source "td-agent.conf.erb"
end

if node['td_agent']['includes']
  directory "/etc/td-agent/conf.d" do
    mode "0755"
  end
end

package "td-agent" do
  options value_for_platform(
    ["ubuntu", "debian"] => {"default" => "-f --force-yes"},
    "default" => nil
    )
  action :upgrade
  version node[:td_agent][:version] if node[:td_agent][:pinning_version]
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
  subscribes :restart, resources(:template => "/etc/td-agent/td-agent.conf")
end
