# frozen_string_literal: true

module SaralUploaderExt
  class CustomError < StandardError
    attr_reader :description
    def initialize(message, description)
      @description = description
      super(message)
    end
  end
end