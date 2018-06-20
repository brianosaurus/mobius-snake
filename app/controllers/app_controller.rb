class AppController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:pay]

  ROUND_PRICE = 5

  # GET /
  # User opens the application passing in the token variable.
  def index
    # User has opened application page without a token
    return render plain: "Visit https://store.mobius.network to register in the DApp Store" unless app

    # User has not granted access to his MOBI account so we can't use it for payments
    return render plain: "Visit https://store.mobius.network and open our app" unless app.authorized?

    redirect_to "/flappy_bird/index.html?token=#{token_s}"
  end

  # GET /balance
  def balance
    bal = app ? app.balance : 0
    render plain: bal
  end

  # POST /pay
  def pay
    app.pay(ROUND_PRICE)
    render plain: app.balance
  rescue Mobius::Client::Error::InsufficientFunds
    render json: { insufficient_funds: 0 }, status: :unprocessable_entity
  rescue NoMethodError
    render json: { insufficient_funds: 0 }, status: :unprocessable_entity
  end

  private

  def token_s
    session[:token] = params[:token] || session[:token]
  end

  def token
    return nil if token_s == 'undefined'
    @token ||= Mobius::Client::Auth::Jwt.new(Rails.application.secrets.app[:jwt_secret]).decode!(token_s)
  rescue Mobius::Client::Error
    nil # We treat all invalid tokens as missing
  end

  def app
    @app ||= token && Mobius::Client::App.new(
      Rails.application.secrets.app[:secret_key], # SA2VTRSZPZ5FIC.....I4QD7LBWUUIK
      token ? token.public_key : nil              # Current user
    )
  end
end
