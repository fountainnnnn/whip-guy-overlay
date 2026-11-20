// Gives the page one way to talk to the main process: the same messages the
// macOS app receives through window.webkit.messageHandlers.whip.
const { contextBridge, ipcRenderer } = require('electron')

contextBridge.exposeInMainWorld('whipNative', {
  postMessage: m => ipcRenderer.send('whip', m),
})
