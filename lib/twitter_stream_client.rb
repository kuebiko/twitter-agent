class TwitterStreamClient
  include Celluloid::IO

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

    puts credentials.inspect

    @stream_client.consumer_key = credentials[:consumer_key]
    @stream_client.consumer_secret = credentials[:consumer_secret]
    @stream_client.access_token = credentials[:oauth_token]
    @stream_client.access_token_secret = credentials[:oauth_token_secret]

    # [@stream_client, @rest_client].each do |client|
      # client.consumer_key = credentials['consumer_key']
      # client.consumer_secret = credentials['consumer_secret']
      # client.access_token = credentials['oauth_token']
      # client.access_token_secret = credentials['oauth_token_secret']
    # end

    puts 'Fire this baby up'
    ## Start user stream
    async.loop_user_stream
  end

  def loop_user_stream
    @stream_client.user do |object|
      case object
      when Twitter::Tweet
        puts "Publishing #{object.text} to MQ"
        # publisher.publish('resources/found', object.attrs.to_json)
      when Twitter::Streaming::StallWarning
        warn "Falling behind!"
      end
    end
  end
end
