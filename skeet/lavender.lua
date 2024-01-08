local vector = require "vector"

local ffi = require("ffi")

local VGUI_System010 =  client.create_interface('vgui2.dll', 'VGUI_System010')
local VGUI_System = ffi.cast(ffi.typeof('void***'), VGUI_System010)
ffi.cdef [[
    typedef int(__thiscall* get_clipboard_text_count)(void*);
    typedef void(__thiscall* set_clipboard_text)(void*, const char*, int);
    typedef void(__thiscall* get_clipboard_text)(void*, int, const char*, int);
]]
local get_clipboard_text_count = ffi.cast('get_clipboard_text_count', VGUI_System[0][7])
local set_clipboard_text = ffi.cast('set_clipboard_text', VGUI_System[0][9])
local get_clipboard_text = ffi.cast('get_clipboard_text', VGUI_System[0][11])



local lavender = {
    lua_name = "Lavender",
    build = "KING",
    logs = {}
}

local menu = {
    ref = {
        aa = {
            enabled = ui.reference("AA", "Anti-aimbot angles" , "Enabled"),
            pitch = ui.reference("AA", "Anti-aimbot angles", "Pitch"),
            yaw_base = ui.reference("AA", "Anti-aimbot angles", "Yaw base"),
            yaw = { ui.reference("AA", "Anti-aimbot angles", "Yaw") },
            yaw_jitter = { ui.reference("AA", "Anti-aimbot angles", "Yaw jitter") },
            body_yaw = { ui.reference("AA", "Anti-aimbot angles", "Body yaw") },
            fs_body_yaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw"),
            edge_yaw = ui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
            fs = { ui.reference("AA", "Anti-aimbot angles", "Freestanding") },
            roll = ui.reference("aa", "anti-aimbot angles", "Roll"),
        },
        min_dmg = ui.reference("RAGE", "Aimbot", "Minimum damage"),
        force_sp = ui.reference("RAGE", "Aimbot", "Force safe point"),
        force_baim = ui.reference("RAGE", "Aimbot", "Force body aim"),
        qp = { ui.reference("RAGE", "Other", "Quick peek assist") },
        fd = { ui.reference("RAGE", "Other", "Duck peek assist") },
        dt = { ui.reference("RAGE", "Aimbot", "Double tap") },
        dt_hc = ui.reference("RAGE", "Aimbot", "Double tap hit chance"),
        dt_fl = ui.reference("RAGE", "Aimbot", "Double tap fake lag limit"),
        aa_hs = { ui.reference("AA", "Other", "On shot anti-aim") },
        aa_slowmotion = { ui.reference("AA", "Other", "Slow motion") },
        aa_legs = ui.reference("AA", "other", "leg movement"),
        fl_enabled = ui.reference("AA", "Fake lag", "Enabled"),
        fl_amount = ui.reference("AA", "Fake lag", "Amount"),
        fl_variance = ui.reference("AA", "Fake lag", "Variance"),
        fl_limit = ui.reference("AA", "Fake lag", "Limit"),
    },

    contains = function(self, table, val)
        if #table > 0 then
            for i=1, #table do
                if table[i] == val then
                    return true
                end
            end
        end
        return false
    end,

    rgbToHex = function(self, r, g, b)
        r = tostring(r);g = tostring(g);b = tostring(b)
        r = (r:len() == 1) and '0'..r or r;g = (g:len() == 1) and '0'..g or g;b = (b:len() == 1) and '0'..b or b

        local rgb = (r * 0x10000) + (g * 0x100) + b
        return (r == '00' and g == '00' and b == '00') and '000000' or string.format('%x', rgb)
    end,

    t = "AA",
    c = "Anti-aimbot angles",

    clr = {
        lavender = "\ad7b8ffff",
        white = " \aFFFFffff",
        def = "\ac8c8c8FF"
    },
    
    checkbox = function(self, a, name, cus)
        local newName = cus and string.format("%s%s%s-> %s", self.clr.lavender, a, self.clr.white, name) or string.format("%s[%s]%s~ %s", self.clr.lavender, a, self.clr.white, name)
        return ui.new_checkbox(self.t, self.c, newName)
    end,

    combobox = function(self, a, name, options, cus)
        local newName = cus and string.format("%s%s%s-> %s", self.clr.lavender, a, self.clr.white, name) or string.format("%s[%s]%s~ %s", self.clr.lavender, a, self.clr.white, name)

        return ui.new_combobox(self.t, self.c, newName, options)
    end,

    multicombo = function(self, a, name, options, cus)
        local newName = cus and string.format("%s%s%s-> %s", self.clr.lavender, a, self.clr.white, name) or string.format("%s[%s]%s~ %s", self.clr.lavender, a, self.clr.white, name)
        return ui.new_multiselect(self.t, self.c, newName, options)
    end,

    slider = function(self, a, name, min, max, start, bool, char, int, cus)
        local newName = cus and string.format("%s%s%s-> %s", self.clr.lavender, a, self.clr.white, name) or string.format("%s[%s]%s~ %s", self.clr.lavender, a, self.clr.white, name)
        return ui.new_slider(self.t, self.c, newName, min, max, start, bool, char, int)
    end,

    hotkey = function(self, a, name, cus)
        local newName = cus and string.format("%s%s%s-> %s", self.clr.lavender, a, self.clr.white, name) or string.format("%s[%s]%s~ %s", self.clr.lavender, a, self.clr.white, name)
        return ui.new_hotkey(self.t, self.c, newName)
    end,
}

local states = {"global", "standing", "ducking", "slow walking", "running", "jumping", "duck jumping", "dormant"}
local states_fs = {"standing", "ducking", "slow walking", "running", "jumping", "duck jumping", "dormant"}
local state_to_int = {}
local visuals = {}
local gui = {}

menu.add_menu = function()
    --menu.clr.lavender = "\ac8c8c8FF"
    gui = {
    --dumb but lets just override the function
    enable = ui.new_checkbox(menu.t, menu.c, "enable \ad7b8fffflavender\aFFFFffff.systems"),
    tab = ui.new_combobox(menu.t, menu.c, "tab", {"anti-aim", "miscellaneous", "visuals"}),

    aa = {
        --exploits = menu:multicombo("aa", "exploits", {"massive fake", "roll"}),
        keybinds = menu:multicombo("aa", "keybinds", {"freestand", "manual aa", "roll", "legit aa", "edge yaw"}),
        display_key = menu:checkbox("aa", "display keybinds"),
        freestand_disablers = menu:multicombo("aa", "freestand disablers", states_fs),
        key_freestand = menu:hotkey("     key", "freestand", true),
        key_left = menu:hotkey("     key", "left", true),
        key_right = menu:hotkey("     key", "right", true),
        key_forwards = menu:hotkey("     key", "forwards", true),
        key_roll = menu:hotkey("     key", "roll", true),

        key_legit_aa = menu:hotkey("     key", "legit anti-aim", true),
        key_edgeyaw = menu:hotkey("     key", "edge-yaw", true),

        roll_options = menu:combobox("aa", "roll options", {"peek head", "defensive"}),
        roll_disablers = menu:multicombo("aa", "roll disablers", states_fs),
        legitaaoptions = menu:combobox("aa", "legit aa", {"static", "jitter"}),

        preset = menu:combobox("aa", "preset", {"automatic", "constructor"}),
        on_shot_fix = menu:checkbox("aa", "improve \ab6b665ffexploit\ac8c8c8FF fakelag"),
        warmup_aa = menu:checkbox("aa", "\ab6b665ffwarmup\ac8c8c8FF aa"),
        debug = menu:checkbox("aa", "print aa data in console"),

        auto_mode = menu:combobox("aa", "preset", {"cycle entity", "experimental", "\ad7b8ffffNEW\aFFFFffff synchronize jitter"}),
        preset_exp_strafe = menu:checkbox("aa", "fix strafing"),
        config_mode = menu:combobox("custom", "config mode", {"builder", "\ad7b8fffflogic\aFFFFffff-based"}),
        selected_state = menu:combobox("custom", "selected state", states),
        builder = {},
    },
    misc = {
        animations = menu:multicombo("misc", "animation breakers", {"legs", "freeze legs in air", "0 pitch land", "fakelag animation"}),
        extras = menu:multicombo("misc", "extras", {"killsay", "teleport dt", "faster dt", "force defensive", "anti backstab"}),
        key_teleport = menu:hotkey("     key", "teleport key", true),
        key_defensive = menu:hotkey("     key", "defensive key", true),

        teleport_clr = ui.new_label(menu.t, menu.c, "     \ad7b8fffflocal not hittable\aFFFFffff accent"),
        teleport_clr_1 = ui.new_color_picker(menu.t, menu.c, "local not hittable", 0xd7, 0xb8, 255, 255),
        teleport2_clr = ui.new_label(menu.t, menu.c, "     \ad7b8fffflocal hit\aFFFFffff accent"),
        teleport2_clr_1 = ui.new_color_picker(menu.t, menu.c, "local hit", 0xd7, 0xb8, 255, 255),

    },
    vis = {
        main = menu:checkbox("vis", "enable"),
        indicators = menu:combobox("vis", "crosshair indicator style" , {"disabled", "default", "advanced", "modern"}),
        indcators_height = menu:slider("vis", "height", -300, 300, 45, true, "px", 1),
        new_options = menu:multicombo("vis", "indicator options", {"center", "gradient style 1"}),
        new_clr_beta = ui.new_label(menu.t, menu.c, "     \ad7b8ffffbuild\aFFFFffff accent"),
        new_clr_beta_1 = ui.new_color_picker(menu.t, menu.c, "build accent", 0xd7, 0xb8, 255, 255),
        new_clr_dsync = ui.new_label(menu.t, menu.c, "     \ad7b8ffffgradient\aFFFFffff accent"),
        new_clr_dsync_1 = ui.new_color_picker(menu.t, menu.c, "gradient accent", 0xd7, 0xb8, 255, 255),
        def_clr_beta = ui.new_label(menu.t, menu.c, "     \ad7b8ffffbuild\aFFFFffff accent"),
        def_clr_beta_1 = ui.new_color_picker(menu.t, menu.c, "def build accent", 0xd7, 0xb8, 255, 255),

        mod_clr_beta = ui.new_label(menu.t, menu.c, "     \ad7b8ffffbuild\aFFFFffff accent"),
        mod_clr_beta_1 = ui.new_color_picker(menu.t, menu.c, "mod build accent", 0xd7, 0xb8, 255, 255),
        mod_clr_exploits = ui.new_label(menu.t, menu.c, "     \ad7b8ffffexploits\aFFFFffff accent"),
        mod_clr_exploits_1 = ui.new_color_picker(menu.t, menu.c, "exploits accent", 0xd7, 0xb8, 255, 255),
        mod_clr_binds = ui.new_label(menu.t, menu.c, "     \ad7b8ffffbinds\aFFFFffff accent"),
        mod_clr_binds_1 = ui.new_color_picker(menu.t, menu.c, "binds accent", 0xd7, 0xb8, 255, 255),

        additives = menu:multicombo("vis", "additional indicators", {"logs", "arrows"}),
        logs_clr = ui.new_label(menu.t, menu.c, "     \ad7b8fffflogs\aFFFFffff accent"),
        logs_clr_1 = ui.new_color_picker(menu.t, menu.c, "logs accent", 0xd7, 0xb8, 255, 255),
        arrow_clr = ui.new_label(menu.t, menu.c, "     \ad7b8ffffarrow manual\aFFFFffff accent"),
        arrow_clr_1 = ui.new_color_picker(menu.t, menu.c, "arrow manual accent", 0xd7, 0xb8, 255, 255),
        arrow_clr2 = ui.new_label(menu.t, menu.c, "     \ad7b8ffffarrow desync\aFFFFffff accent"),
        arrow_clr2_1 = ui.new_color_picker(menu.t, menu.c, "arrow desync accent", 0xd7, 0xb8, 255, 255),

        logs_display = menu:multicombo("vis", "logs display", {"antiaim data", "hit", "miss"}),
        arrow_height = menu:slider("vis", "arrow height", -300, 300, 45, true, "px", 1),
        arrow_distance = menu:slider("vis", "arrow distance", 0, 100, 30, true, "px", 1),

        watermark_height = menu:slider("vis", "watermark height", -300, 300, 45, true, "px", 1),
        watermark_theme_clr = ui.new_label(menu.t, menu.c, "     \ad7b8ffffwatermark\aFFFFffff accent"),
        watermark_theme_clr_1 = ui.new_color_picker(menu.t, menu.c, "watermark accent", 0xd7, 0xb8, 255, 255),

    },
    }
    for i, state in ipairs(states) do
        state_to_int[states[i]] = i
        gui.aa.builder[state] = {
            active = ui.new_checkbox(menu.t, menu.c, "toggle \ad7b8ffff"..state),
            -- default builder
            desync_freestand = menu:combobox(state, "desync freestand", {"disabled", "hide", "peek"}, true),
            left_right = menu:multicombo(state, "left & right yaw options", {"body yaw", "yaw jitter", "yaw"}, true),
    
            yaw_add = menu:slider(state, "yaw", -180, 180, 0, true, "°", 1, true),
            yaw_add_left = menu:slider(state, "yaw add left", -180, 180, 0, true, "°", 1, true),
            yaw_add_right = menu:slider(state, "yaw add right", -180, 180, 0, true, "°", 1, true),
    
            yaw_jitter = menu:combobox(state, "yaw jitter", {"disabled", "center", "offset", "random", "skitter"}, true),
            yaw_jitter_add = menu:slider(state, "yaw jitter add", -180, 180, 0, true, "°", 1, true),
            yaw_jitter_add_left = menu:slider(state, "yaw jitter add left", -180, 180, 0, true, "°", 1, true),
            yaw_jitter_add_right = menu:slider(state, "yaw jitter add right", -180, 180, 0, true, "°", 1, true),
    
            body_yaw = menu:combobox(state, "body yaw" , {"static", "opposite", "jitter"}, true),
            body_add = menu:slider(state, "body yaw add", -180, 180, 0, true, "°", 1, true),
            body_add_left = menu:slider(state, "body yaw add left", -180, 180, 0, true, "°", 1, true),
            body_add_right = menu:slider(state, "body yaw add right", -180, 180, 0, true, "°", 1, true),
        
            -- logic builder
            --"avoid record overlap ~ \ad7b8ffffWIP",
            freestanding = ui.new_slider(menu.t, menu.c, "\ad7b8ffff" .. state .. "\aFFFFffff -> " .. "freestanding mode", 0, 3, 2, true, "", 1, {[0] = "disabled", [1] = "default", [2] = "advanced", [3] = "ultra"}),
            additives = menu:multicombo(state, "antiaim additives", {"anti\ad7b8ffffbruteforce\ac8c8c8FF", "center head positioning", "fake generation"}, true),
            anti_brute_options = menu:multicombo(state, "anti\ad7b8ffffbruteforce \aFFFFffffoptions", {"fake generation", "jitter generation"}, true),
            auto_fake = ui.new_slider(menu.t, menu.c, "\ad7b8ffff" .. state .. "\aFFFFffff -> " .. "fake automation", 1, 3, 2, true, "", 1, {[1] = "low", [2] = "medium", [3] = "high"}),
            head_centering = ui.new_slider(menu.t, menu.c, "\ad7b8ffff" .. state .. "\aFFFFffff -> " .. "head centering", 0, 100, 0, true, "%", 1, {[0] = "disabled", [100] = "automatic"}),
            anti_log = menu:checkbox(state, "anti log on hs", true),
        }
    end
end

menu.add_menu()

--[[
ui.set_callback(gui.vis.menu_clr_1, function()
    for i, x in next, gui do 
        if type(x) == "table" then
            for j, h in next, x do

                if type(h) == "table" then
                    for p, d in next, h do
                        print(p)
                    end
                else
                    local element = ui.get(h)
                    if type(h) ~= "table" then
                        --local text = menu:find(element, "     ")
                    end
                end
            end
        end
    end"
end)
--]]


menu.stock_jitter = function(self)
    ui.set(menu.ref.aa.pitch, "Down")
    ui.set(menu.ref.aa.yaw_base, "At targets")
    ui.set(menu.ref.aa.yaw[1], "180")
    ui.set(menu.ref.aa.yaw[2], 0)
    ui.set(menu.ref.aa.yaw_jitter[1], "Center")
    ui.set(menu.ref.aa.yaw_jitter[2], 0)
    ui.set(menu.ref.aa.body_yaw[1], "Jitter")
    ui.set(menu.ref.aa.body_yaw[2], 0)
    ui.set(menu.ref.aa.fs_body_yaw, false)
    ui.set(menu.ref.aa.roll, 0)
end

menu:stock_jitter()

menu.skeet_menu = function(self, bool)
    for i, x in pairs(menu.ref.aa) do
        if type(x) == "table" then
            ui.set_visible(x[1], bool)
            ui.set_visible(x[2], bool)
        else
            ui.set_visible(x, bool)
        end
    end
end

local disable_custom = false
local custom_freestand = false

