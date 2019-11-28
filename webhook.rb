require 'sinatra/base'
require 'json'
require 'pry'
require 'awesome_print'

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
      authenticate
      ap '--------------'
      ap params
      ap '--------------'
      command = Command.new(params[:text])
      body command.response
    rescue SecurityError => err
      body error_response(err)
    rescue CommandError => err
      body error_response(err)
    end
  end

  private

  def token
    @token ||= ENV.fetch('SLACK_API_TOKEN', nil)
  end

  def authenticate
    return if token && params[:token].eql?(token)
    raise SecurityError, 'Please check the value of `SLACK_API_TOKEN` in env matches that in slack outgoing webhook integration'
  end

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
