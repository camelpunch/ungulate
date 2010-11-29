module ViewHelpers
  def ungulate_upload_form_for(upload, &block)
    open_form = <<HTML
<form action="#{upload.bucket_url}" enctype="multipart/form-data" method="post">
<div>
<input name="key" type="hidden" value="#{upload.key}" />
<input name="AWSAccessKeyId" type="hidden" value="#{upload.access_key_id}" />
<input name="acl" type="hidden" value="#{upload.acl}" />
<input name="policy" type="hidden" value="#{upload.policy}" />
<input name="signature" type="hidden" value="#{upload.signature}" />
<input name="success_action_redirect" type="hidden" value="#{upload.success_action_redirect}" />
HTML

    close_form = "\n</div>\n</form>\n"

    if respond_to?(:safe_concat)
      content = capture(&block)
      output = ActiveSupport::SafeBuffer.new
      output.safe_concat(open_form.html_safe)
      output << content
      output.safe_concat(close_form.html_safe)
    else
      concat(open_form)
      yield
      concat(close_form)
    end
  end
end
