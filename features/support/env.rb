$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../bin')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../data')

require "rubygems"
require "bundler/setup"

require 'aruba/cucumber'

def usage_information
  <<-EOS
Usage:
	./international_trade [options] data/TRANS.csv data/RATES.xml

Options:
    -s, --sku                  Item for which we compute the grand total of sales (default: DM1182)
    -c, --target_currency      Sets the target currency for output (default: USD)
    -h, --help                 Print this help message
  EOS
end