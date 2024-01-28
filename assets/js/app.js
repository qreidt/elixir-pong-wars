// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// Source palette: https://twitter.com/AlexCristache/status/1738610343499157872
const colorPalette = {
  ArcticPowder: "#F1F6F4",
  MysticMint: "#D9E8E3",
  Forsythia: "#FFC801",
  DeepSaffron: "#FF9932",
  NocturnalExpedition: "#114C5A",
  OceanicNoir: "#172B36",
};

// Alias
colorPalette.LIGHT = colorPalette.MysticMint;
colorPalette.LIGHT_BALL = colorPalette.NocturnalExpedition;
colorPalette.DARK = colorPalette.NocturnalExpedition;
colorPalette.DARK_BALL = colorPalette.MysticMint;

let arenaSizeX = 0;
let arenaSizeY = 0;
let arenaSquaresX = 0;
let arenaSquaresY = 0;
const squareSize = 24;

/** @type {HTMLCanvasElement} canvas */
let canvas;

/** @type {CanvasRenderingContext2D} */
let ctx;


/**
 * 
 * @param {Array<Array<String>>} arena
 * @param {CanvasRenderingContext2D} ctx
 * @param {Number} squareSize
 */
function drawSquares(arena) {
  for (let x = 0; x < arenaSquaresX; x++) {
    for (let y = 0; y < arenaSquaresY; y++) {
      ctx.fillStyle = colorPalette[arena[x][y]] ?? '#FFF';
      ctx.fillRect(x * squareSize, y * squareSize, squareSize, squareSize);
    }
  }
}

/**
 * 
 * @param {Number} x 
 * @param {Number} y 
 * @param {String} color 
 */
function drawBall(x, y, color) {
  ctx.beginPath();
  ctx.arc(x, y, squareSize / 2, 0, Math.PI * 2, false);
  ctx.fillStyle = color;
  ctx.fill();
  ctx.closePath();
}

/**
 * 
 * @param {Array<Array<String>>} arena
 * @param {HTMLCanvasElement} canvas 
 * @param {CanvasRenderingContext2D} ctx 
 */
function draw(arena, player_1, player_2) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  drawSquares(arena, ctx);
  drawBall(player_1.x, player_1.y, colorPalette.LIGHT_BALL);
  drawBall(player_2.x, player_2.y, colorPalette.DARK_BALL);
}

const canvasHooks = {
    mounted() {
      canvas = this.el.firstElementChild;
      ctx = canvas.getContext("2d");

      // Set Arena Data
      arena = JSON.parse(this.el.dataset.arena);
      arenaSizeX = canvas.width;
      arenaSizeY = canvas.height;
      arenaSquaresX = arenaSizeX / squareSize;
      arenaSquaresY = arenaSizeY / squareSize;

      // Set Players Data
      const player_1 = JSON.parse(this.el.dataset['player-1']);
      const player_2 = JSON.parse(this.el.dataset['player-2']);
      
      draw(arena, player_1, player_2);
    },

    updated() {
      const arena = JSON.parse(this.el.dataset.arena);

      const player_1 = JSON.parse(this.el.dataset['player-1']);
      const player_2 = JSON.parse(this.el.dataset['player-2']);

      draw(arena, player_1, player_2);
    }
};



let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {hooks: { canvas: canvasHooks }, params: {_csrf_token: csrfToken}})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

