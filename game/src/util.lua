
local util = {}

-- ランダム
local random = love.math.random

-- ランダム真偽値
function util.randomBool(n)
    return random(n or 2) == 1
end

-- HSV カラーを RGB カラーに変換
function util.hsv2rgb(h, s, v)
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
function util.rgb2hsv(r, g, b)
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
function util.rgb2bit(r, g, b, a)
    r = r or 1
    g = g or 1
    b = b or 1
    a = a or 1

    return bit.bor(
        bit.lshift(math.floor(a * 255), 24),
        bit.lshift(math.floor(b * 255), 16),
        bit.lshift(math.floor(g * 255), 8),
        math.floor(r * 255)
    )
end

-- 任意の数の RGB カラーをブレンド
function util.blendRGB(...)
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
function util.blendHSV(...)
    local rgbs = {}

    local n = select("#", ...)
    for i = 1, n do
        local color = select(i, ...)
        table.insert(rgbs, { util.hsv2rgb(color[1], color[2], color[3]) })
    end

    local rgb = util.blendRGB(unpack(rgbs))

    return { util.rgb2hsv(rgb[1], rgb[2], rgb[3]) }
end

-- ディープコピー
function util.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        -- tableなら再帰でコピー
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[util.deepcopy(orig_key)] = util.deepcopy(orig_value)
        end
        setmetatable(copy, util.deepcopy(getmetatable(orig)))
    else
        -- number, string, booleanなどはそのままコピー
        copy = orig
    end
    return copy
end

-- ブーリアンテーブルを作成する
function util.makeBooleanTable(min, max, n)
    n = n or 9
    min = min or 1
    max = max or n

    t = {}
    for i = 1, n do
        t[i] = ((i - 1) >= min) and ((i - 1) <= max)
    end

    return t
end


-- 有効なインデックスの最小と最大を探す
function util.findTrueIndexMinMax(t)
    local min = nil
    for i, b in ipairs(t) do
        if b then
            min = i - 1
            break
        end
    end
    if min == nil then return nil, nil end
    local max = nil
    for i = 1, #t do
        if t[#t + 1 - i] then
            max = #t - i
            break
        end
    end
    return min, max
end

return util
