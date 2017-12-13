require 'sinatra/base'
require 'json'
require 'pry'

Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |f| require f }

class Webhook < Sinatra::Base
  get '/' do
    <<~HEREDOC
      Slack webhook for notifying a channel of JSON responses from ping and healthcheck endpoints
    HEREDOC
  end

  post '/webhook' do
    content_type 'application/json'
    begin
      raise SecurityError, 'Please check the value of `SLACK_API_TOKEN` in env matches that in slack outgoing webhook integration' unless (ENV.fetch('SLACK_API_TOKEN') || !params[:token].nil? && params[:token].eql?(ENV.fetch('WEBHOOK_TOKEN')))
      command = Command.new(params[:text])
      body command.response
    rescue SecurityError => err
      body error_response(err)
    rescue CommandError => err
      body error_response(err)
    end
  end

  private

  def error_response err
    {
      attachments: [
        {
          fallback: 'Error',
          pretext: ':penguin: Meep meep!',
          color: 'danger',
          text: err
        }
      ]
    }.to_json
  end
end
