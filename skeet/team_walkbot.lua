local menu_get, menu_set, menu_checkbox, menu_slider, menu_combobox, menu_multiselect, menu_hotkey, menu_button, menu_colorpicker, menu_textbox, menu_listbox, menu_string, menu_label, menu_reference, menu_set_callback, menu_setvisible, client_set_event_callback, render_measure_text = ui.get, ui.set, ui.new_checkbox, ui.new_slider, ui.new_combobox, ui.new_multiselect, ui.new_hotkey, ui.new_button, ui.new_color_picker, ui.new_textbox, ui.new_listbox, ui.new_string, ui.new_label, ui.reference, ui.set_callback, ui.set_visible, client.set_event_callback, renderer.measure_text
local entity_get_prop, entity_get_local_player, entity_is_alive, entity_get_player_weapon, entity_get_classname, entity_get_origin, globals_frametime, client_screen_size, globals_framecount, is_menu_open, menu_mouse_position, client_key_state, table_insert, entity_get_steam64, render_circle_outline, entity_get_all, globals_tickinterval = entity.get_prop, entity.get_local_player, entity.is_alive, entity.get_player_weapon, entity.get_classname, entity.get_origin, globals.frametime, client.screen_size, globals.framecount, ui.is_menu_open, ui.mouse_position, client.key_state, table.insert, entity.get_steam64, renderer.circle_outline, entity.get_all, globals.tickinterval
local math_sqrt, bit_band, globals_curtime, math_floor, bit_lshift, globals_tickcount, entity_get_players, entity_get_player_name, entity_get_steam64, client_userid_to_entindex, entity_is_enemy, entity_is_dormant, entity_hitbox_position, math_max, math_abs, render_text, math_sin = math.sqrt, bit.band, globals.curtime, math.floor, bit.lshift, globals.tickcount, entity.get_players, entity.get_player_name, entity.get_steam64, client.userid_to_entindex, entity.is_enemy, entity.is_dormant, entity.hitbox_position, math.max, math.abs, renderer.text, math.sin

local vector = require("vector")

local aa = {}
local bot = {}

local tab = "lua"
local container = "b"

local update_list = menu_button("lua", "b", "[AUTOBOT] - Update players", function()

    for i, x in pairs(bot.players_click) do
        x[2] = false
    end

    bot.leader = nil
    bot:get_leader()
end)

local playerlist =  menu_listbox("lua", "b", "player list", function(self)

end)


local clicks = {
	click = false,
	delay = 0,
	lastitem = 0,
	stored_item = 0,
}

local function contains(tbl, val) 
    for i=1, #tbl do
        if tbl[i] == val then return true end 
    end 
    return false 
end

bot.leader = nil
bot.players = {}
bot.players_name = {}
bot.players_click = {}

local t_f = {
    [true] = "\aF40C0CFF",
	[false] = "\aA8B8B8FF",
}

menu_set_callback(playerlist, function(e)
	local listitem = menu_get(playerlist)
	local x = clicks

    if x.lastitem == listitem and x.delay + 0.5 > globals.curtime() and not x.click and x.delay ~= globals_curtime() then
        for i, x in pairs(bot.players_click) do
            if i ~= listitem + 1 then
                x[2] = false
            end
        end
        
		x.lastitem = -1
		x.delay = globals_curtime()
		x.click = true

		bot.players_click[listitem + 1][2] = not bot.players_click[listitem + 1][2] -- invert state (true / false)

		client.delay_call(0.2, function()
			x.click = false -- if we double click, reset the variable
		end)
	end

	if not x.click then
		x.delay = globals_curtime()
		x.lastitem = menu_get(playerlist)
	end
	
	local temp_list = {}

	for k, v in ipairs(bot.players_click) do
        local string = ("%s● %s %s"):format(t_f[v[2]], "\aFFFFFFC8", v[1])

        if not contains(temp_list, string) then
            table.insert(temp_list, string)
        end
	end

    bot:get_leader_tbl()
	ui.update(playerlist, temp_list)
end)


local helpers = {}
helpers.distance2D = function(self, x1, y1, x2, y2)
    return math_floor(math_sqrt((x2-x1)^2 + (y2-y1)^2) * 0.0833) --distance in feet
end

helpers.roundToNearest = function(self, number, multiple )
    local half = multiple/2
    return number+half - (number+half) % multiple
end

helpers.calcangle = function(self, x_src, y_src, z_src, x_dst, y_dst, z_dst)
    x_delta = x_src - x_dst
    y_delta = y_src - y_dst
    z_delta = z_src - z_dst
    hyp = math_sqrt(x_delta^2 + y_delta^2)
    x = math.atan2(z_delta, hyp) * 57.295779513082
    y = math.atan2( y_delta , x_delta) * 180 / 3.14159265358979323846

    if y > 180 then
        y = y - 180
    end
    if y < -180 then
        y = y + 180
    end
    return y
