require 'spec_helper'

module InternationalTrade
  describe App do

    def run_app(arguments = nil, options = nil)
      arguments ||= %w(data/SAMPLE_TRANS.csv data/SAMPLE_RATES.xml)
      arguments += options.split if options

      @app = App.new(arguments, nil)
      @app.run
    end

    describe "the sales 'sku' in question" do
      it "defaults to 'DM1182'" do
        run_app
        @app.options['sku'].should == 'DM1182'
      end

      it "may be passed as an option using the '-s' switch" do
        run_app(nil, '-s XXX123')
        @app.options['sku'].should == 'XXX123'
      end

      it "may be passed as an option using the '--sku' switch" do
        run_app(nil, '--sku YYY789')
        @app.options['sku'].should == 'YYY789'
      end
    end

    describe "the target currency" do
      it "defaults to 'USD'" do
        run_app
        @app.options['target_currency'].should == 'USD'
      end

      it "may be passed as an option using the '-c' switch" do
        run_app(nil, '-c CAD')
        @app.options['target_currency'].should == 'CAD'
      end

      it "may be passed as an option using the '--target_currency' switch" do
        run_app(nil, '--target_currency CAD')
        @app.options['target_currency'].should == 'CAD'
      end

    end

    describe "#transactions" do
      before { run_app(nil, '--sku DM1182') }
      it "include transactions for the sales 'sku' in question" do
        @app.transactions.size.should == 3 # sanity check
        @app.transactions.each do |txn|
          txn.sku.should == 'DM1182'
        end
      end
    end

  end
end
