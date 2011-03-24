Feature: International trade
  In order to get into Ruby Mendicant University's May 2011 Core Skills Course
  As a ruby developer
  I want to complete the "International Trade" puzzle

  Scenario: asking for help
    When I run "international_trade -h"
    Then the output should contain usage information

  Scenario: fail running with no arguments
    When I run "international_trade"
    Then the output should contain usage information

  Scenario: fail running without exchange rates file
    When I run "international_trade TRANS.csv"
    Then the output should contain usage information

  Scenario: fail running without sales data file
    When I run "international_trade RATES.xml"
    Then the output should contain usage information

  Scenario: fail running with invalid option
    When I run "international_trade -x RATES.xml"
    Then the output should contain:
      """
      Unknown option -- 'x'
      """
    And the output should contain usage information

  Scenario: fail when passing in non-existent data files
    When I run "international_trade NONEXISTENT.csv NONEXISTENT.xml"
    Then the output should contain:
      """
      File containing sales data (NONEXISTENT.csv) does not exist
      """
      And the output should contain:
        """
        File file containing the conversion rates (NONEXISTENT.xml) does not exist
        """
      And the output should contain usage information

  Scenario: OK running with valid data files
    Given a file named "data/SAMPLE_TRANS.csv"
      And a file named "data/SAMPLE_RATES.xml"
    When I run "international_trade data/SAMPLE_TRANS.csv data/SAMPLE_RATES.xml"
    Then the output should not contain usage information


  Scenario: valid output file produced from valid data files
      Given a file named "data/SAMPLE_TRANS.csv" with:
        """
        store,sku,amount
        Yonkers,DM1210,70.00 USD
        Yonkers,DM1182,19.68 AUD
        Nashua,DM1182,58.58 AUD
        Scranton,DM1210,68.76 USD
        Camden,DM1182,54.64 USD

        """
      And a file named "data/SAMPLE_RATES.xml" with:
        """
        <?xml version="1.0"?>
        <rates>
          <rate>
            <from>AUD</from>
            <to>CAD</to>
            <conversion>1.0079</conversion>
          </rate>
          <rate>
            <from>CAD</from>
            <to>USD</to>
            <conversion>1.0090</conversion>
          </rate>
          <rate>
            <from>USD</from>
            <to>CAD</to>
            <conversion>0.9911</conversion>
          </rate>
        </rates>

        """
      When I run "international_trade data/SAMPLE_TRANS.csv data/SAMPLE_RATES.xml"
      Then the output should not contain usage information
        And the output should contain:
          """
          134.22
          """
