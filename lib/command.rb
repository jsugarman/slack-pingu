require 'nokogiri'
require 'httparty'
require 'timeout'
require_relative 'command_parser'

class Command
  class InvalidCommand < StandardError; end
  class TooManyDomains < StandardError; end
  class ResponseError < StandardError; end

  extend Forwardable
  def_delegators :@parser, :command, :hostnames

  def initialize(text)
    @parser = CommandParser.new(text)
  end

  def response
    puts "Interpreting #{command}" # unless ENV.fetch('RACK_ENV',nil) == 'test'

    case command
    when 'ping'
      slack_response(ping)
    when 'healthcheck'
      slack_response(healthcheck)
    when 'help', 'hi'
      help_response
    else
      raise InvalidCommand.new("do not understand the command \"#{command.sub(/pingu\s+/i,'')}\"")
    end

    # case
    # when command.match?(/pingu\s+ping\s+<([\w\d\.-])+(\s*,\s*[\w\d\.-]+)*>/i)
    #   slack_response(ping)
    # when command.match?(/pingu\s+healthcheck\s+<([\w\d\.-])+(\s*,\s*[\w\d\.-]+)*>/i)
    #   slack_response(healthcheck)
    # when command.match?(/pingu\s+(help|hi)/i)
    #   help_response
    # else
    #   raise CommandError.new("do not understand the command \"#{command.sub(/pingu\s+/i,'')}\"")
    # end
  end

  private

  def usages
    <<~EOT
      \n- `pingu ping &lt;domain-name.co.uk[,other-domain.dsd.io]&gt;`
      \n- `pingu healthcheck &lt;domain-name.co.uk[,other-domain.dsd.io]&gt;`
    EOT
  end

  def help_response
    { text: "Say one of the following:#{usages}" }.to_json
  end

  # def domains
    # @domains ||= command.
    #   match(/(pingu\s+)((?:ping|healthcheck)\s+)(<[^>]*>)(.*)/i).
    #   captures[2].
    #   tr('<>','').
    #   split(/[\s*,\s*]+/)
  # end

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
    raise TooManyDomains.new('too many domains!') if hostnames.size > 10
    hostnames.each_with_object({}) do |hostname, memo|
      memo[hostname.to_sym] = request('https://' + hostname + "/#{path}")
    end
  end

  def ping
    call 'ping'
  end

  def healthcheck
    call 'healthcheck'
  end

  def slack_response(responses)
    {
      attachments: responses.map { |k, v| SlackResponse.new(k, v).attachment }
    }.to_json
  end
end
