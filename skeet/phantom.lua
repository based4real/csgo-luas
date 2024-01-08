local menu = {
	top_message = ui.new_label("LUA", "A", "--------- Phantom Yaw ---------"),
	main_aa = ui.new_checkbox("LUA", "A", "Enable Anti-Aim"),
	antiaim_yaw = ui.new_combobox("LUA", "A", "Anti-Aim Yaw", "Dangerous", "Hybrid"),
	antiaim_options = ui.new_combobox("LUA", "A", "Anti-Aim based of", "Enemy Lethal"),
    antiaim_shot = ui.new_checkbox("LUA", "A", "Center jitter on-shot"),
}

local brute = {
    yaw_status = "default",
    indexed_angle = 0,
    last_miss = 0,
    best_angle = 0,
    misses = { }, --this is either nil, 1 or 2
    hit_reverse = { }
}

local shot = {
    did_shoot = false,
    delay = 0,
}

local best_enemy = nil

local aa_main = ui.reference("AA", "Anti-aimbot angles", "Enabled")
local aa_yaw, aa_yaw_offset = ui.reference("AA", "Anti-aimbot angles", "Yaw")
local aa_yaw_jitter, aa_yaw_jitter_offset = ui.reference("AA", "Anti-aimbot angles", "Yaw jitter")
local aa_yaw_base = ui.reference("AA", "Anti-aimbot angles", "Yaw base")
local aa_body_yaw, aa_body_yaw_offset = ui.reference("AA", "Anti-aimbot angles", "Body yaw")
local aa_freestand_body = ui.reference("AA", "Anti-aimbot angles", "Freestanding body yaw")
local aa_fake_yaw_limit = ui.reference("AA", "Anti-aimbot angles", "fake yaw limit")


local function extrapolate_position(xpos,ypos,zpos,ticks,ent)
	x,y,z = entity.get_prop(ent, "m_vecVelocity")
	for i=0, ticks do
		xpos =  xpos + (x*globals.tickinterval())
		ypos =  ypos + (y*globals.tickinterval())
		zpos =  zpos + (z*globals.tickinterval())
	end
	return xpos,ypos,zpos
end

local function normalize_yaw(yaw)
	while yaw > 180 do yaw = yaw - 360 end
	while yaw < -180 do yaw = yaw + 360 end
	return yaw
end

local function ang_on_screen(x, y)
    if x == 0 and y == 0 then return 0 end

    return math.deg(math.atan2(y, x))
end

local function Angle_Vector(angle_x, angle_y)
    local sp, sy, cp, cy = nil
    sy = math.sin(math.rad(angle_y));
    cy = math.cos(math.rad(angle_y));
    sp = math.sin(math.rad(angle_x));
    cp = math.cos(math.rad(angle_x));
    return cp * cy, cp * sy, -sp;
end

local function get_velocity(player)
    local x,y,z = entity.get_prop(player, "m_vecVelocity")
    if x == nil then return end
    return math.sqrt(x*x + y*y + z*z)
end

local vec_3 = function(_x, _y, _z) 
	return { x = _x or 0, y = _y or 0, z = _z or 0 } 
end

local function CalcAngle(localplayerxpos, localplayerypos, enemyxpos, enemyypos)
   local relativeyaw = math.atan( (localplayerypos - enemyypos) / (localplayerxpos - enemyxpos) )
    return relativeyaw * 180 / math.pi
end

local function get_best_enemy()
    -- We store the best target in a global variable so we don't have to re run the calculations every time we want to find the best target.
    best_enemy = nil

    local enemies = entity.get_players(true)
    local best_fov = 180

    local lx, ly, lz = client.eye_position()
    local view_x, view_y, roll = client.camera_angles()
    
    for i=1, #enemies do
        local cur_x, cur_y, cur_z = entity.get_prop(enemies[i], "m_vecOrigin")
        local cur_fov = math.abs(normalize_yaw(ang_on_screen(lx - cur_x, ly - cur_y) - view_y + 180))
        if cur_fov < best_fov then
			best_fov = cur_fov
			best_enemy = enemies[i]
		end
    end
