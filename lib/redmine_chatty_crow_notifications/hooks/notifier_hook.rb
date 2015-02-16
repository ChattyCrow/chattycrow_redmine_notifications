require 'chatty_crow'

module RedmineChattyCrowNotifications
  module Hooks
    class NotifierHook < Redmine::Hook::Listener
      def redmine_url
        @redmine_url ||= "#{Setting[:protocol]}://#{Setting[:host_name]}"
      end

      def text_message(type, context)
        issue = context[:issue]
        journal = context[:journal]

        if type == :update
          text = l(:field_chatty_crow_issue_updated) + " ##{issue.id}\n\n"
          text += l(:field_chatty_crow_issue_update_author) + ": #{journal.user.name}\n"
        else
          text = l(:field_chatty_crow_issue_created) + " ##{issue.id}\n\n"
          text += l(:field_author) + ": #{issue.author.name}\n"
        end

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
      end

      def slack_message(type, context)
        issue = context[:issue]
        journal = context[:journal]

        # Map priority to colors
        colors = {
          'Low' => '#ffffff',
          'Normal' => 'good',
          'High' => 'warning',
          'Urgent' => 'danger',
          'Immediate' => '#000000'
        }
        # Prepare payload
        payload = {
          icon: ':bulb:',
          attachments: [{
            color: colors[issue.priority.name] || 'good',
            fallback: text_message(type, context),
          }]
        }

        # Create fields
        fields = []

        if type == :update
          payload[:body] = l(:field_chatty_crow_issue_updated) + " ##{issue.id}\n\n"
          fields << { title: l(:field_chatty_crow_issue_update_author), value: journal.user.name, short: true }
        else
          payload[:body] = l(:field_chatty_crow_issue_created) + " ##{issue.id}\n\n"
          fields << { title: l(:field_author), value: issue.author.name, short: true }
        end

        # Other fields
        fields << { title: l(:field_subject), value: issue.subject, short: true }
        fields << { title: l(:field_url), value: "#{redmine_url}/issues/#{issue.id}", short: true }
        fields << { title: l(:field_project), value: issue.project.name, short: true }
        fields << { title: l(:field_tracker), value: issue.tracker.name, short: true }
        fields << { title: l(:field_priority), value: issue.priority.name, short: true }

        if issue.assigned_to
          fields << { title: l(:field_assigned_to), value: issue.assigned_to.name.to_s, short: true }
        end
        if issue.start_date
          fields << { title: l(:field_start_date), value: issue.start_date.strftime("%d.%m.%Y"), short: true }
        end
        if issue.due_date
        fields << { title: l(:field_due_date), value: issue.due_date.strftime("%d.%m.%Y"), short: true }
        end
        if issue.estimated_hours
          fields << { title: l(:field_estimated_hours), value: "#{issue.estimated_hours} #{l(:field_hours)}", short: true }
        end
        if issue.done_ratio
          fields << { title: l(:field_done_ratio), value: issue.done_ratio.to_s, short: true }
        end
        if issue.status
          fields << { title: l(:field_status), value: issue.status.name.to_s, short: true }
        end

        fields << { title: l(:field_journal_notes), value: journal.notes, short: false }

        # Return
        payload[:attachments][0][:fields] = fields

        # return payload
        payload
      end

      def controller_issues_new_after_save(context={})
        deliver :new, context
      end

      def controller_issues_edit_after_save(context={})
        deliver :update, context
      end

      private

      def deliver(type, context)
        # Get issue from context
        issue = context[:issue]

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

        # Prepare batch request
        batch = ::ChattyCrow.create_batch(cc_config['token'])

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

          # Create notification
          if channel[:type].downcase == 'slack'
            batch.send("add_#{channel[:type].downcase}", slack_message(type, context).merge(channel: channel[:token], contacts: channel[:contacts]))
          else
            batch.send("add_#{channel[:type].downcase}", text_message(type, context), { channel: channel[:token], contacts: channel[:contacts] })
          end
        end

        # Send notification
        begin
          Timeout::timeout(timeout) do
            batch.execute!
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
