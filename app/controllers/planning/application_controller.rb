# frozen_string_literal: true

module Planning
  class ApplicationController < Backend::BaseController
    protect_from_forgery with: :exception

    layout 'assets_injection_layout'
    include Pickable
  end
end
