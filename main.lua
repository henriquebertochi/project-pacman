--[[
FUNÇÕES BÁSICAS
]] --

local gameMode
local delta

local offsetX
local offsetY
local areaX = 1000
local areaY = 800
local activeResolution = 1

local resolution = {
	{ x = 1920, y = 1080 },
}

local pauseSizeX = 400
local pauseSizeY = 200

local isEscPressed
local isSpacePressed
local isEnterPressed
local isUpPressed
local isDownPressed
local isLeftPressed
local isRightPressed

local fontBig
local fontMedium
local fontSmall
local fontSmallMedium
local fontScore

local pacmanSprites

local menuBgR = 0
local menuBgG = 0
local menuBgB = 0

local menuMode
local menuActive

local menuTimer
local menuEnabled
local menuPositions = 2

function resetMenu()
	menuActive = 1
	menuTimer = 0
	menuEnabled = false
end

-- FUNÇÕES UPDATE

function menuTimerWait()
	if menuTimer > 0.2 then
		menuEnabled = true
	else
		menuEnabled = false
	end
end

function menuTimerAdd()
	menuTimer = menuTimer + delta
end

function updateMenu()
	menuTimerWait()
	if menuMode == "main" then
		updateMainMenu()
	end
	if isUpPressed and (menuActive > 1) then
		if menuEnabled then
			menuActive = menuActive - 1
			menuTimer = 0
		end
	end
	if isDownPressed and (menuActive < menuPositions) then
		if menuEnabled then
			menuActive = menuActive + 1
			menuTimer = 0
		end
	end
	menuTimerAdd()
end

function updateMainMenu()
	if isEnterPressed and menuEnabled then
		if menuActive == 1 then
			initGame()
		end
		if menuActive == 2 then
			love.event.push('quit')
		end
	end
end

-- FUNÇÕES INICIAIS

function loadStuff()
	fontBig = love.graphics.newFont(48)
	fontMedium = love.graphics.newFont(36)
	fontSmall = love.graphics.newFont(14)
	fontSmallMedium = love.graphics.newFont(28)
	fontScore = love.graphics.newFont("fonts/arcadeclassic.TTF", 28)

	pacmanSprites = {}
	pacmanSprites[1] = {}
	pacmanSprites[2] = {}
	pacmanSprites[3] = {}
	pacmanSprites[4] = {}
	pacmanSprites[1][1] = love.graphics.newImage("images/pacman/up/pacman1up.png")
	pacmanSprites[1][2] = love.graphics.newImage("images/pacman/up/pacman2up.png")
	pacmanSprites[1][3] = love.graphics.newImage("images/pacman/up/pacman3up.png")
	pacmanSprites[2][1] = love.graphics.newImage("images/pacman/right/pacman1right.png")
	pacmanSprites[2][2] = love.graphics.newImage("images/pacman/right/pacman2right.png")
	pacmanSprites[2][3] = love.graphics.newImage("images/pacman/right/pacman3right.png")
	pacmanSprites[3][1] = love.graphics.newImage("images/pacman/down/pacman1down.png")
	pacmanSprites[3][2] = love.graphics.newImage("images/pacman/down/pacman2down.png")
	pacmanSprites[3][3] = love.graphics.newImage("images/pacman/down/pacman3down.png")
	pacmanSprites[4][1] = love.graphics.newImage("images/pacman/left/pacman1left.png")
	pacmanSprites[4][2] = love.graphics.newImage("images/pacman/left/pacman2left.png")
	pacmanSprites[4][3] = love.graphics.newImage("images/pacman/left/pacman3left.png")

	ghostsSprites = {}
	ghostsSprites[1] = love.graphics.newImage("images/ghosts/1.png")
	ghostsSprites[2] = love.graphics.newImage("images/ghosts/2.png")
	ghostsSprites[3] = love.graphics.newImage("images/ghosts/3.png")
	ghostsSprites[4] = love.graphics.newImage("images/ghosts/4.png")
	ghostsSprites[5] = love.graphics.newImage("images/ghosts/safe.png")
	ghostsSprites[6] = love.graphics.newImage("images/ghosts/eaten.png")

	cornerSprites = {}
	cornerSprites[1] = love.graphics.newImage("images/maze/1.png")
	cornerSprites[2] = love.graphics.newImage("images/maze/2.png")
	cornerSprites[3] = love.graphics.newImage("images/maze/3.png")
	cornerSprites[4] = love.graphics.newImage("images/maze/4.png")
	cornerSprites[5] = love.graphics.newImage("images/maze/5.png")
	cornerSprites[6] = love.graphics.newImage("images/maze/6.png")

	resetMenu()

	love.window.setMode(1920, 1080, { fullscreen = true, fullscreentype = "normal" })
	offsetX = (1920 - areaX) / 2
	offsetY = (1080 - areaY) / 2

	love.keyboard.setKeyRepeat(true)
