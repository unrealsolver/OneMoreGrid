var APP;

APP = angular.module('kxGrid', []).filter('momentDate', function() {
  return function(inputValue, formatString) {
    if (inputValue) {
      return moment(inputValue).format(formatString);
    } else {
      return '';
    }
  };
});

APP.directive('kxGrid', function($timeout) {
  return {
    restrict: 'A',
    templateUrl: 'kxgrid.html',
    scope: {
      kxGrid: '='
    },
    controller: function($scope, $element) {
      var Sorter, dataProcessingChain, externalFilters, getStartingPriority, makePriorityOrderGenerator, pog, sort, sortingProcessor;
      $scope.types = {
        "default": {
          type: 'default',
          isSortable: true,
          isVisible: true,
          isFilterable: true,
          priority: null,
          headerClass: [],
          headerTplUrl: 'defaultHeader.html',
          cellClass: ['no-overflow'],
          cellTplUrl: 'defaultCell.html'
        },
        number: {
          cellTplUrl: 'numberCell.html',
          headerClass: ['numeric', 'collapse'],
          cellClass: ['numeric'],
          priority: 1,
          precision: 0
        },
        selection: {
          cellTplUrl: 'selectionCell.html',
          headerClass: ['collapse'],
          headerTplUrl: 'selectionHeader.html',
          isSortable: false,
          isFilterable: false,
          ctrl: function($scope) {
            $scope.ctrl = {
              checked: false
            };
            return $scope.$watch('ctrl.checked', function(val) {
              return _.each($scope.$data, function(d) {
                return d.$selected = $scope.ctrl.checked;
              });
            });
          }
        },
        expand: {
          isSortable: false,
          isFilterable: false,
          cellTplUrl: 'expandCell.html',
          headerClass: ['collapse'],
          priority: 'persistent'
        },
        actions: {
          isSortable: false,
          isFilterable: false,
          cellTplUrl: 'actionsCell.html',
          cellClass: ['actions-cell'],
          headerClass: ['collapse'],
          priority: 'persistent'
        },
        date: {
          cellTplUrl: 'dateCell.html',
          dateFormat: 'll'
        }
      };
      $scope.dpcState = {};
      makePriorityOrderGenerator = function(priority) {
        return function() {
          return ++priority;
        };
      };
      $scope.kxGrid.api = {
        setVisibility: function(field, isVisible) {
          return _.findWhere($scope.$columns, {
            field: field
          }).$visible = isVisible;
        }
      };
      getStartingPriority = function(columns) {
        return +_.max($scope.kxGrid.columns, function(d) {
          return +d.priority || 0;
        }).priority || 0;
      };
      pog = makePriorityOrderGenerator(getStartingPriority($scope.kxGrid.columns));
      $scope.$columns = _.map($scope.kxGrid.columns, function(d) {
        var column, contextual;
        contextual = {};
        column = _.defaults.apply(_, [{}, d, contextual, $scope.types[d.type], $scope.types["default"]]);
        if (column.isSortable) {
          column.headerClass.push('sortable');
        }
        column.$visible = column.isVisible instanceof Function ? column.isVisible() : column.isVisible;
        return column;
      });
      externalFilters = _.chain($scope.column).where({
        isFilterable: true
      }).map(function(d) {
        return d;
      });
      sort = function(column) {
        _.each($scope.$columns, function(d) {
          if (d === column) {
            if (d.$sort === 'asc') {
              return d.$sort = 'desc';
            } else {
              return d.$sort = 'asc';
            }
          } else {
            return d.$sort = null;
          }
        });
        $scope.dpcState.sorting = {
          field: column.field,
          order: column.$sort
        };
        return $scope.update();
      };
      $scope.rowClicked = function(row) {
        return _.each($scope.$data, function(d) {
          if (d === row) {
            return d.$choosen ^= true;
          } else {
            return d.$choosen = false;
          }
        });
      };
      $scope.api = {
        sort: sort
      };
      Sorter = (function() {
        Sorter.prototype.state = {};

        function Sorter(options) {}

        Sorter.prototype.process = function(data) {
          var sorted, sorting;
          sorting = $scope.dpcState.sorting;
          if (sorting) {
            sorted = _.sortBy(data, function(d) {
              return d[sorting.field];
            });
            if (sorting.order === 'asc') {
              return sorted;
            }
            return _.foldr(sorted, (function(m, d) {
              return m.concat(d);
            }), []);
          } else {
            return data;
          }
        };

        Sorter.prototype.init = function(update, data, columns) {
          return this.update = update;
        };

        Sorter.prototype.getParams = function(params) {
          return $scope.dpcState.sorting;
        };

        Sorter.prototype.who = 'Sorter';

        return Sorter;

      })();
      sortingProcessor = function(input, ctx) {
        var sorted;
        if (ctx.sorting) {
          sorted = _.sortBy(input, function(d) {
            return d[ctx.sorting.field];
          });
          if (ctx.sorting.order === 'asc') {
            return sorted;
          }
          return _.foldr(sorted, (function(m, d) {
            return m.concat(d);
          }), []);
        } else {
          return input;
        }
      };
      dataProcessingChain = [new Sorter()].concat($scope.kxGrid.dataProcessingChain || []);
      $scope.update = $scope.kxGrid.useBackend ? function() {
        var params;
        params = _.extend.apply(_, _.map(dataProcessingChain, function(d) {
          return d.getParams($scope.dpcState) || {};
        }));
        return $scope.kxGrid.backend.provider(params).then(function(data) {
          return $scope.$data = data;
        });
      } : function() {
        return $scope.$data = _.foldl(dataProcessingChain, function(m, p) {
          return p.process(m, $scope.dpcState);
        }, $scope.kxGrid.data || []);
      };
      $scope.update();
      $scope.$watch('kxGrid.data', function(val) {
        if (!val) {
          return;
        }
        _.each(dataProcessingChain, function(d) {
          return d.init(function() {
            return $scope.update(this);
          }, val || [], $scope.$columns);
        });
        $scope.update();
        return setTimeout(function() {
          return $($element.find('table')).table().data('table').refresh();
        });
      });
      return setTimeout(function() {
        return $($element).trigger('enhance.tablesaw');
      });
    }
  };
});

APP.directive('paginator', function() {
  return {
    restrict: 'A',
    template: '<h2>{{paginator}}</h2>\n<button ng-click="next()">Next</button>',
    scope: {
      paginator: '='
    },
    controller: function($scope, $element) {
      var processor, state;
      processor = $scope.paginator;
      state = processor.state;
      return $scope.next = function() {
        if (state.page * state.size > state.total) {
          state.page = 1;
        } else {
          state.page += state.size;
        }
        return processor.update();
      };
    }
  };
});
