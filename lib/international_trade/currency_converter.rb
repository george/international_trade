require 'bigdecimal'
require 'big_decimal_extension'
require 'xmlsimple'

module InternationalTrade
  class CurrencyConverter
    attr_reader :target_currency, :rates

    def initialize(exchange_data_file, target_currency)
      @target_currency = target_currency.upcase
      parse(exchange_data_file)
    end

    # returns the amount expressed in :target_currency
    def convert(amount)
      cost, from_currency = amount.split
      conversion_rate = compute_conversion_rate(from_currency)
      # "#{(BigDecimal(cost, 5) * conversion_rate).to_s('F')} #{target_currency}"
      BigDecimal(cost, 5) * conversion_rate
    end

    #######
    private
    #######
    # Note: woefully childish implementation
    def compute_conversion_rate(from_currency)
      from_converter = @rates.detect do |conversion_hash|
        conversion_hash['from'].upcase == from_currency.upcase
      end

      return BigDecimal(from_converter['conversion'], 5) if from_converter['to'].upcase == target_currency.upcase

      intermediate_converter = @rates.detect do |conversion_hash|
        conversion_hash['from'].upcase == from_converter['to'].upcase &&
        conversion_hash['to'].upcase   == target_currency
      end

      BigDecimal(from_converter['conversion'], 5) * BigDecimal(intermediate_converter['conversion'], 5)
    end

    def parse(data_file)
      @rates = XmlSimple.xml_in(data_file, 'ForceArray' => false)['rate']
    end
  end
end