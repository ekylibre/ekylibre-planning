# frozen_string_literal: true

# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Backend
  class InterventionsController < Backend::BaseController
    def create
      unless permitted_params[:participations_attributes].nil?
        participations = permitted_params[:participations_attributes]

        participations.each_pair do |key, value|
          participations[key] = JSON.parse(value)
        end

        permitted_params[:participations_attributes] = participations
      end

      @intervention = Intervention.new(permitted_params)
      url = if params[:create_and_continue]
              { action: :new, continue: true }
            elsif URI(request.referer).path == '/planning/schedulings/new_detailed_intervention'
              planning_schedulings_path
            else
              params[:redirect] || { action: :show, id: 'id'.c }
            end

      notify = params[:intervention_proposal] ? :record_x_planned : :record_x_created

      return if save_and_redirect(@intervention, url: url, notify: notify, identifier: :number)

      render(locals: { cancel_url: { action: :index }, with_continue: true })
    end
  end
end
