return function()
    local point = input.point

    local objects_in_circle = Scene:get_objects_in_circle{
        position = point,
        radius = 0,
        }

        print("---")
        if #objects_in_circle > 0 then
            for i = 1,#objects_in_circle do
                local obj = objects_in_circle[i]
                local objcolor = obj:get_color()
                print("Object name is '"..(obj:get_name() or "") .. "'")
                print("GUID is "..tostring(obj.id))
                print("position is "..tostring(obj:get_position()))
                print("body type is "..tostring(obj:get_body_type()))
                print("color is "..tostring(objcolor.r).." "..tostring(objcolor.g).." "..tostring(objcolor.b).." "..tostring(objcolor.a))
                print("---")
            end
        end
    print("Click position is "..tostring(point))
    print("- - - - - -")
end
