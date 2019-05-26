
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
    -- スクリーンサイズ
    self.width, self.height = love.graphics.getDimensions()

    -- ボード初期化
    self.board = Board {
        width = 100,
        height = 100,
        scale = 3,
        colors = {
            live = Board.newHSVColor(1, 0, 1),
            death = Board.newHSVColor(0, 0, 0)
        },
        rule = Board.rules.life,
        option = {
            crossoverRule = true,
            crossoverColor = false,
            crossoverRate = 0.00001,
            mutationRate = 0.00001,
            aging = false,
            agingColor = false,
            agingDeath = false,
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

    self:resetTitle()
end

-- 更新
function Game:update(dt, ...)
    -- 操作
    self:controls()

    -- ボード更新
    self.board:update(dt)
end

-- 描画
function Game:draw(...)
    self.board:draw()
end

-- キー入力
function Game:keypressed(key, scancode, isrepeat)
    if key == 'return' then
        self.board:togglePause()
    elseif key == 'z' then
        self.randomColor = not self.randomColor
        print('randomColor', self.randomColor)
    elseif key == 'x' then
        self.randomRule = not self.randomRule
        print('randomRule', self.randomRule)
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
        self.board.rule = Board.rules.bugs
        self.board.colors.live = Board.newHSVColor(1 / 9 * 5, 1, 1)
        self:resetTitle()
    elseif key == '7' then
        self.board.rule = Board.rules._2x2
        self.board.colors.live = Board.newHSVColor(1 / 9 * 6, 1, 1)
        self:resetTitle()
    elseif key == '8' then
        self.board.rule = Board.rules.stains
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

-- マウス入力
function Game:mousepressed(x, y, button, istouch, presses)
end

-- マウスホイール
function Game:wheelmoved(x, y)
    if y < 0 and self.board.scale > 1 then
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
    love.window.setTitle('LIFE-LIKE - ' .. Board.ruleToString(rule or self.board.rule))
end

return Game
