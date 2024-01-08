local userid = 123--get_id()

local menu_get, menu_set, menu_checkbox, menu_slider, menu_combobox, menu_multiselect, menu_hotkey, menu_button, menu_colorpicker, menu_textbox, menu_listbox, menu_string, menu_label, menu_reference, menu_set_callback, menu_setvisible, client_set_event_callback, render_measure_text = ui.get, ui.set, ui.new_checkbox, ui.new_slider, ui.new_combobox, ui.new_multiselect, ui.new_hotkey, ui.new_button, ui.new_color_picker, ui.new_textbox, ui.new_listbox, ui.new_string, ui.new_label, ui.reference, ui.set_callback, ui.set_visible, client.set_event_callback, renderer.measure_text
local entity_get_prop, entity_get_local_player, entity_is_alive, entity_get_player_weapon, entity_get_classname, entity_get_origin, globals_frametime, client_screen_size, globals_framecount, is_menu_open, menu_mouse_position, client_key_state, table_insert, entity_get_steam64, render_circle_outline, entity_get_all, globals_tickinterval = entity.get_prop, entity.get_local_player, entity.is_alive, entity.get_player_weapon, entity.get_classname, entity.get_origin, globals.frametime, client.screen_size, globals.framecount, ui.is_menu_open, ui.mouse_position, client.key_state, table.insert, entity.get_steam64, renderer.circle_outline, entity.get_all, globals.tickinterval
local math_sqrt, bit_band, globals_curtime, math_floor, bit_lshift, globals_tickcount, entity_get_players, entity_get_player_name, entity_get_steam64, client_userid_to_entindex, entity_is_enemy, entity_is_dormant, entity_hitbox_position, math_max, math_abs, render_text = math.sqrt, bit.band, globals.curtime, math.floor, bit.lshift, globals.tickcount, entity.get_players, entity.get_player_name, entity.get_steam64, client.userid_to_entindex, entity.is_enemy, entity.is_dormant, entity.hitbox_position, math.max, math.abs, renderer.text


local aa = {}
local menu = {}
menu.f = {}

menu.f.call = function(x)
	return { menu_reference("aa", "anti-aimbot angles", x) }
end

menu.refs = {
	enable = menu.f.call("enabled"),
	pitch = menu.f.call("pitch"),
	base = menu.f.call("yaw base"),
	yaw = menu.f.call("yaw"),
	jitter = menu.f.call("yaw jitter"),
	body = menu.f.call("body yaw"),
	fs = menu.f.call("freestanding body yaw"),
	edge = menu.f.call("edge yaw"),
	freestand = menu.f.call("freestanding"),
	roll = menu.f.call("roll"),
	slowmotion = { menu_reference("aa", "other", "Slow motion") },
	fd = menu_reference("rage", "other", "duck peek assist"),
	dt = { menu_reference("rage", "other", "double tap") },
	hs = { menu_reference("aa", "other", "on shot anti-aim") },
	fl_enabled = menu_reference("aa", "fake lag", "enabled"),
	fl_limit = menu_reference("aa", "fake lag", "limit"),
	leg_movement = menu_reference("aa", "other", "leg movement"),
}

aa.p_data = {
    yaw_status = "default",
    indexed_angle = 0,
    last_miss = 0,
    best_angle = 0,
    misses = { }, --this is either nil, 1 or 2
    hit_reverse = { },
    log = {},
    switch = false,
}

aa.log_check = function(self)
    for j, x in next, self.p_data.log do
        local hp = entity_get_prop(x.idx, "m_iHealth")
        local team = entity_get_prop(x.idx, "m_iTeamNum")
        if hp == nil or team == nil then
            --print("id: " .. j .. " entid: " .. x.idx .. " hp: " .. tostring(hp))
            --print ("succesfully removed") 
            table.remove(self.p_data.log, j)
        else
            if team == entity_get_prop(me, "m_iTeamNum") then
                --print ("succesfully removed " .. entity_get_player_name(j) .. " due to being same team") 
                table.remove(self.p_data.log, j)
            end
        end
    end
end

