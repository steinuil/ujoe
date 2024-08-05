type t

@new external make: string => t = "WebSocket"

@send external send: (t, string) => unit = "send"

@send external close: t => unit = "close"
@send external closeWithCode: (t, int) => unit = "close"
@send external closeWithReason: (t, string) => unit = "close"
@send external closeWithCodeAndReason: (t, int, string) => unit = "close"

module MessageEvent = {
  type t

  @get external data: t => string = "data"
  @get external lastEventId: t => string = "lastEventId"
}

@send
external on: (
  t,
  @string
  [
    | @as("open") #open_((. unit) => unit)
    | #close((. int, string) => unit)
    | #message((. MessageEvent.t) => unit)
    | #error((. Dom.errorEvent) => unit)
  ],
) => unit = "addEventListener"

@send
external off: (
  t,
  @string
  [
    | @as("open") #open_((. unit) => unit)
    | #close((. int, string) => unit)
    | #message((. MessageEvent.t) => unit)
    | #error((. Dom.errorEvent) => unit)
  ],
) => unit = "removeEventListener"

@get external binaryType: t => @string [#blob | #arraybuffer] = "binaryType"
@set external setBinaryType: (t, @string [#blob | #arraybuffer]) => unit = "binaryType"

@get external bufferedAmount: t => int = "bufferedAmount"

@get external protocol: t => string = "protocol"

@get external readyState: t => @int [#0 | #1 | #2 | #3] = "readyState"

@get external url: t => string = "url"
