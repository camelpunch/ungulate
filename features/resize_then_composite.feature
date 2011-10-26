Feature: Image resize
  As a site owner
  I want Ungulate to resize then composite images
  So that I don't have to watermark images by hand

  Scenario: Run queue on image key with no path separator
    Given an empty queue
    And an empty bucket
    And a request to resize "image.jpg" and then composite with "https://dmxno528jhfy0.cloudfront.net/superhug-watermark.png"
    When I run Ungulate
    Then there should be a public watermarked version