aa.antibf_impact = function(self, e)
    --if not ui.get(menu.main_aa) then return end

    local me = entity_get_local_player()

    if not entity_is_alive(me) then return end

    local shooter_id = e.userid
    local shooter = client_userid_to_entindex(shooter_id)

    -- Distance calculations can sometimes bug when the entity is dormant hence the 2nd check.
    if not entity_is_enemy(shooter) or entity_is_dormant(shooter) then return end

    local lx, ly, lz = entity_hitbox_position(me, "head_0")
    
    local ox, oy, oz = entity_get_prop(me, "m_vecOrigin")
    local ex, ey, ez = entity_get_prop(shooter, "m_vecOrigin")

    local dist = ((e.y - ey)*lx - (e.x - ex)*ly + e.x*ey - e.y*ex) / math.sqrt((e.y-ey)^2 + (e.x - ex)^2)
    
    -- 32 is our miss detection radius and the 2nd check is to avoid adding more than 1 miss for a singular bullet (bullet_impact gets called mulitple times per shot).
    if math_abs(dist) <= 32 and globals_curtime() - self.p_data.last_miss > 0.015 then
        self.p_data.last_miss = globals_curtime()
        if self.p_data.log[shooter] == nil then
        self.p_data.log[shooter] = {
				idx = shooter,
                yaw = 0,
                yaw_min = 0,
                yaw_max = 0,
                jitter = 0,
                jitter_min = 0,
                jitter_max = 0,
                should_update = true,
                should_update_fake = true,
                last_miss = 0,
                misses = 0,	
                cached_yaw = 0,
                cached_jitter = 0,
                fake = {f1 = 0, f2 = 0}
            }
            else
            self.p_data.log[shooter].should_update_fake = true
            self.p_data.log[shooter].should_update = true

            self.p_data.log[shooter].misses = self.p_data.log[shooter].misses + 1
            self.p_data.log[shooter].last_miss = globals_curtime()
        end
    end
end

aa.antibf_death = function(self, e)        
    local victim_id = e.userid
    local victim = client.userid_to_entindex(victim_id)

    if victim ~= entity_get_local_player() then return end

    local attacker_id = e.attacker
    local attacker = client_userid_to_entindex(attacker_id)

    if not entity_is_enemy(attacker) then return end

    if not e.headshot then return end

    if self.p_data.misses[attacker] == nil or (globals_curtime() - self.p_data.last_miss < 0.06 and self.p_data.misses[attacker] == 1) then
        if self.p_data.log[attacker] == nil then
            self.p_data.log[attacker] = {
				idx = attacker,
                yaw = 0,
                yaw_min = 0,
                yaw_max = 0,
                jitter = 0,
                jitter_min = 0,
                jitter_max = 0,
                should_update = true,
                should_update_fake = true,
                last_miss = 0,
                misses = 0,	
                cached_yaw = 0,
                cached_jitter = 0,
                fake = {f1 = 0, f2 = 0}
            }
        else
            self.p_data.log[attacker].should_update = true
            self.p_data.log[attacker].should_update_true = true
        end
    end
end

local main_cache_min = 0
local main_cache_max = 0

local jitter_m_cache = 0
local jitter_m2_cache = 0


aa.calculate_yaw = function(self, cmd, yaw)
    local localplayer = entity_get_local_player()
    if localplayer == nil or not entity_is_alive(localplayer) then
        return
    end

    --math.randomseed(client.unix_time())
    math.randomseed(globals_curtime())

    local target = client.current_threat()
	if target == nil then
		return { -4, 5, 68, 84, false }
	end

    if self.p_data.log[target] then
		if self.p_data.log[target].should_update then
			if self.p_data.log[target].yaw == nil then self.p_data.log[target].yaw = {y = 0, y2 = 0} end
            --self.p_data.log[target].yaw_min = menu_get(main_yaw_min)
            --self.p_data.log[target].yaw_max = menu_get(main_yaw_max)

            --self.p_data.log[target].jitter_min = menu_get(jitter_min)
            --self.p_data.log[target].jitter_max = menu_get(jitter_max)

            self.p_data.log[target].yaw = math.random(menu_get(main_yaw_min), menu_get(main_yaw_max))

            local diff = self.p_data.log[target].cached_yaw - self.p_data.log[target].yaw
            --if self.p_data.log[target].cached_yaw - 2 < self.p_data.log[target].yaw and self.p_data.log[target].cached_yaw + 2 > self.p_data.log[target].yaw then
            local r = menu_get(main_yaw_min)
            local r2 = menu_get(main_yaw_max)


            self.p_data.log[target].jitter = math.random(menu_get(jitter_min), menu_get(jitter_max))

            print("generate for: " .. entity_get_player_name(target) .. " main: " .. self.p_data.log[target].yaw .. " jitter: " .. self.p_data.log[target].jitter)


            self.p_data.log[target].cached_yaw = self.p_data.log[target].yaw
            self.p_data.log[target].cached_jitter = self.p_data.log[target].jitter

            self.p_data.log[target].fake.f1 = math.random(45, 100)
            self.p_data.log[target].fake.f2 = -math.random(45, 100)

            self.p_data.log[target].should_update = false
        end

		if self.p_data.log[target].should_update_fake then
            self.p_data.log[target].fake.f1 = math.random(45, 120)
            self.p_data.log[target].fake.f2 = -math.random(45, 120)

            self.p_data.log[target].should_update_fake = false
        end
		return { self.p_data.log[target].yaw, self.p_data.log[target].jitter, self.p_data.log[target].fake.f1, self.p_data.log[target].fake.f2}

        --return { self.p_data.log[target].yaw_min, self.p_data.log[target].yaw_max, self.p_data.log[target].jitter_min,  self.p_data.log[target].jitter_max}

    end
    return {0, 0}    
