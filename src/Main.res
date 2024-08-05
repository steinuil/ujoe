open Webapi

let conn = WebSocket.make("ws://127.0.0.1:8081/webirc/websocket/")

ReactDOM.render(
  <ChatBox conn />,
  Dom.Document.getElementById(Dom.document, "root")->Belt.Option.getExn,
)
