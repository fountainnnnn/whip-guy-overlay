// Whip Guy for Windows (and Linux, and macOS if you prefer it to the Swift app).
// A transparent, click-through, always-on-top window over the primary display
// that loads ../web/index.html. Clicks pass through to the apps below except
// over the whip guy, so he can be dragged, poked and right-clicked.
const { app, BrowserWindow, Menu, Tray, screen, ipcMain, nativeImage } = require('electron')
const path = require('path')

app.commandLine.appendSwitch('autoplay-policy', 'no-user-gesture-required')
if (!app.requestSingleInstanceLock()) app.quit()

let win = null
let tray = null
let rects = []
let dragging = false
let ignoring = true
let speed = 1
const flags = { random: true, bubbles: true, sound: true, hidden: false }

function js(code) {
  if (win && !win.isDestroyed()) win.webContents.executeJavaScript(code).catch(() => {})
}

function toggle(key) {
  flags[key] = !flags[key]
  js(`window.whip.set('${key}', ${flags[key]})`)
  tray.setContextMenu(buildMenu())
}

function setSpeed(next) {
  speed = Math.min(3, Math.max(0.3, next))
  js(`window.whip.set('speed', ${speed})`)
}

function buildMenu() {
  const run = name => () => js(`window.whip.do('${name}')`)
  return Menu.buildFromTemplate([
    { label: '💥  MEGA ULTRA GIGA WHIP CRACK', click: run('mega') },
    { label: '🤠  Call reinforcements', click: run('reinforcements') },
    { label: '✈️  Request air strike', click: run('airstrike') },
    { label: '🔫  Duel against Claude', click: run('duel') },
    { type: 'separator' },
    { label: 'Random events', type: 'checkbox', checked: flags.random, click: () => toggle('random') },
    { label: 'Speech bubbles', type: 'checkbox', checked: flags.bubbles, click: () => toggle('bubbles') },
    { label: 'Sound', type: 'checkbox', checked: flags.sound, click: () => toggle('sound') },
    { label: 'Faster', click: () => setSpeed(speed * 1.4) },
    { label: 'Slower', click: () => setSpeed(speed / 1.4) },
    { label: flags.hidden ? 'Show whip guy' : 'Hide whip guy', click: () => toggle('hidden') },
    { type: 'separator' },
    { label: 'Quit Whip Guy', click: () => app.quit() },
  ])
}

// Let the mouse through everywhere except over the whip guy.
function trackMouse() {
  if (!win || win.isDestroyed()) return
  const p = screen.getCursorScreenPoint()
  const b = win.getBounds()
  const x = p.x - b.x
  const y = p.y - b.y
  const over = dragging || rects.some(([rx, ry, rw, rh]) => x >= rx && x <= rx + rw && y >= ry && y <= ry + rh)
  if (over === ignoring) {
    ignoring = !over
    win.setIgnoreMouseEvents(ignoring)
  }
}

app.whenReady().then(() => {
  const { bounds } = screen.getPrimaryDisplay()
  win = new BrowserWindow({
    ...bounds,
    transparent: true,
    backgroundColor: '#00000000',
    frame: false,
    resizable: false,
    movable: false,
    minimizable: false,
    maximizable: false,
    fullscreenable: false,
    hasShadow: false,
    skipTaskbar: true,
    focusable: false,
    alwaysOnTop: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      backgroundThrottling: false,
    },
  })
  win.setAlwaysOnTop(true, 'screen-saver')
  win.setIgnoreMouseEvents(true)
  if (process.platform === 'darwin') {
    win.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true })
    if (app.dock) app.dock.hide()
  }
  win.loadFile(path.join(__dirname, '..', 'web', 'index.html'))
  if (process.env.WHIP_DEBUG) {
    win.webContents.on('console-message', (_e, _level, msg) => console.log('page:', msg))
    win.webContents.on('did-finish-load', () => console.log('loaded', JSON.stringify(win.getBounds())))
    ipcMain.on('whip', (_e, m) => console.log('ipc:', JSON.stringify(m)))
  }

  const icon = nativeImage.createFromPath(path.join(__dirname, 'icon.png')).resize({ width: 18, height: 18 })
  tray = new Tray(icon)
  tray.setToolTip('Whip Guy')
  tray.setContextMenu(buildMenu())

  setInterval(trackMouse, 25)
})

ipcMain.on('whip', (_e, m) => {
  if (!m || typeof m !== 'object') return
  if (m.type === 'rects' && Array.isArray(m.rects)) rects = m.rects
  else if (m.type === 'drag') dragging = !!m.on
  else if (m.type === 'menu') buildMenu().popup({ window: win })
})

app.on('window-all-closed', () => app.quit())
