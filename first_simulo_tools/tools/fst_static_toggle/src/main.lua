function on_update()
    local shift = Input:key_pressed("ShiftLeft") or Input:key_pressed("ShiftRight")
    local alt = Input:key_pressed("AltLeft") or Input:key_pressed("AltRight")
    local control = Input:key_pressed("ControlLeft") or Input:key_pressed("ControlRight")
    if Input:pointer_just_pressed() or shift or alt or control then
        on_pointer_down(Input:pointer_pos(),shift,alt,control)
    end
end

function on_pointer_down(point, shift, alt, control)
    runtime_eval{
        input = {
            point = point,
            shift = shift,
            alt = alt,
            control = control,
        },
        code = [[
local objects_in_circle = Scene:get_objects_in_circle{
    position = input.point,
    radius = 0,
}

local function toggle(obj)
    local current_body_type = obj:get_body_type()
    local target_body_type = nil
    if current_body_type == BodyType.Static then
        target_body_type = BodyType.Dynamic
    end
    if current_body_type == BodyType.Dynamic or current_body_type == BodyType.Kinematic then
        target_body_type = BodyType.Static
    end
    if input.shift then target_body_type = BodyType.Static end
    if input.alt then target_body_type = BodyType.Dynamic end
    if input.control then target_body_type = BodyType.Kinematic end
    obj:set_body_type(target_body_type)
end

if objects_in_circle[1] ~= nil then
    if shift == false and alt == false then
        toggle(objects_in_circle[1])
    else
        for i,obj in ipairs(objects_in_circle) do
            toggle(obj)
        end
    end
end
        ]]
    }
end
