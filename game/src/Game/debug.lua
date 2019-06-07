
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

-- ユーティリティ
local util = require 'util'

-- ゲームクラス
local Game = require(folderOfThisFile .. 'class')

-- ライブラリ
local Slab = require 'Slab'
local Window = require('Slab.Internal.UI.Window')
local Input = require('Slab.Internal.UI.Input')
local binser = require 'binser'
local Neighborhood = require 'Neighborhood'

-- クラス
local Board = require 'Board'

-- スペーサー
local function spacer(w, h)
    local x, y = Slab.GetCursorPos()
    Slab.Button('', { Invisible = true, W = w, H = h })
    Slab.SetCursorPos(x, y)
end

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

-- チェックボックス（数値）
local function checkboxInteger(t, name, label)
    local changed = false

    Slab.BeginColumn(1)
    Slab.Text(label or name or '')
    Slab.EndColumn()

    Slab.BeginColumn(2)
    if Slab.CheckBox(t[name] ~= 0, '', { Id = name or label or '' }) then
        t[name] = t[name] ~= 0 and 0 or 1
        changed = true
    end
    Slab.EndColumn()

    return changed
end

-- 入力欄
local function input(t, name, label)
    local changed = false

    Slab.BeginColumn(1)
    Slab.Text(label or name or '')
    Slab.EndColumn()

    Slab.BeginColumn(2)
	local ww, wh = Slab.GetWindowActiveSize()
    local h = Slab.GetStyle().Font:getHeight()
    if Slab.Input(name, { Text = tostring(t[name]), ReturnOnText = false, W = ww, H = h }) then
        t[name] = Slab.GetInputText()
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
    if Slab.Input(tostring(t) .. name, { Text = tostring(t[name]), ReturnOnText = false, NumbersOnly = true, W = ww, H = h }) then
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

-- 入力欄（数字）
local function inputInteger(t, name, label, min, max)
    local changed = inputNumber(t, name, label, min, max)

    if changed then
        t[name] = math.floor(t[name])
    end

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
    Slab.Rectangle({ W = ww, H = h, Color = { util.hsv2rgb(unpack(color.hsv)) }, Outline = true })
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

-- デバッグ更新
function Game:updateDebug(dt, ...)
    Slab.Update(dt)

    -- メインメニューバー
    if Slab.BeginMainMenuBar() then
        -- ファイル
        if Slab.BeginMenu("File") then
            if Slab.MenuItem("New...") then
                self.board.pause = true
                self.newBoardArgs = util.deepcopy(self.newBoardArgsTemplate)
                Slab.OpenDialog('New')
            end
            if self.savable then
                if Slab.MenuItem("Open...") then
                    self.board.pause = true
                    self.fileList = nil
                    self.selectedFile = nil
                    Slab.OpenDialog('Open')
                end
                if Slab.MenuItem("Save") then
                    if #self.filename > 0 then
                        local success, message = self:saveBoard(self.filename)
                        if success then
                            Slab.CloseDialog()
                        else
                            self.errorMessage = message
                        end
                    else
                        self.board.pause = true
                        self.fileList = nil
                        Slab.OpenDialog('Save')
                    end
                end
                if Slab.MenuItem("Save As...") then
                    self.board.pause = true
                    self.fileList = nil
                    Slab.OpenDialog('Save')
                end
            end

            Slab.Separator()

            if Slab.MenuItem("Open save directory") then
                love.system.openURL('file://' .. love.filesystem.getSaveDirectory())
            end

            Slab.Separator()

            if Slab.MenuItem("Quit") then
                love.event.quit()
            end

            Slab.EndMenu()
        end

        -- ウィンドウ
        if Slab.BeginMenu("Windows") then
            if Slab.MenuItemChecked("Control", self.windows.control) then
                self.windows.control = not self.windows.control
            end
            if Slab.MenuItemChecked("Optional Rule", self.windows.rule) then
                self.windows.rule = not self.windows.rule
            end
            Slab.EndMenu()
        end

        Slab.EndMainMenuBar()
    end

    -- 各ダイアログ
    self:newDialog()
    self:openDialog()
    self:saveDialog()

    -- 各ウィンドウ
    if self.windows.control then self:controlWindow() end
    if self.windows.rule then self:ruleWindow() end

    -- カラーエディットウィンドウ
    if self.editColor then
        if self:colorEditWindow() then
            self.board:renderAllCells()
        end
    end

    -- エラーメッセージボックス
    if self.errorMessage then
        if Slab.MessageBox('Error', self.errorMessage) ~= '' then
            self.errorMessage = nil
        end
    end

    self.focusUI = Window.IsObstructedAtMouse()
    self.focusKeyboard = Input.IsFocused()
end

