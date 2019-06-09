
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

-- ゲームクラス
local Game = require(folderOfThisFile .. 'class')

-- ユーティリティ
local util = require 'util'

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
        {
            title = 'Bugs',
            type = 'LargerThanLife',
            rulestring = 'R5,C0,M1,S34..58,B34..45,NM'
        },
        {
            title = 'Bugsmovie',
            type = 'LargerThanLife',
            rulestring = 'R10,C0,M1,S123..212,B123..170,N'
        },
        {
            title = 'Globe',
            type = 'LargerThanLife',
            rulestring = 'R8,C0,M0,S163..223,B74..252,NM'
        },
        {
            title = 'Gnarl',
            type = 'LargerThanLife',
            rulestring = 'R1,C0,M1,S1..1,B1..1,NN'
        },
        {
            title = 'Majority',
            type = 'LargerThanLife',
            rulestring = 'R4,C0,M1,S41..81,B41..81,NM'
        },
        {
            title = 'Majorly',
            type = 'LargerThanLife',
            rulestring = 'R7,C0,M1,S113..225,B113..225,NM'
        },
        {
            title = 'ModernArt',
            type = 'LargerThanLife',
            rulestring = 'R10,C255,M1,S2..3,B3..3,NM'
        },
        {
            title = 'Waffle',
            type = 'LargerThanLife',
            rulestring = 'R7,C0,M1,S100..200,B75..170,NM'
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
    self.currentFilename = self.filename
    self.fileList = nil
    self.selectedFile = nil
    self.newBoardArgsTemplate = {
        width = self.board.width,
        height = self.board.height,
        option = util.deepcopy(self.board.option),
    }
    self.newBoardArgs = nil
    self.errorMessage = nil

    -- セル設置時の設定
    self.rule = util.deepcopy(self.board.rule)
    self.rulestring = Board.ruleToString(self.rule)
    self.color = util.deepcopy(self.board.colors.live)
    self.randomColor = true
    self.randomRule = false
    self.state = 1

    -- ボードのランダム設定
    self.board:resetRandomizeCells(self.randomColor, self.randomRule)
    self.board:renderAllCells()

    -- 移動モード
    self.move = false
    self.moveOrigin = { x = 0, y = 0 }
    self.offsetOrigin = { x = 0, y = 0 }

    -- ＵＩ
    self.focusUI = false
    self.focusKeyboard = false
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
    if self.debugMode and self.focusKeyboard then
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
    end
end

-- キー離した
function Game:keyreleased(key, scancode)
    if self.debugMode and self.focusKeyboard then
        -- debug
    end
end

-- テキスト入力
function Game:textinput(text)
    if self.debugMode and self.focusKeyboard then
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
    self.rule = Board.newRandomRule()
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

            local count
            if self.rule.count and self.state > 1 then
                count = self.state
            end

            self.board:setCell(
                x,
                y,
                self.board:newCell{
                    rule = self.rule,
                    color = self.color,
                    count = count,
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
function Game:resetTitle()
    if #self.currentFilename > 0 then
        love.window.setTitle('LIFE-LIKE - ' .. self.currentFilename)
    else
        love.window.setTitle('LIFE-LIKE')
    end
end