end



brute.impact = function(e)
    if not ui.get(menu.main_aa) then return end

    local me = entity.get_local_player()

    -- Since bullet_impact gets triggered even while we're dead having this check is a good idea.
    if not entity.is_alive(me) then return end

    local shooter_id = e.userid
    local shooter = client.userid_to_entindex(shooter_id)

    -- Distance calculations can sometimes bug when the entity is dormant hence the 2nd check.
    if not entity.is_enemy(shooter) or entity.is_dormant(shooter) then return end

    local lx, ly, lz = entity.hitbox_position(me, "head_0")
    
	local ox, oy, oz = entity.get_prop(me, "m_vecOrigin")
    local ex, ey, ez = entity.get_prop(shooter, "m_vecOrigin")

    local dist = ((e.y - ey)*lx - (e.x - ex)*ly + e.x*ey - e.y*ex) / math.sqrt((e.y-ey)^2 + (e.x - ex)^2)
    
    -- 32 is our miss detection radius and the 2nd check is to avoid adding more than 1 miss for a singular bullet (bullet_impact gets called mulitple times per shot).
    if math.abs(dist) <= 32 and globals.curtime() - brute.last_miss > 0.015 then
        brute.last_miss = globals.curtime()
        if brute.misses[shooter] == nil then
            brute.misses[shooter] = 1 
        elseif brute.misses[shooter] >= 2 then
            brute.misses[shooter] = nil
        else
            brute.misses[shooter] = brute.misses[shooter] + 1
        end
    end
end


brute.death = function(e)
    if not ui.get(menu.main_aa) then return end
    
    local victim_id = e.userid
    local victim = client.userid_to_entindex(victim_id)

    if victim ~= entity.get_local_player() then return end

    local attacker_id = e.attacker
    local attacker = client.userid_to_entindex(attacker_id)

    if not entity.is_enemy(attacker) then return end

    if not e.headshot then return end

    if brute.misses[attacker] == nil or (globals.curtime() - brute.last_miss < 0.06 and brute.misses[attacker] == 1) then
        if brute.hit_reverse[attacker] == nil then
            brute.hit_reverse[attacker] = true
        else
            brute.hit_reverse[attacker] = nil
        end
    end
end

-- ALL DYNAMIC AA FUNCTIONS
-- normal Freestanding
local function DoFreestanding(enemy, ...)
    local lx, ly, lz = entity.get_prop(entity.get_local_player(), "m_vecOrigin")
    local viewangle_x, viewangle_y, roll = client.camera_angles()
    local headx, heady, headz = entity.hitbox_position(entity.get_local_player(), 0)
    local enemyx, enemyy, enemyz = entity.get_prop(enemy, "m_vecOrigin")
    local bestangle = nil
    local lowest_dmg = math.huge

    if(entity.is_alive(enemy)) then
        local yaw = CalcAngle(lx, ly, enemyx, enemyy)
        for i,v in pairs({...}) do
            local dir_x, dir_y, dir_z = Angle_Vector(0, (yaw + v))
            local end_x = lx + dir_x * 55
            local end_y = ly + dir_y * 55
            local end_z = lz + 80           
            
            local index, damage = client.trace_bullet(enemy, enemyx, enemyy, enemyz + 70, end_x, end_y, end_z,true)
            local index2, damage2 = client.trace_bullet(enemy, enemyx, enemyy, enemyz + 70, end_x + 12, end_y, end_z,true) --test
            local index3, damage3 = client.trace_bullet(enemy, enemyx, enemyy, enemyz + 70, end_x - 12, end_y, end_z,true) --test

            if(damage < lowest_dmg) then
                lowest_dmg = damage
                if(damage2 > damage) then
                    lowest_dmg = damage2
                end
                if(damage3 > damage) then
                    lowest_dmg = damage3
                end 
                if(lx - enemyx > 0) then
                    bestangle = v
                else
                    bestangle = v * -1
                end
            elseif(damage == lowest_dmg) then
                    return 0
            end
        end
    end
    return bestangle
