# frozen_string_literal: true

module Planning
  module ApplicationHelper
    def can_edit?(params)
      edit_params = params
      edit_params[:action] = :edit

      authorized?(edit_params)
    end
  end
end