end

local spots = { }

local forward = false

local current_spot = 1

local last_angles_set = 0
local angles = true

bot.leader = nil
bot.leader_idx = nil
bot.leader_found = nil

bot.teams = {
    ["2"] = "T",
    ["3"] = "CT"
}

--[gamesense] 73426591

bot.getConfigNames = function()
	local values = {}
	
	for config_name, _ in pairs(bot.players) do
		table.insert(values, config_name)
	end

	return values
end

bot.getConfigNameForID = function(id)
	return configs.getConfigNames()[id]
end


bot.get_leader = function(self)
    local me = entity_get_local_player()

    if me == nil then
        return
    end

	local players = entity_get_players(false)

    self.leader_idx = nil
    self.players = {}
    self.players_name = {}
    self.players_click = {}
    for i=1, #players do
        local idx = players[i]

        local steam_id = entity_get_steam64(idx)
        local name = entity_get_player_name(idx)
        local team_num = entity_get_prop(idx, "m_iTeamNum")
        local teams = self.teams[tostring(team_num)]

        table.insert(self.players, {
            idx = idx,
            username = name,
            team = teams,
        
            steamid = steam_id,  

        })

        table.insert(self.players_name, "\aA8B8B8FF" .."●  " .. name)
        table.insert(self.players_click, {
            name,
            false
        })

        ::skip::
    end

    ui.update(playerlist, self.players_name)
end

bot.scope_wpns = {
    ["CWeaponSSG08"] = true,
    ["CWeaponSG556"] = true,
    ["CWeaponAWP"] = true,
    ["CWeaponG3SG1"] = true,
}

bot.scope = false
bot.is_leader_scoped = function(self, cmd, idx, me)
    local im_scoped = entity_get_prop(me, "m_bIsScoped") == 1
    local leader_scoped = entity_get_prop(idx, "m_bIsScoped") == 1

    local active_wpn = entity_get_player_weapon(me)
    if active_wpn == nil then return end

    local weapon = entity_get_classname(active_wpn)
    if weapon == nil then return end

    if self.scope_wpns[weapon] then
        if leader_scoped then
            if not im_scoped then
                cmd.in_zoom = 1
            end
        else
            if im_scoped then
                cmd.in_zoom = 1
            end
        end
    end
end

bot.get_leader_tbl = function(self)
    for i, x in ipairs(self.players_click) do
        if x[2] then
            bot.leader = self.players[i].idx
        end
    end
end

bot.is_leader_jumping = function(self, cmd, idx)
    local leader_jumping = bit_band(entity_get_prop(idx, "m_fFlags"), 1) == 0
    
    if leader_jumping then
        cmd.in_jump = 1
    end
end

bot.is_leader_ducking = function(self, cmd, idx)
    local leader_ducking = entity_get_prop(idx, "m_flDuckAmount") > 0.5

    if leader_ducking then
        cmd.in_duck = 1
    end
end

bot.get_leader_pos = function(self, idx)
    local lx, ly, lz = entity_get_prop(idx, "m_vecOrigin")
    if lx == nil then
        return
    end
    
    return {lx, ly, lz}
end

bot.get_velocity = function(self, idx)
	local x,y,z = entity_get_prop(idx, 'm_vecVelocity')
	return math_sqrt(x*x + y*y + z*z)
end

bot.positions = {}
bot.leader_last_shot = 0
bot.leader_shot_player = false
bot.leader_shot_move = false

bot.leader_shoot = function(self, e)
    local me = entity_get_local_player()
    if me == nil then
        return
    end

    self.leader_shot_player = false

    local leader = bot.leader
    local shooter_id = e.userid

    local shooter = client_userid_to_entindex(shooter_id)

    -- Distance calculations can sometimes bug when the entity is dormant hence the 2nd check.
    if shooter == leader then

        local players = entity_get_players(true)
        for i=1, #players do
            if self.leader_shot_player then
                goto skip
            end

            local idx = players[i]

           -- if idx == me then
           --     goto skip
           -- end

            local lx, ly, lz = entity_hitbox_position(idx, "head_0")
            local ox, oy, oz = entity_get_prop(shooter, "m_vecOrigin")
        
            local dist = ((e.y - oy)*lx - (e.x - ox)*ly + e.x*oy - e.y*ox) / math.sqrt((e.y-oy)^2 + (e.x - ox)^2)
            if math.abs(dist) < 60 then
                print("shot at player")
                self.leader_shot_player = true
            end

            ::skip::
        end

        if not self.leader_shot_player then

            self.positions.x = e.x
            self.positions.y = e.y
            self.positions.z = e.z
            self.leader_shot_move = true

        end

        --local dist = ((e.y - ey)*lx - (e.x - ex)*ly + e.x*ey - e.y*ex) / math.sqrt((e.y-ey)^2 + (e.x - ex)^2)
        -- 32 is our miss detection radius and the 2nd check is to avoid adding more than 1 miss for a singular bullet (bullet_impact gets called mulitple times per shot).
        --print(dist)
    end