end
-- secondary Freestanding (to make it kick in more, used when the normal function finds no angle)
local function DoEarlyFreestanding(enemy, ...)
    --if stored_freestand == 90 or stored_freestand == -90 then return end
    -- CHINA ALERT
    local lx, ly, lz = entity.get_prop(enemy, "m_vecOrigin") -- to
    local viewangle_x, viewangle_y, roll = client.camera_angles()
    local localplayer = entity.get_local_player()
    local headx, heady, headz = entity.hitbox_position(localplayer, 0)
    local enemyx, enemyy, enemyz = entity.get_prop(localplayer, "m_vecOrigin") -- from
    local bestangle = nil
    local lowest_dmg = math.huge
    local last_moved = 0
    local fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z = nil
    -- I DONT EVEN KNOW WHY THIS WORKS
    if(entity.is_alive(enemy)) then
        local yaw = CalcAngle(enemyx, enemyy, lx, ly)
        for i,v in pairs({...}) do
            local dir_x, dir_y, dir_z = Angle_Vector(0, (yaw + v))
            local end_x = lx + dir_x * 55
            local end_y = ly + dir_y * 55
            local end_z = lz + 80
            -- EXTRAPOLATE
            local eyepos_x, eyepos_y, eyepos_z = client.eye_position()
            local local_velocity = get_velocity(entity.get_local_player())
            local can_be_extrapolated = local_velocity > 15
            local ticks_to_extrapolate = 11
            if (local_velocity < 50) then
                ticks_to_extrapolate = 90
            elseif (local_velocity >= 50 and local_velocity < 120) then
                ticks_to_extrapolate = 50
            elseif (local_velocity >= 120 and local_velocity < 190) then
                ticks_to_extrapolate = 40
            elseif (local_velocity >= 190) then
                ticks_to_extrapolate = 20
            end

            if can_be_extrapolated then
                eyepos_x, eyepos_y, eyepos_z = extrapolate_position(eyepos_x, eyepos_y, eyepos_z, ticks_to_extrapolate, entity.get_local_player())
                fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z = eyepos_x, eyepos_y, eyepos_z
                last_moved = globals.curtime() + 1
            else
                if last_moved ~= 0 then
                    if globals.curtime() > last_moved then
                        last_moved = 0
                        fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z = nil
                    else
                        eyepos_x, eyepos_y, eyepos_z = fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z
                    end
                else
                    eyepos_x, eyepos_y, eyepos_z = extrapolate_position(eyepos_x, eyepos_y, eyepos_z, ticks_to_extrapolate, entity.get_local_player())
                end
            end
            
            local index, damage = client.trace_bullet(localplayer, enemyx, enemyy, enemyz + 70, end_x, end_y, end_z,true)
            local index2, damage2 = client.trace_bullet(localplayer, enemyx, enemyy, enemyz + 70, end_x + 12, end_y, end_z,true) --test
            local index3, damage3 = client.trace_bullet(localplayer, enemyx, enemyy, enemyz + 70, end_x - 12, end_y, end_z,true) --test

            if fs_stored_eyepos_x ~= nil then
                index, damage = client.trace_bullet(localplayer, fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z + 70, end_x, end_y, end_z,true)
                index2, damage2 = client.trace_bullet(localplayer, fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z + 70, end_x + 12, end_y, end_z,true) --test
                index3, damage3 = client.trace_bullet(localplayer, fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z + 70, end_x - 12, end_y, end_z,true) --test
            end

            if(damage < lowest_dmg) then
                lowest_dmg = damage
                if(damage2 > damage) then
                    lowest_dmg = damage2
                end
                if(damage3 > damage) then
                    lowest_dmg = damage3
                end 
                if(enemyx - lx > 0) then
                    bestangle = v
                else
                bestangle = v * -1
                end
            elseif(damage == lowest_dmg) then
                return 0
            end
        end
    end
    return bestangle
