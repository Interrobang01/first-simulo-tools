function on_update()
    if Input:pointer_just_pressed() or Input:key_pressed("ShiftLeft") or Input:key_pressed("AltLeft") then
        on_pointer_down(Input:pointer_pos(),Input:key_pressed("ShiftLeft"),Input:key_pressed("AltLeft"))
    end
end

function on_pointer_down(point, shift, alt)
    runtime_eval{
        input = {
            point = point,
            shift = shift,
            alt = alt,
        },
        code = [[
local objects_in_circle = Scene:overlap_circle{
    position = input.point,
    radius = 0,
}

local function toggle(obj)
    local is_static = obj:temp_get_is_static()
    if input.shift then is_static = false end
    if input.alt then is_static = true end
    obj:temp_set_is_static(not is_static)
end

if objects_in_circle[1] ~= nil then
    if shift == false and alt == false then
        toggle(objects_in_circle[1])
    else
        for i,obj in ipairs(objects_in_circle) do
            toggle(obj)
            print("e")
        end
    end
end
        ]]
    }
end
