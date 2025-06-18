require 'Zenitha'

ZENITHA.setFirstScene("main")
ZENITHA.setShowFPS(false)
ZENITHA.setVersionText("")
ZENITHA.globalEvent.drawCursor = NULL
ZENITHA.globalEvent.clickFX = NULL
SCR.setSize(1600, 1000)

SCN.add("main", require('scene_keyboard'))
