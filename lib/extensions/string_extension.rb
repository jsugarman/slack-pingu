require 'inflecto'

class String
  def humanize
    Inflecto.humanize(self)
  end
end
