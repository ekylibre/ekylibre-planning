# frozen_string_literal: true

require 'planning/engine'
require 'planning/ext_navigation'

module Planning
  def self.root
    Pathname.new(File.dirname(__dir__))
  end
end
