Feature: Set a version's image quality
  As a developer
  I want to be able to specify an image version's quality
  So that I can store smaller files, or deliberately reduce their quality

  Scenario: Run queue that has one image job
    Given an empty queue
    And an empty bucket
    And a request to resize "some/path/to/image.jpg" to sizes:
      | label     | width | height  | quality |
      | large     | 200   | 100     | 75      |
      | large_low | 200   | 100     | 50      |
      | small     | 100   | 50      | 40      |
      | small_low | 100   | 50      | 30      |
    When I run Ungulate
    Then the "large_low" version should have a smaller file than the "large" version
    And the "small_low" version should have a smaller file than the "small" version

