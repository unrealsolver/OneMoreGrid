APP.directive 'kxGrid', (

) ->
  restrict: 'E'
  templateUrl: 'kxgrid.html'
  controller: ($scope, $element) ->
    $($element).trigger 'enhance.tablesaw'
