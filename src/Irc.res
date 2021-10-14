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
}
