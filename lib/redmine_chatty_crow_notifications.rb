# Patches
ActionDispatch::Reloader.to_prepare do
  require_dependency 'redmine_chatty_crow_notifications/patches/user_patch'
end

# Hooks
require_dependency 'redmine_chatty_crow_notifications/hooks/my_account_hook'
require_dependency 'redmine_chatty_crow_notifications/hooks/notifier_hook'

# Is Sidekiq defined?
if defined?(::Sidekiq)
  require_dependency 'redmine_chatty_crow_notifications/jobs/chatty_crow_job'
end

# Redmine modul
module RedmineChattyCrowNotifications
  # List of available services!
  SERVICES = %w(Jabber Skype Sms Ios Android HipChat Slack)
end
