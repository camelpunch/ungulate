module ViewHelpers
  def ungulate_upload_form_for(upload, &block)
    concat(%Q(<form action="#{upload.bucket_url}" enctype="multipart/form-data" method="post">\n))
    concat("<div>\n")
    concat(%Q(<input name="key" type="hidden" value="#{upload.key}" />\n))
    concat(%Q(<input name="AWSAccessKeyId" type="hidden" value="#{upload.access_key_id}" />\n))
    concat(%Q(<input name="acl" type="hidden" value="#{upload.acl}" />\n))
    concat(%Q(<input name="policy" type="hidden" value="#{upload.policy}" />\n))
    concat(%Q(<input name="signature" type="hidden" value="#{upload.signature}" />\n))
    concat(%Q(<input name="success_action_redirect" type="hidden" value="#{upload.success_action_redirect}" />\n))
    yield
    concat("\n</div>\n")
    concat("</form>\n")
  end
end
