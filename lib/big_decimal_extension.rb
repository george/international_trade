require 'bigdecimal'

# shamelessly (almost) pilfered from: http://www.furmanek.net/37/gaussian-rounding-in-ruby/
# after multiple failed attempts at my own implementation

module BigDecimalExtension
  def banker_round(decimals = 2)
    return BigDecimal( (_round(self * (10**decimals))/((10**decimals).to_f)).to_s )
  end

  #######
  private
  #######

  def _round(val)
    sign = val < 0 ? -1 : 1
    return (val.abs.round * sign) if (val.abs - val.abs.floor) != 0.5
    return (val.abs.ceil  * sign) if val.abs.floor % 2 == 1
    return (val.abs.floor * sign)
  end
end

class BigDecimal
  include BigDecimalExtension
end