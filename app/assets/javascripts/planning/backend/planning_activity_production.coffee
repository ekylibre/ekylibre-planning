((E, $) ->
  'use strict'

  $(document).ready ->
    url = window.location.pathname
    return unless url.includes('backend/activity_productions')
    if url.includes('/backend/activity_productions/')
      id = url.substring(url.lastIndexOf('/') + 1);
      $.ajax
        url: '/planning/schedulings/intervention_chronologies'
        data: {
          activity_production_id: id
        }
        success: (data) =>
          if $('.activity-production-chronology').length == 0
            $('#interventions .cobble-content').before(data)


    irregularBatch = false
    irregularBatchVal = $('#activity_production_batch #activity_production_batch_attributes_irregular_batch').val()
    return if irregularBatchVal == undefined

    if JSON.parse(irregularBatchVal)
      $('#activity_production_batch .irregular-batches').show()
      $('#activity_production_batch .regular-batch *').attr("disabled", true);
      $('#activity_production_batch .regular-batch').css('opacity', 0.5)
      $('#activity_production_batch .advanced-operator').html("<i class='picto picto-minus'></i>")
      irregularBatch = true

    if $('#activity_production_batch_planting').is(':not(:checked)')
      $('.edit_batch_planting').hide()

    # Open the modal if they are an error inside it
    if $('#activity_production_batch .help-inline').length
      batch_modal = new ekylibre.modal('#activity_production_batch')
      batch_modal.getModal().modal 'show'

    # Change unroll selector when campaign change
    activityId = $('#technical-itinerary-association').data('activity')
    $(document).on "selector:change change", "#activity_production_campaign_id", (event) ->
      campaign_id = $(event.target).parent().find("input[name='activity_production[campaign_id]']").val()
      $('#activity_production_technical_itinerary_id').attr('data-selector', "/planning/technical_itineraries/unroll?scope%5Bof_activity%5D=#{activityId}&scope%5Bof_campaign%5D=#{campaign_id}")

    #hidde or show selector (date)
    $(document).on "selector:change change", "[name='activity_production[technical_itinerary_id]'], #activity_production_technical_itinerary_id", (event) ->
      if $("#activity_production_technical_itinerary_id").val().length > 0
        $('.technical_itinerary_advanced').show()
      else
        $('.technical_itinerary_advanced').hide()


    # Open the modal
    $('#activity_production_batch_planting, .edit_batch_planting').click ->
      if $('#activity_production_batch_planting').is(':checked')
        $('.edit_batch_planting').show()
        @batch_modal = new ekylibre.modal('#activity_production_batch')
        @batch_modal.getModal().modal 'show'
        $('#activity_production_batch').find('input').each (index, element) ->
          $(element).data('old_value', $(element).val())
        if JSON.parse(irregularBatchVal)
          checkValidity()
        else
          checkRegularValidity()
      else
        $('.edit_batch_planting').hide()

    # Validate modal
    validate = false
    $('#activity_production_batch .validate').click (event) ->
      validate = true

      E.stopEvent(event)
      toggleModal(event)

    # Close modal
    $(document).on 'click', '#activity_production_batch .close', (event) ->
      event.preventDefault()
      event.stopImmediatePropagation()
      have_last_value = false
      $("#activity_production_batch").find('input').each (index, input) ->
        $(input).val($(input).attr('last-value'))
        unless ['', 'false', 'true', undefined].includes($(input).attr('last-value'))
          have_last_value = true
      unless have_last_value
        $('.activity_production_batch_planting input').prop('checked', false)
        $('.edit_batch_planting').hide()
      toggleModal(event)

    # After close modal (need because we can echap or click outside to close it)
    $('#activity_production_batch').on 'hidden.bs.modal', (event) ->
      E.stopEvent(event)
      unless validate
        reSetInput()

      validate = false


    # Change type of Batch
    $('#activity_production_batch #advanced_mode').click ->
      if irregularBatch
        irregularBatch = false
        $('#activity_production_batch_attributes_irregular_batch').val(false)
        $('#activity_production_batch .irregular-batches').hide()
        $('#activity_production_batch .regular-batch *').attr("disabled", false);
        $('#activity_production_batch .regular-batch').css('opacity', 'unset')
        $('#activity_production_batch .advanced_mode').append("<i class='picto picto-plus'></i>")
        $('#activity_production_batch .advanced-operator').html("<i class='picto picto-plus'></i>")
        checkRegularValidity()
      else
        irregularBatch = true
        $('#activity_production_batch_attributes_irregular_batch').val(true)
        $('#activity_production_batch .advanced-operator').html("<i class='picto picto-minus'></i>")
        $('#activity_production_batch .irregular-batches').show()
        $('#activity_production_batch .regular-batch *').attr("disabled", true);
        $('#activity_production_batch .regular-batch').css('opacity', 0.5)
        if $('#activity_production_batch .irregular-batches .nested-fields').length == 0
          $('#activity_production_batch .irregular-batches .add_fields').trigger('click')
        checkValidity()

    $('#activity_production_batch .activity_production_batch_irregular_batches_estimated_sowing_date input').on 'change', (event) ->
      $(event.target).attr('value', $(event.target).val())


    # listen event to check validity of modal in regular batch
    $('#activity_production_batch .regular-batch').on 'keyup click change', (e) ->
      checkRegularValidity()

    # Check validity of regular batch
    checkRegularValidity = () ->
      empty = $('#activity_production_batch .regular-batch').find('input').filter(->
        @value == ''
        )
      if empty.length
        $('#activity_production_batch .validate').attr("disabled", true)
      else
        $('#activity_production_batch .validate').attr("disabled", false)

    # listen event to check validity of modal in iregular batch
    $('#activity_production_batch .irregular-batches').on 'keyup click change cocoon:after-insert cocoon:after-remove', (e) ->
      checkValidity()

    # Add the index
    $('#activity_production_batch .irregular-batches').on 'cocoon:after-insert cocoon:after-remove', (e) ->
      $('#activity_production_batch .irregular-batches .nested-fields').each (index, element) ->
        $($(element).find('.batch-number')[0]).html("#{index + 1} :")

    $('#activity_production_batch_attributes_number, #activity_production_batch_attributes_day_interval').on 'change', () ->
      $(this).val(0) if $(this).val() < 0

    # close the modal
    toggleModal = (event) ->
      batch_modal = new ekylibre.modal('#activity_production_batch')
      batch_modal.getModal().modal 'toggle'
      irregularBatchVal = $("#activity_production_batch .irregular-batch input").val()
      if irregularBatchVal != '' && JSON.parse(irregularBatchVal)
        $("#activity_production_batch .irregular-batches").show()
        $("#activity_production_batch .regular-batch *").attr("disabled", true);
        $("#activity_production_batch .regular-batch").css('opacity', 0.5)
        $("#activity_production_batch .advanced-operator").html("<i class='picto picto-minus'></i>")
        checkValidity(event)
      else
        $("#activity_production_batch .irregular-batches").hide()
        $("#activity_production_batch .regular-batch *").attr("disabled", false);
        $("#activity_production_batch .regular-batch").css('opacity', 'unset')
        $("#activity_production_batch .advanced_mode").append("<i class='picto picto-plus'></i>")
        $("#activity_production_batch .advanced-operator").html("<i class='picto picto-plus'></i>")
        checkRegularValidity(event)
      $(batch_modal.getModal().find('input')).each (index, input) ->
        val = $(input).val()
        $(input).attr('last-value', val)

    # reset the value of the modal
    reSetInput = () ->
      $('#activity_production_batch').find('input').each (index, element) ->
        $(element).val($(element).data('old_value'))

      # Remove element who didn't have datas (don't exist before)
      empty = $('#activity_production_batch .irregular-batches').find('input').filter(->
        _.isEmpty($(this).data())
        )
      empty.each (index, element) ->
        if $('.nested-fields').length > 1
          $(element).parents('.nested-fields').remove()
        else
          $(element).val('')

    # Check the validity of ireggular batch part of modal
    checkValidity = () ->
      empty = emptyInput()
      if empty.length
        $('#activity_production_batch .validate').attr("disabled", true)
      else
        $('#activity_production_batch .validate').attr("disabled", false)

    #  look for empty input in irregular batches modal part
    emptyInput = () ->
      empty = $('#activity_production_batch .irregular-batches').find('input').filter(->
        @value == '' && $(this).is(":visible")
        )
      empty


  $(document).on 'mouseup', '.activity-production-cobbles .week-proposal', (e) =>
    date = e.currentTarget.dataset.interventionProposalWeek

    $.ajax
      url: '/planning/schedulings/change_week_preference'
      data: { date: date }
      success: (response) =>
        window.location.href = location.origin + '/planning/schedulings'


  $(document).on 'click', '.activity-production-cobbles .open-modal',(e) ->
    newHref = location.origin + '/planning/schedulings'
    newHref += "?open-modal-proposal-id=#{ e.currentTarget.dataset.proposalId }"

    window.location.href = newHref


) ekylibre, jQuery
