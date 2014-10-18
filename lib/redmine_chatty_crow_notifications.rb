# Patches
ActionDispatch::Reloader.to_prepare do
  require_dependency 'redmine_chatty_crow_notifications/patches/user_patch'
end

# Hooks
require_dependency 'redmine_chatty_crow_notifications/hooks/my_account_hook'
require_dependency 'redmine_chatty_crow_notifications/hooks/notifier_hook'

# Redmine modul
module RedmineChattyCrowNotifications
  # List of available services!
  SERVICES = %w(Jabber Skype Sms Ios Android HipChat)
end
