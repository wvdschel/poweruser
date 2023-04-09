#!/usr/bin/env ruby

$stdout.reopen("/var/log/poweruser.log", "w")
$stderr.reopen("/var/log/poweruser_errors.log", "w")

def run_directory(dir)
  puts "Running #{dir}"
  Dir["/etc/poweruser/scripts/#{dir}.d/*"].each do |file|
    begin
      # Ruby 1.9 output redirection
      #spawn(file, :err=>:out, :out=>"/var/log/poweruser.log")
      if not system(file)
        puts "#{file} failed"
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
