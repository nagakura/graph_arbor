#exports.index res req ->
# res.render 'index', {title: index}

###
express - require 'express'
app = express.createServer()

app.get '/', (req, res) ->
  res.send "Hello World"
###

exports.index = (req, res) ->
  #res.render 'index', {title: 'index'}
  res.render req.name, {title: 'index'} if req.name?

  
