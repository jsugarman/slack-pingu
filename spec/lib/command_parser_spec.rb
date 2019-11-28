RSpec.describe CommandParser do
  subject { described_class.new(text) }
  let(:text) { 'pingu help' }

  it { is_expected.to respond_to :command }
  it { is_expected.to respond_to :hostnames }

  describe '#command' do
    subject { described_class.new(text).command }

    context 'help' do
      let(:text) { 'pingu help' }
      it { is_expected.to eql 'help' }

      context 'with whitespace' do
        let(:text) { "pingu help\s" }
        it { is_expected.to eql 'help' }
      end
    end

    context 'ping' do
      let(:text) { 'pingu ping whatever.com' }
      it { is_expected.to eql 'ping' }
    end

    context 'healthcheck' do
      let(:text) { 'pingu healthcheck whatever.com' }
      it { is_expected.to eql 'healthcheck' }
    end

    context 'unknown command' do
      let(:text) { 'pingu whatever whereever.com' }
      it { expect { subject }.to raise_error described_class::Error, "unknown command \"pingu whatever whereever.com\"" }
    end
  end

  describe '#hostnames' do
    subject { described_class.new(text).hostnames }

    it { is_expected.to be_an(Array) }
    it { is_expected.to all(be_a(String)) }

    context 'one hostname' do
      let(:text) { 'pingu ping <http://whatever.com|whatever.com>' }

      it { is_expected.to eq(['whatever.com']) }
    end

    context 'one hostname old syntax' do
      let(:text) { 'pingu ping <whatever.com>' }

      it { is_expected.to eq(['whatever.com']) }
    end

    context 'multiple hostnames' do
      let(:hostnames) { %w(whatever.com whereever.com anywhere.co.uk) }

      context 'unformatted hostnames' do
        let(:text) { 'pingu ping whatever.com, whereever.com, anywhere.co.uk' }
        it { is_expected.to match_array(hostnames) }
       end

      context 'slack formatted hostnames where protocol NOT specified' do
        let(:text) { 'pingu ping <http://whatever.com|whatever.com>, <http://whereever.com|whatever.com>, <http://anywhere.co.uk|anywhere.co.uk>' }
        it { is_expected.to match_array(hostnames) }
      end

      context 'slack formatted hostnames where protocol specified' do
        let(:text) { 'pingu ping <https://whatever.com>, <https://whereever.com>, <https://anywhere.co.uk' }
        it { is_expected.to match_array(hostnames) }
      end
    end
  end
end
