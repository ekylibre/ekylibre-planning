# frozen_string_literal: true

module Planning
  module Interventions
    class ProductPlanningController < ::Backend::BaseController
      def is_planned_intervention
        interactor = Interventions::AnotherInterventionPlannedInteractor
                     .call(permitted_params)

        if interactor.fail?
          render json: { error_message: interactor.error }
        else
          render json: { no_planned_intervention: true }
        end
      end

      private

      def permitted_params
        params.permit(:id, :procedure_name, :product_type)
      end
    end
  end
end
