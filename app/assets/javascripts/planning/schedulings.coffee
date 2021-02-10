((E, $) ->
  'use strict'

  $(document).ready ->

    if document.getElementsByClassName('schedulings-calendar').length > 0 && $('.schedulings-calendar').attr('is-loaded') != "true"
      $('.schedulings-calendar').attr('is-loaded', true)
      schedulingsCalendar = new E.SchedulingsCalendar('.schedulings-calendar')
      schedulingsCalendar.addFixedHeaderEvent()

    $(document).on 'mouseup', '#create-intervention-modal .target', (e) =>
      val = $(e.target).prev('input').val() || $(e.target).val()
      unrollPath = $('#intervention_intervention_target_product_id').attr('data-selector')
      componentReg = /(unroll\?.*scope.*of_expression[^=]*)=([^&]*)(&?.*)/
      landParcelName = $('#intervention_intervention_target_product_id').attr('data-land-parcel-name')
      supportId = $('#intervention_intervention_target_product_id').attr('data-support-id')

      unrollPath = unrollPath.replace(componentReg, "$1=is+#{val}$3")

      if val == 'land_parcel'
        if unrollPath.includes('of_activity_production')
          supportId = $('#intervention_intervention_target_product_id').attr('data-support-id')
          string = unrollPath.split('of_activity_production')[0]
          scope = "with_id=#{supportId}$3"
          unrollPath = string + scope
      else if val == 'plant'
        if unrollPath.includes('with_id')
          activityProduction = $('#intervention_intervention_target_product_id').attr('data-activity-production')
          string = unrollPath.split('with_id')[0]
          scope = "of_activity_production=#{activityProduction}$3"
          unrollPath = string + scope

      $('#intervention_intervention_target_product_id').attr('data-selector', unrollPath)

      if val == 'land_parcel'
        $($("#intervention_intervention_target_product_id")[0]).selector('value', supportId)
      else
        $('#intervention_intervention_target_product_id').val(null)
        $('.intervention_intervention_target_product .selector-value').val(null)

      $('#intervention_intervention_target_product_id').trigger "selector:set"


  class SchedulingsCalendar
    LAND_PARCEL_FILTER: 'land_parcel_id'
    WORKER_FILTER: 'worker_id'
    EQUIPMENT_FILTER: 'equipment_id'
    ACTIVITY_FILTER: 'activity_id'
    PROCEDURE_NAME_FILTER: 'procedure_name'


    constructor: (selector) ->
      @selector = selector

      new Vue
        el: selector
        data:
          day: ''
          formatted_day: '',
          week: '',
          week_days: [],
          all_columns_empty: true,
          show_details: this._mustDisplayDetails(),
          interventions: {},
          intervention_proposal: {},
          new_intervention: { target: ''}
          showInterventionProposal: false
        mounted: ->
          this.loadDatas()
        methods:
          today: this._today
          previousWeek: this._previousWeek
          nextWeek: this._nextWeek
          loadDatas: this._loadDatas
          filter: this._loadDatas
          selectedValue: this._selectedValue
          initFilters: this._initFilters
          startMoveItem: this._startMoveItem
          moveItem: this._moveItem
          outItem: this._outItem
          checkIfColumnsEmpty: this._checkIfColumnsEmpty
          initializeModal: this._initializeModal
          showIntervention: this._showIntervention


    _showIntervention: (type) ->
      return true if !this.showInterventionProposal
      return true if this.showInterventionProposal && type == 'planned'
      return false if this.showInterventionProposal && type == 'proposal'

    addFixedHeaderEvent: ->
      columnsOffset = document.getElementsByClassName('schedulings-calendar-columns')[0].offsetTop

      $('#core').scroll ->
        scroll = $('#core').scrollTop()
        firstDayColumn = $('.schedulings-calendar-columns .day-column').first()
        columnWidth = firstDayColumn.width()

        if scroll >= columnsOffset
          $('.schedulings-calendar-columns .column-header').addClass('column-header--fixed')
          $('.schedulings-calendar-columns .column-header').css('top', $('#core').offset().top)
          $('.schedulings-calendar-columns .column-header').css('width', columnWidth)
        else
          $('.schedulings-calendar-columns .column-header').removeClass('column-header--fixed')
          $('.schedulings-calendar-columns .column-header').css('top', 'initial')


    _mustDisplayDetails: ->
      activityFilterValue = this._selectedValue(@ACTIVITY_FILTER)
      procedureNameFilterValue = this._selectedValue(@PROCEDURE_NAME_FILTER)

      return true if activityFilterValue != '' || procedureNameFilterValue != ''
      false


    _today: ->
      this.day = moment().format("YYYY-MM-DD")
      params = {}
      params['day'] = this.day
      this.loadDatas(params)

    _nextWeek: ->
      params = {}
      params['week'] = 'next'

      this.loadDatas(params)


    _previousWeek: ->
      params = {}
      params['week'] = 'previous'

      this.loadDatas(params)


    _startMoveItem: (event) ->
      $('.datas-column').sortable({
        connectWith: '.datas-column'
      })
      .droppable({
        out: this.outItem
      })


    _outItem: (event) ->
      params = {}

      startColumnDayIndex = event.target.getAttribute('day-index')
      startColumnLeftOffset = event.target.offsetLeft
      leftNavbarWidth = $('.inner').width()
      schedulingsColumnsWidth = $('.schedulings-calendar-columns').width()

      if event.toElement != undefined
        targettedElement = $(event.toElement)
      else
        targettedElement = $(event.originalEvent.target)

      if !targettedElement.hasClass('.intervention')
        targettedElement = targettedElement.closest('.intervention')

      return if targettedElement[0] == undefined

      boudingElement = targettedElement[0].getBoundingClientRect()

      if boudingElement.left < leftNavbarWidth
        $(targettedElement).attr('change-week', true)
        this.previousWeek()

      if boudingElement.left > schedulingsColumnsWidth
        $(targettedElement).attr('change-week', true)
        this.nextWeek()


    _moveItem: (event) ->
      $('.schedulings-calendar .intervention').each (index, intervention) ->
        if typeof InstallTrigger != 'undefined'
          $(intervention).data('can-open-modal', false)

      loadDatas = false
      loadDatas = true if $(event.item).attr('change-week') == "true"

      interventionItem = event.item
      interventionId = event.item.getAttribute('intervention-id')
      targettedItem = document.querySelectorAll(".datas-columns .intervention[intervention-id='#{ interventionId }']")[0]

      if targettedItem == undefined
        targetDayIndex = event.target.getAttribute('day-index')
      else
        targetDayIndex = targettedItem.parentElement.getAttribute('day-index')

      dayElement = document.querySelectorAll(".schedulings-calendar-columns .day-column[index='#{ targetDayIndex }']")
      day = dayElement[0].getAttribute('formatted_day')

      params = { 'day': day }
      baseUrl = "/planning/schedulings/#{ interventionId }"
      urlMethod = "/update_estimated_date"
      urlMethod = "/update_intervention_dates" if event.item.classList.contains('planned-intervention')

      buildedUrl = baseUrl + urlMethod

      this.$http.post(buildedUrl, params).then ((response) =>
        interventionsItemsToRemove = document.querySelectorAll(".datas-columns .intervention[intervention-id='#{ interventionId }'][draggable='false'][change-week='true']")

        if !loadDatas && interventionsItemsToRemove.length > 0
          $(event.target).append(event.item)

        if loadDatas
          this.loadDatas()

          interventionsItemsToRemove.forEach (interventionItem) ->
            interventionItem.remove()

          $(".datas-columns .intervention[intervention-id='#{ interventionId }']").removeAttr('change-week')
      )

      if $('#land_parcel_id').val() != ''
        $('.activity-production').remove()
        $.ajax
          url: '/planning/schedulings/intervention_chronologies'
          data: {
            land_parcel_id: $('#land_parcel_id').val()
          }
          success: (data) =>
            if $('.activity-production-chronology').length == 0
              $('.schedulings-chronology').before(data)


    _loadDatas: (params) ->
      params ||= {}
      params['day'] ||= this.formatted_day

      this.initFilters(params)

      this.$http.get('/planning/schedulings/weekly_daily_charges', { params: params }).then ((response) =>
        datas = response.body

        this.all_columns_empty = true
        this.day = datas.day
        this.formatted_day = datas.formatted_day
        this.week = datas.human_week
        this.week_days = datas.week_days

        if datas.interventions != undefined
          this.interventions = datas.interventions
          this.checkIfColumnsEmpty(this.interventions)
      )


    _checkIfColumnsEmpty: (object) ->
      keys = Object.keys(object)
      keys.map((key, index) =>
        dayDatas = object[key]

        if this.all_columns_empty == true && dayDatas.length > 0
          this.all_columns_empty = false
      )


    _initFilters: (params) =>
      params ||= {}

      params[@LAND_PARCEL_FILTER] = this._selectedValue(@LAND_PARCEL_FILTER)
      params[@WORKER_FILTER] = this._selectedValue(@WORKER_FILTER)
      params[@EQUIPMENT_FILTER] = this._selectedValue(@EQUIPMENT_FILTER)
      params[@ACTIVITY_FILTER] = this._selectedValue(@ACTIVITY_FILTER)
      params[@PROCEDURE_NAME_FILTER] = this._selectedValue(@PROCEDURE_NAME_FILTER)


    _selectedValue: (elementId) ->
      element = document.getElementById(elementId)
      selectedIndex = element.selectedIndex

      element.options[selectedIndex].value

    _initializeModal: (intervention, event) ->
      setTimeout( =>
        targettedElement = $(event.target)
        targettedElement = targettedElement.closest('.intervention') unless targettedElement.hasClass('.intervention')

        if targettedElement.data('can-open-modal')
          if targettedElement.hasClass('planned-intervention')
            url = '/backend/interventions/modal'
            params = { intervention_id: intervention.id }
          else
            url = '/planning/schedulings/new_intervention'
            params = {
              intervention_proposal_id: intervention.id,
              worker_id: this.selectedValue('worker_id'),
              equipment_id: this.selectedValue('equipment_id')
            }

          this.$http.get(url, { params: params }).then ((response) =>
            @interventionModal = new ekylibre.modal('#create-intervention-modal')
            @interventionModal.removeModalContent()
            @interventionModal.getModalContent().append(response.bodyText)
            @interventionModal.getModal().modal 'show'

            $("input[data-selector]").each ->
              $(this).selector()
            )
        else
          $('.schedulings-calendar .intervention').each (index, interventionProposal) ->
            $(interventionProposal).data('can-open-modal', true)

      , 100)

  E.SchedulingsCalendar = SchedulingsCalendar

) ekylibre, jQuery
