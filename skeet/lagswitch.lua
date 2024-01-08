-- GAMESENSE.PUB

local ref_aim_check = ui.reference("rage", "other", "enabled")
local ref_duckpeek = ui.reference("rage", "other", "duck peek assist")

local trigger_speed = ui.new_slider("lua", "b", "Timer", 0, 100, 10)
local function exploit(cmd)
    local me = entity.get_local_player()
    if me == nil then return end

    local timer = entity.get_prop(me, "m_nTickbase") % ui.get(trigger_speed) == 0
    local air = bit.band(entity.get_prop(me, "m_fFlags"), 1) == 0

    if air then
        ui.set(ref_duckpeek, timer and "Always on" or "Toggle")
        ui.set(ref_aim_check, false)

        cmd.in_duck = not timer
    else
        ui.set(ref_aim_check, true)
        ui.set(ref_duckpeek, "Toggle")
    end
end

client.set_event_callback("setup_command", function(cmd)

    exploit(cmd)

end)