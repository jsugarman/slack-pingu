class CommandParser
  class Error < StandardError; end

  attr_reader :text

  def initialize(text)
    @text = text
  end

  def command
    captures[1].strip
  rescue NoMethodError => e
    raise Error, "unknown command \"#{text}\""
  end

  def hostnames
    captures[2].split(',').each_with_object([]) do |markdown, arr|
      arr.append(md_to_hostname(markdown))
    end
  end

  private

  def captures
    @captures = text.
                  match(/(pingu\s+)(ping\s*|healthcheck\s*|help\s*)(.*)/i).
                  captures
  end

  def md_to_hostname(markdown_url)
    url = markdown_url.
            sub(/\|.*/,'')&.
            tr('<>','')&.
            strip
    URI.parse(url).hostname || url
  end
end