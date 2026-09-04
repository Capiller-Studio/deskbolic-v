# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard::Messages', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let!(:account_user) { create(:account_user, account: account, user: user, owner: true) }
  let(:plan) { create(:plan, :free) }
  let!(:subscription) { create(:subscription, account: account, plan: plan, status: :active) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }

  before do
    set_subdomain(account.identifier)
    sign_in user
  end

  describe 'POST /messages' do
    it 'creates an outgoing agent message' do
      post messages_path(locale: :en),
           params: {
             message: {
               conversation_id: conversation.id,
               response: 'Hello! How can I help you today?',
               message_type: 'outgoing'
             }
           },
           headers: { 'HTTP_REFERER' => "/en/conversations/#{conversation.id}" }
      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      expect(conversation.messages.where(content: 'Hello! How can I help you today?')).to exist
    end

    it 'creates a message with attachments' do
      file = fixture_file_upload(
        Rails.root.join('../core/spec/fixtures/files/test.png'),
        'image/png'
      ) rescue Rack::Test::UploadedFile.new(StringIO.new('fake-image'), 'image/png', original_filename: 'test.png')

      post messages_path(locale: :en),
           params: {
             message: {
               conversation_id: conversation.id,
               response: 'Here is the image',
               attachments: [ file ]
             }
           },
           headers: { 'HTTP_REFERER' => "/en/conversations/#{conversation.id}" }

      expect(response).to have_http_status(:redirect).or have_http_status(:ok)
      created_message = conversation.messages.last
      expect(created_message.content).to eq('Here is the image')
      expect(created_message.attachments.count).to eq(1)
    end

    context 'with Facebook Page channel' do
      let(:fb_channel) { create(:channel_facebook_page, account: account) }
      let(:fb_inbox) { create(:inbox, account: account, channel: fb_channel) }
      let(:fb_conversation) { create(:conversation, account: account, inbox: fb_inbox) }

      before do
        allow(Facebook::Messenger::Subscriptions).to receive_messages(subscribe: true, unsubscribe: true)
      end

      it 'splits text and attachment into sibling messages' do
        file = Rack::Test::UploadedFile.new(StringIO.new('fake-image'), 'image/png', original_filename: 'test.png')

        expect {
          post messages_path(locale: :en),
               params: {
                 message: {
                   conversation_id: fb_conversation.id,
                   response: 'Screenshot attached',
                   attachments: [ file ]
                 }
               },
               headers: { 'HTTP_REFERER' => "/en/conversations/#{fb_conversation.id}" }
        }.to change { fb_conversation.messages.count }.by(2)

        messages = fb_conversation.messages.order(created_at: :asc)
        expect(messages.first.content).to eq('Screenshot attached')
        expect(messages.first.attachments).to be_empty
        expect(messages.second.content).to be_nil
        expect(messages.second.attachments.count).to eq(1)
      end
    end

    context 'with personal note and mentions' do
      let(:mentioned_user) { create(:user, first_name: 'John', last_name: 'Doe') }
      let!(:mentioned_account_user) { create(:account_user, account: account, user: mentioned_user) }

      it 'creates a personal note and parses user mentions' do
        post messages_path(locale: :en),
             params: {
               message: {
                 conversation_id: conversation.id,
                 response: 'Note for @John about the issue',
                 visibility: 'personal'
               }
             },
             headers: { 'HTTP_REFERER' => "/en/conversations/#{conversation.id}" }

        expect(response).to have_http_status(:redirect).or have_http_status(:ok)
        note = conversation.messages.last
        expect(note.personal?).to be(true)
        expect(note.content).to eq('Note for @John about the issue')
        expect(Mention.where(resource: note, mentioned: mentioned_user)).to exist
      end
    end
  end
end
