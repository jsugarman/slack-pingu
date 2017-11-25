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
    begin
      raise SecurityError, 'Please check the value of `WEBHOOK_TOKEN` in env matches that in the webhook' unless (ENV['WEBHOOK_TOKEN'] || !params[:token].nil? && params[:token].eql?(ENV['WEBHOOK_TOKEN']))
      command = Command.new(params[:text])
      body command.response
    rescue SecurityError => err
      body error_response(err)
    rescue CommandError => err
      body error_response(err) #+ error_response(Command.usages)
    end
  end

  private

  def error_response err
    {
      attachments: [
        {
          fallback: 'Error',
          pretext: 'Meep meep!',
          color: 'danger',
          text: err
        }
      ]
    }.to_json
  end
end

class CommandError < StandardError; end

class Command
  USAGES = [
      'pingu ping &lt;domain-name.co.uk&gt;',
      'pingu ping &lt;domain-name.co.uk&gt;[,&lt;other-domain.dsd.io&gt;]'
  ].map { |usage| "`#{usage}`" }.freeze

  attr_reader :command

  def initialize command
    @command = command
  end

  def response
    case
    when command.match?(/pingu\s+ping\s+([\w\d\.-])+(,\s?[\w\d\.-]+)*/i)
      ping
    when command.match?(/pingu\s+help/i)
      help
    else
      raise CommandError, "do not understand the command \"#{command.sub(/pingu/i,'')}\""
    end
  end

  private

  def self.usages
    { text: "Say one of the following: #{USAGES.join(', ')}" }.to_json
  end

  def help
    self.class.usages
  end

  def ping
    {
      attachments: [
        {
          fallback: 'Success',
          color: 'good',
          pretext: ':penguin: pingu pinging... test',
          text: ':penguin: ping'
        }
      ]
    }.to_json
  end
end
