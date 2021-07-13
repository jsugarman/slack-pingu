# frozen_string_literal: true

# parsing slack text, including markdown,
# to constituent parts for processing.
#
class CommandParser
  class UnknownCommand < StandardError; end

  attr_reader :text

  def initialize(text)
    @text = text
  end

  def command
    captures[1].strip
  rescue NoMethodError
    raise UnknownCommand, "unknown command \"#{text}\""
  end

  def hostnames
    captures[2].split(',').each_with_object([]) do |markdown, arr|
      arr.append(md_to_hostname(markdown))
    end
  end

  private

  def captures
    @captures = text
                .match(/(pingu\s+)(ping\s*|healthcheck\s*|help\s*|hi\s*)(.*)/i)
                .captures
  end

  def md_to_hostname(markdown_url)
    url = markdown_url
          &.sub(/\|.*/, '')
          &.gsub(/&lt;|&gt;/, '')
          &.tr('<>', '')
          &.strip
          &.encode(Encoding.find('ASCII'), **encoding_options)

    URI.parse(url).hostname || url
  end

  # Replace invalid byte sequences
  # Replace anything not defined in ASCII
  # Use a blank for those replacements
  # Always break lines with \n
  def encoding_options
    { invalid: :replace,
      undef: :replace,
      replace: '',
      universal_newline: true }
  end
end
