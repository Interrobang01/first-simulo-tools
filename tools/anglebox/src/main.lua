local mode_enum = {
    inactive = 0,
    first_click_down = 1,
    first_click_up = 2,
    second_click_down = 3,
}

local point_1 = nil
local point_2 = nil
local point_3 = nil
local point_4 = nil
local mode = mode_enum.inactive
local guids = {
    point_1_marker_guid = nil,
    point_2_marker_guid = nil,
    point_4_ghost_1_guid = nil,
    point_4_ghost_2_guid = nil,
    ghost_guid = nil,
}
local input = {}

local function reset_variables()
    guids = {}
    point_1 = nil
    point_2 = nil
    point_3 = nil
    point_4 = nil
    mode = mode_enum.inactive
end


local function points_to_standard_form(p1,p2)
    local a = p2.y-p1.y
    local b = p1.x-p2.x
    local c = p1.y*(p2.x-p1.x)-(p2.y-p1.y)*p1.x
    return {a=a,b=b,c=c}
end

local function distance_from_line_to_point(a,b,c,p)
    return math.abs(a*p.x+b*p.y+c)/math.sqrt(a^2+b^2)
end

local function closest_point_on_line_to_point(a,b,c,p)
    local denominator = a^2+b^2
    local x = (b*(b*p.x-a*p.y)-a*c)/denominator
    local y = (a*(-b*p.x+a*p.y)-b*c)/denominator
    return vec2(x,y)
end

local function midpoint(p1,p2)
    return (p1+p2)/2
end

local function tripoint_box(line_start,line_end,p3,point_4,mirror_mode)
    -- https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
    local line = points_to_standard_form(line_start,line_end)
    local sy = distance_from_line_to_point(line.a,line.b,line.c,p3)
    local altitude_intersection = closest_point_on_line_to_point(line.a,line.b,line.c,p3)
    local edge_midpoint = midpoint(line_start,line_end)
    local altitude_midpoint = midpoint(altitude_intersection,p3)
    local pos = altitude_midpoint + (edge_midpoint-altitude_intersection)
    if mirror_mode then pos = edge_midpoint sy = sy * 2 end
    local sx = (line_start-line_end):magnitude()
    local relative_line_end = line_end-line_start
    local rotation = math.atan(relative_line_end.y/relative_line_end.x)
    return {pos=pos,sx=sx,sy=sy,rotation=rotation,point_1=line_start,point_2=line_end,point_3=p3,point_4=point_4}
end

local function line(line_start,line_end,thickness,point_4)
    local pos = midpoint(line_start,line_end)
    local sx = (line_start-line_end):magnitude()
    local relative_line_end = line_end-pos
    local rotation = math.atan(relative_line_end.y/relative_line_end.x)
    return {pos=pos,sx=sx,sy=thickness,rotation=rotation,point_1=line_start,point_2=line_end,point_4=point_4}
end

local clear_ghosts = [[
local guids = {
        input.point_1_marker_guid,
        input.point_2_marker_guid,
        input.point_3_marker_guid,
        input.point_4_ghost_1_guid,
        input.point_4_ghost_2_guid,
        input.ghost_guid,
}

for i = 1,#guids do
    if guids[i] ~= nil then
        local obj = Scene:get_object_by_guid(guids[i])
        if obj ~= nil then
            obj:destroy()
        end
    end
end
]]

local endcaps_function = [[
local function endcapify(type)
    local function make_endcap(endcap_pos,shape,endcap_sy,endcap_rotation)
        local color = 0x695662
        if type == "Real" then
            color = 0xe5d3b9
        end
        if shape == "Circle" then
            return Scene:add_circle{
                name = "endcap",
                position = endcap_pos,
                radius = endcap_sy/2,
                is_static = true,
                color = color,
            }
        end
        if shape == "Square" then
            local box = Scene:add_box{
                name = "endcap",
                position = endcap_pos,
                size = vec2(endcap_sy/math.sqrt(2),endcap_sy/math.sqrt(2)),
                is_static = true,
                color = color,
            }
            box:set_angle(endcap_rotation+math.pi/4)
            if type == "Ghost" then
                box:temp_set_collides(false)
            end
            return box
        end
    end
    local relative_point_4 = input.point_4 - input.point_3
    local shape = nil
    if relative_point_4.x+relative_point_4.y > 0.5 then
        shape = "Square"
    end
    if relative_point_4.x+relative_point_4.y < -0.5 then
        shape = "Circle"
    end
    if shape ~= nil then
        return {
            make_endcap(input.pos+(-input.point_1+input.point_2)/2,shape,input.sy,input.rotation),
            make_endcap(input.pos+(input.point_1-input.point_2)/2,shape,input.sy,input.rotation),
        }
    end
end
]]

local prev_pointer_pos = vec2(0, 0)

