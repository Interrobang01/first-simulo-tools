function on_update()
    if Input:pointer_just_pressed() then
        on_pointer_down(Input:pointer_pos())
    end
end

function on_pointer_down(point)
    runtime_eval{
        input = {
            point = point,
        },
        code = [[
local objects_in_circle = Scene:get_objects_in_circle{
    position = input.point,
    radius = 0,
}
Console:log("Pos is "..tostring(input.point))
if #objects_in_circle > 0 then
    for i = 1,#objects_in_circle do
        local obj = objects_in_circle[i]
        local name = obj:get_name()
        local objcolor = obj:get_color()
        Console:log(" ")
        Console:log("Object name is "..name)
        Console:log("GUID is "..tostring(obj.guid))
        Console:log("position is "..tostring(obj:get_position()))
        Console:log("body type is "..tostring(obj:get_body_type()))
        Console:log("color is "..tostring(objcolor.r).." "..tostring(objcolor.g).." "..tostring(objcolor.b).." "..tostring(objcolor.a))
    end
end
        ]]
    }
end
