socket = io.connect()

socket.on "message", (data) ->
  $("div#chat-area").prepend "<div>" + data.message + "<div>"

