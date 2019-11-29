RSpec.describe Command do
  subject { described_class.new(text) }
  let(:text) { 'pingu help' }

  it 'returns a command object' do
    is_expected.to be_an_instance_of Command
  end

  it { is_expected.to respond_to :command }
  it { is_expected.to respond_to :hostnames }

  it 'assigns command text' do
    expect(subject.command).to eql 'help'
  end

  describe '#command' do
    subject { described_class.new(text).command }
    let(:text) { 'pingu ping &lt;<http://mocked-domain.dsd.io|mocked-domain.dsd.io>&gt' }

    it 'returns command text ready for regex matching' do
      is_expected.to eql 'ping'
    end
  end

  describe '#hostnames' do
    subject { described_class.new(text).hostnames }
    let(:text) { 'pingu ping &lt;<http://mocked-domain.dsd.io|mocked-domain.dsd.io>&gt' }

    it 'returns command text ready for regex matching' do
      is_expected.to match_array(['mocked-domain.dsd.io'])
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
      it { is_expected.to be_success_at_attachment }
    end

    context 'when healthcheck command sent' do
      let(:text) { 'pingu healthcheck &lt;mocked-domain.dsd.io&gt;' }
      it { is_expected.to be_success_at_attachment }
    end

    context 'when help command sent' do
      let(:text) { 'pingu help' }

      it 'responds with help text' do
        is_expected.to include_json("\"Say one of the following\"").at_path("text")
      end
    end

    context 'when hi command sent' do
      let(:text) { 'pingu hi' }

      it 'responds with help text' do
        is_expected.to include_json("\"Say one of the following\"").at_path("text")
      end
    end

    context 'when too many domains provided' do
      domains = 11.times.with_object([]) { |i,memo| memo << "mocked-domain-#{i+1}.dsd.io" }.join(',')
      let(:text) { "pingu ping &lt;#{domains}&gt;" }
      it 'raise an error if number of domains exceeds configured limit' do
        expect { subject }.to raise_error described_class::TooManyDomains, 'too many domains!'
      end
    end
  end
end
