type t

@new external make: string => t = "WebSocket"

@send external send: (t, string) => unit = "send"

@send external close: t => unit = "close"
@send external closeWithCode: (t, int) => unit = "close"
@send external closeWithReason: (t, string) => unit = "close"
@send external closeWithCodeAndReason: (t, int, string) => unit = "close"

@send
external on: (
  t,
  @string
  [
    | @as("open") #open_(unit => unit)
    | #close((int, string) => unit)
    | #message(string => unit)
    | #error(Dom.errorEvent => unit)
  ],
) => unit = "addEventListener"

@get external binaryType: t => @string [#blob | #arraybuffer] = "binaryType"
@set external setBinaryType: (t, @string [#blob | #arraybuffer]) => unit = "binaryType"

@get external bufferedAmount: t => int = "bufferedAmount"

@get external protocol: t => string = "protocol"

@get external readyState: t => @int [#connecting | #open_ | #closing | #closed] = "readyState"

@get external url: t => string = "url"
