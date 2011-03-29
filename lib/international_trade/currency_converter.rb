require 'bigdecimal'
require 'big_decimal_extension'
require 'ostruct'
require 'xmlsimple'

module InternationalTrade
  class CurrencyConverter
    attr_reader :cached_conversion_rates, :cost, :exchange_data_file, :rates, :target_currency

    def initialize(exchange_data_file, target_currency)
      @target_currency = target_currency.upcase
      @exchange_data_file = exchange_data_file
      @rates = nil
      @cached_conversion_rates = {}

      parse_exchange_data_file
    end

    # returns the amount expressed in :target_currency
    def convert(amount)
      @cost, from_currency = amount.split
      @cost = BigDecimal(@cost, 15)

      return BigDecimal(@cost.to_s, 15) if from_currency == self.target_currency

      # shitty cache management
      conversion_rate = if cached_rate = self.cached_conversion_rates[from_currency.to_sym]
                          cached_rate
                        else
                          rate = composite_conversion_rate(from_currency)
                          cache_conversion_rate(from_currency, rate)
                          rate
                        end

      (conversion_rate * @cost).banker_round
    end

    #######
    private
    #######
    def cache_conversion_rate(from_currency, conversion_rate)
      @cached_conversion_rates[from_currency.to_sym] = conversion_rate
    end

    # here's where we do the heavy lifting;
    # also the single method of which I am most proud :)
    def composite_conversion_rate(from_currency)
      if exact_match = self.rates.detect{ |r| r.from == from_currency && r.to == self.target_currency }
        return exact_match.conversion
      end

      self.rates.find_all{ |r| r.from == from_currency }.each do |rate|
        self.rates.delete_if{ |r| r == rate || ( r.to == rate.from && r.from == rate.to ) } # no back-tracking

        if conversion = composite_conversion_rate(rate.to)
          return ( conversion * rate.conversion )
          break
        end
      end
    end

    def parse_exchange_data_file
      @rates = _parse_exchange_data_file
      post_process_conversion_rates
    end

    def post_process_conversion_rates
      @rates = @rates.collect do |rate|
        # Float-ify conversion rates for cleaner code (later)
        rate['conversion'] = BigDecimal(rate['conversion'], 15)

        # normalize currency casing
        %w(from to).each{ |x| rate[x] = rate[x].upcase}
        rate
      end

      # convert the conversions to OpenStructs, as they're nicer to work with
      @rates = rates.collect{ |rate| OpenStruct.new(rate)}
    end

    def _parse_exchange_data_file
      @_parse_exchange_data_file ||= XmlSimple.xml_in(self.exchange_data_file, 'ForceArray' => false)['rate']
    end
  end
end