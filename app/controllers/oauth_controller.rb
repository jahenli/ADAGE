class OauthController < ApplicationController
  before_filter :authenticate_user!, except: [:access_token, :user, :authorize_unity, :guest]
  skip_before_filter :verify_authenticity_token, :only => [:access_token, :user, :guest]

  def authorize
    application = Client.where(app_token: params[:client_id]).first
    access_token = current_user.access_tokens.create({client: application})
    redirect_to access_token.redirect_uri_for(params[:redirect_uri]+"?&state=#{params[:state]}")
  end

  def access_token
    application = Client.where(app_token: params[:client_id], app_secret: params[:client_secret]).first
    if application.nil?
      render :json => {:error => "Could not find application." }
      return
    end

    access_token = AccessToken.authenticate(params[:code], application.id)
    render :json => {:access_token => access_token.consumer_secret  }
  end

  def authorize_unity
    user = User.with_login(params[:email]).first
    if user != nil and user.valid_password? params[:password]
      sign_in user
    else
      redirect_to '/auth/failure', :status => 401, :message => 'incorrect player name or password'
      return
    end

    application = Client.where(app_token: params[:client_id], app_secret: params[:client_secret]).first
    if application.nil?
      render :json => {:error => "Could not find application." }
      return
    end

    access_token = current_user.access_tokens.find_or_create_by_user_id(current_user.id, {client: application})
    render :json => {:access_token => access_token.consumer_secret }

  end

  def failure
    render :text => "ERROR: #{params[:message]}"
  end

  def unity_user
    unless current_user
      redirect_to '/auth/failure', :message => 'player not found'
    end

    hash = {
      provider: 'ADAGE',
      uid: current_user.id.to_s,
      player_name: current_user.player_name,
      email: current_user.email
    }
    respond_to do |format|
      format.json { render :json => hash.to_json }
    end

  end

  def user
    access_token = AccessToken.where(consumer_secret: params[:oauth_token]).first
    user = access_token.user
    redirect_to :failure unless user
    hash = {
      provider: 'ada',
      uid: user.id.to_s,
      info: {
        email: user.email,
        player_name: user.player_name
      }
    }

    respond_to do |format|
      format.json { render :json => hash.to_json }
    end
  end

  def guest
    application = Client.where(app_token: params[:client_id], app_secret: params[:client_secret]).first

    unless application.nil?
      user =  User.create_guest
      access_token =  user.access_tokens.create({client: application})

      redirect_to :failure unless user
      hash = {
        provider: 'ada',
        uid: user.id.to_s,
        info: {
          email: user.email,
          player_name: user.player_name,
          token: access_token['consumer_secret'],
          guest: true
        }
      }

      respond_to do |format|
        format.json { render :json => hash.to_json }
      end
    else
      render :json => {:error => "Could not find application." }
      return
    end
  end

end
