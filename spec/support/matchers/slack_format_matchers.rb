RSpec::Matchers.define :be_error_at_attachment do |attachment_index|
  match do |actual|
    expect(actual).to be_json_eql("\"Error\"").at_path("attachments/#{attachment_index}/fallback")
    expect(actual).to be_json_eql("\"danger\"").at_path("attachments/#{attachment_index}/color")
    expect(actual).to be_json_eql("\":penguin: Meep meep!\"").at_path("attachments/#{attachment_index}/pretext")
  end
end

RSpec::Matchers.define :be_success_at_attachment do |attachment_index|
  match do |actual|
    expect(actual).to be_json_eql("\"Success\"").at_path("attachments/#{attachment_index}/fallback")
  end
end

RSpec::Matchers.define :be_failure_at_attachment do |attachment_index|
  match do |actual|
    expect(actual).to be_json_eql("\"Failure\"").at_path("attachments/#{attachment_index}/fallback")
    expect(actual).to be_json_eql("\"danger\"").at_path("attachments/#{attachment_index}/color")
    expect(actual).to be_json_eql("\":penguin: Meep meep!\"").at_path("attachments/#{attachment_index}/pretext")
  end
end
