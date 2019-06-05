
local class = require 'middleclass'
local fblove = require 'fblove_strip'

-- ユーティリティ
local util = require 'util'

-- 近傍
local Neighborhood = require 'Neighborhood'

-- アプリケーション
local Board = class 'Board'

-- ランダム
local random = love.math.random

-- ルール名一覧
Board.static.ruleNames = {
    'Life',
    'Generations',
    'LargerThanLife',
}

-- ルール一覧
Board.static.rules = {}
for _, name in ipairs(Board.static.ruleNames) do
    Board.rules[name] = require(name)
end

-- ランダムなルール名
function Board.static.randomRuleName()
    return Board.ruleNames[random(#Board.ruleNames)]
end

-- ランダムなルール
function Board.static.randomRule()
    return Board.rules[random(#Board.rules)]
end

-- 新ルール
function Board.static.newRule(name, ...)
    assert(Board.rules[name], 'Invalid rule name: "' .. tostring(name) .. '"')
    return Board.rules[name].newRule(...)
end

-- 新規ランダムルール
function Board.static.newRandomRule(name, ...)
    return Board.rules[name and name or Board.randomRuleName()].newRandomRule(...)
end

-- ルールをルール文字列化
function Board.static.ruleToString(rule)
    assert(Board.rules[rule.type], 'Invalid rule name: "' .. tostring(rule.type) .. '"')
    return Board.rules[rule.type].toString(rule)
end

-- ルール文字列をルール化
function Board.static.stringToRule(ruleType, str)
    assert(Board.rules[ruleType], 'Invalid rule name: "' .. tostring(ruleType) .. '"')
    return Board.rules[ruleType].toRule(str)
end

-- 他のルールから Life ルールに変換
function Board.static.convertRule(ruleType, rule)
    if ruleType == 'Life' then
        return Board.convertLifeRule(rule)
    elseif ruleType == 'Generations' then
        return Board.convertGenerationsRule(rule)
    elseif ruleType == 'LargerThanLife' then
        return Board.convertLargerThanLifeRule(rule)
    end
    return rule
end

-- 他のルールから Life ルールに変換
function Board.static.convertLifeRule(rule)
    local newRule
    if rule.type == 'Life' then
        -- Life ルール
        newRule = rule
    elseif rule.type == 'Generations' then
        -- Generations ルール
        newRule = {
            type = 'Life',
            birth = util.deepcopy(rule.birth),
            survive = util.deepcopy(rule.survive),
        }
    elseif rule.type == 'LargerThanLife' then
        -- LargerThanLife ルール
        newRule = {
            type = 'Life',
            birth = util.makeBooleanTable(rule.birth.min, rule.birth.max),
            survive = util.makeBooleanTable(rule.survive.min, rule.survive.max),
        }
    end
    return newRule
end

-- 他のルールから Generations ルールに変換
function Board.static.convertGenerationsRule(rule)
    local newRule
    if rule.type == 'Life' then
        -- Life ルール
        newRule = {
            type = 'Generations',
            birth = util.deepcopy(rule.birth),
            survive = util.deepcopy(rule.survive),
            count = 2,
        }
    elseif rule.type == 'Generations' then
        -- Generations ルール
        newRule = rule
    elseif rule.type == 'LargerThanLife' then
        -- LargerThanLife ルール
        newRule = {
            type = 'Generations',
            birth = util.makeBooleanTable(rule.birth.min, rule.birth.max),
            survive = util.makeBooleanTable(rule.survive.min, rule.survive.max),
            count = rule.count + 2,
        }
    end
    return newRule
end

-- 他のルールから LargerThanLife ルールに変換
function Board.static.convertLargerThanLifeRule(rule)
    local newRule
    if rule.type == 'Life' then
        -- Life ルール
        newRule = {
            type = 'LargerThanLife',
            range = 1,
            count = 0,
            middle = 0,
            survive = { min = 0, max = 0 },
            birth = { min = 1, max = 1, },
            neighborhood = 'M',
        }
        newRule.survive.min, newRule.survive.max = util.findTrueIndexMinMax(rule.survive)
        newRule.birth.min, newRule.birth.max = util.findTrueIndexMinMax(rule.birth)
    elseif rule.type == 'Generations' then
        -- Generations ルール
        newRule = {
            type = 'LargerThanLife',
            range = 1,
            count = rule.count - 2,
            middle = 0,
            survive = { min = 0, max = 0 },
            birth = { min = 1, max = 1, },
            neighborhood = 'M',
        }
        newRule.survive.min, newRule.survive.max = util.findTrueIndexMinMax(rule.survive)
        newRule.birth.min, newRule.birth.max = util.findTrueIndexMinMax(rule.birth)
    elseif rule.type == 'LargerThanLife' then
        -- LargerThanLife ルール
        newRule = rule
    end
    return newRule
end

-- 新HSVカラー
Board.static.newHSVColor = function(h, s, v)
    return { hsv = { h or 0, s or 1, v or 1 } }
end

-- 新カラー
Board.static.newColor = function(randomize)
    return randomize and Board.newHSVColor(love.math.random(), 1, 1) or Board.newHSVColor(1, 0, 1)
end

-- ルールが一致しているか判定
Board.static.checkRules = function(rules)
    local diffIndice = {}
    local sameIndice = {}
    local diff

    -- 先頭ルールをベースにする
    local baseRule = rules[1]
    for i, baseFlag in ipairs(baseRule) do
        -- ベースフラグと一致するかどうか
        diff = false
        for j, rule in ipairs(rules) do
            if j > 1 then
                if rule[i] ~= baseFlag then
                    diff = true
                    break
                end
            end
        end

        -- 相違または一致テーブルに振り分ける
        table.insert(diff and diffIndice or sameIndice, i)
    end

    return diffIndice, sameIndice
end

-- ムーア近傍
Board.static.mooreNeighborhood = Neighborhood.require('M')

-- ノイマン近傍
Board.static.vonNeumannNeighborhood = Neighborhood.require('N')

-- 初期化
function Board:initialize(args)
    args = type(args) == 'table' and args or {}

    -- カラー
    self.colors = args.colors or {
        live = Board.newHSVColor(0, 1, 1),
        death = Board.newHSVColor(0, 0, 0)
    }

    -- フレームバッファ
    local sw, sh = love.graphics.getDimensions()
    self.fb = fblove(args.width or sw, args.height or sh)

    -- リサイズ処理
    self:resize(args.width, args.height, args.scale)

    -- セル
    self.cells = args.cells or {}

    -- ルール
    self.rule = args.rule or Board.stringToRule('Life', 'B3/S23')

    -- オフセット
    self.offset = { x = 0, y = 0 }
    self:setOffset(0, 0)

    -- 遺伝オプション
    self.option = args.option or {}
    self.option.crossover = self.option.crossover ~= nil and self.option.crossover or false
    self.option.crossoverRule = self.option.crossoverRule ~= nil and self.option.crossoverRule or false
    self.option.crossoverColor = self.option.crossoverColor ~= nil and self.option.crossoverColor or false
    self.option.crossoverRate = self.option.mutationRate or 0.001
    self.option.mutation = self.option.mutation ~= nil and self.option.mutation or false
    self.option.mutationRule = self.option.mutationRule ~= nil and self.option.mutationRule or false
    self.option.mutationColor = self.option.mutationColor ~= nil and self.option.mutationColor or false
    self.option.mutationRate = self.option.mutationRate or 0.000001
    self.option.mutationRules = self.option.mutationRules or { Life = true, Generations = false }
    self.option.aging = self.option.aging ~= nil and self.option.aging or false
    self.option.agingColor = self.option.agingColor ~= nil and self.option.agingColor or false
    self.option.agingDeath = self.option.agingDeath ~= nil and self.option.agingDeath or false
    self.option.lifespan = self.option.lifespan or 1000
    self.option.lifespanRandom = self.option.lifespanRandom ~= nil and self.option.lifespanRandom or false
    self.option.lifeSaturation = self.option.lifeSaturation or 0.75

    -- その他
    self.minLifeSaturation = 1 - self.option.lifeSaturation
    self.lifeSaturationUnit = 1 / self.option.lifespan
    self.interval = args.interval or 0
    self.wait = self.interval
    self.pause = args.pause ~= nil and args.pause or false

    self:renderAllCells()
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

-- 寿命関連の設定を更新
function Board:updateLifespanOption()
    self.minLifeSaturation = 1 - self.option.lifeSaturation
    self.lifeSaturationUnit = 1 / self.option.lifespan
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
    self.fb.setbg(util.rgb2bit(unpack(self:getColor(self.colors.death))))
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
        rule = rule or util.deepcopy(args.rule) or util.deepcopy(self.rule),
        color = color or util.deepcopy(args.color) or util.deepcopy(self.colors.live),
        age = 0,
    }
end

-- 交差
function Board:crossover(parents)
    -- 親をランダムに選ぶ
    local numParents = #parents
    local randomParent = parents[love.math.random(numParents)]

    -- 突然変異するかどうか
    local mutation = self.option.mutation and (random() <= self.option.mutationRate) or false
    local birthOrSurvive = random(2) == 1

    -- ルール
    local rule
    if self.option.crossover and self.option.crossoverRule then
        -- 交差

        -- 新ルール
        rule = util.deepcopy(randomParent.rule)

        if numParents == 1 then
            -- 交差するほど数がいない
        else
            -- それぞれのルールのリストアップ
            local birthRules = {}
            local surviveRules = {}
            local counts = {}
            local countMin, countMax = 10000, 2
            for _, parent in ipairs(parents) do
                table.insert(birthRules, parent.rule.birth)
                table.insert(surviveRules, parent.rule.survive)
                if parent.rule.count then
                    table.insert(counts, parent.rule.count)
                    if parent.rule.count < countMin then
                        countMin = parent.rule.count
                    elseif parent.rule.count > countMax then
                        countMax = parent.rule.count
                    end
                end
            end

            -- 誕生ルールの交差
            do
                -- 交差
                local rules = {}
                local diffIndice, sameIndice = Board.checkRules(birthRules)
                for _, index in ipairs(diffIndice) do
                    rule.birth[index] = parents[random(numParents)].rule.birth[index]
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
                local diffIndice, sameIndice = Board.checkRules(surviveRules)
                for _, index in ipairs(diffIndice) do
                    rule.survive[index] = parents[random(numParents)].rule.survive[index]
                end

                -- 突然変異
                if #sameIndice > 0 and mutation and self.option.mutationRule and not birthOrSurvive then
                    -- 全ての親で同じフラグのどれかを反転
                    local mutationIndex = sameIndice[random(#sameIndice)]
                    rule.survive[mutationIndex] = not rule.survive[mutationIndex]
                    mutated = true
                end
            end

            -- 死亡カウントの交差
            if #counts > 0 then
                rule = Board.convertGenerationsRule(rule)
                if not mutation then
                    rule.count = counts[random(#counts)]
                else
                    rule.count = random(countMin, countMax * 2)
                end
            end
        end
    else
        -- クローン
        if mutation and self.option.mutationRule then
            -- 突然変異
            rule = Board.newRandomRule()
        else
            -- コピー
            rule = util.deepcopy(randomParent.rule)
        end
    end

    -- 色
    local color
    if self.option.crossover and self.option.crossoverColor then
        -- 交差
        if mutation and self.option.mutationColor then
            -- 突然変異
            color = Board.newHSVColor(random(), 1, 1)
        elseif numParents == 1 then
            -- 交差するほど数がいない
            color = util.deepcopy(randomParent.color)
        else
            -- 交差
            local colors = {}
            for _, parent in ipairs(parents) do
                local hsv = util.deepcopy(parent.color.hsv)
                hsv[2] = 1
                hsv[3] = 1
                table.insert(colors, hsv)
            end
            color = Board.newHSVColor(unpack(util.blendHSV(unpack(colors))))
        end
        color.hsv[2] = 1
        color.hsv[3] = 1
    else
        -- クローン
        if mutation and self.option.mutationColor then
            -- 突然変異
            color = Board.newHSVColor(random(), 1, 1)
        else
            -- コピー
            color = util.deepcopy(randomParent.color)
        end
        color.hsv[2] = 1
        color.hsv[3] = 1
    end

    -- 突然変異ログ
    if mutation then
        print('mutated!', Board.ruleToString(rule), color.hsv[1])
    end

    return rule, color
end

-- セルをリセット
function Board:resetCells(cells)
    self.cells = cells or {}
end

-- セルを全て配置
function Board:resetAllCells(rule, color, div)
    self.cells = {}

    for x = 1, self.width do
        for y = 1, self.height do
            if util.randomBool(div) then
                self:setCell(
                    x,
                    y,
                    self:newCell{
                        rule = (type(rule) == 'function') and rule() or rule,
                        color = (type(color) == 'function') and color() or color
                    }
                )
            end
        end
    end
end

-- セルをランダム配置
function Board:resetRandomizeCells(randomColor, randomRule)
    randomColor = randomColor == nil and true or randomColor
    randomRule = randomRule ~= nil and randomRule or false

    self.cells = {}

    for x = 1, self.width do
        for y = 1, self.height do
            if util.randomBool() then
                self:setCell(
                    x,
                    y,
                    self:newCell{
                        rule = randomRule and Board.newRandomRule() or self.rule,
                        color = randomColor and Board.newColor(true) or util.deepcopy(self.colors.live)
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

    self.fb.setbg(util.rgb2bit(unpack(self:getColor(self.colors.death))))
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
    elseif cell.count then
        -- 死んでいくセルはカウントしない
    else
        return cell
    end
end

-- セルが生き残るかどうか
function Board:checkSurvive(count, rule)
    rule = rule or self.rule
    if rule.survive.min and rule.survive.max then
        return (count >= rule.survive.min) and count <= (rule.survive.max)
    else
        return rule.survive[count + 1] == true
    end
end

-- セルが誕生するかどうか
function Board:checkBirth(count, rule)
    rule = rule or self.rule
    if rule.birth.min and rule.birth.max then
        return (count >= rule.birth.min) and count <= (rule.birth.max)
    else
        return rule.birth[count + 1] == true
    end
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

-- セルが死んでいくかどうか
function Board:checkDyingState(cell)
    if not cell.count then
        return nil
    elseif cell.count <= 2 then
        return 'die'
    else
        return 'dying'
    end
end

-- 色の取得
function Board:getColor(color)
    if color[1] then
        return color
    elseif color.rgb then
        return color.rgb
    elseif color.hsv then
        return { util.hsv2rgb(unpack(color.hsv)) }
    end
end

-- セル色の取得
function Board:getCellColor(cell)
    return self:getColor(cell and (cell.color or self.colors.live) or self.colors.death)
end

-- 近傍の取得
function Board:getNeighborhood(cell)
    return cell.rule.neighborhood and Neighborhood.require(cell.rule.neighborhood, cell.rule.range, cell.rule.middle) or Board.mooreNeighborhood
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
            local state = self:checkDyingState(cell)
            if not state then
                -- まだ死なない
                local count = 0
                for _, pos in ipairs(self:getNeighborhood(cell)) do
                    if self:checkCell(x + pos[1], y + pos[2], cell, candidates) then
                        count = count + 1
                    end
                end

                -- 生死判定
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
                elseif cell.rule.count and cell.rule.count > 2 then
                    -- 死に始め
                    local nextCell = {
                        rule = cell.rule,
                        color = util.deepcopy(cell.color),
                        count = cell.rule.count - 1,
                    }
                    nextCell.color.hsv[3] = (nextCell.count - 1) / (nextCell.rule.count - 1)
                    self:renderPixel(x, y, self:getCellColor(nextCell))

                    -- 次世代へ
                    self:entryNextGeneration(x, y, nextCell, nextGenerations)
                else
                    -- 死ぬ
                    table.insert(deaths, x)
                    table.insert(deaths, y)
                end

            elseif state == 'die' then
                -- 死ぬ
                table.insert(deaths, x)
                table.insert(deaths, y)

            elseif state == 'dying' then
                -- 死んでいく
                local nextCell = {
                    rule = cell.rule,
                    color = util.deepcopy(cell.color),
                    count = cell.count - 1,
                }
                nextCell.color.hsv[3] = (nextCell.count - 1) / (nextCell.rule.count - 1)
                self:renderPixel(x, y, self:getCellColor(nextCell))

                -- 次世代へ
                self:entryNextGeneration(x, y, nextCell, nextGenerations)
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

    -- 死者を描画
    for i = 1, #deaths, 2 do
        self:renderPixel(deaths[i], deaths[i + 1], self:getColor(self.colors.death))
    end

    -- 次の世代へ差し替える
    self.cells = nextGenerations

    self:refresh()
end

-- 保存用のダンプ
function Board:dump()
    return {
        width = self.width,
        height = self.height,
        option = self.option,
        cells = self.cells,
    }
end

return Board
