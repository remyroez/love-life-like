
local class = require 'middleclass'
local fblove = require 'fblove_strip'

-- アプリケーション
local Board = class 'Board'

-- HSV カラーを RGB カラーに変換
local function hsv2rgb(h, s, v)
    if s <= 0 then return v, v, v end
    h, s, v = (h or 0) * 6, (s or 1), (v or 1)
    local c = v * s
    local x = (1 - math.abs((h % 2) - 1)) * c
    local m, r, g, b = (v - c), 0, 0, 0
    if h < 1     then r, g, b = c, x, 0
    elseif h < 2 then r, g, b = x, c, 0
    elseif h < 3 then r, g, b = 0, c, x
    elseif h < 4 then r, g, b = 0, x, c
    elseif h < 5 then r, g, b = x, 0, c
    else              r, g, b = c, 0, x
    end
    return (r + m), (g + m), (b + m)
end

-- RGB カラーを HSV カラーに変換
local function rgb2hsv(r, g, b)
    r, g, b = r or 0, g or 0, b or 0
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, v
    v = max

    local d = max - min
    if max == 0 then s = 0 else s = d / max end

    if max == min then
      h = 0 -- achromatic
    else
      if max == r then
      h = (g - b) / d
      if g < b then h = h + 6 end
      elseif max == g then h = (b - r) / d + 2
      elseif max == b then h = (r - g) / d + 4
      end
      h = h / 6
    end

    return h, s, v
end

-- RGB カラーをビット変換
local function rgb2bit(r, g, b, a)
    r = r or 1
    g = g or 1
    b = b or 1
    a = a or 1

    return bit.bor(
        bit.lshift(math.floor(a * 255), 24),
        bit.lshift(math.floor(r * 255), 16),
        bit.lshift(math.floor(g * 255), 8),
        math.floor(b * 255)
    )
end

-- 任意の数の RGB カラーをブレンド
local function blendRGB(...)
    local rgb = { 0, 0, 0 }

    local n = select("#", ...)
    for i = 1, n do
        local color = select(i, ...)
        for j, elm in ipairs(rgb) do
            rgb[j] = rgb[j] + color[j]
        end
    end

    rgb[1] = math.min(rgb[1] / n, 1)
    rgb[2] = math.min(rgb[2] / n, 1)
    rgb[3] = math.min(rgb[3] / n, 1)

    return rgb
end

-- 任意の数の HSV カラーをブレンド
local function blendHSV(...)
    local rgbs = {}

    local n = select("#", ...)
    for i = 1, n do
        local color = select(i, ...)
        table.insert(rgbs, { hsv2rgb(color[1], color[2], color[3]) })
    end

    local rgb = blendRGB(unpack(rgbs))

    return { rgb2hsv(rgb[1], rgb[2], rgb[3]) }
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

-- 新HSVカラー
Board.static.newHSVColor = function(h, s, v)
    return { hsv = { h or 0, s or 1, v or 1 } }
end

-- 新カラー
Board.static.newColor = function(randomize)
    return randomize and Board.newHSVColor(love.math.random(), 1, 1) or Board.newHSVColor(1, 0, 1)
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

-- ルールが一致しているか判定
Board.static.checkRules = function(rules)
    local checked = { 'any', 'any', 'any', 'any', 'any', 'any', 'any', 'any', 'any' }
    local sameIndice = {}

    -- 先頭ルールをベースにする
    local base = rules[1]
    for i = 1, #checked do
        -- 先頭ルールのフラグをベースにする
        checked[i] = tostring(base[i])

        -- ベースフラグと一致しなかったら any
        for j, rule in ipairs(rules) do
            if j > 1 then
                if rule[i] ~= base[i] then
                    checked[i] = 'any'
                    break
                end
            end
        end
        if checked[i] ~= 'any' then
            table.insert(sameIndice, i)
        end
    end

    return checked, sameIndice
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
    -- Conway's Game of Life
    life = Board.static.stringToRule 'B3/S23',
    -- HighLife
    highLife = Board.static.stringToRule 'B36/S23',
    -- Maze
    maze = Board.static.stringToRule 'B3/S12345',
    -- Mazectric
    mazectric = Board.static.stringToRule 'B3/S1234',
    -- Replicator
    replicator = Board.static.stringToRule 'B1357/S1357',
    -- Seeds
    seeds = Board.static.stringToRule 'B2/S',
    -- Life without death
    lifeWithoutDeath = Board.static.stringToRule 'B3/S012345678',
    -- Bugs
    bugs = Board.static.stringToRule 'B3567/S15678',
    -- 2x2
    _2x2 = Board.static.stringToRule 'B36/S125',
    -- Stains
    stains = Board.static.stringToRule 'B3678/S235678',
    -- Day & Night
    dayAndNight = Board.static.stringToRule 'B3678/S34678',
    -- Bacteria
    bacteria = Board.static.stringToRule 'B34/S456',
    -- Diamoeba
    diamoeba = Board.static.stringToRule 'B35678/S5678',
}

