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
        allow(ENV).to receive(:fetch).and_call_original
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

          it 'returns slack attachment' do
            is_expected.to have_json_size(1).at_path('attachments')
          end

          it 'returns slack error attachment' do
            is_expected.to be_error_at_attachment 0
            is_expected.to include_json("\"test\"").at_path("attachments/0/text")
          end
        end
      end

      context 'when sent a ping command with one domain argument' do
        subject { last_response.body }

        let(:domain) { 'mocked-domain.dsd.io' }
        let(:text) { "pingu ping &lt;#{domain}&gt;" }

        context 'body' do
          it 'contains slack formatted success message' do
            is_expected.to be_success_at_attachment 0
          end

          it 'contains domain name pinged' do
            is_expected.to include_json("\"mocked-domain.dsd.io\"").at_path("attachments/0/pretext")
          end

          it 'contains humanized text representing ping response' do
            is_expected.to be_json_eql("\"Build version\"").at_path("attachments/0/fields/0/title")
            is_expected.to be_json_eql("\"1.0\"").at_path("attachments/0/fields/0/value")
          end
        end
      end

      context 'when sent a ping command with multiple domain arguments' do
        subject { last_response.body }

        let(:domains) { %w(mocked-domain.dsd.io mocked-domain-1.dsd.io) }

        context 'separated by commas' do
          let(:text) { "pingu ping &lt;#{domains.join(',')}&gt;" }

          it 'returns a slack attachment for each domain seperated by commas' do
            is_expected.to have_json_size(2).at_path('attachments')
            is_expected.to be_success_at_attachment 0
            is_expected.to be_success_at_attachment 1
          end
        end

        context 'separated by whitespace and commas' do
          context 'space,space' do
            let(:text) { "pingu ping &lt;#{domains.join('  ,  ')}&gt;" }
            it 'returns a slack attachment for each domain seperated by commas with whitespace' do
              is_expected.to have_json_size(2).at_path('attachments')
            end
          end

          context ',space' do
            let(:text) { "pingu ping &lt;#{domains.join(',  ')}&gt;" }
            it 'returns a slack attachment for each domain seperated by commas with whitespace' do
              is_expected.to have_json_size(2).at_path('attachments')
            end
          end
        end
      end
    end
  end
end