end

aa.n_cache = {
	nade = 0,
	on_ladder = false,
	holding_nade = false
}

aa.run_command_check = function()
	local me = entity.get_local_player()
	if me == nil then return end

	aa.n_cache.on_ladder = entity.get_prop(me, "m_MoveType") == 9 

	local selected = entity_get_player_weapon(ent)
	if selected == nil then return end
	local weapon = entity_get_classname(selected)
	aa.n_cache.holding_nade = weapon:find("Grenade")
end

aa.can_desync = function(self, cmd, ent, count, vel)
	if self.disablers.anti_backstab then return end
	local selected = entity_get_player_weapon(ent)
	if cmd.in_attack == 1 or cmd.in_attack2 == 1 or cmd.in_attack3 == 1 then
		local weapon = entity_get_classname(selected)
		if aa.n_cache.holding_nade then
			self.n_cache["nade"] = count
		else
			if cmd.in_attack2 == 0 and entity.get_prop(selected, "m_flNextPrimaryAttack") - 0.1 < globals.curtime() - globals.tickinterval() then
				return false
			end
		end
	end
	local throw = entity.get_prop(selected, "m_fThrowTime")
	if self.n_cache["nade"] + 8 == count or (throw ~= nil and throw ~= 0) then return false end
	if entity.get_prop(entity.get_game_rules(), "m_bFreezePeriod") == 1 then return false end
	if self.n_cache.on_ladder and vel ~= 0 then return false end
	if cmd.in_use == 1 then return false end
	return true
end

local delays = {
	choked = 0,
	mouse1 = 0,
	dt = 0,
	dt2 = 0,
}

local vector = require("vector")

aa.disablers = {
	at_targets = false,
	manual_yaw = 0,
	legit_aa = false,
	anti_backstab = false,
}

aa.at_targets = function(self, threat)
	local pitch, yaw2 = client.camera_angles()
	if self.disablers.at_targets then
		return pitch, yaw2 + self.disablers.manual_yaw + 180
	else
		if threat ~= nil then
			local eyepos = vector(client.eye_position())
			local origin = vector(entity_get_origin(threat))
			local target = origin + vector(0, 0, 40)
			pitch, yaw = eyepos:to(target):angles() 
			return pitch, yaw + self.disablers.manual_yaw + 180
		else
			return pitch, yaw2 + self.disablers.manual_yaw + 180
		end
	end
end

local entity = {}
entity.get_velocity = function(self, player)
	if player == nil then return end
	local x,y,z = entity_get_prop(player, 'm_vecVelocity')
	return math_sqrt(x*x + y*y + z*z)
end


aa.get_choke = function(self, cmd)
    local fakelag = menu_get(menu.refs.fl_limit)

	local check_fakelag = fakelag % 2 == 1

    local choked = cmd.chokedcommands
    local check_choke = choked % 2 == 0

	local dt_on = menu_get(menu.refs.dt[2]) and menu_get(menu.refs.dt[1])
	local hs_on = menu_get(menu.refs.hs[2]) and menu_get(menu.refs.hs[1])
	local fd_on = menu_get(menu.refs.fd)

	local vel = entity:get_velocity(entity_get_local_player())
	if dt_on then
		if delays.choked > 2 then
			if cmd.chokedcommands >= 0 then
				check_choke = false
			end
		end
	end

	delays.choked = cmd.chokedcommands

	if delays.dt ~= dt_on then
		delays.dt2 = globals_curtime() + 0.25
	end

	if not dt_on and not hs_on and not cmd.no_choke or fd_on then
        if not check_fakelag then
			if delays.dt2 > globals_curtime() then
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
	
	delays.dt = dt_on
	return check_choke
