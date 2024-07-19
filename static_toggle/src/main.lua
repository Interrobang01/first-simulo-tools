function on_update()
    if Input:pointer_just_pressed() then
        on_pointer_down(Input:pointer_pos());
    end;
end;

function on_pointer_down(point)
    print("Pointer down at " .. point.x .. ", " .. point.y);

    runtime_eval({
        input = {
            point = point,
        },
        code = [[
            local objects_in_circle = Scene:overlap_circle({
                position = input.point,
                radius = 0,
            });

            function rgb_to_color(r, g, b)
                return r * 0x10000 + g * 0x100 + b;
            end

            function color_to_rgb(color)
                local r = math.floor(color / 0x10000)
                local g = math.floor((color % 0x10000) / 0x100)
                local b = color % 0x100
                return {r = r, g = g, b = b}
            end

function rgb_to_hsl(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local h, s, l
    l = (max + min) / 2

    if max == min then
        h, s = 0, 0 -- achromatic
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return h, s, l
end

function hsl_to_rgb(h, s, l)
    local r, g, b

    if s == 0 then
        r, g, b = l, l, l -- achromatic
    else
        local function hue2rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1 / 6 then return p + (q - p) * 6 * t end
            if t < 1 / 2 then return q end
            if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
            return p
        end

        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        r = hue2rgb(p, q, h + 1 / 3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1 / 3)
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

function adjust_brightness(rgb, factor)
    local r, g, b = rgb.r, rgb.g, rgb.b
    local h, s, l = rgb_to_hsl(r, g, b)
    l = math.min(1, math.max(0, l * factor)) -- clamp l between 0 and 1
    r, g, b = hsl_to_rgb(h, s, l)
    return {r = r, g = g, b = b}
end


            if objects_in_circle[1] ~= nil then

                local obj = objects_in_circle[1];

                print("is_static is " .. tostring(obj:temp_get_is_static()));

                local is_static = obj:temp_get_is_static();
                obj:temp_set_is_static(not is_static);

                local new_is_static = obj:temp_get_is_static();

                print("set is_static to " .. tostring(new_is_static));
                local rgb = color_to_rgb(obj.color);
                if (not obj.name:find("^static_")) then
                    rgb = adjust_brightness(rgb, 0.5);
                    print('realium compound');
                    obj.name = "static_" .. obj.name;
                else
                    rgb = adjust_brightness(rgb, 2);
                    obj.name = obj.name:gsub("^static_", "");
                end;
                obj.color = rgb_to_color(rgb.r, rgb.g, rgb.b);
            else
                print("no hit");
            end;
        ]]
    });
end;
