# frozen_string_literal: true

module Planning
  module ApplicationHelper
    def can_edit?
      url_options = { controller: controller_path, action: :edit }
      authorized?(url_options)
    end
  end
end
