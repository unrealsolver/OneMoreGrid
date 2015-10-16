var express = require('express')
var app = express()

app.use(require('connect-livereload')())
app.use(express.static('demo'))
app.use(express.static('dist'))
app.use(express.static('bower_components'))

var server = app.listen(3000, function() {
  var adress = server.address()
  console.log(
    'Server is listening on http://' + adress.address + ':' + adress.port
  )
})
