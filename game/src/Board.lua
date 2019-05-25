
local class = require 'middleclass'

-- アプリケーション
local Board = class 'Board'

-- ムーア近傍
local mooreNeighborhood = {
    { -1, -1 },
    {  0, -1 },
    {  1, -1 },
    { -1,  0 },
    {  1,  0 },
    { -1,  1 },
    {  0,  1 },
    {  1,  1 },
}

-- ルール
local rules = {
    -- Conway's Game of Life
    life = {
        --              0,     1,     2,     3,     4,     5,     6,     7      8
        birth   = { false, false, false,  true, false, false, false, false, false,  },
        survive = { false, false,  true,  true, false, false, false, false, false,  }
    },
}

-- 初期化
function Board:initialize(width, height, scale)
    -- リサイズ処理
    self:resize(width, height, scale)

    -- セル
    self.cells = {}

    -- ルール
    self.rule = rules.life

    -- オフセット
    self.offsets = { 0, 0 }
    self:setOffset(0, 0)

    -- その他
    self.interval = 0
    self.wait = self.interval
    self.pause = false
end

-- 更新
function Board:update(dt, ...)
    if self.pause then
        -- ポーズ中
    else
        -- 時間経過
        self.wait = self.wait - dt

        -- インターバルを超えて時間が経過したらその分ステップ
        while self.wait < 0 do
            -- ステップ
            self:step()

            -- インターバルの追加
            if self.interval > 0 then
                self.wait = self.wait + self.interval
            else
                -- インターバルなしなら終わり
                self.wait = self.interval
                break
            end
        end
    end
end

-- 描画
function Board:draw(...)
    love.graphics.push()
    love.graphics.translate(self.offsets[1], self.offsets[2])
    love.graphics.scale(self.scale)
    love.graphics.draw(self.canvas, self.quad)
    love.graphics.pop()
end

-- ポーズ切り替え
function Board:togglePause()
    self.pause = not self.pause
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
    self.quad = love.graphics.newQuad(0, 0, sw / self.scale + self.width, sh / self.scale + self.height, self.width, self.height)
end

-- リスケール
function Board:rescale(scale)
    self.scale = scale or self.scale or 1

    -- 矩形のサイズ変更
    local sw, sh = love.graphics.getDimensions()
    self.quad:setViewport(0, 0, (sw) / self.scale + self.width, (sh) / self.scale + self.height)

    -- オフセットの再設定
    self:setOffset(self.offsets[1], self.offsets[2])
end

-- オフセットの設定
function Board:setOffset(x, y)
    local sw, sh = self.width * self.scale, self.height * self.scale
    self.offsets[1], self.offsets[2] = ((x) % sw) - sw, ((y) % sh) - sh
end

-- 座標のループ
function Board:clampPositions(x, y)
    return ((x - 1) % self.width) + 1, ((y - 1) % self.height) + 1
end

-- ローカル座標へ変換
function Board:toLocalPositions(x, y)
    return self:clampPositions(math.ceil(x / self.scale), math.ceil(y / self.scale))
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

-- セルをランダム配置
function Board:resetRandomizeCells()
    self.cells = {}

    for x = 1, self.width do
        for y = 1, self.height do
            if love.math.random(2) == 1 then
                self:setCell(x, y, {})
            end
        end
    end
end

-- セルを描画
function Board:renderCell(x, y)
    self:renderTo(
        function ()
            if self:getCell(x, y) then
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.setColor(0, 0, 0)
            end
            love.graphics.points(x, y)
        end
    )
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

-- 候補者としてエントリー
function Board:entryCandidates(x, y, neighbor, candidates)
    if candidates[x] == nil then
        candidates[x] = {}
    end
    if candidates[x][y] == nil then
        candidates[x][y] = { neighbors = { neighbor } }
    else
        table.insert(candidates[x][y].neighbors, neighbor)
    end
end

-- 次の世代としてエントリー
function Board:entryNextGeneration(x, y, cell, nextGenerations)
    if nextGenerations[x] == nil then
        nextGenerations[x] = {}
    end
    nextGenerations[x][y] = cell
end

-- セルのチェック
function Board:checkCell(x, y, target, candidates)
    x, y = self:clampPositions(x, y)
    local cell = self:getCell(x, y)
    if cell == nil then
        -- 見つからなければ次世代候補にする
        self:entryCandidates(x, y, target, candidates)
    else
        return cell
    end
end

-- セルが生き残るかどうか
function Board:checkSurvive(cell, count)
    return self.rule.survive[count + 1] == true
end

-- セルが誕生するかどうか
function Board:checkBirth(count)
    return self.rule.birth[count + 1] == true
end

-- 次の世代へ進む
function Board:step()
    -- 誕生候補
    local candidates = {}

    -- 誕生
    local births = {}

    -- 死亡
    local deaths = {}

    -- 次の世代
    local nextGenerations = {}

    -- 生存しているセルをチェック
    for x, column in pairs(self.cells) do
        for y, cell in pairs(column) do
            local count = 0
            for _, pos in ipairs(mooreNeighborhood) do
                if self:checkCell(x + pos[1], y + pos[2], cell, candidates) then
                    count = count + 1
                end
            end
            if self:checkSurvive(cell, count) then
                -- 生き残る
                self:entryNextGeneration(x, y, cell, nextGenerations)
            else
                -- 死ぬ
                table.insert(deaths, x)
                table.insert(deaths, y)
            end
        end
    end

    -- 誕生するかチェック
    for x, column in pairs(candidates) do
        for y, candidate in pairs(column) do
            if self:checkBirth(#candidate.neighbors) then
                -- 生まれる
                table.insert(births, x)
                table.insert(births, y)
                self:entryNextGeneration(x, y, {}, nextGenerations)
            end
        end
    end

    -- 死者と誕生者を描画
    self:renderTo(
        function ()
            love.graphics.setColor(0, 0, 0)
            love.graphics.points(deaths)
            love.graphics.setColor(1, 1, 1)
            love.graphics.points(births)
        end
    )

    -- 次の世代へ差し替える
    self.cells = nextGenerations
end

return Board
