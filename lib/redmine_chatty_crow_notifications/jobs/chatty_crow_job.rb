# encoding: utf-8
#
# This file is a part of Redmine ChattyCrow notifictation
#
# @author Strnadj <jan.strnadek@gmail.com>

module RedmineChattyCrowNotifications
  module Jobs
    # Sidekiq job worker
    class ChattyCrowJob
      include Sidekiq::Worker
      sidekiq_options queue: :chatty_crow

      # Send async notification
      def perform(data)
        RedmineChattyCrowNotifications.send_notification data
      end
    end
  end
end
