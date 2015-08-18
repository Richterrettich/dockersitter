#!/usr/bin/env ruby

require 'yaml'


if File.exist? "config.yml"
  config = YAML.load_file("config.yml")
  puts config.inspect
else
  config = Hash.new
  puts "pleas enter your email"
  config[:email] = STDIN.gets.chomp
  puts "please enter your name"
  config[:name] = STDIN.gets.chomp
  puts "pleas enter your host-name (leave blank if you don't have one)"
  config[:host] = STDIN.gets.chomp
  File.write "config.yml",config.to_yaml
end

