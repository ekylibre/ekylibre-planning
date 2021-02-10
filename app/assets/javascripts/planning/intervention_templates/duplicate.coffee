((E, $) ->
  'use strict'

  $(document).on 'ready list:page:change page:load', () ->
    $('.btn-duplication_list').off 'click', onClick

    onClick = (event) =>
      url = $(event.currentTarget).attr('href')
      $.ajax
        url: url
        dataType: 'script'
        success: (data) =>
        error: (e, response) ->
          console.log(e)
      return false


    $('.btn-duplication_list').click onClick

) ekylibre, jQuery
