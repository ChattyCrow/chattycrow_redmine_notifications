# encoding: utf-8
#
# This file is a part of Redmine ChattyCrow notifictation
#
# @author Strnadj <jan.strnadek@gmail.com>

require File.expand_path('../../test_helper', __FILE__)
require 'fakeweb'

class SendNotificationTest < ActionController::TestCase
  tests ::IssuesController

  fixtures :projects, :versions, :users, :roles, :members,
           :member_roles, :issues, :journals, :journal_details,
           :trackers, :projects_trackers, :issue_statuses,
           :enabled_modules, :enumerations, :boards, :messages,
           :attachments, :custom_fields, :custom_values, :time_entries

  def setup
    # Set user & default language
    @request.session[:user_id] = 1
    Setting.default_language = 'en'

    # Create channel
    @channel = ChattyCrowChannel.create(
      channel_type: :hipchat,
      channel_token: 'abc1234',
      active: true
    )

    # Settings for plugin override!
    set = Setting.where(name: 'plugin_redmine_chatty_crow_notifications').first_or_create
    set.value = {"host"=> CHATTY_CROW_API_URL, "token"=>CHATTY_CROW_TOKEN, "timeout"=>"30"}
    set.save!
  end

  def host
    Setting.plugin_redmine_chatty_crow_notifications['host'] + 'batch'
  end

  def mock_notification
    body = {
      channels: [
        {
          channel: 'abc1234',
          status: 'PERROR',
          msg: '1 of 1 created',
          success: 1,
          total: 1,
          message_id: 1
        },
      ]
    }

    FakeWeb.register_uri :post, host, body: body.to_json, status: %w(200 OK)
  end

  def clear_http_mocks
    FakeWeb.clean_registry
  end

  def last_request
    FakeWeb.last_request
  end

  def last_headers
    ret = {}
    last_request.each_header do |key, value|
      ret[key] = value
    end
    ret
  end

  def test_send_notification
    # Create users subscription
    ChattyCrowUserSetting.create(
      user_id: 2,
      chatty_crow_channel_id: @channel.id,
      contact: 'franta'
    )

    # Mock ChattyCrow API
    mock_notification

    # Create a new issue with watchers! (its part of code from issue controller test)
    post :create, :project_id => 1,
                  :issue => {:tracker_id => 1,
                             :subject => 'This is a new issue with watchers',
                             :description => 'This is the description',
                             :priority_id => 5,
                             :watcher_user_ids => ['2', '3']}

    # Test chatty crow api
    assert_equal last_headers['token'], CHATTY_CROW_TOKEN

    # Remove mock
    clear_http_mocks
  end

  def test_not_send_notification
    # Create users subscription
    ChattyCrowUserSetting.where(user_id: 2).destroy_all

    # Mock ChattyCrow API
    mock_notification

    # Create a new issue with watchers! (its part of code from issue controller test)
    post :create, :project_id => 1,
                  :issue => {:tracker_id => 1,
                             :subject => 'This is a new issue with watchers',
                             :description => 'This is the description',
                             :priority_id => 5,
                             :watcher_user_ids => ['2', '3']}

    # Test chatty crow api
    assert_nil last_request

    # Remove mock
    clear_http_mocks
  end

end
