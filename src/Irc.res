module Message = {
  type nickname = {
    nick: string,
    user: option<string>,
    host: string,
  }

  type prefix =
    | Nickname(nickname)
    | ServerName(string)

  type t = {
    command: string,
    params: array<string>,
    prefix: option<prefix>,
    tags: option<Js.Dict.t<option<string>>>,
  }

  let make = (~prefix=?, ~tags=?, command, params) => {
    command: command,
    params: params,
    prefix: prefix,
    tags: tags,
  }

  let splitInTwo = (string, ~substring) =>
    switch Js.String.splitAtMost(substring, ~limit=2, string) {
    | [before, after] => Some((before, after))
    | _ => None
    }

  let splitInTwoRe = (string, ~pattern) => {
    Js.Re.exec_(pattern, string)
    ->Belt.Option.flatMap(res =>
      Js.Re.captures(res)
      ->Belt.Array.get(0)
      ->Belt.Option.flatMap(Js.Nullable.toOption)
      ->Belt.Option.map(end_ => {
        let start = Js.Re.index(res)
        (start, start + end_->Js.String.length)
      })
    )
    ->Belt.Option.map(((start, end_)) => {
      let before = string->Js.String.slice(~from=0, ~to_=start)
      let after = string->Js.String.sliceToEnd(~from=end_)

      (before, after)
    })
  }

  let stripPrefix = (string, ~prefix) =>
    if Js.String.startsWith(prefix, string) {
      Some(Js.String.sliceToEnd(string, ~from=Js.String.length(prefix)))
    } else {
      None
    }

  let parse = line => {
    let line = Js.String.trim(line)

    let (tags, line) =
      stripPrefix(line, ~prefix="@")
      ->Belt.Option.flatMap(splitInTwoRe(~pattern=%re("/\s+/")))
      ->Belt.Option.map(((tags, line)) => {
        let tags =
          Js.String.split(";", tags)
          ->Belt.Array.map(tag =>
            tag
            ->splitInTwo(~substring="=")
            ->Belt.Option.mapWithDefault((tag, None), ((key, value)) => (key, Some(value)))
          )
          ->Js.Dict.fromArray
        (Some(tags), line)
      })
      ->Belt.Option.getWithDefault((None, line))

    let (prefix, line) =
      stripPrefix(line, ~prefix=":")
      ->Belt.Option.flatMap(splitInTwoRe(~pattern=%re("/\s+/")))
      ->Belt.Option.map(((prefix, line)) => {
        switch splitInTwo(prefix, ~substring="@") {
        | None => (Some(ServerName(prefix)), line)
        | Some((prefix, host)) =>
          switch splitInTwo(prefix, ~substring="!") {
          | None => (Some(Nickname({nick: prefix, host: host, user: None})), line)
          | Some((nick, user)) => (Some(Nickname({nick: nick, user: Some(user), host: host})), line)
          }
        }
      })
      ->Belt.Option.getWithDefault((None, line))

    let (command, line) =
      splitInTwoRe(line, ~pattern=%re("/\s+/"))->Belt.Option.getWithDefault((line, ""))

    let line = " " ++ line

    let (trailing, line) = switch splitInTwo(line, ~substring=" :") {
    | None => ([], line)
    | Some((line, trailing)) => ([trailing], line)
    }

    let line = Js.String.trim(line)

    let params = if Js.String.length(line) == 0 {
      trailing
    } else {
      Js.String.splitByRe(%re("/\s+/"), line)
      ->Belt.Array.keepMap(param => param)
      ->Belt.Array.concat(trailing)
    }

    {
      command: command,
      params: params,
      prefix: prefix,
      tags: tags,
    }
  }

  let escapeTagValue = value =>
    value
    ->Js.String2.replaceByRe(%re("/\u005C/ug"), "\\\\")
    ->Js.String2.replaceByRe(%re("/\;/g"), "\\:")
    ->Js.String2.replaceByRe(%re("/\u000D/ug"), "\\r")
    ->Js.String2.replaceByRe(%re("/\u000A/ug"), "\\n")
    ->Js.String2.replaceByRe(%re("/\u0020/ug"), "\\s")

  let toString = ({command, params, prefix, tags}) => {
    let tags = switch tags {
    | None => ""
    | Some(tags) =>
      let tags =
        Js.Dict.entries(tags)
        ->Belt.Array.map(((k, v)) => {
          switch v {
          | None => k
          | Some(v) => k ++ "=" ++ v
          }
        })
        ->Belt.Array.joinWith(";", s => s)
      "@" ++ tags ++ " "
    }

    let prefix = switch prefix {
    | None => ""
    | Some(prefix) => {
        let prefix = switch prefix {
        | Nickname({nick, user: Some(user), host}) => nick ++ "!" ++ user ++ "@" ++ host
        | Nickname({nick, user: None, host}) => nick ++ "@" ++ host
        | ServerName(name) => name
        }
        ":" ++ prefix ++ " "
      }
    }

    let params = switch params {
    | [] => ""
    | [trailing] => " :" ++ trailing
    | _ => {
        let trailing = params->Belt.Array.getUnsafe(Js.Array.length(params) - 1)
        let params = params->Js.Array.slice(~start=0, ~end_=Js.Array.length(params) - 1)

        " " ++ params->Belt.Array.joinWith("", s => s ++ " ") ++ ":" ++ trailing
      }
    }

    tags ++ prefix ++ command ++ params
  }

  let user = (username, realname) => make("USER", [username, "0", "*", realname])

  let pass = password => make("PASS", [password])

  let nick = nick => make("NICK", [nick])

  let ping = srvs => make("PING", srvs)

  let pong = srvs => make("PONG", srvs)

  let quit = msg => make("QUIT", [msg])

  let join = channel => make("JOIN", [channel])

  let privmsg = (target, message) => make("PRIVMSG", [target, message])
}

