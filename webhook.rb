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
      # TODO: implement slack token
      # raise SecurityError, 'Please check the value of `WEBHOOK_TOKEN` in the environment' unless (ENV['WEBHOOK_TOKEN'] || !params[:token].nil? && params[:token].eql?(ENV['WEBHOOK_TOKEN']))

      command = Command.new(params[:command])
      body command.response
    rescue SecurityError => err
      body error_reponse(err)
    rescue CommandError => err
      body error_reponse(err) + error_reponse(Command.usages)
    end
  end

  private

  def error_reponse err = nil
    {
      message: err
    }.to_json
  end
end

class CommandError < StandardError; end

class Command
  USAGES = [
      '@pingbot ping &lt;domain-name.co.uk&gt;',
      '@pingbot ping &lt;domain-name.co.uk&gt;[,&lt;other-domain.dsd.io&gt;]'
  ].map { |usage| "`#{usage}`" }.freeze

  attr_reader :command

  def initialize command
    @command = command
  end

  def response
    case
    when command.match?(/@ping-?bot\s+ping\s+([\w\d\.-])+(,\s?[\w\d\.-]+)*/i)
      ping
    when command.match?(/@ping-?bot\s+help/i)
      help
    else
      raise CommandError, "#{command} is invalid" unless command.match? /@ping-?bot\s+ping\s+([\w\d\.-])+(,\s?[\w\d\.-]+)*/i
    end
  end

  private

  def self.usages
    { message: "Say one of the following: #{USAGES.join(', ')}" }.to_json
  end

  def help
    self.class.usages
  end

  def ping
    {
      message: ':robot: ping-bot pinging... test'
    }.to_json
  end
end