menu.visiblity = function(self)
    local main = ui.get(gui.enable)

    local tab = ui.get(gui.tab)
    local preset = ui.get(gui.aa.preset)
    local config_mode = ui.get(gui.aa.config_mode)
    local selected_state = ui.get(gui.aa.selected_state)
    local visuals = ui.get(gui.vis.main)
    local style = ui.get(gui.vis.indicators)

    self:skeet_menu(not main)

    local antiaim = main and tab == "anti-aim"

    ui.set_visible(gui.tab, main)
    ui.set_visible(gui.aa.preset, antiaim)
    ui.set_visible(gui.aa.config_mode, antiaim and preset == "constructor")
    --ui.set_visible(gui.aa.exploits, antiaim)
    ui.set_visible(gui.aa.on_shot_fix, antiaim)
    ui.set_visible(gui.aa.warmup_aa, antiaim)

    ui.set_visible(gui.aa.auto_mode, antiaim and preset == "automatic")

    ui.set_visible(gui.aa.preset_exp_strafe, antiaim and preset == "automatic" and mode == "experimental")

    ui.set_visible(gui.aa.debug, antiaim)
    ui.set_visible(gui.aa.selected_state, antiaim and preset == "constructor")

    ui.set_visible(gui.aa.keybinds, antiaim)
    local keys_on = menu:contains(ui.get(gui.aa.keybinds), "freestand") or menu:contains(ui.get(gui.aa.keybinds), "manual aa") or menu:contains(ui.get(gui.aa.keybinds), "roll") or menu:contains(ui.get(gui.aa.keybinds), "legit aa") or menu:contains(ui.get(gui.aa.keybinds), "edge yaw")
    ui.set_visible(gui.aa.display_key, antiaim and keys_on)
    ui.set_visible(gui.aa.freestand_disablers, antiaim and ui.get(gui.aa.display_key) and menu:contains(ui.get(gui.aa.keybinds), "freestand"))
    ui.set_visible(gui.aa.key_freestand, antiaim and ui.get(gui.aa.display_key) and menu:contains(ui.get(gui.aa.keybinds), "freestand"))
    ui.set_visible(gui.aa.key_left, antiaim and ui.get(gui.aa.display_key) and menu:contains(ui.get(gui.aa.keybinds), "manual aa"))
    ui.set_visible(gui.aa.key_right, antiaim and ui.get(gui.aa.display_key) and menu:contains(ui.get(gui.aa.keybinds), "manual aa"))
    ui.set_visible(gui.aa.key_forwards, antiaim and ui.get(gui.aa.display_key) and menu:contains(ui.get(gui.aa.keybinds), "manual aa"))
    ui.set_visible(gui.aa.key_roll, antiaim and ui.get(gui.aa.display_key) and menu:contains(ui.get(gui.aa.keybinds), "roll"))
    ui.set_visible(gui.aa.roll_disablers, antiaim and ui.get(gui.aa.display_key) and menu:contains(ui.get(gui.aa.keybinds), "roll"))
    ui.set_visible(gui.aa.roll_options, antiaim and ui.get(gui.aa.display_key) and menu:contains(ui.get(gui.aa.keybinds), "roll"))
    ui.set_visible(gui.aa.key_legit_aa, antiaim and ui.get(gui.aa.display_key) and menu:contains(ui.get(gui.aa.keybinds), "legit aa"))
    ui.set_visible(gui.aa.key_edgeyaw, antiaim and ui.get(gui.aa.display_key) and menu:contains(ui.get(gui.aa.keybinds), "edge yaw"))
    ui.set_visible(gui.aa.legitaaoptions, antiaim and ui.get(gui.aa.display_key) and menu:contains(ui.get(gui.aa.keybinds), "legit aa"))

    ui.set_visible(gui.misc.animations, main and tab == "miscellaneous")
    ui.set_visible(gui.misc.extras, main and tab == "miscellaneous")
    ui.set_visible(gui.misc.key_teleport, main and tab == "miscellaneous" and menu:contains(ui.get(gui.misc.extras), "teleport dt"))
    ui.set_visible(gui.misc.key_defensive, main and tab == "miscellaneous" and menu:contains(ui.get(gui.misc.extras), "force defensive"))

    ui.set_visible(gui.misc.teleport_clr, main and tab == "miscellaneous" and menu:contains(ui.get(gui.misc.extras), "teleport dt"))
    ui.set_visible(gui.misc.teleport_clr_1, main and tab == "miscellaneous" and menu:contains(ui.get(gui.misc.extras), "teleport dt"))
    ui.set_visible(gui.misc.teleport2_clr, main and tab == "miscellaneous" and menu:contains(ui.get(gui.misc.extras), "teleport dt"))
    ui.set_visible(gui.misc.teleport2_clr_1, main and tab == "miscellaneous" and menu:contains(ui.get(gui.misc.extras), "teleport dt"))


    ui.set_visible(gui.vis.main, main and tab == "visuals")
    ui.set_visible(gui.vis.indicators, main and tab == "visuals" and visuals)
    ui.set_visible(gui.vis.indcators_height, main and tab == "visuals" and visuals  and style ~= "disabled")
    ui.set_visible(gui.vis.new_options, main and tab == "visuals" and visuals and style == "advanced")
    ui.set_visible(gui.vis.new_clr_beta_1, main and tab == "visuals" and visuals and style == "advanced")
    ui.set_visible(gui.vis.new_clr_dsync_1, main and tab == "visuals" and visuals and style == "advanced")

    ui.set_visible(gui.vis.new_clr_beta, main and tab == "visuals" and visuals and style == "advanced")
    ui.set_visible(gui.vis.new_clr_dsync, main and tab == "visuals" and visuals and style == "advanced")

    ui.set_visible(gui.vis.def_clr_beta, main and tab == "visuals" and visuals and style == "default")
    ui.set_visible(gui.vis.def_clr_beta_1, main and tab == "visuals" and visuals and style == "default")

    ui.set_visible(gui.vis.mod_clr_beta, main and tab == "visuals" and visuals and style == "modern")
    ui.set_visible(gui.vis.mod_clr_beta_1, main and tab == "visuals" and visuals and style == "modern")
    ui.set_visible(gui.vis.mod_clr_exploits, main and tab == "visuals" and visuals and style == "modern")
    ui.set_visible(gui.vis.mod_clr_exploits_1, main and tab == "visuals" and visuals and style == "modern")
    ui.set_visible(gui.vis.mod_clr_binds, main and tab == "visuals" and visuals and style == "modern")
    ui.set_visible(gui.vis.mod_clr_binds_1, main and tab == "visuals" and visuals and style == "modern")

    ui.set_visible(gui.vis.additives, main and tab == "visuals" and visuals)

    ui.set_visible(gui.vis.logs_clr, main and tab == "visuals" and visuals and menu:contains(ui.get(gui.vis.additives), "logs"))
    ui.set_visible(gui.vis.logs_clr_1, main and tab == "visuals" and visuals  and menu:contains(ui.get(gui.vis.additives), "logs"))
    ui.set_visible(gui.vis.logs_display, main and tab == "visuals" and visuals and menu:contains(ui.get(gui.vis.additives), "logs"))

    ui.set_visible(gui.vis.arrow_clr, main and tab == "visuals" and visuals and menu:contains(ui.get(gui.vis.additives), "arrows"))
    ui.set_visible(gui.vis.arrow_clr_1, main and tab == "visuals" and visuals and menu:contains(ui.get(gui.vis.additives), "arrows"))
    ui.set_visible(gui.vis.arrow_clr2, main and tab == "visuals" and visuals and menu:contains(ui.get(gui.vis.additives), "arrows"))
    ui.set_visible(gui.vis.arrow_clr2_1, main and tab == "visuals" and visuals and menu:contains(ui.get(gui.vis.additives), "arrows"))
    ui.set_visible(gui.vis.arrow_height, main and tab == "visuals" and visuals and menu:contains(ui.get(gui.vis.additives), "arrows"))
    ui.set_visible(gui.vis.arrow_distance, main and tab == "visuals" and visuals and menu:contains(ui.get(gui.vis.additives), "arrows"))

    ui.set_visible(gui.vis.watermark_height, main and tab == "visuals" and visuals and menu:contains(ui.get(gui.vis.additives), "watermark"))
    ui.set_visible(gui.vis.watermark_theme_clr, main and tab == "visuals" and visuals and menu:contains(ui.get(gui.vis.additives), "watermark"))
    ui.set_visible(gui.vis.watermark_theme_clr_1, main and tab == "visuals" and visuals and menu:contains(ui.get(gui.vis.additives), "watermark"))

    for state, item in pairs(gui.aa.builder) do
        
        local state_active = ui.get(item.active) or state == "global"
        ui.set_visible(item.active, main and tab == "anti-aim" and preset == "constructor" and selected_state == state and state ~= "global")

        local builder = main and tab == "anti-aim" and preset == "constructor" and selected_state == state and state_active and config_mode == "builder"
        local logic = main and tab == "anti-aim" and preset == "constructor" and selected_state == state and state_active and config_mode ~= "builder"

        local body_lr = menu:contains(ui.get(item.left_right), "body yaw")
        local yawjit_lr = menu:contains(ui.get(item.left_right), "yaw jitter")
        local yaw_lr = menu:contains(ui.get(item.left_right), "yaw")

        local dsync_fs = ui.get(item.desync_freestand) ~= "disabled"
        local jitter = ui.get(item.yaw_jitter) ~= "disabled"

        if not dsync_fs then
            body_lr = false yawjit_lr = false yaw_lr = false fake_lr = false
        end
        ui.set_visible(item.desync_freestand, builder)
        ui.set_visible(item.left_right, builder and dsync_fs)

        ui.set_visible(item.yaw_add, builder and not yaw_lr)
        ui.set_visible(item.yaw_add_left, builder and dsync_fs and yaw_lr)
        ui.set_visible(item.yaw_add_right, builder and dsync_fs and yaw_lr)

        ui.set_visible(item.body_yaw, builder)
        ui.set_visible(item.body_add, builder and not body_lr)
        ui.set_visible(item.body_add_left, builder and dsync_fs and body_lr)
        ui.set_visible(item.body_add_right, builder and dsync_fs and body_lr)

        ui.set_visible(item.yaw_jitter, builder)
        ui.set_visible(item.yaw_jitter_add, builder and jitter and not yawjit_lr)
        ui.set_visible(item.yaw_jitter_add_left, builder and jitter and dsync_fs and yawjit_lr)
        ui.set_visible(item.yaw_jitter_add_right, builder and jitter and dsync_fs and yawjit_lr)

        ui.set_visible(item.freestanding, logic)
        ui.set_visible(item.additives, logic)
        ui.set_visible(item.anti_brute_options, logic and menu:contains(ui.get(item.additives), "anti\ad7b8ffffbruteforce\ac8c8c8FF"))
        ui.set_visible(item.auto_fake, logic and menu:contains(ui.get(item.additives), "fake generation"))
        ui.set_visible(item.head_centering, logic and menu:contains(ui.get(item.additives), "center head positioning"))
        ui.set_visible(item.anti_log, logic and state == "global")

    end
end

local base64 = {}
extract = function(v, from, width)
    return bit.band(bit.rshift(v, from), bit.lshift(1, width) - 1)
end
function base64.makeencoder(alphabet)
    local encoder = {}
    local t_alphabet = {}
    for i = 1, #alphabet do
        t_alphabet[i - 1] = alphabet:sub(i, i)
    end
    for b64code, char in pairs(t_alphabet) do
        encoder[b64code] = char:byte()
    end
    return encoder
end
function base64.makedecoder(alphabet)
    local decoder = {}
    for b64code, charcode in pairs(base64.makeencoder(alphabet)) do
        decoder[charcode] = b64code
    end
    return decoder
end
DEFAULT_ENCODER = base64.makeencoder("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
DEFAULT_DECODER = base64.makedecoder("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")

CUSTOM_ENCODER = base64.makeencoder("KmAWpuFBOhdbI1orP2UN5vnSJcxVRgazk97ZfQqL0yHCl84wTj3eYXiD6stEGM+/=")
CUSTOM_DECODER = base64.makedecoder("KmAWpuFBOhdbI1orP2UN5vnSJcxVRgazk97ZfQqL0yHCl84wTj3eYXiD6stEGM+/=")

function base64.encode(str, encoder, usecaching)
    str = tostring(str)

    encoder = encoder or DEFAULT_ENCODER
    local t, k, n = {}, 1, #str
    local lastn = n % 3
    local cache = {}
    for i = 1, n - lastn, 3 do
        local a, b, c = str:byte(i, i + 2)
        local v = a * 0x10000 + b * 0x100 + c
        local s
        if usecaching then
            s = cache[v]
            if not s then
                s = string.char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[extract(v, 6, 6)],
                        encoder[extract(v, 0, 6)])
                cache[v] = s
            end
        else
            s = string.char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[extract(v, 6, 6)],
                    encoder[extract(v, 0, 6)])
        end
        t[k] = s
        k = k + 1
    end
    if lastn == 2 then
        local a, b = str:byte(n - 1, n)
        local v = a * 0x10000 + b * 0x100
        t[k] = string.char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[extract(v, 6, 6)],
                   encoder[64])
    elseif lastn == 1 then
        local v = str:byte(n) * 0x10000
        t[k] = string.char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[64], encoder[64])
    end
    return table.concat(t)
end
function base64.decode(b64, decoder, usecaching)
    decoder = decoder or DEFAULT_DECODER
    local pattern = "[^%w%+%/%=]"
    if decoder then
        local s62, s63
        for charcode, b64code in pairs(decoder) do
            if b64code == 62 then
                s62 = charcode
            elseif b64code == 63 then
                s63 = charcode
            end
        end
        pattern = ("[^%%w%%%s%%%s%%=]"):format(string.char(s62), string.char(s63))
    end
    b64 = b64:gsub(pattern, "")
    local cache = usecaching and {}
    local t, k = {}, 1
    local n = #b64
    local padding = b64:sub(-2) == "==" and 2 or b64:sub(-1) == "=" and 1 or 0
    for i = 1, padding > 0 and n - 4 or n, 4 do
        local a, b, c, d = b64:byte(i, i + 3)
        local s
        if usecaching then
            local v0 = a * 0x1000000 + b * 0x10000 + c * 0x100 + d
            s = cache[v0]
            if not s then
                local v = decoder[a] * 0x40000 + decoder[b] * 0x1000 + decoder[c] * 0x40 + decoder[d]
                s = string.char(extract(v, 16, 8), extract(v, 8, 8), extract(v, 0, 8))
                cache[v0] = s
            end
        else
            local v = decoder[a] * 0x40000 + decoder[b] * 0x1000 + decoder[c] * 0x40 + decoder[d]
            s = string.char(extract(v, 16, 8), extract(v, 8, 8), extract(v, 0, 8))
        end
        t[k] = s
        k = k + 1
    end
    if padding == 1 then
        local a, b, c = b64:byte(n - 3, n - 1)
        local v = decoder[a] * 0x40000 + decoder[b] * 0x1000 + decoder[c] * 0x40
        t[k] = string.char(extract(v, 16, 8), extract(v, 8, 8))
    elseif padding == 2 then
        local a, b = b64:byte(n - 3, n - 2)
        local v = decoder[a] * 0x40000 + decoder[b] * 0x1000
        t[k] = string.char(extract(v, 16, 8))
    end
    return table.concat(t)
end

local configs = {}
configs.validation_key = "aae93c994bd9f81ea4f55ced07e494f3"

-- color: userdata holding "r, g, b, a" as floats (0.0 - 1.0)
configs.convertColorToString = function(color)
	r = math_round(color.r * 255)
	g = math_round(color.g * 255)
	b = math_round(color.b * 255)
	a = math_round(color.a * 255)

    return string.format("%i, %i, %i, %i", r, g, b, a)
end


-- split "str" at "sep" and return a table of the resulting substrings
configs.splitString = function(str, sep)
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields+1] = c end)
    return fields
end

-- loop through "tbl" and save content into "saveTbl"
configs.saveTable = function(tbl, saveTbl)
    -- table loop
    for k, v in pairs(tbl) do 
        -- if "v" is a table, call the function again with adjusted arguments, basic recursion
        if type(v) == "table" then
            -- since our value is a table we need to create an empty table
            -- in our "saveTbl" with our key as the name of the table
            saveTbl[k] = {}

            -- call this function again with adjusted arguments
            -- "v" is the table thats being looped over and our newly created table
            -- is the table that the values of "v" get saved in
            configs.saveTable(v, saveTbl[k])

        else
            -- since "v" isnt a table, we can safely assume its a menu element
            -- so get its value and save it in our "saveTbl"
            if string.find(k, "clr") ~= nil then
                if string.find(k, "clr") > 0 and string.find(k, "_1") then
                    v = {
                    	type = "color",
                    	v = {ui.get(v)},
                    }
                else
                    v = ui.get(v)
                end
            else
                v = ui.get(v)
                if type(v) == "table" then
                    v = {
                        type = "multi",
                        v = v
                    }
                end
            end
            --print(k .. " " .. json.stringify(v) .. " t: " .. json.stringify(type(v)))
            --v = ui.get
            -- if "v" is of type "userdata", it means that the menu element is a color picker
            -- so get the color and save that to "saveTbl"
            saveTbl[k] = v
        end        
    end    
end

-- tbl: values to load, menuElementsTable: table to save values into, should be the table that holds the menu elements, tblName: ignore, just for debugging
configs.loadTable = function(tbl, menuElementsTable, tblName)
    -- set "tblName" to "tblName" if it isnt set
    tblName = tblName or ""

    -- loop through "tbl"
    for k, v in pairs(tbl) do 

        -- same thing as in "saveTable"
        -- if "v" is a table, call the function again with adjusted arguments
        if type(v) == "table" then
            if v.type ~= nil then 
                --print(k .. " " .. v.type .. " v: " .. json.stringify(v.v))
        		-- custom table, not a sub menu
        		-- meaning its either a color picker or a multiselect
        		if v.type == "color" then
        			-- yep, color picker
        			local r, g, b, a = unpack(v.v)
                    ui.set(menuElementsTable[k], r, g, b, a)
        		elseif v.type == "multi" then 
        			-- yep, multi select
        			ui.set(menuElementsTable[k], v.v)
        		end
        	else
	            -- our table to loop through becomes "v"
            	-- and the table to save values in becomes the table that has the same name as "km"
            	configs.loadTable(v, menuElementsTable[k], tblName .. k .. ".")
        	end
        else
        -- if the value contains spacebar it should be a color
		if menuElementsTable[k] == nil then goto skip end

        if string.find(k, "key") ~= nil then
            goto skip
        else
            ui.set(menuElementsTable[k], v)
        end
        --print(type(v))
        --if v.type ~= nil then 
        --    print("true")
        --end
			::skip::
            
           --print("Setting " .. tblName .. k .. " to " .. tostring(v) .. " (prev " .. tostring(menuElementsTable[k]) .. ")")
        end        
    end   
end

configs.clipboard_import = function(self)
    local clipboard_text_length = get_clipboard_text_count( VGUI_System )
    local clipboard_data = ''

  if clipboard_text_length > 0 then
      buffer = ffi.new('char[?]', clipboard_text_length)
      size = clipboard_text_length * ffi.sizeof('char[?]', clipboard_text_length)

      get_clipboard_text( VGUI_System, 0, buffer, size )
      clipboard_data = ffi.string( buffer, clipboard_text_length-1 )
  end

  return clipboard_data
end