-- 初期化
function Board:initialize(args)
    args = type(args) == 'table' and args or {}

    -- カラー
    self.colors = args.colors or {
        death = { 0, 0, 0 },
        live = { 1, 1, 1 },
    }

    -- フレームバッファ
    local sw, sh = love.graphics.getDimensions()
    self.fb = fblove(args.width or sw, args.height or sh)

    -- リサイズ処理
    self:resize(args.width, args.height, args.scale)

    -- セル
    self.cells = args.cells or {}

    -- ルール
    self.rule = args.rule or Board.rules.life

    -- オフセット
    self.offset = { x = 0, y = 0 }
    self:setOffset(0, 0)

    -- 遺伝オプション
    self.option = args.option or {}
    self.option.crossoverRule = args.option.crossoverRule == nil and true or args.option.crossoverRule
    self.option.crossoverColor = args.option.crossoverColor == nil and true or args.option.crossoverColor
    self.option.crossoverRate = args.option.mutationRate or 0.001
    self.option.mutationRate = args.option.mutationRate or 0.001
    self.option.mutation = args.option.mutation == nil and true or args.option.mutation
    self.option.aging = args.option.aging ~= nil and args.option.aging or false
    self.option.agingColor = args.option.agingColor ~= nil and args.option.agingColor or false
    self.option.agingDeath = args.option.agingDeath ~= nil and args.option.agingDeath or false
    self.option.lifespan = args.option.lifespan or 1000
    self.option.lifespanRandom = args.option.lifespanRandom ~= nil and args.option.lifespanRandom or false
    self.option.lifeSaturation = args.option.lifeSaturation or 0.75

    -- その他
    self.minLifeSaturation = 1 - self.option.lifeSaturation
    self.lifeSaturationUnit = 1 / self.option.lifespan
    self.interval = args.interval or 0
    self.wait = self.interval
    self.pause = args.pause ~= nil and args.pause or false
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
function Board:renderTo(fn)
    --self.canvas:renderTo(...)
    fn(self)
end

-- フレームバッファ更新
function Board:refresh()
    self.fb.refresh()
end

-- リサイズ
function Board:resize(width, height, scale)
    -- サイズが未指定なら、ウィンドウサイズ
    local sw, sh = love.graphics.getDimensions()
    self.width = width or self.width or sw
    self.height = height or self.height or sh
    self.scale = scale or self.scale or 1

    -- キャンバスの作成
    self.fb.reinit(self.width, self.height)
    self.fb.setbg(rgb2bit(unpack(self:getColor(self.colors.death))))
    self.canvas = self.fb.get()
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
    self.quad:setViewport(0, 0, sw / self.scale + self.width, sh / self.scale + self.height)

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
    if args.parents then
        rule, color = self:crossover(args.parents)
    end

    -- 新規
    return {
        rule = rule or args.rule or self.rule,
        color = color or args.color or deepcopy(self.colors.live),
        age = 0,
    }
end

