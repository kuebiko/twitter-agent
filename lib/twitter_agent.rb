require 'twitter'

require 'celluloid/io'
require 'celluloid/autostart'

class TwitterAgent < Kuebiko::Agent
  include Celluloid::IO

  attr_accessor :rest_client, :stream_client

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

    @rest_client = Twitter::REST::Client.new
    @stream_client = Twitter::Streaming::Client.new(connection_opts)

    [@stream_client, @rest_client].each do |client|
      client.consumer_key = credentials['consumer_key']
      client.consumer_secret = credentials['consumer_secret']
      client.access_token = credentials['oauth_token']
      client.access_token_secret = credentials['oauth_token_secret']
    end

    ## Start user stream
    async.loop_user_stream
  end

  def loop_user_stream
    stream_client.user do |object|
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
