require 'fog'
require 'rails'
require 'carrierwave'

CarrierWave.configure do |config|
  config.root = Rails.root.join('tmp')
  config.cache_dir = 'carrierwave'
  config.fog_credentials = {
    :provider                         => 'Google',
    :google_storage_access_key_id     => Rails.application.secrets.storage_access_key,
    :google_storage_secret_access_key => Rails.application.secrets.storage_access_secret
  }
  config.fog_directory = 'yelostore'

end