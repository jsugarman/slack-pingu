require 'sinatra/base'
require 'json'

class Webhook < Sinatra::Base
  get '/' do
    <<~HEREDOC
      Slack webhook for notifying a channel of responses from ping.json endpoints
    HEREDOC
  end

  post '/webhook' do
    content_type 'application/json'
    body webhook_response
  end

  private

  def webhook_response
    {
      message: ':robot: ping-bot message test'
    }.to_json
  end
end
