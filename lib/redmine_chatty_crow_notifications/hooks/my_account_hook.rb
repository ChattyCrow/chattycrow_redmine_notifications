module RedmineChattyCrowNotifications
  module Hooks
    class MyAccountHook < Redmine::Hook::ViewListener
      def view_my_account(context={})
        user = context[:user]
        return "" unless user
        res = ""

        channels      = ChattyCrowChannel.all
        user_settings = user.chatty_crow_channel_settings

        if channels.count > 0

          res = "<fieldset class='box tabular' id='chatty_crow_notifications'>"
          res << "<legend>#{l(:label_chatty_crow_channel_plural)}</legend>"

          channels.each do |channel|
            res << "<p>"
            res << "<label>#{channel.channel_type}</label>"
            res << text_field_tag("user[chatty_crow_channel_settings][#{channel.id}]", user_settings[channel.id])
            res << "</p>"
          end
        end

        return res
      end
    end
  end
end
