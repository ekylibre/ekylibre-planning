((E, $) ->
  'use strict'

  $(document).ready ->

    $('#create-intervention-modal').on 'show.bs.modal', (e) =>
      e.stopImmediatePropagation();
      intervention = $(e.currentTarget).find('.modal-body').data().interventionId
      $.ajax
        url: '/backend/interventions/generate_buttons'
        data: { interventions: [intervention] }
        success: (data) =>
          unless data == null
            $(e.currentTarget).find('.modal-footer').append(data)

) ekylibre, jQuery
