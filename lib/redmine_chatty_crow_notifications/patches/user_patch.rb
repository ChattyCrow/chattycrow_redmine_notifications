require_dependency 'user'

module RedmineChattyCrowNotifications
  module Patches
    module UserPatch
      def self.included(base)
        base.class_eval do
          has_many :chatty_crow_user_settings
          safe_attributes 'chatty_crow_channel_settings'

          # Setter
          def chatty_crow_channel_settings=(s)
            # Get channel IDs for validation
            cc_channel_ids = ChattyCrowChannel.pluck(:id)

            # Destroy all settings
            chatty_crow_user_settings.destroy_all

            # Create settings!
            s.each do |key, value|
              # Skip value
              next if value.blank? || !cc_channel_ids.include?(key.to_i)

              # Find channel!
              ChattyCrowUserSetting.create(
                user_id: self.id,
                chatty_crow_channel_id: key,
                contact: value
              )
            end
          end

          # Getter
          def chatty_crow_channel_settings
            Hash[chatty_crow_user_settings.map { |m| [ m.chatty_crow_channel_id, m.contact ] }]
          end
        end
      end
    end
  end
end

unless User.included_modules.include?(RedmineChattyCrowNotifications::Patches::UserPatch)
  User.send(:include, RedmineChattyCrowNotifications::Patches::UserPatch)
end
