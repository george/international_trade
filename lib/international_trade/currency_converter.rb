require 'bigdecimal'
require 'big_decimal_extension'
require 'ostruct'
require 'xmlsimple'

module InternationalTrade
  class CurrencyConverter
    attr_reader :cost, :rates, :target_currency

    def initialize(exchange_data_file, target_currency)
      @target_currency = target_currency.upcase
      parse(exchange_data_file)
    end

    # returns the amount expressed in :target_currency
    def convert(amount)
      @cost, from_currency = amount.split
      @cost = Float(@cost)
      
      return BigDecimal(@cost.to_s, 10) if from_currency == self.target_currency

      BigDecimal((calculated_conversion_rate(from_currency) * @cost).to_s, 10).banker_round
    end

    #######
    private
    #######

    def calculate_from_conversion_rate_indexes(indexes)
      indexes.inject(1) do |mem, idx|
        mem *= Float(conversion_rate_from_index(idx))
      end
    end
    
    def calculated_conversion_rate(from_currency)
      calculate_from_conversion_rate_indexes(calculated_conversion_rate_indexes(from_currency))
    end
    
    def calculated_conversion_rate_indexes(from_currency, conversion_rate_indexes = [])
      puts "from_currency: #{from_currency}"
      potential_source_currencies = _potential_source_currencies(from_currency)
      
      if potential_source_currencies.size > 1
        
        # are any a direct match on the target_currency?
        if direct_match = potential_source_currencies.detect{ |c| c.to == self.target_currency }
          conversion_rate_indexes << direct_match.index
          return conversion_rate_indexes
        else
          # recurse on potential_source_currencies
          potential_source_currencies.each do |candidate|
            next if candidate.to == from_currency
            calculated_conversion_rate_indexes(candidate.from, conversion_rate_indexes)
          end
        end
      else # only 1 potential_source_currency
        potential_currency = potential_source_currencies.first
        conversion_rate_indexes << potential_currency.index
        
        # direct match on the target_currency?
        if potential_currency.to == self.target_currency
          return conversion_rate_indexes
        else
          return calculated_conversion_rate_indexes(potential_currency.to, conversion_rate_indexes)
        end
      end
    end
    
    def conversion_rate_from_index(idx)
      @rates.detect{ |r| r.index == idx }.conversion
    end

    def parse(data_file)
      @rates = XmlSimple.xml_in(data_file, 'ForceArray' => false)['rate']
      post_process_rates
    end
    
    def post_process_rates
      @rates = @rates.enum_for(:each_with_index).collect do |rate, idx|
        # give it an idex for ease of reference
        rate[:index] = idx
        
        # normalize currency casing
        %w(from to).each{ |x| rate[x] = rate[x].upcase}
        rate
      end
      
      # finally we convert the conversions to OpenStructs (mainly so we
      # can use symbol to proc later)
      @rates = rates.collect{ |rate| OpenStruct.new(rate)}
    end
    
    def _potential_source_currencies(from_currency)
      @rates.find_all{|r| r.from == from_currency}
    end
    
    def _potential_target_currencies(target_currency)
      @rates.find_all{|r| r.to == target_currency}
    end
  end
end