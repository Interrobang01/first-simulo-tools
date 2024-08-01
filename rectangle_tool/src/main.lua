local start = vec2(0, 0)
local start_marker_guid = nil
local end_marker_guid = nil
local prev_shape_guid = nil
local adjusted_start = vec2(0, 0)
local adjusted_end = vec2(0, 0)

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
    start = point
    local output = runtime_eval{
        input = {
            point = point,
        },
        code = [[
            local start_marker = Scene:add_box{
                position = input.point,
                size = vec2(0.2, 0.2),
                is_static = true,
                color = 0xe5d3b9,
            }
            local end_marker = Scene:add_box{
                position = input.point,
                size = vec2(0.2, 0.2),
                is_static = true,
                color = 0xe5d3b9,
            }
            return {
                start_guid = start_marker.guid,
                end_guid = end_marker.guid,
            }
        ]]
    }

    if output ~= nil then
        start_marker_guid = output.start_guid
        end_marker_guid = output.end_guid
        print('set guids')
    end
end

function on_pointer_move(point)
    if start_marker_guid ~= nil then
        print('start marker wasnt nil, realing up')
        local output = runtime_eval{
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

                local start_marker = Scene:get_object_by_guid(input.start_marker_guid)
                local end_marker = Scene:get_object_by_guid(input.end_marker_guid)
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
                    local dx = adjusted_end_point.x - adjusted_start_point.x
                    local dy = adjusted_end_point.y - adjusted_start_point.y
                    local xsign = 1
                    local ysign = 1
                    if dx < 0 then xsign = -1 end
                    if dy < 0 then ysign = -1 end
                    if math.abs(dx) > math.abs(dy) then
                        adjusted_end_point = vec2(dx+adjusted_start_point.x,math.abs(dx)*ysign+adjusted_start_point.y)
                    else
                        adjusted_end_point = vec2(math.abs(dy)*xsign+adjusted_start_point.x,dy+adjusted_start_point.y)
                    end
                end
                if centerscale then
                    adjusted_start_point = adjusted_start_point*2 - adjusted_end_point
                end

                start_marker:set_position(adjusted_start_point)
                end_marker:set_position(adjusted_end_point)

                if input.prev_shape_guid ~= nil then
                    Scene:get_object_by_guid(input.prev_shape_guid):destroy()
                end

                local width = math.abs(adjusted_end_point.x - adjusted_start_point.x)
                local height = math.abs(adjusted_end_point.y - adjusted_start_point.y)

                local size = vec2(width, height)
                local pos = vec2((adjusted_end_point.x + adjusted_start_point.x) / 2, (adjusted_end_point.y + adjusted_start_point.y) / 2)

                local new_box_omg = Scene:add_box{
                    position = pos,
                    size = size,
                    is_static = true,
                    color = 0x695662,
                }

                return {
                    guid = new_box_omg.guid,
                    adjusted_start = adjusted_start_point,
                    adjusted_end = adjusted_end_point,
                }
            ]]
        }
        if output ~= nil then
            prev_shape_guid = output.guid
            adjusted_start = output.adjusted_start
            adjusted_end = output.adjusted_end
        end
    end
end

function on_pointer_up(point)
    print("Pointer up!")
    runtime_eval{
        input = {
            start_point = adjusted_start,
            end_point = adjusted_end,
            start_guid = start_marker_guid,
            end_guid = end_marker_guid,
            prev_shape_guid = prev_shape_guid,
        },
        code = [[
            print("hi im in remote eval for the Epic Finale!!")

            if input.start_guid ~= nil then
                print('about to destroy start ' .. tostring(input.start_guid))
                print('about to destroy end ' .. tostring(input.end_guid))
                Scene:get_object_by_guid(input.start_guid):destroy()
                Scene:get_object_by_guid(input.end_guid):destroy()
            end

            if input.prev_shape_guid ~= nil then
                print('about to destroy prev_shape_guid ' .. tostring(input.prev_shape_guid))
                Scene:get_object_by_guid(input.prev_shape_guid):destroy()
            end

            local width = math.abs(input.end_point.x - input.start_point.x)
            local height = math.abs(input.end_point.y - input.start_point.y)
            print("defined width and height")

            local size = vec2(width, height)

            if size.x > 0 and size.y > 0 then
                local pos = vec2((input.end_point.x + input.start_point.x) / 2, (input.end_point.y + input.start_point.y) / 2)
                print("defined size and pos")

                print("about to add a cuboid, color is " .. 0xe5d3b9)
                Scene:add_box{
                    position = pos,
                    size = size,
                    is_static = false,
                    color = 0xe5d3b9,
                }

                print("Added a cuboid at " .. pos.x .. ", " .. pos.y .. " with size " .. size.x .. ", " .. size.y)
            end
        ]]
    }
    prev_shape_guid = nil
    start_marker_guid = nil
    end_marker_guid = nil
    adjusted_start = vec2(0, 0)
    adjusted_end = vec2(0, 0)
end