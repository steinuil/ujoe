let containerStyle = ReactDOM.Style.make(
  ~display="flex",
  ~flexDirection="column",
  ~height="100%",
  ~fontFamily="IBM Plex Sans",
  (),
)

let topStyle = ReactDOM.Style.make(
  ~padding="10px 15px",
  ~backgroundColor="#464B8D",
  ~color="#FFF",
  ~borderBottom="2px solid #161950",
  ~flexShrink="0",
  (),
)

let chatStyle = ReactDOM.Style.make(
  ~padding="10px 15px",
  ~flexGrow="1",
  ~backgroundColor="#161950",
  ~color="#FFF",
  ~overflowY="auto",
  (),
)

let inputStyle = ReactDOM.Style.make(
  ~backgroundColor="#464B8D",
  ~color="#FFF",
  ~borderTop="2px solid #161950",
  ~flexShrink="0",
  ~padding="4px",
  ~display="flex",
  (),
)

let inputBox = ReactDOM.Style.make(
  ~backgroundColor="#161950",
  ~color="#FFF",
  ~fontFamily="IBM Plex Sans",
  ~fontSize="1em",
  ~borderRadius="5px",
  ~padding="5px 8px",
  ~border="none",
  ~boxSizing="border-box",
  ~flexGrow="1",
  (),
)

let onValue = (set, ev) => set(_ => ReactEvent.Form.target(ev)["value"])

let nickStyle = ReactDOM.Style.make(~padding="5px 8px", ~marginRight="2px", ~flexShrink="0", ())

@react.component
let make = (~conn) => {
  let (messages, setMessages) = React.useState(() => [])

  let chatRef = React.useRef(Js.Nullable.null)

  let scrollToBottom = () =>
    chatRef.current->Js.Nullable.iter((. chat) => {
      let topY = chat->Webapi.Dom.Element.scrollTop->Js.Math.floor_int
      // let height = chat->Webapi.Dom.Element.scrollHeight
      let offsetHeight =
        chat
        ->Webapi.Dom.Element.asHtmlElement
        ->Belt.Option.map(chat => {
          Js.log(chat->Webapi.Dom.HtmlElement.scrollHeight)
          chat->Webapi.Dom.HtmlElement.offsetHeight
        })
        ->Belt.Option.getWithDefault(0)

      // Js.log2(y, ayy)

      Js.log2("bottom y:", topY + offsetHeight)
    })

  React.useEffect1(() => {
    Js.Nullable.toOption(chatRef.current)->Belt.Option.map(chat => {
      let listener = _ => {
        scrollToBottom()
      }

      chat->Webapi.Dom.Element.addEventListener("scroll", listener)

      () => chat->Webapi.Dom.Element.removeEventListener("scroll", listener)
    })
  }, [chatRef.current])

  React.useEffect0(() => {
    let onMessage = (. msg) => {
      setMessages(messages => messages->Belt.Array.concat([msg]))
    }

    conn->Irc.onMessage(onMessage)

    Some(() => conn->Irc.offMessage(onMessage))

    // conn->WebSocket.on(
    //   #message(
    //     (. msg) => {
    //       let timestamp = Webapi.Performance.now(Webapi.Dom.Window.performance(Webapi.Dom.window))
    //       let msg = Irc.Message.parse(msg->WebSocket.MessageEvent.data)

    //       switch msg.command {
    //       | "PING" => conn->WebSocket.send(Irc.Message.pong(msg.params)->Irc.Message.toString)
    //       | "376" | "422" =>
    //         conn->WebSocket.send(Irc.Message.join("#soranowoto-dev")->Irc.Message.toString)
    //       | _ => ()
    //       }

    //       setMessages(messages => messages->Belt.Array.concat([(timestamp, msg)]))
    //     },
    //   ),
    // )

    // switch conn->WebSocket.readyState {
    // | #1 => {
    //     Js.log("connected")
    //     conn->WebSocket.send(Irc.Message.user("steen-test", "steen")->Irc.Message.toString)
    //     conn->WebSocket.send(Irc.Message.nick("steen-test")->Irc.Message.toString)
    //   }
    // | #0 =>
    //   conn->WebSocket.on(
    //     #open_(
    //       (. ()) => {
    //         Js.log("connecting")
    //         conn->WebSocket.send(Irc.Message.user("steen-test", "steen")->Irc.Message.toString)
    //         conn->WebSocket.send(Irc.Message.nick("steen-test")->Irc.Message.toString)
    //       },
    //     ),
    //   )
    // | state => Js.log2("state", state)
    // }
  })

  let (input, setInput) = React.useState(() => "")

  let handleSubmit = ev => {
    ReactEvent.Form.preventDefault(ev)

    // conn->WebSocket.send(Irc.Message.privmsg("#soranowoto-dev", input)->Irc.Message.toString)
    conn->WebSocket.send(input)
    setInput(_ => "")
  }

  let handleKey = ev => {
    switch ReactEvent.Keyboard.key(ev) {
    | "ArrowUp" => ()
    | "ArrowDown" => ()
    | _ => ()
    }
  }

  <div style=containerStyle>
    <div style=topStyle> {React.string("top bar and options")} </div>
    <div style=chatStyle ref={ReactDOM.Ref.domRef(chatRef)}>
      {messages
      ->Belt.Array.mapWithIndex((i, (timestamp, msg)) =>
        <div key={Js.Int.toString(i) ++ Js.Float.toString(timestamp)}>
          {React.string(Irc.Message.toString(msg))}
        </div>
      )
      ->React.array}
    </div>
    <form onSubmit=handleSubmit style=inputStyle>
      <div style=nickStyle> {React.string("steenuil")} </div>
      <input
        tabIndex=1
        type_="text"
        style=inputBox
        value=input
        onChange={onValue(setInput)}
        onKeyDown=handleKey
      />
      <input type_="submit" style={ReactDOM.Style.make(~display="none", ())} />
    </form>
  </div>
}
