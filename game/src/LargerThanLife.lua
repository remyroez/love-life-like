
local LargerThanLife = {}

-- ユーティリティ
local util = require 'util'

-- ランダム
local random = love.math.random

-- 新ルール
function LargerThanLife.newRule()
    return {
        type = 'LargerThanLife',
        range = 1,
        count = 0,
        middle = 0,
        survive = { min = 0, max = 0 },
        birth = { min = 1, max = 1, },
        neighborhood = 'M',
    }
end

-- 新規ランダムルール
function LargerThanLife.newRandomRule()
    local smin = random(0, 10)
    local bmin = random(0, 10)
    return {
        type = 'LargerThanLife',
        range = random(1, 10),
        count = random(0, 100),
        middle = random(0, 1),
        survive = { min = smin, max = random(smin, smin * 2) },
        birth = { min = bmin, max = random(bmin, bmin * 2), },
        neighborhood = util.randomBool() and 'M' or 'N',
    }
end

-- ルールを文字列化
function LargerThanLife.toString(rule)
    rule = type(rule) == 'table' and rule or LargerThanLife.newRule()

    return
        'R' .. tostring(rule.range) .. ',' ..
        'C' .. tostring(rule.count) .. ',' ..
        'M' .. tostring(rule.middle) .. ',' ..
        'S' .. tostring(rule.survive.min) .. '..' .. tostring(rule.survive.max) .. ',' ..
        'B' .. tostring(rule.birth.min) .. '..' .. tostring(rule.birth.max) .. ',' ..
        'N' .. rule.neighborhood
end

-- ルールを文字列化
function LargerThanLife.toRule(str)
    str = type(str) == 'string' and str or ''

    -- 空ルール
    local rule = LargerThanLife.newRule()
    rule.range = 0
    rule.birth.min = 0
    rule.birth.max = 0

    local target = ''
    local subtarget = 'min'
    for i = 1, string.len(str) do
        local c = string.sub(str, i, i)
        if c == 'R' then
            target = 'range'
        elseif c == 'C' then
            target = 'count'
        elseif target ~= 'neighborhood' and c == 'M' then
            target = 'middle'
        elseif c == 'S' then
            target = 'survive'
            subtarget = 'min'
        elseif c == 'B' then
            target = 'birth'
            subtarget = 'min'
        elseif target ~= 'neighborhood' and c == 'N' then
            target = 'neighborhood'
        elseif c == ',' then
            -- 区切り文字（リセット）
            target = ''
        elseif c == '.' then
            subtarget = 'max'
        elseif target == 'neighborhood' and (c == 'M' or c == 'N') then
            -- 近傍
            rule.neighborhood = c
        elseif target == '' then
            -- ターゲットがないなら、数字を取るべきではない
        else
            local n = tonumber(c)
            if not n then
                -- 数字じゃない
            elseif target == 'survive' or target == 'birth' then
                -- 生存／誕生
                rule[target][subtarget] = rule[target][subtarget] * 10 + n
            else
                rule[target] = rule[target] * 10 + n
            end
        end
    end

    return rule
end

-- ルールが正常かどうか
function LargerThanLife.validate(rule)
    local ok = false

    if type(rule) ~= 'table' then
    elseif rule.type ~= 'LargerThanLife' then
    elseif type(rule.range) ~= 'number' then
    elseif type(rule.count) ~= 'number' then
    elseif type(rule.middle) ~= 'number' then
    elseif type(rule.survive) ~= 'table' then
    elseif type(rule.survive.min) ~= 'number' then
    elseif type(rule.survive.max) ~= 'number' then
    elseif type(rule.birth) ~= 'table' then
    elseif type(rule.birth.min) ~= 'number' then
    elseif type(rule.birth.max) ~= 'number' then
    elseif type(rule.birth.max) ~= 'number' then
    elseif rule.neighborhood ~= 'M' and rule.neighborhood ~= 'N' then
    else
        ok = true
    end

    return ok
end

-- ルールの情報を取得する
function LargerThanLife.getRuleElements(rules)
    local births = { min = { min = 10000, max = 0 }, max = { min = 10000, max = 0 } }
    local survives = { min = { min = 10000, max = 0 }, max = { min = 10000, max = 0 } }
    local ranges = { min = 10000, max = 1 }
    local middles = {}
    local neighborhoods = {}
    local counts = { min = 10000, max = 0 }
    for _, rule in ipairs(rules) do
        table.insert(births, rule.birth)
        table.insert(births.min, rule.birth.min)
        table.insert(births.max, rule.birth.max)
        table.insert(survives, rule.survive)
        table.insert(survives.min, rule.survive.min)
        table.insert(survives.max, rule.survive.max)

        -- 誕生範囲最低値の最低値／最大値
        if rule.birth.min < births.min.min then births.min.min = rule.birth.min
        elseif rule.birth.min < births.min.max then births.min.max = rule.birth.min
        end
        -- 誕生範囲最大値の最低値／最大値
        if rule.birth.max < births.max.min then births.max.min = rule.birth.max
        elseif rule.birth.max < births.max.max then births.max.max = rule.birth.max
        end
        -- 生存範囲最低値の最低値／最大値
        if rule.survive.min < survives.min.min then survives.min.min = rule.survive.min
        elseif rule.survive.min < survives.min.max then survives.min.max = rule.survive.min
        end
        -- 生存範囲最大値の最低値／最大値
        if rule.survive.max < survives.max.min then survives.max.min = rule.survive.max
        elseif rule.survive.max < survives.max.max then survives.max.max = rule.survive.max
        end
        -- 範囲
        table.insert(ranges, rule.range)
        if rule.range < ranges.min then
            ranges.min = rule.range
        elseif rule.range > ranges.max then
            ranges.max = rule.range
        end
        -- カウント
        table.insert(counts, rule.count)
        if rule.count < counts.min then
            counts.min = rule.count
        elseif rule.count > counts.max then
            counts.max = rule.count
        end
        -- その他
        table.insert(middles, rule.middle)
        table.insert(neighborhoods, rule.neighborhood)
    end

    return {
        ranges = ranges,
        counts = counts,
        middles = middles,
        survives = survives,
        births = births,
        neighborhoods = neighborhoods,
    }
end

return LargerThanLife
