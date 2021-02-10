((E, $) ->
  'use strict'

  $(document).ready ->
    $('#duplicate_technical_itinerary').off 'click', onClick

    onClick = (event) =>
        url = $(event.currentTarget).attr('href')
        $.ajax
          url: url
          dataType: 'script'
          success: (data) =>
          error: (e, response) ->
            console.log(e)
        return false

    $('#duplicate_technical_itinerary').click onClick

    # Open the modal to choose the InterventionTemplate on the TechnicalItineraries#new view
    $('#technical_itinerary_duplication_modal').modal('show')

    $('#technical_itinerary_duplication_modal').on 'hide.bs.modal', ->
      Turbolinks.visit(document.referrer)

) ekylibre, jQuery
