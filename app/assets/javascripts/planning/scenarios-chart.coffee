((E, $) ->
  'use strict'

  time = 0
  $(document).ready (event) ->
    return unless window.location.pathname.includes('/planning/scenarios')
    if time == 0
      time++
      planChargeClass = '.plan-charge-chart'

      return if $(planChargeClass).length <= 0

      $('body #main .header').remove()
      $('body #main #content').css('height', '100%')

      if event.type == "page:load"
        existingChart = E.PlanChargeChartUtils.getChart()
        existingChart.chart.destroy() if existingChart != undefined && existingChart.chart != undefined

      planChargeChart = new PlanChargeChart()
      planChargeChart.renderChart(planChargeClass)

      $('#core').scroll E.PlanChargeChartEvents.onScroll



  class PlanChargeChart
    CHART_WIDTH: 7000
    CHART_HEIGHT: 400

    RESPONSIVE: true
    DISPLAY_LEGEND: true
    ENABLE_TOOLTIPS: false
    HOVER_ANIMATION_DURATION: 0
    MAINTAIN_ASPECT_RATIO: false
    SPACE_BETWEEN_GROUP_BARS: 20
    BAR_WIDTH: 50
    MIN_Y_AXES_VALUE: 0

    TOOLS_BAR_COLOR: '#64B5F6'
    DOERS_BAR_COLOR: '#AED581'

    HOVERED_TOOLS_BAR_COLOR: '#5FB3F3'
    HOVERED_DOERS_BAR_COLOR: '#99E65B'

    HIGHLIGHTED_TOOLS_BAR_COLOR: '#01579B'
    HIGHLIGHTED_DOERS_BAR_COLOR: '#33691E'

    BAR_VALUE_COLOR: '#212121'
    SELECTED_BAR_VALUE_COLOR: '#9E9E9E'

    Y_AXES_LABEL: 'Heures'


    constructor: ->
      @barChart = new E.VueBarChart()
      @zoom = false
      @barHighlighted = false
      @selectedBar = null
      @selectedSecondBar = null
      @hoveredElement = null

      $(".plan-charge").css('width', @CHART_WIDTH)


    renderChart: (chartSelector) ->
      return unless window.location.pathname.includes('/planning/scenarios')
      @component = new Vue
                     el: chartSelector
                     data: this._initializeDatas()
                     mounted: ->
                       this.loadWithAllActivity()
                       this.chartOptions = this.initChartOptions()
                     methods:
                       loadWithAllActivity: this._loadWithAllActivity
                       loadWithActivity: this._loadWithActivity
                       loadPreviousYear: this._loadPreviousYear
                       loadNextYear: this._loadNextYear
                       initChartOptions: this._chartOptions
                       highlightBar: this._highlightBar
                       zoomOnWeek: this._zoomOnWeek
                       loadCharges: this._loadCharges
                       selectedDropdownElement: this._selectedDropdownElement
                       unzoomOnYear: this._unzoomOnYear
                       updateChartAfterSuccess: this._updateChartAfterSuccess
                       displayDetails: this._displayDetails
                       addDetails: this._addDetails
                       addRowDetails: this._addRowDetails
                       unzoom: this._unzoom
                       updateDetails: this._updateDetails


    _initializeDatas: ->
      {
        chart: null,
        chartData: {},
        chartOptions: {},
        chartYearFilter: new Date().getFullYear(),
        zoom: false
      }


    _unzoomOnYear: =>
      return if this.component == undefined || this.component.chart == null

      @zoom = false
      @selectedBar = null
      @selectedSecondBar = null
      chart = this.component.chart

      $("##{ chart.canvas.id }").parent().css('width', @CHART_WIDTH)
      $("##{ chart.canvas.id }").parent().css('height', @CHART_HEIGHT)

      $(".plan-charge").css('width', @CHART_WIDTH)

      PlanChargeChartUtils.displayAllLegendItems()

      if !$('.plan-charge-details').hasClass('hidden')
        $('.plan-charge-details').addClass('hidden')


    _loadWithAllActivity: (unzoom = false) ->
      originalLabel = $('.plan-charge-filters .activity-dropdown').attr('data-original-label')
      $('.plan-charge-filters .activity-dropdown-label').text(originalLabel)

      chartFilters = $('.plan-charge-filters')
      previousSelectedActivity = chartFilters.find('.activity-selector li[selected="selected"]')
      previousSelectedActivity.removeAttr('selected') if previousSelectedActivity.length > 0

      chart = E.PlanChargeChartUtils.getChart()
      firstDayOfWeek = chart.data.labels[0]

      if unzoom == true || $('.plan-charge').width() == 7000
        this.unzoomOnYear()
        this.loadCharges()
      else
        this.zoomOnWeek(null, firstDayOfWeek) if $('.plan-charge').width() != 7000


    _loadWithActivity: (event) ->
      selectedElement = this.selectedDropdownElement(event)
      activity_label = selectedElement.text()

      $('.plan-charge-filters .activity-dropdown-label').text(activity_label)

      chart = E.PlanChargeChartUtils.getChart()
      firstDayOfWeek = chart.data.labels[0]

      if $('.plan-charge').width() == 7000
        this.unzoomOnYear()
        this.loadCharges()
      else
        this.zoomOnWeek(null, firstDayOfWeek) if $('.plan-charge').width() != 7000


    _unzoom: (event) ->
      selectedActivity = $('.plan-charge-filters .activity-selector li[selected="selected"]')

      this.unzoomOnYear()
      this.loadCharges()
      #if selectedActivity.length == 0
      #  this.loadWithAllActivity(true)
      #else



    _selectedDropdownElement: (event) ->
      selectedElement = $(event.target)

      chartFilters = $('.plan-charge-filters')
      previousSelectedActivity = chartFilters.find('.activity-selector li[selected="selected"]')
      previousSelectedActivity.removeAttr('selected') if previousSelectedActivity.length > 0

      if selectedElement.is('span')
        selectedElement = $(selectedElement).parent()

      selectedElement.attr('selected', 'selected')
      selectedElement


    _loadPreviousYear: ->
      previousDate = new Date(this.chartYearFilter - 1, 0, 1)
      this.chartYearFilter = previousDate.getFullYear()

      this.unzoomOnYear()
      this.loadCharges()


    _loadNextYear: ->
      nextDate = new Date(this.chartYearFilter + 1, 0, 1)
      this.chartYearFilter = nextDate.getFullYear()

      this.unzoomOnYear()
      this.loadCharges()


    _loadCharges: (datas, callback) ->
      $("#bar-chart").parent().append('<i class="picto picto-circle-o-notch picto-spin"></i>')

      datas ||= {}

      datas['year'] = this.chartYearFilter
      datas['year'] ||= $('.plan-charge-chart .plan-charge-filters .year-selector-label').text()

      chartFilters = $('.plan-charge-filters')
      selectedActivity = chartFilters.find('.activity-selector li[selected="selected"]')

      if selectedActivity.length > 0
        datas['activity_id'] = selectedActivity.find('#activity_id').val()

      datas['scenario_id'] = $('.plan-charge').data().id
      $.ajax
        url: '/planning/scenarios/period_charges'
        data: datas
        success: (data, status, request) =>
          reloadAllActivitiesButton = $('.plan-charge-chart .plan-charge-filters .reload-all-activities')

          @barChart.changeDatasetColors(this.component.chart, data.datasets) if @barChart

          if callback != undefined
            callback(data)

            if typeof this._displayDetails != "undefined"
              this._displayDetails(data, false)
            else
              this.displayDetails(data, false)

            $(reloadAllActivitiesButton).parent().removeClass('hidden')
          else
            jsonChartDatas = JSON.stringify(data)
            this.chartData = JSON.parse(jsonChartDatas)
            $(reloadAllActivitiesButton).parent().addClass('hidden')

          $("#bar-chart").parent().find('.picto.picto-circle-o-notch').remove()


    _displayDetails: (datas, ajaxify) ->
      datas['scenario_id'] = $('.plan-charge').data().id
      if ajaxify
        $("#bar-chart").parent().append('<i class="picto picto-circle-o-notch picto-spin"></i>')
        $.ajax
          url: '/planning/scenarios/period_charges'
          data: datas
          success: (data, status, request) =>
            this._updateDetails(data)
            $("#bar-chart").parent().find('.picto.picto-circle-o-notch').remove()
      else
        data = datas
        if typeof this._updateDetails != "undefined"
          this._updateDetails(data)
        else
          this.updateDetails(data)


    _updateDetails: (data) ->
      $('.plan-charge #plan-charge-details .cobble-title').text(data['title'])

      if typeof this._addDetails != "undefined"
        this._addDetails('tools', data)
        this._addDetails('doers', data)
        this._addDetails('inputs', data)
      else
        this.addDetails('tools', data)
        this.addDetails('doers', data)
        this.addDetails('inputs', data)


    _addDetails: (detailsType, data) ->
      if $('.plan-charge-details').hasClass('hidden')
        $('.plan-charge-details').removeClass('hidden')

      cobble = $('.plan-charge #plan-charge-details')
      detailsBlock = $(cobble).find(".#{ detailsType }")
      tableRows = $(detailsBlock).find('.details-table tbody')
      elements = data[detailsType]

      existingLines = $(tableRows).find('tr')
      if existingLines.length > 0
        existingLines.remove()

      if elements.length == 0
        $(detailsBlock).addClass('hidden')
        return

      if $(detailsBlock).hasClass('hidden')
        $(detailsBlock).removeClass('hidden')


      if typeof this._addRowDetails != "undefined"
        this._addRowDetails(elements, tableRows)
      else
        this.addRowDetails(elements, tableRows)


    _addRowDetails: (elements, tableRows) ->
      elements.forEach (element, index) ->
        newLine = $('<tr></tr>')
        $(newLine).append("<td>#{ element['name'] }</td>")
        $(newLine).append("<td><a href='#{ element['link']  }'>#{ element['type'] }</a></td>")
        $(newLine).append("<td>#{ element['quantity'] }</td>")
        $(newLine).append("<td>#{ element['available_quantity'] }</td>")

        $(tableRows).append(newLine)


    _chartOptions: =>
      {
        legend: {
          display: @DISPLAY_LEGEND
        },
        barValueSpacing: @SPACE_BETWEEN_GROUP_BARS,
        scales: {
          xAxes: [{
            barThickness: @BAR_WIDTH
          }],
          yAxes: [{
            ticks: {
              min: @MIN_Y_AXES_VALUE,
            }
            scaleLabel: {
              display: true,
              labelString: @Y_AXES_LABEL
            }
          }]
        },
        responsive: @RESPONSIVE,
        maintainAspectRatio: @MAINTAIN_ASPECT_RATIO,
        tooltips: {
          enabled: @ENABLE_TOOLTIPS
        },
        hover: {
          animationDuration: @HOVER_ANIMATION_DURATION
          mode: 'point'
        },
        animation: {
          onComplete: this._onAnimationComplete
        }
        onClick: this._onBarClick
      }


    _onAnimationComplete: (event) =>
      if !@zoom && event.easing != undefined && event.easing != ""
        parentComponentWidth = $('.bar-chart').width()
        scrollPosition = 0
        PlanChargeChartUtils.moveLegend(parentComponentWidth, scrollPosition)

      if this.component.chart == null
        chartFirstKey = Object.keys(Chart.instances)[0]
        this.component.chart = Chart.instances[chartFirstKey].chart

      barValueColor = @BAR_VALUE_COLOR
      @barChart.addValuesInBars(this.component.chart, barValueColor)

      return if @selectedBar == null

      barValueColor = @SELECTED_BAR_VALUE_COLOR
      @barChart.addValueInBar(this.component.chart, barValueColor, @selectedBar._datasetIndex, @selectedBar._index)
      @barChart.addValueInBar(this.component.chart, barValueColor, @selectedSecondBar._datasetIndex, @selectedSecondBar._index)


    _onBarClick: (event) =>
      clickedElement = this.component.chart.getElementAtEvent(event)[0]

      return if clickedElement == undefined

      if @zoom && this._isSameSelectedBar(clickedElement)
        @zoom = true
        data = this.component.chart.data
        firstDayOfWeek = data.labels[0]

        this._changeBarsColor(@TOOLS_BAR_COLOR, @DOERS_BAR_COLOR)

        @selectedBar = null
        @selectedSecondBar = null

        this._zoomOnWeek(clickedElement, firstDayOfWeek)
        return

      if @zoom
        @barHighlighted = true
        this._highlightBar(clickedElement)
        this._addDetailsForDay(clickedElement)
      else
        @zoom = true
        this._zoomOnWeek(clickedElement)


    _isSameSelectedBar: (element) ->
      return false if @selectedBar == null || @selectedSecondBar == null

      elementDatasetIndex = element._datasetIndex
      elementIndex = element._index

      return (element._datasetIndex == @selectedBar._datasetIndex &&
                element._index == @selectedBar._index) ||
                (element._datasetIndex == @selectedSecondBar._datasetIndex &&
                element._index == @selectedSecondBar._index)


    _highlightBar: (element) ->
      chart = this.component.chart

      if @selectedBar != null
        this._changeBarsColor(@TOOLS_BAR_COLOR, @DOERS_BAR_COLOR)

      @selectedBar = element
      @selectedSecondBar = this._getSecondBar(element._datasetIndex, element._index)

      this._changeBarsColor(@HIGHLIGHTED_TOOLS_BAR_COLOR, @HIGHLIGHTED_DOERS_BAR_COLOR)


    _changeBarsColor: (toolsBarColor, doersBarColor) ->
      this._changeBarColor(@selectedBar, toolsBarColor, doersBarColor)
      this._changeBarColor(@selectedSecondBar, toolsBarColor, doersBarColor)

      this.component.chart.render(0, true)


    _changeBarColor: (bar, toolsBarColor, doersBarColor) ->
      barDatasetIndex = bar._datasetIndex

      barColor = toolsBarColor
      barColor = doersBarColor if barDatasetIndex != 0

      @barChart.changeBarColor(this.component.chart, bar, barColor)


    _getSecondBar: (firstBardatasetIndex, firstElementIndex) ->
      secondBarDatasetIndex = 0

      if firstBardatasetIndex == 0
        secondBarDatasetIndex = 1

      secondBarDataset = this.component.chart.getDatasetMeta(secondBarDatasetIndex)
      return secondBarDataset.data[firstElementIndex]


    _zoomOnWeek: (clickedElement, firstDayOfWeek) ->
      chart = E.PlanChargeChartUtils.getChart()
      chart ||= this.component.chart

      $("##{ chart.canvas.id }").parent().css('width', '')
      $("##{ chart.canvas.id }").parent().css('height', '')

      $(".plan-charge").css('width', '')

      datas = {}

      if firstDayOfWeek != undefined
        datas['week'] = firstDayOfWeek
      else
        elementIndex = clickedElement._index
        datas['week'] = chart.data.labels[elementIndex]

      if typeof this._loadCharges != "undefined"
        this._loadCharges(datas, this._updateChartAfterSuccess)
      else
        this.loadCharges(datas, this.updateChartAfterSuccess)


    _addDetailsForDay: (clickedElement) ->
      elementIndex = clickedElement._index

      datas = {}
      datas['day'] = this.component.chart.data.labels[elementIndex]
      datas['year'] = this.chartYearFilter
      datas['year'] ||= $('.plan-charge-chart .plan-charge-filters .year-selector-label').text()

      this._displayDetails(datas, true)


    _updateChartAfterSuccess: (data) =>
      chart = E.PlanChargeChartUtils.getChart()
      chart ||= this.component.chart

      chart.data.labels = data['labels']
      chart.data.datasets[0].data = data['datasets'][0]['data']
      chart.data.datasets[1].data = data['datasets'][1]['data']

      chart.update()
      chart.resize()


  class PlanChargeChartUtils
    constructor: ->


    @getChart: ->
      chartFirstKey = Object.keys(Chart.instances)[0]
      return Chart.instances[chartFirstKey]


    @moveLegend: (elementWidth, scrollPosition) ->
      updateChart = true
      chart = PlanChargeChartUtils.getChart()
      newPosition = this.getNewElementPosition(elementWidth, scrollPosition)

      chart.legend.right = 0

      updateChart = false if newPosition == chart.legend.left
      chart.legend.left = newPosition if newPosition != chart.legend.left

      chart.render(0, true) if updateChart


    @displayAllLegendItems: ->
      chart = PlanChargeChartUtils.getChart()

      chart.legend.legendItems.forEach (legendItem, index) ->
        legendItem.hidden = false

      chart.data.datasets.forEach (dataset, index) ->
        meta = chart.controller.getDatasetMeta(index)
        meta.hidden = null

      chart.update(0)


    @getNewElementPosition: (elementWidth, scrollPosition) ->
      chartWidth = 7000
      halfOfChart = chartWidth / 2

      if scrollPosition == 0
        return - ((chartWidth - $(window).width()) / 2)

      if scrollPosition > halfOfChart
        newPosition = scrollPosition - (halfOfChart - (elementWidth / 2))
      else
        newPosition = - ((halfOfChart - (elementWidth / 2)) - scrollPosition)



  class PlanChargeChartEvents
    constructor: ->


    @onScroll: (event) ->
      elementWidth = $(event.target).width()
      scrollPosition = $(event.target).scrollLeft()

      PlanChargeChartUtils.moveLegend(elementWidth, scrollPosition) if scrollPosition != 0


  E.PlanChargeChart = PlanChargeChart
  E.PlanChargeChartUtils = PlanChargeChartUtils
  E.PlanChargeChartEvents = PlanChargeChartEvents

) ekylibre, jQuery
