((E, $) ->
  'use strict'

  $(document).ready ->
    openModalProposalId = ekylibre.locationUtils.findGetParameter("open-modal-proposal-id")

    if openModalProposalId != null
      E.SchedulingsActions.openProposalModal(openModalProposalId)

    if $('#land_parcel_id').val() != '' && $('.schedulings-calendar').length > 0
      $.ajax
        url: '/planning/schedulings/intervention_chronologies'
        data: {
          land_parcel_id: $('#land_parcel_id').val()
        }
        success: (data) =>
          if $('.activity-production-chronology').length == 0
            $('.schedulings-chronology').before(data)

    $.fn.intervention_proposal_parameters = ->
      target = $('input[name=target]:checked').val()
      parcel = $("input[name='intervention[intervention_target][product_id]']").val()
      doers = $("input[name='intervention[intervention_doer][product_id]']").map(->
          parameter_id = $(this).parents('.selector').find('.selector-search').data('productParameterId')
          product_id = $(this).val()
          { product_id: product_id, parameter_id: parameter_id}
        ).get()
      tools = $("input[name='intervention[intervention_tool][product_id]']").map(->
          parameter_id = $(this).parents('.selector').find('.selector-search').data('productParameterId')
          product_id = $(this).val()
          { product_id: product_id, parameter_id: parameter_id}
        ).get()
      inputs = $("input[name='intervention[intervention_input][product_id]']").map(->
          parameter_id = $(this).parents('.selector').find('.selector-search').data('productParameterId')
          quantity = $(this).parents('.input-part').find('#intervention_quantity_quantity').val()
          unit = $(this).parents('.input-part').find('#intervention_quantity_unit').val()
          product_id = $(this).val()
          { product_id: product_id, quantity: quantity, unit: unit, parameter_id: parameter_id }
        ).get()
      outputs = $("input[name='intervention[intervention_output][variant_id]']").map(->
          parameter_id = $(this).parents('.selector').find('.selector-search').data('productParameterId')
          quantity = $(this).parents('.output-part').find('#intervention_quantity_quantity').val()
          unit = $(this).parents('.output-part').find('#intervention_quantity_unit').val()
          variant_id = $(this).val()
          { variant_id: variant_id, quantity: quantity, unit: unit, parameter_id: parameter_id }
        ).get()
      proposalId = $('#create-intervention-modal .modal-body').attr('data-proposal-id')
      {
        proposal_id: proposalId,
        target: target,
        parcel: parcel,
        doers: doers,
        tools: tools,
        inputs: inputs,
        outputs: outputs
      }

    $(document).on 'mouseup', '#create-intervention-modal .selector-dropdown', (e) =>
      $('#create-intervention-modal .selector-choices-list:visible').each ->
        $(this).hide()

    $(document).on 'mouseup', '#create-intervention-modal #save-intervention-proposal', (e) =>
      $.ajax
        url: '/planning/schedulings/update_proposal',
        type: 'put',
        data: $.fn.intervention_proposal_parameters()
        success: (data) =>
          if data.response
            modal = new E.modal('#create-intervention-modal')
            modal.getModal().modal 'hide'

    $(document).on 'mouseup', '#create-intervention-modal #new-detailed-intervention', (e) =>
      e.stopImmediatePropagation();
      $.ajax
        url: '/planning/schedulings/update_proposal',
        type: 'put',
        data: $.fn.intervention_proposal_parameters()
        success: (data) =>
          if data.response
            params = $.fn.intervention_proposal_parameters()
            Turbolinks.visit("/planning/schedulings/new_detailed_intervention?proposal_id=#{params.proposal_id}&check_validity=false")

    $(document).on 'mouseup', '#create-intervention-modal #plan-intervention', (e) =>
      e.stopImmediatePropagation();
      $.ajax
        url: '/planning/schedulings/update_proposal',
        type: 'put',
        data: $.fn.intervention_proposal_parameters()
        success: (data) =>
          if data.response
            params = $.fn.intervention_proposal_parameters()
            $.ajax
              url: '/planning/schedulings/create_intervention'
              type: 'post',
              data: { proposal_id: params.proposal_id }
              success: (data) =>
                if data.save
                  location.reload()
                else
                  params = $.fn.intervention_proposal_parameters()
                  Turbolinks.visit("/planning/schedulings/new_detailed_intervention?proposal_id=#{params.proposal_id}&check_validity=true")
              error: (data) =>
                console.log(data)


    $(document).on 'selector:set', '#intervention_intervention_target_product_id', (e) ->
      value_id = $(e.target).parents('.selector').find('.selector-value').val()
      target = $('input[name=target]:checked').val()
      proposalId = $('#create-intervention-modal .modal-body').attr('data-proposal-id')
      $.ajax
        url: '/planning/schedulings/update_modal_time'
        data: {
          value_id: value_id,
          target: target,
          proposal_id: proposalId
        }
        success: (data) =>
          $('#estimated-working-time').text(data.time)

    $(document).on 'change', '#land_parcel_id', (e) ->
      e.stopImmediatePropagation();
      $('.activity-production').remove()
      if this.value != ''
        $.ajax
          url: '/planning/schedulings/intervention_chronologies'
          data: {
            land_parcel_id: this.value
          }
          success: (data) =>
            $('.schedulings-chronology').before(data)

    # Click on chronologies with one intervention_proposal on week
    $(document).on 'click', '.schedulings-calendar .open-modal',(e) ->
      proposalId = e.currentTarget.dataset.proposalId

      E.SchedulingsActions.openProposalModal(proposalId)


    # Click on chronologies where there are only many intervention_proposals in the week
    $(document).on 'mouseup', '.schedulings-calendar .week-proposal', (e) =>
      date = e.currentTarget.dataset.interventionProposalWeek

      $.ajax
        url: '/planning/schedulings/change_week_preference'
        data: { date: date }
        success: (response) =>
          location.reload()



  class SchedulingsActions
    openProposalModal: (proposalId) ->
      url = '/planning/schedulings/new_intervention'

      params = {
        intervention_proposal_id: proposalId
      }

      $.ajax
        url: '/planning/schedulings/new_intervention'
        data: params
        success: (response) =>
          @interventionModal = new ekylibre.modal('#create-intervention-modal')
          @interventionModal.removeModalContent()
          @interventionModal.getModalContent().append(response)
          @interventionModal.getModal().modal 'show'


  E.SchedulingsActions = new SchedulingsActions()


) ekylibre, jQuery
