
local class = require 'middleclass'
local Slab = require 'Slab'
local Window = require('Slab.Internal.UI.Window')

-- クラス
local Application = require 'Application'
local Board = require 'Board'

-- ゲーム
local Game = class('Game', Application)

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
            live = Board.newHSVColor(1, 0, 1),
            death = Board.newHSVColor(0, 0, 0)
        },
        rule = Board.rules.life,
        option = {
            crossoverRule = true,
            crossoverColor = false,
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

    -- セル設置時の設定
    self.color = self.board.colors.live
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

    self:ruleWindow()

    self.focusUI = Window.IsObstructedAtMouse()
end

local checkbox = function (t, name, label)
    Slab.BeginColumn(1)
    Slab.Text(label or name or '')
    Slab.EndColumn()

    Slab.BeginColumn(2)
    if Slab.CheckBox(t[name], '', { Id = name or label or '' }) then
        t[name] = not t[name]
    end
    Slab.EndColumn()
end

local inputNumber = function (t, name, label, min, max)
    local changed = false

    Slab.BeginColumn(1)
    Slab.Text(label or name or '')
    Slab.EndColumn()

    Slab.BeginColumn(2)
    if Slab.Input(name, { Text = tostring(t[name]), ReturnOnText = false, NumbersOnly = true }) then
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

-- デバッグ更新
function Game:ruleWindow()
    Slab.BeginWindow('Rule', { Title = "Rule", Columns = 2 })

    -- オプション
    local option = self.board.option
    checkbox(option, 'crossover', 'Crossover')
    checkbox(option, 'crossoverRule', 'Crossover Rule')
    checkbox(option, 'crossoverColor', 'Crossover Color')
    --Slab.Text('crossoverRate')
    --Slab.Separator()
    checkbox(option, 'mutation', 'Mutation')
    inputNumber(option, 'mutationRate', 'Mutation Rate', 0, 1)
    --Slab.Separator()
    checkbox(option, 'aging', 'Aging')
    checkbox(option, 'agingColor', 'Aging Color')
    checkbox(option, 'agingDeath', 'Aging Death')
    --Slab.Separator()
    if inputNumber(option, 'lifespan', 'Lifespan', 0) then
        option.lifespan = math.floor(option.lifespan)
        self.board:updateLifespanOption()
    end
    checkbox(option, 'lifespanRandom', 'Lifespan Random')
    if inputNumber(option, 'lifeSaturation', 'Lifespand Saturation', 0, 1) then
        self.board:updateLifespanOption()
    end

    Slab.EndWindow()
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
    elseif key == 'z' then
        self.randomColor = not self.randomColor
        print('randomColor', self.randomColor)
    elseif key == 'x' then
        self.randomRule = not self.randomRule
        print('randomRule', self.randomRule)
    elseif key == 'm' then
        self.board.option.mutation = not self.board.option.mutation
        print('mutation', self.board.option.mutation)
    elseif key == 'c' then
        self.board.option.crossoverColor = not self.board.option.crossoverColor
        print('crossoverColor', self.board.option.crossoverColor)
    elseif key == 'r' then
        self.board.option.crossoverRule = not self.board.option.crossoverRule
        print('crossoverRule', self.board.option.crossoverRule)
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
            self.board:setCell(
                x,
                y,
                self.board:newCell{
                    rule = self.randomRule and Board.newRule(true) or nil,
                    color = self.randomColor and Board.newColor(true) or nil
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