-- 新規ダイアログ
function Game:newDialog()
    if Slab.BeginDialog('New', { Title = 'New Board', Columns = 2 }) then
        -- ダイアログの幅が設定できないので、透明ボタンで強制設定
        local x, y = Slab.GetCursorPos()
        Slab.Button('', { Invisible = true, W = 400 })
        Slab.SetCursorPos(x, y)

        -- サイズ
        local args = self.newBoardArgs
        inputInteger(args, 'width', 'Width', 1)
        inputInteger(args, 'height', 'Height', 1)

        separator()

        -- オプション
        local option = args.option
        checkbox(option, 'crossover', 'Crossover')
        checkbox(option, 'crossoverRule', 'Crossover Rule')
        checkbox(option, 'crossoverColor', 'Crossover Color')
        separator()

        checkbox(option, 'mutation', 'Mutation')
        checkbox(option, 'mutationRule', 'Mutation Rule')
        checkbox(option, 'mutationColor', 'Mutation Color')
        inputNumber(option, 'mutationRate', 'Mutation Rate', 0, 1)
        separator()

        checkbox(option, 'aging', 'Aging')
        checkbox(option, 'agingColor', 'Aging Color')
        checkbox(option, 'agingDeath', 'Aging Death')
        separator()

        inputInteger(option, 'lifespan', 'Lifespan', 0)
        checkbox(option, 'lifespanRandom', 'Lifespan Random')
        inputNumber(option, 'lifeSaturation', 'Lifespan Saturation', 0, 1)

        Slab.Separator()

        if Slab.Button('Create', {AlignRight = true}) then
            self:resetBoard(args)
            Slab.CloseDialog()
        end
        Slab.SameLine()
        if Slab.Button('Cancel', {AlignRight = true}) then
            Slab.CloseDialog()
        end
        Slab.EndDialog()
    end
end

-- ボードのリセット
function Game:resetBoard(args, filename)
    self.board = Board {
        width  = args.width,
        height = args.height,
        cells  = args.cells,
        option = args.option,
        pause = true
    }
    self.baseRuleString = Board.ruleToString(self.board.rule)
    self.filename = filename or ''
    self.currentFilename = self.filename
    self:resetTitle()
end

-- 開くダイアログ
function Game:openDialog()
    if Slab.BeginDialog('Open', { Title = 'Open Board' }) then
        spacer(300)

        -- ファイル一覧リストボックス
        Slab.BeginListBox('OpenList')
        do
            -- ファイル一覧の更新
            if self.fileList == nil then
                self:refreshFileList()
            end

            -- ファイル一覧リストボックスアイテム
            for i, file in ipairs(self.fileList) do
                Slab.BeginListBoxItem('OpenItem_' .. i, { Selected = self.selectedFile == file })
                Slab.Text(file)
                if Slab.IsListBoxItemClicked() then
                    self.selectedFile = file
                end
                Slab.EndListBoxItem()
            end
        end
        Slab.EndListBox()

        Slab.Separator()

        -- 開くボタン
        if Slab.Button('Open', { AlignRight = true, Disabled = self.selectedFile == nil }) then
            self:openBoard(self.selectedFile)
            Slab.CloseDialog()
        end

        -- キャンセルボタン
        Slab.SameLine()
        if Slab.Button('Cancel', { AlignRight = true }) then
            Slab.CloseDialog()
        end

        Slab.EndDialog()
    end
end

-- ボードの保存
function Game:openBoard(filename)
    local data = love.filesystem.read('board/' .. filename)
    local dump = binser.dn(data)
    self:resetBoard(dump, filename)
end

