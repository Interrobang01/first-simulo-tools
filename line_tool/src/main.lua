local start = vec2(0, 0);
local start_marker_guid = nil;
local end_marker_guid = nil;
local prev_shape_guid = nil;
local adjusted_start = vec2(0, 0);
local adjusted_end = vec2(0, 0);

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
    print("Pointer down at " .. point.x .. ", " .. point.y);
    start = point;
    local output = runtime_eval({
        input = {
            point = point,
        },
        code = [[
            local start_marker = Scene:add_box({
                position = input.point,
                size = vec2(0.1, 0.1),
                is_static = true,
                color = 0xe5d3b9,
            });
            local end_marker = Scene:add_box({
                position = input.point,
                size = vec2(0.1, 0.1),
                is_static = true,
                color = 0xe5d3b9,
            });
            return {
                start_guid = start_marker.guid,
                end_guid = end_marker.guid,
            };
        ]]
    });

    if output ~= nil then
        start_marker_guid = output.start_guid;
        end_marker_guid = output.end_guid;
        print('set guids');
    end;
end;

function on_pointer_move(point)
    if start_marker_guid ~= nil then
        print('start marker wasnt nil, realing up');
        local output = runtime_eval({
            input = {
                start_point = start,
                end_point = point,
                start_marker_guid = start_marker_guid,
                end_marker_guid = end_marker_guid,
                prev_shape_guid = prev_shape_guid,
            },
            code = [[
                local snap = Input:key_pressed("ControlLeft") or Input:key_pressed("ControlRight")
                local square = Input:key_pressed("ShiftLeft") or Input:key_pressed("ShiftRight")
                local centerscale = Input:key_pressed("AltLeft") or Input:key_pressed("AltRight")

                local start_marker = Scene:get_object_by_guid(input.start_marker_guid);
                local end_marker = Scene:get_object_by_guid(input.end_marker_guid);
                local adjusted_start_point = input.start_point
                local adjusted_end_point = input.end_point

                if snap then
                    local function round_vector(vector)
                        return vec2(math.floor(vector.x+0.5),math.floor(vector.y+0.5))
                    end
                    adjusted_start_point = round_vector(adjusted_start_point)
                    adjusted_end_point = round_vector(adjusted_end_point)
                end
                if square then
                    local delta = adjusted_end_point - adjusted_start_point
                    local horiz = math.abs(delta.x) -- y = 0
                    local vert = math.abs(delta.y) -- x = 0
                    local diag = math.abs(delta.x+delta.y)/math.sqrt(2) -- x = y
                    local negdiag = math.abs(delta.x-delta.y)/math.sqrt(2) -- x = -y
                    local max = math.max(horiz, vert, diag, negdiag)
                    if max == horiz then
                        delta = vec2(delta.x,0)
                    elseif max == vert then
                        delta = vec2(0,delta.y)
                    elseif max == diag then
                        delta = vec2((delta.x+delta.y)/2,(delta.x+delta.y)/2)
                    elseif max == negdiag then
                        delta = vec2((delta.x-delta.y)/2,(delta.x-delta.y)/-2)
                    end

                    adjusted_end_point = adjusted_start_point + delta
                end
                if centerscale then
                    adjusted_start_point = adjusted_start_point*2 - adjusted_end_point
                end

                start_marker:set_position(adjusted_start_point);
                end_marker:set_position(adjusted_end_point);

                if input.prev_shape_guid ~= nil then
                    Scene:get_object_by_guid(input.prev_shape_guid):destroy();
                end;

                local sx = (adjusted_start_point-adjusted_end_point):magnitude()
                if sx > 0 then
                    local pos = (adjusted_start_point+adjusted_end_point)/2
                    local relative_line_end = adjusted_end_point-pos
                    local rotation = math.atan(relative_line_end.y/relative_line_end.x)
                    local line = Scene:add_box({
                        position = pos,
                        size = vec2(sx/2, 1/2),
                        is_static = true,
                        color = 0x695662,
                    });
                    line:set_angle(rotation)
                    return {
                        guid = line.guid,
                        adjusted_start = adjusted_start_point,
                        adjusted_end = adjusted_end_point,
                    };
                else
                    return {
                        guid = nil,
                        adjusted_start = adjusted_start_point,
                        adjusted_end = adjusted_end_point,
                    };
                end


            ]]
        });
        if output ~= nil then
            prev_shape_guid = output.guid;
            adjusted_start = output.adjusted_start;
            adjusted_end = output.adjusted_end;
        end;
    end;
end;

function on_pointer_up(point)
    print("Pointer up!");
    runtime_eval({
        input = {
            start_point = adjusted_start,
            end_point = adjusted_end,
            start_guid = start_marker_guid,
            end_guid = end_marker_guid,
            prev_shape_guid = prev_shape_guid,
        },
        code = [[
            print("hi im in remote eval for the Epic Finale!!");

            if input.start_guid ~= nil then
                print('about to destroy start ' .. tostring(input.start_guid));
                print('about to destroy end ' .. tostring(input.end_guid));
                Scene:get_object_by_guid(input.start_guid):destroy();
                Scene:get_object_by_guid(input.end_guid):destroy();
            end;

            if input.prev_shape_guid ~= nil then
                print('about to destroy prev_shape_guid ' .. tostring(input.prev_shape_guid));
                Scene:get_object_by_guid(input.prev_shape_guid):destroy();
            end;

            local sx = (input.start_point-input.end_point):magnitude()

            if sx > 0 then
                local pos = (input.start_point+input.end_point)/2
                local relative_line_end = input.end_point-pos
                local rotation = math.atan(relative_line_end.y/relative_line_end.x)
                print("defined size and pos");

                print("about to add a cuboid, color is " .. 0xe5d3b9 .. " size is " .. tostring(sx) .. " pos is " .. tostring(pos));
                local thickness = 1/2
                local line = Scene:add_box({
                    position = pos,
                    size = vec2(sx/2, thickness),
                    is_static = true,
                    color = 0xe5d3b9,
                });
                line:set_angle(rotation)

                local startcap = Scene:add_box({
                    position = input.start_point,
                    size = vec2(thickness/math.sqrt(2), thickness/math.sqrt(2)),
                    is_static = true,
                    color = 0xe5d3b9,
                });
                startcap:set_angle(rotation+math.pi/4)
                local endcap = Scene:add_box({
                    position = input.end_point,
                    size = vec2(thickness/math.sqrt(2), thickness/math.sqrt(2)),
                    is_static = true,
                    color = 0xe5d3b9,
                });
                endcap:set_angle(rotation+math.pi/4)


            end;
        ]]
    });
    prev_shape_guid = nil;
    start_marker_guid = nil;
    end_marker_guid = nil;
    adjusted_start = vec2(0, 0);
    adjusted_end = vec2(0, 0);
end;