end

-- FUNÇÕES DE CORES

function white()
	love.graphics.setColor(255, 255, 255, 255)
end

function red()
	love.graphics.setColor(255, 0, 0, 255)
end

function blue()
	love.graphics.setColor(0, 0, 255, 255)
end

function yellow()
	love.graphics.setColor(255, 255, 0, 255)
end

function greenAlpha()
	love.graphics.setColor(0, 255, 0, 90)
end

function yellowAlpha()
	love.graphics.setColor(255, 255, 0, 127)
end

function redAlpha()
	love.graphics.setColor(255, 0, 0, 127)
end

--[[
CÓDIGO DO JOGO
]] --

local pacman
local ghosts
local tunnel

local gridSize = 24
local gridX = 28
local gridY = 30
local gridOffsetX
local gridOffsetY

local dotSize = 0.14 * gridSize
local specialDotMaxTime = 5
local collectedDots

local score = 0
local lives
local level = 1
local gameTimer = 0

-- COORDENANDO O MAPA (PONTOS E PAREDES)

function initMap()
	local i
	local j
	local k

	contents, size = love.filesystem.read("maps/maze.map", gridX * gridY)
	map = {}
	for i = 0, gridX, 1 do
		map[i] = {}
		for j = 0, gridY, 1 do
			map[i][j] = false
		end
	end

	j = 0
	k = 0
	for i = 1, #contents do
		local c = contents:sub(i, i)
		if c == "1" then
			map[j][k] = true
		end
		j = j + 1
		if j == gridX then
			j = 0
			k = k + 1
		end
	end

	contents, size = love.filesystem.read("maps/dots.map", gridX * gridY)
	dots = {}
	for i = 0, gridX, 1 do
		dots[i] = {}
		for j = 0, gridY, 1 do
			dots[i][j] = false
		end
	end

	j = 0
	k = 0
	for i = 1, #contents do
		local c = contents:sub(i, i)
		if c == "1" then
			dots[j][k] = true
		end
		j = j + 1
		if j == gridX then
			j = 0
			k = k + 1
		end
	end

	contents, size = love.filesystem.read("maps/corners.map", gridX * gridY)
	corners = {}
	for i = 0, gridX, 1 do
		corners[i] = {}
		for j = 0, gridY, 1 do
			corners[i][j] = 0
		end
	end

	j = 0
	k = 0
	for i = 1, #contents do
		local c = contents:sub(i, i)
		if c == "1" then
			corners[j][k] = 1
		end
		if c == "2" then
			corners[j][k] = 2
		end
		if c == "3" then
			corners[j][k] = 3
		end
		if c == "4" then
			corners[j][k] = 4
		end
		if c == "5" then
			corners[j][k] = 5
		end
		if c == "6" then
			corners[j][k] = 6
		end
		j = j + 1
		if j == gridX then
			j = 0
			k = k + 1
		end
	end

	tunnel = {}
	tunnel[1] = {}
	tunnel[2] = {}
	tunnel[1].x = 1
	tunnel[1].y = 13
	tunnel[2].x = 26
	tunnel[2].y = 13

	specialDots = {}
	specialDots[1] = {}
	specialDots[2] = {}
	specialDots[3] = {}
	specialDots[4] = {}
	specialDots[1].x = 1
	specialDots[1].y = 3
	specialDots[1].active = true
	specialDots[2].x = 26
	specialDots[2].y = 3
	specialDots[2].active = true
	specialDots[3].x = 1
	specialDots[3].y = 22
	specialDots[3].active = true
	specialDots[4].x = 26
	specialDots[4].y = 22
	specialDots[4].active = true
end

-- INICIANDO PACMAN E OS GHOSTS

