local vertices = {}
local thickness_mode = false

local prev_pointer_pos = vec2(0, 0)

function on_update()
    if Input:pointer_just_pressed() then
        on_pointer_down(Input:pointer_pos())
    end
    if Input:pointer_just_released() then
        on_pointer_up(Input:pointer_pos())
    end
    if Input:pointer_pos() ~= prev_pointer_pos then
        --on_pointer_move(Input:pointer_pos())
    end
    prev_pointer_pos = Input:pointer_pos()
end

function on_pointer_down(point)
    local output = runtime_eval{
        input = {
            point = point,
            thickness_mode = thickness_mode,
        },
        code = [[

local vertex_pos = input.point
--local vertex_marker = Scene:add_box{
--    position = vertex_pos,
--    size = vec2(0.2, 0.2),
--    is_static = true,
--    color = 0xe5d3b9,
--}
--vertex_marker:temp_set_collides(false)
--local vertex_line = nil

return {
    vertex_pos = vertex_pos,
}
        ]]
    }
    if output ~= nil then
        table.insert(vertices,{pos = output.vertex_pos})
    end
end

function on_pointer_move(point)
    runtime_eval{
        input = {
            point = point,
            tablee = {1,2,3,4},
        },
        code = [[
print("a")
print(tostring(input.tablee == nil))
for i,v in ipairs(input.tablee) do
    print(v)
end
        ]]
    }
end

function on_pointer_up(point)

    -- tables can't be passed so this is the only way
    local vertices_string = "local vertices = {"
    for i,v in ipairs(vertices) do
        vertices_string = vertices_string.."{"
        for n,m in pairs(v) do
            print(tostring(n).." aaaaaaa")
            vertices_string = vertices_string..tostring(n).."="..tostring(m)..","
        end
        vertices_string = vertices_string.."},"
    end
    vertices_string = vertices_string.."}"
    print(vertices_string)
    local output = runtime_eval{
        input = {
            point = point,
            thickness_mode = thickness_mode,
        },
        code = vertices_string..[[
if #vertices == 0 then return end
local should_reset_vertices = false
local distance = (input.point - vertices[#vertices].pos):magnitude()
print("distance is "..tostring(distance))
if distance < 0.1 then
    for i,v in ipairs(vertices) do
        local cap = Scene:add_circle{
            position = v.pos,
            radius = 1/2,
            color = 0xe5d3b9,
            is_static = true,
        }
        if i == #vertices then break end
        local line_end = vertices[i+1].pos
        local line_pos = (v.pos+line_end)/2
        local sx = (v.pos-line_end):magnitude()
        local relative_line_end = line_end-line_pos
        local rotation = math.atan(relative_line_end.y/relative_line_end.x)
        local line = Scene:add_box{
            position = line_pos,
            size = vec2(sx, 1),
            is_static = true,
            color = 0xe5d3b9
        }
        line:set_angle(rotation)
    end
    should_reset_vertices = true
end
return {
    should_reset_vertices = should_reset_vertices,
}
        ]]
    }
    if output.should_reset_vertices then
        vertices = {}
    end
end