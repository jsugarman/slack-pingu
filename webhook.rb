require 'sinatra/base'
require 'json'
require 'pry'
require 'net/http'
require 'nokogiri'

class Webhook < Sinatra::Base
  get '/' do
    <<~HEREDOC
      Slack webhook for notifying a channel of responses from ping.json endpoints
    HEREDOC
  end

  post '/webhook' do
    content_type 'application/json'
    begin
      raise SecurityError, 'Please check the value of `WEBHOOK_TOKEN` in env matches that in the webhook' unless (ENV.fetch('WEBHOOK_TOKEN') || !params[:token].nil? && params[:token].eql?(ENV.fetch('WEBHOOK_TOKEN')))
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
      'pingu ping &lt;domain-name.co.uk[,other-domain.dsd.io]&gt;'
  ].map { |usage| "`#{usage}`" }.freeze

  attr_reader :command

  def initialize command
    @command = strip_html(command)
  end

  def response
    puts "Interpreting #{command}"
    case
    when command.match?(/pingu\s+ping\s+<([\w\d\.-])+(,\s*[\w\d\.-]+)*>/i)
      ping_responses = ping
      slack_response(ping_responses)
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

  def self.usages
    { text: "Say one of the following: #{USAGES.join(', ')}" }.to_json
  end

  def help_response
    self.class.usages
  end

  def domains
    @domains ||= command.
      match(/(pingu\s+)(ping\s+)(<[^>]*>)(.*)/i).
      captures[2].
      tr('<>','').
      split(/[\s,]+/)
  end

  def request url
    uri = URI(url)
    ::Net::HTTP.get(uri)
  end

  def ping
    domains.each_with_object({}) do |domain, memo|
      memo[domain.to_sym] = request('https://' + domain + '/ping')
    end
  end

  def slack_response ping_responses
    {
      attachments: ping_responses.map { |k, v| SlackPingResponse.new(k, v).attachment }
    }.to_json
  end
end

class SlackPingResponse
  attr_reader :domain, :response

  def initialize domain, response
    @domain = domain
    @response = response
  end

  def attachment
    if response
      success("#{domain} all good!", response)
    else
      failure("#{domain} is not well!")
    end
  end

  private

  def success pretext, text
    success_template pretext, text
  end

  def failure text
    failure_template text
  end

  def success_template(pretext, text)
    {
      fallback: 'Success',
      color: 'good',
      pretext: ":penguin: #{pretext}",
      text: text,
      fields: fields_for(text)
    }
  end

  def failure_template(text)
    {
      fallback: 'Failure',
      color: 'danger',
      pretext: ':pengiun: Meep meep!',
      text: text
    }
  end

  def fields_for text
    attributes = JSON.parse(text)
    attributes.each_with_object([]) do |(k, v), memo|
      memo << { title: k, value: v, short: true }
    end
  end
end