function initPacman()
	pacman = {}
	pacman.mapX = 13
	pacman.mapY = 16
	pacman.lastMapX = pacman.mapX
	pacman.lastMapY = pacman.mapY
	pacman.x = pacman.mapX * gridSize + gridSize * 0.5
	pacman.y = pacman.mapY * gridSize + gridSize * 0.5
	pacman.speed = 140
	pacman.size = gridSize * 0.5 - 4
	pacman.sprite = 1
	pacman.spriteInc = true
	pacman.direction = 4
	pacman.directionText = "left"
	pacman.nextDirection = 4
	pacman.nextDirectionText = "left"
	pacman.movement = 0
	pacman.distance = 0
	pacman.image = 1
	pacman.specialDotActive = false
	pacman.specialDotTimer = 0
	pacman.upFree = false
	pacman.downFree = false
	pacman.leftFree = false
	pacman.rightFree = false
	pacman.sameSpriteTimer = 0

	if map[pacman.mapX][pacman.mapY - 1] == false then
		pacman.upFree = true
	end
	if map[pacman.mapX][pacman.mapY + 1] == false then
		pacman.downFree = true
	end
	if map[pacman.mapX - 1][pacman.mapY] == false then
		pacman.leftFree = true
	end
	if map[pacman.mapX + 1][pacman.mapY] == false then
		pacman.rightFree = true
	end
end

function resetPacmanPosition()
	pacman.mapX = 13
	pacman.mapY = 16
	pacman.lastMapX = pacman.mapX
	pacman.lastMapY = pacman.mapY
	pacman.x = pacman.mapX * gridSize + gridSize * 0.5
	pacman.y = pacman.mapY * gridSize + gridSize * 0.5
	pacman.sprite = 1
	pacman.spriteInc = true
	pacman.direction = 4
	pacman.directionText = "left"
	pacman.nextDirection = 4
	pacman.nextDirectionText = "left"
	pacman.movement = 0
	pacman.distance = 0
	pacman.image = 1
	pacman.specialDotActive = false
	pacman.specialDotTimer = 0
end

function initGhosts()
	ghosts = {}
	for i = 1, 4, 1 do
		ghosts[i] = {}
		ghosts[i].mapX = 0
		ghosts[i].mapY = 0
		ghosts[i].x = 0
		ghosts[i].y = 0
		ghosts[i].eaten = false
		ghosts[i].out = false
		ghosts[i].upFree = false
		ghosts[i].downFree = false
		ghosts[i].leftFree = false
		ghosts[i].rightFree = false
		ghosts[i].direction = 1
		ghosts[i].nextDirection = 1
		ghosts[i].speed = 100
		ghosts[i].normSpeed = 100
		ghosts[i].slowSpeed = 70
	end
	resetGhostsPosition()
end

function resetGhostsPosition()
	ghosts[1].mapX = 12
	ghosts[1].mapY = 10
	ghosts[1].direction = 4
	ghosts[1].nextDirection = 4

	ghosts[2].mapX = 15
	ghosts[2].mapY = 10
	ghosts[2].direction = 2
	ghosts[2].nextDirection = 2

	ghosts[3].mapX = 13
	ghosts[3].mapY = 13
	ghosts[3].direction = 1
	ghosts[3].nextDirection = 1

	ghosts[4].mapX = 14
	ghosts[4].mapY = 13
	ghosts[4].direction = 1
	ghosts[4].nextDirection = 1
	for i = 1, 4, 1 do
		ghosts[i].x = ghosts[i].mapX * gridSize + gridSize * 0.5
		ghosts[i].y = ghosts[i].mapY * gridSize + gridSize * 0.5
		if map[ghosts[i].mapX][(ghosts[i].mapY) - 1] == false then
			ghosts[i].upFree = true
		end
		if map[ghosts[i].mapX][(ghosts[i].mapY) + 1] == false then
			ghosts[i].downFree = true
		end
		if map[(ghosts[i].mapX) - 1][ghosts[i].mapY] == false then
			ghosts[i].leftFree = true
		end
		if map[(ghosts[i].mapX) + 1][ghosts[i].mapY] == false then
			ghosts[i].rightFree = true
		end
	end
end

function initGame()
	gameMode = "getReady"
	lives = 3
	score = 0
	gameOverTimer = 0
	getReadyTimer = 0
	gameTimer = 0
	collectedDots = 0

	initMap()
	initPacman()
	initGhosts()

	gridOffsetX = (areaX * 0.5) - (gridX * gridSize * 0.5) + offsetX
	gridOffsetY = (areaY * 0.5) - (gridY * gridSize * 0.5) + offsetY
end

-- FUNÇÕES DRAW

function drawArea()
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.rectangle("line", offsetX, offsetY, areaX, areaY)
end

function drawMenu()
	if menuMode == "main" then
		drawMainMenu()
	end
end

