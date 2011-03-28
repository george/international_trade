require 'spec_helper'

module InternationalTrade
  describe CurrencyConverter do
    def convert(target_currency, amount)
      # CurrencyConverter.new('data/SAMPLE_RATES.xml', target_currency).convert(amount).to_s('F')
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
    end
  end
end