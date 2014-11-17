# require 'elasticsearch/transport'
Elasticsearch::Client.new host: Rails.application.secrets.elasticsearch_url