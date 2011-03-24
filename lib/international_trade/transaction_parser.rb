require 'fastercsv'
require 'ostruct'

module InternationalTrade
  class TransactionParser
    def self.parse(filepath, sku)
      @filepath = filepath
      fetch_transactions_for(sku)
    end

    #######
    private
    #######

    def self.headers
      @headers ||= raw_csv_rows[0]
    end

    def self.fetch_transactions_for(sku)
      raw_transaction_rows.collect do |transaction_row|
        next unless FasterCSV::Row.new(headers, transaction_row).field('sku') == sku
        OpenStruct.new(Hash[headers.zip(transaction_row)])
      end.compact
    end

    def self.raw_csv_rows
      @raw_csv_rows ||= FasterCSV.read(@filepath)
    end

    def self.raw_transaction_rows
      raw_csv_rows[1..-1] # remove headers
    end
  end
end