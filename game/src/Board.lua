
local class = require 'middleclass'

-- アプリケーション
local Board = class 'Board'

-- HSV カラーを RGB カラーに変換
local function hsv(h, s, v)
    if s <= 0 then return v, v, v end
    h, s, v = h * 6, s, v
    local c = v * s
    local x = (1 - math.abs((h % 2) - 1)) * c
    local m, r, g, b = (v - c), 0, 0, 0
    if h < 1     then r, g, b = c, x, 0
    elseif h < 2 then r, g, b = x, c, 0
    elseif h < 3 then r, g, b = 0, c, x
    elseif h < 4 then r, g, b = 0, x, c
    elseif h < 5 then r, g, b = x, 0, c
    else              r, g, b = c, 0, x
    end return (r + m), (g + m), (b + m)
end

-- ディープコピー
local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        -- tableなら再帰でコピー
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        -- number, string, booleanなどはそのままコピー
        copy = orig
    end
    return copy
end

-- ランダム
local random = love.math.random

-- ランダム真偽値
local function randomBool()
    return random(2) == 1
end

-- 新ルール
Board.static.newRule = function(randomize)
    return randomize and {
        --              0,     1,     2,     3,     4,     5,     6,     7      8
        birth   = { false, randomBool(), randomBool(), randomBool(), randomBool(), randomBool(), randomBool(), randomBool(), randomBool(), },
        survive = { randomBool(), randomBool(), randomBool(), randomBool(), randomBool(), randomBool(), randomBool(), randomBool(), randomBool(), }
    } or {
        --              0,     1,     2,     3,     4,     5,     6,     7      8
        birth   = { false, false, false, false, false, false, false, false, false, },
        survive = { false, false, false, false, false, false, false, false, false, }
    }
end

-- ルールを文字列化
Board.static.ruleToString = function(rule)
    local buffer = 'B'

    for i, bool in ipairs(rule.birth) do
        if bool then
            buffer = buffer .. tostring(i - 1)
        end
    end

    buffer = buffer .. '/S'

    for i, bool in ipairs(rule.survive) do
        if bool then
            buffer = buffer .. tostring(i - 1)
        end
    end

    return buffer
end

-- ルールを文字列化
Board.static.stringToRule = function(str)
    str = str or 'B/S'

    local rule = Board.newRule()

    local target = 'birth'
    for i = 1, string.len(str) do
        local c = string.sub(str, i, i)
        if c == 'B' then
            target = 'birth'
        elseif c == 'S' then
            target = 'survive'
        else
            local n = tonumber(c)
            if n then
                rule[target][n + 1] = true
            end
        end
    end

    return rule
end

