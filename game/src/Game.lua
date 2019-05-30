
local class = require 'middleclass'
local Slab = require 'Slab'
local Window = require('Slab.Internal.UI.Window')

-- クラス
local Application = require 'Application'
local Board = require 'Board'

-- ゲーム
local Game = class('Game', Application)

-- セパレータ
local function separator(n)
    n = n or 2
    for i = 1, n do
        Slab.BeginColumn(i)
        Slab.Separator()
        Slab.EndColumn()
    end
end

-- ボタン
local function button(label)
    local activate = false

    Slab.BeginColumn(1)
    Slab.NewLine()
    Slab.EndColumn()

    Slab.BeginColumn(2)
	local ww, wh = Slab.GetWindowActiveSize()
    local h = Slab.GetStyle().Font:getHeight()
    if Slab.Button(label, { W = ww, H = h }) then
        activate = true
    end
    Slab.EndColumn()

    return activate
end

-- チェックボックス
local function checkbox(t, name, label)
    local changed = false

    Slab.BeginColumn(1)
    Slab.Text(label or name or '')
    Slab.EndColumn()

    Slab.BeginColumn(2)
    if Slab.CheckBox(t[name], '', { Id = name or label or '' }) then
        t[name] = not t[name]
        changed = true
    end
    Slab.EndColumn()

    return changed
end

-- 入力欄（数字）
local function inputNumber(t, name, label, min, max)
    local changed = false

    Slab.BeginColumn(1)
    Slab.Text(label or name or '')
    Slab.EndColumn()

    Slab.BeginColumn(2)
	local ww, wh = Slab.GetWindowActiveSize()
    local h = Slab.GetStyle().Font:getHeight()
    if Slab.Input(name, { Text = tostring(t[name]), ReturnOnText = false, NumbersOnly = true, W = ww, H = h }) then
        local n = tonumber(Slab.GetInputText())
        if min and n < min then
            n = min
        elseif max and n > max then
            n = max
        end
        t[name] = n
        changed = true
    end
    Slab.EndColumn()

    return changed
end

-- カラーボタン
local function buttonColor(color, name)
    local activate = false

    Slab.BeginColumn(1)
    Slab.Text(name or '')
    Slab.EndColumn()

    Slab.BeginColumn(2)
	local ww, wh = Slab.GetWindowActiveSize()
    local x, y = Slab.GetCursorPos()
    local h = Slab.GetStyle().Font:getHeight()
    Slab.Rectangle({ W = ww, H = h, Color = { Board.hsv2rgb(unpack(color.hsv)) }, Outline = true })
    Slab.SetCursorPos(x, y)
	activate = Slab.Button("", { Invisible = true, W = ww, H = h })
    Slab.EndColumn()

    return activate
end

-- ルールのチェックボックス
local function checkboxesRule(rule)
    local changed = false

    Slab.BeginColumn(1)
    Slab.Text('Birth')
    Slab.EndColumn()

    Slab.BeginColumn(2)
    for i, flag in ipairs(rule.birth) do
        if Slab.CheckBox(flag, '', { Id = tostring(rule) .. ' birth[' .. i .. ']' }) then
            rule.birth[i] = not rule.birth[i]
            changed = true
        end
        Slab.SameLine()
    end
    Slab.EndColumn()

    Slab.BeginColumn(1)
    Slab.Text('Survive')
    Slab.EndColumn()

    Slab.BeginColumn(2)
    Slab.NewLine()
    for i, flag in ipairs(rule.survive) do
        if Slab.CheckBox(flag, '', { Id = tostring(rule) .. ' survive[' .. i .. ']' }) then
            rule.survive[i] = not rule.survive[i]
            changed = true
        end
        Slab.SameLine()
    end
    Slab.NewLine()
    Slab.EndColumn()

    return changed
end

-- ルール文字列入力欄
local function inputRulestrings(rulestring, label)
    local changed = false

    Slab.BeginColumn(1)
    Slab.Text(label or 'Rulestrings')
    Slab.EndColumn()

    Slab.BeginColumn(2)
	local ww, wh = Slab.GetWindowActiveSize()
    local h = Slab.GetStyle().Font:getHeight()
    if Slab.Input('rulestrings', { Text = rulestring, ReturnOnText = false, W = ww, H = h }) then
        changed = true
    end
    Slab.EndColumn()

    return changed
end

-- 初期化
function Game:initialize(...)
    Application.initialize(self, ...)

    love.keyboard.setKeyRepeat(true)
    Slab.Initialize()
end

