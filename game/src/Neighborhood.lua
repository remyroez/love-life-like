
local Neighborhood = {}

-- ユーティリティ
local util = require 'util'

Neighborhood.cache = {}

Neighborhood.names = {
    'Moore neighborhood',
    'von Neumann neighborhood',
}

Neighborhood.nameTable = {
    'M',
    'N',
    ['M'] = 'Moore neighborhood',
    ['N'] = 'von Neumann neighborhood',
}

-- ムーア近傍の作成
function Neighborhood.makeMooreNeighborhood(range, middle)
    range = range or 1
    middle = (middle ~= nil) and (middle ~= 0) or false

    local side = range * 2 + 1
    local t = {}
    for i = 1, side do
        for j = 1, side do
            local x, y = -range + i - 1, -range + j - 1
            if not middle and x == 0 and y == 0 then
                -- 中心は入れない
            else
                table.insert(t, { x, y })
            end
        end
    end
    return t
end

-- ノイマン近傍の作成
function Neighborhood.makeVonNeumannNeighborhood(range, middle)
    range = range or 1
    middle = (middle ~= nil) and (middle ~= 0) or false

    local side = range * 2 + 1
    local t = {}
    for i = 1, side do
        for j = 1, side do
            local x, y = -range + i - 1, -range + j - 1
            if not middle and x == 0 and y == 0 then
                -- 中心は入れない
            elseif (math.abs(x) + math.abs(y)) > range then
                -- 距離範囲外は入れない
            else
                table.insert(t, { x, y })
            end
        end
    end
    return t
end

Neighborhood.maker = {
    ['M'] = Neighborhood.makeMooreNeighborhood,
    ['N'] = Neighborhood.makeVonNeumannNeighborhood,
}

-- 近傍の作成
function Neighborhood.make(name, range, middle)
    local maker = Neighborhood.maker[name]
    return maker and maker(range, middle) or nil
end

-- 近傍の取得（無ければ作成）
function Neighborhood.require(name, range, middle)
    name = name or 'M'
    range = range or 1
    middle = middle or 0

    if Neighborhood.cache[name] == nil then
        Neighborhood.cache[name] = {}
    end
    if Neighborhood.cache[name][range] == nil then
        Neighborhood.cache[name][range] = {}
    end
    if Neighborhood.cache[name][range][middle] == nil then
        Neighborhood.cache[name][range][middle] = Neighborhood.make(name, range, middle)
    end

    return Neighborhood.cache[name][range][middle]
end

return Neighborhood
