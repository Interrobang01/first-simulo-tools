function on_update()
    if Input:pointer_just_pressed() then
        on_pointer_down(Input:pointer_pos())
    end;
end;

function on_pointer_down(point)
    print("Position is "..tostring(point))
    runtime_eval{
        input = {
            point = point,
        },
        code = [[
local objects_in_circle = Scene:get_objects_in_circle{
    position = input.point,
    radius = 0,
}

if #objects_in_circle > 0 then
    for i = 1,#objects_in_circle do
        print(" ")
        print("Object name is "..objects_in_circle[i]:get_name())
        print("Object GUID is "..tostring(objects_in_circle[i].guid))
        print("Object position is "..tostring(objects_in_circle[i]:get_position()))
    end
end
        ]]
    }
end;
