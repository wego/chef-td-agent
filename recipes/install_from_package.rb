#
# Cookbook Name:: td-agent
# Recipe:: package
#
# Copyright 2011, Treasure Data, Inc.
#

package_source_base_url = 'http://packages.treasuredata.com'
package_gpgkey_url = "http://packages.treasuredata.com/GPG-KEY-td-agent"
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
    key package_gpgkey_url
    action :add
  end
when 'centos', 'redhat', 'amazon'
  yum_repository 'treasure-data' do
    url "#{package_source_base_url}/redhat/$basearch"
    gpgkey package_gpgkey_url
    action :add
  end
end

package "td-agent" do
  options value_for_platform(
    ["ubuntu", "debian"] => {"default" => "-f --force-yes"},
    "default" => nil
  )
  action :upgrade
end