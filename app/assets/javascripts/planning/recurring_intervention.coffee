((E, $) ->
  'use strict'

  Vue.component 'recurring-intervention',
    props: { close: '',
    validate: '',
    repete_model: '',
    repete: '',
    interval: '',
    template: Object }
    template: "
      <span class='recurring_intervention' v-if='!template.is_planting && !template.is_harvesting && template.parent_hash == null'>
        <a href='#' @click='showModal = true'>
          <i class='picto picto-repeat'></i>
        </a>
        <div id='duration-modal'>
          <transition>
            <div class='modal modal-mask' v-if='showModal'>
              <div class='modal-wrapper modal-dialog'>
                <div class='modal-content'>
                  <div class='modal-header'>
                    <h4 class='modal-title'>Répétition</h4>
                  </div>
                  <div class='modal-body'>
                    <div class='modal-form'>
                      <div class='fieldset-legend'>
                        <i class='picto picto-book'></i>
                        {{ repete_model + ' ' + template.intervention_template_name }}
                      </div>
                      <div class='control-group'>
                        <label class='control-label'>{{ repete }}</label>
                        <div class='controls'>
                          <input type='number' v-model='repeteTimes' min=0></input>
                          <span class='add-on'>Fois</span>
                        </div>
                      </div>
                      <div class='control-group'>
                        <label class='control-label'>{{ interval }}</label>
                        <div class='controls'>
                          <input type='number' v-model='repeteInterval' min=0></input>
                          <span class='add-on'>Jours</span>
                        </div>
                      </div>
                    </div>
                  </div>
                  <div class='modal-footer'>
                    <slot name='footer'></slot>
                    <button class='close-modal btn btn-default' @click.prevent='showModal = false'>
                      {{ close }}
                    </button>
                    <button class='validate-modal btn primary' @click.prevent='startDuplicate'>
                    {{ validate }}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </transition>
        </div>
      </span>
    ",
    data: ->
      showModal: false,
      repeteTimes: 0,
      repeteInterval: 0
    created: ->
    methods:
      startDuplicate: ->
        this.$emit('updated', { template: this.template,
        repeteTimes: this.repeteTimes,
        repeteInterval: this.repeteInterval })
        this.showModal = false
) ekylibre, jQuery