-- 交差
function Board:crossover(parents)
    -- 親をランダムに選ぶ
    local randomParent = parents[love.math.random(#parents)]

    -- 突然変異するかどうか
    local mutation = self.option.mutation and (random() <= self.option.mutationRate) or false
    local birthOrSurvive = random(2) == 1

    -- ルール
    local rule
    if self.option.crossoverRule then
        -- 交差

        -- 新ルール
        rule = Board.newRule()

        -- それぞれのルールのリストアップ
        local birthRules = {}
        local surviveRules = {}
        for _, parent in ipairs(parents) do
            table.insert(birthRules, parent.rule.birth)
            table.insert(surviveRules, parent.rule.survive)
        end

        -- 誕生ルールの交差
        do
            -- 交差
            local rules = {}
            local checked, sameIndice = Board.checkRules(birthRules)
            for i, check in ipairs(checked) do
                if check == 'any' then
                    rule.birth[i] = parents[random(#parents)].rule.birth[i]
                else
                    rule.birth[i] = check == 'true'
                end
            end

            -- 突然変異
            if #sameIndice > 0 and mutation and birthOrSurvive then
                -- 全ての親で同じフラグのどれかを反転
                local mutationIndex = sameIndice[random(#sameIndice)]
                rule.birth[mutationIndex] = not rule.birth[mutationIndex]
                mutated = true
            end
        end

        -- 生存ルールの交差
        do
            -- 交差
            local rules = {}
            local checked, sameIndice = Board.checkRules(surviveRules)
            for i, check in ipairs(checked) do
                if check == 'any' then
                    rule.survive[i] = parents[love.math.random(#parents)].rule.survive[i]
                else
                    rule.survive[i] = check == 'true'
                end
            end

            -- 突然変異
            if #sameIndice > 0 and mutation and not birthOrSurvive then
                -- 全ての親で同じフラグのどれかを反転
                local mutationIndex = sameIndice[random(#sameIndice)]
                rule.survive[mutationIndex] = not rule.survive[mutationIndex]
                mutated = true
            end
        end
    else
        -- クローン
        if mutation then
            -- 突然変異
            rule = Board.newRule(true)
        else
            -- 交差
            rule = deepcopy(randomParent.rule)
        end
    end

    -- 色
    local color
    if self.option.crossoverColor then
        -- 交差
        if mutation then
            -- 突然変異
            color = Board.newHSVColor(random(), 1, 1)
        else
            -- 交差
            local colors = {}
            for _, parent in ipairs(parents) do
                table.insert(colors, parent.color.hsv)
            end
            color = Board.newHSVColor(unpack(blendHSV(unpack(colors))))
        end
        color.hsv[2] = 1
        color.hsv[3] = 1
    else
        -- クローン
        if mutation then
            -- 突然変異
            color = Board.newHSVColor(random(), 1, 1)
        else
            -- 交差
            color = deepcopy(randomParent.color)
        end
        color.hsv[2] = 1
        color.hsv[3] = 1
    end

    -- 突然変異ログ
    if mutation then
        print('mutated!', Board.ruleToString(rule), unpack(color.hsv))
    end

    return rule, color
end

-- セルをリセット
function Board:resetCells(cells)
    self.cells = cells or {}
end

-- セルをランダム配置
function Board:resetRandomizeCells(randomColor, randomRule)
    randomColor = randomColor == nil and true or randomColor
    randomRule = randomRule ~= nil and randomRule or false

    self.cells = {}

    for x = 1, self.width do
        for y = 1, self.height do
            if randomBool() then
                self:setCell(
                    x,
                    y,
                    self:newCell{
                        rule = randomRule and Board.newRule(true) or self.rule,
                        color = randomColor and Board.newColor(true) or deepcopy(self.colors.live)
                    }
                )
            end
        end
    end
end

-- セルを描画
function Board:renderPixel(x, y, rgb)
    x = x and (x - 1) or 0
    y = y and (y - 1) or 0
    rgb = rgb or { 0, 0, 0 }
    local pixel = self.fb.bufrgba[y][x]
    if pixel then
        pixel.r = math.floor(rgb[1] * 255)
        pixel.g = math.floor(rgb[2] * 255)
        pixel.b = math.floor(rgb[3] * 255)
        pixel.a = 255
    else
        print('no pixel', x, y)
    end
end

-- セルを描画
function Board:renderCell(x, y, refresh)
    refresh = refresh == nil and true or refresh

    self:renderPixel(x, y, self:getCellColor(self:getCell(x, y)))

    if refresh then self:refresh() end
end

-- セルをすべて描画
function Board:renderAllCells(refresh)
    refresh = refresh == nil and true or refresh

    self.fb.fill()

    for x, column in pairs(self.cells) do
        for y, cell in pairs(column) do
            self:renderPixel(x, y, self:getCellColor(cell))
        end
    end

    if refresh then self:refresh() end
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

-- 隣人からセルが誕生するかどうかチェック
function Board:checkBirthWithNeighbors(neighbors)
    local parents = {}

    local count = #neighbors
    for _, neighbor in ipairs(neighbors) do
        if self:checkBirth(count, neighbor.rule) then
            table.insert(parents, neighbor)
        end
    end

    return parents
end

-- セルがまだ若いかどうか
function Board:checkAge(cell)
    if not self.option.aging then
        return true
    elseif not self.option.agingDeath then
        return true
    elseif self.option.lifespanRandom then
        -- 年をとるほど死にやすくなる
        return random() > cell.age / self.option.lifespan
    else
        -- 寿命を厳格に判定
        return cell.age <= self.option.lifespan
    end
end

-- 色の取得
function Board:getColor(color)
    if color[1] then
        return color
    elseif color.rgb then
        return color.rgb
    elseif color.hsv then
        return { hsv2rgb(unpack(color.hsv)) }
    end
end

-- セル色の取得
function Board:getCellColor(cell)
    return self:getColor(cell and (cell.color or self.colors.live) or self.colors.death)
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
            if self:checkSurvive(count, cell.rule) and self:checkAge(cell) then
                -- 生き残る
                cell.age = cell.age + 1

                -- 次世代へ
                self:entryNextGeneration(x, y, cell, nextGenerations)

                -- 老化
                if self.option.aging and self.option.agingColor then
                    if cell.color.hsv[2] > self.minLifeSaturation then
                        cell.color.hsv[2] = cell.color.hsv[2] - self.lifeSaturationUnit
                    end
                    self:renderPixel(x, y, self:getCellColor(cell))
                end
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
            local parents = self:checkBirthWithNeighbors(candidate.neighbors)
            if #parents > 0 then
                -- 生まれる
                local cell = self:entryNextGeneration(x, y, self:newCell{ parents = parents }, nextGenerations)
                self:renderPixel(x, y, self:getCellColor(cell))
            end
        end
    end

    -- 死者と誕生者を描画
    for i = 1, #deaths, 2 do
        self:renderPixel(deaths[i], deaths[i + 1])
    end

    -- 次の世代へ差し替える
    self.cells = nextGenerations

    self:refresh()
end

return Board
