#
# Cookbook Name:: td-agent
# Recipe:: default
#
# Copyright 2011, Treasure Data, Inc.
#

group_name = node[:td_agent][:group]
user_name = node[:td_agent][:user]
install_dir = node[:td_agent][:install_dir]
log_file = node[:td_agent][:log_file]
pid_file = node[:td_agent][:pid_file]

group group_name do
  action :create
end

user user_name do
  comment  'td-agent'
  gid      group_name
  action   :create
end

directory install_dir do
  owner user_name
  group group_name
  mode '0755'
  action :create
end

# all config file will be in conf.d folder
# and to be clear we always use include in the main config
directory "#{install_dir}/conf" do
  mode "0755"
end

if node[:td_agent][:install_package]
  include_recipe 'td-agent::install_from_package'
end

template "#{install_dir}/td-agent.conf" do
  mode "0644"
  source "td-agent.conf.erb"
end

node[:td_agent][:plugins].each do |plugin|
  if plugin == 'elasticsearch'
    package 'curl'
    package 'libcurl4-gnutls-dev'
  end
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

template '/etc/init.d/td-agent' do
  mode "0755"
  source 'td-agent.init_d.erb'
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
  attributes = attributes.dup
  if attributes.delete(:encrypted_data_bag_aws_key)
    aws_key = EncryptedDataBagItem.load("aws", "s3-fluentd")
    if attributes[:type] == 's3'
      attributes = attributes.merge(aws_key_id: aws_key['access_key_id'], aws_sec_key: aws_key['secret_access_key'])
    elsif attributes[:store_s3] && attributes[:store_s3][:type] == 's3'
      attributes[:store_s3] = attributes[:store_s3].merge(aws_key_id: aws_key['access_key_id'], aws_sec_key: aws_key['secret_access_key'])
    end
  end
  template key do
    path      "#{install_dir}/conf/match_#{key}.conf"
    source    "plugin_match.conf.erb"
    variables({:attributes => attributes})
    notifies :restart, "service[td-agent]", :immediately
  end
end

# Rotate by size also as log can grow quickly on error
logrotate_app 'td-agent' do
  path           log_file
  rotate         3
  frequency      'daily'
  options        ['compress', 'dateext', 'delaycompress', 'missingok']
  create         "0644 #{user_name} #{group_name}"
  sharedscripts  true
  size           '1024M'
  lastaction     %Q(
    pid=#{pid_file}
    test -s $pid && kill -USR1 "$(cat $pid)"
  )
end
