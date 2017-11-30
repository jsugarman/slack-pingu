require 'sinatra/base'
require 'json'
require 'pry'
require 'net/http'
require 'nokogiri'
require 'inflecto'

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
      'pingu ping &lt;domain-name.co.uk[,other-domain.dsd.io]&gt;',
      'pingu healthcheck &lt;domain-name.co.uk[,other-domain.dsd.io]&gt;'
  ].map { |usage| "`#{usage}`" }.freeze

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

  def help_response
    { text: "Say one of the following: #{USAGES.join(', ')}" }.to_json
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
    ::Net::HTTP.get(uri)
  end

  def ping
    domains.each_with_object({}) do |domain, memo|
      memo[domain.to_sym] = request('https://' + domain + '/ping')
    end
  end

  def healthcheck
    domains.each_with_object({}) do |domain, memo|
      memo[domain.to_sym] = request('https://' + domain + '/healthcheck')
    end
  end

  def slack_response responses
    {
      attachments: responses.map { |k, v| SlackResponse.new(k, v).attachment }
    }.to_json
  end
end

class SlackResponse
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

  def success_template(pretext, response)
    {
      fallback: 'Success',
      color: 'good',
      pretext: ":penguin: #{pretext}",
      fields: present(response)
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

  def present json
    attributes = JSON.parse(json)
    attributes.each_with_object([]) do |(k, v), memo|
      memo << { title: k.humanize, value: v, short: true }
    end
  end
end

class String
  def humanize
    Inflecto.humanize(self)
  end
end
