module RedmineChattyCrowNotifications
  module Jobs
    class ChattyCrowJob
      include Sidekiq::Worker
      sidekiq_options :queue => :chatty_crow

      # Send async
      def perform(issue)

      end
    end
  end
end
