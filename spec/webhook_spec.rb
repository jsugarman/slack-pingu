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

    describe 'POST /webhook' do
      let(:token) { 'my_fake_token' }
      let(:params) { { token: token, text: text } }
      let(:command) { instance_double('command') }

      before do |example|
        allow(ENV).to receive(:fetch).with('WEBHOOK_TOKEN').and_return token
        post '/webhook', params unless example.metadata[:skip_post]
      end

      context 'when sent an invalid command' do
        let(:text) { 'pingu test' }

        it 'calls error response', :skip_post do
          expect_any_instance_of(described_class).to receive(:error_response)
          post '/webhook', params
        end

        it 'returns status ok' do
          expect(last_response.status).to eql 200
        end

        context 'header' do
          subject(:headers) { last_response.headers }

          it 'content type is JSON' do
            expect(headers['Content-Type']).to eql 'application/json'
          end
        end

        context 'body' do
          subject { last_response.body }

          let(:custom_slack_error) do
            {
              attachments: [
                {
                  fallback: 'Error',
                  pretext: 'Meep meep!',
                  color: 'danger',
                  text: 'test'
                }
              ]
            }.to_json
          end

          it 'returns slack attachment JSON' do
            is_expected.to have_json_path('attachments/0')
          end

          it 'returns slack formatted error message' do
            is_expected.to have_json_size(1).at_path('attachments')
            is_expected.to be_json_eql("\"danger\"").at_path("attachments/0/color")
            is_expected.to be_json_eql("\"Meep meep!\"").at_path("attachments/0/pretext")
            is_expected.to be_json_eql("\"Error\"").at_path("attachments/0/fallback")
            is_expected.to include_json("\"test\"").at_path("attachments/0/text")
          end
        end
      end

      context 'when sent a ping command with one domain argument' do
        subject { last_response.body }

        let(:domain) { 'mocked-domain.dsd.io' }
        let(:text) { "pingu ping &lt;#{domain}&gt;" }
        let(:ping_response) do
            {
              attachments: [
                {
                  fallback: 'Error',
                  pretext: 'Meep meep!',
                  color: 'danger',
                  text: {
                    'mocked-domain.dsd.io': { build_version: "1.0" }
                  }
                }
              ]
            }.to_json
        end

        context 'body' do
          it 'contains slack formatted success message' do
            is_expected.to be_json_eql("\"Success\"").at_path("attachments/0/fallback")
          end

          it 'contains domain name pinged' do
            is_expected.to include_json("\"mocked-domain.dsd.io\"").at_path("attachments/0/pretext")
          end

          it 'contains text representing ping response' do
            puts JSON.parse last_response.body
            is_expected.to be_json_eql("\"1.0\"").at_path("attachments/0/text")
          end
        end
      end

      context 'when sent a ping command with multiple domain args' do
        let(:text) { 'pingu ping my-domain.co.uk, my-other-domain.co.uk' }

        xit 'issues GET to each domains ping endpoint' do
        end

        context 'when ping endpoint responds' do
          xit 'returns each ping response to webhook caller' do
          end
        end
      end
    end
  end
end
