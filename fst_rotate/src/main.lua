local start = vec2(0, 0)
local selected_object_guid = nil
local start_object_position = nil
local start_object_rotation = nil
local start_object_static_state = nil
local start_angle = nil
local rotation_delta = 0

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
    print("Pointer down at " .. point.x .. ", " .. point.y)
    start = Input:snap_if_preferred(point)
    local output = runtime_eval{
        input = {
            point = point,
        },
        code = [[
            local selected_objects = Scene:get_objects_in_circle{
                position = input.point,
                radius = 0,
            }
            if #selected_objects == 0 then return end
            selected_object = selected_objects[1]
            local was_static = selected_object:temp_get_is_static()
            selected_object:temp_set_is_static(true)
            return {
                selected_object_guid = selected_object.guid,
                start_object_position = selected_object:get_position(),
                start_object_rotation = selected_object:get_angle(),
                start_object_static_state = was_static,
            }
        ]]
    }

    if output ~= nil then
        selected_object_guid = output.selected_object_guid
        start_object_position = output.start_object_position
        start_object_rotation = output.start_object_rotation
        start_object_static_state = output.start_object_static_state
        start_angle = -math.atan2(point.y - start_object_position.y,point.x - start_object_position.x)+start_object_rotation
    end
end

function on_pointer_move(point)
    if selected_object_guid ~= nil then
        local snap = Input:key_pressed("ControlLeft") or Input:key_pressed("ControlRight")
        local relative = Input:key_pressed("ShiftLeft") or Input:key_pressed("ShiftRight")
        local pivot_on_start_point = Input:key_pressed("AltLeft") or Input:key_pressed("AltRight")

        if start_object_position == nil then start_object_position = point end

        local pivot_point = nil
        if pivot_on_start_point then
            pivot_point = start
        else
            pivot_point = start_object_position
        end

        rotation_delta = math.atan2(point.y - pivot_point.y,point.x - pivot_point.x)

        local rotation = start_angle + rotation_delta
        if relative then
            rotation = rotation_delta
        end

        if snap then
            rotation = rotation/(2*math.pi)*16
            rotation = rotation+0.5
            rotation = math.floor(rotation)
            rotation = rotation*(2*math.pi)/16
        end

        local position = nil

        if pivot_on_start_point then
            local temp_pos = start_object_position-start
            local temp_pos_magnitude = temp_pos:magnitude()
            local pivot_angle = rotation-start_angle
            position = vec2(math.cos(pivot_angle),math.sin(pivot_angle))*temp_pos_magnitude + start
        end

        runtime_eval{
            input = {
                guid = selected_object_guid,
                rotation = rotation,
                position = position,
            },
            code = [[
                local obj = Scene:get_object_by_guid(input.guid)



                obj:set_angle(input.rotation)
                if input.position ~= nil then
                    obj:set_position(input.position)
                end
            ]]
        }
    end
end

function on_pointer_up(point)
    if selected_object_guid ~= nil then
        if start_object_position == nil then start_object_position = point end
        runtime_eval{
            input = {
                point = point,
                prev_point = prev_point,
                guid = selected_object_guid,
                was_static = start_object_static_state,
            },
            code = [[
                local obj = Scene:get_object_by_guid(input.guid)
                obj:temp_set_is_static(input.was_static)
            ]]
        }
    end
    start = vec2(0, 0)
    selected_object_guid = nil
    start_object_position = nil
    start_object_rotation = nil
    start_object_static_state = nil
end