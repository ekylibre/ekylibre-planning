((E, $) ->
  'use strict'

  $(document).ready ->
    Vue.use(VueResource);
    Vue.http.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

    element = document.getElementById("intervention_template_form")

    if element != null && element.getAttribute('data-is-initialized') != "true"

      element.setAttribute('data-is-initialized', true)

      template = JSON.parse(element.dataset.template)
      product_parameters_attributes = JSON.parse(element.dataset.productParametersAttributes)
      number = 0

      product_parameters_attributes.forEach (product_parameter) ->
        product_parameter._destroy = null
        product_parameter.id_number = number
        product_parameter.showList = false
        number++

      procedure_names = JSON.parse(element.dataset.procedureNames)
      template.product_parameters_attributes = product_parameters_attributes

      association_activities_attributes = JSON.parse(element.dataset.associationActivitiesAttributes)
      association_activities_attributes.forEach (association) ->
        association._destroy = null
        association.errors = null

      template.association_activities_attributes = association_activities_attributes


      interventionTemplateNew = new Vue {
        el: '.edit_intervention_template, .new_intervention_template',
        data:
          template: template,
          procedure_names: procedure_names
          activitiesList: []
          productList: []
          errors: [],
        created: ->
          if this.template.association_activities_attributes.length == 0
            this.addAssociation()
        methods:
          addParameter: (procedure) ->
            unit = null
            if procedure.is_tool_or_doer
              unit = 'unit'
            template.product_parameters_attributes.push
              id: null,
              quantity: 0,
              unit: unit
              product_name: '',
              _destroy: null,
              productList: [],
              showList: false,
              procedure: procedure
              product_nature_id: ''
              product_nature_variant_id: ''
              # number to authenticate precise element in the array
              id_number: template.product_parameters_attributes.length

          addAssociation: ->
            if this.canAddAssociation()
              template.association_activities_attributes.push
                id: null
                activity_label: ''
                activity_id: null
                _destroy: null
                showList: false
                errors: null

          canAddAssociation: ->
            associations =  _.filter(this.template.association_activities_attributes, { '_destroy': null })
            association = associations[associations.length - 1]
            if associations.length > 0
              if ["", null].includes(association.activity_id)
                false
              else
                true
            else
              true

          canRemoveAssociation: ->
            associations = _.filter(this.template.association_activities_attributes, { '_destroy': null })
            associations.length > 1

          removeAssociation: (index) ->
            association = this.template.association_activities_attributes[index]
            if(association.id == null)
              this.template.association_activities_attributes.splice(index, 1)
            else
              this.template.association_activities_attributes[index]._destroy = "1"

          updateAssociation: (response) ->
            association = this.template.association_activities_attributes[response.aid]
            association.showList = false

          listOfActivities: (index) ->
            association = this.template.association_activities_attributes[index]
            this.$http.get('/backend/activities/unroll', { params: { q: association.activity_label }}).then ((response) =>
                association = association
                this.activitiesList = response.body
                association.showList = true
              ), (response) =>
                console.log(response)

          removeParameter: (id_number) ->
            parameter = this.template.product_parameters_attributes[id_number]
            if(parameter.id == null)
              this.template.product_parameters_attributes.splice(id_number, 1)
              this.updateParameterIdNumber()
            else
              this.template.product_parameters_attributes[id_number]._destroy = "1"

          updateParameterIdNumber: ->
            number = 0
            this.template.product_parameters_attributes.forEach (p) ->
              p.id_number = number
              number++

          completeDropdown: _.debounce(((index, procedure, event) ->
            # debounce limit number of ajax call (wait user finish to write)
            product_parameter = this.attributesForProcedure(procedure)[index]
            url = '/backend/products/search_variants/search_by_expression'
            $.ajax
              url: url
              dataType: 'json'
              data:
                keep: true
                scope: procedure.expression.of_expression,
                q: product_parameter.product_name,
                max: 80,
                is_tool_or_doer: procedure.is_tool_or_doer
              success: (data) =>
                this.productList = data
                product_parameter.showList = true
              error: ->
                console.log('error')
          ), 300)

          newAddMarkInDropdown: (index, procedure, productLabel) ->
            product_parameter = this.attributesForProcedure(procedure)[index]
            inputText = product_parameter.product_name

            mark = document.createElement('mark')
            mark.innerHTML = inputText.toUpperCase()

            regex = new RegExp(inputText, 'i')
            productLabel.replace(regex, mark.outerHTML)

          updateProduct: (index, procedure, id, name) ->
            product_parameter = this.attributesForProcedure(procedure)[index]
            product_parameter.product_name = name
            product_parameter.showList = false
            if procedure.is_tool_or_doer
              product_parameter.product_nature_id = id
            else
              product_parameter.product_nature_variant_id = id

          closeChoice: (index) ->
            product_parameter = this.template.product_parameters_attributes[index]
            console.log(product_parameter.showList)
            if product_parameter.showList
              product_parameter.showList = false

          closeAllModal: ->
            this.template.product_parameters_attributes.forEach (p) ->
              p.showList = false
            this.template.association_activities_attributes.forEach (p) ->
              p.showList = false

          attributesForProcedure: (procedure) ->
            # List all the attributes for a particular procedure
            this.template.product_parameters_attributes.filter (p) -> p.procedure.type == procedure.type

          saveTemplate: ->
            if this.template.id == null
              this.$http.post('/planning/intervention_templates', { intervention_template: this.template }).then ((response) =>
                Turbolinks.visit('/planning/intervention_templates/'  + response.body.id)
              ), (response) =>
                # TODO manage errors
                console.log(response)
                this.errors = response.data
            else
              this.$http.put("/planning/intervention_templates/#{this.template.id}", { intervention_template: this.template }).then ((response) =>
                Turbolinks.visit("/planning/intervention_templates/#{response.body.id}/")
              ), (response) =>
                # TODO manage errors
                this.errors = response.data

          updateUnit: (procedure, index, event) ->
            product_parameter = this.attributesForProcedure(procedure)[index]
            product_parameter.unit = event.target.value

          canSubmitForm: ->
            associations =  _.filter(this.template.association_activities_attributes, { '_destroy': null })
            without_activity = _.filter(associations, { 'activity_id': null })
            with_activity = _.reject(associations, { 'activity_id': null })
            if with_activity.length > 0
              if without_activity.length > 0
                without_activity.forEach (a) ->
                  a.errors = ""
                true
              else
                with_activity.forEach (a) ->
                  a.errors = null
                false
            else
              with_activity.forEach (a) ->
                a.errors = null
              false
        }

      document.body.addEventListener "click", (e) ->
        interventionTemplateNew.closeAllModal()

) ekylibre, jQuery
