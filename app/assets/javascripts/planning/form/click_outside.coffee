((E, $) ->
  'use strict'

  $(document).ready ->

    Vue.directive 'click-outside',
      bind: (el, binding, vnode) ->

        el.event = (event) ->
          # here I check that click was outside the el and his childrens
          if !(el == event.target or el.contains(event.target))
            # and if it did, call method provided in attribute value
            vnode.context[binding.expression] event
          return

        document.body.addEventListener 'click', el.event
        return
      unbind: (el) ->
        document.body.removeEventListener 'click', el.event
        return
) ekylibre, jQuery
