util = require 'util'
path = require 'path'
yeoman = require 'yeoman-generator'
GitHubApi = require 'github'

githubUserInfo = (name, cb) ->
  proxy = process.env.http_proxy or process.env.HTTP_PROXY or process.env.https_proxy or process.env.HTTPS_PROXY or null
  githubOptions = version: '3.0.0'

  if proxy
    proxy = url.parse proxy

    githubOptions.proxy =
      host: proxy.hostname
      port: proxy.port

  github = new GitHubApi githubOptions

  github.user.getFrom
    user: name
  , (err, res) ->
    throw err  if err
    cb JSON.parse JSON.stringify res
    return
  return

class CoffeeModuleGenerator extends yeoman.generators.Base
  constructor: (args, options, config) ->
    super
    @currentYear = (new Date()).getFullYear()
    @on 'end', => @installDependencies skipInstall: options['skip-install']
    @pkg = JSON.parse @readFileAsString path.join __dirname, '../package.json'
    return

  prompting:
    askFor: ->
      done = @async()

      # have Yeoman greet the user.
      console.log @yeoman

      prompts = [
        name: 'githubUser'
        message: 'Would you mind telling me your username on GitHub?'
        default: 'someuser'
      ,
        name: 'moduleName'
        message: 'What\'s the name of your module?'
        default: @_.slugify(@appname)
      ,
        name: 'moduleDescription'
        message: 'A simple description of your module?'
        default: ""
      ,
        type: "confirm"
        name: 'swigCompiler'
        message: 'Add frontend swig templates'
        default: false
      ,
        type: "confirm"
        name: 'restAPI'
        message: 'Add a basic rest API'
        default: false
      ,
        name: 'serverPort'
        message: 'define the express port'
        default: 8001
      ]

      @prompt prompts, (props) =>
        @githubUser = props.githubUser
        @moduleName = props.moduleName
        @moduleDescription = props.moduleDescription
        @swigCompiler = props.swigCompiler
        @restAPI = props.restAPI
        @appname = @moduleName
        done()
        return
      return

  configuring:
    userInfo: ->
      done = @async()

      githubUserInfo @githubUser, (res) =>
        @realname = res.name
        @email = res.email
        @githubUrl = res.html_url
        done()
        return
      return

  writing: 
    projectfiles: ->
      @template '_package.json', 'package.json'
      @template '_bower.json', 'bower.json'
      @template 'Gruntfile.coffee'
      @template 'README.md'
      @template 'LICENSE'
      return

    gitfiles: ->
      @copy '_gitignore', '.gitignore'
      return

    app: ->
      @dest.mkdir('_src')
      @dest.mkdir('_src/lib')
      @dest.mkdir('_src/modules')

      @template '_src/server.coffee', "_src/server.coffee"
      @template '_src/lib/apibase.coffee', "_src/lib/apibase.coffee"
      @template '_src/lib/config.coffee', "_src/lib/config.coffee"
      @template '_src/modules/gui.coffee', "_src/modules/gui.coffee"
      if @restAPI
        @dest.mkdir('_src/models')
        @template '_src/lib/redisconnector.coffee', "_src/lib/redisconnector.coffee"
        @template '_src/models/redishash.coffee', "_src/models/redishash.coffee"
        @template '_src/models/todos.coffee', "_src/models/todos.coffee"
        @template '_src/modules/restbase.coffee', "_src/modules/restbase.coffee"
        @template '_src/modules/todos.coffee', "_src/modules/todos.coffee"

      @dest.mkdir('views')
      @template 'views/index.html', "views/index.html"
      @template 'views/frame.html', "views/frame.html"
      @template 'views/404.html', "views/404.html"

      @dest.mkdir('_src_static')
      @dest.mkdir('_src_static/js')
      @dest.mkdir('_src_static/css')
      @dest.mkdir('_src_static/css/styl')
      @template '_src_static/js/plugins.coffee', "_src_static/js/plugins.coffee"
     
      @template '_src_static/css/style.styl', "_src_static/css/style.styl"
      @template '_src_static/css/styl/general.styl', "_src_static/css/styl/general.styl"
      @template '_src_static/css/styl/globals.styl', "_src_static/css/styl/globals.styl"
      return

  install:
    npm: ->
      generator.npmInstall()
      generator.bowerInstall()
      return

module.exports = CoffeeModuleGenerator