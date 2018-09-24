express = require 'express'
multer = require 'multer'
upload = multer(dest:'uploads/')
PouchDB = require 'pouchdb'
PouchDB.plugin(require('pouchdb-load'))
admZip = require 'adm-zip'
fs = require 'fs'
glob = require 'glob'
bodyParser = require 'body-parser'
_ = require 'underscore'

app = express()

app.use bodyParser.urlencoded
  limit: '50mb'

app.use (req, res, next) ->
  res.header("Access-Control-Allow-Origin", "*")
  res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
  next()

app.get '/', (req,res) ->
  res.send "
    <html>
      Upload zipped backup file created by clicking 'Save Backup' on the tablet.
      <form method='post' enctype='multipart/form-data' action='/file'>
        Destination <small>(e.g.: https://username:password@cococloud.co/databasename)</small>: <input name='destination'>
        <br/>
        <input type='file' name='backup'>
        <br/>
        <input type='submit' value='upload single'>
      </form>

      <form action='/multi' method='post' enctype='multipart/form-data'>
        Destination <small>(e.g.: https://username:password@cococloud.co/databasename)</small>: <input name='destination'>
        <br/>
        <input type='file' name='backups' multiple>
        <input type='submit' value='upload multiple'>
      </form>

    </html>
  "

app.post '/backup', (req,res,next) ->

  console.log "Backup request"
  db = new PouchDB(req.body.destination)
  db.load(req.body.value).then ->
    console.log "Backup loaded"
    res.send "Backup loaded"
  .catch (error) -> console.log error

app.post '/file', upload.single('backup'), (req,res,next) ->
  try
    fs.unlinkSync '/tmp/backup.pouchdb'
  catch error

  console.log req

  zip = new admZip(req.file.path)
  zip.extractAllTo '/tmp'
  fs.readFile '/tmp/backup.pouchdb', (err,data) ->
    db = new PouchDB(req.body.destination)
    db.load(data.toString()).then ->
      console.log "#{req.file.path} loaded"
      res.send "Backup loaded"
      try
        fs.unlinkSync '/tmp/backup.pouchdb'
      catch error
    .catch (error) -> console.log error

app.post '/multi', upload.any(), (req,res,next) ->
  try
    fs.unlinkSync '/tmp/backup.pouchdb'
  catch error

  counter = 0
  _(req.files).each (file) =>
    console.log file
    zip = new admZip(file.path)
    zip.extractAllTo '/tmp'
    fs.readFile '/tmp/backup.pouchdb', (err,data) ->
      db = new PouchDB(req.body.destination)
      db.load(data.toString()).then ->
        console.log "#{file.path} loaded"
        counter += 1
        try
          fs.unlinkSync '/tmp/backup.pouchdb'
        catch error
      .catch (error) -> console.log error

    res.send "Loaded #{counter} backup files."


app.listen 3000, ->
  console.log('Example app listening on port 3000!')
