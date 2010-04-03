Feature: Cope with empty queue
  As a sysadmin
  I want Ungulate to cope with an empty queue
  So that it doesn't cause alarm in normal situations

  Scenario: Run on empty queue
    Given an empty queue
    When I run Ungulate
    Then there should be no errors

