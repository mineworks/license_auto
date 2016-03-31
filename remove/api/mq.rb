require 'bunny'

module API

class RabbitMQ
  # "amqp://guest:guest@localhost:5672"
  def initialize(rabbit_mq_conn_str)
    @conn = Bunny.new(rabbit_mq_conn_str)
    @conn.start
    @ch = @conn.create_channel
  end

  def publish(queue_name, message, auto_release=true, durable=true, check_exist=false)
    # TODO: @Micfan, 检查队列中是否存在该消息,如果已存在或正在处理,则返回false
    def queue_exist(message)
      false
    end

    q = @ch.queue(queue_name, :auto_release => auto_release, :durable => durable)
    x = @ch.default_exchange

    if check_exist and not queue_exist(message)
      x.publish(message, :routing_key => q.name)
    else
      x.publish(message, :routing_key => q.name)
    end
  end
end

end
