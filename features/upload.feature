Feature: Upload
  As a site maintainer
  I want users to upload files directly to S3
  So that our servers don't have to deal with the upload

  @selenium
  Scenario: Upload from form
    Given an empty bucket
    And an Ungulate form rendered with a success redirect
    When I attach a file to the form
    And I submit the form
    Then I should be taken to the success redirect URL
    And the file I uploaded should be on S3

