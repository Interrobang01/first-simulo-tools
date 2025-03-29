function on_update()
    if self:pointer_just_pressed() then
        on_pointer_down(self:pointer_pos())
    end
end

function on_pointer_down(point)
    RemoteScene:run{
        input = {
            point = self:snap_if_preferred(point),
            delete_original_objects = self:get_property("delete_original_objects").value,
            make_convex = self:get_property("make_convex").value,
            bolt_products = self:get_property("bolt_products").value,
            use_connected_objects = self:get_property("use_connected_objects").value,
            operation_or = self:get_property("operation_or").value,
            operation_not = self:get_property("operation_not").value,
            operation_and = self:get_property("operation_and").value,
        },
        code = "require('@interrobang/ibtools/tools/polygon_boolean/src/on_pointer_down_runtime.lua')()"
    }
end
