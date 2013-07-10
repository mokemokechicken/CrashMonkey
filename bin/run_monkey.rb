#!/usr/bin/env ruby

require 'optparse'

$: << File.dirname(__FILE__) + '/../lib'
require 'crash_monkey'

opts = {}
ARGV.options do |o|
  Version = '0.1'
  o.on('-a app_name', 'Target Application') {|b| opts[:app_path] = b}
  o.on('-n run_count', 'How many times monkeys run(default: 2)') {|b| opts[:run_count] = b.to_i}
  o.on('-d result_dir', 'Where to output result(default: /var/tmp/auto_monkey)') {|b| opts[:result_base_dir] = b}
  o.on('-t time_limit_sec', 'Time limit of running(default: 100 sec)') {|b| opts[:time_limit_sec] = b.to_i}
  o.on('-c config_path', 'Configuration JSON Path') {|b| opts[:config_path] = b}
  o.on('--show-config', 'Show Current Configuration JSON') {|_| opts[:show_config] = true}
  o.parse!
end

opts[:run_count] ||= 2
opts[:result_base_dir] ||= '/var/tmp/auto_monkey'
opts[:time_limit_sec] ||= 100

result_ok = UIAutoMonkey::MonkeyRunner.new.run(opts)

puts result_ok ? 'EXIT 0' : 'EXIT 1' unless opts[:show_config]

exit(result_ok ? 0 : 1)
