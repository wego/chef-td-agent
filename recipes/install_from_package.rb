#
# Cookbook Name:: td-agent
# Recipe:: package
#
# Copyright 2011, Treasure Data, Inc.
#

package_source_base_url = 'http://packages.treasure-data.com'

case node[:platform]
when 'ubuntu'
  dist = node[:lsb][:codename]
  package_source = if dist == 'precise'
    "#{package_source_base_url}/precise/"
  else
    "#{package_source_base_url}/debian/"
  end

  apt_repository 'treasure-data' do
    uri package_source
    distribution dist
    components ['contrib']
    key "http://packages.treasure-data.com/debian/RPM-GPG-KEY-td-agent"
    action :add
  end
when 'centos', 'redhat', 'amazon'
  yum_repository 'treasure-data' do
    url "#{package_source_base_url}/redhat/$basearch"
    gpgkey "#{package_source_base_url}/redhat/RPM-GPG-KEY-td-agent"
    action :add
  end
end

package "td-agent" do
  options value_for_platform(
    ["ubuntu", "debian"] => {"default" => "-f --force-yes"},
    "default" => nil
  )
  action :install
  version node[:td_agent][:version] if node[:td_agent][:version]
end