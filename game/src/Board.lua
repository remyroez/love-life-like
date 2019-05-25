
local class = require 'middleclass'

-- アプリケーション
local Board = class 'Board'

-- 初期化
function Board:initialize(width, height, scale)
    -- リサイズ処理
    self:resize(width, height, scale)

    -- セル
    self.cells = {}

    -- その他
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

-- リサイズ
function Board:resize(width, height, scale)
    -- サイズが未指定なら、ウィンドウサイズ
    local sw, sh = love.graphics.getDimensions()
    self.width = width or self.width or sw
    self.height = height or self.height or sh
    self.scale = scale or self.scale or 1

    -- キャンバスの作成
    self.canvas = love.graphics.newCanvas(self.width, self.height)
    self.canvas:setFilter('nearest', 'nearest')
    self.canvas:setWrap('repeat', 'repeat')

    -- 矩形の作成
    self.quad = love.graphics.newQuad(0, 0, sw / self.scale, sh / self.scale, self.width, self.height)
end

-- リスケール
function Board:rescale(scale)
    self.scale = scale or self.scale or 1

    -- 矩形のサイズ変更
    local sw, sh = love.graphics.getDimensions()
    self.quad:setViewport(0, 0, sw / self.scale, sh / self.scale)
end

-- ローカル座標へ変換
function Board:toLocalPosition(x, y)
    return x % self.width, y % self.height
end

-- セルの取得
function Board:getCell(x, y)
    return self.cells[x] and self.cells[x][y] or nil
end

-- セルの設定
function Board:setCell(x, y, cell)
    if self.cells[x] == nil then
        self.cells[x] = {}
    end
    self.cells[x][y] = cell
    return self.cells[x][y]
end

-- セルをすべて描画
function Board:renderAllCells()
    self:renderTo(
        function ()
            love.graphics.clear()
            local points = {}
            for x = 1, self.width do
                for y = 1, self.height do
                    if self:getCell(x, y) then
                        table.insert(points, x)
                        table.insert(points, y)
                    end
                end
            end
            love.graphics.setColor(1, 1, 1)
            love.graphics.points(points)
        end
    )
end

return Board
