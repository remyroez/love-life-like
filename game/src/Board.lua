
local class = require 'middleclass'

-- アプリケーション
local Board = class 'Board'

-- 初期化
function Board:initialize(width, height)
    -- 幅と高さが未指定なら、ウィンドウと同じにする
    local sw, sh = love.graphics.getDimensions()
    self.width = width or sw
    self.height = height or sh

    -- キャンバスの作成
    self.canvas = love.graphics.newCanvas(self.width, self.height)
    self.canvas:setFilter('nearest', 'nearest')
    self.canvas:setWrap('repeat', 'repeat')

    self:renderTo(
        function ()
            love.graphics.setColor(1, 0, 0)
            love.graphics.line(0, 0, self.width, self.height)
        end
    )

    -- 矩形の作成
    self.quad = love.graphics.newQuad(0, 0, sw, sh, self.width, self.height)

    -- セル
    self.cells = {}

    -- その他
    self.scale = 1
end

-- 更新
function Board:update(dt, ...)
end

-- 描画
function Board:draw(...)
    love.graphics.push()
    love.graphics.scale(self.scale)
    love.graphics.draw(self.canvas, self.quad)
    love.graphics.pop()
end

-- キャンバスへ描画
function Board:renderTo(...)
    self.canvas:renderTo(...)
end

return Board
