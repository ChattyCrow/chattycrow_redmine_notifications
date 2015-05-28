# encoding: utf-8
#
# This file is a part of Redmine ChattyCrow notifictation
#
# @author Strnadj <jan.strnadek@gmail.com>

require File.expand_path('../../test_helper', __FILE__)

class UserSettingsPageTest < ActionController::TestCase
  tests ::MyController

  fixtures :projects, :versions, :users, :roles, :members,
           :member_roles, :issues, :journals, :journal_details,
           :trackers, :projects_trackers, :issue_statuses,
           :enabled_modules, :enumerations, :boards, :messages,
           :attachments, :custom_fields, :custom_values, :time_entries

  def setup
    # Set user & default language
    @request.session[:user_id] = 2
    Setting.default_language = 'en'
  end

  def test_empty_user_settings
    get :account
    assert_response :success
    assert_select '#chatty_crow_notifications', 0
  end

  def test_chatty_crow_user_settings
    ChattyCrowChannel.create(
      channel_type: :hipchat,
      channel_token: 'abc1234',
      active: true
    )
    get :account
    assert_response :success
    assert_select '#chatty_crow_notifications' do
      assert_select 'input', 1
    end
  end

end
