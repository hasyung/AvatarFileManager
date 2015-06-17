APP_ROOT = '/var/www/file_manager/current/'

ENV["BUNDLE_GEMFILE"] = File.join(APP_ROOT, "Gemfile")

on_worker_boot do
  Redis.current.client.reconnect
  $redis = Redis.current
end

on_restart do
  Redis.current.client.reconnect
  $redis = Redis.current
end

environment "production"
threads 2, 8
workers 2

#bind "tcp://127.0.0.1:4000"
bind "unix:///tmp/file_manager.sock"

pidfile "#{APP_ROOT}/tmp/pids/puma.pid"
state_path "#{APP_ROOT}/tmp/pids/puma.state"
daemonize true
preload_app!
activate_control_app