function drawMainMenu()
	love.graphics.setBackgroundColor(menuBgR, menuBgG, menuBgB)
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setFont(fontBig)
	love.graphics.print("PACMAN FURG", offsetX + 160, offsetY + 100)

	local furgLogo = love.graphics.newImage("images/furg.png")
	love.graphics.draw(furgLogo, offsetX + 800, offsetY + 0, 0, 0.1, 0.1)
	local pacmanLogo = love.graphics.newImage("images/pacman-logo.png")
	love.graphics.draw(pacmanLogo, offsetX + 0, offsetY + 0, 0, 0.1, 0.1)

	love.graphics.setFont(fontSmallMedium)
	love.graphics.print("by Henrique Bertochi and Vicenzo Copetti", offsetX + 160, offsetY + 200)
	love.graphics.setFont(fontMedium)
	if menuActive == 1 then red() else white() end
	love.graphics.print("NEW GAME", offsetX + 200, offsetY + 300)
	if menuActive == 2 then red() else white() end
	love.graphics.print("QUIT", offsetX + 200, offsetY + 350)
end

function drawPacman()
	white()
	love.graphics.draw(pacmanSprites[pacman.direction][pacman.sprite], pacman.x + gridOffsetX - 8.5,
		pacman.y + gridOffsetY - 8.5)
end

function drawGhosts()
	for i = 1, 4, 1 do
		white()
		if pacman.specialDotActive == false then
			love.graphics.draw(ghostsSprites[i], ghosts[i].x + gridOffsetX - 8.5, ghosts[i].y + gridOffsetY - 8.5)
		else
			if ghosts[i].eaten == true then
				love.graphics.draw(ghostsSprites[6], ghosts[i].x + gridOffsetX - 8.5, ghosts[i].y + gridOffsetY - 8.5)
			else
				love.graphics.draw(ghostsSprites[5], ghosts[i].x + gridOffsetX - 8.5, ghosts[i].y + gridOffsetY - 8.5)
			end
		end
	end
end

function drawMaze()
	white()
	for i = 0, gridX, 1 do
		for j = 0, gridY, 1 do
			if corners[i][j] > 0 then
				love.graphics.draw(cornerSprites[corners[i][j]], i * gridSize + gridOffsetX, j * gridSize + gridOffsetY)
			end
		end
	end
end

function drawDots()
	white()
	for i = 0, gridX, 1 do
		for j = 0, gridY, 1 do
			if dots[i][j] then
				love.graphics.circle("fill", i * gridSize + gridOffsetX + 0.5 * gridSize,
					j * gridSize + gridOffsetY + 0.5 * gridSize, dotSize, 50)
			end
		end
	end
end

function drawSpecialDots()
	white()
	for i = 1, 4, 1 do
		if specialDots[i].active then
			local specialDotX = specialDots[i].x * gridSize + gridOffsetX + 0.5 * gridSize
			local specialDotY = specialDots[i].y * gridSize + gridOffsetY + 0.5 * gridSize
			love.graphics.circle("fill", specialDotX, specialDotY, dotSize * 2, 50)
		end
	end
end

function drawScore()
	love.graphics.setFont(fontScore)
	white()
	love.graphics.print("Score " .. tostring(score), gridOffsetX + (gridX - 8) * gridSize, gridOffsetY - 30)
	love.graphics.print("Level " .. tostring(level), gridOffsetX + gridSize, gridOffsetY - 30)
end

function drawLives()
	if lives > 1 then
		for i = 1, lives - 1, 1 do
			white()
			love.graphics.draw(pacmanSprites[4][2], gridOffsetX + i * 20, gridOffsetY + gridY * gridSize + 15)
		end
	end
end

function drawGame()
	drawMaze()
	drawDots()
	drawSpecialDots()
	drawScore()
	drawLives()
	drawGhosts()
	drawPacman()
end

-- FUNÇÕES UPDATE

-- MOVIMENTAÇÃO DO PACMAN

