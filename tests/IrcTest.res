open Irc.Message

let eq = (a, b) => a == b

let runSplitInTwo = () => {
  Tests.run(
    __POS_OF__("splitInTwoRe one match"),
    splitInTwoRe("abc def", ~pattern=%re("/\s+/")),
    eq,
    Some(("abc", "def")),
  )

  Tests.run(
    __POS_OF__("splitInTwoRe multiple matches"),
    splitInTwoRe("abc def ghi", ~pattern=%re("/\s+/")),
    eq,
    Some(("abc", "def ghi")),
  )
}

let runParse = () => {
  Tests.run(
    __POS_OF__("no params"),
    parse("PONG\r\n"),
    eq,
    {
      command: "PONG",
      params: [],
      prefix: None,
      tags: None,
    },
  )

  Tests.run(
    __POS_OF__("two params"),
    parse("PRIVMSG test test\r\n"),
    eq,
    {
      command: "PRIVMSG",
      params: ["test", "test"],
      prefix: None,
      tags: None,
    },
  )

  Tests.run(
    __POS_OF__("trailing part"),
    parse("PRIVMSG test :Testing!\r\n"),
    eq,
    {
      command: "PRIVMSG",
      params: ["test", "Testing!"],
      prefix: None,
      tags: None,
    },
  )

  Tests.run(
    __POS_OF__("only trailing part"),
    parse("PRIVMSG :Testing!\r\n"),
    eq,
    {
      command: "PRIVMSG",
      params: ["Testing!"],
      prefix: None,
      tags: None,
    },
  )

  Tests.run(
    __POS_OF__("nickname"),
    parse(":test!user@host PRIVMSG test :Still testing!\r\n"),
    eq,
    {
      command: "PRIVMSG",
      params: ["test", "Still testing!"],
      prefix: Some(Nickname({nick: "test", user: Some("user"), host: "host"})),
      tags: None,
    },
  )

  Tests.run(
    __POS_OF__("server name"),
    parse(":host PRIVMSG test :Still testing!\r\n"),
    eq,
    {
      command: "PRIVMSG",
      params: ["test", "Still testing!"],
      prefix: Some(ServerName("host")),
      tags: None,
    },
  )

  Tests.run(
    __POS_OF__("tags and prefix"),
    parse("@aaa=bbb;ccc;example.com/ddd=eee :test@test PRIVMSG test :Testing with tags!\r\n"),
    eq,
    {
      command: "PRIVMSG",
      params: ["test", "Testing with tags!"],
      prefix: Some(Nickname({nick: "test", user: None, host: "test"})),
      tags: Some(
        Js.Dict.fromArray([("aaa", Some("bbb")), ("ccc", None), ("example.com/ddd", Some("eee"))]),
      ),
    },
  )

  Tests.run(
    __POS_OF__("empty message"),
    parse("   \r\n"),
    eq,
    {
      command: "",
      params: [],
      prefix: None,
      tags: None,
    },
  )
}

let runToString = () => {
  Tests.run(
    __POS_OF__("tags and prefix"),
    toString({
      command: "PRIVMSG",
      params: ["test", "Testing with tags!"],
      prefix: Some(Nickname({nick: "test", user: None, host: "test"})),
      tags: Some(
        Js.Dict.fromArray([("aaa", Some("bbb")), ("ccc", None), ("example.com/ddd", Some("eee"))]),
      ),
    }),
    eq,
    "@aaa=bbb;ccc;example.com/ddd=eee :test@test PRIVMSG test :Testing with tags!",
  )

  Tests.run(
    __POS_OF__("only trailing part"),
    toString({
      command: "PRIVMSG",
      params: ["Still testing!"],
      prefix: Some(Nickname({nick: "test", user: Some("user"), host: "host"})),
      tags: None,
    }),
    eq,
    ":test!user@host PRIVMSG :Still testing!",
  )

  Tests.run(
    __POS_OF__("no params"),
    toString({
      command: "PONG",
      params: [],
      prefix: None,
      tags: None,
    }),
    eq,
    "PONG",
  )
}

let run = () => {
  runSplitInTwo()
  runParse()
  runToString()
}