end

local function enemy_is_peeking_and_can_hit_us(ent)
    if ent == nil then return end
    local origin_x, origin_y, origin_z = entity_get_prop(ent, "m_vecOrigin")
    local vx,vy,vz = entity_get_prop(enemyclosesttocrosshair, "m_vecViewOffset")
    if origin_z == nil then return end
    origin_x,origin_y,origin_z = origin_x+vx,origin_y+vy,origin_z+vz

    --origin_z = origin_z + 64
    local lp = entity_get_local_player()
    
    if (get_velocity(ent) < 20) or in_air(ent) or in_air(entity_get_local_player()) then return false end

    local extrapolated_x, extrapolated_y, extrapolated_z = extrapolate_position(origin_x, origin_y, origin_z, 16, ent)
    --origin_x, origin_y, origin_z
    --
    local hx,hy,hz = entity_hitbox_position(lp, 0)
    local lx,ly,lz = client_eye_position()
    lz = hz
    
    local _, eye_yaw = entity_get_prop(lp, "m_angEyeAngles")
    local desync = normalise_angle(eye_yaw + (get_body_yaw(lp)))
    local real_x = lx + math_cos(math_rad(desync)) * 20
    local real_y = ly + math_sin(math_rad(desync)) * 12
    
    local desynced = normalise_angle(eye_yaw - (get_body_yaw(lp)))
    local fake_x = lx + math_cos(math_rad(desynced)) * 20
    local fake_y = ly + math_sin(math_rad(desynced)) * 12
    --client_trace_bullet(enemyclosesttocrosshair, ex, ey, ez, lx_left, ly_left, lz,true)
    local head_idx, head_dmg = client_trace_bullet(ent, extrapolated_x, extrapolated_y, extrapolated_z, real_x, real_y, lz,true)
    local fake_idx, fake_dmg = client_trace_bullet(ent, extrapolated_x, extrapolated_y, extrapolated_z, fake_x, fake_y, lz,true)

    local predicted_damage = 0
    local desynced_damage = 0
    local timer = 0

    if head_dmg ~= nil and head_dmg > 0 then
        predicted_damage = head_dmg
    else
        predicted_damage = 0
    end
    
    if fake_dmg ~= nil and fake_dmg > 0 then
        desynced_damage = fake_dmg
    else
        desynced_damage = 0
    end
    
    if flip_angle then return false end
    --if predicted_damage == desynced_damage then return false end
    if predicted_damage <= desynced_damage then return false end

    --client.log("real: ", predicted_damage, " fake: ", desynced_damage, " comb: ",comb)
    return predicted_damage ~= nil and predicted_damage > 58
    
end

local function adjust_aa(aa,side)

if side == -90 then
    newSide = "left"
elseif side == 90 then
    newSide = "right"
end

if shot.did_shoot == true then
    if shot.delay + 0.5 > globals.curtime() then
        ui.set(aa_yaw, "180")
        ui.set(aa_yaw_offset, 9)
        ui.set(aa_yaw_jitter, "Off")
        ui.set(aa_body_yaw, "Jitter")
        ui.set(aa_body_yaw_offset, 21)
        ui.set(aa_fake_yaw_limit, 59)       
        --apply center jitter end
    else
        shot.did_shoot = false
    end
end


