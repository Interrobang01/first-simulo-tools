local start = vec2(0,0)
local target_1_position = vec2(0, 0)
local target_1_color = nil
local target_1_guid = nil

function on_update()
    if Input:pointer_just_pressed() then
        on_pointer_down(Input:pointer_pos());
    end;
    if Input:pointer_just_released() then
        on_pointer_up(Input:pointer_pos());
    end;
end;

function on_pointer_down(point)
    print("Pointer down at " .. point.x .. ", " .. point.y)
    start = point
    local output = runtime_eval{
        input = {
            point = point,
        },
        code = [[
            local selected_objects = Scene:overlap_circle{
                position = input.point,
                radius = 0,
            }
            if #selected_objects == 0 then return end

            local snap = Input:key_pressed("ControlLeft") or Input:key_pressed("ControlRight")
            local start_at_center = Input:key_pressed("AltLeft") or Input:key_pressed("AltRight")

            local target_1 = selected_objects[1]
            local target_1_color = target_1.color
            target_1.color = (0xffffff - target_1.color) -- temporary color reassignment algorithm. change later

            local target_1_position = target_1:get_position()
            local start = input.point
            if start_at_center then start = target_1_position end

            if snap then
                start = start * 2
                start = start+vec2(0.5,0.5)
                start = vec2(math.floor(start.x),math.floor(start.y))
                start = start / 2
            end

            return {
                target_1_position = target_1_position,
                target_1_color = target_1_color,
                target_1_guid = target_1.guid,
                start = start
            }
        ]]
    }

    if output ~= nil then
        target_1_position = output.target_1_position
        target_1_color = output.target_1_color
        target_1_guid = output.target_1_guid
        start = output.start
    end
end

function on_pointer_up(point)
    print("Pointer up!")
    if target_1_guid ~= nil then
        runtime_eval{
            input = {
                start_point = start,
                end_point = point,
                target_1_guid = target_1_guid,
                target_1_color = target_1_color,
                target_1_position = target_1_position,
            },
            code = [[

                local selected_objects = Scene:overlap_circle{
                    position = input.end_point,
                    radius = 0,
                }

                local target_1 = Scene:get_object_by_guid(input.target_1_guid)

                target_1.color = input.target_1_color

                if #selected_objects == 0 then return end

                local snap = Input:key_pressed("ControlLeft") or Input:key_pressed("ControlRight")
                local motor = Input:key_pressed("ShiftLeft") or Input:key_pressed("ShiftRight")
                local end_at_center = Input:key_pressed("AltLeft") or Input:key_pressed("AltRight")

                local adjusted_end_point = input.end_point

                if snap then
                    adjusted_end_point = adjusted_end_point * 2
                    adjusted_end_point = adjusted_end_point+vec2(0.5,0.5)
                    adjusted_end_point = vec2(math.floor(adjusted_end_point.x),math.floor(adjusted_end_point.y))
                    adjusted_end_point = adjusted_end_point / 2
                end

                local target_2 = selected_objects[1]
                if target_2 == target_1 then
                    if #selected_objects == 1 then
                        target_2 = Scene:add_circle{
                            position = adjusted_end_point,
                            radius = 0.01,
                            is_static = true,
                            color = Scene.background_color,
                        }
                        target_2:temp_set_collides(false)
                    else
                        target_2 = selected_objects[2]
                    end
                end

                if end_at_center then adjusted_end_point = target_2:get_position() end

                target_1:set_position(adjusted_end_point + (input.target_1_position-input.start_point))
                target_1:set_linear_velocity((adjusted_end_point-input.start_point)/10) -- crude way to unsleep objects. also, feel.



                local hinge = Scene:add_hinge_at_world_point{
                    point = adjusted_end_point,
                    object_a = target_1,
                    object_b = target_2,
                    motor_enabled = motor,
                    motor_speed = math.pi*2, -- radians per second
                    max_motor_torque = 10000, -- maximum torque for the motor, in newton-meters
                }
                ]]
        }
    end
    target_1_guid = nil
end