class Identity::PasswordResetsController < ApplicationController
  skip_before_action :authenticate

  before_action :set_user, only: :update

  def edit
    head :no_content
  end

  def create
    if @user = User.find_by(email: params[:email], verified: true)
      UserMailer.with(user: @user).password_reset.deliver_later
    else
      render json: { error: "You can't reset your password until you verify your email" }, status: :bad_request
    end
  end

  def update
    if @user.update(user_params)
      revoke_tokens; render(json: @user)
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private
    def set_user
      token = PasswordResetToken.find_signed!(params[:sid]); @user = token.user
    rescue StandardError
      render json: { error: "That password reset link is invalid" }, status: :bad_request
    end

    def user_params
      params.permit(:password, :password_confirmation)
    end

    def revoke_tokens
      @user.password_reset_tokens.delete_all
    end
end
