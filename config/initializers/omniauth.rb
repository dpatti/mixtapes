OmniAuth.config.full_host = "https://mixtapes.dpatti.com" if Rails.env.production?

# OmniAuth 2.0 disables GET requests to the request phase (/auth/:provider) by
# default. This app links to it with plain GET links, so re-enable GET.
OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, Settings.oauth.app_id, Settings.oauth.app_secret
end
