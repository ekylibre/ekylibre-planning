# frozen_string_literal: true

module Backend
  module PlanningInterventionsHelper
    def product_expression(target)
      target = target.decorate
      return 'is plant' if target.plant?
      return 'is land_parcel' if target.land_parcel?
    end
  end
end
