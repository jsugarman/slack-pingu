RSpec.describe Command do
  subject { described_class.new(text) }
  let(:text) { 'pingu help' }

  it 'returns as command object' do
    is_expected.to be_an_instance_of Command
  end

  it 'assigns command text to instance variable' do
    expect(subject.instance_variable_get(:@command)).to eql 'pingu help'
  end

  it 'strips html out of command' do
    expect_any_instance_of(described_class).to receive(:strip_html).with(text)
    subject
  end

  it { is_expected.to respond_to :command }

  describe '#command' do
    subject { described_class.new(text).command }
    let(:text) { 'pingu ping &lt;<a href="https://mocked-domain.dsd.io">mocked-domain.dsd.io</a>&gt;' }

    it 'strips html' do
      expect(described_class.new('<br><a href="https://mocked-domain.dsd.io">mocked-domain.dsd.io</a></br>').command).to eql 'mocked-domain.dsd.io'
    end

    it 'decodes slack encodings' do
      expect(described_class.new('&lt;Tom &amp; Jerry&gt;').command).to eql '<Tom & Jerry>'
    end

    it 'returns command text ready for regex matching' do
      is_expected.to eql 'pingu ping <mocked-domain.dsd.io>'
    end
  end

  describe '#response' do
    subject { described_class.new(text).response }
    let(:text) { 'pingu ping &lt;mocked-domain.dsd.io,mocked-domain-2.dsd.io&gt;' }
    let(:slack_response) { instance_double('SlackResponse') }

    it 'returns a slack response attachment for each domain' do
      expect(SlackResponse).to receive(:new).twice.and_return(slack_response)
      expect(slack_response).to receive(:attachment).twice
      subject
    end

    context 'when ping command sent' do
      let(:text) { 'pingu ping &lt;mocked-domain.dsd.io&gt;' }
      it { is_expected.to be_success_at_attachment 0 }
    end

    context 'when healthcheck command sent' do
      let(:text) { 'pingu healthcheck &lt;mocked-domain.dsd.io&gt;' }
      it { is_expected.to be_success_at_attachment 0 }
    end

    context 'when help command sent' do
      let(:text) { 'pingu help' }

      it 'responds with help text' do
        is_expected.to include_json("\"Say one of the following\"").at_path("text")
      end
    end
  end
end