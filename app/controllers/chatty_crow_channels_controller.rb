# encoding: utf-8
#
# This file is a part of Redmine ChattyCrow notifictation
#
# @author Strnadj <jan.strnadek@gmail.com>

# Controler for managment chatty crow channels
class ChattyCrowChannelsController < ApplicationController
  unloadable

  before_filter :find_chatty_crow_channel, only: [:destroy, :edit, :update]
  before_filter :build_chatty_crow_channel_from_params, only: [:new, :create]

  def new
  end

  def create
    if @chatty_crow_channel.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_plugin_settings
    else
      render action: :new
    end
  end

  def edit
  end

  def update
    if @chatty_crow_channel.update_attributes(params[:chatty_crow_channel])
      flash[:notice] = l(:notice_successful_create)
      redirect_to_plugin_settings
    else
      render action: :edit
    end
  end

  def destroy
    @chatty_crow_channel.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to_plugin_settings
  end

  private

  def redirect_to_plugin_settings
    redirect_to action: :plugin,
                controller: :settings,
                id: :redmine_chatty_crow_notifications,
                tab: :channels
  end

  def find_chatty_crow_channel
    @chatty_crow_channel = ChattyCrowChannel.find params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def build_chatty_crow_channel_from_params
    if params[:chatty_crow_channel]
      @chatty_crow_channel = ChattyCrowChannel.new params[:chatty_crow_channel]
    else
      @chatty_crow_channel = ChattyCrowChannel.new
    end
  end
end
