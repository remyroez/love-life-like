
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
        birth   = { min = 0, max = 0, },
        neighborhood = 'moore',
    }
end

-- 新規ランダムルール
function LargerThanLife.newRandomRule(min, max)
    return {
        type = 'LargerThanLife',
        range = 1,
        count = 0,
        middle = 0,
        survive = { min = 0, max = 0 },
        birth   = { min = 0, max = 0, },
        neighborhood = 'moore',
    }
end

-- ルールを文字列化
function LargerThanLife.toString(rule)
    rule = type(rule) == 'table' and rule or {}

    local buffer = 'R' .. rule.range

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
function LargerThanLife.toRule(str)
    str = type(str) == 'string' and str or 'B/S/C'

    local rule = LargerThanLife.newRule(0)

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
function LargerThanLife.validate(rule)
    local ok = false

    if type(rule) ~= 'table' then
    elseif rule.type ~= 'LargerThanLife' then
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

return LargerThanLife