function on_update()
    if Input:pointer_just_pressed() then
        on_pointer_down(Input:pointer_pos())
    end
    if Input:pointer_just_released() then
        on_pointer_up(Input:pointer_pos())
    end
    if Input:pointer_pos() ~= prev_pointer_pos then
        on_pointer_move(Input:pointer_pos())
    end
    if Input:key_just_pressed("Escape") then
        local output = runtime_eval{
            input = guids,
            code = clear_ghosts,
        }
        reset_variables()
    end
    prev_pointer_pos = Input:pointer_pos()
end

function on_pointer_down(point)
    print("down! mode is "..tostring(mode))
    if mode == mode_enum.inactive then
        mode = mode_enum.first_click_down
        point_1 = Input:snap_if_preferred(point)
    end
    if mode == mode_enum.first_click_down then
        print("AAAAAAAA")
    end
    if mode == mode_enum.first_click_up then
        mode = mode_enum.second_click_down
        point_3 = Input:snap_if_preferred(point)
    end
    if mode == mode_enum.second_click_down then
        print("EEEEEEEEE")
    end
end

function on_pointer_move(point)
    print("move! mode is "..tostring(mode))
    if mode ~= mode_enum.inactive then
        if mode == mode_enum.first_click_down then
            point_2 = Input:snap_if_preferred(point)
        elseif mode == mode_enum.first_click_up then
            point_3 = Input:snap_if_preferred(point)
        elseif mode == mode_enum.second_click_down then
            point_4 = Input:snap_if_preferred(point)
        end
        input = {}
        local faux_point_1 = point_1
        local faux_point_2 = point_2
        local faux_point_3 = point_3
        local mirror_mode = false
        if Input:key_pressed("AltLeft") then
            if mode == mode_enum.first_click_down then
                faux_point_1 = faux_point_1 - (faux_point_2 - faux_point_1)
            end
            mirror_mode = true
        end
        if point_3 == nil then
            input = line(faux_point_1,faux_point_2,0.1,point_4)
        else
            input = tripoint_box(faux_point_1,faux_point_2,faux_point_3,point_4,mirror_mode)
        end
        for i,v in pairs(guids) do
            input[i] = v
        end
        local output = runtime_eval{
            input = input,
            code = clear_ghosts..endcaps_function..[[


                local function make_marker(marker_pos)
                    print(tostring(marker_pos))
                    local box = Scene:add_box{
                        name = "marker",
                        position = marker_pos,
                        size = vec2(0.1,0.1),
                        is_static = true,
                        color = 0,
                    }
                    box:temp_set_collides(false)
                    return box
                end
                local return_guids = {}
                if input.point_1 ~= nil then
                    return_guids["point_1_marker_guid"] = make_marker(input.point_1).guid
                end
                if input.point_2 ~= nil then
                    return_guids["point_2_marker_guid"] = make_marker(input.point_2).guid
                end

                if input.point_4 ~= nil then
                    local endcaps = endcapify("Ghost")
                    if endcaps ~= nil then
                        return_guids["point_4_ghost_1_guid"] = endcaps[1].guid
                        return_guids["point_4_ghost_2_guid"] = endcaps[2].guid
                    end
                end

                local sx = input.sx
                local sy = input.sy
                if sx > 0 and sy > 0 then
                    local pos = input.pos
                    local rotation = input.rotation
                    local line = Scene:add_box{
                        position = pos,
                        size = vec2(sx, input.sy),
                        is_static = true,
                        color = 0x695662,
                    }
                    line:set_angle(rotation)
                    line:temp_set_collides(false)
                    return_guids["ghost_guid"] = line.guid
                end
                return {
                    return_guids = return_guids,
                }
            ]]
        }
        if output ~= nil then
            guids = output.return_guids
        end
    end
end

function on_pointer_up(point)
    print("up! mode is "..tostring(mode))
    if mode == mode_enum.inactive then
        print("what how")
    end
    if mode == mode_enum.first_click_down then

        point_2 = Input:snap_if_preferred(point)
        if Input:key_pressed("AltLeft") then
            point_1 = point_1 - (point_2 - point_1)
        end
        mode = mode_enum.first_click_up
    end
    if mode == mode_enum.first_click_up then
        print("impossible???")
    end
    if mode == mode_enum.second_click_down then
        for i,v in pairs(guids) do
            input[i] = v
        end

        runtime_eval{
            input = input,
            code = clear_ghosts..endcaps_function..[[

                local sx = input.sx
                if sx > 0 then
                    local pos = input.pos
                    local rotation = input.rotation
                    local line = Scene:add_box{
                        position = pos,
                        size = vec2(sx, input.sy),
                        is_static = true,
                        color = 0xe5d3b9,
                    }
                    line:set_angle(rotation)
                end
                local endcaps = endcapify("Real")
                
                
            ]]
        }

        reset_variables()
    end
end