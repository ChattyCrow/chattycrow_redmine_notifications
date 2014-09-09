require 'chatty_crow'

module RedmineChattyCrowNotifications
  module Hooks
    class NotifierHook < Redmine::Hook::Listener
      def controller_issues_new_after_save(context={})
        redmine_url = "#{Setting[:protocol]}://#{Setting[:host_name]}"
        issue = context[:issue]

        text = l(:field_chatty_crow_issue_created) + " ##{issue.id}\n\n"
        text += l(:field_author) + ": #{issue.author.name}\n"
        text += l(:field_subject) + ": #{issue.subject}\n"
        text += l(:field_url) + ": #{redmine_url}/issues/#{issue.id}\n"
        text += l(:field_project) + ": #{issue.project}\n"
        text += l(:field_tracker) + ": #{issue.tracker.name}\n"
        text += l(:field_priority) + ": #{issue.priority.name}\n"
        if issue.assigned_to
          text += l(:field_assigned_to) + ": #{issue.assigned_to.name}\n"
        end
        if issue.start_date
          text += l(:field_start_date) + ": #{issue.start_date.strftime("%d.%m.%Y")}\n"
        end
        if issue.due_date
          text += l(:field_due_date) + ": #{issue.due_date.strftime("%d.%m.%Y")}\n"
        end
        if issue.estimated_hours
          text += l(:field_estimated_hours) + ": #{issue.estimated_hours} " + l(:field_hours) + "\n"
        end
        if issue.done_ratio
          text += l(:field_done_ratio) + ": #{issue.done_ratio}%\n"
        end
        if issue.status
          text += l(:field_status) + ": #{issue.status.name}\n"
        end
        text += "\n#{issue.description}"

        deliver text, issue
      end

      def controller_issues_edit_after_save(context={})
        redmine_url = "#{Setting[:protocol]}://#{Setting[:host_name]}"
        issue = context[:issue]
        journal = context[:journal]

        text = l(:field_chatty_crow_issue_updated) + " ##{issue.id}\n\n"
        text += l(:field_chatty_crow_issue_update_author) + ": #{journal.user.name}\n"
        text += l(:field_subject) + ": #{issue.subject}\n"
        text += l(:field_url) + ": #{redmine_url}/issues/#{issue.id}\n"
        text += l(:field_project) + ": #{issue.project}\n"
        text += l(:field_tracker) + ": #{issue.tracker.name}\n"
        text += l(:field_priority) + ": #{issue.priority.name}\n"
        if issue.assigned_to
          text += l(:field_assigned_to) + ": #{issue.assigned_to.name}\n"
        end
        if issue.start_date
          text += l(:field_start_date) + ": #{issue.start_date.strftime("%d.%m.%Y")}\n"
        end
        if issue.due_date
          text += l(:field_due_date) + ": #{issue.due_date.strftime("%d.%m.%Y")}\n"
        end
        if issue.estimated_hours
          text += l(:field_estimated_hours) + ": #{issue.estimated_hours} " + l(:field_hours) + "\n"
        end
        if issue.done_ratio
          text += l(:field_done_ratio) + ": #{issue.done_ratio}%\n"
        end
        if issue.status
          text += l(:field_status) + ": #{issue.status.name}\n"
        end
        text += "\n#{journal.notes}"

        deliver text, issue
      end

      private

      def deliver(message, issue)
        # Get Application token
        cc_config = Setting.plugin_redmine_chatty_crow_notifications

        # Configure chatty crow
        ChattyCrow.configure do |config|
          config.host            = cc_config['host']
          config.token           = cc_config['token']
        end

        # Get channels
        channels = {}
        ChattyCrowChannel.active.each do |channel|
          channels[channel.id] = {
            contacts: [],
            token: channel.channel_token,
            type: channel.channel_type
          }
        end

        # Get notification list!
        User.active.includes(:chatty_crow_user_settings).each do |user|
          # Skip users dont care about issue changes
          next if !user.notify_about?(issue)

          # Find specific channels
          user.chatty_crow_user_settings.each do |user_setting|
            channels[user_setting.chatty_crow_channel_id][:contacts] << user_setting.contact if user_setting.contact
          end
        end

        # Get timeout
        timeout = cc_config['timeout'].to_i
        timeout = 10 if timeout <= 0

        # Sent to all channels (skip empty contacts)
        channels.each_value do |channel|
          # Skip empty
          next if channel[:contacts].empty?

          # Send notification
          begin
            # Get send type
            send_type = "send_#{channel[:type].downcase}"

            Timeout::timeout(timeout) do
              # If android message has to be in hash
              if send_type == 'send_android'
                ChattyCrow.send(send_type, alert: message, channel: channel[:token], contacts: channel[:contacts])
              else
                ChattyCrow.send(send_type, message, channel: channel[:token], contacts: channel[:contacts])
              end
            end
          rescue TimeoutError
            # Dont sent, timeout!
            Rails.logger.info "[ChattyCrow] Timeout!"
          rescue Exception => e
            Rails.logger.info "[ChattyCrow] Exception: #{e.message}"
          end
        end
      end
    end
  end
end
