function love.conf(t)
    t.identity = 'chord_diagram_editor' --Saving folder
    t.version = '11.1'
    t.gammacorrect = false
    t.appendidentity = true         --Search files in source then in save directory
    t.accelerometerjoystick = false --Accelerometer=joystick on ios/android
    if t.audio then t.audio.mixwithsystem = true end

    local W = t.window
    W.title = "Chord Diagram Editor"
    W.icon = "image/dark/5d-symbol.png"
    W.width, W.height = 1600, 1000
    W.minwidth, W.minheight = 160, 100
    -- W.borderless=false
    W.resizable = true
    W.fullscreentype = "desktop" --"exclusive"
    W.fullscreen = false
    W.vsync = 0                  --Do not limit FPS
    W.msaa = false               --Num of samples to use with multi-sampled antialiasing
    W.depth = 0                  --Bits/samp of depth buffer
    W.stencil = 1                --Bits/samp of stencil buffer
    W.display = 1                --Monitor ID
    W.highdpi = true             --High-dpi mode for the window on a Retina display

    local M = t.modules
    M.window, M.system, M.event = true, true, true
    M.audio, M.sound = true, true
    M.math, M.data = true, true
    M.timer, M.graphics, M.font, M.image = true, true, true, true
    M.mouse, M.touch, M.keyboard, M.joystick = true, true, true, true
    M.physics, M.thread, M.video = false, true, false
end
