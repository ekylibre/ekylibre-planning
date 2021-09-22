# frozen_string_literal: true

module Ekylibre
  module Record
    class Base < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
