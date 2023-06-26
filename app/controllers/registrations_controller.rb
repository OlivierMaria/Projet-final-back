class RegistrationsController < ApplicationController
  before_action :authenticate, except: :create

  # Crée un nouvel utilisateur
  def create
    @user = User.new(user_params)

    if @user.save
      @session = @user.sessions.create!(expires_at: 3.hours.from_now)
      token = response.set_header "token", @session.signed_id
      send_email_verification
      render json: {token: token, username: @user.username, user_id: @user.id, session_id: @session.id, user_mail: user.email }, status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

    # Met à jour les informations de l'utilisateur actuel
    def update
      if Current.user.update(user_params_update)
        render json: Current.user
      else
        render json: Current.user.errors, status: :unprocessable_entity
      end
    end

  # Détruit l'utilisateur actuel
  def destroy
    if Current.user.destroy
      render json: { message: "User successfully destroyed" }
    else
      render json: { error: "Failed to destroy user" }, status: :unprocessable_entity
    end
  end

  private
    # Définit les paramètres acceptés pour la modification de l'utilisateur actuel 
    def user_params_update
      params.permit(:username, :email)
    end
    # Définit les paramètres acceptés pour la création d'un utilisateur
    def user_params
      params.permit(:username, :email, :password, :password_confirmation)
    end
 
    # Envoie l'e-mail de vérification à l'utilisateur
    def send_email_verification
      UserMailer.with(user: @user).email_verification.deliver_later
    end
end
