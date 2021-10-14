@react.component
let make = () => {
  let handleClick = _ => {
    let ws = WebSocket.make("ws://127.0.0.1:8080/")
    ws->WebSocket.on(#message(msg => Js.log(msg)))
  }

  <div>
    {React.string("test")} <button onClick=handleClick> {React.string("connect")} </button>
  </div>
}
