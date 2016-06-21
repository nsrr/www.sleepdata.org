# frozen_string_literal: true

# This controller handles easy registration/sign in of users as part of a tool
# contribution or request, or a dataset hosting request.
class RequestController < ApplicationController
  before_action :authenticate_user!, only: [:contribute_tool_description, :contribute_tool_set_description, :contribute_tool_submitted, :dataset_hosting_submitted]

  def contribute_tool_start
    @community_tool = CommunityTool.new
  end

  def contribute_tool_set_location
    @community_tool = CommunityTool.new(community_tool_params)
    @community_tool.valid?
    if @community_tool.errors[:url].present?
      render :contribute_tool_start
    else
      if current_user
        save_tool_user
      else
        render :contribute_tool_about_me
      end
    end
  end

  def contribute_tool_register_user
    @community_tool = CommunityTool.new(community_tool_params)
    unless current_user
      user = User.new(user_params)
      if user.save
        user.send_welcome_email_with_password_in_background(params[:user][:password])
        sign_in(:user, user)
      else
        @registration_errors = user.errors
        render :contribute_tool_about_me
        return
      end
    end

    save_tool_user
  end

  def contribute_tool_sign_in_user
    @community_tool = CommunityTool.new(community_tool_params)
    unless current_user
      user = User.find_by_email params[:email]
      if user && user.valid_password?(params[:password])
        sign_in(:user, user)
      else
        @sign_in_errors = []
        @sign_in = true
        render :contribute_tool_about_me
        return
      end
    end

    save_tool_user
  end

  def contribute_tool_description
    @community_tool = current_user.community_tools.where(status: 'started').find_by_id params[:id]
    redirect_to dashboard_path, alert: 'This tool does not exist.' unless @community_tool
  end

  def contribute_tool_set_description
    @community_tool = current_user.community_tools.where(status: 'started').find_by_id params[:id]
    unless @community_tool
      redirect_to dashboard_path, alert: 'This tool does not exist.'
      return
    end

    status = (params[:draft] == '1' ? 'started' : 'submitted')

    if @community_tool.update(name: params[:community_tool][:name], description: params[:community_tool][:description], status: status)
      if status == 'started'
        redirect_to dashboard_path, notice: 'Draft saved successfully.'
      else
        redirect_to contribute_tool_submitted_path
      end
    else
      render :contribute_tool_description
    end
  end

  # DAUA Submissions

  def submissions_start
  end

  def submissions_launch
    if current_user
      save_agreement_user
    else
      @agreement = Agreement.new
      render :submissions_about_me
    end
  end

  def submissions_register_user
    @agreement = Agreement.new
    unless current_user
      user = User.new(user_params)
      if user.save
        user.send_welcome_email_with_password_in_background(params[:user][:password])
        sign_in(:user, user)
      else
        @registration_errors = user.errors
        render :submissions_about_me
        return
      end
    end

    save_agreement_user
  end

  def submissions_sign_in_user
    @agreement = Agreement.new
    unless current_user
      user = User.find_by_email params[:email]
      if user && user.valid_password?(params[:password])
        sign_in(:user, user)
      else
        @sign_in_errors = []
        @sign_in = true
        render :submissions_about_me
        return
      end
    end

    save_agreement_user
  end

  def dataset_hosting_start
    @hosting_request = HostingRequest.new
  end

  def dataset_hosting_set_description
    @hosting_request = HostingRequest.new(hosting_request_params)
    @hosting_request.valid?
    if @hosting_request.errors[:description].present? || @hosting_request.errors[:institution_name].present?
      render :dataset_hosting_start
    else
      if current_user
        save_dataset_hosting_user
      else
        render :dataset_hosting_about_me
      end
    end
  end

  def dataset_hosting_register_user
    @hosting_request = HostingRequest.new(hosting_request_params)
    unless current_user
      user = User.new(user_params)
      if user.save
        user.send_welcome_email_with_password_in_background(params[:user][:password])
        sign_in(:user, user)
      else
        @registration_errors = user.errors
        render :dataset_hosting_about_me
        return
      end
    end

    save_dataset_hosting_user
  end

  def dataset_hosting_sign_in_user
    @hosting_request = HostingRequest.new(hosting_request_params)
    unless current_user
      user = User.find_by_email params[:email]
      if user && user.valid_password?(params[:password])
        sign_in(:user, user)
      else
        @sign_in_errors = []
        @sign_in = true
        render :dataset_hosting_about_me
        return
      end
    end

    save_dataset_hosting_user
  end

  def dataset_hosting_submitted
  end

  #
  # Tool Requests
  def tool_request
  end

  # Dataset Hosting

  # def dataset_hosting
  #   @hosting_request = HostingRequest.new
  # end

  # def create_hosting_request
  #   @hosting_request = HostingRequest.new(hosting_request_params)
  #   unless current_user
  #     user = User.new(user_params)
  #     if user.save
  #       UserMailer.hosting_request_account_created(params[:user][:password]).deliver!
  #       sign_in(:user, user)
  #     else
  #       @errors = user.errors
  #       render :dataset_hosting
  #       return
  #     end
  #   end

  #   @hosting_request.user_id = current_user.id
  #   if @hosting_request.save
  #     redirect_to dataset_hosting_submitted_path
  #   else
  #     render :dataset_hosting
  #   end
  # end

  private

  def community_tool_params
    params[:community_tool] ||= { blank: '1' }
    params[:community_tool][:description] = params[:community_tool][:url].to_s.strip if params[:community_tool].key?(:url)
    params.require(:community_tool).permit(:name, :description, :url)
  end

  def hosting_request_params
    params.require(:hosting_request).permit(:description, :institution_name)
  end

  def user_params
    params[:user] ||= {}
    params[:user][:password] = params[:user][:password_confirmation] = SecureRandom.hex(8)
    params.require(:user).permit(
      :first_name, :last_name, :email,
      :password, :password_confirmation)
  end

  def save_tool_user
    @community_tool.user_id = current_user.id
    if @community_tool.save
      description = @community_tool.readme_content
      if description
        description = "```\n#{description}\n```" unless @community_tool.markdown?
        @community_tool.update description: description
      end
      redirect_to contribute_tool_description_path(@community_tool)
    else
      render :contribute_tool_start
    end
  end

  def save_agreement_user
    dataset = current_user.all_viewable_datasets.find_by_param(params[:dataset])
    if dataset
      @agreement = dataset.agreements.find_by(user_id: current_user.id, status: ['resubmit', 'started'])
      @agreement = dataset.agreements.create(user_id: current_user.id) unless @agreement
    else
      @agreement = current_user.agreements.create(status: 'started')
    end
    redirect_to step_agreement_path(@agreement, step: @agreement.current_step)
  end

  def save_dataset_hosting_user
    @hosting_request.user_id = current_user.id
    if @hosting_request.save
      redirect_to dataset_hosting_submitted_path
    else
      render :dataset_hosting_start
    end
  end
end
