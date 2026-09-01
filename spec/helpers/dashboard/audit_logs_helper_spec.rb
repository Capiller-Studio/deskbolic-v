# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::AuditLogsHelper, type: :helper do
  describe '#audit_log_sensitive_field?' do
    it 'identifies sensitive field names' do
      expect(helper.audit_log_sensitive_field?('password')).to be true
      expect(helper.audit_log_sensitive_field?('encrypted_password')).to be true
      expect(helper.audit_log_sensitive_field?('api_key')).to be true
      expect(helper.audit_log_sensitive_field?('secret_token')).to be true
      expect(helper.audit_log_sensitive_field?('access_token')).to be true
      expect(helper.audit_log_sensitive_field?('auth_token')).to be true
      expect(helper.audit_log_sensitive_field?('smtp_configurations')).to be false # container hash, checked recursively
    end

    it 'allows non-sensitive fields' do
      expect(helper.audit_log_sensitive_field?('title')).to be false
      expect(helper.audit_log_sensitive_field?('name')).to be false
      expect(helper.audit_log_sensitive_field?('event_key')).to be false
      expect(helper.audit_log_sensitive_field?('status')).to be false
      expect(helper.audit_log_sensitive_field?('user_id')).to be false
    end
  end

  describe '#audit_log_format_value' do
    it 'masks sensitive field values with bullets' do
      expect(helper.audit_log_format_value('api_key', 'super_secret_123')).to eq('••••••••')
      expect(helper.audit_log_format_value('password', 'my_password')).to eq('••••••••')
      expect(helper.audit_log_format_value('token', 'eyJhbGciOiJIUzI1Ni...')).to eq('••••••••')
    end

    it 'masks explicit [FILTERED] values' do
      expect(helper.audit_log_format_value('title', '[FILTERED]')).to eq('••••••••')
    end

    it 'formats non-sensitive values normally' do
      expect(helper.audit_log_format_value('name', 'Support Team')).to eq('Support Team')
      expect(helper.audit_log_format_value('status', 'active')).to eq('active')
      expect(helper.audit_log_format_value('count', 42)).to eq('42')
    end

    it 'handles nil gracefully' do
      expect(helper.audit_log_format_value('title', nil)).to eq('—')
    end

    it 'sanitizes sensitive keys inside nested hashes' do
      nested = { 'address' => 'smtp.example.com', 'password' => 'secret_pass' }
      result = helper.audit_log_format_value('smtp_configurations', nested, max_len: 100)
      expect(result).to include('smtp.example.com')
      expect(result).to include('••••••••')
      expect(result).not_to include('secret_pass')
    end
  end

  describe '#audit_log_changes_for' do
    let(:activity) do
      double(
        'Activity',
        object_changes: {
          'id' => ['old_id', 'new_id'],
          'account_id' => ['old_acc', 'new_acc'],
          'title' => ['Old Title', 'New Title'],
          'color' => ['#ffffff', '#000000'],
          'inbox_id' => ['old_inbox', 'new_inbox']
        }
      )
    end

    it 'filters out ignored metadata and internal foreign keys' do
      changes = helper.audit_log_changes_for(activity)
      expect(changes.keys).to contain_exactly('title', 'color')
    end
  end
end