-- ムーア近傍
Board.static.mooreNeighborhood = {
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
Board.static.rules = {
    -- Conway's Game of Life (B3/S23)
    life = Board.static.stringToRule 'B3/S23',
    -- HighLife (B36/S23)
    highLife = Board.static.stringToRule 'B36/S23',
    -- Maze (B3/S12345)
    maze = Board.static.stringToRule 'B3/S12345',
    -- Mazectric (B3/S1234)
    mazectric = Board.static.stringToRule 'B3/S1234',
    -- Replicator (B1357/S1357)
    replicator = Board.static.stringToRule 'B1357/S1357',
    -- Seeds (B2/S)
    seeds = Board.static.stringToRule 'B2/S',
    -- Life without death (B3/S012345678)
    lifeWithoutDeath = Board.static.stringToRule 'B3/S012345678',
    -- Bugs (B3567/S15678)
    bugs = Board.static.stringToRule 'B3567/S15678',
    -- 2x2 (B36/S125)
    _2x2 = Board.static.stringToRule 'B36/S125',
    -- Stains (B3678/S235678)
    stains = Board.static.stringToRule 'B3678/S235678',
    -- Day & Night (B3678/S34678)
    dayAndNight = Board.static.stringToRule 'B3678/S34678',
}

-- 初期化
function Board:initialize(args)
    args = type(args) == 'table' and args or {}

    -- カラー
    self.colors = args.colors or {
        death = { 0, 0, 0 },
        live = { 1, 1, 1 },
    }

    -- リサイズ処理
    self:resize(args.width, args.height, args.scale)

    -- セル
    self.cells = args.cells or {}

    -- ルール
    self.rule = args.rule or Board.rules.life

    -- オフセット
    self.offset = { x = 0, y = 0 }
    self:setOffset(0, 0)

    -- その他
    self.interval = args.interval or 0
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
    love.graphics.translate(self.offset.x, self.offset.y)
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
    self:setOffset(self.offset.x, self.offset.y)
end

-- オフセットの設定
function Board:setOffset(x, y)
    local sw, sh = self.width * self.scale, self.height * self.scale
    self.offset.x, self.offset.y = (x % sw) - sw, (y % sh) - sh
end

-- 座標のループ
function Board:clampPositions(x, y)
    return ((x - 1) % self.width) + 1, ((y - 1) % self.height) + 1
end

-- ローカル座標へ変換
function Board:toLocalPositions(x, y)
    x, y = x - self.offset.x, y - self.offset.y
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

-- セルの設定
function Board:newCell(args)
    args = args or {}

    -- 遺伝
    local rule
    local color
    if args.neighbors then
        neighbors = args.neighbors
        rule = deepcopy(neighbors[love.math.random(#neighbors)].rule)
        color = deepcopy(neighbors[love.math.random(#neighbors)].color)
        color.hsv[2] = 1
    end

    -- 新規
    return {
        rule = rule or args.rule or self.rule,
        color = color or args.color or { hsv = { 0, 0, 1 } },
        age = 0,
    }
end

-- セルをリセット
function Board:resetCells(cells)
    self.cells = cells or {}
end

-- セルをランダム配置
function Board:resetRandomizeCells(randomColor)
    randomColor = randomColor == nil and true or randomColor

    self.cells = {}

    for x = 1, self.width do
        for y = 1, self.height do
            if randomBool() then
                self:setCell(
                    x,
                    y,
                    self:newCell{
                        color = randomColor and { hsv = { love.math.random(), 1, 1 } } or self.colors.live
                    }
                )
            end
        end
    end
end

-- セルを描画
function Board:renderCell(x, y)
    self:renderTo(
        function ()
            local cell = self:getCell(x, y)
            if cell then
                love.graphics.setColor(self:getColor(cell.color or self.colors.live))
            else
                love.graphics.setColor(self:getColor(self.colors.death))
            end
            love.graphics.points(x, y)
        end
    )
end

-- セルをすべて描画
function Board:renderAllCells()
    self:renderTo(
        function ()
            love.graphics.clear(self:getColor(self.colors.death))
            local points = {}
            local cell = nil
            for x = 1, self.width do
                for y = 1, self.height do
                    cell = self:getCell(x, y)
                    if cell then
                        love.graphics.setColor(self:getColor(cell.color or self.colors.live))
                    else
                        love.graphics.setColor(self:getColor(self.colors.death))
                    end
                    love.graphics.points(x, y)
                end
            end
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
    return cell
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
function Board:checkSurvive(count, rule)
    return (rule or self.rule).survive[count + 1] == true
end

-- セルが誕生するかどうか
function Board:checkBirth(count, rule)
    return (rule or self.rule).birth[count + 1] == true
end

-- 色の取得
function Board:getColor(color)
    if color[1] then
        return color
    elseif color.rgb then
        return color.rgb
    elseif color.hsv then
        return hsv(unpack(color.hsv))
    end
end

-- 次の世代へ進む
function Board:step()
    -- 誕生候補
    local candidates = {}

    -- 死亡
    local deaths = {}

    -- 次の世代
    local nextGenerations = {}

    -- 生存しているセルをチェック
    for x, column in pairs(self.cells) do
        for y, cell in pairs(column) do
            local count = 0
            for _, pos in ipairs(Board.mooreNeighborhood) do
                if self:checkCell(x + pos[1], y + pos[2], cell, candidates) then
                    count = count + 1
                end
            end
            if self:checkSurvive(count, cell.rule) then
                -- 生き残る
                cell.age = cell.age + 1
                --[[
                if cell.color.hsv[2] > 0.25 then
                    cell.color.hsv[2] = cell.color.hsv[2] - 0.001
                end
                --]]
                self:entryNextGeneration(x, y, cell, nextGenerations)
                --[[
                self:renderTo(
                    function ()
                        love.graphics.setColor(self:getColor(cell.color or self.colors.live))
                        love.graphics.points(x, y)
                    end
                )
                --]]--
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
                local cell = self:entryNextGeneration(x, y, self:newCell{ color = color, neighbors = candidate.neighbors }, nextGenerations)
                self:renderTo(
                    function ()
                        love.graphics.setColor(self:getColor(cell.color or self.colors.live))
                        love.graphics.points(x, y)
                    end
                )
            end
        end
    end

    -- 死者と誕生者を描画
    self:renderTo(
        function ()
            love.graphics.setColor(self:getColor(self.colors.death))
            love.graphics.points(deaths)
        end
    )

    -- 次の世代へ差し替える
    self.cells = nextGenerations
end

return Board
