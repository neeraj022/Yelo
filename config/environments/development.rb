Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # for error notifications
  # config.middleware.use ExceptionNotification::Rack,
  # :email => {
  #   :email_prefix => "yelo development",
  #   :sender_address => %{"notifier" <yeloapp@gmail.com>},
  #   :exception_recipients => ["#{Rails.application.secrets.n_mail}"]
  # }

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
    # added for devise and sending mail

  config.action_mailer.default_url_options = { :host => 'http://www.yelo.red' }
  #change false for production
  config.action_mailer.perform_deliveries = true 
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
   :address              => "smtp.gmail.com",
   :port                 => 587,
   :enable_starttls_auto => true,
   :user_name            => Rails.application.secrets.smtp_username,
   :password             => Rails.application.secrets.smtp_password,
   :domain               => 'yelo.red',
   :authentication       => 'plain'
 }

end
