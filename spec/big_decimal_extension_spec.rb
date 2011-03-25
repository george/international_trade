require 'spec_helper'
require 'bigdecimal'
require 'big_decimal_extension'

describe BigDecimal do
  describe "#banker_round" do
    def rounded(number, scale = 2)
      BigDecimal(number.to_s).banker_round(scale).to_s('F')
    end

    context "with scale of 2" do
      it "returns 54.18 given 54.1754" do
        rounded(54.1754).should == '54.18'
      end

      it "returns 54.18 given 54.1854" do
        rounded(54.1754).should == '54.18'
      end

      it "returns 54.17 given 54.1739" do
        rounded(54.1739).should == '54.17'
      end

      it "returns 54.18 given 54.176" do
        rounded(54.176).should == '54.18'
      end
    end
  end
end
