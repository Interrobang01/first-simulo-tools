local function on_pointer_down(point)
    RemoteScene:run
    {
        input = {point = point},
        code = "require('./packages/@interrobang/ibtools/tools/info/src/on_pointer_down_runtime.lua')()"
    }
end

function on_update()
    if self:pointer_just_pressed() then
        on_pointer_down(self:pointer_pos())
    end
end
