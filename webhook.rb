require 'sinatra/base'
require 'json'
require 'pry'
require 'httparty'
require 'nokogiri'
require 'inflecto'
require 'timeout'

Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"].each { |f| require f }

class Webhook < Sinatra::Base
  get '/' do
    <<~HEREDOC
      Slack webhook for notifying a channel of responses from ping.json endpoints
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

class CommandError < StandardError; end
class ResponseError < StandardError; end

class Command
  attr_reader :command

  def initialize command
    @command = strip_html(command)
  end

  def response
    puts "Interpreting #{command}" unless ENV.fetch('RACK_ENV',nil) == 'test'
    case
    when command.match?(/pingu\s+ping\s+<([\w\d\.-])+(\s*,\s*[\w\d\.-]+)*>/i)
      slack_response(ping)
    when command.match?(/pingu\s+healthcheck\s+<([\w\d\.-])+(\s*,\s*[\w\d\.-]+)*>/i)
      slack_response(healthcheck)
    when command.match?(/pingu\s+help/i)
      help_response
    else
      raise CommandError, "do not understand the command \"#{command.sub(/pingu\s+/i,'')}\""
    end
  end

  private

  def strip_html(html)
    Nokogiri::HTML(html).content
  end

  def usages
    <<~EOT
      \n- `pingu ping &lt;domain-name.co.uk[,other-domain.dsd.io]&gt;`
      \n- `pingu healthcheck &lt;domain-name.co.uk[,other-domain.dsd.io]&gt;`
    EOT
  end

  def help_response
    { text: "Say one of the following:#{usages}" }.to_json
  end

  def domains
    @domains ||= command.
      match(/(pingu\s+)((?:ping|healthcheck)\s+)(<[^>]*>)(.*)/i).
      captures[2].
      tr('<>','').
      split(/[\s*,\s*]+/)
  end

  def request url
    uri = URI(url)
    response = HTTParty.get(uri, timeout: 5)
    raise ResponseError if (400..550).include?(response.code.to_i)
    response
  rescue Timeout::Error
    { error: "#{uri} timeout error: #{err}" }.to_json
  rescue SocketError => err
    { error: "#{uri} socket error: #{err}" }.to_json
  rescue ResponseError => err
     { error: "#{uri} unreachable: #{response.code}" }.to_json
  rescue StandardError => err
    { error: "#{uri} error: #{err}" }.to_json
  end

  def call path
    domains.each_with_object({}) do |domain, memo|
      memo[domain.to_sym] = request('https://' + domain + "/#{path}")
    end
  end

  def ping
    call 'ping'
  end

  def healthcheck
    call 'healthcheck'
  end

  def slack_response responses
    {
      attachments: responses.map { |k, v| SlackResponse.new(k, v).attachment }
    }.to_json
  end
end
