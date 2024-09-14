local selected_object_guid = nil
local selected_object_offset = nil
local drag_ghost_guid = nil

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
    prev_pointer_pos = Input:pointer_pos()
end

function on_pointer_down(point)
    local output = runtime_eval{
        input = {
            point = point,
        },
        code = [[
local function get_first_obj(point)
    local overlap_circle = Scene:get_objects_in_circle{
        position = point,
        radius = 0,
    }
    if overlap_circle[1] ~= nil then
        return overlap_circle[1]
    else
        local obj = nil
        local radius = 0.1
        while obj == nil do
            local overlap_circle = Scene:get_objects_in_circle{
                position = point,
                radius = radius,
            }
            obj = overlap_circle[1]
            radius = radius * 1.1
        end
        return obj
    end
end

local obj = get_first_obj(input.point)
return {
    selected_object_guid = obj.guid,
    start_object_offset = obj:get_local_point(input.point),
}
        ]]
    }

    if output ~= nil then
        selected_object_guid = output.selected_object_guid
        selected_object_offset = output.start_object_offset
    end
end

function on_pointer_move(point)
    if selected_object_guid ~= nil then
        local imprecision_mode = Input:key_pressed("ShiftLeft") or Input:key_pressed("ShiftRight")
        local output = runtime_eval{
            input = {
                point = point,
                selected_object_offset = selected_object_offset,
                guid = selected_object_guid,
                imprecision_mode = imprecision_mode,
                drag_ghost_guid = drag_ghost_guid,
            },
            code = [[
local function line(line_start,line_end,thickness,color,static)
    local pos = (line_start+line_end)/2
    local sx = (line_start-line_end):magnitude()
    local relative_line_end = line_end-pos
    local rotation = math.atan(relative_line_end.y/relative_line_end.x)
    local line = Scene:add_box{
        position = pos,
        size = vec2(sx, thickness),
        is_static = static,
        color = color
    }
    line:set_angle(rotation)
    return line
end

                if input.drag_ghost_guid ~= nil then
                    local ghost = Scene:get_object_by_guid(input.drag_ghost_guid)
                    if ghost ~= nil then
                        ghost:destroy()
                    end
                end

                local obj = Scene:get_object_by_guid(input.guid)
                local obj_global_pos = obj:get_world_point(input.selected_object_offset)

                local pointer_diff = input.point - (obj_global_pos)

                local obj_vel = obj:get_linear_velocity()
                local obj_vel_diff = (obj_vel) - pointer_diff

                force = obj_vel_diff*20 * obj:get_mass()
                new_angular_velocity = 0

                if Input:key_pressed("Q") then
                    new_angular_velocity = new_angular_velocity + 2
                end

                if Input:key_pressed("E") then
                    new_angular_velocity = new_angular_velocity - 2
                end

                if input.imprecision_mode then
                    force = pointer_diff*-20 * obj:get_mass()
                    obj:apply_force(-force,input.point)
                    obj:apply_torque(new_angular_velocity * obj:get_mass())
                else
                    obj:apply_force_to_center(-force)
                    obj:set_angular_velocity(new_angular_velocity)
                end




                local ghost_color = 0xf0f0f0
                if input.imprecision_mode then
                    ghost_color = 0xffdfff
                end
                local drag_ghost = line(obj_global_pos,input.point,0.05,ghost_color,true)
                drag_ghost:temp_set_collides(false)
                return{
                    drag_ghost_guid = drag_ghost.guid
                }
            ]]
        }
        if output ~= nil then
            drag_ghost_guid = output.drag_ghost_guid
        end
    end
end

function on_pointer_up(point)
    if selected_object_guid ~= nil then
        if start_object_position == nil then start_object_position = point end
        runtime_eval{
            input = {
                drag_ghost_guid = drag_ghost_guid,
            },
            code = [[
                if input.drag_ghost_guid ~= nil then
                    local ghost = Scene:get_object_by_guid(input.drag_ghost_guid)
                    if ghost ~= nil then
                        ghost:destroy()
                    end
                end
            ]]
        }
    end
    selected_object_guid = nil
    selected_object_offset = nil
    drag_ghost_guid = nil
end