configs.clipboard_export = function(self, string)
	if string then
		set_clipboard_text(VGUI_System, string, #string)
	end
end

configs.import = ui.new_button("aa", "other", "import config from clipboard", function(self)
    local protected = function()
        local clipboard = text == nil and configs:clipboard_import() or text

        local json_config = base64.decode(clipboard, CUSTOM_DECODER)

        if json_config:match(configs.validation_key) == nil then
            error("cannot_find_validation_key")
            return
        end

        json_config = json.parse(json_config)

        if json_config == nil then
            error("wrong_json")
            return
        end

        configs.loadTable(json_config, gui)
        --print("Loaded values\n" .. json.encode(handle_menu))

    end

    local status, message = pcall(protected)

    if not status then
        print("Failed to load config:", message)
        return
    end
end)

local valueTable = {}
configs.export = ui.new_button("aa", "other", "export config to clipboard", function()
    configs.saveTable(gui, valueTable)
	valueTable[configs.validation_key] = true

	local json_config = json.stringify(valueTable)
	
	json_config = base64.encode(json_config, CUSTOM_ENCODER)

    configs:clipboard_export(json_config)
end)


local helpers = {
    calcangle = function(self, localplayerxpos, localplayerypos, enemyxpos, enemyypos)
        local relativeyaw = math.atan( (localplayerypos - enemyypos) / (localplayerxpos - enemyxpos) )
        return relativeyaw * 180 / math.pi
    end,

    angle_vector = function(self, angle_x, angle_y)
        local sp, sy, cp, cy = nil
        sy = math.sin(math.rad(angle_y));
        cy = math.cos(math.rad(angle_y));
        sp = math.sin(math.rad(angle_x));
        cp = math.cos(math.rad(angle_x));
        return cp * cy, cp * sy, -sp;
    end,

    angle_diff = function(self, dest_angle, src_angle)
        local delta = math.fmod(dest_angle - src_angle, 360)
        if dest_angle > src_angle then
            if delta >= 180 then
                delta = delta - 360
            end
        else
            if delta <= -180 then
                delta = delta + 360
            end
        end
        return delta
    end,

    clamp = function(self, val, min_val, max_val)
	    return math.max(min_val, math.min(max_val, val))
    end,

    round = function(self, num, decimals)
        local mult = 10^(decimals or 0)
        return math.floor(num * mult + 0.5) / mult
    end,

    TICKS_TO_TIME = function(self, ticks)
        return globals.tickinterval() * ticks;
    end,

    extrapolateTick = function(self, player, ticks)
        local VelX,VelY,VelZ = entity.get_prop(player, 'm_vecVelocity')
    
        --local position = entity:GetProp("DT_BaseEntity", "m_vecOrigin")
        local px, py, pz = entity.hitbox_position(player, 0)
        
        return {
            px + VelX * (self:TICKS_TO_TIME(ticks)), 
            py + VelY * (self:TICKS_TO_TIME(ticks)), 
            pz + VelZ * (self:TICKS_TO_TIME(ticks))
        }
    end,


}

local ent_helper = {
    threat = 0,

    get_velocity = function(self, player)
        if player == nil then return end
        local x,y,z = entity.get_prop(player, 'm_vecVelocity')
        return math.sqrt(x*x + y*y + z*z)
    end,

    land_delay = 0,
    ldata = {
        cur_state = 0
    },

    get_state = function(self)
        local player = entity.get_local_player()
        if player == nil or not entity.is_alive(player) then
            return
        end
        local vel = self:get_velocity(player)
        local on_ground = bit.band(entity.get_prop(player, "m_fFlags"), 1) == 1
        local stand = on_ground and vel < 1.2
        local slowwalk = ui.get(menu.ref.aa_slowmotion[1]) and ui.get(menu.ref.aa_slowmotion[2])
        local move = on_ground and vel > 1.2 and not slowwalk
        local in_air = bit.band(entity.get_prop(player, "m_fFlags"), 1) == 0
        local ducking = entity.get_prop(player, "m_flDuckAmount") > 0.2 or ui.get(menu.ref.fd[1])
    
        if in_air then
            self.land_delay = globals.curtime() + 0.25
            if ducking then
                self.ldata.cur_state = "duck jumping"
            else
                self.ldata.cur_state = "jumping"
            end
        else
            if self.land_delay < globals.curtime() then
                if stand then
                    self.ldata.cur_state = "standing"
                end
                if slowwalk then
                    self.ldata.cur_state = "slow walking"
                end
                if move then
                    self.ldata.cur_state = "running"
                end
                if ducking then
                    self.ldata.cur_state = "ducking"
                end
            end
        end
        return self.ldata.cur_state
    end,

    canEnemyHitUsPeek = function(self, ent, ticks, mode, draw)
        if ent == nil then
            return
        end
    
        local localPlayer = entity.get_local_player()
        
        if localPlayer == nil then
            return
        end
        
        local ox, oy, oz = entity.hitbox_position(ent, 0)
        local o2x, o2y, o2z = entity.hitbox_position(localPlayer, 0)
        
        if ox == nil or o2x == nil then
            return
        end
    
        local local_vel = self:get_velocity(localPlayer)
        --local oScrn = Render.ScreenPosition(origin2)
        local canHitUs = false
        
        --for i = 1, ticks do
        local trace = 0
        local fraction = 0

        if mode == "enemy" then
            extrapolatedPosition = helpers:extrapolateTick(ent, ticks)
            positionX, positionY = renderer.world_to_screen(extrapolatedPosition[1], extrapolatedPosition[2], extrapolatedPosition[3])
            fraction, entindex_hit = client.trace_line(localPlayer, o2x, o2y, o2z, extrapolatedPosition[1], extrapolatedPosition[2], extrapolatedPosition[3])
            oScrnX, oscrnY = renderer.world_to_screen(o2x, o2y, o2z)
        elseif mode == "local" then
            extrapolatedPosition = helpers:extrapolateTick(localPlayer, ticks)
            positionX, positionY = renderer.world_to_screen(extrapolatedPosition[1], extrapolatedPosition[2], extrapolatedPosition[3])
            fraction, entindex_hit = client.trace_line(ent, ox, oy, oz, extrapolatedPosition[1], extrapolatedPosition[2], extrapolatedPosition[3])
            oScrnX, oscrnY = renderer.world_to_screen(ox, oy, oz)
        end


            if fraction == 1 then
                canHitUs = true
            end


            local t_r, t_g, t_b, t_a = ui.get(gui.misc.teleport_clr_1)
            local t2_r, t2_g, t2_b, t2_a = ui.get(gui.misc.teleport2_clr_1)

        -- debug code
        if draw then
            if fraction == 1 then
                renderer.line(oScrnX, oscrnY, positionX, positionY, t2_r, t2_g, t2_b, t2_a)
            else
                renderer.line(oScrnX, oscrnY, positionX, positionY, t_r, t_g, t_b, t_a)
            end
        end
            -- Render.Text(string.format("d: %.2f", trace.damage), position, Color.new(1.0, 1.0, 1.0, 1.0), 8)
        return canHitUs
        --]]
    end,
}

