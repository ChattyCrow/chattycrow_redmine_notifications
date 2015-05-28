# encoding: utf-8
#
# This file is a part of Redmine ChattyCrow notifictation
#
# @author Strnadj <jan.strnadek@gmail.com>

module RedmineChattyCrowNotifications
  module Hooks

    # Notification hook from my account
    class MyAccountHook < Redmine::Hook::ViewListener

      # Add user settings to my account
      def view_my_account(context = {})
        # Get user
        user = context[:user]

        # If present return fieldset view
        if user
          res = ''

          channels      = ChattyCrowChannel.all
          user_settings = user.chatty_crow_channel_settings

          if channels.count > 0

            res = '<fieldset class="box tabular" id="chatty_crow_notifications">'
            res << "<legend>#{l(:label_chatty_crow_channel_plural)}</legend>"

            channels.each do |channel|
              res << '<p>'
              res << "<label>#{channel.channel_type}</label>"
              res << text_field_tag("user[chatty_crow_channel_settings][#{channel.id}]", user_settings[channel.id])
              res << '</p>'
            end

            res << '</fieldset>'
          end

          res
        end
      end
    end
  end
end