-- 読み込み
function Game:load(...)
    -- スクリーンサイズ
    self.width, self.height = love.graphics.getDimensions()

    -- ボード初期化
    self.board = Board {
        width = 100,
        height = 100,
        scale = 1,
        colors = {
            live = Board.newHSVColor(0, 1, 1),
            death = Board.newHSVColor(0, 0, 0)
        },
        rule = Board.deepcopy(Board.rules.life),
        option = {
            crossoverRule = false,
            crossoverColor = true,
            crossoverRate = 0.00001,
            mutationRate = 0.000001,
            mutation = false,
            aging = false,
            agingColor = true,
            agingDeath = true,
            lifespan = 100,
            lifespanRandom = false,
            lifeSaturation = 0.75,
        },
        pause = false
    }
    self.baseRuleString = Board.ruleToString(self.board.rule)

    -- セル設置時の設定
    self.rule = Board.deepcopy(Board.rules.life)
    self.rulestring = Board.ruleToString(self.rule)
    self.color = Board.deepcopy(self.board.colors.live)
    self.randomColor = true
    self.randomRule = false

    -- ボードのランダム設定
    self.board:resetRandomizeCells(self.randomColor, self.randomRule)
    self.board:renderAllCells()

    -- 移動モード
    self.move = false
    self.moveOrigin = { x = 0, y = 0 }
    self.offsetOrigin = { x = 0, y = 0 }

    -- ＵＩ
    self.focusUI = false
    self.editColor = nil
    self.beforeColor = nil

    self:resetTitle()
end

-- 更新
function Game:update(dt, ...)
    -- デバッグＵＩ
    if self.debugMode then
        self:updateDebug(dt, ...)
    end

    -- 操作
    self:controls()

    -- ボード更新
    self.board:update(dt)
end

-- 描画
function Game:draw(...)
    -- ボード描画
    self.board:draw()

    -- デバッグＵＩ
    if self.debugMode then
        self:drawDebug(...)
    end
end

-- デバッグ更新
function Game:updateDebug(dt, ...)
    Slab.Update(dt)

    -- メインメニューバー
    if Slab.BeginMainMenuBar() then
        -- ファイル
        if Slab.BeginMenu("File") then
            if Slab.MenuItem("New") then
            end
            if Slab.MenuItem("Open") then
            end
            if Slab.MenuItem("Save") then
            end
            if Slab.MenuItem("Save As") then
            end

            Slab.Separator()

            if Slab.MenuItem("Quit") then
                love.event.quit()
            end

            Slab.EndMenu()
        end
        Slab.EndMainMenuBar()
    end

    self:controlWindow()
    self:ruleWindow()

    -- カラーエディット
    if self.editColor then
        if self:colorEditWindow() then
            self.board:renderAllCells()
        end
    end

    self.focusUI = Window.IsObstructedAtMouse()
end

-- セルウィンドウ
function Game:controlWindow()
    Slab.BeginWindow('Control', { Title = "Control", Columns = 2 })

    local ww, wh = Slab.GetWindowActiveSize()
    local buttonOption = { W = ww / 4 - 4 }

    -- ポーズ
    if Slab.Button(self.board.pause and 'Play' or 'Pause', buttonOption) then
        self.board:togglePause()
    end

    -- ステップ
    Slab.SameLine()
    if Slab.Button('Step', buttonOption) then
        self.board.pause = true
        self.board:step()
    end

    -- リセット
    Slab.SameLine()
    if Slab.Button('Reset', buttonOption) then
        self.board:resetAllCells(
            self.randomRule and function () return Board.newRule(true) end or self.rule,
            self.randomColor and function () return Board.newColor(true) end or self.color
        )
        self.board:renderAllCells()
    end

    -- クリア
    Slab.SameLine()
    if Slab.Button('Clear', buttonOption) then
        self.board:resetCells()
        self.board:renderAllCells()
    end

    -- ルール
    if checkboxesRule(self.rule) then
        self.rulestring = Board.ruleToString(self.rule)
    end
    if inputRulestrings(self.rulestring) then
        self.rule = Board.stringToRule(Slab.GetInputText())
        self.rulestring = Board.ruleToString(self.rule)
    end

    separator()

    -- カラー
    if buttonColor(self.color, 'Color') then
        self.editColor = self.color
        self.beforeColor = Board.deepcopy(self.editColor)
    end

    separator()

    checkbox(self, 'randomColor', 'Random Color')
    checkbox(self, 'randomRule', 'Random Rule')

    -- コンテキストメニュー
    if Slab.BeginContextMenuWindow() then
        if Slab.MenuItem('Randomize rule') then
            self:randomizeRule()
        end
        if Slab.MenuItem('Randomize color') then
            self:randomizeColor()
        end

        Slab.EndContextMenu()
    end

    Slab.EndWindow()
end

