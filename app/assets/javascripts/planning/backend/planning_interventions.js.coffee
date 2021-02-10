((E, $) ->

  $(document).on 'change', '.nested-parameters .nested-cultivation .land-parcel-plant-selector', (event) ->
    nestedCultivationBlock = $(event.target).closest('.nested-cultivation')
    isPlannedInterventionError = $(nestedCultivationBlock).find('.is-planned-intervention-error')

    $(isPlannedInterventionError).remove() if $(isPlannedInterventionError).length > 0


  $(document).on 'selector:change', '.nested-parameters .nested-cultivation .intervention_targets_product .selector-search', (event) ->
    E.PlanningInterventionForm.isPlannedIntervention(event)


  $(document).on 'selector:change', '.nested-parameters .nested-plant .intervention_targets_product .selector-search', (event) ->
    E.PlanningInterventionForm.isPlannedIntervention(event)


  $(document).on 'selector:change', '.nested-parameters .nested-land_parcel .intervention_targets_product .selector-search', (event) ->
    E.PlanningInterventionForm.isPlannedIntervention(event)


  $(document).on 'selector:change', '.nested-parameters .nested-zone .intervention_targets_product .selector-search', (event) ->
    E.PlanningInterventionForm.isPlannedIntervention(event)


  E.PlanningInterventionForm =
    isPlannedIntervention: (event) ->
      interventionNature = $('.intervention_nature input[type="hidden"]').val()

      return if interventionNature == "request"

      procedureName = $('#intervention_procedure_name').val()
      productId = $(event.target).closest('.selector').find('.selector-value').val()
      nestedCultivationBlock = $(event.target).closest('.nested-product-parameter')
      landParcelPlantSelectorElement = $(nestedCultivationBlock).find('.land-parcel-plant-selector')
      productType = $(landParcelPlantSelectorElement).find('input[type="radio"]:checked').val()

      $.ajax
        url: "/planning/interventions/product_planning/#{ productId }/is_planned_intervention",
        data: { procedure_name: procedureName, product_type: productType }
        success: (data, status, request) ->
         unrollBlock = $(nestedCultivationBlock).find('.intervention_targets_product .controls')
         isPlannedInterventionError = $(unrollBlock).find('.is-planned-intervention-error')

         if isPlannedInterventionError.length > 0
           $(isPlannedInterventionError).remove()

         if data.error_message
           error = $("<span class='help-inline is-planned-intervention-error'>#{ data.error_message }</span>")
           $(unrollBlock).append(error)


) ekylibre, jQuery
