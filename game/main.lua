
-- デバッグモード
local debugMode = true

-- ライブラリ
local lume = require 'lume'
local lurker = require 'lurker'

-- フォーカス
local focused = true
local screenshot

-- ゲーム
local game = (require 'Game')()

-- ホットスワップ後の対応
if lurker then
    lurker.postswap = function (f)
    end
end

-- 読み込み
function love.load()
    love.math.setRandomSeed(love.timer.getTime())
end

-- 更新
function love.update(dt)
    if focused then
        game:update(dt)
    end
end

-- 描画
function love.draw()
    if focused or screenshot == nil then
        -- 画面のリセット
        love.graphics.reset()

        game:draw()

    elseif screenshot then
        -- スクリーンショットを描画
        love.graphics.draw(screenshot)
    end
end

-- キー入力
function love.keypressed(key, scancode, isrepeat)
    if key == 'escape' then
        -- 終了
        love.event.quit()
    elseif key == 'printscreen' then
        -- スクリーンショット
        love.graphics.captureScreenshot(os.time() .. ".png")
    elseif key == 'f1' and debugMode and lurker then
        -- スキャン
        lurker.scan()
    elseif key == 'f5' then
        -- リスタート
        love.event.quit('restart')
    elseif key == 'f12' then
        -- デバッグモード切り替え
        debugMode = not debugMode
    else
        game:keypressed(key, scancode, isrepeat)
    end
end

-- マウス入力
function love.mousepressed(...)
    game:mousepressed(...)
end

-- フォーカス
function love.focus(f)
    focused = f

    if not f then
        -- フォーカスを失ったので、スクリーンショット撮影
        love.graphics.captureScreenshot(
            function (imageData)
                screenshot = love.graphics.newImage(imageData)
            end
        )
    elseif screenshot then
        -- フォーカスが戻ったので、スクリーンショット開放
        screenshot:release()
        screenshot = nil
    end
end

-- リサイズ
function love.resize(...)
    game:resize(...)
end
