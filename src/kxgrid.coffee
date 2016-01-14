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
      number:
        cellTplUrl: 'numberCell.html'
        headerClass: ['numeric', 'collapse']
        cellClass: ['numeric']
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
      date:
        cellTplUrl: 'dateCell.html'
        dateFormat: 'll'


    # Data Processing Chain State
    $scope.dpcState = {}

    makePriorityOrderGenerator = (priority) -> ->
      ++priority

    ## Non-pure way to two-way communication
    $scope.kxGrid.api =
      setVisibility: (field, isVisible) ->
        _.findWhere($scope.$columns, {field}).$visible = isVisible
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

      column.$visible = if column.isVisible instanceof Function
        column.isVisible()
      else
        column.isVisible

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

    class Sorter
      state: {}
      constructor: (options) ->
      process: (data) ->
        sorting = $scope.dpcState.sorting
        if sorting
          sorted = _.sortBy data, (d) ->
            d[sorting.field]
          return sorted if sorting.order == 'asc'
          return _.foldr sorted, ((m, d) -> m.concat d), []
        else
          ## Pass through
          data
      init: (update, data, columns) ->
        @update = update
      getParams: (params) ->
        $scope.dpcState.sorting
      who: 'Sorter'

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
      new Sorter()
    ].concat $scope.kxGrid.dataProcessingChain or []

    $scope.update = if $scope.kxGrid.useBackend
      ->
        params = _.extend.apply _, _.map dataProcessingChain, (d) -> d.getParams($scope.dpcState) or {}
        $scope.kxGrid.backend.provider(params).then (data) ->
          $scope.$data = data
    else
      ->
        $scope.$data = _.foldl dataProcessingChain, (m, p) ->
          p.process m, $scope.dpcState
        , $scope.kxGrid.data or []

    $scope.update()

    $scope.$watch 'kxGrid.data', (val) ->
      unless val then return
      ## Init
      _.each dataProcessingChain, (d) ->
        d.init ->
          $scope.update this
        , val or [], $scope.$columns
      $scope.update()
      setTimeout ->
        $($element.find 'table').table().data('table').refresh()

    setTimeout -> $($element).trigger 'enhance.tablesaw'
