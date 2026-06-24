-- ============================================================================
-- 1. MOCK MINIMAL WOW API & BLIZZARD UI ENVIRONMENT
-- ============================================================================
local dummy_frame = {}
setmetatable(dummy_frame, {
    __index = function(t, key)
        return function(...) return t end
    end,
    __call = function(t, ...) return t end
})

CreateFrame = function(frameType, name, parent, template) return dummy_frame end
GetLocale = function() return "enUS" end

-- Catch-all for global namespace reads
setmetatable(_G, {
    __index = function(t, key)
        if key == "RaidBrowser" then
            rawset(t, "RaidBrowser", rawget(t, "RaidBrowser") or {})
            local rb = rawget(t, "RaidBrowser")
            rb.raidset = rb.raidset or dummy_frame
            rb.gui = rb.gui or { setup = function() end, update = function() end, refresh = function() end }
            rb.Print = rb.Print or function(self, msg) 
                if type(self) == "string" then msg = self end
                print("[RaidBrowser Log] " .. tostring(msg)) 
            end
            return rb
        end
        return dummy_frame
    end
})

RaidBrowser = _G.RaidBrowser

-- ============================================================================
-- 2. MOCK ACE3 / LIBSTUB FRAMEWORK
-- ============================================================================
local AceAddonMock = {
    NewAddon = function(self, name, ...)
        return _G.RaidBrowser
    end
}

LibStub = {
    NewLibrary = function(self, major, minor) return {} end,
    GetLibrary = function(self, major, silent)
        if string.match(major, "AceAddon") then return AceAddonMock end
        return {
            EmbedBlizOptions = function() end,
            RegisterChatCommand = function() end,
        }
    end
}
setmetatable(LibStub, { __call = function(t, major, silent) return t:GetLibrary(major, silent) end })

-- ============================================================================
-- 3. MOCK EXT-STD LUA ALGORITHM FUNCTIONS (CRITICAL REPAIR)
-- ============================================================================
std = {
    algorithm = {
        transform = function(t, func)
            local res = {}
            for i, v in ipairs(t) do res[i] = func(v) end
            return res
        end,
        count = function(t, value)
            local count = 0
            for _, v in ipairs(t) do if v == value then count = count + 1 end end
            return count
        end,
        fold = function(t, initial, func)
            local result = initial
            for _, v in ipairs(t) do result = func(result, v) end
            return result
        end,
        -- Merges an array with a trailing list of values
        copy_back = function(dest, source)
            local res = {}
            for _, v in ipairs(dest or {}) do table.insert(res, v) end
            for _, v in ipairs(source or {}) do table.insert(res, v) end
            return res
        end,
        -- Finds an item matching a conditional predicate function
        find_if = function(t, predicate)
            for i, v in ipairs(t or {}) do
                if predicate(v) then return i end
            end
            return nil
        end
    }
}

local fallback_meta = {
    __index = function(t, key)
        return function(arg1, arg2, ...) return arg1 or {} end
    end
}
setmetatable(std.algorithm, fallback_meta)
setmetatable(std, fallback_meta)

-- ============================================================================
-- 4. LOAD ADDON CORE SOURCE FILES IN SEQUENCE
-- ============================================================================
test_cases = test_cases or {} 

dofile("timer.lua")
dofile("event.lua")
dofile("stats.lua")
dofile("raidset_frame.lua")
dofile("core.lua") 
dofile("gui.lua")

-- ============================================================================
-- 5. MANUALLY INITIALIZE ADDON LIFECYCLE (SAFE COMPILATION BYPASS)
-- ============================================================================
if type(_G.RaidBrowser.OnInitialize) == "function" then
    _G.RaidBrowser:OnInitialize()
end

-- Fallback safety mocks if parsing functions depend on them
_G.RaidBrowser.set_timer = function() return nil end
_G.RaidBrowser.add_event_listener = function() return nil end
_G.RaidBrowser.raidset = dummy_frame
_G.RaidBrowser.gui = { setup = function() end, update = function() end, refresh = function() end }

-- ============================================================================
-- 6. RUN THE TEST SUITE
-- ============================================================================
dofile("../tests/lfm_tests.lua")