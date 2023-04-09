#!/usr/bin/env ruby
require 'timeout'

$stdout.reopen("/var/log/poweruser.log", "w")
$stderr.reopen("/var/log/poweruser_errors.log", "w")

def run_directory(dir)
  puts "Running #{dir}"
  Dir["/etc/poweruser/scripts/#{dir}.d/*"].each do |file|
  begin
    pid = spawn(file, :err=>:out, :out=>$stdout)
      begin
        Timeout.timeout(20) do
          exit_code = Process.wait pid
          if exit_code != 0
            puts "failed to run #{file}: exit code #{exit_code}"
          end
        end
      rescue Timeout::Error
        puts "script stuck: #{file} has been running for 20s, killing"
        Process.kill 9, pid
        # collect status so it doesn't stick around as zombie process
        Process.wait pid
      end
    end
  end
end

def plugged_in?
  File.read('/sys/class/power_supply/AC0/online') == "1\n"
end

run_directory("startup")

trap("INT") do
  run_directory('shutdown')
  exit
end

old_state = nil
while true
  new_state = plugged_in?
  if new_state != old_state
    if new_state
      run_directory('plugged')
    else
      run_directory('unplugged')
    end
    old_state = new_state
  end
  sleep 1.5
end
