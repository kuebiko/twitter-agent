require 'twitter'

class TwitterAgent < Kuebiko::Agent
  RESOURCE_TOPIC = 'resources/twitter/tweet'

  attr_accessor :rest_client, :stream_client

  def initialize
    super

    @stream_client = TwitterStreamClient.new
    @stream_client.add_callback(:on_tweet, method(:handle_new_tweet))

    # Send credentials request and register callback
    request_credentials
  end

  def handle_new_tweet(tweet)
    msg = Kuebiko::Message.new send_to: [RESOURCE_TOPIC]

    msg.payload = Kuebiko::MessagePayload::Document.new.tap do |pl|
      pl.agent_type = self.class.name

      pl.created_at = tweet.created_at
      pl.mime_type = 'application/json'
      pl.language_code = tweet.lang

      pl.source = 'Twitter API'
      pl.source_id = tweet.id

      pl.geolocation = tweet.geo.to_h

      pl.content = tweet.to_h
    end

    dispatcher.send(msg)
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
