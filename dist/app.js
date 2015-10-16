var APP;

APP = angular.module('kxGrid', []);

APP.directive('kxGrid', function() {
  return {
    restrict: 'E',
    templateUrl: 'kxgrid.html',
    controller: function($scope, $element) {
      return $($element).trigger('enhance.tablesaw');
    }
  };
});