-- ルールウィンドウ
function Game:ruleWindow()
    Slab.BeginWindow('Rule', { Title = "Rule", Columns = 2 })

    -- コモンルール
    if checkboxesRule(self.board.rule) then
        self.baseRuleString = Board.ruleToString(self.board.rule)
    end
    if inputRulestrings(self.baseRuleString) then
        self.board.rule = Board.stringToRule(Slab.GetInputText())
        self.baseRuleString = Board.ruleToString(self.board.rule)
    end

    separator()

    -- カラー（生）
    if buttonColor(self.board.colors.live, 'Live Color') then
        self.editColor = self.board.colors.live
        self.beforeColor = Board.deepcopy(self.editColor)
    end

    -- カラー（死）
    if buttonColor(self.board.colors.death, 'Death Color') then
        self.editColor = self.board.colors.death
        self.beforeColor = Board.deepcopy(self.editColor)
    end

    separator()

    -- オプション
    local option = self.board.option
    checkbox(option, 'crossover', 'Crossover')
    checkbox(option, 'crossoverRule', 'Crossover Rule')
    checkbox(option, 'crossoverColor', 'Crossover Color')
    separator()

    checkbox(option, 'mutation', 'Mutation')
    inputNumber(option, 'mutationRate', 'Mutation Rate', 0, 1)
    separator()

    checkbox(option, 'aging', 'Aging')
    checkbox(option, 'agingColor', 'Aging Color')
    checkbox(option, 'agingDeath', 'Aging Death')
    separator()

    if inputNumber(option, 'lifespan', 'Lifespan', 0) then
        option.lifespan = math.floor(option.lifespan)
        self.board:updateLifespanOption()
    end
    checkbox(option, 'lifespanRandom', 'Lifespan Random')
    if inputNumber(option, 'lifeSaturation', 'Lifespan Saturation', 0, 1) then
        self.board:updateLifespanOption()
    end

    Slab.EndWindow()
end

-- ルールウィンドウ
function Game:colorEditWindow(id, title)
    local changed = false

    Slab.BeginWindow(id or 'ColorEdit', { Title = title or 'HSV Color Edit', Columns = 2 })

    -- 色見本
    local ww, wh = Slab.GetWindowActiveSize()
    local h = Slab.GetStyle().Font:getHeight()
    Slab.Rectangle({ W = 300, H = h, Color = { Board.hsv2rgb(unpack(self.editColor.hsv)) }, Outline = true })

    -- 各パラメータ
    if inputNumber(self.editColor.hsv, 1, 'Hue', 0, 1) then
        changed = true
    end
    if inputNumber(self.editColor.hsv, 2, 'Saturation', 0, 1) then
        changed = true
    end
    if inputNumber(self.editColor.hsv, 3, 'Value', 0, 1) then
        changed = true
    end

    Slab.Separator()

    -- ＯＫ
    if Slab.Button("OK", {AlignRight = true}) then
        self.editColor = nil
        changed = true
    end

    -- キャンセル
    Slab.SameLine()
    if Slab.Button("Cancel", {AlignRight = true}) then
        self.editColor.hsv[1] = self.beforeColor.hsv[1]
        self.editColor.hsv[2] = self.beforeColor.hsv[2]
        self.editColor.hsv[3] = self.beforeColor.hsv[3]
        self.editColor = nil
        self.beforeColor = nil
        changed = true
    end

    Slab.EndWindow()

    return changed
end

-- デバッグ描画
function Game:drawDebug(...)
    Slab.Draw()
end

-- キー入力
function Game:keypressed(key, scancode, isrepeat)
    if self.debugMode and self.focusUI then
        -- debug
    elseif key == 'return' then
        self.board:togglePause()
    elseif key == 'space' or key == 's' then
        self.board.pause = true
        self.board:step()
    elseif key == 'backspace' then
        self.board:resetRandomizeCells(self.randomColor, self.randomRule)
        self.board:renderAllCells()
    elseif key == 'delete' then
        self.board:resetCells()
        self.board:renderAllCells()
    elseif key == 'tab' then
        self.board.rule = Board.newRule(true)
        self.board.colors.live = Board.newColor(true)
        self.board:resetRandomizeCells(self.randomColor)
        self.board:renderAllCells()
        self:resetTitle()
    elseif key == '`' then
        self.board:resetRandomizeCells(true, true)
        self.board:renderAllCells()
        self:resetTitle()
    elseif key == '1' then
        self.board.rule = Board.rules.life
        self.board.colors.live = Board.newHSVColor(1 / 9 * 0, 1, 1)
        self:resetTitle()
    elseif key == '2' then
        self.board.rule = Board.rules.highLife
        self.board.colors.live = Board.newHSVColor(1 / 9 * 1, 1, 1)
        self:resetTitle()
    elseif key == '3' then
        self.board.rule = Board.rules.mazectric
        self.board.colors.live = Board.newHSVColor(1 / 9 * 2, 1, 1)
        self:resetTitle()
    elseif key == '4' then
        self.board.rule = Board.rules.replicator
        self.board.colors.live = Board.newHSVColor(1 / 9 * 3, 1, 1)
        self:resetTitle()
    elseif key == '5' then
        self.board.rule = Board.rules.seeds
        self.board.colors.live = Board.newHSVColor(1 / 9 * 4, 1, 1)
        self:resetTitle()
    elseif key == '6' then
        self.board.rule = Board.rules.bacteria
        self.board.colors.live = Board.newHSVColor(1 / 9 * 5, 1, 1)
        self:resetTitle()
    elseif key == '7' then
        self.board.rule = Board.rules._2x2
        self.board.colors.live = Board.newHSVColor(1 / 9 * 6, 1, 1)
        self:resetTitle()
    elseif key == '8' then
        self.board.rule = Board.rules.diamoeba
        self.board.colors.live = Board.newHSVColor(1 / 9 * 7, 1, 1)
        self:resetTitle()
    elseif key == '9' then
        self.board.rule = Board.rules.lifeWithoutDeath
        self.board.colors.live = Board.newHSVColor(1 / 9 * 8, 1, 1)
        self:resetTitle()
    elseif key == '0' then
        self.board.rule = Board.newRule(true)
        self.board.colors.live = Board.newColor(true)
        self:resetTitle()
    end
