local start = vec2(0, 0)
local selected_object_guid = nil
local start_object_position = nil
local start_object_body_type = false
local prev_point = nil

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
            local selected_objects = Scene:get_objects_in_circle{
                position = input.point,
                radius = 0,
            }
            if #selected_objects == 0 then return end
            selected_object = selected_objects[1]
            local body_type = selected_object:get_body_type()
            selected_object:set_body_type(BodyType.Static)
            return {
                selected_object_guid = selected_object.guid,
                start_object_position = selected_object:get_position(),
                start_object_body_type = body_type,
            }
        ]]
    }

    if output ~= nil then
        selected_object_guid = output.selected_object_guid
        start_object_position = output.start_object_position
        start_object_body_type = output.start_object_body_type
    end
    prev_point = point
end

function on_pointer_move(point)
    if selected_object_guid ~= nil then
        if start_object_position == nil then start_object_position = point end
        local delta = point - start
        runtime_eval{
            input = {
                start_position = start_object_position,
                point = point,
                start = start,
                delta = delta,
                guid = selected_object_guid,
            },
            code = [[
                local obj = Scene:get_object_by_guid(input.guid)

                local line = Input:key_pressed("ShiftLeft") or Input:key_pressed("ShiftRight")
                local center_snap = Input:key_pressed("AltLeft") or Input:key_pressed("AltRight")
                
                local delta = Input:snap_if_preferred(input.delta)
                if center_snap then
                    delta = Input:snap_if_preferred(input.point)-input.start_position
                end
                if line then
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
                    
                end
                local position = input.start_position + delta

                obj:set_position(position)
            ]]
        }
    end
    prev_point = point
end

function on_pointer_up(point)
    if selected_object_guid ~= nil then
        if start_object_position == nil then start_object_position = point end
        runtime_eval{
            input = {
                point = point,
                prev_point = prev_point,
                guid = selected_object_guid,
                body_type = start_object_body_type,
            },
            code = [[
                local obj = Scene:get_object_by_guid(input.guid)
                obj:set_body_type(input.body_type)
                if input.body_type ~= BodyType.Static then
                    obj:set_linear_velocity((input.point - input.prev_point)*60)
                end
            ]]
        }
    end
    start = vec2(0, 0)
    selected_object_guid = nil
    start_object_position = nil
    start_object_body_type = false
    prev_point = nil
end