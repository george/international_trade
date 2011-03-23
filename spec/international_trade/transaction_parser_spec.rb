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
    # subject { TransactionParser.new('data/SAMPLE_TRANS.csv', 'DM1182') }
    #
    # it "responds to :filepath" do
    #   subject.filepath.should == 'data/SAMPLE_TRANS.csv'
    # end
    #
    # it "knows how many transactions it has" do
    #   subject.transactions.size.should == 5
    # end
    #
    # describe "an individual transaction" do
    #   subject { sales.transactions.first }
    #   let(:sales) { TransactionParser.new('data/SAMPLE_TRANS.csv') }
    #
    #   it "responds to :store" do
    #     subject.store.should == 'Yonkers'
    #   end
    #
    #   it "responds to :sku" do
    #     subject.sku.should == 'DM1210'
    #   end
    #
    #   it "responds to :amount" do
    #     subject.amount.should == '70.00 USD'
    #   end
    # end
  end
end