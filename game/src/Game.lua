
local class = require 'middleclass'

-- クラス
local Application = require 'Application'
local Board = require 'Board'

-- ゲーム
local Game = class('Game', Application)

-- 初期化
function Game:initialize(...)
    Application.initialize(self, ...)
end

-- 読み込み
function Game:load(...)
    self.width, self.height = love.graphics.getDimensions()
    self.board = Board(100, 100)
end

-- 更新
function Game:update(dt, ...)
    self.board:update(dt)
end

-- 描画
function Game:draw(...)
    self.board:draw()
end

-- キー入力
function Game:keypressed(key, scancode, isrepeat)
end

-- マウス入力
function Game:mousepressed(x, y, button, istouch, presses)
end

-- リサイズ
function Game:resize(width, height)
    self.width, self.height = width, height
end

return Game
