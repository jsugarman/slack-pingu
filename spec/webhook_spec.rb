RSpec.describe Webhook do
  subject { described_class.new }

  it { is_expected.to be_kind_of Sinatra::Wrapper }

  context 'controller' do

    describe 'GET /' do
      before { get '/' }

      it 'responds with success' do
        expect(last_response).to be_ok
      end

      it 'responds with basic help text' do
        expect(last_response.body).to match /slack webhook/i
      end
    end
  end
end
