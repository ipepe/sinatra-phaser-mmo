class window.iSocket
  _address: null
  _socket: null
  _event_callbacks: {}
  constructor: (address) ->
    if address
      @_address = address
    else
      @_address = 'ws://' + window.location.host
    @_socket = new WebSocket(@_address)
    @_hookOntoSocket()

  _hookOntoSocket: ->
    @_socket.onmessage = (message) =>
      response = JSON.parse(message.data)
      @_read(response.event, response.attributes)
    @_socket.onopen = =>
      @_read('socket_open')
    @_socket.onclose = =>
      @_read('socket_close')

  _checkEvent: (event) ->
    throw 'ArgumentError' unless typeof event == 'string'
    throw 'ArgumentError' unless event

  _read: (event, attributes=null) ->
#    console.log('reading incame _socket event:', event, attributes)
    @_checkEvent(event)
    if @_event_callbacks[event] && @_event_callbacks[event].length
      @_event_callbacks[event].forEach (callback) ->
        callback(attributes)

  send: (event, attributes) ->
    @_checkEvent(event)
    @_socket.send(JSON.stringify({event: event, attributes: attributes}))

  on: (event, callback) ->
    throw 'Callback is not a function' if typeof callback != 'function'
    @_event_callbacks[event] = [] unless @_event_callbacks[event] instanceof Array
    @_event_callbacks[event].push(callback)
