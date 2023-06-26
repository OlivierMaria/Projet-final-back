class SessionsController < ApplicationController
  skip_before_action :authenticate, only: :create
  before_action :set_session, only: %i[ show destroy ]

  # Renvoie la liste des sessions de l'utilisateur actuel
  def index
    render json: Current.user.sessions.order(created_at: :desc)
  end

  # Affiche les détails d'une session
  def show
    if @session.expires_at.present? && @session.expires_at < Time.now
      render json: { error: "Session has expired" }, status: :unprocessable_entity
    else
      if @session.expires_at.present?
        @session.update(expires_at: 3.hours.from_now)
      end

      render json: @session
    end
  end
  
  # Crée une nouvelle session pour l'utilisateur
  def create
    user = User.find_by(email: params[:email])

    if user && user.authenticate(params[:password])
      active_session = user.sessions.find_by("expires_at > ?", Time.now)

      if active_session
        render json: { error: "User already has an active session" }, status: :unprocessable_entity
      else
        @session = user.sessions.create!(expires_at: 3.hours.from_now)
        token = response.set_header "token", @session.signed_id

        render json: {email: user.email, token: token, username: user.username, user_id: user.id, session_id: @session.id }, status: :created
      end
    else
      render json: { error: "That email or password is incorrect" }, status: :unauthorized
    end
  end
  
  # Détruit une session existante
  def destroy
    @session.destroy
    render json: { message: "Session successfully destroyed" }
  end
  
  private
    # Récupère la session de l'utilisateur actuel
    def set_session
      @session = Current.user.sessions.find(params[:id])
    end
end
