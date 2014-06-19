require 'twitter'

require 'celluloid/io'
require 'celluloid/autostart'

class TwitterAgent < Kuebiko::Agent
  include Celluloid::IO

  attr_accessor :rest_client, :stream_client

  def initialize
    super

    @stream_client = TwitterStreamClient.new

    # Send credentials request and register callback
    request_credentials
  end

  def request_credentials
    msg = Kuebiko::Message.new send_to: ['resources/configurations']
    msg.payload = Kuebiko::MessagePayload::Query.new(query: :twitter)

    dispatcher.send(msg, method(:handle_credentials_reply))
  end

  def handle_credentials_reply(msg)
    @stream_client.initialize_twitter_client(JSON.parse(msg.payload.body, symbolize_names: true))
  rescue JSON::ParserError
    # TODO: Proper log this you idiot
    puts 'Invalid message payload'
  end
end
