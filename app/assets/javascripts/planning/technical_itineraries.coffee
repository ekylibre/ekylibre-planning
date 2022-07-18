((E, $) ->
  'use strict'

  $(document).ready ->
    Vue.use(VueResource);
    Vue.http.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

    element = document.getElementById("technical_itinerary_form")

    if element != null && element.getAttribute('data-is-initialized') != "true"

      element.setAttribute('data-is-initialized', true)

      #############
      # Variables #
      #############
      itinerary = JSON.parse(element.dataset.itinerary)
      itinerary_templates_attributes = JSON.parse(element.dataset.itineraryTemplatesAttributes)
      is_linked_to_production = JSON.parse(element.dataset.isLinkedToProduction)

      aid = 0
      itinerary_templates_attributes.forEach (attribute) ->
        attribute._destroy = null
        attribute.aid = aid
        attribute.plantingDelay = 0
        aid++

      itinerary.itinerary_templates_attributes = itinerary_templates_attributes
      itinerary.is_linked_to_production = is_linked_to_production

      last_position = _.maxBy itinerary.itinerary_templates_attributes, (t) -> t.position

      empty_template = {
        id: null,
        _destroy: null,
        position: last_position + 1,
        day_between_intervention: 0,
        intervention_template_id: null,
        procedure_name: null,
        plant_density: 4000,
        is_planting: false,
        is_harvesting: false,
        plantingDelay: 0,
        aid: aid,
        duration: 0,
        dont_divide_duration: false
        parent_hash: null
        reference_hash: null
        toUpdate: null
        maxValue: null
        test: null
      }
      ########
      # VUE #
      #######

      window.itineraryNew = new Vue {
        el: '.new_technical_itinerary, .edit_technical_itinerary',
        data:
          itinerary: itinerary,
          new_template: empty_template,
          openModal: false,
          errors: [],
          modalValue: { time: 0, dont_divide_duration: false }
          activityIsDisabled: false

        created: ->
          this.updatePlantationDelay()
          this.disableActivity()

        methods:
          getComponentData: ->
            on: {
              update: this.dragedItem
            }

          checkMove: (evt) ->
            template = this.findTemplateByPosition(Number(evt.dragged.attributes.position.value))
            template.parent_hash == null

          dragedItem: (evt) ->
            template = this.findTemplateByPosition(Number(evt.item.attributes.position.value))
            position = evt.newIndex
            orderedTemplates = this.orderedTemplates()

            if position > evt.oldIndex
              templates = _.filter(orderedTemplates, (t) ->
                  t.position <= position && t.position > template.position
              )

              templates.forEach ((t) ->
                t.position -= 1
              ), this
            else
              templates = _.filter(orderedTemplates, (t) ->
                  t.position >= position
              )

              templates.forEach ((t) ->
                position++
                t.position = position
              ), this

            template.position = evt.newIndex

            templates = _.filter(this.orderedTemplates(), (t) ->
                t.position > template.position
            )

            if typeof(templates) != 'undefined' && templates.length > 0
              nextTemplate = templates[0]
              if evt.newIndex > evt.oldIndex
                this._updateOldNextTemplateDays(template, evt.oldIndex)
              else
                this._updateOldNextTemplateDays(template, evt.oldIndex + 2)
              template.day_between_intervention = null
              if template.position > 0
                template.maxValue = nextTemplate.day_between_intervention
                template.toUpdate = true
                this._pushDraggableOption('disabled', true)
              else
                this.updatePlantationDelay()

              this.updatePosition()

          validTemplateUpdate: (template) ->
            nextTemplate = this.findTemplateByPosition(template.position + 1)
            if template.day_between_intervention != null && parseInt(template.day_between_intervention) <= parseInt(template.maxValue)
              if nextTemplate != undefined
                nextTemplate.day_between_intervention -= parseInt(template.day_between_intervention)

              template.maxValue = null
              template.toUpdate = false

              if template.reference_hash != null
                recurringTemplate = eval("this.$refs.recurring_" + template.aid)[0]
                response = { template: template, templates: this.getTemplates(), repeteTimes: recurringTemplate.repeteTimes, repeteInterval: recurringTemplate.repeteInterval }
                this.duplicateTemplate(response)

              this._pushDraggableOption('disabled', false)
              this.updatePlantationDelay()

          updateItem: (response) ->
            this.new_template.intervention_template_name = response.item.name
            this.new_template.is_planting = response.item.is_planting
            this.new_template.is_harvesting = response.item.is_harvesting
            this.new_template.procedure_name = response.item.procedure_name

          addTemplate: (event) ->
            if(this.new_template.intervention_template_id && this.new_template.intervention_template_name)
              this._manageTemplates(event)

          _manageTemplates: (event) ->
            templates = _.filter(this.getTemplates(), { '_destroy': null })

            if !this.new_template.is_planting && !this.new_template.is_harvesting
              this.setNewTemplate(true)
              this.errors = []
              return
            if this.new_template.is_planting
              if this.find_planting_template_index(templates) < 0
                this.setNewTemplate(true)
                this.errors = []
              else
                this.errors = [event.target.getAttribute('data-second-planting-template-error')]

              return
            if this.canAddHarvestingTemplate()
              this.openModal = true
              this.errors = []
            else
              this.errors = [event.target.getAttribute('data-second-harvesting-template-error')]

          updateHarvestingTemplateDuration: ->
            time = this.modalValue.time
            duration = this.modalValue.dont_divide_duration
            time = 0 if duration
            if this.canAddHarvestingTemplate()
              this.new_template.duration = time
              this.new_template.dont_divide_duration = duration
              this.setNewTemplate(true)
            else
              template = this.getTemplates()[template_index]
              time = 0 if duration
              template.duration = time
              template.dont_divide_duration = duration

            this.modalValue.time = 0
            this.modalValue.dont_divide_duration = false
            this.openModal = false

          canAddHarvestingTemplate: ->
            templates = _.filter(this.getTemplates(), { '_destroy': null })
            if this.new_template.is_harvesting && this.find_harvesting_template_index(templates) < 0
              return true
            else if _.filter(this.getTemplates(), { '_destroy': null, is_harvesting: true, procedure_name: this.new_template.procedure_name }).length > 0
              false
            else
              true

          setNewTemplate: (updatePosition)->
            this.getTemplates().push(this.new_template)
            last_position = _.maxBy _.filter(this.getTemplates(), { '_destroy': null }), (t) -> t.position
            aid++
            this.new_template = {
              id: null,
              _destroy: null,
              position: last_position + 1,
              day_between_intervention: 0,
              intervention_template_id: null,
              procedure_name: null,
              intervention_template_name: null,
              is_planting: false,
              is_harvesting: false,
              plantingDelay: 0,
              aid: aid,
              duration: 0,
              dont_divide_duration: false
              parent_hash: null
              reference_hash: null
              toUpdate: null
              maxValue: null
            }
            if updatePosition
              this.updatePosition()
            this.updatePlantationDelay()
            this.disableActivity()


          removeParentTemplate: (position) ->
            template = this.findTemplateByPosition(position)

            this.removeTemplate(position)

            if template.reference_hash != null
              templates = _.filter(this.getTemplates(), { 'parent_hash': template.reference_hash })
              templates.forEach ((t) ->
                this.removeTemplate(t.position)
              ), this


          removeTemplate: (position) ->
            template = this.findTemplateByPosition(position)

            # Edit next template to sum day_between intervention with the one who is destroy
            next_template = this.findTemplateByPosition(template.position + 1)
            if next_template != undefined && next_template.aid != template.aid
              sum = Number(next_template.day_between_intervention) + Number(template.day_between_intervention)
              next_template.day_between_intervention = sum

            if(template.id == null)
              template_number = this.findTemplateIndexByPosition(position)
              this.getTemplates().splice(template_number, 1)
            else
              template.position = null
              template._destroy = '1'

            this.disableActivity()

            this.updatePosition()

          saveItineraty: ->
            if this.itinerary.id == null
              this.$http.post('/planning/technical_itineraries', { technical_itinerary: this.itinerary }).then ((response) =>
                Turbolinks.visit('/planning/technical_itineraries/'  + response.body.id)
                ), (response) =>
                  this.errors = [response.data]
            else
              this.$http.put("/planning/technical_itineraries/#{ this.itinerary.id }", { technical_itinerary: this.itinerary }).then ((response) =>
                Turbolinks.visit("/planning/technical_itineraries/#{response.body.id}")
                ), (response) =>
                  this.errors = [response.data]

          getTemplates: ->
            this.itinerary.itinerary_templates_attributes

          findTemplate: (aid) ->
            this.getTemplates().find (template) ->
              template.aid == aid

          findTemplateByPosition: (position) ->
            this.getTemplates().find (template) ->
              template.position == position

          findTemplateIndexByPosition: (position) ->
            this.getTemplates().findIndex (x) =>
              x.position == position

          find_template_index: (index) ->
            this.getTemplates().findIndex (x) =>
              x.aid == index


          find_harvesting_template_index: (templates) ->
            templates.findIndex (x) =>
              x.is_harvesting

          find_planting_template_index: (templates) ->
            templates.findIndex (x) =>
              x.is_planting

          find_template_index_position: (position) ->
            templates = _.filter(this.getTemplates(), { '_destroy': null })
            _.findIndex templates, [
              'position'
              position
            ]

          updatePosition: ->
            number = 0
            templates = _.filter(this.orderedTemplates(), { '_destroy': null })
            templates[0].day_between_intervention = 0
            templates.forEach (t) ->
              # t.aid = number
              t.position = number
              number++

          orderedTemplates: ->
            _.orderBy(this.getTemplates(), 'position')

          updatePlantationDelay: ->
            orderedTemplates =  _.filter(this.orderedTemplates(), { '_destroy': null })
            plantationIndex = this.find_planting_template_index(orderedTemplates)
            number = 0
            plantingPass = false
            # If there is template which is plantation
            if plantationIndex >= 0
              orderedTemplates.forEach (t) ->
                unless plantingPass
                  number += Number(t.day_between_intervention)
                if t.is_planting
                  plantingPass = true
              plantingPass = false

              orderedTemplates.forEach (t) ->
                if t.is_planting
                  plantingPass = true
                  number = 0
                if plantingPass
                  unless t.is_planting
                    number += Number(t.day_between_intervention)
                    t.plantingDelay = number
                else
                  number -= Number(t.day_between_intervention)
                  t.plantingDelay = - number
            # If there is no template which is plantation
            else
              orderedTemplates.forEach (t) ->
                t.plantingDelay = '-'

          editTiming: (template) ->
            this.modalValue.time = template.duration
            this.modalValue.dont_divide_duration = template.dont_divide_duration
            this.openModal = true

          duplicateTemplate: (response) ->
            this.$http.post('/planning/technical_itineraries/duplicate_intervention', { response: response, templates: this.getTemplates() }).then ((response) =>
              this.itinerary.itinerary_templates_attributes = response.data
              maxAid = _.maxBy(@getTemplates(), (o) ->
                o.aid
              ).aid
              aid = maxAid++
              this.new_template.aid = maxAid
              this.updatePosition()
              this.updatePlantationDelay()
            )

          _updateOldNextTemplateDays: (template, oldIndex) ->
            oldNextTemplate = this.findTemplateByPosition(oldIndex)
            if oldNextTemplate != undefined
              oldNextTemplate.day_between_intervention = parseInt(template.day_between_intervention) + parseInt(oldNextTemplate.day_between_intervention)

          _findSortableElement: ->
            sortableElement = null
            childrens = this.$children

            childrens.forEach (children) ->
              Object.keys(children.$el).some((key) ->
                if key.indexOf("Sortable") != -1
                  sortableElement = children
            )

            return sortableElement


          _findSortableKey: ->
            sortableKey = null
            sortableElement = this._findSortableElement().$el

            Object.keys(sortableElement).map((key) ->
              if key.indexOf("Sortable") != -1
                sortableKey = key
              )

            return sortableKey


          _findDraggableOptions: ->
            draggableOptions = null
            sortableElement = this._findSortableElement().$el
            sortableKey = this._findSortableKey()

            if sortableKey
              draggableOptions = sortableElement[sortableKey].options

            return draggableOptions


          _pushDraggableOption: (name, value) ->
            sortableElement = this._findSortableElement().$el
            sortableKey = this._findSortableKey()

            if sortableKey
              sortableElement[sortableKey].options[name] = value

          _findDuplicateTemplates: ->
            _.filter(this.orderedTemplates(), {'is_duplicate': true})


          disableActivity: ->
            this.activityIsDisabled = true if this.itinerary.activity_id != null

            #this.$http.get('/planning/intervention_templates/interventions_have_activities', { params:  { templates: this.getTemplates()}}).then ((response) =>
            #  this.activityIsDisabled = response.data
            #), this

          isLinkedToProduction: ->
            this.itinerary.is_linked_to_production
      }


) ekylibre, jQuery
