local start = vec2(0, 0);
local start_marker_guid = nil;
local end_marker_guid = nil;
local prev_shape_guid = nil;
local adjusted_start = vec2(0, 0);
local adjusted_end = vec2(0, 0);

local side = true
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
    if Input:key_just_pressed("Space") then
        if side then side = false else side = true end
        print("Switched side")
    end
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
                        local scaledvector = vector*2
                        return vec2(math.floor(scaledvector.x+0.5),math.floor(scaledvector.y+0.5))/2
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

                local circle = nil

                local radius = (adjusted_start_point-adjusted_end_point):magnitude()
                if radius > 0 then
                    local pos = (adjusted_start_point+adjusted_end_point)/2
                    circle = Scene:add_circle{
                        position = pos,
                        radius = radius/2,
                        is_static = true,
                        color = 0x695662,
                    }
                    return {
                        guid = circle.guid,
                        adjusted_start = adjusted_start_point,
                        adjusted_end = adjusted_end_point,
                    };
                else
                    return {
                        adjusted_start = adjusted_start_point,
                        adjusted_end = adjusted_end_point,
                    };
                end


            ]]
        });
        if output ~= nil then
            if output.guid ~= nil then
                prev_shape_guid = output.guid;
            else
                prev_shape_guid = nil;
            end
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
            side = side,
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

            local radius = (input.start_point-input.end_point):magnitude()/2

            if radius > 0 then

                local curve_pos = (input.start_point+input.end_point)/2

                local vertices = {}
                for i = 0,16 do
                    local angle = math.pi*i/16
                    local relative_start = input.end_point - input.start_point
                    local sign = 1
                    if relative_start.x < 0 then sign = -1 end
                    local added_angle = math.atan(relative_start.y/relative_start.x) + math.pi*sign/2
                    print(added_angle)
                    angle = angle - added_angle
                    table.insert(vertices, vec2(math.sin(angle),math.cos(angle))*radius+curve_pos)
                end

                for i,line_start in ipairs(vertices) do
                    local cap = Scene:add_circle{
                        position = line_start,
                        radius = 1/2,
                        color = 0xe5d3b9,
                        is_static = true,
                    }
                    if i == #vertices then break end
                    local line_end = vertices[i+1]
                    local sx = (line_start-line_end):magnitude()
                    local pos = (line_start+line_end)/2
                    local relative_line_end = line_end-pos
                    local rotation = math.atan(relative_line_end.y/relative_line_end.x)

                    local line = Scene:add_box({
                        position = pos,
                        size = vec2(sx/2, 1/2),
                        is_static = true,
                        color = 0xe5d3b9,
                    });
                    line:set_angle(rotation)
                end
            end;
        ]]
    });
    prev_shape_guid = nil;
    start_marker_guid = nil;
    end_marker_guid = nil;
    adjusted_start = vec2(0, 0);
    adjusted_end = vec2(0, 0);
end;