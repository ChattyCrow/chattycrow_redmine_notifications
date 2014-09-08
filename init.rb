require 'redmine'
require 'rubygems'
require 'chatty_crow'

require 'redmine_chatty_crow_notifications'

Redmine::Plugin.register :redmine_chatty_crow_notifications do
  name 'Redmine ChattyCrow Notifications plugin'
  author 'NetBrick s.r.o.'
  description 'A plugin to sends Redmine Activity to channels in ChattyCrow'
  version '0.0.1'
  url 'https://github.com/netbrick/redmine_chattycrow_notifications'
  requires_redmine version_or_higher: '2.1.2'
  settings default: { host: 'https://chattycrow.com/api/v1/', timeout: 10 }, partial: 'settings/chatty_crow'
end
