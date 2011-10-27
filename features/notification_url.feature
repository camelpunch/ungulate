Feature: Notification URL
  As a developer
  I want Ungulate to PUT to a URL when it's finished a job
  So that I don't have to poll for the completed resource

  Background:
    Given an empty queue
    And an empty bucket

  Scenario: Run queue that has one image job
    Given a request that has a notification URL
    When I run Ungulate
    Then the notification URL should receive a PUT

