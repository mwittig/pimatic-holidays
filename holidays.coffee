module.exports = (env) ->

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  # Include you own depencies with nodes global require function:
  #  
  #     someThing = require 'someThing'
  #  
  dateholidays = require 'date-holidays'

  # ###MyPlugin class
  # Create a class that extends the Plugin class and implements the following functions:
  class holidays extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #  
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
    init: (app, @framework, @config) =>
      env.logger.info("HolidaySensor initialized...")

      deviceConfigDef = require("./device-config-schema")
      
      @framework.deviceManager.registerDeviceClass("HolidaySensor", {
        configDef: deviceConfigDef.HolidaySensor,
        createCallback: (config) => new HolidaySensor(config)
      })	

  class HolidaySensor extends env.devices.Sensor
    
    # ####constructor()
    # Your constructor function must assign a name and id to the device.
    constructor: (@config) ->
      @name = @config.name
      @id = @config.id
      @country = @config.country ? @plugin.config.country
      @state = @config.state ? @plugin.config.state
      @debug = @config.debug ? @plugin.config.debug
      @_holidayname = "none"      
      @_holidaytype = "none"
      @_presence = false
      # ...

      # update the presence value every 5 seconds
      setInterval( ( => 
        @_setPresence()
      ), 5000)

      super()
      
    attributes:
      presence:
        description: "holiday yes/no"
        type: "boolean"
        labels: ['Holiday', 'noHoliday']
      holidayname:
        description: "holidays name"
        type: "string"
      holidaytype:
        description: "holidays type"
        type: "string"
        
    _setPresence: (value) ->
      if @debug is true then env.logger.info("debug", @debug)
      if @debug is true then env.logger.info("country", @country)
      if @debug is true then env.logger.info("state", @state)
      dh = new dateholidays(@country, @state)  
      # check if date is a holiday while respecting timezones
      today = new Date()
      todaystring = today.getFullYear() + "-" + (today.getMonth()+1) + "-" + today.getDate()

      # fakedate for testing
      #todaystring = '2017-12-24'
      
      if @debug is true then env.logger.info("actualdate", todaystring )
      istodayholiday = dh.isHoliday( new Date(todaystring) )
      
      @_holidayname = 'none'
      if istodayholiday then @_holidayname = istodayholiday["name"]
      @emit 'holidayname', @_holidayname
      if @debug is true then env.logger.info("holidayname variable:", @_holidayname)

      @_holidaytype = "none"
      if istodayholiday then @_holidaytype = istodayholiday["type"]
      @emit 'holidaytype', @_holidaytype
      if @debug is true then env.logger.info("holidaytype variable:", @_holidaytype)
      
      if @debug is true then env.logger.info("istodayholiday:", istodayholiday)
      if istodayholiday == false then value = false else value = true 
      if @debug is true then env.logger.info("presencevalue:", value)
      if @_presence is value then return
      @_presence = value
      @emit 'presence', value

    getPresence: -> Promise.resolve(@_presence)
    
    getHolidayname: -> Promise.resolve(@_holidayname)
    
    getHolidaytype: -> Promise.resolve(@_holidaytype)

    template: "presence"
       
    destroy: () ->
      clearInterval @_setPresence if @_setPresence?
      super()

  # ###Finally
  # Create a instance of my plugin
  holidays = new holidays
  # and return it to the framework.
  return holidays