local player_resource = entity.get_all("CCSPlayerResource")[1]
local antiaim = {

    p_data = {
        yaw_status = "default",
        indexed_angle = 0,
        last_miss = 0,
        best_angle = 0,
        misses = { }, --this is either nil, 1 or 2
        hit_reverse = { },
        log = {},
    },

    log_check = function(self)
        for j, x in next, self.p_data.log do
            local hp = entity.get_prop(x.idx, "m_iHealth")
            local team = entity.get_prop(x.idx, "m_iTeamNum")
            if hp == nil or team == nil then
                --print("id: " .. j .. " entid: " .. x.idx .. " hp: " .. tostring(hp))
                --print ("succesfully removed") 
                table.remove(self.p_data.log, j)
            else
                if team == entity.get_prop(me, "m_iTeamNum") then
                    --print ("succesfully removed " .. entity.get_player_name(j) .. " due to being same team") 
                    table.remove(self.p_data.log, j)
                end
            end
        end
    end,

    generate_log = function(self)
        local ents = entity.get_players(true)
        local me = entity.get_local_player()
        for i=1, #ents do
            local enemy = ents[i]
            local hp = entity.get_prop(enemy, "m_iHealth")
            if enemy == nil then goto skip end
            if entity.get_prop(enemy, "m_iTeamNum") == entity.get_prop(me, "m_iTeamNum") then goto skip end
            if player == me then goto skip end
                if self.p_data.log[enemy] == nil then
                    self.p_data.log[enemy] = {
                        idx = enemy,
                        name = entity.get_player_name(enemy),
                        steam = entity.get_steam64(enemy),
                        jitter = math.random(55, 80),
                        fake = {c = 0, j = 0, f = 0, y = 0},
                        fake_a = {upd = true, c = 0, y = 0, j = 0, b = 0, f = 0}, --c is counter for preset
                        yaw = {y = 0, y2 = 0},
                        fakes = {f = 0, f2 = 0},
                        dyn_jitter = 0,
                        should_update = true,
                        last_miss = 0,
                        misses = 0,            
                    }
                    --print("generated log for " .. entity.get_player_name(enemy))
                    --self:log_check()
                end
                
            ::skip::
        end
        --self:log_check()
    end,

    generate_yaw = function(self, threat)
        if self.p_data.log[threat] == nil then return 45 end
            if self.p_data.log[threat].jitter < 70 then
                a = math.random(65, 80)
            elseif self.p_data.log[threat].jitter >= 70 then
                a = math.random(55, 70)
            else
                a = math.random(55, 80)
            end
        return a
    end,

    roll_active = false,

    preset = {
        low_fake = {
            aa1 = {j = 0, f = 0, y = 0},
            aa2 = {j = 0, f = 4, y = 0},
            aa3 = {j = 0, f = 11, y = 0},
            aa4 = {j = 0, f = 16, y = 0},
            aa5 = {j = 0, f = 20, y = 0},
            aa6 = {j = 0, f = 28, y = 0},
            aa7 = {j = 0, f = 39, y = -5},
            aa8 = {j = 10, f = 48, y = -5},
            aa9 = {j = 7, f = 60, y = -5},
            aa10 = {j = 5, f = 106, y = -5},
        },
        default = {
            aa1 = {j = 0, f = 0, y = 0},
            aa2 = {j = 0, f = 5, y = 2},
            aa3 = {j = 0, f = 4, y = 0},
            aa4 = {j = 0, f = 11, y = -2},
            aa5 = {j = 0, f = 16, y = 0},
            aa6 = {j = 0, f = 48, y = 5},
            aa7 = {j = 0, f = 42, y = 0},
            aa8 = {j = 0, f = 53, y = 5},
            aa9 = {j = 0, f = 20, y = 0},
            aa10 = {j = 0, f = 106, y = -2},
        },
        maximum = {
            aa1 = {j = 2, f = 0, y = -3},
            aa2 = {j = 0, f = 5, y = 2},
            aa3 = {j = 9, f = 4, y = 0},
            aa4 = {j = 0, f = 11, y = -2},
            aa5 = {j = 5, f = 11, y = 0},
            aa6 = {j = 0, f = 48, y = 5},
            aa7 = {j = 4, f = 16, y = -2},
            aa8 = {j = 0, f = 53, y = 5},
            aa9 = {j = 3, f = 178, y = 0},
            aa10 = {j = 0, f = 106, y = -2},
        },
        --[[
        cycle = {
            aa1 = {y = 5, j = 74, b = 0, f = 60},
            aa2 = {y = 10, j = 69, b = 0, f = 57},
            aa3 = {y = 10, j = 75, b = 0, f = 60},
            aa4 = {y = 3, j = 65, b = 0, f = 57},
            aa5 = {y = 9, j = 77, b = 0, f = 60},
            aa6 = {y = 5, j = 69, b = 0, f = 57},
            aa7 = {y = 3, j = 75, b = 0, f = 60},
            aa8 = {y = 3, j = 68, b = 0, f = 57},
            aa9 = {y = 1, j = 75, b = 0, f = 60},
            aa10 = {y = 1, j = 68, b = 0, f = 57}
        },
        --]]
        cycle = {
            aa1 = {y = 5, j = 74, b = 0, f = 60},
            aa2 = {y = 10, j = 69, b = 0, f = 60},
            aa3 = {y = 10, j = 75, b = 0, f = 60},
            aa4 = {y = 3, j = 80, b = 0, f = 60},
            aa5 = {y = 9, j = 77, b = 0, f = 60},
            aa6 = {y = 5, j = 83, b = 0, f = 60},
            aa7 = {y = 3, j = 75, b = 0, f = 60},
            aa8 = {y = 3, j = 68, b = 0, f = 60},
            aa9 = {y = 1, j = 75, b = 0, f = 60},
            aa10 = {y = 1, j = 68, b = 0, f = 60}
        },
        logic = {
            --aa1 = {y = 9, j = 72, b = 98, f = 59},
            aa1 = {y = 14, j = 75, b = 0, f = 60},
            --aa2 = {y = 2, j = 65, b = -48, f = 58},
            aa2 = {y = 9, j = 77, b = 28, f = 60},
            aa3 = {y = 10, j = 73, b = 77, f = 60},
            --aa3 = {y = 5, j = 66, b = 127, f = 59},
            aa4 = {y = 10, j = 77, b = 136, f = 60},
            --aa4 = {y = -3, j = 64, b = 78, f = 60},
            aa5 = {y = 3, j = 73, b = 28, f = 60},
            --aa6 = {y = 18, j = 64, b = 180, f = 60},
            aa6 = {y = 9, j = 70, b = 151, f = 60},
            aa7 = {y = 5, j = 73, b = 0, f = 59},
        },

        jitter = {
            aa1 = {j = 65},
            aa2 = {j = 70},
            aa3 = {j = 69},
            aa4 = {j = 72},
            aa5 = {j = 79},
            aa6 = {j = 75},
            aa7 = {j = 80},
            aa8 = {j = 74},
            aa9 = {j = 84},
            aa10 = {j = 70},
        },
    },

    fake_automation = function(self, mode, threat, anti_bf)
        a = 0
        if self.p_data.log[threat] == nil then return end
        if self.p_data.log[threat].fake.c == 0 then
            self.p_data.log[threat].fake.c = math.random(0, 10)
        end

        self.p_data.log[threat].fake.c = self.p_data.log[threat].fake.c + 1

        if self.p_data.log[threat].fake.c > 10 then
            self.p_data.log[threat].fake.c = 1
        end

        if mode == 1 then
            self.p_data.log[threat].fake.j = self.preset.low_fake["aa" .. self.p_data.log[threat].fake.c].j
            self.p_data.log[threat].fake.f = self.preset.low_fake["aa" .. self.p_data.log[threat].fake.c].f
        elseif mode == 2 then
            self.p_data.log[threat].fake.j = self.preset.default["aa" .. self.p_data.log[threat].fake.c].j
            self.p_data.log[threat].fake.f = self.preset.default["aa" .. self.p_data.log[threat].fake.c].f
            self.p_data.log[threat].fake.y = self.preset.default["aa" .. self.p_data.log[threat].fake.c].y
        elseif mode == 3 then
            self.p_data.log[threat].fake.j = self.preset.maximum["aa" .. self.p_data.log[threat].fake.c].j
            self.p_data.log[threat].fake.f = self.preset.maximum["aa" .. self.p_data.log[threat].fake.c].f
            self.p_data.log[threat].fake.y = self.preset.maximum["aa" .. self.p_data.log[threat].fake.c].y
        end

        if menu:contains(ui.get(gui.vis.additives), "logs") and menu:contains(ui.get(gui.vis.logs_display), "antiaim data") then
            local red, green, blue = ui.get(gui.vis.logs_clr_1)
            local clr = '\a' .. menu:rgbToHex(red, green, blue) ..'ff'
            local w = "\aFFFFffff"
            if anti_bf then
                visuals:add_to_log(clr .. entity.get_player_name(threat) .. w .. " activated anti-bruteforce - " .. clr .. "[" .. self.p_data.log[threat].misses .. "]" .. w)
                    
                --string.format(
                --    "%s activated anti-bruteforce - [%s]!", entity.get_player_name(threat), self.p_data.log[threat].misses)
                    --"anti bf fake for %s succesfully - j: [%i] f: [%i] y: [%i]", entity.get_player_name(threat), self.p_data.log[threat].fake.j, self.p_data.log[threat].fake.f, self.p_data.log[threat].fake.y)
                --)
            else
                visuals:add_to_log("automation fake for " .. clr .. entity.get_player_name(threat) .. w .. " succesfully - j: " .. clr .. "[" .. self.p_data.log[threat].fake.j .. "]" .. w .. " f: " .. clr .. "[" .. self.p_data.log[threat].fake.f .. "]" .. w .. " y: " .. clr .. "[" .. self.p_data.log[threat].fake.y .. "]" .. w)

                --visuals:add_to_log(string.format(
                --    "automation fake for %s succesfully - j: [%i] f: [%i] y: [%i]", entity.get_player_name(threat), self.p_data.log[threat].fake.j, self.p_data.log[threat].fake.f, self.p_data.log[threat].fake.y)
               -- )
            end
        end

        if ui.get(gui.aa.debug) then
            local name = string.lower(lavender.lua_name) .. " " .. string.upper(lavender.build)
            if anti_bf then
                print(string.format(
                    "%s -> anti bf fake for %s succesfully - j: [%i] f: [%i] y: [%i]", name, entity.get_player_name(threat), self.p_data.log[threat].fake.j, self.p_data.log[threat].fake.f, self.p_data.log[threat].fake.y)
                )
            else
                print(string.format(
                    "%s -> automation fake for %s succesfully - j: [%i] f: [%i] y: [%i]", name, entity.get_player_name(threat), self.p_data.log[threat].fake.j, self.p_data.log[threat].fake.f, self.p_data.log[threat].fake.y)
                )                
            end
        end
    end,

    reset_fake = function(self, mode, threat) 
        if self.p_data.log[threat] == nil then return end
        self.p_data.log = {}

        self:generate_log()
        self:fake_automation(mode, threat)
    end,

    get_fake = function(self, threat)
        if threat == nil then return end
        if self.p_data.log[threat] then
            a = self.p_data.log[threat].fake.j
            b = self.p_data.log[threat].fake.f
            c = self.p_data.log[threat].fake.y
            if a ~= nil or b ~= nil or c ~= nil then
                return {0,0,0}
            end
            return {a, b, c}
        end
    end,

    calculate_yaw = function(self, cmd, mode)
        local localplayer = entity.get_local_player()
        if localplayer == nil or not entity.is_alive(localplayer) then
            return
        end
        math.randomseed(client.unix_time())
        local target = client.current_threat()
        if self.p_data.log[target] then
            if mode == "experimental" then
                if self.p_data.log[target].should_update then
                    if self.p_data.log[target].yaw == nil then self.p_data.log[target].yaw = {y = 0, y2 = 0} end

                    self.p_data.log[target].yaw.y = math.random(-28, -22)
                    self.p_data.log[target].yaw.y2 = math.abs(self.p_data.log[target].yaw.y) + math.random(10, 15) + 5
                    self.p_data.log[target].fakes.f = math.random(65, 121)
                    self.p_data.log[target].fakes.f2 = -self.p_data.log[target].fakes.f - 5
                    self.p_data.log[target].should_update = false
                end
            return { self.p_data.log[target].yaw.y, self.p_data.log[target].yaw.y2, self.p_data.log[target].fakes.f, self.p_data.log[target].fakes.f2 }
        end

        if mode == "synchronize" then
            if self.p_data.log[target].should_update then
                self.p_data.log[target].dyn_jitter = math.random(75, 84)
                self.p_data.log[target].should_update = false
            end
            return { self.p_data.log[target].dyn_jitter }
            end
        end
        return {0, 0}
    end,


    update_auto = function(self, threat, anti_bf)
        local mode = ui.get(gui.aa.auto_mode)
        if mode == "cycle entity" then
            if self.p_data.log[threat].fake_a.c == 0 then
                self.p_data.log[threat].fake_a.c = math.random(1, 10)
            end

            self.p_data.log[threat].fake_a.c = self.p_data.log[threat].fake_a.c + 1

            if self.p_data.log[threat].fake_a.c > 10 then
                self.p_data.log[threat].fake_a.c = 1
            end

            if anti_bf then
                self.p_data.log[threat].fake_a.y = self.preset.cycle["aa" .. self.p_data.log[threat].fake_a.c].y
                self.p_data.log[threat].fake_a.j = self.preset.jitter["aa" .. self.p_data.log[threat].fake_a.c].j
            else
                self.p_data.log[threat].fake_a.y = self.preset.cycle["aa" .. self.p_data.log[threat].fake_a.c].y
                self.p_data.log[threat].fake_a.j = self.preset.cycle["aa" .. self.p_data.log[threat].fake_a.c].j
                self.p_data.log[threat].fake_a.b = self.preset.cycle["aa" .. self.p_data.log[threat].fake_a.c].b
                self.p_data.log[threat].fake_a.f = self.preset.cycle["aa" .. self.p_data.log[threat].fake_a.c].f
            end
        end
        self.p_data.log[threat].fake_a.upd = false
    end,

    antibf_impact = function(self, e)
        --if not ui.get(menu.main_aa) then return end
        local me = entity.get_local_player()

        if not entity.is_alive(me) then return end

        local shooter_id = e.userid
        local shooter = client.userid_to_entindex(shooter_id)

        -- Distance calculations can sometimes bug when the entity is dormant hence the 2nd check.
        if not entity.is_enemy(shooter) or entity.is_dormant(shooter) then return end
    
        local lx, ly, lz = entity.hitbox_position(me, "head_0")
        
        local ox, oy, oz = entity.get_prop(me, "m_vecOrigin")
        local ex, ey, ez = entity.get_prop(shooter, "m_vecOrigin")
    
        local dist = ((e.y - ey)*lx - (e.x - ex)*ly + e.x*ey - e.y*ex) / math.sqrt((e.y-ey)^2 + (e.x - ex)^2)
        
        local state = ent_helper:get_state()

        local preset = ui.get(gui.aa.preset)
        local mode = ui.get(gui.aa.config_mode)

        local enabled = ui.get(gui.aa.builder[state].active)
        local path = enabled and gui.aa.builder[state] or gui.aa.builder["global"]    

        local anti_bf = menu:contains(ui.get(path.additives), "anti\ad7b8ffffbruteforce\ac8c8c8FF")
        local anti_brute_options = ui.get(path.anti_brute_options)

        local red, green, blue = ui.get(gui.vis.logs_clr_1)
        local clr = '\a' .. menu:rgbToHex(red, green, blue) ..'ff'
        local w = "\aFFFFffff"

        local auto_fake = menu:contains(anti_brute_options, "fake generation") 
        -- 32 is our miss detection radius and the 2nd check is to avoid adding more than 1 miss for a singular bullet (bullet_impact gets called mulitple times per shot).
        if math.abs(dist) <= 32 and globals.curtime() - self.p_data.last_miss > 0.015 then
            self.p_data.last_miss = globals.curtime()
            if self.p_data.log[shooter] == nil then
                self.p_data.log[shooter] = {
                        idx = shooter,
                        jitter = math.random(55, 80),
                        fake = {c = 0, j = 0, f = 0},
                        fake_a = {c = 0, y = 0, j = 0, b = 0, f = 0}, --c is counter for preset
                        last_miss = 0,
                        misses = 0,
                    }
                    else
                    local auto_mode = ui.get(gui.aa.auto_mode)
                    local name = string.lower(lavender.lua_name) .. " " .. string.upper(lavender.build)

                    if preset == "automatic" and auto_mode == "\ad7b8ffffNEW\aFFFFffff synchronize jitter" then
                        if menu:contains(ui.get(gui.vis.additives), "logs") and menu:contains(ui.get(gui.vis.logs_display), "antiaim data") then
                            visuals:add_to_log("anti-bruteforce " .. clr .. entity.get_player_name(shooter) .. w .. " succesfully generated!" .. w)

                            --visuals:add_to_log("anti-bruteforce " .. entity.get_player_name(shooter) .. " succesfully generated - [" .. self.p_data.log[shooter].fake_a.j .. "]")
                        end

                        if ui.get(gui.aa.debug) then
                            print(name .. " -> anti bf jitter generated " .. entity.get_player_name(shooter) .. " succesfully!")
                            --self:update_auto(shooter, true)
                        end

                    end
                    
                    if preset == "automatic" and auto_mode == "cycle entity" then
                        if self.p_data.log[shooter].fake_a.j >= 70 then
                            self.p_data.log[shooter].fake_a.j = math.random(64, 69)
                        else
                            self.p_data.log[shooter].fake_a.j = math.random(70, 80)
                        end

                        if menu:contains(ui.get(gui.vis.additives), "logs") and menu:contains(ui.get(gui.vis.logs_display), "antiaim data") then
                            visuals:add_to_log("anti-bruteforce " .. clr .. entity.get_player_name(shooter) .. w .. " succesfully generated - " .. clr .. "[" .. self.p_data.log[shooter].fake_a.j .. "]" .. w)

                            --visuals:add_to_log("anti-bruteforce " .. entity.get_player_name(shooter) .. " succesfully generated - [" .. self.p_data.log[shooter].fake_a.j .. "]")
                        end

                        if ui.get(gui.aa.debug) then
                            print(name .. " -> anti bf jitter generated " .. entity.get_player_name(shooter) .. " succesfully - [" .. self.p_data.log[shooter].fake_a.j .. "]")
                            --self:update_auto(shooter, true)
                        end
                    end
                    
                    if preset == "automatic" and auto_mode == "experimental" then
                        if menu:contains(ui.get(gui.vis.additives), "logs") and menu:contains(ui.get(gui.vis.logs_display), "antiaim data") then
                            visuals:add_to_log("anti-bruteforce " .. clr .. entity.get_player_name(shooter) .. w .. " succesfully generated!")

                            --visuals:add_to_log("anti-bruteforce " .. entity.get_player_name(shooter) .. " succesfully generated")
                        end

                        if ui.get(gui.aa.debug) then
                            print(name .. " -> anti bf jitter generated " .. entity.get_player_name(shooter) .. " succesfully")
                        end
                        self.p_data.log[shooter].should_update = true
                    end

                    if preset == "constructor" and mode == "\ad7b8fffflogic\aFFFFffff-based" then
                        if auto_fake then
                            local auto_fake_opt = ui.get(path.auto_fake)
                            self:fake_automation(auto_fake_opt, shooter, true)
                        end
                        if menu:contains(anti_brute_options, "jitter generation") then
                            self.p_data.log[shooter].jitter = self:generate_yaw(shooter)
                            if menu:contains(ui.get(gui.vis.additives), "logs") and menu:contains(ui.get(gui.vis.logs_display), "antiaim data") then
                                --visuals:add_to_log("anti-bruteforce jitter generated " .. clr .. entity.get_player_name(shooter) .. w .. " succesfully - " .. clr .. "[" .. self.p_data.log[shooter].jitter .. "]" .. w)

                                --visuals:add_to_log("anti bf jitter generated " .. entity.get_player_name(shooter) .. " succesfully - [" .. self.p_data.log[shooter].jitter .. "]")
                            end

                            if ui.get(gui.aa.debug) then
                                print(name .. " -> anti bf jitter generated " .. entity.get_player_name(shooter) .. " succesfully - [" .. self.p_data.log[shooter].jitter .. "]")
                            end
                        end
                    end
                    self.p_data.log[shooter].misses = self.p_data.log[shooter].misses + 1
                    self.p_data.log[shooter].last_miss = globals.curtime()
                end

            --local txtlastmiss = math.ceil(self.p_data.log[shooter].last_miss)
            --print("anti-bruteforce - " .. entity.get_player_name(shooter) .. " missed [" .. self.p_data.log[shooter].misses .. "]/[" .. txtlastmiss .. "]")
    
    end

    end,

    antibf_death = function(self, e)        
        local victim_id = e.userid
        local victim = client.userid_to_entindex(victim_id)
    
        if victim ~= entity.get_local_player() then return end
    
        local attacker_id = e.attacker
        local attacker = client.userid_to_entindex(attacker_id)
    
        if not entity.is_enemy(attacker) then return end
    
        if not e.headshot then return end

        local preset = ui.get(gui.aa.preset)
        local mode = ui.get(gui.aa.config_mode)            
        local path = gui.aa.builder["global"]
        local anti_log = mode == "\ad7b8fffflogic\aFFFFffff-based" and ui.get(path.anti_log) 
    
        local red, green, blue = ui.get(gui.vis.logs_clr_1)
        local clr = '\a' .. menu:rgbToHex(red, green, blue) ..'ff'
        local w = "\aFFFFffff"

        if self.p_data.misses[attacker] == nil or (globals.curtime() - self.p_data.last_miss < 0.06 and self.p_data.misses[attacker] == 1) then
            math.randomseed(client.unix_time())
            if self.p_data.log[attacker] == nil then
                self.p_data.log[attacker] = {
                    idx = attacker,
                    jitter = math.random(55, 80),
                    fake = {c = 0, j = 0, f = 0},
                    last_miss = 0,
                    misses = 0,
                }
            else
                if preset == "automatic" and auto_mode == "cycle entity" then
                    self:update_auto(attacker)
                end

                if preset == "automatic" and auto_mode == "experimental" or preset == "automatic" and auto_mode == "\ad7b8ffffNEW\aFFFFffff synchronize jitter" then
                    self.p_data.log[attacker].should_update = true
                end

                if preset == "constructor" and mode == "\ad7b8fffflogic\aFFFFffff-based" then
                    local name = string.lower(lavender.lua_name) .. " " .. string.upper(lavender.build)

                    if menu:contains(ui.get(gui.vis.additives), "logs") and menu:contains(ui.get(gui.vis.logs_display), "antiaim data") then
                        visuals:add_to_log("headshot by " .. clr .. entity.get_player_name(attacker) .. w .. " aa hit - j: " .. clr .. "[" .. self.p_data.log[attacker].fake.j .. "]" .. w .. " f: " .. clr .. "[" .. self.p_data.log[attacker].fake.f .. "] " .. w .. " y: " .. clr .. "[" .. self.p_data.log[attacker].fake.y .. "]" .. w)

                        --visuals:add_to_log(string.format(
                       --     "hs by %s aa hit - j: [%i] f: [%i] y: [%i]", entity.get_player_name(attacker), self.p_data.log[attacker].fake.j, self.p_data.log[attacker].fake.f, self.p_data.log[attacker].fake.y)
                       -- )
                    end

                    if ui.get(gui.aa.debug) then
                        print(string.format(
                            "%s -> hs by %s aa hit - j: [%i] f: [%i] y: [%i]", name, entity.get_player_name(attacker), self.p_data.log[attacker].fake.j, self.p_data.log[attacker].fake.f, self.p_data.log[attacker].fake.y)
                        )
                    end   

                    local auto_fake_opt = ui.get(path.auto_fake)
                    self:fake_automation(auto_fake_opt, attacker)
                    self.p_data.log[attacker].jitter = self:generate_yaw(attacker)
                    if menu:contains(ui.get(gui.vis.additives), "logs") and menu:contains(ui.get(gui.vis.logs_display), "antiaim data") then
                        visuals:add_to_log("generated new for " .. clr .. entity.get_player_name(attacker) .. w .. " - j: " .. clr .. "[" .. self.p_data.log[attacker].fake.j .. "]" .. w .. " f: " .. clr .. "[" .. self.p_data.log[attacker].fake.f .. "] " .. w .. " y: " .. clr .. "[" .. self.p_data.log[attacker].fake.y .. "]" .. w)

                        --visuals:add_to_log(string.format(
                        --    "generated new for %s - j: [%i] f: [%i] y: [%i]", entity.get_player_name(attacker), self.p_data.log[attacker].fake.j, self.p_data.log[attacker].fake.f, self.p_data.log[attacker].fake.y)
                        --)
                    end
                    if ui.get(gui.aa.debug) then
                        print(string.format(
                            "%s -> generated new for %s - j: [%i] f: [%i] y: [%i]", name, entity.get_player_name(attacker), self.p_data.log[attacker].fake.j, self.p_data.log[attacker].fake.f, self.p_data.log[attacker].fake.y)
                        )
                    end            
                end
            end
        end
    end,
    
    fs_data = {
        side = 0,
        last_side = 0
    },

    wall_detect = function(self, cmd)
        local x, y, z = client.eye_position()
        local junk, yaw = client.camera_angles()
        local trace_data = {left = 0, right = 0}
        for i = yaw - 90, yaw + 90, 30 do
            if i ~= yaw then
                local px, py, pz = x + 256 * math.cos(math.rad(i)), y + 256 * math.sin(math.rad(i)), z
                local fraction = client.trace_line(entity.get_local_player(), x, y, z, px, py, pz)
                local side = i < yaw and "left" or "right"
                
                trace_data[side] = trace_data[side] + fraction
            end
        end
        if trace_data.left > 1 and trace_data.right < 1 then
            return true
        end
        if trace_data.right > 1 and trace_data.left < 1 then
            return true
        end
        return false
    end,

    get_freestand = function(self, cmd, mode)
        local me = entity.get_local_player()

        if not me or entity.get_prop(me, "m_lifeState") ~= 0 then return end
        local now = globals.curtime()
        local index, damage = 0
        local threat = ent_helper.threat

        if mode == 3 then
            if threat == nil then return end
            if ent_helper:get_velocity(threat) < ent_helper:get_velocity(me) + 5 then
                if entity.get_prop(threat, "m_iHealth") < 50 then
                    ui.set(menu.ref.aa.fs[1], "Default")
                    ui.set(menu.ref.aa.fs[2], "Always on")
                    return
                else
                    ui.set(menu.ref.aa.fs[2], "-")
                end
            else
                ui.set(menu.ref.aa.fs[2], "-")
            end
            if not self:wall_detect() then self.fs_data.side = -1 return end
        else
            ui.set(menu.ref.aa.fs[2], "-")
        end

        if entity.is_alive(threat) then
            local lx, ly, lz = entity.get_prop(entity.get_local_player(), "m_vecOrigin")
            local enemyx, enemyy, enemyz = entity.get_prop(threat, "m_vecOrigin")
            local yaw = helpers:calcangle(lx, ly, enemyx, enemyy)
            local dir_x, dir_y, dir_z = helpers:angle_vector(0, (yaw))
            local end_x = lx + dir_x * 55
            local end_y = ly + dir_y * 55
            local end_z = lz + 80
            index, damage = client.trace_bullet(threat, enemyx, enemyy, enemyz + 70, end_x, end_y, end_z,true)
        end

        if damage == nil then 
            return 
        end

        if mode == 2 then
            if damage > 1 then
                self.fs_data.side = 0
                return
            end
        end

        if damage < 1 then
            --local _mode = getmenu(lua_menu.custom.stand.freestand)

            local x, y, z = client.eye_position()
            --local x, y, z = entity.get_origin(entity.get_local_player())
            local _, yaw = client.camera_angles()


            local trace_data = {left = 0, right = 0}

            for i = yaw - 90, yaw + 90, 30 do
                if i ~= yaw then
                    local rad = math.rad(i)

                    local px, py, pz = x + 256 * math.cos(rad), y + 256 * math.sin(rad), z

                    local fraction = client.trace_line(me, x, y, z, px, py, pz)
                    local side = i < yaw and "left" or "right"

                    trace_data[side] = trace_data[side] + fraction
                end
            end

            self.fs_data.side = trace_data.left < trace_data.right and 1 or 2

            if self.fs_data.side == self.fs_data._lastside then 
                return 
            end

            self.fs_data.last_side = self.fs_data.side
        end
    end,

    data = {
        feet_yaw = 0,
        server_feet_yaw = 0,
        abs_yaw = 0
    },

    head_centering = function(self, amount, mode, threat)
        ui.set(menu.ref.aa.yaw[2], self.var.aa_dir == 0 and 0 or self.var.aa_dir)
        a = 0
        r = 0
        if mode == 1 then   
            local body = ui.get(menu.ref.aa.body_yaw[1])
            local a = amount / 100 * 90
            local r = math.ceil(a / 8)
        return {r, a}
        elseif mode == 2 then
            if threat == nil then
                a = 63
            else
                if self.p_data.log[threat] then
                    a = self.p_data.log[threat].jitter
                    r = math.ceil(a / 8)
                    return {r, a}
                end
            end
        end
    end,

    on_shot_fix = function(self, cmd, active)
        if active then
            local hs = ui.get(menu.ref.aa_hs[1]) and ui.get(menu.ref.aa_hs[2])
            local dt = ui.get(menu.ref.dt[1]) and ui.get(menu.ref.dt[2])
            local active = dt and hs
            ui.set(menu.ref.fl_enabled, true)
            if hs then
                ui.set(menu.ref.fl_enabled, false)
                ui.set(menu.ref.fl_limit, 14)
            elseif dt then
                if self.did_shoot > globals.curtime() then
                    ui.set(menu.ref.fl_limit, 1)
                else
                    ui.set(menu.ref.fl_limit, 14)
                end
            else
                ui.set(menu.ref.fl_limit, 14)
            end
        end
    end,

    get_desync_amount = function(self, cmd)
        return math.abs(math.max(-60, math.min(60, helpers:round((entity.get_prop(entity.get_local_player(), "m_flPoseParameter", 11) or 0)*120-60+0.5, 1))))/(180/math.pi)
    end,

    did_shoot = 0,
    should_update = 0,
    old_value = 0,
    old_value2 = 0,

    builder_logic = function(self, cmd)
        local state = ent_helper:get_state()

        local enabled = ui.get(gui.aa.builder[state].active)
        local path = enabled and gui.aa.builder[state] or gui.aa.builder["global"]
        
        local fs = ui.get(path.freestanding)
        local additives = ui.get(path.additives)
        local anti_brute_options = ui.get(path.anti_brute_options)
        local auto_fake = ui.get(path.auto_fake)
        local head_centering = ui.get(path.head_centering)
        local side = self.fs_data.side

        local ref = menu.ref.aa
        local center = {0, 0}

        local threat = ent_helper.threat

        if head_centering == 100 then
            center = self:head_centering(head_centering, 2, threat)
        else
            center = self:head_centering(head_centering, 1)
        end

        if fs ~= 0 then -- default
            self:get_freestand(cmd, fs)
        else
            self.fs_data.side = -1
        end
        
        if auto_fake ~= self.old_value then
            self:reset_fake(auto_fake, threat)
        end

        if ui.get(gui.aa.debug) then
            if head_centering ~= self.old_value2 then
                if head_centering == 100 then
                    self:generate_yaw(threat)
                end
            end
        end

        self.old_value = auto_fake
        self.old_value2 = head_centering
    
        if center ~= nil then
            if side == 1 then
                center[1] = center[1] + 8
                --center[2] = center[2] + 7
            elseif side == 2 then
                center[1] = center[1] - 8
                --center[2] = center[2] + 7
            end

            ui.set(ref.pitch, "Down")
            ui.set(ref.yaw_base, "At targets")
            ui.set(ref.yaw[1], "180")
            ui.set(ref.yaw_jitter[1], "Center")
            ui.set(ref.body_yaw[1], "Jitter")

            --if u comment out from here
            --[[]]
            if auto_fake ~= 0 then
                --if u comment local fake out and do fake = {0,0,0} it works just fine
                if self.p_data.log[threat] then
                    ui.set(ref.yaw_jitter[2], center[2] + self.p_data.log[threat].fake.j)
                    ui.set(ref.body_yaw[2], self.p_data.log[threat].fake.f)
                    ui.set(ref.yaw[2], self.var.aa_dir == 0 and center[1] + self.p_data.log[threat].fake.y or self.var.aa_dir)
                end
            else
                ui.set(ref.yaw[2], self.var.aa_dir == 0 or center[1] and self.var.aa_dir)
                ui.set(ref.yaw_jitter[2], center[2])
            end
            -- to here it works
            ui.set(ref.fs_body_yaw, false)
            ui.set(ref.roll, 0)
        end
        
    end,

    builder_default = function(self, cmd)
        local state = ent_helper:get_state()
        local threat = client.current_threat()
        if threat == nil or entity.is_dormant(threat) then
            state = "dormant"
        end

        local enabled = ui.get(gui.aa.builder[state].active)

        local path = enabled and gui.aa.builder[state] or gui.aa.builder["global"]

        local yaw, jitter, body, fake, yaw_opt, body_opt = 0, 0, 0, 0, "Off", "Off"

        --get menu 
        local dsync_fs =             ui.get(path.desync_freestand)
        local left_right =           ui.get(path.left_right)
        local yaw_add =              ui.get(path.yaw_add)
        local yaw_add_left =         ui.get(path.yaw_add_left)
        local yaw_add_right =        ui.get(path.yaw_add_right)
        local yaw_jitter =           ui.get(path.yaw_jitter)
        local yaw_jitter_add =       ui.get(path.yaw_jitter_add)
        local yaw_jitter_add_left =  ui.get(path.yaw_jitter_add_left)
        local yaw_jitter_add_right = ui.get(path.yaw_jitter_add_right)
        local body_yaw =             ui.get(path.body_yaw)
        local body_add =             ui.get(path.body_add)
        local body_add_left =        ui.get(path.body_add_left)
        local body_add_right =       ui.get(path.body_add_right)

        self:get_freestand(cmd)
        local side = self.fs_data.side == 2
        
        local fs_yaw = menu:contains(left_right, "yaw")
        local fs_yawjit = menu:contains(left_right, "yaw jitter")
        local fs_body = menu:contains(left_right, "body yaw")

        if dsync_fs == "disabled" then
            yaw = yaw_add
            jitter = yaw_jitter_add
            body = body_add
        elseif dsync_fs == "hide" then
            if fs_yaw then
                yaw = side and yaw_add_left or yaw_add_right
            else
                yaw = yaw_add
            end
            if fs_yawjit then
                jitter = side and yaw_jitter_add_left or yaw_jitter_add_right
            else
                jitter = yaw_jitter_add
            end
            if fs_body then
                body = side and body_add_left or body_add_right
            else
                body = body_add
            end
        elseif dsync_fs == "peek" then
            if fs_yaw then
                yaw = side and yaw_add_right or yaw_add_left
            else
                yaw = yaw_add
            end
            if fs_yawjit then
                jitter = side and yaw_jitter_add_right or yaw_jitter_add_left
            else
                jitter = yaw_jitter_add
            end
            if fs_body then
                body = side and body_add_right or body_add_left
            else
                body = body_add
            end
            if fs_fake then
                fake = side and fake_limit_right or fake_limit_left     
            else
                fake = fake_limit
            end
        end

        if yaw_jitter == "disabled" then yaw_opt = "Off" 
        elseif yaw_jitter == "center" then yaw_opt = "Center"
        elseif yaw_jitter == "offset" then yaw_opt = "Offset"
        elseif yaw_jitter == "random" then yaw_opt = "Random"
        elseif yaw_jitter == "skitter" then yaw_opt = "Skitter"
        else yaw_opt = "Off" end

        if body_yaw == "static" then body_opt = "Static" 
        elseif body_yaw == "opposite" then body_opt = "Opposite"
        elseif body_yaw == "jitter" then body_opt = "Jitter"
        else body_opt = "Off" end
        

        local ref = menu.ref.aa
        ui.set(ref.pitch, "Down")
        ui.set(ref.yaw_base, "At targets")
        ui.set(ref.yaw[1], "180")
        ui.set(ref.yaw[2], self.var.aa_dir == 0 and yaw or self.var.aa_dir)
        ui.set(ref.yaw_jitter[1], yaw_opt)
        ui.set(ref.yaw_jitter[2], jitter)
        ui.set(ref.body_yaw[1], body_opt)
        ui.set(ref.body_yaw[2], body)
        ui.set(ref.fs_body_yaw, false)
        ui.set(ref.roll, 0)
    end,

    freestand_key = { 
        ["0"] = "Always on",
        ["1"] = "On hotkey",
        ["2"] = "Toggle",
        ["3"] = "Off hotkey"
    },

    micromovements = function(self, cmd, player)
        local velocity = math.floor(ent_helper:get_velocity(player))
    
        local m_fFlags = entity.get_prop(player, "m_fFlags")
        local duck = entity.get_prop(player, "m_flDuckAmount") > 0.7
    
        local on_ground = bit.band(m_fFlags, bit.lshift(1, 0)) == 1
    
        --we dont rly need the vel check but lets just have it
        local micro = globals.tickcount() % 2 == 0
        local w, a, s, d = cmd.in_forward == 1, cmd.in_moveleft == 1, cmd.in_moveright == 1, cmd.in_back == 1
    
        if not on_ground then return end
        if w or a or s or d then return end
    
        local amount = duck and 3.25 or 1.1
        if velocity < 1.1 then
            cmd.sidemove = micro and amount or -amount;
        end
    end,

    delays = {
        choked = 0,
        mouse1 = 0,
        dt = 0,
        dt2 = 0,
    },

    cache = {
        nade = 0
    },
    
    can_desync = function(self, cmd, ent, count, vel)
        local selected = entity.get_player_weapon(ent)
        if cmd.in_attack == 1 or cmd.in_attack2 == 1 or cmd.in_attack3 == 1 then
            local weapon = entity.get_classname(selected)
            if weapon:find("Grenade") then
                self.cache["nade"] = count
            else
                if cmd.in_attack2 == 0 and entity.get_prop(selected, "m_flNextPrimaryAttack") - 0.1 < globals.curtime() - globals.tickinterval() then
                    return false
                end
        end
        end
        local throw = entity.get_prop(selected, "m_fThrowTime")
        if self.cache["nade"] + 8 == count or (throw ~= nil and throw ~= 0) then return false end
        if entity.get_prop(entity.get_game_rules(), "m_bFreezePeriod") == 1 then return false end
        if entity.get_prop(ent, "m_MoveType") == 9 and vel ~= 0 then return false end
        if cmd.in_use == 1 then return false end
        return true
    end,

    can_defuse = function(self)
        local me = entity.get_local_player()
        if entity.get_prop(me, "m_iTeamNum") ~= 3 then
            return false
        end
    
        local lx, ly = entity.get_origin(me)
        local c4 = entity.get_all("CPlantedC4")
    
        for index, ent in ipairs(c4) do
            local x, y = entity.get_origin(ent)
            local distance = math.sqrt((lx-x)^2 + (ly-y)^2)
            if distance < 128 then
                return true
            end
        end
        return false
    end,

    legit_aa_preset = function(self, static, at_targets)
        local ref = menu.ref.aa
        ui.set(ref.enabled, true)
        ui.set(ref.pitch, "Off")
        ui.set(ref.yaw_base, at_targets and "At targets" or "Local view")
        ui.set(ref.yaw[1], at_targets and "180" or "Off")
        ui.set(ref.yaw[2], at_targets and 180 or 0)
        ui.set(ref.yaw_jitter[1], "Off")
        ui.set(ref.yaw_jitter[2], 0)
        ui.set(ref.body_yaw[1], static and "Jitter" or "Opposite")
        ui.set(ref.body_yaw[2], 0)
        ui.set(ref.fs_body_yaw, static and false or true)
        ui.set(ref.roll, 0)
        end,

    legit_aa_active = false,

    legit_aa = function(self, cmd)
        self.legit_aa_active = false

        local me = entity.get_local_player()
        if me == nil then return end

        local weaponn = entity.get_player_weapon()
        local active = menu:contains(ui.get(gui.aa.keybinds), "legit aa")

        if active then
            local key = ui.get(gui.aa.key_legit_aa)
            local can_defuse = self:can_defuse()
            local legit_mode = ui.get(gui.aa.legitaaoptions)
            if key then
                if not can_defuse then
                    self.legit_aa_active = true
                    self:legit_aa_preset(legit_mode == "jitter")
                    if weaponn ~= nil and entity.get_classname(weaponn) == "CC4" then
                        if cmd.in_attack == 1 then
                            cmd.in_attack = 0 
                            cmd.in_use = 1
                        end
                    else
                        if cmd.chokedcommands == 0 then
                            cmd.in_use = 0
                        end
                    end
                end
            end
        end
    end,
    
    
    get_choke = function(self, cmd)
        local fakelag = ui.get(menu.ref.fl_limit)

        local check_fakelag = fakelag % 2 == 1
    
        local choked = cmd.chokedcommands
        local check_choke = choked % 2 == 0
    
        local dt_on = ui.get(menu.ref.dt[2]) and ui.get(menu.ref.dt[1])
        local hs_on = ui.get(menu.ref.aa_hs[2]) and ui.get(menu.ref.aa_hs[1])
        local fd_on = ui.get(menu.ref.fd[1])
    
        if dt_on then
            if self.delays.choked > 2 then
                if cmd.chokedcommands >= 0 then
                    check_choke = false
                end
            end
        end
    
        self.delays.choked = cmd.chokedcommands
    
        if self.delays.dt ~= dt_on then
            self.delays.dt2 = globals.curtime() + 0.25
        end
    
        if not dt_on and not hs_on and not cmd.no_choke or fd_on then
            if not check_fakelag then
                if self.delays.dt2 > globals.curtime() then
                    if cmd.chokedcommands >= 0 and cmd.chokedcommands < fakelag then
                        check_choke = choked % 2 == 0
                    else
                        check_choke = choked % 2 == 1
                    end
                else
                    check_choke = choked % 2 == 1
                end
            end
        end
        
        self.delays.dt = dt_on
        return check_choke    
    end,
    
    at_targets = function(self, threat)
        if threat ~= nil then
            local eyepos = vector(client.eye_position())
            local origin = vector(entity.get_origin(threat))
            local target = origin + vector(0, 0, 40)
            pitch, yaw = eyepos:to(target):angles() 
            return pitch, yaw
        end
    end,
        
    c_store = {
        jitter = false,
        yaw = 0,
        invert = false,
        strafing = false,

        key_left = false,
        key_right = false,
        key_forward = false,
    },
    
    custom_desync = function(self, cmd, values, legitaa)
        --force aa off
        ui.set(menu.ref.aa.enabled, false)
    
        local me = entity.get_local_player()
        if me == nil then return end
        local count = globals.tickcount()

        local vel = ent_helper:get_velocity(me)
        local can_desync = self:can_desync(cmd, me, count, vel)
        local choke = self:get_choke(cmd)
    
        local pitch, yaw2 = client.camera_angles()
        local current_player = client.current_threat()
        
        if values[1] == nil or values[2] == nil or values[3] == nil or values[4] == nil then return end
        local r, r2 = values[1], values[2]
        local f, f2 = values[3], values[4]
        pitch = 89
        local _, yaw = self:at_targets(current_player)
        if yaw == nil then 
            yaw = yaw2
        end
        yaw = yaw + 180
        
        if self.c_store.key_left then
            yaw = yaw - 90
        end
        if self.c_store.key_right then
            yaw = yaw + 90
        end        
        if self.c_store.key_forward then
            yaw = yaw - 180
        end

        self:micromovements(cmd, entity.get_local_player())

        if can_desync then
            if choke then
            --handle micromovements
            cmd.allow_send_packet = false

                self.c_store.jitter = not self.c_store.jitter
                if values[6] then --jitter fake
                    if self.c_store.jitter then
                        self.c_store.yaw = f
                    else
                        self.c_store.yaw = f2
                    end
                else
                    self.c_store.yaw = f
                end
            else
                if values[5] then --jitter real
                    if self.c_store.jitter then
                        self.c_store.yaw = r
                    else
                        self.c_store.yaw = r2
                    end
                else
                    self.c_store.yaw = r
                end
            end
    
            cmd.yaw = yaw + self.c_store.yaw
            cmd.pitch = 90
        end
    end,

    anti_backstab_active = false,

    anti_backstab = function(self, cmd)
        self.anti_backstab_active = false
        local me = entity.get_local_player()
        if me == nil then return end
    
        local disable_more_one = true
        local predict_high_vel = true
    
        local lx, ly = entity.get_origin(me)
    
        local enemies = entity.get_players(true)
        local people_in_range = 0
    
        for i=1, #enemies do
            local enemy = enemies[i]
    
            local active_wpn = entity.get_player_weapon(enemy)
            if active_wpn == nil then return end
    
            local weapon = entity.get_classname(active_wpn)
            if weapon == nil then return end
    
            local x, y = entity.get_origin(enemy)
            local distance = math.sqrt((lx-x)^2 + (ly-y)^2)
    
            local check_range = 300
            local has_knife = weapon:find("Knife")
    
            if distance < check_range then
                people_in_range = people_in_range + 1
    
                if disable_more_one then
                    if people_in_range > 1 then
                        return
                    end
                end
                if has_knife then
                    self.anti_backstab_active = true
                    self:legit_aa_preset(false, true)
                end
            end
    
            if predict_high_vel then
                local newextrapolatedPos = helpers:extrapolateTick(enemy, 125)
                local newDist = math.sqrt((lx-newextrapolatedPos[1])^2 + (ly-newextrapolatedPos[2])^2)
                if is_air then
                    if has_knife then
                        if newDist < check_range then
                            self.anti_backstab_active = true
                            self:legit_aa_preset(false, true)
                        end
                    end
                end
            end
        end
    end,

    enable_fs = false,
    fs_active = false,
    edge_yaw = false,


    binds = {
        left = false,
        right = false,
        forward = false,
        mode = 0,
    },

    var = {
        aa_dir = 0,
        last_press_t = 0,
    },

    handle_keybinds = function(self, cmd)
        local get_keybinds = ui.get(gui.aa.keybinds)
        ui.set(menu.ref.aa.fs[1], false)
        self.enable_fs = false
        local mode = ui.get(gui.aa.auto_mode)
        local preset = ui.get(gui.aa.preset)

        self.fs_active = false

        if menu:contains(get_keybinds, "freestand") then
            local state = ent_helper:get_state()
            local fgt = { ui.get(gui.aa.key_freestand) }
            local set_menu_key = self.freestand_key[tostring(fgt[2])]
            ui.set(menu.ref.aa.fs[2], set_menu_key)
            if not menu:contains(ui.get(gui.aa.freestand_disablers), state) and not self.legit_aa_active then
                if ui.get(gui.aa.key_freestand) then
                    self.fs_active = true
                    disable_custom = true
                    ui.set(menu.ref.aa.fs[2], "Always on")
                    ui.set(menu.ref.aa.fs[1], true)
                    if preset == "automatic" and mode == "experimental" then
                        self.enable_fs = true
                    end
                end
            end
        end

        ui.set(menu.ref.aa.edge_yaw, false)
        self.edge_yaw = false

        if menu:contains(get_keybinds, "edge yaw") then
            if ui.get(gui.aa.key_edgeyaw) then
                if preset == "automatic" and mode == "experimental" then
                    ui.set(menu.ref.aa.enabled, true)
                    ui.set(menu.ref.aa.pitch, "Down")
                    ui.set(menu.ref.aa.yaw_base, "At targets")
                    ui.set(menu.ref.aa.yaw[1], "180")
                    ui.set(menu.ref.aa.yaw[2], 0)            
                    ui.set(menu.ref.aa.yaw_jitter[1], "Center")
                    ui.set(menu.ref.aa.yaw_jitter[2], 75)
                    ui.set(menu.ref.aa.body_yaw[1], "Jitter")
                    ui.set(menu.ref.aa.body_yaw[2], 0)
                    ui.set(menu.ref.aa.fs_body_yaw, false)
                    ui.set(menu.ref.aa.roll, 0)
                end
                self.edge_yaw = true
                ui.set(menu.ref.aa.edge_yaw, true)
            end
        end


        local left = ui.get(gui.aa.key_left)
        local right = ui.get(gui.aa.key_right)
        local forward = ui.get(gui.aa.key_forwards)

        local t_r = { ui.get(gui.aa.key_right) }
        local t_l = { ui.get(gui.aa.key_left) }
        ui.set(gui.aa.key_left, "On hotkey")
        ui.set(gui.aa.key_right, "On hotkey")

        if menu:contains(get_keybinds, "manual aa") then
            if fs_active then
                self.var.aa_dir = 0
                self.var.last_press_t = globals.curtime()
            else
                if forward and self.var.last_press_t + 0.2 < globals.curtime() then
                    self.var.aa_dir = self.var.aa_dir == 180 and 0 or 180
                    self.var.last_press_t = globals.curtime()
                    self.binds.mode = 0
                elseif right and self.var.last_press_t + 0.2 < globals.curtime() then
                    self.var.aa_dir = self.var.aa_dir == 90 and 0 or 90
                    self.var.last_press_t = globals.curtime()
                    self.binds.mode = 90
                elseif left and self.var.last_press_t + 0.2 < globals.curtime() then
                    self.var.aa_dir = self.var.aa_dir == -90 and 0 or -90
                    self.var.last_press_t = globals.curtime()
                    self.binds.mode = -90
                elseif self.var.last_press_t > globals.curtime() then
                    self.var.last_press_t = globals.curtime()
                    self.binds.mode = 0
                end
                if self.var.aa_dir == 90 then
                    self.binds.mode = 90
                elseif self.var.aa_dir == -90 then
                    self.binds.mode = -90
                else
                    self.binds.mode = 0
                end 
            end
        else
            self.var.aa_dir = 0
            self.var.last_press_t = globals.curtime()
        end

        local active = menu:contains(ui.get(gui.aa.keybinds), "roll")
        self.roll_active = false

        if active then
            local key = ui.get(gui.aa.key_roll)
            local freestand = ui.get(gui.aa.roll_options)
            self:get_freestand(cmd)

            local side = self.fs_data.side == 1
            local state = ent_helper:get_state()
            if not menu:contains(ui.get(gui.aa.roll_disablers), state) then
                if key then
                    self.roll_active = true
                    local ref = menu.ref.aa
                    ui.set(ref.enabled, true)
                    ui.set(ref.pitch, "Down")
                    ui.set(ref.yaw_base, "At targets")
                    ui.set(ref.yaw[1], "180")
                    ui.set(ref.yaw[2], 0)            
                    ui.set(ref.yaw_jitter[1], "Off")
                    ui.set(ref.yaw_jitter[2], 0)
                    ui.set(ref.body_yaw[1], "Static")
                    ui.set(ref.body_yaw[2], side and -180 or 180)
                    ui.set(ref.fs_body_yaw, false)
                    ui.set(ref.roll, 0)
                    
                    if freestand == "peek head" then
                        if side then
                            ui.set(ref.yaw[2], -90)
                            cmd.roll = 50
                        else
                            ui.set(ref.yaw[2], 90)
                            cmd.roll = -50
                        end
                    elseif freestand == "defensive" then

                        if side then
                            ui.set(ref.yaw[2], -28)
                            cmd.roll = -50
                        else
                            ui.set(ref.yaw[2], 28)
                            cmd.roll = 50
                        end 
                    end
                end
            end
        end
    end,

    cached_mode = "",

    automatic_aa = function(self, cmd)
        local mode = ui.get(gui.aa.auto_mode)

        local me = entity.get_local_player()
        if me == nil then return end

        local threat = ent_helper.threat
        local state = ent_helper:get_state()
        local air = state == "jumping" or state == "duck jumping"

            if mode == "cycle entity" then
                if threat ~= nil then
                    if mode ~= self.cached_mode then
                        self.p_data.log = {}
                    end

                    if self.p_data.log[threat] then
                        if self.p_data.log[threat].fake_a.upd or self.cached_mode ~= mode then
                            self:update_auto(threat)
                        end

                        yaw = self.p_data.log[threat].fake_a.y
                        jitter = self.p_data.log[threat].fake_a.j
                        body = self.p_data.log[threat].fake_a.b
                        fake = self.p_data.log[threat].fake_a.f

                        if air then
                            if self.p_data.log[threat].fake_a.j > 55 then
                                jitter = math.random(55, 68)
                            end
                            yaw = 14
                        end
                    else
                        yaw = self.var.aa_dir == 0 and 4 or self.var.aa_dir
                        jitter = 68
                        body = 0
                        fake = 60
                    end
                end
            elseif mode == "experimental" then
                local value = self:calculate_yaw(cmd)
            
                realb = value[1]
                realb2 = value[2]

                if realb == 0 and realb2 == 0 then
                    realb = -24
                    realb2 = 46
                end
                    
                if value[3] == nil then value[3] = 120 end
                if value[4] == nil then value[4] = -120 end
                fakeb = value[3]
                fakeb2 = value[4]


                local strafe_fix = ui.get(gui.aa.preset_exp_strafe)
                
                if strafe_fix then
                    local is_strafing = entity.get_prop(entity.get_local_player(), "m_bStrafing")
                    if not self.c_store.strafing then
                        fakeb = 0
                        fakeb2 = 0
                    end
                end

                if disable_custom or self.enable_fs or self.edge_yaw then return end

                local manual = self.var.aa_dir
                self:custom_desync(cmd, {realb + manual, realb2 + manual, fakeb, fakeb2, true, true})

                yaw = 0
                jitter = 0
                body = 0
                fake = 0

            elseif mode == "\ad7b8ffffNEW\aFFFFffff synchronize jitter" then
                local value = self:calculate_yaw(cmd, "synchronize")

                if self.p_data.log[threat] then
                    jitter = self.p_data.log[threat].dyn_jitter
                    yaw = 15
                    body = 0
                    fake = 60
                else
                    yaw = 0
                    jitter = 75
                    body = 0
                    fake = 60
                end
            end
        self.cached_mode = mode 

        if not self.legit_aa_active then
            local ref = menu.ref.aa
            if jitter == nil then jitter = 0 end
            ui.set(ref.pitch, "Down")
            ui.set(ref.yaw_base, "At targets")
            ui.set(ref.yaw[1], "180")
            ui.set(ref.yaw[2], self.var.aa_dir == 0 and yaw or self.var.aa_dir)
            ui.set(ref.yaw_jitter[1], "Center")
            ui.set(ref.yaw_jitter[2], jitter)
            ui.set(ref.body_yaw[1], "Jitter")
            ui.set(ref.body_yaw[2], body)
            ui.set(ref.fs_body_yaw, false)
            ui.set(ref.roll, 0)
        end
    end,

    warmup_active = false,

    warmup_aa = function(self, cmd)
        local active = ui.get(gui.aa.warmup_aa)

        if active then
            local warmup = entity.get_prop(entity.get_game_rules(), "m_bWarmupPeriod");
            if warmup == 1 then
                self.warmup_active = true
                local ref = menu.ref.aa
                ui.set(ref.pitch, "Down")
                ui.set(ref.yaw_base, "At targets")
                ui.set(ref.yaw[1], "Spin")
                ui.set(ref.yaw[2], 16)
                ui.set(ref.yaw_jitter[1], "Center")
                ui.set(ref.yaw_jitter[2], 0)
                ui.set(ref.body_yaw[1], "Off")
                ui.set(ref.body_yaw[2], 0)
                ui.set(ref.fs_body_yaw, false)
                ui.set(ref.roll, 0)
            else
                self.warmup_active = false
            end
        else
            self.warmup_active = false
        end
    end,

    main_handle = function(self, cmd)
        if self.roll_active then return end
        if self.anti_backstab_active then return end
        if self.warmup_active then return end
        if self.legit_aa_active then return end
        local aa = ui.get(gui.aa.preset)
        if aa == "automatic" then
            self:automatic_aa(cmd)
        elseif aa == "constructor" then
            local mode = ui.get(gui.aa.config_mode)
            if mode == "builder" then
                self:builder_default(cmd)
            elseif mode == "\ad7b8fffflogic\aFFFFffff-based" then
                self:builder_logic(cmd)
            end
        end
    end,
}

