class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]

    user = User.where(provider: auth["provider"], uid: auth["uid"]).first

    if !user
      # Store auth information in a stateless manner
      cookies.signed[:auth] = JSON.generate(auth)
      redirect_to new_user_url and return
    end

    log_in(user)
  end

  def destroy
    session[:user_id] =  nil
    redirect_to root_url, flash: { success: "Signed out" }
  end
end
