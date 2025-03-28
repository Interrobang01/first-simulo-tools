local function get_input_params(input)
    local params = {
        point = input.point,
        delete_original_objects = input.delete_original_objects,
        make_convex = input.make_convex,
        bolt_products = input.bolt_products,
        use_connected_objects = input.use_connected_objects
    }
    
    -- Determine the operation type
    if input.operation_or then
        params.operation = "or"
    elseif input.operation_not then
        params.operation = "not"
    elseif input.operation_and then
        params.operation = "and"
    else
        params.operation = "not" -- Default
    end
    
    return params
end

local function get_selected_objects(point)
    local objs = Scene:get_objects_in_circle{
        position = point,
        radius = 0,
    }

    table.sort(objs, function(a, b)
        return a:get_z_index() > b:get_z_index()
    end)
    
    if #objs < 2 then
        print("Not enough objects to perform boolean operation")
        return nil
    end
    
    return objs
end

local function perform_boolean_operation(top, bottom, operation, make_convex)
    local polygon = require('@interrobang/iblib/lib/polygon.lua')
    
    local position = bottom:get_position()
    local angle = bottom:get_angle()
    
    local resulting_shapes = polygon.shape_boolean{
        shape_a = bottom:get_shape(),
        position_a = position,
        rotation_a = angle,
        shape_b = top:get_shape(),
        position_b = top:get_position(),
        rotation_b = top:get_angle(),
        operation = operation,
        make_convex = make_convex,
        get_most_relevant = false,
    }
    
    if resulting_shapes == nil then
        print("Boolean operation failed")
        return nil
    end

    if resulting_shapes[1] == nil then
        print("Boolean operation resulted in an empty shape")
        return nil
    end
    
    return resulting_shapes, position, angle, bottom:get_color(), bottom:get_body_type()
end

local function put_together_args(shapes, position, angle, color, body_type)
    local args = {}
    for i = 1, #shapes do
        args[i] = {
            position = position,
            radius = 1,
            body_type = body_type,
            color = color,
            angle = angle,
            shape = shapes[i],
        }
    end
    return args
end

local function make_args(top, bottom, operation, make_convex)
    local shapes, position, angle, color, body_type = perform_boolean_operation(
        top, bottom, operation, make_convex
    )
    return put_together_args(shapes, position, angle, color, body_type)
end

local function create_result_objects(args, bolt_products)
    local last_object = nil
    
    for i = 1, #args do
        -- Make circle
        local result_circle = Scene:add_circle(args[i])
        result_circle:set_angle(args[i].angle)
        result_circle:set_shape(args[i].shape)

        -- Bolt circle
        if bolt_products and last_object ~= nil then
            Scene:add_bolt{
                object_a = last_object,
                object_b = result_circle,
            }
        end
        
        last_object = result_circle
    end
    
    return last_object
end

return function() -- main
    -- Get input parameters
    -- technically not necessary
    -- but it's encapsulation which is good
    local params = get_input_params(input) -- input not used after this point
    
    -- Get selected objects
    local objs = get_selected_objects(params.point)
    if not objs then return end
    
    local top = objs[1]
    local bottom = objs[2]
    
    -- Get args for objects
    local args = make_args(top, bottom, params.operation, params.make_convex)
    
    -- Create result objects
    create_result_objects(args, params.bolt_products)
    
    -- Handle original objects if needed
    if params.delete_original_objects then
        top:destroy()
        bottom:destroy()
    end

    Scene:push_undo() -- Always push undo
end
