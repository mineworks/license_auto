

rack_env = ENV['RACK_ENV']

require 'boot'

Bundler.require(:default, rack_env)

## RabbitMQ connection
# TODO: singleton
# require "singleton"
rabbit_mq_spec = YAML.load_file('./config/rabbit_mq.yml')[rack_env]
rabbit_mq_conn = "amqp://#{rabbit_mq_spec['username']}:#{rabbit_mq_spec['password']}@#{rabbit_mq_spec['host']}:#{rabbit_mq_spec['port']}"
begin
  $rmq = Bunny.new(rabbit_mq_conn)
  $rmq.start

  $ch = $rmq.create_channel
  $x = $ch.default_exchange

  $repo_queue = $ch.queue('license.repo', :auto_release => false, :durable => true)

  $pack_queue = $ch.queue('license.pack', :auto_release => false, :durable => true)

rescue Exception => e
  raise(e)
end


Dir[File.expand_path('../../api/*.rb', __FILE__)].each do |f|
  require f
end

license_client_spec = YAML.load_file('./config/license_client.yml')[rack_env]
LicenseClient.connect(license_client_spec)