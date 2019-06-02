
local Life = {}

-- ユーティリティ
local util = require 'util'

-- 新規ルール
function Life.newRule()
    return {
        type = 'Life',
        --              0,     1,     2,     3,     4,     5,     6,     7      8
        birth   = { false, false, false, false, false, false, false, false, false, },
        survive = { false, false, false, false, false, false, false, false, false, }
    }
end

-- 新規ランダムルール
function Life.newRandomRule()
    return {
        type = 'Life',
        birth   = { false, util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), },
        survive = { util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), util.randomBool(), }
    }
end

-- ルールを文字列化
function Life.toString(rule)
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

    return buffer
end

-- ルールを文字列化
function Life.toRule(str)
    str = type(str) == 'string' and str or 'B/S'

    local rule = Life.newRule()

    local target = 'birth'
    for i = 1, string.len(str) do
        local c = string.sub(str, i, i)
        if c == 'B' then
            target = 'birth'
        elseif c == 'S' then
            target = 'survive'
        else
            local n = tonumber(c)
            if n then
                rule[target][n + 1] = true
            end
        end
    end

    return rule
end

-- ルールが正常かどうか
function Life.validate(rule)
    local ok = false

    if type(rule) ~= 'table' then
    elseif rule.type ~= 'Life' then
    elseif type(rule.birth) ~= 'table' then
    elseif #rule.birth ~= 9 then
    elseif type(rule.survive) ~= 'table' then
    elseif #rule.survive ~= 9 then
    else
        ok = true
    end

    return ok
end

return Life
