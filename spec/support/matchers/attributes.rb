RSpec::Matchers.define :have_reader_for do |attribute|
  match do |record|
    record.send(attribute) == send(attribute)
  end

  description do
    "have a readable #{attribute}"
  end
end
