
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

-- ゲームクラス
local Game = require(folderOfThisFile .. 'class')

-- ライブラリ
local Slab = require 'Slab'
local binser = require 'binser'

-- クラス
local Application = require 'Application'
local Board = require 'Board'

-- 初期化
function Game:initialize(...)
    Application.initialize(self, ...)

    love.keyboard.setKeyRepeat(true)
    Slab.Initialize()

    -- board フォルダ準備
    self.savable = false
    local dir = love.filesystem.getInfo('board', 'directory')
    if dir == nil then
        self.savable = love.filesystem.createDirectory('board')
    else
        self.savable = true
    end
end

-- 読み込み
function Game:load(...)
    -- スクリーンサイズ
    self.width, self.height = love.graphics.getDimensions()

    -- プリセットルール
    self.rules = {
        {
            title = 'Conway\'s Game of Life',
            type = 'Life',
            rulestring = 'B3/S23'
        },
        {
            title = 'HighLife',
            type = 'Life',
            rulestring = 'B36/S23'
        },
        {
            title = 'Maze',
            type = 'Life',
            rulestring = 'B3/S12345'
        },
        {
            title = 'Mazectric',
            type = 'Life',
            rulestring = 'B3/S1234'
        },
        {
            title = 'Replicator',
            type = 'Life',
            rulestring = 'B1357/S1357'
        },
        {
            title = 'Seeds',
            type = 'Life',
            rulestring = 'B2/S'
        },
        {
            title = 'Life without death',
            type = 'Life',
            rulestring = 'B3/S012345678'
        },
        {
            title = 'Bugs',
            type = 'Life',
            rulestring = 'B3567/S15678'
        },
        {
            title = '2x2',
            type = 'Life',
            rulestring = 'B36/S125'
        },
        {
            title = 'Stains',
            type = 'Life',
            rulestring = 'B3678/S235678'
        },
        {
            title = 'Day & Night',
            type = 'Life',
            rulestring = 'B3678/S34678'
        },
        {
            title = 'Bacteria',
            type = 'Life',
            rulestring = 'B34/S456'
        },
        {
            title = 'Diamoeba',
            type = 'Life',
            rulestring = 'B35678/S5678'
        },
        {
            title = 'Wall',
            type = 'Life',
            rulestring = 'B/S012345678'
        },
        {
            title = 'Star Wars',
            type = 'Generations',
            rulestring = 'B2/S345/C4'
        },
        {
            title = 'Brian\'s Brain',
            type = 'Generations',
            rulestring = 'B2/S/3'
        },
    }
    self.selectedRule = nil
    self.selectedRule = self.rules[1].title .. ' (' .. self.rules[1].rulestring .. ')'

    -- ボード初期化
    self.board = Board {
        width = 100,
        height = 100,
        pause = false
    }
    self.baseRuleString = Board.ruleToString(self.board.rule)

    -- ボード保存関連
    self.filename = ''
    self.fileList = nil
    self.selectedFile = nil
    self.newBoardArgsTemplate = {
        width = self.board.width,
        height = self.board.height,
        option = Board.deepcopy(self.board.option),
    }
    self.newBoardArgs = nil
    self.errorMessage = nil

    -- セル設置時の設定
    self.rule = Board.deepcopy(self.board.rule)
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
    self.windows = {
        control = true,
        rule = true,
    }

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
    self.selectedRule = nil
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
