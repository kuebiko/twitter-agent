require 'celluloid/io'
require 'celluloid/autostart'

class TwitterStreamClient
  include Celluloid::IO

  def initialize
    @callbacks = {
      on_tweet: [],
      on_delete: []
    }
  end

  # Initializes Stream and REST twitter clients with authentication information
  #
  # @params credentials [Hash] API authentication information
  # @params credentials [String] :consumer_key
  # @params credentials [String] :consumer_secret
  # @params credentials [String] :access_token
  # @params credentials [String] :access_token_secret
  def initialize_twitter_client(credentials)
    connection_opts = {
      tcp_socket_class: Celluloid::IO::TCPSocket,
      ssl_socket_class: Celluloid::IO::SSLSocket
    }

    # @rest_client = Twitter::REST::Client.new
    @stream_client = Twitter::Streaming::Client.new(connection_opts)

    @stream_client.consumer_key = credentials[:consumer_key]
    @stream_client.consumer_secret = credentials[:consumer_secret]
    @stream_client.access_token = credentials[:oauth_token]
    @stream_client.access_token_secret = credentials[:oauth_token_secret]

    ## Start user stream
    async.loop_user_stream
  end

  def add_callback(event, callback)
    @callbacks[event] << callback
  end

  def loop_user_stream
    # @stream_client.user(replies: 'all') do |object|
    @stream_client.user do |object|
      p "#{Time.now}: Got #{object.class.name}"
      case object
      when Twitter::Tweet
        @callbacks[:on_tweet].each { |c| c.call(object) }
      else
        # puts object.to_h if object.respond_to?(:to_h)
        puts object.inspect
      end
    end
  rescue StandardError => e
    puts e.message
  end
end
