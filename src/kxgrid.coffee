APP.directive 'kxGrid', (
  $timeout
) ->
  restrict: 'A'
  templateUrl: 'kxgrid.html'
  scope:
    kxGrid: '='
  controller: ($scope, $element) ->

    $scope.types =
      default:
        type: 'default'
        isSortable: true
        isVisible: true
        isFilterable: true
        priority: null
        headerClass: []
        headerTplUrl: 'defaultHeader.html'
        cellClass: ['no-overflow']
        cellTplUrl: 'defaultCell.html'
        cellFilter: ''
      number:
        cellTplUrl: 'numberCell.html'
        headerClass: ['numeric', 'collapse']
        cellClass: ['numeric']
        cellFilter: 'number:3'
        priority: 1
        precision: 0
      selection:
        cellTplUrl: 'selectionCell.html'
        headerClass: ['collapse']
        headerTplUrl: 'selectionHeader.html'
        isSortable: false
        isFilterable: false
        ctrl: ($scope) ->
          $scope.ctrl =
            checked: false
          $scope.$watch 'ctrl.checked', (val) ->
            _.each $scope.$data, (d) -> d.$selected = $scope.ctrl.checked
      expand:
        isSortable: false
        isFilterable: false
        cellTplUrl: 'expandCell.html'
        headerClass: ['collapse']
        priority: 'persistent'
      actions:
        isSortable: false
        isFilterable: false
        cellTplUrl: 'actionsCell.html'
        cellClass: ['actions-cell']
        headerClass: ['collapse']
        priority: 'persistent'


    # Data Processing Chain State
    $scope.dpcState = {}

    makePriorityOrderGenerator = (priority) -> ->
      ++priority

    ## Non-pure way to two-way communication
    $scope.kxGrid.api =
      setVisibility: (field, isVisible) ->
        _.findWhere($scope.$columns, {field}).isVisible = isVisible
        ## TODO: Reset tablesaw

    getStartingPriority = (columns) ->
      +_.max($scope.kxGrid.columns, (d) ->
        +d.priority or 0
      ).priority || 0

    pog = makePriorityOrderGenerator getStartingPriority $scope.kxGrid.columns

    $scope.$columns = _.map $scope.kxGrid.columns, (d) ->
      ## Phase 1 (Pre)
      contextual = {}
      #unless d.priority
      #  contextual.priority = pog()

      ## Phase 2 (Main, merging all options together)
      column = _.defaults.apply _, [
        {}
        d
        contextual
        $scope.types[d.type]
        $scope.types.default
      ]

      ## Phase 3 (Post)
      if column.isSortable
        column.headerClass.push 'sortable'

      column

    externalFilters = _.chain $scope.column
      .where isFilterable: true
      .map (d) -> d

    sort = (column) ->
      _.each $scope.$columns, (d) ->
        if d == column
          if d.$sort == 'asc'
            d.$sort = 'desc'
          else
            d.$sort = 'asc'
        else
          d.$sort = null
      $scope.dpcState.sorting =
        field: column.field
        order: column.$sort
      $scope.update()

    $scope.rowClicked = (row) ->
      _.each $scope.$data, (d) ->
        if d == row
          d.$choosen ^= true
        else
          d.$choosen = false

    $scope.api =
      sort: sort

    #class Sorter
    #  state: {}
    #  constructor: (options) ->
    #  process: (data) ->
    #    if @sorting
    #      sorted = _.sortBy data, (d) ->
    #        d[@sorting.field]
    #      return sorted if @sorting.order == 'asc'
    #      return _.foldr sorted, ((m, d) -> m.concat d), []
    #    else
    #      ## Pass through
    #      data
    #  init: (cb, data, columns) ->
    #    @cb = cb
    #  getParams: ->

    #@scope.sorter = new Sorter()

    sortingProcessor = (input, ctx) ->
      if ctx.sorting
        sorted = _.sortBy input, (d) ->
          d[ctx.sorting.field]
        return sorted if ctx.sorting.order == 'asc'
        return _.foldr sorted, ((m, d) -> m.concat d), []
      else
        ## Pass through
        input

    dataProcessingChain = [
      #sortingProcessor
    ].concat $scope.kxGrid.dataProcessingChain or []

    ## Processor is optional param
    $scope.update = (processor) ->
      console.log $scope.kxGrid.data
      if processor
        console.log processor.who
      $scope.$data = _.foldl dataProcessingChain, (m, p) ->
        p.process m, $scope.dpcState
      , $scope.kxGrid.data or []

    $scope.update()

    $scope.$watch 'kxGrid.data', (val) ->
      ## Init
      _.each dataProcessingChain, (d) ->
        d.init ->
          console.log this
          $scope.update this
        , val or [], $scope.$columns
      $scope.update()
      setTimeout ->
        $($element.find 'table').table().data('table').refresh()

    setTimeout -> $($element).trigger 'enhance.tablesaw'
