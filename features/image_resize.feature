Feature: Image resize
  As a developer
  I want Ungulate to resize images
  So that I don't have to do it in my application

  Scenario: Run queue
    Given an empty queue
    And a request to resize "image.jpg" to sizes:
      | label | width | height  |
      | large | 200   | 100     |
      | small | 100   | 50      |
    When I run Ungulate
    Then there should be the following versions:
      | key                     |
      | image_large.jpg |
      | image_small.jpg |

