function love.conf(t)
    t.version = "0.9.1"
    t.console = false

    t.window.title = "PacMan FURG"
    t.window.width = 1920
    t.window.height = 1080
    t.window.fullscreen = true
    t.window.vsync = true
    t.window.fullscreentype = "normal"

    -- Ativando os módulos
    t.modules.event = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.window = true
    t.modules.thread = true
end
