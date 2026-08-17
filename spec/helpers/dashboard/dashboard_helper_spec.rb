# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::DashboardHelper, type: :helper do
  describe '#flash_alert_type' do
    it 'maps flash types to color classes' do
      expect(helper.flash_alert_type('success')).to eq('green')
      expect(helper.flash_alert_type('error')).to eq('red')
      expect(helper.flash_alert_type('alert')).to eq('blue')
      expect(helper.flash_alert_type('notice')).to eq('yellow')
      expect(helper.flash_alert_type('unknown')).to eq('green')
    end
  end

  describe '#member_status_class and #team_status_class' do
    it 'maps member and team statuses to color classes' do
      expect(helper.member_status_class('active')).to eq('green')
      expect(helper.member_status_class('offline')).to eq('gray')
      expect(helper.member_status_class('inactive')).to eq('red')
      expect(helper.team_status_class('archived')).to eq('gray')
    end
  end

  describe '#strategy_icon' do
    it 'maps assignment strategies to emojis' do
      expect(helper.strategy_icon('round_robin')).to eq('🔄')
      expect(helper.strategy_icon('load_balanced')).to eq('⚖️')
      expect(helper.strategy_icon('skills_based')).to eq('🎯')
      expect(helper.strategy_icon('manual')).to eq('✋')
      expect(helper.strategy_icon('other')).to eq('📋')
    end
  end
end