-- 保存ダイアログ
function Game:saveDialog()
    if Slab.BeginDialog('Save', { Title = 'Save Board', Columns = 2 }) then
        spacer(300)

        -- ファイル一覧リストボックス
        Slab.BeginListBox('SaveList')
        do
            -- ファイル一覧の更新
            if self.fileList == nil then
                self:refreshFileList()
            end

            -- ファイル一覧リストボックスアイテム
            for i, file in ipairs(self.fileList) do
                Slab.BeginListBoxItem('SaveItem_' .. i, { Selected = self.filename == file })
                Slab.Text(file)
                if Slab.IsListBoxItemClicked() then
                    self.filename = file
                end
                Slab.EndListBoxItem()
            end
        end
        Slab.EndListBox()

        Slab.Separator()

        -- ファイル名
        input(self, 'filename', 'File Name')

        Slab.Separator()

        -- 保存ボタン
        if Slab.Button('Save', { AlignRight = true, Disabled = #self.filename == 0 }) then
            local success, message = self:saveBoard(self.filename)
            if success then
                self.currentFilename = self.filename
                self:resetTitle()
                Slab.CloseDialog()
            else
                self.errorMessage = message
            end
        end

        -- キャンセルボタン
        Slab.SameLine()
        if Slab.Button('Cancel', { AlignRight = true }) then
            self.filename = ''
            Slab.CloseDialog()
        end

        Slab.EndDialog()
    end
end

-- ボードの保存
function Game:saveBoard(filename)
    local data = binser.s(self.board:dump())
    return love.filesystem.write('board/' .. filename, data)
end

-- ファイルリストの更新
function Game:refreshFileList()
    self.fileList = {}
    local items = love.filesystem.getDirectoryItems('board')
    for i, filename in ipairs(items) do
        if love.filesystem.getInfo('board/' .. filename, 'file') then
            table.insert(self.fileList, filename)
        end
    end
end

-- 操作ウィンドウ
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
            self.randomRule and function () return Board.newRandomRule() end or self.rule,
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

    -- ルールプリセット
    if Slab.BeginComboBox('ControlRulePresets', { Selected = self.selectedRule or 'Rule Presets',  W = ww }) then
        for i, t in ipairs(self.rules) do
            if Slab.TextSelectable(t.title .. ' (' .. t.rulestring .. ')') then
                self.rule = Board.stringToRule(t.type, t.rulestring)
                self.rulestring = Board.ruleToString(self.rule)
                self.selectedRule = t.title .. ' (' .. t.rulestring .. ')'
            end
        end
        Slab.EndComboBox()
    end

    -- ルールタイプ
    do
        Slab.BeginColumn(1)
        Slab.Text('Rule')
        Slab.EndColumn()

        Slab.BeginColumn(2)
        local cw, ch = Slab.GetWindowActiveSize()
        if Slab.BeginComboBox('RuleType', { Selected = self.rule.type,  W = cw }) then
            for i, name in ipairs(Board.ruleNames) do
                if Slab.TextSelectable(name) then
                    self.rule = Board.convertRule(name, self.rule)
                    self.rulestring = Board.ruleToString(self.rule)
                    self.selectedRule = nil
                end
            end
            Slab.EndComboBox()
        end
        Slab.EndColumn()
    end

    if self.rule.type == 'LargerThanLife' then
        local changed = false
        changed = inputInteger(self.rule, 'range', 'Range', 1) or changed
        changed = inputInteger(self.rule, 'count', 'Count', 0) or changed
        changed = checkboxInteger(self.rule, 'middle', 'Middle', 0, 1) or changed
        changed = inputInteger(self.rule.survive, 'min', 'Survive Min', 0) or changed
        changed = inputInteger(self.rule.survive, 'max', 'Survive Max', 0) or changed
        changed = inputInteger(self.rule.birth, 'min', 'Birth Min', 0) or changed
        changed = inputInteger(self.rule.birth, 'max', 'Birth Max', 0) or changed

        -- 近傍
        do
            Slab.BeginColumn(1)
            Slab.Text('Neighborhood')
            Slab.EndColumn()

            Slab.BeginColumn(2)
            local cw, ch = Slab.GetWindowActiveSize()
            if Slab.BeginComboBox('Neighborhood', { Selected = Neighborhood.nameTable[self.rule.neighborhood],  W = cw }) then
                for i, name in ipairs(Neighborhood.names) do
                    if Slab.TextSelectable(name) then
                        self.rule.neighborhood = Neighborhood.nameTable[i]
                        changed = true
                    end
                end
                Slab.EndComboBox()
            end
            Slab.EndColumn()
        end

        if changed then
            self.rulestring = Board.ruleToString(self.rule)
            self.selectedRule = nil
        end
    else
        -- ルールチェックボックス
        if self.rule.birth and self.rule.survive and checkboxesRule(self.rule) then
            self.rulestring = Board.ruleToString(self.rule)
            self.selectedRule = nil
        end

        -- ルール カウント
        if self.rule.count and inputInteger(self.rule, 'count', 'Count', 2) then
            self.rulestring = Board.ruleToString(self.rule)
            self.selectedRule = nil
        end
    end

    -- ルール文字列
    if inputRulestrings(self.rulestring) then
        self.rule = Board.stringToRule(self.rule.type, Slab.GetInputText())
        self.rulestring = Board.ruleToString(self.rule)
        self.selectedRule = nil
    end

    separator()

    -- カラー
    if buttonColor(self.color, 'Color') then
        self.editColor = self.color
        self.beforeColor = util.deepcopy(self.editColor)
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
    Slab.BeginWindow('Rule', { Title = "Optional Rule", Columns = 2 })

    --[[

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
        self.beforeColor = util.deepcopy(self.editColor)
    end

    -- カラー（死）
    if buttonColor(self.board.colors.death, 'Death Color') then
        self.editColor = self.board.colors.death
        self.beforeColor = util.deepcopy(self.editColor)
    end

    separator()

    --]]

    spacer(300)

    -- オプション
    local option = self.board.option
    checkbox(option, 'crossover', 'Crossover')
    checkbox(option, 'crossoverRule', 'Crossover Rule')
    checkbox(option, 'crossoverColor', 'Crossover Color')
    separator()

    checkbox(option, 'mutation', 'Mutation')
    checkbox(option, 'mutationRule', 'Mutation Rule')
    checkbox(option, 'mutationColor', 'Mutation Color')
    inputNumber(option, 'mutationRate', 'Mutation Rate', 0, 1)
    separator()

    checkbox(option, 'aging', 'Aging')
    checkbox(option, 'agingColor', 'Aging Color')
    checkbox(option, 'agingDeath', 'Aging Death')
    separator()

    if inputInteger(option, 'lifespan', 'Lifespan', 0) then
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
    Slab.Rectangle({ W = 300, H = h, Color = { util.hsv2rgb(unpack(self.editColor.hsv)) }, Outline = true })

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
