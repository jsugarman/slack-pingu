# frozen_string_literal: true

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

      context 'as reminder' do
        let(:text) { 'Reminder: pingu ping &lt;<http://claim-crown-court-defence.service.gov.uk|claim-crown-court-defence.service.gov.uk>&gt;' }
        it { is_expected.to eql 'ping' }
      end
    end

    context 'healthcheck' do
      let(:text) { 'pingu healthcheck whatever.com' }
      it { is_expected.to eql 'healthcheck' }

      context 'as reminder' do
        let(:text) { 'Reminder: pingu ping &lt;<http://claim-crown-court-defence.service.gov.uk|claim-crown-court-defence.service.gov.uk>&gt;' }
        it { is_expected.to eql 'ping' }
      end
    end

    context 'unknown command' do
      let(:text) { 'pingu whatever whereever.com' }
      it { expect { subject }.to raise_error described_class::UnknownCommand, 'unknown command "pingu whatever whereever.com"' }
    end
  end

  describe '#hostnames' do
    subject { described_class.new(text).hostnames }

    let(:hostnames) { %w[whatever.com whereever.com anywhere.co.uk] }

    it { is_expected.to be_an(Array) }
    it { is_expected.to all(be_a(String)) }

    context 'one hostname with slack markdown' do
      let(:text) { 'pingu ping <http://whatever.com|whatever.com>' }

      it { is_expected.to eq(['whatever.com']) }
    end

    context 'one hostname old syntax' do
      let(:text) { 'pingu ping <whatever.com>' }

      it { is_expected.to eq(['whatever.com']) }
    end

    context 'with one hostname old syntax, slack encoding' do
      let(:text) { 'Reminder: pingu ping &lt;<http://whatever.com|whatever.com>&gt;' }
      it { is_expected.to eq(['whatever.com']) }
    end

    xcontext 'with one hostname old syntax, html' do
      let(:text) { 'Reminder: pingu ping &lt;<a href="https://whatever.com">whatever.com</a>&gt;' }
      it { is_expected.to eq(['whatever.com']) }
    end

    context 'with multiple unformatted hostnames' do
      let(:text) { 'pingu ping whatever.com, whereever.com, anywhere.co.uk' }

      it { is_expected.to match_array(hostnames) }
    end

    context 'with multiple hostnames where protocol NOT specified' do
      let(:text) { 'pingu ping <http://whatever.com|whatever.com>, <http://whereever.com|whatever.com>, <http://anywhere.co.uk|anywhere.co.uk>' }

      it { is_expected.to match_array(hostnames) }
    end

    context 'with multiple hostnames where protocol specified' do
      let(:text) { 'pingu ping <https://whatever.com>, <https://whereever.com>, <https://anywhere.co.uk' }

      it { is_expected.to match_array(hostnames) }
    end

    context 'with multiple hostnames, old slack syntax, reminder' do
      let(:text) { 'Reminder: pingu ping &lt;<http://whatever.com|whatever.com>, <http://whereever.com|whatever.com>, <http://anywhere.co.uk|anywhere.co.uk>&gt;' }

      it { is_expected.to match_array(hostnames) }
    end

    context 'with multiple hostnames including unicode' do
      let(:text) { "pingu ping \u00A0https://whatever.com, \u00A0https://whereever.com, \u00A0https://anywhere.co.uk" }

      it { is_expected.to match_array(hostnames) }
    end
  end
end
