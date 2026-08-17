# frozen_string_literal: true

module Dashboard
  module InboxHelper
    def inbox_icon(inbox)
      icon = case inbox.channel_type
            when 'Channel::WebWidget'    then 'widget.svg'
            when 'Channel::FacebookPage' then 'facebook.svg'
            when 'Channel::Instagram'    then 'insta.svg'
            when 'Channel::Whatsapp'     then 'whatsapp_badge.svg'
            when 'Channel::Email'        then 'email.svg'
            when 'Channel::ContactForm'  then 'contact_form.svg'
            when 'Channel::Custom'       then 'custom_ch.svg'
            else 'widget.svg'
            end

      inline_svg_tag(icon, class: 'link-icon', alt: 'inbox icon')
    end
  end
end