local easings = {
	lerp = function(self, start, vend, time)
		return start + (vend - start) * time
	end,

	clamp = function(self, val, min, max)
		if val > max then return max end
		if min > val then return min end
		return val
	end,

    ease_in_out_quart = function(self, x)
        local sqt = x^2
        return sqt / (2 * (sqt - x) + 1);
    
    end
}

visuals = {

    p_text = {},

    pulsate_text = function(self, text, speed, max)
        if self.p_text[text] == nil then
            self.p_text[text] = {
                a = true,
                p = 0
            }
        else
            if self.p_text[text].a then
                self.p_text[text].p = self.p_text[text].p + speed
                if self.p_text[text].p >= max then
                    self.p_text[text].a = false
                end
            elseif self.p_text[text].a == false then
                self.p_text[text].p = self.p_text[text].p - speed
                if self.p_text[text].p <= 0 then
                    self.p_text[text].a = true
                end
            end
            return self.p_text[text].p
        end
    end,

    animation = function(self, check, name, value, speed) 
        if check then 
            return helpers:round(name + (value - name) * globals.frametime() * speed, 2)
        else 
            return name > 0.9 and helpers:round(name - (value + name) * globals.frametime() * speed / 2, 2) or 0
        end
    end,

    animation2 = function(self, check, name, value, speed) 
        if check then 
            return helpers:round(name + (value - name) * globals.frametime() * speed, 2)
        else 
            return helpers:round(name - (value + name) * globals.frametime() * speed / 2, 2)
        end
    end,

    lerp = function(self, a, b, t)
	    return a + (b - a) * t
    end,

    anim = {
        name = 0,
        bar = 0,
        dt = 0,
        d = {
            frac = 0,
            dt = 0,
            was_dt = 0,
            os = 0,
            fs = 0,
        },
        old = ""
    },

    render_keys = {
        dt = {on = false, str = "DT"},
        hs = {on = false, str = "HS"},
        fs = {on = false, str = "FS"},
    },

    indicator_key = function(self, me, x, y)
        --anims smh

        local scoped = entity.get_prop(me, "m_bIsScoped") == 1

        if scoped then
            x = x + 1
            self.anim.d.frac = math.max(self.anim.d.frac - globals.frametime(),0)
        else
            self.anim.d.frac = math.min(self.anim.d.frac + globals.frametime(),0.5)
        end

        local fraction = easings:ease_in_out_quart(self.anim.d.frac*2)

        local space = renderer.measure_text("-", " ")
        local dt = ui.get(menu.ref.dt[1]) and ui.get(menu.ref.dt[2])
        local os = ui.get(menu.ref.aa_hs[1]) and ui.get(menu.ref.aa_hs[2])
        --local fs = contains(ui.get(ref_freestand), "Default") and ui.get(ref_freestand_key)

        local w4 = renderer.measure_text("-", "DT")
        local w5 = renderer.measure_text("-", "OS")
        local w6 = renderer.measure_text("-", "FS")

        if dt or self.anim.d.dt ~= 0 or self.anim.d.was_dt then
            if dt then
                self.anim.d.dt = math.min(self.anim.d.dt + globals.frametime()*5,1)
            else
                self.anim.d.dt = math.max(self.anim.d.dt - globals.frametime()*5,0)
            end
            local str = "DT"
            local size = w4 + (space + w5) * easings:ease_in_out_quart(self.anim.d.os) + (space + w6) * easings:ease_in_out_quart(self.anim.d.fs) + space * easings:ease_in_out_quart(self.anim.d.os) * easings:ease_in_out_quart(self.anim.d.fs)

            renderer.text(x - (size/2) * fraction, y + 20 + 20 * easings:ease_in_out_quart(self.anim.d.dt), 255, 255, 255, 255 * easings:ease_in_out_quart(self.anim.d.dt), "-", 0, str)
        end

        if fs or self.anim.d.fs ~= 0 then
            if fs then
                self.anim.d.fs = math.min(self.anim.d.fs + globals.frametime()*5,1)
            else
                self.anim.d.fs = math.max(self.anim.d.fs - globals.frametime()*5,0)
            end
            local str = "FS"
            local size = w6 + (space + w4) * easings:ease_in_out_quart(self.anim.d.dt) + (space + w5) * easings:ease_in_out_quart(self.anim.d.os) + space * easings:ease_in_out_quart(self.anim.d.dt) * easings:ease_in_out_quart(self.anim.d.os)

            renderer.text(x - (size/2) * fraction + (w4 + space) * easings:ease_in_out_quart(self.anim.d.dt), y + 20 + 20 * easings:ease_in_out_quart(self.anim.d.fs), 255, 255, 255, 255 * easings:ease_in_out_quart(self.anim.d.fs), "-", 0, str)
        end

        if os or self.anim.d.os ~= 0 then
            if os then
                self.anim.d.os = math.min(self.anim.d.os + globals.frametime() * 5,1)
            else
                self.anim.d.os = math.max(self.anim.d.os - globals.frametime() * 5,0)
            end
            local str = "OS"
            local size = w5 + (space + w6) * easings:ease_in_out_quart(self.anim.d.fs) + (space + w4) * easings:ease_in_out_quart(self.anim.d.dt) + space * easings:ease_in_out_quart(self.anim.d.fs) * easings:ease_in_out_quart(self.anim.d.dt)
            
            renderer.text(x - (size/2) * fraction + (w4 + space)*easings:ease_in_out_quart(self.anim.d.dt) + (space + w6) * easings:ease_in_out_quart(self.anim.d.fs), y + 20 + 20 * easings:ease_in_out_quart(self.anim.d.os), 255, 255, 255, 255* easings:ease_in_out_quart(self.anim.d.os), "-", 0, str)
        end
    end,

    default_indicator = function(self, x, y)
        local me = entity.get_local_player()

        if not me or entity.get_prop(me, "m_lifeState") ~= 0 then return end
        local options = ui.get(gui.vis.new_options)
        local t_opt = "-"

        local scoped = entity.get_prop(me, "m_bIsScoped") == 1

        local lua_name = string.upper(lavender.build)
        local tX, tY = renderer.measure_text(t_opt, "BEAZT " .. lua_name)
        if scoped then
            if lua_name == "LIVE" then
                tX = tX + 3
            elseif lua_name == "ALPHA" then
                tX = tX - 6
            end
        end
        local tX2, tY2 = renderer.measure_text(t_opt, "BEAZT ")
        local pos = tX / 2

        local r, g, b = ui.get(gui.vis.def_clr_beta_1)
        local alpha = self:pulsate_text(lua_name, 0.75, 255)
        
        self:indicator_key(me, x, y - 20)

        self.anim.name = self:animation(scoped, self.anim.name, 29, 8)
        self.anim.bar = self:animation(scoped, self.anim.bar, 19, 8)
        self.anim.dt = self:animation(scoped, self.anim.dt, 12, 8)

        renderer.text(x - pos + self.anim.name, y, 255, 255, 255, 255, t_opt, 0, "BEAZT " )
        renderer.text(x - pos + tX2 + self.anim.name, y, r, g, b, alpha, t_opt, 0, lua_name )

        local state = ent_helper:get_state()
        local mx, my = renderer.measure_text(t_opt, state)
        local pos3 = renderer.measure_text(t_opt, string.upper(state)) / 2
        if scoped then
            pos3 = 17
        end
        renderer.text(x - pos3 + self.anim.bar, y + 10, 255, 255, 255, 155, t_opt, 0, string.upper(state))

    end,


    bar_lerp = 0,

    new_indicator = function(self, x, y)
        local me = entity.get_local_player()

        if not me or entity.get_prop(me, "m_lifeState") ~= 0 then return end

        local dsync = antiaim:get_desync_amount()
        local options = ui.get(gui.vis.new_options)
        local center = menu:contains(options, "center")
        local yOffset = 0

        local t_opt = "-"

        local lua_name = string.upper(lavender.build)

        --Vector2.new(screen.x / 2 - g_Render.CalcTextSize("BODY", 13).x / 2, screen.y / 2 + 15),
        
        local tX, tY = renderer.measure_text(t_opt, "LAVENDER " .. lua_name)
        local tX2, tY2 = renderer.measure_text(t_opt, "LAVENDER ")
        local tX3, tY3 = renderer.measure_text(t_opt, lua_name)

        local r, g, b = ui.get(gui.vis.new_clr_beta_1)
        local alpha = self:pulsate_text("BETA", 0.75, 255)

        local scoped = entity.get_prop(me, "m_bIsScoped") == 1
        local pos = tX / 2

        if center then
            if lua_name == "LIVE" then
                self.anim.name = self:animation(scoped, self.anim.name, 30, 12)
                self.anim.bar = self:animation(scoped, self.anim.bar, 30, 12)
                self.anim.dt = self:animation(scoped, self.anim.dt, 26, 12)
            elseif lua_name == "ALPHA" then
                self.anim.name = self:animation(scoped, self.anim.name, 34, 12)
                self.anim.bar = self:animation(scoped, self.anim.bar, 34, 12)
                self.anim.dt = self:animation(scoped, self.anim.dt, 25, 12)
            else
                self.anim.name = self:animation(scoped, self.anim.name, 32, 12)
                self.anim.bar = self:animation(scoped, self.anim.bar, 32, 12)
                self.anim.dt = self:animation(scoped, self.anim.dt, 26, 12)
            end

            renderer.text(x - pos + self.anim.name, y, 255, 255, 255, 255, t_opt, 0, "LAVENDER " )
            renderer.text(x - pos + tX2 + self.anim.name, y, r, g, b, alpha, t_opt, 0, lua_name )

        else
            self.anim.name = 0
            self.anim.bar = 0
            self.anim.dt = 0
            
            renderer.text(x + 1 + self.anim.name, y, 255, 255, 255, 255, t_opt, 0, "LAVENDER " )
            renderer.text(x + tX2 + 1 + self.anim.name, y, r, g, b, alpha, t_opt, 0, lua_name )
        end

        yOffset = yOffset + 11

        local gr, gg, gb, ga = ui.get(gui.vis.new_clr_dsync_1)
        local dsync_w = math.ceil(dsync * 53)
        local style = menu:contains(options, "gradient style 1")

        local speed = globals.frametime() * 25
        self.bar_lerp = self:lerp(self.bar_lerp, dsync_w, speed)

        if center then
            renderer.rectangle(x - pos + 1 + self.anim.bar, y + yOffset, tX + 1, 5, 10, 10, 10, 175)
            renderer.gradient(x - pos + 2 + self.anim.bar, y + yOffset + 1, self.bar_lerp + 1, 3, gr, gg, gb, ga, gr, gg, gb, 0, not style)
        else
            renderer.rectangle(x + 2 + self.anim.bar, y + yOffset, tX + 1, 5, 10, 10, 10, 175)
            renderer.gradient(x + 3 + self.anim.bar, y + yOffset + 1, self.bar_lerp + 1, 3, gr, gg, gb, ga, gr, gg, gb, 0, not style)
        end

        yOffset = yOffset + 5

        local dt = ui.get(menu.ref.dt[2])
        if dt then
            if center then
                local tX4, tY4 = renderer.measure_text(t_opt, "DOUBLETAP")
                renderer.text(x - tX4 / 2 + self.anim.dt, y + yOffset, 255, 255, 255, 255, t_opt, 0, "DOUBLETAP" )
            else
                renderer.text(x + 1 + self.anim.dt, y + yOffset, 255, 255, 255, 255, t_opt, 0, "DOUBLETAP" )
            end
        end
    end,

    arrows = function(self, x, y)
        local me = entity.get_local_player()

        if not me or entity.get_prop(me, "m_lifeState") ~= 0 then return end

        local yaw = antiaim.binds.mode
        local yaw_r = yaw == 90
        local yaw_l = yaw == -90

        local distance = ui.get(gui.vis.arrow_distance)

        local r, g, b, a = ui.get(gui.vis.arrow_clr_1)
        local r2, g2, b2, a2 = ui.get(gui.vis.arrow_clr2_1)
        local iR, iG, iB, iA = 35, 35, 35, 150

        local bodyyaw = entity.get_prop(me, "m_flPoseParameter", 11) * 120 - 60
        local body_r = bodyyaw > 10
        local body_l = bodyyaw < -10

        renderer.triangle(x + distance + 2, y - 8, x + distance + 15, y, x + distance + 2, y + 8, 
        yaw_r and r or iR, 
        yaw_r and g or iG, 
        yaw_r and b or iB, 
        yaw_r and a or iA)

        renderer.rectangle(x + distance - 2, y - 8, 2, 16, 
        body_r and r2 or iR, 
        body_r and g2 or iG, 
        body_r and b2 or iB, 
        body_r and a2 or iA)

        renderer.triangle(x - distance - 2, y + 8, x - distance - 15, y, x - distance - 2, y - 8, 
        yaw_l and r or iR, 
        yaw_l and g or iG, 
        yaw_l and b or iB, 
        yaw_l and a or iA)

        renderer.rectangle(x - distance, y - 8, 2, 16, 
        body_l and r2 or iR, 
        body_l and g2 or iG, 
        body_l and b2 or iB, 
        body_l and a2 or iA)
    end,

    rounding = 9,
    rad = 9 + 2, --rounding + 2
    n = 45,
    o = 20,

    OutlineGlow = function(self, x, y, w, h, radius, r, g, b, a) 
        renderer.rectangle(x+2,y+radius+self.rad,1,h-self.rad*2-radius*2,r,g,b,a)
        renderer.rectangle(x+w-3,y+radius+self.rad,1,h-self.rad*2-radius*2,r,g,b,a)
        renderer.rectangle(x+radius+self.rad,y+2,w-self.rad*2-radius*2,1,r,g,b,a)
        renderer.rectangle(x+radius+self.rad,y+h-3,w-self.rad*2-radius*2,1,r,g,b,a)
        renderer.circle_outline(x+radius+self.rad,y+radius+self.rad,r,g,b,a,radius+self.rounding,180,0.25,1)
        renderer.circle_outline(x+w-radius-self.rad,y+radius+self.rad,r,g,b,a,radius+self.rounding,270,0.25,1)
        renderer.circle_outline(x+radius+self.rad,y+h-radius-self.rad,r,g,b,a,radius+self.rounding,90,0.25,1)
        renderer.circle_outline(x+w-radius-self.rad,y+h-radius-self.rad,r,g,b,a,radius+self.rounding,0,0.25,1) 
    end,

    n = 45,

    FadedRoundedGlow = function(self, x, y, w, h, radius, r, g, b, a, glow, r1, g1, b1) 
        local n=a/255*self.n
        renderer.rectangle(x+radius,y,w-radius*2,1,r,g,b,n)
        renderer.circle_outline(x+radius,y+radius,r,g,b,n,radius,180,0.25,1)
        renderer.circle_outline(x+w-radius,y+radius,r,g,b,n,radius,270,0.25,1)
        renderer.rectangle(x,y+radius,1,h-radius*2,r,g,b,n)
        renderer.rectangle(x+w-1,y+radius,1,h-radius*2,r,g,b,n)
        renderer.circle_outline(x+radius,y+h-radius,r,g,b,n,radius,90,0.25,1)
        renderer.circle_outline(x+w-radius,y+h-radius,r,g,b,n,radius,0,0.25,1)
        renderer.rectangle(x+radius,y+h-1,w-radius*2,1,r,g,b,n)
        for radius=4,glow do 
            local radius=radius/2
            self:OutlineGlow(x-radius,y-radius,w+radius*2,h+radius*2,radius,r1,g1,b1,glow-radius*2)
        end 
    end,
    --solus_render.container(x, y + 2, w, 19, r, g, b, m_alpha*a, m_alpha)
    radius = 12,

    render_logs = function(self)
        local localplayer = entity.get_local_player()
        if not localplayer then return end

        local box_width, box_height = 10, 2
        --if not menu:contains(ui.get(gui.vis.additives), "logs") then return end
    
        if entity.is_alive(localplayer) then
            screen = {client.screen_size()}
            center = {screen[1]/2, screen[2]/2} 
    
            local y = screen[2] - 100
            for i, info in ipairs(lavender.logs) do
                if i > 6 then
                    table.remove(lavender.logs, i)
                end
    
                if info.text ~= nil and info.text ~= "" then
                    local text_size_x, text_size_y = renderer.measure_text("", "[lavender] " .. info.text)
    
                    if info.timer + 3.8 < globals.realtime() then
                        info.first_circle = easings:lerp(
                            info.first_circle, 0, globals.frametime() * 1
                        )
        
                        info.second_circle = easings:lerp(
                            info.second_circle, 0, globals.frametime() * 1
                        )
        
                        info.box_left = easings:lerp(
                            info.box_left, 0, globals.frametime() * 2
                        )
        
                        info.box_right = easings:lerp(
                            info.box_right, 0, globals.frametime() * 1
                        )
        
                        info.box_left_1 = easings:lerp(
                            info.box_left_1, 0, globals.frametime() * 1
                        )
        
                        info.box_right_1 = easings:lerp(
                            info.box_right_1, 0, globals.frametime() * 1
                        )
    
                        info.smooth_y = easings:lerp(
                            info.smooth_y,
                            screen[2] + 100,
                            globals.frametime() * 2
                        )
    
                        info.alpha = easings:lerp(
                            info.alpha,
                            0,
                            globals.frametime() * 15
                        )
                    else
                        info.alpha = easings:lerp(
                            info.alpha,
                            255,
                            globals.frametime() * 4
                        )

                        info.alpha2 = easings:lerp(
                            info.alpha2,
                            255,
                            globals.frametime() * 1
                        )
                        
                        info.smooth_y = easings:lerp(
                            info.smooth_y,
                            y,
                            globals.frametime() * 4
                        )
    
                        info.first_circle = easings:lerp(
                            info.first_circle, 275, globals.frametime() * 5
                        )
    
                        info.second_circle = easings:lerp(
                            info.second_circle, -95, globals.frametime() * 3
                        )
    
                        info.box_left = easings:lerp(
                            info.box_left, text_size_x / 2 + 15, globals.frametime() * 10
                        )
    
                        info.box_right = easings:lerp(
                            info.box_right, center[1] + text_size_x / 2 + 4, globals.frametime() * 6
                        )
    
                        info.box_left_1 = easings:lerp(
                            info.box_left_1, center[1] - text_size_x / 2 - 2, globals.frametime() * 6
                        )
    
                        info.box_right_1 = easings:lerp(
                            info.box_right_1, center[1] + text_size_x / 2 + 4, globals.frametime() * 6
                        )

                        info.right_circle = easings:lerp(
                            info.right_circle, text_size_x / 2 + 13, globals.frametime() * 6
                        )

                        info.right_circle_1 = easings:lerp(
                            info.right_circle_1, text_size_x / 2 + 13, globals.frametime() * 6
                        )

                        if info.box_left - 12 > text_size_x / 2 then
                            info.left_circle = easings:lerp(
                                info.left_circle, 1000, globals.frametime() * 0.15
                            )
                        end
                        info.left_circle_1 = easings:lerp(
                            info.left_circle_1, 0.5, globals.frametime() * 6
                        )
                    end
    
                    --local color = menu_database.handler.references["Notifications color"].reference:Get()
                    local add_y = math.floor(info.smooth_y)
                    local alpha = math.floor(info.alpha)
                    local alpha_c = math.floor(info.alpha2)
    
                    local first_circle = math.floor(info.first_circle)
                    local left_box = math.floor(info.box_left)
                    
                    local left_circle = math.floor(info.left_circle) / 300
                    
                    local r, g, b, a = ui.get(gui.vis.logs_clr_1)

                    local new_alpha = alpha / 255 * 155

                    clamp = function(self, val, min, max)
                        if val > max then return max end
                        if min > val then return min end
                        return val
                    end
                    local left_box_clamp = easings:clamp(left_circle * 100, 0, 100)
                   -- renderer.rectangle(center[1] + 20, center[2] + 31, 32, 1, r, g, b, a)
    
                   for i = 1, 1 do
                    for k = 1, 2 do
                        renderer.rectangle(
                            center[1], 
                            add_y - 28 + box_height,
                            -left_box + 1 + box_width,
                            1,
                            r, g, b, new_alpha
                        )

                        renderer.rectangle(
                            center[1], 
                            add_y - 28 + box_height,
                            left_box - 1 - box_width,
                            1,
                            r, g, b, new_alpha
                        )    

                        renderer.rectangle(
                            center[1], 
                            add_y - 3 - box_height,
                            left_box - 1 - box_width,
                            1,
                            r, g, b, new_alpha
                        )
                        
                        renderer.rectangle(
                            center[1], 
                            add_y - 3 - box_height,
                            -left_box + 1 + box_width,
                            1,
                            r, g, b, new_alpha
                        )   

                    
                        if left_box - 12 > text_size_x / 2 then
                            if left_circle > 0.5 then left_circle = 0.5 end
                            renderer.circle_outline(
                                center[1] - text_size_x / 2 - 12 + box_width, 
                                add_y - 13 - box_height, 
                                r, g, b, new_alpha,
                                13 - box_height,
                                90,
                                left_circle,
                                1
                            )
                        end
                    
                                            
                        if left_box - 12 > text_size_x / 2 then
                            renderer.circle_outline(
                                center[1] + text_size_x / 2 + 11 - box_width, 
                                add_y - 13 - box_height, 
                                r, g, b, new_alpha,
                                13 - box_height,
                                270,
                                left_circle,
                                1
                            )
                        end
                    end
                end
                --[]
                   renderer.rectangle(
                        center[1] - text_size_x / 2 - 12 + box_width, 
                        add_y - 27 + box_height,
                        text_size_x + 13 - box_width,
                        22 - box_height,
                        25, 25, 25, new_alpha
                    )
                    --screen_size.x / 2 + text_size.x / 2 + 13
                    renderer.circle(
                        center[1] - text_size_x / 2 - 12 + box_width, 
                        add_y - 15,
                        25, 25, 25, new_alpha,
                        10,
                        180,
                        0.5
                    )
    
                    renderer.circle(
                        center[1] + text_size_x / 2 + 11 - box_width, 
                        add_y - 15,
                        25, 25, 25, new_alpha,
                        10,
                        0,
                        0.5
                    )

                    --FadedRoundedGlow = function(self, x, y, w, h, radius, r, g, b, a, glow, r1, g1, b1) 

                    self:FadedRoundedGlow(center[1] - text_size_x / 2 - 24 + box_width, add_y - 26, text_size_x + 37 - box_width, 22, self.radius, r, g, b, a, 20, r, g, b)

                    local textSize = renderer.measure_text("", "[lavender] ")
                    
                    local red, green, blue = ui.get(gui.vis.logs_clr_1)
                    local clr = '\a' .. menu:rgbToHex(red, green, blue) ..'ff'
                    local w = "\aFFFFffff"

                    renderer.text(center[1] - text_size_x / 2, add_y - 22, r, g, b, alpha / 255 * 155, '', 0, clr .. "[lavender] " .. w)

                    renderer.text(textSize + center[1] - text_size_x / 2, add_y - 22, 225, 225, 225, alpha, '', 0, info.text)
    
    
                    y = y - 30
                    if info.timer + 4 < globals.realtime() then table.remove(lavender.logs, i) end
                end
            end
        end
    end,

    add_to_log = function(self, input, hit)
        local screen = {client.screen_size()}
        local center = {screen[1]/2, screen[2]/2} 
        if hit then
            table.insert(lavender.logs, {
                text = input,
            
                timer = globals.realtime(),
                smooth_y = screen[2] + 100,
                alpha = 0,
                alpha2 = 0,
            
                first_circle = 0,
                second_circle = 0,
            
                box_left = 0,
                box_right = 0,
            
                right_circle = 0,
                right_circle_1 = 0,
                left_circle = 0,
                left_circle_1 = 0,
            
                box_left_1 = 0,
                box_right_1 = 0
            })

        else
            table.insert(lavender.logs, {
                text = input,
            
                timer = globals.realtime(),
                smooth_y = screen[2] + 100,
                alpha = 0,
                alpha2 = 0,
            
                first_circle = 0,
                second_circle = 0,
            
                box_left = 0,
                box_right = 0,
            
                right_circle = 0,
                right_circle_1 = 0,
                left_circle = 0,
                left_circle_1 = 0,
            
                box_left_1 = 0,
                box_right_1 = 0
            })
        end
    end,

    modern_anim = {
        dt = 0,
        hs = 0,
        qp = 0,
        baim = 0,
        sp = 0,
        fs = 0,
        scope = {
            name = 0,
            build = 0,
            dt = 0,
            hs = 0,
            qp = 0,
            binds = 0,
        },
        alpha = {
            dt = 0,
            hs = 0,
            qp = 0,             
        },
        smoothhh = 0
    },

    modern_indicator = function(self, x, y)
        local me = entity.get_local_player()

        if not me or entity.get_prop(me, "m_lifeState") ~= 0 then return end
        local options = ui.get(gui.vis.new_options)
        local t_opt = "-"

        local scoped = entity.get_prop(me, "m_bIsScoped") == 1

        local lua_name = string.upper(lavender.build)

        local nX, nY = renderer.measure_text(t_opt, "LAVENDER")
        local bX, bY = renderer.measure_text(t_opt, lua_name)
        local dX, dY = renderer.measure_text(t_opt, "DT")
        local hX, hY = renderer.measure_text(t_opt, "HS")
        local qX, qY = renderer.measure_text(t_opt, "QP")
        local baimX, baimY = renderer.measure_text(t_opt, "BAIM")
        local fsX, fsY = renderer.measure_text(t_opt, "FS")
        local spX, spY = renderer.measure_text(t_opt, "SP")
        local bindsX, bindsY = renderer.measure_text(t_opt, "BAIM FS SP")

        --ghetto
        if scoped then
            if lua_name == "BETA" then
                bX = bX + 6
            elseif lua_name == "LIVE" then
                bX = bX + 10
            end 
        end
        --colors
        local bR, bG, bB, bA = ui.get(gui.vis.mod_clr_beta_1)
        local eR, eG, eB, eA = ui.get(gui.vis.mod_clr_exploits_1)
        local biR, biG, biB, biA = ui.get(gui.vis.mod_clr_binds_1)
        local iR, iG, iB, iA = 200, 200, 200, 175


        local spacer = 9
        
        local pos = nX / 2
        local bPos = bX / 2

        local r, g, b = ui.get(gui.vis.def_clr_beta_1)
        local alpha = self:pulsate_text(lua_name, 0.75, 255)

        local dt = ui.get(menu.ref.dt[2]) and ui.get(menu.ref.dt[1])
        local hs = ui.get(menu.ref.aa_hs[2]) and ui.get(menu.ref.aa_hs[1])
        local qp = ui.get(menu.ref.qp[2]) and ui.get(menu.ref.qp[1])
        local baim = ui.get(menu.ref.force_baim)
        local fs = antiaim.fs_active

        local sp = ui.get(menu.ref.force_sp)

        if sp then
            spR, spG, spB, spA = biR, biG, biB, biA
        else
            spR, spG, spB, spA = iR, iG, iB, iA
        end

        if baim then
            baimR, baimG, baimB, baimA = biR, biG, biB, biA
        else
            baimR, baimG, baimB, baimA = iR, iG, iB, iA
        end
        
        if fs then
            fsR, fsG, fsB, fsA = biR, biG, biB, biA
        else
            fsR, fsG, fsB, fsA = iR, iG, iB, iA
        end

        --scope shit
        self.modern_anim.scope.name = self:animation(scoped, self.modern_anim.scope.name, 20, 8)
        self.modern_anim.scope.build = self:animation(scoped, self.modern_anim.scope.build, 14, 8)
        self.modern_anim.scope.dt = self:animation(scoped, self.modern_anim.scope.dt, 6, 8)
        self.modern_anim.scope.hs = self:animation(scoped, self.modern_anim.scope.hs, 8, 8)
        self.modern_anim.scope.qp = self:animation(scoped, self.modern_anim.scope.qp, 8, 8)
        self.modern_anim.scope.binds = self:animation(scoped, self.modern_anim.scope.binds, 21, 8)

        --alpha
        self.modern_anim.alpha.dt = self:animation(dt, self.modern_anim.alpha.dt, eA, 8)
        self.modern_anim.alpha.hs = self:animation(hs, self.modern_anim.alpha.hs, eA, 8)
        self.modern_anim.alpha.qp = self:animation(qp, self.modern_anim.alpha.qp, biA, 8)
        self.modern_anim.baim = self:animation(baim, self.modern_anim.baim, 255, 8)
        self.modern_anim.fs = self:animation(fs, self.modern_anim.fs, 255, 8)
        self.modern_anim.sp = self:animation(sp, self.modern_anim.sp, 255, 8)

        --render
        offset = 18
        
        --extra anims for smoothnessss
        self.modern_anim.dt = self:animation(dt, self.modern_anim.dt, offset + 1, 8)
        renderer.text(x - 12 + self.modern_anim.scope.dt + dX / 2 + 3, y + self.modern_anim.dt, eR, eG, eB, self.modern_anim.alpha.dt, t_opt, 0, "DT" )
        if dt then offset = offset + spacer end

        --hs
        self.modern_anim.hs = self:animation(hs, self.modern_anim.hs, offset + 1, 8)
        renderer.text(x - 12 + self.modern_anim.scope.hs + hX / 2 + 1, y + self.modern_anim.hs, eR, eG, eB, self.modern_anim.alpha.hs, t_opt, 0, "HS" )
        if hs then offset = offset + spacer end

        --qp
        self.modern_anim.qp = self:animation(qp, self.modern_anim.qp, offset + 1, 8)
        renderer.text(x - 12 + self.modern_anim.scope.qp + qX / 2 + 1, y + self.modern_anim.qp, biR, biG, biB, self.modern_anim.alpha.qp, t_opt, 0, "QP" )
        if qp then offset = offset + spacer end

        self.modern_anim.smoothhh = self:animation(true, self.modern_anim.smoothhh, offset + 1, 8)


        --binds
        local pos1 = bindsX / 3 - 36
        local pos2 = bindsX / 2  - 21
        local pos3 = bindsX
        renderer.text(x - pos3 / 2 + (self.modern_anim.scope.binds), y + self.modern_anim.smoothhh, baimR, baimG, baimB, baimA, t_opt, 0, "BAIM" )
        renderer.text(x - pos2 / 2 + (self.modern_anim.scope.binds), y + self.modern_anim.smoothhh, fsR, fsG, fsB, fsA, t_opt, 0, "FS" )
        renderer.text(x - pos1 / 2 + (self.modern_anim.scope.binds), y + self.modern_anim.smoothhh, spR, spG, spB, spA, t_opt, 0, "SP" )

        --better to render last
        renderer.text(x - pos + self.modern_anim.scope.name, y, 255, 255, 255, 255, t_opt, 0, "LAVENDER " )
        
        renderer.text(x - bPos + self.modern_anim.scope.build, y + 9, bR, bG, bB, alpha, t_opt, 0, lua_name )
    end,


    avatar_storage = {},

    watermark = function(self, x, y)
        local me = entity.get_local_player()
        if not me or entity.get_prop(me, "m_lifeState") ~= 0 then return end

        -- top bar
        local bR, bG, bB, bA = ui.get(gui.vis.watermark_theme_clr_1)
        renderer.rectangle(18, y, 150, 2, bR, bG, bB, 255)

        --drop shadow small thing test
        --renderer.rectangle(20, y + 2, 150, 1, 15, 15, 15, 75)
        local textX = 65


        --gradient
        renderer.gradient(18, y + 2, 150, 45, bR, bG, bB, 100, bR, bG, bB, 0, false)

        --username
        local name = lavender.usr:upper()
        renderer.text(textX, y + 6, 255, 255, 255, 255, "-", 0, "USER: ")
        renderer.text(textX + 24, y + 6, bR, bG, bB, 255, "-", 0, name)

        --build
        local vers = lavender.build:upper()
        renderer.text(textX, y + 16, 255, 255, 255, 255, "-", 0, "BUILD: ")
        renderer.text(textX + 26, y + 16, bR, bG, bB, 255, "-", 0, vers)

        --current state
        local state = string.upper(ent_helper:get_state())
        renderer.text(textX, y + 26, 255, 255, 255, 255, "-", 0, "STATE: ")
        renderer.text(textX + 27, y + 26, bR, bG, bB, 255, "-", 0, state)

        --desync amount
        local dsync = antiaim:get_desync_amount()
        local dsync_w = math.ceil(dsync * 60)
        --renderer.text(textX, y + 34, 255, 255, 255, 255, "-", 0, "DESYNC: ")
        --renderer.text(58, y + 34, 255, 255, 255, 255, "-", 0, dsync_w)

        renderer.gradient(60, y + 41, 108, 1, bR, bG, bB, 175, bR, bG, bB, 255, true)

        renderer.text(textX + 45, y + 42, 155, 155, 155, 155, "-", 0, "LAVENDER  2022")
        --renderer.text(textX + 30, y - 7, 155, 155, 155, 155, "-c", 0, "LAVENDER  2022")

        local steam_id = entity.get_steam64(me)
        local avatar = images.get_steam_avatar(steam_id)
        
        if self.avatar_storage[me] == nil or self.avatar_storage[me].conts ~= avatar.contents then
            self.avatar_storage[me] = {
                conts = avatar.contents,
                texture = renderer.load_rgba(avatar.contents, avatar.width, avatar.height)
            }
        end

        renderer.gradient(60, y + 2, 2, 40, bR, bG, bB, 175, bR, bG, bB, 25, false)
        renderer.gradient(166, y + 2, 2, 40, bR, bG, bB, 175, bR, bG, bB, 25, false)
        renderer.gradient(18, y + 2, 2, 40, bR, bG, bB, 175, bR, bG, bB, 25, false)

        --render picture
        renderer.texture(self.avatar_storage[me].texture, 20, y + 2, 40, 40, 255, 255, 255, 255, "f")


    end,

    main_handle = function(self, x, y)
        local enable = ui.get(gui.vis.main)
        local indicator = ui.get(gui.vis.indicators)

        local additives = ui.get(gui.vis.additives)

        self:render_logs()

        if enable then
            local ypos = ui.get(gui.vis.indcators_height)
            if menu:contains(additives, "arrows") then
                local ypos_arrow = ui.get(gui.vis.arrow_height)
                self:arrows(x * .5, y * .5 + ypos_arrow)
            end
            if menu:contains(additives, "watermark") then
                local ypos_watermark = ui.get(gui.vis.watermark_height)
                self:watermark(x, y * .5 + ypos_watermark)
            end

            if indicator == "default" then
                self:default_indicator(x * .5, y * .5 + ypos)
            elseif indicator == "advanced" then
                self:new_indicator(x * .5, y * .5 + ypos)
            elseif indicator == "modern" then
                self:modern_indicator(x * .5, y * .5 + ypos)
            end
        end
    end,
}

