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
  class ActivityProductionsController < Backend::BaseController
    layout 'assets_injection_layout'

    before_action :set_activity_production, only: [:edit, :show, :update]

    def new
      @activity_production = ActivityProduction.new(show_permitted_params)

      params[:form_partial] = 'planning/backend/activity_productions/form'
    end

    before_action only: [:create, :update] do
      params[:form_partial] = 'planning/backend/activity_productions/form'
    end

    def edit
      params[:form_partial] = 'planning/backend/activity_productions/form'
    end

    def show
      t3e @activity_production, name: @activity_production.name

      if @activity_production.present?
        harvest_advisor = ::Interventions::Phytosanitary::PhytoHarvestAdvisor.new
        @reentry_possible = harvest_advisor.reentry_possible?(@activity_production.support, Time.zone.now)
      end

      render file: 'planning/backend/activity_productions/show'
    end

    private

    def set_activity_production
      @activity_production = ActivityProduction.find(params[:id])
    end

    def show_permitted_params
      params.permit(:activity_id, :campaign_id)
    end
  end
end