function updatePacman()
	if isUpPressed then
		pacman.nextDirection = 1
		pacman.nextDirectionText = "up"
	end
	if isDownPressed then
		pacman.nextDirection = 3
		pacman.nextDirectionText = "down"
	end
	if isLeftPressed then
		pacman.nextDirection = 4
		pacman.nextDirectionText = "left"
	end
	if isRightPressed then
		pacman.nextDirection = 2
		pacman.nextDirectionText = "right"
	end

	-- verifica se o pacman está em um túnel
	if (pacman.mapX == tunnel[1].x) and (pacman.mapY == tunnel[1].y) then
		pacman.mapX = tunnel[2].x - 1
		pacman.mapY = tunnel[2].y
		pacman.x = pacman.mapX * gridSize + gridSize * 0.5
		pacman.y = pacman.mapY * gridSize + gridSize * 0.5
	end

	if (pacman.mapX == tunnel[2].x) and (pacman.mapY == tunnel[2].y) then
		pacman.mapX = tunnel[1].x + 1
		pacman.mapY = tunnel[1].y
		pacman.x = pacman.mapX * gridSize + gridSize * 0.5
		pacman.y = pacman.mapY * gridSize + gridSize * 0.5
	end

	-- verifica se o pacman pode se mover para tal direção
	pacman.upFree = false
	pacman.downFree = false
	pacman.leftFree = false
	pacman.rightFree = false
	if map[pacman.mapX][pacman.mapY - 1] == false then
		pacman.upFree = true
	end
	if map[pacman.mapX][pacman.mapY + 1] == false then
		pacman.downFree = true
	end
	if map[pacman.mapX - 1][pacman.mapY] == false then
		pacman.leftFree = true
	end
	if map[pacman.mapX + 1][pacman.mapY] == false then
		pacman.rightFree = true
	end

	if pacman.mapY == 10 then
		if (pacman.mapX == 13) or (pacman.mapX == 14) then
			pacman.downFree = false
		end
	end

	-- verficar se o pacman está fora da sua box (manter consistente nas coordenadas)
	if pacman.x < (pacman.mapX * gridSize + gridSize) then
		pacman.mapX = pacman.mapX - 1
	end
	if pacman.x > (pacman.mapX * gridSize + gridSize) then
		pacman.mapX = pacman.mapX + 1
	end
	if pacman.y < (pacman.mapY * gridSize + gridSize) then
		pacman.mapY = pacman.mapY - 1
	end
	if pacman.y > (pacman.mapY * gridSize + gridSize) then
		pacman.mapY = pacman.mapY + 1
	end

	-- cuida se pode mover para tal direção
	pacman.movement = delta * pacman.speed
	if pacman.direction == 1 then
		if pacman.upFree then
			pacman.y = pacman.y - pacman.movement
		end
		if pacman.y > (pacman.mapY * gridSize + 0.5 * gridSize) then
			pacman.y = pacman.y - pacman.movement
		end
	end

	if pacman.direction == 3 then
		if pacman.downFree then
			pacman.y = pacman.y + pacman.movement
		end
		if pacman.y < (pacman.mapY * gridSize + 0.5 * gridSize) then
			pacman.y = pacman.y + pacman.movement
		end
	end

	if pacman.direction == 2 then
		if pacman.rightFree then
			pacman.x = pacman.x + pacman.movement
		end
		if pacman.x < (pacman.mapX * gridSize + 0.5 * gridSize) then
			pacman.x = pacman.x + pacman.movement
		end
	end

	if pacman.direction == 4 then
		if pacman.leftFree then
			pacman.x = pacman.x - pacman.movement
		end
		if pacman.x > (pacman.mapX * gridSize + 0.5 * gridSize) then
			pacman.x = pacman.x - pacman.movement
		end
	end

	-- verifica se é possível e faz a troca
	if pacman.direction ~= pacman.nextDirection then
		if (math.abs(pacman.x - (pacman.mapX * gridSize + 0.5 * gridSize)) < 2.5) and (math.abs(pacman.y - (pacman.mapY * gridSize + 0.5 * gridSize)) < 2.5) then
			if (pacman.nextDirection == 1) and pacman.upFree then
				pacmanChangeDirection()
			end
			if (pacman.nextDirection == 3) and pacman.downFree then
				pacmanChangeDirection()
			end
			if (pacman.nextDirection == 2) and pacman.rightFree then
				pacmanChangeDirection()
			end
			if (pacman.nextDirection == 4) and pacman.leftFree then
				pacmanChangeDirection()
			end
		end
	end

	-- checa se pacman está em cima de um ponto e o exclui
	if (dots[pacman.mapX][pacman.mapY] == true) then
		dots[pacman.mapX][pacman.mapY] = false
		score = score + 1
		collectedDots = collectedDots + 1
	end

	-- ^^ ponto especial
	for i = 1, 4, 1 do
		if (specialDots[i].x == pacman.mapX) and (specialDots[i].y == pacman.mapY) then
			if specialDots[i].active then
				specialDots[i].active = false
				pacman.specialDotActive = true
				score = score + 10
			end
		end
	end

	-- ativação do efeito do ponto especial
	if pacman.specialDotActive then
		if pacman.specialDotTimer > specialDotMaxTime then
			pacman.specialDotTimer = 0
			pacman.specialDotActive = false
			for i = 1, 4, 1 do
				ghosts[i].eaten = false
			end
		else
			pacman.specialDotTimer = pacman.specialDotTimer + delta
		end
	end

	-- calcula distancia e muda o sprite
	if (pacman.lastMapX > pacman.mapX) or (pacman.lastMapX < pacman.mapX) then
		pacman.lastMapX = pacman.mapX
		increasePacmanDistance()
		increasePacmanSprite()
		pacman.sameSpriteTimer = 0
	end
	if (pacman.lastMapY > pacman.mapY) or (pacman.lastMapY < pacman.mapY) then
		pacman.lastMapY = pacman.mapY
		increasePacmanDistance()
		increasePacmanSprite()
		pacman.sameSpriteTimer = 0
	end
	if (pacman.lastMapX == pacman.mapX) and (pacman.lastMapY == pacman.mapY) then
		pacman.sameSpriteTimer = pacman.sameSpriteTimer + delta
	end
	if pacman.sameSpriteTimer > 0.2 then
		pacman.sprite = 1
		pacman.spriteInc = true
	end
