Feature: Image resize
  As a developer
  I want Ungulate to resize images
  So that I don't have to do it in my application

  Background:
    Given an empty queue
    And an empty bucket

  Scenario: Run queue on image key with no path separator
    Given a request to resize "image.jpg" to sizes:
      | label | width | height  |
      | large | 200   | 100     |
      | small | 100   | 50      |
    When I run Ungulate
    Then there should be the following public versions:
      | key             |
      | image_large.jpg |
      | image_small.jpg |

  Scenario: Run queue on image key with path separator
    Given a request to resize "some/path/to/image.jpg" to sizes:
      | label | width | height  |
      | large | 200   | 100     |
      | small | 100   | 50      |
    When I run Ungulate
    Then there should be the following public versions:
      | key                           |
      | some/path/to/image_large.jpg  |
      | some/path/to/image_small.jpg  |

