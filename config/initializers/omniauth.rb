Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Settings.oauth.app_id, Settings.oauth.app_secret
end