local misc = {

    ground_ticks = 1, 
    end_time = 0,

    anim_breaker = function(self, cmd)
        local anims = ui.get(gui.misc.animations) --"legs", "freeze legs in air", "0 pitch land", "fakelag animation"
        local me = entity.get_local_player()

        if me ==  nil then return end
        
        local hs = ui.get(menu.ref.aa_hs[1]) and ui.get(menu.ref.aa_hs[2])
        local dt = ui.get(menu.ref.dt[1]) and ui.get(menu.ref.dt[2])

        if menu:contains(anims, "legs") then
            local strafing = entity.get_prop(me, "m_bStrafing")
            local random = math.random(1, 2)
            entity.set_prop(me, "m_flPoseParameter", 1, 0)
            if strafing == 1 then
                value = "Never slide"
            else
                value = "Always slide"
            end
            ui.set(menu.ref.aa_legs, value)
        end

        if menu:contains(anims, "freeze legs in air") then
            entity.set_prop(me, "m_flPoseParameter", 1, 6)
        end

        if menu:contains(anims, "0 pitch land") then
            local on_ground = bit.band(entity.get_prop(me, "m_fFlags"), 1)
            
            if on_ground == 1 then
                self.ground_ticks = self.ground_ticks + 1
            else
                self.ground_ticks = 0
                self.end_time = globals.curtime() + 1
            end 
            if self.ground_ticks > ui.get(menu.ref.fl_limit)+1 and self.end_time > globals.curtime() then
                entity.set_prop(me, "m_flPoseParameter", 0.5, 12)
            end
        end
    
        if menu:contains(anims, "fakelag animation") then
            p = math.random(1, 2)

            if dt or hs then 
                return
            end
            entity.set_prop(entity.get_local_player(), "m_flPoseParameter", math.random(0, 1), math.random(1, 4))

            if p == 0 then
                ui.set(menu.ref.aa_legs, "Always slide")
            elseif p == 1 then
                ui.set(menu.ref.aa_legs, "never slide")
            else
                ui.set(menu.ref.aa_legs, "never slide")
            end

        end
    end,

    killsay = function(self, e)

        local victim_id = e.userid
        local victim = client.userid_to_entindex(victim_id)

        local me = entity.get_local_player()
    
        local attacker_id = e.attacker
        local attacker = client.userid_to_entindex(attacker_id)

        if attacker == me then
            if e.headshot then
                killsay_nn = {
                    '𝕪𝕦𝕠 𝕘𝕠𝕥 𝕙𝕖𝕒𝕕𝕖𝕕 𝕓𝕖𝕔𝕒𝕦𝕤𝕖 𝕪𝕠𝕦 𝕙𝕒𝕧𝕖 𝕟𝕠 𝕝𝕒𝕧𝕖𝕟𝕕𝕖𝕣',
                    "𝕝𝕒𝕧𝕖𝕟𝕕𝕖𝕣 𝕥𝕠𝕠 𝕤𝕥𝕣𝕠𝕟𝕜 𝕗𝕠𝕣 𝕖𝕟𝕖𝕞𝕪",
                    "𝕨𝕙𝕪 𝕞𝕚𝕤𝕤? 𝕓𝕖𝕔𝕒𝕦𝕤𝕖 𝕒𝕞 𝕦𝕤𝕖 𝕝𝕒𝕧𝕖𝕟𝕕𝕖𝕣",
                    "𝕥𝕣𝕪 𝕙𝕚𝕥 𝕞𝕖 𝕙𝕖𝕒𝕕",
                }  
                   ran_pick = math.random(1,4)
                   client.exec("say " .. killsay_nn[ran_pick])
            else
                killsay_nn = {
                    '𝕌 𝕒ℝ𝔼 𝔸ℝ𝔼 𝕋ℝ𝕐 𝕎𝕀ℕℕ𝕀ℕ𝔾 𝕄𝔼? 𝕓𝕚𝕘 𝕡𝕣𝕠𝕓𝕝𝕖𝕞',
                    "𝕪𝕠𝕦𝕣'𝕣𝕖 𝕒𝕣𝕖 𝕘𝕠𝕥 𝕕𝕖𝕒𝕕𝕖𝕕 𝕓𝕪 𝕝𝕒𝕧𝕖𝕟𝕕𝕖𝕣",
                    "𝕚 𝕒𝕞 𝕦𝕤𝕖 𝕓𝕖𝕤𝕥 𝕒𝕟𝕥𝕚𝕒𝕚𝕞 𝕝𝕦𝕒",
                    "𝕔𝕒𝕟𝕥 𝕙𝕚𝕥??? 𝕃𝔸𝕧𝕖𝕟𝕕𝕖𝕣 𝕝𝕦𝕒",
                }  
                ran_pick = math.random(1,4)
                client.exec("say " .. killsay_nn[ran_pick])
            end
        end
    end,

    teleport_dt = function(self)
        if menu:contains(ui.get(gui.misc.extras), "teleport dt") then
            local active_key = ui.get(gui.misc.key_teleport)

            --ui.set(menu.ref.dt[1], true)
            ui.set(menu.ref.dt[2], "Toggle")
            --ui.set(menu.ref.dt[1], true)
            local me = entity.get_local_player()
            if me == nil then return end

            local lx, ly = entity.get_origin(me)

            if active_key then
                renderer.indicator(150, 200, 60, 255, "TELEPORT")
            end

            local enemy = client.current_threat()
            if enemy == nil then return end

            local check_range = 200
            local x, y = entity.get_origin(enemy)

            local newextrapolatedPos = ent_helper:canEnemyHitUsPeek(enemy, 3, "local", active_key)

            if active_key then
                if newextrapolatedPos then
                    --ui.set(menu.ref.dt[1], false)
                    ui.set(menu.ref.dt[2], "On hotkey")
                end
            end
        end
    end,

    faster_dt = function(self)
       
    end,

    force_defensive = function(self, cmd)
        local active = menu:contains(ui.get(gui.misc.extras), "force defensive")

        if active then
            local key = ui.get(gui.misc.key_defensive)

            if key then
                cmd.force_defensive = -1
            end
        end
    end,

    hitgroup_names = {
        "generic",
        "head",
        "chest",
        "stomach",
        "left arm",
        "right arm",
        "left leg",
        "right leg",
        "neck",
        "?",
        "gear"
    },    

    hitlog = function(self, event)
        local active = menu:contains(ui.get(gui.vis.additives), "logs") and menu:contains(ui.get(gui.vis.logs_display), "hit")
        
        if active then
            local red, green, blue = ui.get(gui.vis.logs_clr_1)
            
            local clr = '\a' .. menu:rgbToHex(red, green, blue) ..'ff'
            local w = "\aFFFFffff"
            local txt = 'hit ' .. clr .. entity.get_player_name( event.target ) .. w .. " in " .. clr .. self.hitgroup_names[ event.hitgroup + 1 ] .. w .. " for " ..  clr .. event.damage .. w .. " hp"
            visuals:add_to_log(txt)
        end
    end,

    misslog = function(self, event)
        local active = menu:contains(ui.get(gui.vis.additives), "logs") and menu:contains(ui.get(gui.vis.logs_display), "miss")
        
        if active then
            local red, green, blue = ui.get(gui.vis.logs_clr_1)
            
            local clr = '\a' .. menu:rgbToHex(red, green, blue) ..'ff'
            local w = "\aFFFFffff"
            local txt = 'missed ' .. clr .. entity.get_player_name( event.target ) .. w .. " due to " .. clr .. event.reason .. w
            visuals:add_to_log(txt)
        end
    end,
}



