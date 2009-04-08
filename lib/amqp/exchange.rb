module AMQP
  class Exchange

    def initialize(server, type, name, opts = {})
      @server, @type, @name, @opts = server, type, name, opts
      @key = opts[:key]

      unless name == "amq.#{type}" or name == ''
        @server.send_frame(
          Protocol::Exchange::Declare.new(
            { :exchange => name, :type => type, :nowait => true }.merge(opts)
          )
        )
      end
    end
    attr_reader :name, :type, :key

    def publish(data, opts = {})
      out = []

      out << Protocol::Basic::Publish.new(
        { :exchange => name, :routing_key => opts.delete(:key) || @key }.merge(opts)
      )
      data = data.to_s
      out << Protocol::Header.new(
        Protocol::Basic,
        data.length, {
          :content_type  => 'application/octet-stream',
          :delivery_mode => (opts.delete(:persistent) ? 2 : 1),
          :priority      => 0 
        }.merge(opts)
      )
      out << Frame::Body.new(data)

      @server.send_frame(*out)
    end

    def delete(opts = {})
      @server.send_frame(Protocol::Exchange::Delete.new({ :exchange => name, :nowait => true }.merge(opts)))
    end

    def reset
      @deferred_status = nil
      initialize(@server, @type, @name, @opts)
    end
  end
end