end

function increasePacmanDistance()
	pacman.distance = pacman.distance + 1
end

function increasePacmanSprite()
	if pacman.sprite == 3 then
		pacman.spriteInc = false
	end
	if pacman.sprite == 1 then
		pacman.spriteInc = true
	end
	if pacman.spriteInc then
		pacman.sprite = pacman.sprite + 1
	end
	if pacman.spriteInc == false then
		pacman.sprite = pacman.sprite - 1
	end
end

-- por fim muda a direção do pacman
function pacmanChangeDirection()
	pacman.direction = pacman.nextDirection
	pacman.directionText = pacman.nextDirectionText
	pacman.x = pacman.mapX * gridSize + gridSize * 0.5
	pacman.y = pacman.mapY * gridSize + gridSize * 0.5
end

-- MOVIMENTO DOS GHOSTS

function updateGhosts()
	for i = 1, 4, 1 do
		if pacman.specialDotActive == false then
			ghosts[i].speed = ghosts[i].normSpeed
			if (ghosts[i].mapX == pacman.mapX) and (ghosts[i].mapY == pacman.mapY) then
				lives = lives - 1
				gameMode = "getReady"
				getReadyTimer = 0
				resetPacmanPosition()
				resetGhostsPosition()
			end
		end

		-- podem morrer com o efeito do ponto especial ativado
		if pacman.specialDotActive then
			ghosts[i].speed = ghosts[i].slowSpeed
			if (ghosts[i].mapX == pacman.mapX) and (ghosts[i].mapY == pacman.mapY) then
				if ghosts[i].eaten == false then
					ghosts[i].eaten = true
				end
			end
		end

		-- verifica se tal direção é possível
		ghosts[i].upFree = false
		ghosts[i].downFree = false
		ghosts[i].leftFree = false
		ghosts[i].rightFree = false
		if map[ghosts[i].mapX][ghosts[i].mapY - 1] == false then
			ghosts[i].upFree = true
		end
		if map[ghosts[i].mapX][ghosts[i].mapY + 1] == false then
			ghosts[i].downFree = true
		end
		if map[ghosts[i].mapX - 1][ghosts[i].mapY] == false then
			ghosts[i].leftFree = true
		end
		if map[ghosts[i].mapX + 1][ghosts[i].mapY] == false then
			ghosts[i].rightFree = true
		end

		if (ghosts[i].mapX == 21) and (ghosts[i].mapY == 13) then
			ghosts[i].rightFree = false
		end

		if (ghosts[i].mapX == 6) and (ghosts[i].mapY == 13) then
			ghosts[i].leftFree = false
		end

		if ghosts[i].mapY == 10 then
			if (ghosts[i].mapX == 13) or (ghosts[i].mapX == 14) then
				ghosts[i].downFree = false
			end
		end

		-- verficar se o ghost está fora da sua box (manter consistente nas coordenadas)
		if ghosts[i].x < (ghosts[i].mapX * gridSize + gridSize) then
			ghosts[i].mapX = ghosts[i].mapX - 1
		end
		if ghosts[i].x > (ghosts[i].mapX * gridSize + gridSize) then
			ghosts[i].mapX = ghosts[i].mapX + 1
		end
		if ghosts[i].y < (ghosts[i].mapY * gridSize + gridSize) then
			ghosts[i].mapY = ghosts[i].mapY - 1
		end
		if ghosts[i].y > (ghosts[i].mapY * gridSize + gridSize) then
			ghosts[i].mapY = ghosts[i].mapY + 1
		end

		-- chama a função movimentação do GHOST
		if gameTimer > 4 then
			moveGhosts(i)
		else
			if i < 3 then
				moveGhosts(i)
			end
		end
		
		-- se o GHOST está se movendo em uma direção onde o caminho está bloqueado, ele mudará para uma nova direção aleatória
		local ghostXdistance = math.abs(ghosts[i].x - (ghosts[i].mapX * gridSize + 0.5 * gridSize))
		local ghostYdistance = math.abs(ghosts[i].y - (ghosts[i].mapY * gridSize + 0.5 * gridSize))
		if (ghostXdistance < 2.5) and (ghostYdistance < 2.5) then
			if (ghosts[i].direction == 1) and (ghosts[i].upFree == false) then
				randomGhostNexDirection(i)
				ghostsChangeDirection(i)
			end
			if (ghosts[i].direction == 3) and (ghosts[i].downFree == false) then
				randomGhostNexDirection(i)
				ghostsChangeDirection(i)
			end
			if (ghosts[i].direction == 4) and (ghosts[i].leftFree == false) then
				randomGhostNexDirection(i)
				ghostsChangeDirection(i)
			end
			if (ghosts[i].direction == 2) and (ghosts[i].rightFree == false) then
				randomGhostNexDirection(i)
				ghostsChangeDirection(i)
			end
		end
	end