type message =
  | Quit({user: Message.nickname, reason: option<string>})
  | Join({user: Message.nickname, channel: string})
  | Part({user: Message.nickname, channel: string, reason: option<string>})
  | Privmsg({source: Message.prefix, target: string, message: string})

let toMessage = (msg: Message.t) =>
  switch msg {
  | {command: "QUIT", prefix: Some(Nickname(user)), params: [reason], _} =>
    Some(Quit({user: user, reason: Some(reason)}))
  | {command: "QUIT", prefix: Some(Nickname(user)), params: [], _} =>
    Some(Quit({user: user, reason: None}))

  | {command: "JOIN", prefix: Some(Nickname(user)), params: [channel], _} =>
    Some(Join({user: user, channel: channel}))

  | {command: "PART", prefix: Some(Nickname(user)), params: [channel], _} =>
    Some(Part({user: user, channel: channel, reason: None}))
  | {command: "PART", prefix: Some(Nickname(user)), params: [channel, reason], _} =>
    Some(Part({user: user, channel: channel, reason: Some(reason)}))

  | {command: "PRIVMSG", prefix: Some(source), params: [target, message]} =>
    Some(Privmsg({source: source, target: target, message: message}))

  | _ => None
  }

// type conn = {
//   sock: WebSocket.t,
//   url: string,
//   nick: string,
//   realname: option<string>,
//   channel: string,
// }

let connect = (~channel, ~nick, ~realname=?, url) => {
  let sock = WebSocket.make(url)

  let send = msg => sock->WebSocket.send(msg->Message.toString)

  let connectPromise = Promise.make((resolve, reject) => {
    let handleMessage = (. msg) => {
      let msg = msg->WebSocket.MessageEvent.data->Message.parse

      switch msg.command {
      | "PING" => Message.pong(msg.params)->send
      | "376" | "422" => {
          Message.join(channel)->send

          // resolve(. {
          //   sock: sock,
          //   url: url,
          //   nick: nick,
          //   realname: realname,
          //   channel: channel,
          // })

          resolve(. ignore())
        }
      | _ => ()
      }
    }

    sock->WebSocket.on(#message(handleMessage))

    let rec login = (. ()) => {
      Message.user(nick, realname->Belt.Option.getWithDefault(nick))->send
      Message.nick(nick)->send

      sock->WebSocket.off(#open_(login))
    }

    switch sock->WebSocket.readyState {
    | #2 | #3 => reject(. Error("failed to connect to socket"))
    | #1 => login(.)
    | #0 => sock->WebSocket.on(#open_(login))
    }
  })

  (sock, connectPromise)
}

let onMessage = (sock, cb) => {
  sock->WebSocket.on(
    #message(
      (. msg) => {
        let msg = msg->WebSocket.MessageEvent.data->Message.parse

        cb(. msg)
      },
    ),
  )
}

let offMessage = (sock, cb) => {
  sock->WebSocket.off(#message(cb))
}
