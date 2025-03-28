function on_update()
    if self:pointer_just_pressed() or self:key_pressed("Delete") then
        on_pointer_down(self:pointer_pos());
    end;
end;

function on_pointer_down(point)
    print("Pointer down at " .. point.x .. ", " .. point.y);

    runtime_eval({
        input = {
            point = point,
        },
        code = [[
            local objects_in_circle = Scene:get_objects_in_circle({
                position = input.point,
                radius = 0,
            });

            if objects_in_circle[1] ~= nil then
                local obj = objects_in_circle[1];
                obj:destroy();
            else
                print("no hit");
            end;
        ]]
    });
end;
