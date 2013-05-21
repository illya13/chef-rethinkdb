#
# Author:: Vitaly Aminev (v@aminev.me)
# Cookbook Name:: rethinkdb
# Recipe:: start
#
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# service start
service 'rethinkdb' do
  action :start
  supports :status => true, :restart => true
  provider Chef::Provider::Service::Init
end

node.rethinkdb.instances.each do |instance|
  
  user "#{instance.user}" do
    system false   
    shell '/bin/false' 
    :create
  end
  
  unless system('egrep -i "^rethinkdb" /etc/group')    
    group "#{instance.group}" do
      action :create
    end
  end
  
  group "#{instance.group}" do
    action :modify    
    members instance.user
    append true
  end
  
  directory "/opt/rethinkdb/#{instance.name}" do
    owner instance.user
    group instance.group
    recursive true
    mode 00775
  end
  
  config_name = "/etc/rethinkdb/instances.d/#{instance.name}.conf"
  
  template config_name do
    user instance.user
    group instance.group
    source 'rethinkdb.conf.erb'
    variables({
      :instance => instance,
      :cores    => node.rethinkdb.make_threads 
    })
    mode 00440
    notifies :restart, "service[rethinkdb]", :delayed
  end

end