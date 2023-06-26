class Identity::EmailsController < ApplicationController
  before_action :set_user

  # Met à jour l'adresse e-mail de l'utilisateur
  def update
    if !@user.authenticate(params[:current_password])
      render json: { error: "The password you entered is incorrect" }, status: :bad_request
    elsif @user.update(email: params[:email])
      render_show # Appelle la méthode pour afficher les détails de l'utilisateur
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private
    # Récupère l'utilisateur actuel
    def set_user
      @user = Current.user
    end

    # Rendu de la réponse pour afficher les détails de l'utilisateur
    def render_show
      if @user.email_previously_changed?
        resend_email_verification 
        render(json: @user) 
      else
        render json: @user 
      end
    end

    # Renvoie l'e-mail de vérification à l'utilisateur
    def resend_email_verification
      UserMailer.with(user: @user).email_verification.deliver_later
    end
end
