require 'spec_helper'

module InternationalTrade
  describe CurrencyConverter do
    def convert(target_currency, amount)
      CurrencyConverter.new('data/SAMPLE_RATES.xml', target_currency).convert(amount).to_s('F')
    end

    describe "#convert" do
      # no conversion
      it "returns '101.67 USD' given '101.67 USD'" do
        convert('USD', '101.67 USD').should == '101.67'
      end

      # single-step conversion
      it "returns '100.79 CAD' given '100 AUD'" do
        convert('CAD', '100 AUD').should == '100.79'
      end

      # two-step conversion
      it "returns '101.7 USD' given '100.0 AUD'" do
        convert('USD', '100 AUD').should == '101.7'
      end

      # regression
      it "properly converts AUD => USD after converting EUR => USD" do
        converter = CurrencyConverter.new('data/RATES.xml', 'USD')

        converter.convert('1.0 EUR').to_s('F').should == '1.37'
        converter.convert('1.0 AUD').to_s('F').should == '1.02'
      end
    end
  end

  describe CurrencyConverter do
    def composite_conversion_rate(from_currency, target_currency, converter = nil)
      @converter = converter || CurrencyConverter.new('data/RATES.xml', target_currency)

      @converter.instance_variable_set(:@rates, @converter.instance_variable_get(:@all_rates))
      @converter.send(:composite_conversion_rate, from_currency)
    end

    describe "#composite_conversion_rate" do
      CONVERSIONS = [ ['AUD', 'CAD', '1.0079'],
                      ['AUD', 'EUR', '0.7439'],
                      ['AUD', 'USD', '1.0169711'],
                      ['CAD', 'AUD', '0.9921'],
                      ['CAD', 'EUR', '0.73802319'],
                      ['CAD', 'USD', '1.009'],
                      ['EUR', 'AUD', '1.3442'],
                      ['EUR', 'CAD', '1.35481918'],
                      ['EUR', 'USD', '1.36701255262'],
                      ['USD', 'AUD', '0.98327031'],
                      ['USD', 'CAD', '0.9911'],
                      ['USD', 'EUR', '0.731454783609']
                    ]

      CONVERSIONS.each do |conversion|
        it "returns '#{conversion[2]}' when converting from '#{conversion[0]}' to '#{conversion[1]}'" do
          expected  = BigDecimal(conversion[2], 15)
          converted = composite_conversion_rate(conversion[0], conversion[1])

          converted.class.should     == expected.class
          converted.to_s('F').should == expected.to_s('F')
        end
      end

      it "caches calculated conversion rates" do
        converter = CurrencyConverter.new('data/RATES.xml', 'USD')
        converter.should_receive(:composite_conversion_rate).once.and_return(BigDecimal('2.0', 15))

        converter.convert('1.0 EUR')
        converter.convert('100.0 EUR')
      end
    end
  end
end