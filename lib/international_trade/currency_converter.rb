require 'bigdecimal'
require 'big_decimal_extension'
require 'ostruct'
require 'xmlsimple'

module InternationalTrade
  class CurrencyConverter
    attr_reader :cost, :exchange_data_file, :rates, :target_currency

    def initialize(exchange_data_file, target_currency)
      @target_currency = target_currency.upcase
      @exchange_data_file = exchange_data_file
    end

    # returns the amount expressed in :target_currency
    def convert(amount)
      parse
      
      @cost, from_currency = amount.split
      @cost = Float(@cost)
      
      return BigDecimal(@cost.to_s, 10) if from_currency == self.target_currency

      BigDecimal((composite_conversion_rate(from_currency) * @cost).to_s, 10).banker_round
    end

    #######
    private
    #######

    def composite_conversion_rate(from_currency)
      find_constituent_conversion_rates(from_currency).inject(1) do |mem, rate|
        mem *= Float(rate.conversion)
      end
    end
    
    def find_constituent_conversion_rates(from_currency, constituent_conversion_rates = [])
      puts "\n\n########################################\nfrom_currency: #{from_currency} (#{from_currency.class})"
      potential_source_currencies = _potential_source_currencies(from_currency).reject do |src| 
        constituent_conversion_rates.map(&:from).include?(src.to)
      end
puts "potential_source_currencies:"
potential_source_currencies.each do |curr|
  puts "\t#{curr.inspect}" 
end      
      if potential_source_currencies.size > 1
        
        # are any a direct match on the target_currency?
        if direct_match = potential_source_currencies.detect{ |c| c.to == self.target_currency }
puts "PRE: @rates.size: #{@rates.size.inspect}"
puts "PRE: @rates.size: #{constituent_conversion_rates.size.inspect}"
          constituent_conversion_rates << @rates.delete(direct_match)
puts "POST: @rates.size: #{@rates.size.inspect}"          
puts "POST: @rates.size: #{constituent_conversion_rates.size.inspect}"          
          return constituent_conversion_rates
        else
          # recurse on potential_source_currencies
          potential_source_currencies.each do |candidate|
            next if candidate.to == from_currency
            @rates.delete(candidate)
            @rates.delete_if{ |rate| rate.to == candidate.from && rate.from == candidate.to }
            find_constituent_conversion_rates(candidate.from, constituent_conversion_rates)
          end
        end
      elsif potential_source_currencies.first # only 1 potential_source_currency
        potential_currency = potential_source_currencies.first
        constituent_conversion_rates << @rates.delete(potential_currency)
        @rates.delete_if do |rate| 
          begin
            rate.to == potential_currency.from && rate.from == potential_currency.to
          rescue
            raise <<-EOS
            
            rate: #{rate.inspect}
            potential_currency: #{potential_currency.inspect}
            
            EOS
          end
        end
        # direct match on the target_currency?
        if potential_currency.to == self.target_currency
          return constituent_conversion_rates
        else
          return find_constituent_conversion_rates(potential_currency.to, constituent_conversion_rates)
        end
      end
    end
    
    def conversion_rate_from_index(idx)
      @rates.detect{ |r| r.index == idx }.conversion
    end

    def parse
      @rates = _rates
      post_process_rates
    end
    
    def post_process_rates
      @rates = @rates.enum_for(:each_with_index).collect do |rate, idx|
        # normalize currency casing
        %w(from to).each{ |x| rate[x] = rate[x].upcase}
        rate
      end
      
      # convert the conversions to OpenStructs (mainly so we
      # can use symbol to proc later)
      @rates = rates.collect{ |rate| OpenStruct.new(rate)}
    end
    
    def _potential_source_currencies(from_currency)
      @rates.find_all{|r| r.from == from_currency}
    end
    
    def _potential_target_currencies(target_currency)
      @rates.find_all{|r| r.to == target_currency}
    end
    
    def _rates
      @_rates ||= XmlSimple.xml_in(self.exchange_data_file, 'ForceArray' => false)['rate']
    end
  end
end