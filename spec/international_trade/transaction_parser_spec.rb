require 'spec_helper'

module InternationalTrade
  describe TransactionParser do
    let(:parsed_transactions) { TransactionParser.parse('data/SAMPLE_TRANS.csv', 'DM1182') }
    describe ".parse" do
      subject { parsed_transactions }

      it "returns an Array" do
        subject.should be_an Array
      end

      describe "returns transactions which" do

        it "respond to #store" do
          parsed_transactions.each do |txn|
            txn.store.should_not be_nil
          end
        end

        it "return the appropriate 'sku' for #sku" do
          parsed_transactions.each do |txn|
            txn.sku.should == 'DM1182'
          end
        end

        it "respond to #amount" do
          parsed_transactions.each do |txn|
            txn.amount.should_not be_nil
          end
        end
      end


    end
  end
end