if shot.did_shoot == true then return end
if aa == 1 then
    if newSide == "left" then
        ui.set(aa_yaw, "180")
        ui.set(aa_yaw_offset, 12)
        ui.set(aa_yaw_jitter, "Center")
        ui.set(aa_yaw_jitter_offset, 9)
        ui.set(aa_body_yaw, "Jitter")
        ui.set(aa_body_yaw_offset, -36)
        ui.set(aa_fake_yaw_limit, 37)
    elseif newSide == "right" then
        ui.set(aa_yaw, "180")
        ui.set(aa_yaw_offset, 10)
        ui.set(aa_yaw_jitter, "Center")
        ui.set(aa_yaw_jitter_offset, 3)
        ui.set(aa_body_yaw, "Jitter")
        ui.set(aa_body_yaw_offset, 41)
        ui.set(aa_fake_yaw_limit, 37)
    end
end

if aa == 2 then
    if newSide == "left" then
        ui.set(aa_yaw, "180")
        ui.set(aa_yaw_offset, -10)
        ui.set(aa_yaw_jitter, "Offset")
        ui.set(aa_yaw_jitter_offset, 9)
        ui.set(aa_body_yaw, "Static")
        ui.set(aa_body_yaw_offset, -48)
        ui.set(aa_fake_yaw_limit, 37)
    elseif newSide == "right" then
        ui.set(aa_yaw, "180")
        ui.set(aa_yaw_offset, 23)
        ui.set(aa_yaw_jitter, "Offset")
        ui.set(aa_yaw_jitter_offset, -9)
        ui.set(aa_body_yaw, "Static")
        ui.set(aa_body_yaw_offset, 26)
        ui.set(aa_fake_yaw_limit, 37)
    end
end


if aa == 3 then
    if newSide == "left" then
        ui.set(aa_yaw, "180")
        ui.set(aa_yaw_offset, 7)
        ui.set(aa_yaw_jitter, "Center")
        ui.set(aa_yaw_jitter_offset, 9)
        ui.set(aa_body_yaw, "Static")
        ui.set(aa_body_yaw_offset, 21)
        ui.set(aa_fake_yaw_limit, 37)
    elseif newSide == "right" then
        ui.set(aa_yaw, "180")
        ui.set(aa_yaw_offset, 0)
        ui.set(aa_yaw_jitter, "Center")
        ui.set(aa_yaw_jitter_offset, 5)
        ui.set(aa_body_yaw, "Static")
        ui.set(aa_body_yaw_offset, -37)
        ui.set(aa_fake_yaw_limit, 34)
    end
end

if aa == 4 then
	if newSide == "left" then
        ui.set(aa_yaw, "180")
        ui.set(aa_yaw_offset, 9)
        ui.set(aa_yaw_jitter, "Off")
        ui.set(aa_body_yaw, "Static")
        ui.set(aa_body_yaw_offset, -66)
        ui.set(aa_fake_yaw_limit, 37)	
	elseif newSide == "right" then
		ui.set(aa_yaw, "180")
        ui.set(aa_yaw_offset, -3)
        ui.set(aa_yaw_jitter, "Off")
        ui.set(aa_body_yaw, "Static")
        ui.set(aa_body_yaw_offset, 19)
        ui.set(aa_fake_yaw_limit, 34)	
	end
end

if aa == 5 then
	if newSide == "left" then
		ui.set(aa_yaw, "180")
        ui.set(aa_yaw_offset, -3)
        ui.set(aa_yaw_jitter, "Off")
        ui.set(aa_body_yaw, "Static")
        ui.set(aa_body_yaw_offset, 19)
        ui.set(aa_fake_yaw_limit, 34)
    elseif newSide == "right" then
        ui.set(aa_yaw, "180")
        ui.set(aa_yaw_offset, 9)
        ui.set(aa_yaw_jitter, "Off")
        ui.set(aa_body_yaw, "Static")
        ui.set(aa_body_yaw_offset, -66)
        ui.set(aa_fake_yaw_limit, 37)
	end
end

