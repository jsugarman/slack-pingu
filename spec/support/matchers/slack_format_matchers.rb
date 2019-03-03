RSpec::Matchers.define :be_error_at_attachment do |index: 0, pretext: nil|
  match do |actual|
    expect(actual).to be_json_eql('"Error"').at_path("attachments/#{index}/fallback")
    expect(actual).to be_json_eql('"danger"').at_path("attachments/#{index}/color")
    expect(actual).to include_json("\":penguin: Meep meep!\"").at_path("attachments/#{index}/pretext")
    expect(actual).to include_json("\"problems contacting\"").at_path("attachments/#{index}/pretext") if pretext
    true
  end
end

RSpec::Matchers.define :be_success_at_attachment do |index: 0|
  match do |actual|
    expect(actual).to be_json_eql("\"Success\"").at_path("attachments/#{index}/fallback")
    expect(actual).to include_json("\":penguin: Woohoo!\"").at_path("attachments/#{index}/pretext")
    expect(actual).to include_json("\"looks good!\"").at_path("attachments/#{index}/pretext")
  end
end