end

local angle_to_target = 0

local has_reached_pos = false
local delay = 0


bot.handle_move = function(self, cmd)
    local me = entity_get_local_player()
    local leader = bot.leader

    if leader == nil or entity_is_alive(leader) == false or me == nil then
        return
    end

    local leader_pos             = self:get_leader_pos(leader)
    local lx, ly, lz             = entity_get_prop(me, "m_vecOrigin")

	local x,y,z                  = entity_get_prop(leader, 'm_vecVelocity')

    local localorigin            = vector(entity_get_origin(me))
    local origin                 = vector(entity_get_origin(leader))
    local movement_speed         = 250


    local shot_pos = self.positions
    
    --print("xd")
    if helpers:distance2D(lx, ly, leader_pos[1], leader_pos[2]) > 0 or self.leader_shot_move then
        local angle = helpers:calcangle(lx, ly, lz, leader_pos[1], leader_pos[2], leader_pos[3]) + 180

        if ( tostring(angle) == "nan" ) then
        else
            if angles == true then

                if self.leader_shot_move then
                    if helpers:distance2D(lx, ly, self.positions.x, self.positions.y) > 2 and not has_reached_pos then
                        print(helpers:distance2D(lx, ly, self.positions.x, self.positions.y))
                        local shot_vec = vector(self.positions.x, self.positions.y, self.positions.z)

                        local eyepos                 = vector(client.eye_position())
                        local target                 = shot_vec + vector(0, 0, 40)
                        pitch, yaw                   = eyepos:to(target):angles() 

                        angle_to_target = (shot_vec - localorigin):angles()

                        cmd.move_yaw = yaw

                        cmd.forwardmove = math.cos(math.rad((client.camera_angles() - angle_to_target))) * movement_speed
                        cmd.sidemove = math.sin(math.rad((client.camera_angles() - angle_to_target))) * movement_speed
                        delay = globals.curtime() + 0.1
                    else
                        has_reached_pos = true

                        if delay < globals.curtime() and delay ~= 0 then
                            delay = 0
                            has_reached_pos = false
                            self.leader_shot_move = false
                        end
                    end


                else
                    local eyepos                 = vector(client.eye_position())
                    --local target                 = origin + vector(0, 0, 40)
                    local target                 = origin

                    pitch, yaw                   = eyepos:to(target):angles() 

                    angle_to_target = (origin - localorigin):angles()
                    
                    cmd.move_yaw = yaw

                    cmd.forwardmove = math.cos(math.rad((client.camera_angles() - angle_to_target))) * movement_speed
                    cmd.sidemove = math.sin(math.rad((client.camera_angles() - angle_to_target))) * movement_speed

                    self:is_leader_scoped(cmd, leader, me)
                    self:is_leader_jumping(cmd, leader)
                    self:is_leader_ducking(cmd, leader)
                
                end
                --cmd.move_yaw = yaw
                --cmd.forwardmove = math.cos(math.rad((client.camera_angles() - angle_to_target))) * movement_speed
               -- cmd.sidemove = math.sin(math.rad((client.camera_angles() - angle_to_target))) * movement_speed
    
            end
            
        end
    else
        angles = true
        
    end
    
end

bot.main = function(self, cmd)

    self:handle_move(cmd)
    self:draw_indicator()
end

bot.draw_indicator = function(self)
    if bot.leader_idx ~= nil then
        renderer.indicator(255, 255, 255, 255, "L: " .. entity.get_player_name(bot.leader_idx))
    end
end

bot.clear_data = function(self)
    spots = {}
end

client.set_event_callback("bullet_impact", function(e)

    bot:leader_shoot(e)

end)

client.set_event_callback("round_prestart", function(e)

    has_reached_pos = false
    bot.leader_shot_move = false
    bot.positions.x = 0
    bot.positions.y = 0
    bot.positions.z = 0
    bot.leader_shot_move = false


end)

client.set_event_callback("setup_command", function(cmd)

    bot:main(cmd)

end)