end

-- キー離した
function Game:keyreleased(key, scancode)
    if self.debugMode and self.focusUI then
        -- debug
    end
end

-- テキスト入力
function Game:textinput(text)
    if self.debugMode and self.focusUI then
        -- imgui
    end
end

-- マウス入力
function Game:mousepressed(x, y, button, istouch, presses)
    if self.debugMode and self.focusUI then
        -- imgui
    end
end

-- マウス離した
function Game:mousereleased(x, y, button, istouch, presses)
    if self.debugMode and self.focusUI then
        -- imgui
    end
end

-- マウス移動
function Game:mousemoved(x, y, dx, dy, istouch)
    if self.debugMode and self.focusUI then
        -- imgui
    end
end

-- マウスホイール
function Game:wheelmoved(x, y)
    if self.debugMode and self.focusUI then
        -- imgui
    elseif y < 0 and self.board.scale > 1 then
        -- ズームアウト
        self.board:rescale(self.board.scale - 1)
    elseif y > 0 and self.board.scale < 10 then
        -- ズームイン
        self.board:rescale(self.board.scale + 1)
    end
end

-- リサイズ
function Game:resize(width, height)
    self.width, self.height = width, height
    self.board:rescale()
end

-- ルールをランダム設定
function Game:randomizeRule()
    self.rule = Board.newRule(true)
    self.rulestring = Board.ruleToString(self.rule)
end

-- 色をランダム設定
function Game:randomizeColor()
    local newColor = Board.newColor(true)
    if self.editColor == self.color then
        self.editColor = newColor
    end
    self.color = newColor
end

-- ルールと色をランダム設定
function Game:randomizeRuleAndColor()
    if self.randomRule then
        self:randomizeRule()
    end

    if self.randomColor then
        self:randomizeColor()
    end
end

-- 操作
function Game:controls()
    if self.debugMode and self.focusUI then return end

    if love.mouse.isDown(1) then
        -- メインボタン
        local x, y = self.board:toLocalPositions(love.mouse.getPosition())

        -- セルの追加
        if self.board:getCell(x, y) then
            -- 既にセルがある
        else
            -- セルが無いので描画
            self:randomizeRuleAndColor()

            self.board:setCell(
                x,
                y,
                self.board:newCell{
                    rule = self.rule,
                    color = self.color
                }
            )
            self.board:renderCell(x, y)
        end
    elseif love.mouse.isDown(2) then
        -- サブボタン
        local x, y = self.board:toLocalPositions(love.mouse.getPosition())

        -- セルの消去
        if self.board:getCell(x, y) then
            -- セルがあるので消去
            self.board:setCell(x, y, nil)
            self.board:renderCell(x, y)
        else
            -- 既にセルが無い
        end
    else
    end

    -- 中クリック
    if love.mouse.isDown(3) then
        if not self.move then
            -- 移動モード開始
            self.move = true
            self.moveOrigin.x, self.moveOrigin.y = love.mouse.getPosition()
            self.offsetOrigin.x, self.offsetOrigin.y = self.board.offset.x, self.board.offset.y
        else
            -- 移動中
            local x, y = love.mouse.getPosition()
            self.board:setOffset(self.offsetOrigin.x + x - self.moveOrigin.x, self.offsetOrigin.y + y - self.moveOrigin.y)
        end
    else
        if self.move then
            -- 移動モード終了
            self.move = false
        end
    end
end

-- タイトルのリセット
function Game:resetTitle(rule)
    local strrule = Board.ruleToString(rule or self.board.rule)
    love.window.setTitle('LIFE-LIKE - ' .. strrule)
    print(strrule)
end

return Game
