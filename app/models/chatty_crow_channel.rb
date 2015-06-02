# encoding: utf-8
#
# This file is a part of Redmine ChattyCrow notifictation
#
# @author Strnadj <jan.strnadek@gmail.com>

# Usable channel in redmine
class ChattyCrowChannel < ActiveRecord::Base
  unloadable
  validates_presence_of :channel_type, :channel_token
  scope :active, lambda { where(active: true) }
  has_many :chatty_crow_user_settings, dependent: :delete_all
end
