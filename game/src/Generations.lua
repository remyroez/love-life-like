
local Generations = {}

-- ユーティリティ
local util = require 'util'

-- ランダム
local random = love.math.random

-- 新ルール
function Generations.newRule(count)
    return {
        type = 'Generations',
        --              0,     1,     2,     3,     4,     5,     6,     7      8
        birth   = { false, false, false, false, false, false, false, false, false, },
        survive = { false, false, false, false, false, false, false, false, false, },
        count = count or 2,
    }
end

-- 新規ランダムルール
function Generations.newRandomRule(min, max)
    return {
        type = 'Generations',
        birth   = { false, util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), },
        survive = { util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), },
        count = (min and max == nil) and random(2, min) or (min and max) and random(min, max) or random(2, 100),
    }
end

-- ルールを文字列化
function Generations.toString(rule)
    rule = type(rule) == 'table' and rule or {}

    local buffer = 'B'

    for i, bool in ipairs(rule.birth) do
        if bool then
            buffer = buffer .. tostring(i - 1)
        end
    end

    buffer = buffer .. '/S'

    for i, bool in ipairs(rule.survive) do
        if bool then
            buffer = buffer .. tostring(i - 1)
        end
    end

    buffer = buffer .. '/C' .. rule.count

    return buffer
end

-- ルールを文字列化
function Generations.toRule(str)
    str = type(str) == 'string' and str or 'B/S/C'

    local rule = Generations.newRule(0)

    local target = 'birth'
    for i = 1, string.len(str) do
        local c = string.sub(str, i, i)
        if c == 'B' then
            target = 'birth'
        elseif c == 'S' then
            target = 'survive'
        elseif c == 'C' then
            target = 'count'
        elseif c == '/' then
            if target == 'birth' then
                target = 'survive'
            elseif target == 'survive' then
                target = 'count'
            elseif target == 'count' then
            else
            end
        else
            local n = tonumber(c)
            if not n then
                -- 数字じゃない
            elseif target == 'count' then
                -- カウント時
                rule.count = rule.count * 10 + n
            else
                rule[target][n + 1] = true
            end
        end
    end

    return rule
end

-- ルールが正常かどうか
function Generations.validate(rule)
    local ok = false

    if type(rule) ~= 'table' then
    elseif rule.type ~= 'Generations' then
    elseif type(rule.birth) ~= 'table' then
    elseif #rule.birth ~= 9 then
    elseif type(rule.survive) ~= 'table' then
    elseif #rule.survive ~= 9 then
    elseif type(rule.count) ~= 'number' then
    else
        ok = true
    end

    return ok
end

return Generations
