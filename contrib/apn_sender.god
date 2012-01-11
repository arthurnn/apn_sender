# An example God configuration file for running the apn_sender background daemon
#
#   1. Replace #{app_name} with your application name
#   2. Add any arguments between apn_sender the and start/stop command
#   3. To run 'god -c #{path_to_god_conf}'

rails_env = "production"
rails_root = "/var/www/#{app_name}/current"

# Resque
God.watch do |w|
  w.dir      = "#{rails_root}"
  w.name     = "apn_sender-#{rails_env}"
  w.group    = "resque-#{rails_env}"
  w.interval = 60.seconds
  w.env      = {"VERBOSE" => "1", "ENVIRONMENT" => rails_env}
  w.start    = "bundle exec rake apn:sender"
  w.log      = "#{rails_root}/log/apn_sender.log"

  # restart if memory gets too high
  w.transition(:up, :restart) do |on|
    on.condition(:memory_usage) do |c|
      c.above = 350.megabytes
      c.times = 2
    end
  end

  # determine the state on startup
  w.transition(:init, {true => :up, false => :start}) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 5.seconds
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.interval = 5.seconds
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.running = false
    end
  end
end

# Redis
%w{6379}.each do |port|
  God.watch do |w|
    w.name = "redis"
    w.log = "#{rails_root}/log/redis.log"
    w.interval = 60.seconds
    w.start = "redis-server"
    w.stop = "echo 'SHUTDOWN' | nc localhost 6379"
    w.restart = "echo 'SHUTDOWN' | nc localhost 6379 && redis-server"
    w.start_grace = 10.seconds
    w.restart_grace = 10.seconds

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end
  end
end