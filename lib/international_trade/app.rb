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

    DEFAULT_SKU = 'DM1182'
    DEFAULT_TARGET_CURRENCY = 'USD'

    def initialize(arguments, stdin)
      @arguments = arguments

      # default options
      @options = OpenStruct.new
      @options.sku = DEFAULT_SKU
      @options.target_currency = DEFAULT_TARGET_CURRENCY

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
      @transactions.inject(0.0) do |total, txn|
        # total +=
      end
    end

    def parse_options
      @optparse = OptionParser.new do |opts|
        opts.banner = "Usage:", "\n    ./international_trade [options] data/TRANS.csv data/RATES.xml"
        opts.separator ""
        opts.separator "Options:"

        # opts.on( '-s', '--sku [SKU]', "Item for which we compute the grand total of sales (default: #{DEFAULT_SKU})" ) do |f|
        #   @options.sku = f.strip
        # end
        #
        opts.on( '-s', '--sku [SKU]', "Item for which we compute the grand total of sales (default: #{DEFAULT_SKU})" ) do |sku|
          @options.sku = sku.strip
        end

        opts.on( '-c', '--currency [CURRENCY]', "Sets the target currency for output (default: #{DEFAULT_TARGET_CURRENCY})" ) do |currency|
          @options.target_currency = currency.strip
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
      end

      @optparse.parse!(@arguments)

    rescue OptionParser::InvalidOption => e
      display_usage_and_exit(e.message)
    end

    def verify_data_files
      @transaction_file    = @arguments.detect { |path| File.extname(path).downcase == '.csv' }
      @exchange_data_file = @arguments.detect { |path| File.extname(path).downcase == '.xml' }

      errors = []
      errors << "File containing sales data (#{@transaction_file}) does not exist" unless file_exists?(@transaction_file)
      errors << "File file containing the conversion rates (#{@exchange_data_file}) does not exist" unless file_exists?(@exchange_data_file)

      display_usage_and_exit(errors.join("\n")) unless errors.empty?
    end

    # Setup the arguments
    def process_arguments
      process_transactions
      calculate_total
    end

    def process_transactions
      @transactions = TransactionParser.parse(@transaction_file, @options.sku)
    end

    def display_usage_and_exit(error_message = nil)
      puts "\n#{error_message}\n\n" if error_message
      puts @optparse
      exit
    end

    def file_exists?(filepath)
      filepath && File.exists?(filepath)
    end
  end
end

# TO DO - Add your Modules, Classes, etc
