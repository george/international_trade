$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../bin')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../data')

require 'aruba/cucumber'

def usage_information
  <<-EOS
Usage:
    ./international_trade [options] data/TRANS.csv data/RATES.xml

Options:
    -s, --sku [SKU]                  Item for which we compute the grand total of sales (default: DM1182)
    -c, --currency [CURRENCY]        Sets the target currency for output (default: USD)
    -h, --help                       Show this message
  EOS
end