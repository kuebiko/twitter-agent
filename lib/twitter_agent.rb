require 'twitter'

class TwitterAgent < Kuebiko::Agent
  TWEET_RESOURCE_TOPIC = 'resources/twitter/tweet'
  RELATIONSHIP_RESOURCE_TOPIC = 'resources/relationship'
  PERSONA_RESOURCE_TOPIC = 'entities/persona'

  SOURCE = 'Twitter API'
  TWEET_RESOURCE_TYPE = 'twitter.tweet'

  attr_accessor :rest_client, :stream_client

  def initialize
    super

    @stream_client = TwitterStreamClient.new
    # TwitterStreamClient.supervise_as :twitter
    # @stream_client = Celluloid::Actor[:twitter]
    @stream_client.add_callback(:on_tweet, method(:handle_new_tweet))

    # Send credentials request and register callback

    puts "Subscribed to : #{agent_control_topics.join(', ')}"

    puts 'Requesting credentials now'
    request_credentials
  end

  def handle_new_tweet(tweet)
    msg = Kuebiko::Message.new send_to: [TWEET_RESOURCE_TOPIC]

    ## Other resources
    handle_profile(tweet.user, tweet)

    msg.payload = Kuebiko::MessagePayload::Document.new.tap do |pl|
      pl.agent_type = self.class.name

      pl.created_at = tweet.created_at
      pl.mime_type = 'application/json'
      pl.language_code = tweet.lang

      pl.type = TWEET_RESOURCE_TYPE
      pl.source = SOURCE
      pl.source_id = tweet.id

      pl.geolocation = tweet.geo.to_h

      pl.content = tweet.to_h
    end

    dispatcher.send(msg)
  end

  def handle_profile(profile, tweet = nil)
    msg = Kuebiko::Message.new send_to: [PERSONA_RESOURCE_TOPIC]

    content = profile.to_h
    content.delete(:status)

    msg.payload = Kuebiko::MessagePayload::Persona.new.tap do |pl|
      pl.agent_type = self.class.name

      pl.created_at = profile.created_at
      pl.language_code = profile.lang

      pl.source = SOURCE
      pl.source_id = profile.id

      pl.description = profile.description

      pl.content = content
    end

    dispatcher.send(msg)

    if tweet
      announce_relationship(
        :author,
        { type: TWEET_RESOURCE_TYPE, source: SOURCE, source_id: tweet.id },
        { type: 'entities.persona',  source: SOURCE, source_id: profile.id }
      )
    end
  end

  def handle_mention(tweet, mention)
    announce_relationship(
        :mention,
        { type: TWEET_RESOURCE_TYPE, source: SOURCE, source_id: tweet.id },
        { type: 'entities.persona' , source: SOURCE, source_id: mention.id }
      )
  end

  def announce_relationship(type, left, right)
    msg = Kuebiko::Message.new send_to: [RELATIONSHIP_RESOURCE_TOPIC]

    msg.payload = Kuebiko::MessagePayload::ResourceRelationship.new(
      start_resource: left,
      end_resource: right,
      type: type
    )

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
