require "saral_uploader_ext/version"
require "saral_uploader_ext/engine"
require 'active_support/core_ext/hash/indifferent_access'
require 'yaml'

module SaralUploaderExt
  def self.config
    temp_config = YAML.safe_load(ERB.new(File.read('config/saral_uploader_ext.yml')).result, aliases: true).with_indifferent_access || {}
    if Rails.env.production?
      final_config = temp_config[:production]
    elsif Rails.env.test?
      final_config = temp_config[:test]
    else
      final_config = temp_config[:development]
    end

    final_config[:gcloud_bucket] = final_config['gcloud_bucket'].to_s
    final_config[:gcloud_project_id] = final_config['gcloud_project_id'].to_s
    final_config[:gcloud_keyfile] = final_config['gcloud_keyfile'].to_s
    final_config[:signed_url_expiration_time_in_seconds] = final_config['signed_url_expiration_time_in_seconds'].to_s
    final_config
  end
end