end

-- randomiza a direção do GHOST
function randomGhostNexDirection(ghost)
	local nextDirection
	local forbiddenDirection
	if ghosts[ghost].direction == 1 then
		forbiddenDirection = 3
	end
	if ghosts[ghost].direction == 2 then
		forbiddenDirection = 4
	end
	if ghosts[ghost].direction == 3 then
		forbiddenDirection = 1
	end
	if ghosts[ghost].direction == 4 then
		forbiddenDirection = 2
	end
	repeat
		nextDirection = math.random(1, 4)
	until (nextDirection ~= ghosts[ghost].nextDirection) and (nextDirection ~= forbiddenDirection)
	ghosts[ghost].nextDirection = nextDirection
end

-- movimentação do GHOST
function moveGhosts(ghost)
	local movement = ghosts[ghost].speed * delta
	if ghosts[ghost].direction == 1 then
		if ghosts[ghost].upFree then
			ghosts[ghost].y = ghosts[ghost].y - movement
		end
		if ghosts[ghost].y > (ghosts[ghost].mapY * gridSize + 0.5 * gridSize) then
			ghosts[ghost].y = ghosts[ghost].y - movement
		end
	end
	if ghosts[ghost].direction == 3 then
		if ghosts[ghost].downFree then
			ghosts[ghost].y = ghosts[ghost].y + movement
		end
		if ghosts[ghost].y < (ghosts[ghost].mapY * gridSize + 0.5 * gridSize) then
			ghosts[ghost].y = ghosts[ghost].y + movement
		end
	end
	if ghosts[ghost].direction == 2 then
		if ghosts[ghost].rightFree then
			ghosts[ghost].x = ghosts[ghost].x + movement
		end
		if ghosts[ghost].x < (ghosts[ghost].mapX * gridSize + 0.5 * gridSize) then
			ghosts[ghost].x = ghosts[ghost].x + movement
		end
	end
	if ghosts[ghost].direction == 4 then
		if ghosts[ghost].leftFree then
			ghosts[ghost].x = ghosts[ghost].x - movement
		end
		if ghosts[ghost].x > (ghosts[ghost].mapX * gridSize + 0.5 * gridSize) then
			ghosts[ghost].x = ghosts[ghost].x - movement
		end
	end
end

function ghostsChangeDirection(ghost)
	ghosts[ghost].direction = ghosts[ghost].nextDirection
	ghosts[ghost].x = ghosts[ghost].mapX * gridSize + gridSize * 0.5
	ghosts[ghost].y = ghosts[ghost].mapY * gridSize + gridSize * 0.5
end

-- FUNÇÃO DE AVANÇAR DE NIVEL (AUMENTA A SPEED)
function nextLevel()
	collectedDots = 0
	level = level + 1
	resetPacmanPosition()
	resetGhostsPosition()
	initMap()
	gameMode = "getReady"
	for i = 1, 4, 1 do
		ghosts[i].normSpeed = ghosts[i].normSpeed + 10
		ghosts[i].slowSpeed = ghosts[i].slowSpeed + 5
	end
	pacman.speed = pacman.speed + 2
	specialDotMaxTime = specialDotMaxTime - 0.5
