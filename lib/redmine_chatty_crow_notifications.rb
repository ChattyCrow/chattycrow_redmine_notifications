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
  # List of available services from cc plugin
  SERVICES = ChattyCrow::Request::BaseRequest.subclasses.map { |c| c.name.demodulize }

  # Send notification
  def self.send_notification(data)
    # Get Application token
    cc_config = Setting.plugin_redmine_chatty_crow_notifications

    # Configure chatty crow
    ChattyCrow.configure do |config|
      config.host            = cc_config['host']
      config.token           = cc_config['token']
    end

    # Prepare batch request
    batch = ::ChattyCrow.create_batch cc_config['token']

    # Get data

    # Compute timeout
    timeout = cc_config['timeout'].to_i
    timeout = 10 if timeout <= 0

    # Sent to all channels (skip empty contacts)
    data['channels'].each_value do |channel|
      # Skip empty
      next if channel['contacts'].empty?

      # Create notification
      if channel['type'].downcase == 'slack'
        batch.send("add_#{channel['type'].downcase}", data['slack'].merge(channel: channel['token'], contacts: channel['contacts']))
      else
        batch.send("add_#{channel['type'].downcase}", data['normal'], channel: channel['token'], contacts: channel['contacts'])
      end
    end

    # Send notification
    begin
      Timeout.timeout(timeout) do
        batch.execute!
      end
    rescue TimeoutError => e
      # Dont sent, timeout!
      Rails.logger.info '[ChattyCrow] Timeout!'
      raise e
    rescue => e
      Rails.logger.info "[ChattyCrow] Exception: #{e.message}"
      raise e
    end
  end
end
