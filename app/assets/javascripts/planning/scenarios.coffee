((E, $) ->
  'use strict'

  $(document).ready ->
    return unless window.location.pathname.includes('/planning/scenarios')

    $('#crop .planning-activities').each (index, activity) ->
      $(activity).find('.plot').each (index, element) ->
        if $(element).find('.parcel-name').length < 1
          $(element).prepend("<h3 class='parcel-name'>Parcelle #{index + 1}</h3>")

    if [undefined, ''].includes($('.scenario_campaign .selector-value').val())
      $('#scenario_activities-field a').addClass('disabled')

    $(document).on 'cocoon:after-insert', '#crop', (e, insertedItem) ->
      if $(insertedItem).attr('class') == 'planning-activities'
        activityInput = $(insertedItem).find('.controls input')
        actualSelector = activityInput.attr('data-selector')
        campaignId = $('.scenario_campaign .selector-value').val()
        activityInput.attr('data-selector', "/backend/activities/unroll?scope[of_campaign]=#{campaignId}")
        $('.scenario_campaign .selector-search').attr('disabled', true)

      if $(insertedItem).attr('class') == 'plot'
        actualClass = $(insertedItem.find('#activity_production_batch')).attr('class').split(' ')[0]
        arrayOfClass = $(insertedItem.find('#activity_production_batch')).attr('class').split(' ')
        currentClass = ''
        arrayOfClass.forEach (a) ->
          if a.includes('batch-modal')
            currentClass = a
        newHash = Math.random().toString(36).substr(2)
        newClass = "batch-modal-#{newHash}"
        $(insertedItem.find('#activity_production_batch')).removeClass(currentClass).addClass(newClass)
        parentActivity = insertedItem.parents('.planning-activities')
        parentActivity.find('.plot:visible').each (index, element) ->
          $(element).find('.parcel-name').remove()
          $(element).prepend("<h3 class='parcel-name'>Parcelle #{index + 1}</h3>")

    $('.scenario_campaign').on 'selector:change', ->
      $('#crop #scenario_activities-field a').removeClass('disabled')

    $('#crop').on 'cocoon:before-remove', (e, removedItem) ->
      e.stopImmediatePropagation()
      have_value = false
      removedItem.parents('.planning-activities').find('.plot').each (index, plot) ->
        unless removedItem.find('.parcel-name').text() == $(plot).find('.parcel-name').text()
          if $(plot).find('.technical-itinerary .selector-value').val().length > 0
            have_value = true

      activity = removedItem.parents('.planning-activities').find('.scenario_scenario_activities_activity .selector-search')

      unless have_value
        activity.attr('disabled', false)

      if removedItem.parents('.planning-activities').find('.plot').length <= 1
        activity.attr('disabled', false)

      if removedItem.attr("class") == 'planning-activities'
        if removedItem.find('.scenario_scenario_activities_activity .selector-search').is(':disabled')
          confirmation = confirm("Êtes-vous sûr(e) de vouloir supprimer cette activité ?")
          if confirmation == false
            e.preventDefault();

        if $('.planning-activities').length <= 1
          $('.scenario_campaign .selector input').attr('disabled', false)



    $('#crop').on 'cocoon:after-remove', (e, removedItem) ->
      $('#crop .planning-activities').each (index, activity) ->
        $(activity).find('.plot:visible').each (index, element) ->
          $(element).find('.parcel-name').remove()
          $(element).prepend("<h3 class='parcel-name'>Parcelle #{index + 1}</h3>")


    $(document).on 'selector:change', '.technical-itinerary', (event) ->
      event.stopImmediatePropagation()
      item   = $(event.currentTarget)
      if item.find('.selector-value').val().length > 0
        parentActivity = item.parents('.planning-activities')
        parentActivity.find('.scenario_scenario_activities_activity .selector-search').attr('disabled', true)

    $(document).on 'mousedown', '.technical-itinerary', (event) ->
      event.stopImmediatePropagation()
      campaign = $('.scenario_campaign .selector-value')[0].value
      item = $(event.currentTarget)
      parentActivity = item.parents('.planning-activities')
      activityValue = parentActivity.find('.scenario_scenario_activities_activity .selector-value').val()
      technicalItinerary = item.find('.selector-search')
      technicalItinerary.attr('data-selector', "/planning/technical_itineraries/unroll?scope[of_activity]=#{activityValue}")


    #Show the parcel part when the activity is choosen
    $(document).on 'selector:change', '.scenario_scenario_activities_activity', (event) ->
      $(event.currentTarget).parents('.fieldset-fields').find('.nested-plots').show()

    irregularBatch = false
    # Change type of Batch
    $(document).on 'click', '#activity_production_batch #advanced_mode', (event) ->
      event.preventDefault()
      event.stopImmediatePropagation()
      modalClass = findModalClass(event)
      if irregularBatch
        irregularBatch = false
        $(".#{ modalClass } .scenario_scenario_activities_plots_batch_irregular_batch input").val(false)
        $(".#{ modalClass } .irregular-batches").hide()
        $(".#{ modalClass } .regular-batch *").attr("disabled", false);
        $(".#{ modalClass } .regular-batch").css('opacity', 'unset')
        $(".#{ modalClass } .advanced_mode").append("<i class='picto picto-plus'></i>")
        $(".#{ modalClass } .advanced-operator").html("<i class='picto picto-plus'></i>")
        checkRegularValidity(event)
      else
        irregularBatch = true
        $(".#{ modalClass } .scenario_scenario_activities_plots_batch_irregular_batch input").val(true)
        $(".#{ modalClass } .advanced-operator").html("<i class='picto picto-minus'></i>")
        $(".#{ modalClass } .irregular-batches").show()
        $(".#{ modalClass } .regular-batch *").attr("disabled", true);
        $(".#{ modalClass } .regular-batch").css('opacity', 0.5)
        if $(".#{ modalClass } .irregular-batches .nested-fields").length == 0
          $(".#{ modalClass } .irregular-batches .add_fields").trigger('click')
        checkValidity(event)
      $(".#{modalClass} .irregular-batch input").val(irregularBatch)

    $(document).on 'change', '.batch-planting input', (event) ->
      event.stopImmediatePropagation()
      if $(event.target).is(':checked')
        modalClass = findModalClass(event)
        toggleModal(event)
        irregularBatchVal = $(".#{modalClass} .irregular-batch input").val()
        $(event.currentTarget).parents('.batch-planting-part').find('.edit_batch_planting').show()
        if JSON.parse(irregularBatchVal)
          $("#{modalClass} .irregular-batches").show()
          $("#{modalClass} .regular-batch *").attr("disabled", true);
          $("#{modalClass} .regular-batch").css('opacity', 0.5)
          $("#{modalClass} .advanced-operator").html("<i class='picto picto-minus'></i>")
          irregularBatch = true
      else
        # $('.batch-planting-part .edit_batch_planting').hide()
        $(event.currentTarget).parents('.batch-planting-part').find('.edit_batch_planting').hide()

    $(document).on 'click', '.edit_batch_planting', (event) ->
      event.stopImmediatePropagation()
      toggleModal(event)

    $(document).on 'click', '#activity_production_batch .validate', (event) ->
      validate = true
      event.preventDefault()
      event.stopImmediatePropagation()
      toggleModal(event)

    # Close modal
    $(document).on 'click', '#activity_production_batch .close', (event) ->
      event.preventDefault()
      event.stopImmediatePropagation()
      modalClass = findModalClass(event)
      have_last_value = false
      $(".#{modalClass}").find('input').each (index, input) ->
        $(input).val($(input).attr('last-value'))
        unless ['', 'false', 'true'].includes($(input).attr('last-value'))
          have_last_value = true
      unless have_last_value
        $(event.target).parents('.plot').find('.batch-planting input').prop('checked', false)
        $(event.target).parents('.plot').find('.edit_batch_planting').hide()

      toggleModal(event)

    # listen event to check validity of modal in regular batch
    $(document).on 'keyup click change', '#activity_production_batch .regular-batch', (e) ->
    # $('#activity_production_batch .regular-batch').on 'keyup click change', (e) ->
      checkRegularValidity(e)


    # listen event to check validity of modal in iregular batch
    $(document).on 'keyup click change cocoon:after-insert cocoon:after-remove', '#activity_production_batch .irregular-batches', (e) ->
      checkValidity(e)

    # Add the index
    $(document).on 'cocoon:after-insert cocoon:after-remove', '#activity_production_batch .irregular-batches', (e) ->
      e.preventDefault()
      modalClass = findModalClass(e)
      $(".#{modalClass} .irregular-batches .nested-fields").each (index, element) ->
        $($(element).find('.batch-number')[0]).html("#{index + 1} :")

    # Check validity of regular batch
    checkRegularValidity = (event) ->
      modalClass = findModalClass(event)
      empty = $(".#{modalClass} .regular-batch").find('input').filter(->
        @value == ''
        )
      if empty.length
        $('#activity_production_batch .validate').attr("disabled", true)
      else
        $('#activity_production_batch .validate').attr("disabled", false)


    # Check the validity of ireggular batch part of modal
    checkValidity = (event) ->
      empty = emptyInput(event)
      modalClass = findModalClass(event)
      if empty.length
        $(".#{modalClass} .validate").attr("disabled", true)
      else
        $(".#{modalClass} .validate").attr("disabled", false)


    #  look for empty input in irregular batches modal part
    emptyInput = (event) ->
      modalClass = findModalClass(event)
      empty = $(".#{modalClass} .irregular-batches").find('input').filter(->
        @value == '' && $(this).is(":visible")
        )
      empty

    toggleModal = (event) ->
      modalClass = findModalClass(event)
      batch_modal = new ekylibre.modal(".#{modalClass}")
      batch_modal.getModal().modal 'toggle'
      irregularBatchVal = $(".#{modalClass} .irregular-batch input").val()
      if irregularBatchVal != '' && JSON.parse(irregularBatchVal)
        $(".#{modalClass} .irregular-batches").show()
        $(".#{modalClass} .regular-batch *").attr("disabled", true);
        $(".#{modalClass} .regular-batch").css('opacity', 0.5)
        $(".#{modalClass} .advanced-operator").html("<i class='picto picto-minus'></i>")
        checkValidity(event)
      else
        $(".#{modalClass} .irregular-batches").hide()
        $(".#{modalClass} .regular-batch *").attr("disabled", false);
        $(".#{modalClass} .regular-batch").css('opacity', 'unset')
        $(".#{ modalClass } .advanced_mode").append("<i class='picto picto-plus'></i>")
        $(".#{ modalClass } .advanced-operator").html("<i class='picto picto-plus'></i>")
        checkRegularValidity(event)
      $(batch_modal.getModal().find('input')).each (index, input) ->
        val = $(input).val()
        $(input).attr('last-value', val)

    findModalClass = (event) ->
      array = $(event.target).parents('.plot').find('#activity_production_batch').attr('class').split(' ')
      currentClass = ''
      array.forEach (a) ->
        if a.includes('batch-modal')
          currentClass = a

      currentClass

) ekylibre, jQuery