end

aa.micromovements = function(self, cmd, player)
	local active_wpn = entity_get_player_weapon(player)
	if active_wpn == nil then return end

	local weapon = entity_get_classname(active_wpn)
	if weapon == nil then return end

	if weapon:find("Grenade") then
		return
	end

	local velocity = math_floor(entity:get_velocity(player))
    local m_fFlags = entity_get_prop(player, "m_fFlags")
    local duck = entity_get_prop(player, "m_flDuckAmount") > 0.7

    local on_ground = bit_band(m_fFlags, bit_lshift(1, 0)) == 1

    --we dont rly need the vel check but lets just have it
    local micro = globals.tickcount() % 2 == 0
	local w, a, s, d = cmd.in_forward == 1, cmd.in_moveleft == 1, cmd.in_moveright == 1, cmd.in_back == 1

    if not on_ground then return end
    if w or a or s or d then return end

	local amount = duck and 3.25 or 1.1
    if velocity < 1.1 then
        cmd.sidemove = micro and amount or -amount;
    end
end


aa.c_store = {
	jitter = false,
	yaw = 0,
	invert = false,
	disable_at_targets = true,
	tick = 0,
	did_shoot = false,
}
local ticks_dt = ui.reference("MISC", "SETTINGS", "sv_maxusrcmdprocessticks")
local fl_dt = ui.reference("rage", "other", "Double tap fake lag limit")
local dt_mode = ui.reference("rage", "other", "Double tap mode")
local fakelag_limit = ui.reference("aa", "fake lag", "Limit")
local yaw = ui.reference("aa", "anti-aimbot angles", "yaw")
local ref = {
    enabled = ui.reference("AA", "Anti-aimbot angles", "Enabled"),
    pitch = ui.reference("AA", "Anti-aimbot angles", "Pitch"),
    yaw_base = ui.reference("AA", "Anti-aimbot angles", "Yaw base"),
    yaw = { ui.reference("AA", "Anti-aimbot angles", "Yaw") },
    yaw_jitter = { ui.reference("AA", "Anti-aimbot angles", "Yaw Jitter") },
    body_yaw = { ui.reference("AA", "Anti-aimbot angles", "Body yaw") },
    freestanding_body_yaw = ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw"),
    fake_yaw_limit = ui.reference("AA", "Anti-aimbot angles", "Fake yaw limit"),
    edge_yaw = ui.reference("AA", "Anti-aimbot angles", "Edge yaw"),
    freestanding = { ui.reference("AA", "Anti-aimbot angles", "Freestanding") },
    roll = ui.reference("AA", "Anti-aimbot angles", "Roll"),
}

local mainyaw = menu_slider("lua", "b", "factor", 0, 25, 0, true, "", 1)
local real = menu_slider("lua", "b", "yaw", -180, 180, 0, true, "", 1)
local fake = menu_slider("lua", "b", "fake", -122, 122, 0, true, "", 1)
local flick = menu_slider("lua", "b", "flick", -180, 180, 0, true, "", 1)

local side = false
aa.custom_desync = function(self, cmd)
	--force aa off
	local me = entity_get_local_player()
	if me == nil then return end

	local vel = entity:get_velocity(me)
	local count = globals.tickcount()

    local can_desync = self:can_desync(cmd, me, count, vel)
	
	local choke = self:get_choke(cmd)

	local pitch, yaw2 = client.camera_angles()
    local current_player = client.current_threat()
	
	local _, yaw = self:at_targets(current_player)

	pitch = 89
    menu_setvisible(ticks_dt, true)
    --self:micromovements(cmd, me)
    local tickbase = entity_get_prop(me, "m_nTickBase")
    local tick = tickbase % menu_get(mainyaw) == 1

    --menu_set(ref.body_yaw[1], "Off")

    if tick then
        menu_set(ref.body_yaw[1], "Opposite")
        --menu_set(ref.body_yaw[2], 0)
        menu_set(ref.yaw[2], menu_get(flick))
        cmd.force_defensive = true
    else
        menu_set(ref.body_yaw[1], "Off")
        --menu_set(ref.body_yaw[2], -180)
        menu_set(ref.yaw[2], menu_get(real))

    end


end

client_set_event_callback("setup_command", function(cmd)

	aa:custom_desync(cmd)

end)

client_set_event_callback("player_death", function(e)
	aa:antibf_death(e)
end)

client_set_event_callback("bullet_impact", function(e)
	--aa:antibf_impact(e)
end)