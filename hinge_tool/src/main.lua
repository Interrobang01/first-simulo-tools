local start = vec2(0,0)
local target_1_position = vec2(0, 0)
local target_1_color = nil
local prev_shape_guid = nil
local target_1_guid = nil

local prev_pointer_pos = vec2(0, 0);

function on_update()
    if Input:pointer_just_pressed() then
        on_pointer_down(Input:pointer_pos());
    end;
    if Input:pointer_just_released() then
        on_pointer_up(Input:pointer_pos());
    end;
    if Input:pointer_pos() ~= prev_pointer_pos then
        on_pointer_move(Input:pointer_pos());
    end;
    prev_pointer_pos = Input:pointer_pos();
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
            local target_1 = selected_objects[1]
            local target_1_color = target_1.color
            target_1.color = (0xffffff - target_1.color) -- temporary color reassignment algorithm. change later

            return {
                target_1_position = target_1:get_position(),
                target_1_color = target_1_color,
                target_1_guid = target_1.guid
            }
        ]]
    }

    if output ~= nil then
        target_1_position = output.target_1_position
        target_1_color = output.target_1_color
        target_1_guid = output.target_1_guid
    end
end

function on_pointer_move(point)
    print("Pointer move at " .. point.x .. ", " .. point.y)
    if start_marker_guid ~= nil then
        print('start marker wasnt nil, realing up')
        local output = runtime_eval{
            input = {
                start_point = start,
                end_point = point,
                guid = target_1_guid,
                prev_shape_guid = prev_shape_guid,
            },
            code = [[
                if input.prev_shape_guid ~= nil then
                    Scene:get_object_by_guid(input.prev_shape_guid):destroy()
                end

                local line_pos = (input.start_point+input.end_point)/2
                local line_sx = (input.start_point-input.end_point):magnitude()
                local relative_line_end = input.end_point-line_pos
                local line_rotation = math.atan(relative_line_end.y/relative_line_end.x)
                local line = Scene:add_box({
                    position = line_pos,
                    size = vec2(line_sx/2, 0.25),
                    is_static = true,
                    color = 0x695662
                });
                line:set_angle(line_rotation)

                return {
                    guid = line.guid
                }
            ]]
        }
        if output ~= nil then
            prev_shape_guid = output.guid
        end
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
                prev_shape_guid = prev_shape_guid,
                target_1_color = target_1_color,
                target_1_position = target_1_position,
            },
            code = [[
                if input.prev_shape_guid ~= nil then
                    print('about to destroy prev_shape_guid ' .. tostring(input.prev_shape_guid))
                    Scene:get_object_by_guid(input.prev_shape_guid):destroy()
                end

                local selected_objects = Scene:overlap_circle{
                    position = input.end_point,
                    radius = 0,
                }

                local target_1 = Scene:get_object_by_guid(input.target_1_guid)

                target_1.color = input.target_1_color

                if #selected_objects == 0 then return end

                target_1:set_position(input.end_point + (input.target_1_position-input.start_point))
                target_1:set_linear_velocity(input.end_point-input.start_point) -- crude way to unsleep objects

                local target_2 = selected_objects[1]
                if target_2 == target_1 then
                    if #selected_objects == 1 then
                        target_2 = Scene:add_circle{
                            position = input.end_point,
                            radius = 0.01,
                            is_static = true,
                            color = Scene.background_color,
                        }
                        target_2:temp_set_collides(false)
                    else
                        target_2 = selected_objects[2]
                    end
                end



                local hinge = Scene:add_hinge_at_world_point{
                    point = input.end_point,
                    object_a = target_1,
                    object_b = target_2,
                    motor_enabled = false,
                    motor_speed = 1, -- radians per second
                    max_motor_torque = 10, -- maximum torque for the motor, in newton-meters
                }
                ]]
        }
    end
    prev_shape_guid = nil
    start_marker_guid = nil
    end_marker_guid = nil
    target_1_guid = nil
end