client.set_event_callback("pre_render", function()
    local enable = ui.get(gui.enable)

    if enable then
        local me = entity.get_local_player()
        if me == nil then return end
        antiaim.c_store.strafing = entity.get_prop(me, "m_bStrafing") == 1
        misc:anim_breaker()
    end
end)

client.set_event_callback("setup_command", function(cmd)
    local enable = ui.get(gui.enable)

    if enable then
        math.randomseed(client.unix_time())

        antiaim:warmup_aa(cmd)
        antiaim:generate_log()
        antiaim:main_handle(cmd)

        local antibackstab_on = menu:contains(ui.get(gui.misc.extras), "anti backstab")
        if antibackstab_on then
            antiaim:anti_backstab(cmd)
        else
            antiaim.anti_backstab_active = false
        end
        local improve_exploit = ui.get(gui.aa.on_shot_fix)
        antiaim:on_shot_fix(cmd, improve_exploit)

        disable_custom = false

        antiaim:handle_keybinds(cmd)

        misc:faster_dt()
        misc:force_defensive(cmd)

        antiaim:legit_aa(cmd)

        ent_helper.threat = client.current_threat()
    end
end)

client.set_event_callback("paint_ui", function()
    local enable = ui.get(gui.enable)

    if ui.is_menu_open() then
        menu:visiblity()
    end
    
    if enable then
        local me = entity.get_local_player()
        if #antiaim.p_data.log > 0 then
            if me == nil then
                antiaim.p_data.log = {}
            end
        end

        local aa = ui.get(gui.aa.preset)
        local mode = ui.get(gui.aa.auto_mode)
        local experimental = aa == "automatic" and mode == "experimental"

        if not experimental or disable_custom then
            ui.set(menu.ref.aa.enabled, true)
            if disable_custom and not antiaim.legit_aa_active and not antiaim.fs_active then
                menu:stock_jitter()
            end
            if antiaim.enable_fs then
                ui.set(menu.ref.aa.pitch, "Down")
                ui.set(menu.ref.aa.yaw_base, "At targets")
                ui.set(menu.ref.aa.yaw[1], "180")
                ui.set(menu.ref.aa.yaw[2], 0)
                ui.set(menu.ref.aa.yaw_jitter[1], "Off")
                ui.set(menu.ref.aa.yaw_jitter[2], 0)
                ui.set(menu.ref.aa.body_yaw[1], "Opposite")
                ui.set(menu.ref.aa.fs_body_yaw, true)
                ui.set(menu.ref.aa.roll, 0)
                ui.set_visible(menu.ref.aa.fs_body_yaw, false)
            end
        end
    
        local x, y = client.screen_size()
        visuals:main_handle(x, y)
        misc:teleport_dt()
    end
end)