if aa == 6 then
    ui.set(aa_yaw, "180")
    ui.set(aa_yaw_offset, 3)
    ui.set(aa_yaw_jitter, "Center")
    ui.set(aa_yaw_jitter_offset, 9)
    ui.set(aa_body_yaw, "Jitter")
    ui.set(aa_body_yaw_offset, 41)
    ui.set(aa_fake_yaw_limit, 34)
end
end


local safe_aa = false

local function handle_antiaim()

	local me = entity.get_local_player()

    if me == nil then return end

    if best_enemy == nil or not entity.is_alive(best_enemy) then adjust_aa(6, 0) return end

	local local_pos = vec_3(entity.hitbox_position(me, 0))

    local extrapolated_pos = vec_3(extrapolate_position(local_pos.x, local_pos.y, local_pos.z, 24, me))

    local enemy_pos = vec_3(entity.hitbox_position(best_enemy, 2))

    local hit_ent, hit_dmg = client.trace_bullet(me, extrapolated_pos.x, extrapolated_pos.y, extrapolated_pos.z, enemy_pos.x, enemy_pos.y, enemy_pos.z)

    local players = entity.get_players(true)

    -- CHEEKY FREE#STANDING
    if(best_enemy ~= nil and #players ~= 0) then
        realtime_freestand = DoFreestanding(best_enemy, -90, 90)
        realtime_freestand_v2 = DoEarlyFreestanding(best_enemy, -90, 90)
        
        if realtime_freestand ~= 0 and realtime_freestand ~= nil then
            stored_freestand = realtime_freestand
        end
        
        if realtime_freestand_v2 ~= 0 and realtime_freestand_v2 ~= nil then
            stored_freestand_v2 = realtime_freestand_v2
        end 
        
        if (realtime_freestand ~= 0 and realtime_freestand ~= nil) and realtime_freestand == 90 or realtime_freestand == -90 then
            adaptive_freestand = realtime_freestand
        elseif (realtime_freestand_v2 ~= 0 and realtime_freestand_v2 ~= nil) and realtime_freestand_v2 == 90 or realtime_freestand_v2 == -90 then
            adaptive_freestand = realtime_freestand_v2
        end
        
        local antiaim = ui.get(menu.antiaim_yaw)
        local enemy_hp = entity.get_prop(best_enemy, "m_IHealth")
        local aa_options = ui.get(menu.antiaim_options)

        if antiaim == "Dangerous" and safe_aa == false then
            if adaptive_freestand == -90 then
                if hit_ent == nil then
                    adjust_aa(1, -90)
                else
                    adjust_aa(2, -90)
                end
            end
            if adaptive_freestand == 90 then
                if hit_ent == nil then
                    adjust_aa(1, 90)
                else
                    adjust_aa(2, 90)
                end
            end
        end

        if aa_options == "Enemy Lethal" then
            if enemy_hp < 50 then
                safe_aa = true 
                if adaptive_freestand == -90 then
                    adjust_aa(3, -90)
                end
                if adaptive_freestand == 90 then
                    adjust_aa(3, 90)
                end
            else
            safe_aa = false
            end
        end
		
		if antiaim == "Hybrid" then
			if adaptive_freestand == -90 then
				if hit_ent == nil then
					adjust_aa(5, -90)
				else
					adjust_aa(4, -90)
				end
			end
		if adaptive_freestand == 90 then
			if hit_ent == nil then
				adjust_aa(5, 90)
			else
				adjust_aa(4, 90)
			end
		end
	end
    end
end



local function aim_fire(e)

shot.did_shoot = true
shot.delay = globals.curtime()

end


client.set_event_callback('aim_fire', function(e)

    aim_fire(e)

end)

    client.set_event_callback("bullet_impact", function(e)

        brute.impact(e)

    end)

    client.set_event_callback("player_death", function(e)

        brute.death(e)

    end)


    client.set_event_callback("run_command", function()

        get_best_enemy()
        handle_antiaim()

    end)