
local class = require 'middleclass'

-- アプリケーション
local Application = require 'Application'

-- ゲーム
local Game = class('Game', Application)

-- 初期化
function Game:initialize(...)
    Application.initialize(self, ...)
end

-- 読み込み
function Game:load(...)
end

-- 更新
function Game:update(dt, ...)
end

-- 描画
function Game:draw(...)
end

-- キー入力
function Game:keypressed(key, scancode, isrepeat)
end

-- マウス入力
function Game:mousepressed(x, y, button, istouch, presses)
end

-- リサイズ
function Game:resize(width, height)
end

return Game