ui.set_callback(gui.enable, function()
    if not ui.get(gui.enable) then
        ui.set(menu.ref.aa.pitch, "Down")
        ui.set(menu.ref.aa.yaw_base, "At targets")
        ui.set(menu.ref.aa.yaw[1], "180")
        ui.set(menu.ref.aa.yaw[2], 0)
        ui.set(menu.ref.aa.yaw_jitter[1], "Off")
        ui.set(menu.ref.aa.yaw_jitter[2], 0)
        ui.set(menu.ref.aa.body_yaw[1], "Opposite")
        ui.set(menu.ref.aa.fs_body_yaw, false)
        ui.set(menu.ref.aa.roll, 0)
        ui.set_visible(menu.ref.aa.fs_body_yaw, false)
    end
end)

client.set_event_callback("shutdown", function()
    local enable = ui.get(gui.enable)

    if enable then
        menu:skeet_menu(true)
    end
end)

client.set_event_callback("switch_team", function(e)
    local enable = ui.get(gui.enable)

    if enable then
        antiaim:log_check()
    end
end)

client.set_event_callback("player_disconnect", function(e)
    local enable = ui.get(gui.enable)

    if enable then
        antiaim:log_check()
    end
end)

client.set_event_callback("bullet_impact", function(e)
    local enable = ui.get(gui.enable)
    if enable then
	    antiaim:antibf_impact(e)
    end
end)

client.set_event_callback("player_death", function(e)
    local enable = ui.get(gui.enable)
    if enable then
	    antiaim:antibf_death(e)
        local killsay = menu:contains(ui.get(gui.misc.extras), "killsay")
        if killsay then
            misc:killsay(e)
        end
    end
end)

client.set_event_callback("aim_fire", function(e)
    local enable = ui.get(gui.enable)
    if enable then
	    antiaim.did_shoot = globals.curtime() + 1.25
    end
end)

client.set_event_callback("aim_hit", function(e)
    local enable = ui.get(gui.enable)
    if enable then
        misc:hitlog(e)
    end
end)

client.set_event_callback("aim_miss", function(e)
    local enable = ui.get(gui.enable)
    if enable then
        misc:misslog(e)
    end
end)

local red, green, blue = ui.get(gui.vis.logs_clr_1)
local clr = '\a' .. menu:rgbToHex(red, green, blue) ..'ff'
local w = "\aFFFFffff"
local strB = clr .. string.lower(lavender.build)
visuals:add_to_log(w .. "welcome to " .. strB .. w ..  " version!")