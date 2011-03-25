# == Background
#   This application is a solution to http://puzzlenode.com/puzzles/2
#
# == Usage
#   international_trade ./international_trade data/TRANS.csv data/RATES.xml
#
#   For help use: ./international_trade -h
#
# == Options
#   -h, --help          Displays help message
#
# == Author
#   George Anderson
#   george@benevolentcode.com

require 'slop'

module InternationalTrade
  class App
    attr_accessor :options, :transactions

    DEFAULT_SKU             = 'DM1182'
    DEFAULT_TARGET_CURRENCY = 'USD'

    def initialize(arguments, stdin)
      @arguments = arguments
      @transactions = []
    end

    # main entry point
    def run
      parse_options
      verify_data_files
      process_arguments
    end

    #######
    private
    #######

    def calculate_total
      result = @transactions.inject(0.0) do |total, txn|
        total += @currency_converter.convert(txn.amount)
      end

      puts result
    end

    def display_usage_and_exit(error_message = nil)
      puts "\n#{error_message}\n\n" if error_message
      puts @options
      exit
    end

    def file_exists?(filepath)
      filepath && File.exists?(filepath)
    end

    def initialize_currency_converter
      @currency_converter = CurrencyConverter.new(@exchange_data_file, @options['target_currency'])
    end

    # workaround until https://github.com/injekt/slop/pull/15 is accepted
    def _parse_options(strict = true)
      @options = Slop.parse!(@arguments, :help => true, :strict => strict) do
        banner "Usage:\n\t./international_trade [options] data/TRANS.csv data/RATES.xml\n\nOptions:"

        on :s, :sku,             "Item for which we compute the grand total of sales (default: #{DEFAULT_SKU})", :optional => true, :default => DEFAULT_SKU
        on :c, :target_currency, "Sets the target currency for output (default: #{DEFAULT_TARGET_CURRENCY})",    :optional => true, :default => DEFAULT_TARGET_CURRENCY
      end
    end

    def parse_options
      _parse_options
    rescue Slop::InvalidOptionError => e
      _parse_options(false)
      display_usage_and_exit(e.message)
    rescue Slop::MissingArgumentError => e
      display_usage_and_exit(e.message)
    end

    # Setup the arguments
    def process_arguments
      process_transactions
      initialize_currency_converter
      calculate_total
    end

    def process_transactions
      @transactions = TransactionParser.parse(@transaction_file, @options['sku'])
    end

    def verify_data_files
      @transaction_file    = @arguments.detect { |path| File.extname(path).downcase == '.csv' }
      @exchange_data_file  = @arguments.detect { |path| File.extname(path).downcase == '.xml' }

      errors = []
      errors << "File containing sales data (#{@transaction_file}) does not exist" unless file_exists?(@transaction_file)
      errors << "File file containing the conversion rates (#{@exchange_data_file}) does not exist" unless file_exists?(@exchange_data_file)

      display_usage_and_exit(errors.join("\n")) unless errors.empty?
    end
  end
end

# TO DO - Add your Modules, Classes, etc
