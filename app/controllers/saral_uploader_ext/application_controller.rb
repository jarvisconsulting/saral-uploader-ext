module SaralUploaderExt
  class ApplicationController < ActionController::Base
    before_action :set_app_config

    def set_app_config
      @app_config = SaralUploaderExt.config
    end
  end
end
