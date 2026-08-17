# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dashboard::AvatarHelper, type: :helper do
  describe '#avatar_fallback_color_class' do
    it 'returns a deterministic color class between 1 and 8' do
      color1 = helper.avatar_fallback_color_class('John Doe')
      color2 = helper.avatar_fallback_color_class('John Doe')
      expect(color1).to eq(color2)
      expect(color1).to match(/\Aavatar-fallback-[1-8]\z/)
    end

    it 'handles blank name safely' do
      expect(helper.avatar_fallback_color_class('')).to eq('avatar-fallback-1')
      expect(helper.avatar_fallback_color_class(nil)).to eq('avatar-fallback-1')
    end
  end

  describe '#full_name and #initials' do
    let(:user) { double('User', first_name: 'John', middle_name: nil, last_name: 'Smith', name: nil, display_name: nil) }
    let(:bot) { double('Bot', first_name: nil, middle_name: nil, last_name: nil, name: 'Support Bot', display_name: nil) }

    it 'builds full name from parts' do
      expect(helper.full_name(user)).to eq('John Smith')
      expect(helper.initials(user)).to eq('J')
    end

    it 'uses fallback name and initials' do
      expect(helper.full_name(bot)).to eq('Support Bot')
      expect(helper.initials(bot)).to eq('S')
    end

    it 'handles nil resource' do
      expect(helper.full_name(nil)).to be_nil
      expect(helper.initials(nil)).to eq('?')
    end
  end
end