end

function updateGame()
	menuTimerWait()
	if isEscPressed then
		if menuEnabled then
			love.event.push('quit')
		end
	end
	updatePacman()
	updateGhosts()
	menuTimerAdd()
	gameTimer = gameTimer + delta
	if lives == 0 then
		gameMode = "gameOver"
	end
	if collectedDots == 236 then
		nextLevel()
	end
end

-- aparecer para se preparar (e o timer) antes de começar
function drawGetReady()
	drawGame()
	white()
	love.graphics.setFont(fontScore)
	love.graphics.print("GET READY!", gridOffsetX + 270, gridOffsetY + 420)
end

function drawGameOver()
	pauseOffsetX = (resolution[activeResolution].x - pauseSizeX) / 2
	pauseOffsetY = (resolution[activeResolution].y - pauseSizeY) / 2
	drawGame()

	-- escurece a tela -> destacar o gameover
	love.graphics.setColor(0, 0, 0, 100)
	love.graphics.rectangle("fill", 0, 0, resolution[activeResolution].x, resolution[activeResolution].y)

	red()
	love.graphics.rectangle("fill", pauseOffsetX - 1, pauseOffsetY - 1, pauseSizeX + 2, pauseSizeY + 2)

	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.rectangle("fill", pauseOffsetX, pauseOffsetY, pauseSizeX, pauseSizeY)

	white()
	love.graphics.setFont(fontMedium)
	local textGameOver = "GAME OVER"
	local textWidth = fontMedium:getWidth(textGameOver)
	love.graphics.print(textGameOver, pauseOffsetX + (pauseSizeX - textWidth) / 2, pauseOffsetY + 50)

	love.graphics.setFont(fontSmall)
	local textInstruction = "Press SPACE to return to menu"
	local instructionWidth = fontSmall:getWidth(textInstruction)
	love.graphics.print(textInstruction, pauseOffsetX + (pauseSizeX - instructionWidth) / 2, pauseOffsetY + 130)

	local textQuit = "Press ESC to quit the game"
	local quitWidth = fontSmall:getWidth(textQuit)
	love.graphics.print(textQuit, pauseOffsetX + (pauseSizeX - quitWidth) / 2, pauseOffsetY + 160)
end

--[[
FUNÇÕES UPDATE
]]

function updateGameOver()
	if isSpacePressed then
		gameMode = "menu"
		menuMode = "main"
		menuPositions = 3
		resetMenu()
	end

	if love.keyboard.isDown("escape") then
		love.event.quit()
	end
end

function updateGetReady()
	getReadyTimer = getReadyTimer + delta
	if getReadyTimer > 2.5 then
		gameMode = "game"
		getReadyTimer = 0
	end
end

--[[
FUNÇÕES LUA
]]

function love.load()
	loadStuff()
	gameMode = "menu"
	menuMode = "main"
end

function love.draw()
	if gameMode == "menu" then
		drawMenu()
	end
	if gameMode == "game" then
		drawGame()
	end
	if gameMode == "getReady" then
		drawGetReady()
	end
	if gameMode == "gameOver" then
		drawGameOver()
	end
end

function love.update(dt)
	delta = dt
	if gameMode == "menu" then
		updateMenu()
	end
	if gameMode == "game" then
		updateGame()
	end
	if gameMode == "getReady" then
		updateGetReady()
	end
	if gameMode == "gameOver" then
		updateGameOver()
	end
end

function love.focus(bool)
end

function love.keypressed(key, unicode)
	if key == "escape" then
		isEscPressed = true
	end
	if key == " " then
		isSpacePressed = true
	end
	if key == "return" then
		isEnterPressed = true
	end
	if key == "up" then
		isUpPressed = true
	end
	if key == "down" then
		isDownPressed = true
	end
	if key == "left" then
		isLeftPressed = true
	end
	if key == "right" then
		isRightPressed = true
	end
end

function love.keyreleased(key, unicode)
	if key == "escape" then
		isEscPressed = false
	end
	if key == " " then
		isSpacePressed = false
	end
	if key == "return" then
		isEnterPressed = false
	end
	if key == "up" then
		isUpPressed = false
	end
	if key == "down" then
		isDownPressed = false
	end
	if key == "left" then
		isLeftPressed = false
	end
	if key == "right" then
		isRightPressed = false
	end
end