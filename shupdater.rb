# Shorewall updater
require 'rubygems'
require 'net/ssh'
require 'net/scp'
SHWL_PATH = "/etc/shorewall"
# We need a server name
@server = ARGV[0]
puts "Connecting to #{@server}..."
Net::SSH.start(@server, 'root') do |ssh|
  # find shorewall version
  @shorewall_version = ssh.exec!("shorewall version")
end
puts "#{@server} is running shorewall version #{@shorewall_version}"
case @shorewall_version
when /1\.4\..*/
  # Upload new zone, interface & policy files
  Net::SCP.start(@server, 'root') do |scp|
    puts "Uploading v1 files"
    scp.upload('./zones.v1', SHWL_PATH + '/zones')
    scp.upload('./interfaces.v1', SHWL_PATH + '/interfaces')
    scp.upload('./policy.v1', SHWL_PATH + '/policy')
  end
  # Add ping rule to rules file
  Net::SSH.start(@server, 'root') do |ssh|
    puts "Changing ping rule to allow local pinging"
    ssh.exec!('sed -i s/"ACCEPT\t\tnet\tfw\ticmp\t8"/"ACCEPT\t\tall\tall\ticmp\t8"/g ' + SHWL_PATH + '/rules')
    puts "Restarting shorewall..."
    puts ssh.exec("shorewall restart")
  end
when /4\.2\..*/
  # Upload new zone, interface & policy files
  Net::SCP.start(@server, 'root') do |scp|
    puts "Uploading v4 files"
    scp.upload('./zones.v4', SHWL_PATH + '/zones')
    scp.upload('./interfaces.v4', SHWL_PATH + '/interfaces')
    scp.upload('./policy.v4', SHWL_PATH + '/policy')
  end
  # Add ping rule to rules file
  Net::SSH.start(@server, 'root') do |ssh|
    puts "Changing ping rule to allow local pinging"
    ssh.exec!('sed -i s/"Ping/ACCEPT\t\tnet\t\t\t$FW"/"Ping/ACCEPT\t\tall\t\t\tall"/g ' + SHWL_PATH + '/rules')
    puts "Restarting shorewall..."
    puts ssh.exec("shorewall restart")
  end
end
