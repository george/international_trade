require 'bigdecimal'
require 'big_decimal_extension'
require 'ostruct'
require 'xmlsimple'

module InternationalTrade
  class CurrencyConverter
    attr_reader :cost, :exchange_data_file, :rates, :target_currency
    attr_accessor :constituent_conversion_rates

    def initialize(exchange_data_file, target_currency)
      @target_currency = target_currency.upcase
      @exchange_data_file = exchange_data_file
    end

    # returns the amount expressed in :target_currency
    def convert(amount)
      @cost, from_currency = amount.split
      @cost = BigDecimal(@cost, 15)

      return BigDecimal(@cost.to_s, 15) if from_currency == self.target_currency
      
      parse_exchange_data_file

      (composite_conversion_rate(from_currency) * @cost).banker_round
    end

    #######
    private
    #######
    def composite_conversion_rate(from_currency)
      puts "=> from #{from_currency} (ultimately to: #{self.target_currency})"
      puts "\tdomain:\n#{self.rates.map{|r| "\t\t#{r.from} => #{r.to}"}.join("\n")}"
      # return BigDecimal('1.0', 15) if from_currency == self.target_currency

      if exact_match = self.rates.detect{ |r| r.from == from_currency && r.to == self.target_currency }
        puts "\t!!! exact_match: #{exact_match.conversion.to_s('F')}"
        return exact_match.conversion
      end
      
      sub_domain = self.rates.find_all{ |r| r.from == from_currency }
      
      puts "\t\tsub_domain:\n#{sub_domain.map{|r| "\t\t\t#{r.from} => #{r.to}"}.join("\n")}"
      
      sub_domain.each do |rate|
        puts "\t>> looking at: #{rate.from} => #{rate.to}"
        
        self.rates.delete_if{ |r| r == rate || ( r.to == rate.from && r.from == rate.to ) } # no back-tracking
        
        if conversion = composite_conversion_rate(rate.to)
          puts "\t!!! conversion match: #{rate.conversion.to_s('F')} (conversion: #{conversion.to_s('F')})"
          return ( conversion * rate.conversion )
          break
        end
      end
    end

    def yyy_composite_conversion_rate(from_currency)
      return 1.0 if from_currency == self.target_currency

# raise <<-EOS
#
# find_constituent_conversion_rates(from_currency): #{find_constituent_conversion_rates(from_currency).inspect}
#
# self.constituent_conversion_rates: #{self.constituent_conversion_rates.inspect}
#
# EOS

      # raise find_constituent_conversion_rates(from_currency).inspect
      find_constituent_conversion_rates(from_currency).inject(1.0) do |mem, rate|
        mem *= Float(rate.conversion)
      end
    end

    def find_constituent_conversion_rates(from_currency)
      puts "\n\n########################################\nfrom_currency: #{from_currency} (to: #{self.target_currency.inspect})"
      potential_source_currencies = _potential_source_currencies(from_currency).reject do |src|
        self.constituent_conversion_rates.map(&:from).include?(src.to)
      end
puts "potential_source_currencies:"
potential_source_currencies.each do |curr|
  puts "\t#{curr.inspect}"
end

      if potential_source_currencies.size > 1
        if direct_match = potential_source_currencies.detect{ |c| c.to == self.target_currency }
          puts "!!! pushing (direct_match): #{direct_match}"
          self.constituent_conversion_rates << @rates.delete(direct_match).dup
          puts "\tself.constituent_conversion_rates NOW is: #{self.constituent_conversion_rates.inspect}"
        else
          # recurse on potential_source_currencies
          potential_source_currencies.reject{|s| s.to == from_currency}.each do |candidate|
            @rates.delete(candidate)
            @rates.delete_if{ |rate| rate.to == candidate.from && rate.from == candidate.to }
            if find_constituent_conversion_rates((_candidate = candidate).dup.to)
              puts "!!! pushing (after the fact): #{candidate}"
              # self.constituent_conversion_rates << @rates.delete(_candidate).dup
              self.constituent_conversion_rates << _candidate
              puts "\tself.constituent_conversion_rates NOW is: #{self.constituent_conversion_rates.inspect}"
              return self.constituent_conversion_rates
            end
          end
        end
      elsif potential_currency = potential_source_currencies.first
        puts "!!! pushing (potential_currency): #{potential_currency}"
        self.constituent_conversion_rates << @rates.delete(potential_currency).dup
        puts "\tself.constituent_conversion_rates NOW is: #{self.constituent_conversion_rates.inspect}"
        @rates.delete_if{ |rate| rate.to == potential_currency.from && rate.from == potential_currency.to }

        # direct match on the target_currency?
        if potential_currency.to == self.target_currency
          return self.constituent_conversion_rates
        else
          return find_constituent_conversion_rates(potential_currency.to)
        end
      else
        # do nothing (?)
        puts "~~DOING NOTHING~~"
      end

# [OpenStruct.new(:conversion => 1_000_000_000_000)]
    end

    def xxx_find_constituent_conversion_rates(from_currency, constituent_conversion_rates = [])
      puts "\n\n########################################\nfrom_currency: #{from_currency} (to: #{self.target_currency.inspect})"
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

    def parse_exchange_data_file
      @rates = _parse_exchange_data_file
      post_process_rates
    end

    def post_process_rates
      @rates = @rates.collect do |rate|
        # Float-ify conversion rates for cleaner code (later)
        rate['conversion'] = BigDecimal(rate['conversion'], 15)
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

    def _parse_exchange_data_file
      @_parse_exchange_data_file ||= XmlSimple.xml_in(self.exchange_data_file, 'ForceArray' => false)['rate']
    end
  end
end