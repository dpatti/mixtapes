Mixtapes::Application.config.session_store :cookie_store, {
  :key => '_mixtapes_session',
  :path => '/',
  :expire_after => 6.months,
}
