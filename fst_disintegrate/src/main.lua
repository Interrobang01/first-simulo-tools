function on_update()
    if Input:pointer_just_pressed() or Input:key_pressed("Delete") then
        on_pointer_down(Input:pointer_pos())
    end
end

function on_pointer_down(point)
    print("Pointer down at " .. point.x .. ", " .. point.y);

    runtime_eval{
        input = {
            point = point,
        },
        code = [[
local search_number = 16
local function get_size(object,object_position)
    
    local object_angle = object:get_angle()
    local object_guid = object.guid
    local highest_radius = 0
    for i = 0,search_number do
        local random_direction = vec2(math.cos(i*2*math.pi/search_number+object_angle),math.sin(i*2*math.pi/search_number+object_angle))
        local dist = 1
        for r = 0,20 do
            dist = dist * 2
            local circle = Scene:get_objects_in_circle{
                position = object_position+(random_direction*dist),
                radius = 0,
            }
            local found_object = false
            for index,v in pairs(circle) do
                if v == object then
                    found_object = true
                    break
                end
            end
            if found_object == false then
                if dist > highest_radius then
                    highest_radius = dist
                end
                break
            end
        end
    end
    return highest_radius
end

local objects_in_circle = Scene:get_objects_in_circle{
    position = input.point,
    radius = 0,
}
if objects_in_circle[1] ~= nil then
    local obj = objects_in_circle[1];
    local object_position = obj:get_position()
    local obj_size = get_size(obj,object_position)
    local object_color = obj.color
    local object_velocity = obj:get_linear_velocity()
    local scale = obj_size/16
    for x = -16,16 do
        for y = -16,16 do
            local get_objects_in_circle = Scene:get_objects_in_circle{
                position = object_position + (vec2(x,y)*scale),
                radius = 0,
            }
            print(#get_objects_in_circle)
            local circle_has_object = false
            for i,v in pairs(get_objects_in_circle) do
                if v == obj then circle_has_object = true end
            end
            print(tostring(circle_has_object))
            if circle_has_object then
                local debris = Scene:add_box{
                    name = "debris",
                    position = object_position + (vec2(x,y)*scale),
                    size = vec2(scale,scale),
                    is_static = false,
                    color = object_color,
                }
                debris:set_linear_velocity(object_velocity)
            end
        end
    end
    obj:destroy()
else
    print("no hit")
end
            ]] -- we need this so the double closing square brackets in the code don't close the string
    }
end
