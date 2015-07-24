
local Levels = {}

Levels.NODE_IS_VAILD  = 1  -- 有效的
Levels.NODE_IS_INVAILD  = 0  -- 无效
Levels.NODE_IS_EMPTY  = "X" -- 空的
Levels.NODE_IS_PORTAL_A = "A" -- A门             传送门的传送规则    A---->B---->C---->D---->E---->F---->A   单向循环
Levels.NODE_IS_PORTAL_B = "B" -- B门
Levels.NODE_IS_PORTAL_C = "C" -- C门
Levels.NODE_IS_PORTAL_D = "D" -- D门
Levels.NODE_IS_PORTAL_E = "E" -- E门
Levels.NODE_IS_PORTAL_F = "F" -- F门

local levelsData = {}

------------------样例----------begin----------
levelsData[1] = {  ----图1.png
    rows = 9,
    cols = 11,
    grid = {--棋盘网格
        {1, 1, "x", 1, 1, 1, 1, 1, "x", 1, 1},
        {1, 1, 1, "x", 1, "x", 1,"x", 1, "x", 1},
        {1, 1, "x", 1, 1, "x", 1, "x", 1, 1, 1},
        {1, 1, 1, "x", 1, "x", 1, 1, 1, "x", 1},
        {1, 1, 1, "x", "x", 1, 1, "x", 1, 1, 1},
        {1, 1, "x", 1, 1, "x", 1, 1, "x", 1, 1},
        {1, "x", 1, 1, "x", 1, 1, "x", 1, 1, 1},
        {1, 1, "x", 1, "x", 1, 1, "x", 1, 1, 1},
        {1, "x", 1, 1, 1, "x", 1, 1, "x", 1, 1}
    }
}

levelsData[2] = {  ----图2.png
    rows = 9,
    cols = 11,
    grid = {--棋盘网格
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1},
        {1, "X", 1, "X", 1, "X", 1, "X", 1, "X", 1}
    }
}

levelsData[3] = {  ----图3.png
    rows = 3,
    cols = 3,
    grid = {--棋盘网格
        {"X", 1, "X"},
        {1, 1, 1},
        {1, 1, 1}
    }
}
------------------样例----------end----------

function Levels.numLevels()
    return #levelsData
end

function Levels.get(levelIndex)
    assert(levelIndex >= 1 and levelIndex <= #levelsData, string.format("levelsData.get() - invalid levelIndex %s", tostring(levelIndex)))
    return clone(levelsData[levelIndex])
end

return Levels
