---
title: "Fool's Mate"
date: 2026-09-20 08:00:00 +0100
categories: [Writeups, TryHackMe]
tags: [web-exploitation, client-side-validation, api-security, burp-suite, javascript, curl]
image:
  path: /assets/img/posts/fools-mate/cover.png
related_notes:
  - "[[Burp Suite Cheat Sheet]]"
---

## Introduction

Fool's Mate drops you on a small web app called EndgameTrainer: a chessboard with a mate-in-one puzzle already set up, white rook on a1, white king on g1, black king cornered on g8. Play the obvious winning move and the browser doesn't just refuse it, it pops up a threat: "I'll shut down your PC if you play that." The actual task is figuring out whether that's a real server-side block or something that only exists in the page's own JavaScript, and if it's the latter, getting the win anyway.

## Theory

Client-side validation runs in the browser: it can shape what a user sees or make a form feel responsive, but the browser is fully under the user's control. Anything that decides whether an action is *allowed* has to be re-checked on the server, because nothing stops a request from being sent straight to the API without ever going through the page's JavaScript. Burp Suite's **Proxy** sits between browser and server and intercepts every request; **Repeater** takes a captured request and lets you edit and resend it as many times as you want, which is exactly the tool for testing whether a backend enforces a rule the frontend claims to.

## Walkthrough

### Hitting the client-side block

Playing the winning rook move on the board in the browser doesn't submit anything. Instead, a dialog interrupts:

<img src="/assets/img/posts/fools-mate/fools-mate_01.png" width="700" alt="Browser dialog reading 'I'll shut down your PC if you play that.' after attempting the winning move on the board">

### Reading the client-side check

Opening the browser's DevTools and searching the loaded `app.js` for "move" turns up a function called `preMoveCheck(from, to, promotion)`. It builds a throwaway `Chess` object from the current position, tries the move on that local copy, and if the result is checkmate, it shows the warning and returns `false` without ever sending a request:

```js
function preMoveCheck(from, to, promotion) {
  const probe = new Chess(game.fen());
  let result;
  try {
    result = probe.move({ from, to, promotion: promotion || undefined });
  } catch (e) {
    result = null;
  }
  if (result && probe.isCheckmate()) {
    showSystemNotice("I'll shut down your PC if you play that.");
    return false;
  }
  return true;
}
```

<img src="/assets/img/posts/fools-mate/fools-mate_02.png" width="700" alt="Firefox DevTools Debugger showing app.js with the preMoveCheck function, which blocks a move locally if it would be checkmate">

That's the whole restriction: a local simulation deciding, in the browser, whether to bother sending the real request at all. Nothing here says the server applies the same rule.

### Confirming the endpoint in Burp Repeater

With the browser's traffic proxied through Burp, playing a normal, non-winning move (`f2` to `f4`) shows the actual request shape: a `POST` to `/api/move` with a JSON body of `{"from":"f2","to":"f4"}`, a `sid` session cookie tracking the board state, and a JSON response containing the updated FEN, game status, and the bot's own reply move:

<img src="/assets/img/posts/fools-mate/fools-mate_03.png" width="700" alt="Burp Repeater showing a POST /api/move request with from f2 to f4, and a JSON response with status ongoing and the bot's reply move">

The response comes straight from the server, no reference to `preMoveCheck` anywhere, because that function only exists in the page's own JavaScript. The server has its own move validation (it computed `botMove`, updated the FEN), but nothing in the response suggests it also checks for checkmate before deciding whether to honor the move.

### Sending the winning move directly

Same request shape, this time with the actual winning move, `from: a1`, `to: a8`, rook to the back rank, sent straight through Repeater with the same session cookie:

<img src="/assets/img/posts/fools-mate/fools-mate_04.png" width="700" alt="Burp Repeater request POST /api/move with from a1 to a8, response JSON showing status checkmate, winner white, and a flag field">

The server processes it without hesitation and returns `"status":"checkmate"`, `"winner":"white"`, and a `flag` field directly in the JSON. The browser's warning dialog never had a say in it, because the request never went through the code that shows it.

### Same result with curl

Repeater isn't doing anything Burp-specific here, it's just sending an HTTP request. The identical move works from a plain terminal with `curl`, using a cookie jar to keep the session:

```bash
curl -s -b '/home/kali/Schreibtisch/cookie.txt' -c '/home/kali/Schreibtisch/cookie.txt' \
  -X POST http://10.128.131.98/api/move \
  -H "Content-Type: application/json" \
  -d '{"from":"a1", "to":"a8"}'
```

- `-b '<file>'` sends any cookies already stored in that file along with the request, so the server sees the same session `sid` as before.
- `-c '<file>'` writes back any cookies the server sets in its response into that same file, keeping the session current for the next request.
- `-X POST` sets the HTTP method, since the default for `curl` is `GET`.
- `-H "Content-Type: application/json"` tells the server the body is JSON, matching what `/api/move` expects.
- `-d '{"from":"a1", "to":"a8"}'` is the actual request body, the same JSON structure Burp Repeater sent.

<img src="/assets/img/posts/fools-mate/fools-mate_05.png" width="700" alt="Terminal running the curl command against /api/move with from a1 to a8, returning the same checkmate JSON response with the flag">

Same fields, same checkmate, same flag. Whatever blocks the move only exists in the browser tab, not on the wire.

## Defensive takeaways

The fix here isn't complicated: whatever `preMoveCheck` does client-side has to also run server-side before `/api/move` commits a move, since the server is the only place a decision actually holds. More generally, any endpoint that accepts a `from`/`to` pair (or any state-changing input) has to validate against its own authoritative game state, not trust that the frontend already filtered out illegal or unwanted moves. A UI-level warning is fine as user experience, showing someone why a move is disallowed, but it can never substitute for the same check enforced where the request actually lands.

## Lessons Learned

I've read "never trust the client" as a general rule before, but this was the first time I saw it play out end to end on something this readable: a plain-text JavaScript function I could open in DevTools and read line by line, deciding entirely on its own whether to even bother contacting the server. Once I saw `preMoveCheck` build its own local copy of the board just to decide whether to show a popup, it was obvious the real question was what the server does when asked directly, and Repeater made answering that a matter of editing two field values and hitting send.

## References

- [TryHackMe Room — Fool's Mate](https://tryhackme.com/room/foolsmate)
- [Burp Suite](https://portswigger.net/burp)
