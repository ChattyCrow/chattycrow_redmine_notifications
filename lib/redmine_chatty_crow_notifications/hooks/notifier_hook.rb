# encoding: utf-8
#
# This file is a part of Redmine ChattyCrow notifictation
#
# @author Strnadj <jan.strnadek@gmail.com>


require 'chatty_crow'

module RedmineChattyCrowNotifications
  # Parent of all hooks
  module Hooks

    # Notification hook from system / ticket notifications
    class NotifierHook < Redmine::Hook::Listener

      # Redmine url for links
      def redmine_url
        @redmine_url ||= "#{Setting[:protocol]}://#{Setting[:host_name]}"
      end

      # Simple text message contains important informations
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
          text += l(:field_start_date) + ": #{issue.start_date.strftime('%d.%m.%Y')}\n"
        end

        if issue.due_date
          text += l(:field_due_date) + ": #{issue.due_date.strftime('%d.%m.%Y')}\n"
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

        if journal
          text += "\n#{journal.notes}"
        end

        text
      end

      # Special slack message
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
            fallback: text_message(type, context)
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
          fields << { title: l(:field_start_date), value: issue.start_date.strftime('%d.%m.%Y'), short: true }
        end

        if issue.due_date
          fields << { title: l(:field_due_date), value: issue.due_date.strftime('%d.%m.%Y'), short: true }
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

        if journal
          fields << { title: l(:field_journal_notes), value: journal.notes, short: false }
        end

        # Return
        payload[:attachments][0][:fields] = fields

        # return payload
        payload
      end

      # Send through sidekiq?
      def sidekiq?
        defined?(::Sidekiq) && Setting.plugin_redmine_chatty_crow_notifications['sidekiq'] == '1'
      end

      # Hook after save issue
      def controller_issues_new_after_save(context = {})
        deliver :new, context
      end

      # Hook after edit issue
      def controller_issues_edit_after_save(context = {})
        deliver :update, context
      end

      private

      # Prepare notifications
      def deliver(type, context)
        # Get message data, this hash is serialized into sidekiq
        # It needs to be a hash
        data = {
          'slack' => slack_message(type, context),
          'normal' => text_message(type, context),
          'channels' => {}
        }

        # Get channels
        ChattyCrowChannel.active.each do |channel|
          data['channels'][channel.id] = {
            'contacts' => [],
            'token' => channel.channel_token,
            'type' => channel.channel_type
          }
        end

        # Get notification list users!
        send = false

        # Iterate over users
        User.active.includes(:chatty_crow_user_settings).each do |user|
          # Skip users dont care about issue changes
          next unless user.notify_about?(context[:issue])

          # Find specific channels
          user.chatty_crow_user_settings.each do |user_setting|
            if user_setting.contact.present? && data['channels'][user_setting.chatty_crow_channel_id]
              data['channels'][user_setting.chatty_crow_channel_id]['contacts'] << user_setting.contact
              send = true
            end
          end
        end

        # If sidekiq is available and allowed use it!
        if !send # Dont send message (contacts are empty)
          true
        elsif sidekiq?
          RedmineChattyCrowNotifications::Jobs::ChattyCrowJob.perform_async data
        else
          RedmineChattyCrowNotifications.send_notification data
        end
      end
    end
  end
end
