# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  it 'successfully connects with valid user token' do
    allow(User).to receive(:find_by).with(connection_token: 'valid_user_token').and_return(user)

    connect '/cable?user_token=valid_user_token'
    expect(connection.current_user).to eq(user)
  end

  it 'rejects connection without token' do
    expect { connect '/cable' }.to have_rejected_connection
  end
end
