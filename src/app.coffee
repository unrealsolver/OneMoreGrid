APP = angular.module 'kxGrid', []
  # Converting moment.js date/time to string
  .filter 'momentDate', ->
    (inputValue, formatString) ->
      if inputValue then moment(inputValue).format(formatString) else ''
