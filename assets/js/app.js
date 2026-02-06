// esbuild automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "config.exs".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"

let csrfToken = (function() {
  let meta = document.querySelector("meta[name='csrf-token']")
  if (!meta) {
    console.error("[LiveView] Missing meta[name='csrf-token'] – check your root layout. Clicks will not work.")
    return ""
  }
  let token = meta.getAttribute("content")
  if (token == null || token === "") {
    console.error("[LiveView] csrf-token meta is empty. Clicks may not work.")
    return ""
  }
  return token
})()

let Hooks = {}
try {
  let liveSocket = new LiveSocket("/live", Socket, {
    params: {_csrf_token: csrfToken},
    hooks: Hooks
  })

  // connect if there are any LiveViews on the page
  liveSocket.connect()

  // expose liveSocket on window for web console debug logs and latency simulation:
  // >> liveSocket.enableDebug()
  // >> liveSocket.enableLatencySim(1000)
  window.liveSocket = liveSocket
} catch (err) {
  console.error("[LiveView] Failed to start:", err)
}
