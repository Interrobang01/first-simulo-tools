local function get_input_params(input)
    -- Get input parameters
    -- technically not necessary
    -- but it's encapsulation which is good
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

local function obj_to_obj_params(obj)
    -- Convert an object to a table of parameters
    -- This is useful for passing to functions that require specific attributes
    local params = {
        position = obj:get_position(),
        angle = obj:get_angle(),
        shape = obj:get_shape(),
        color = obj:get_color(),
        body_type = obj:get_body_type(),
        id = obj.id,
    }
    return params
end

local function perform_boolean_operation(top, bottom, operation, make_convex)
    local polygon = require('@interrobang/iblib/lib/polygon.lua')
    
    local resulting_shapes = polygon.shape_boolean{
        shape_a = bottom.shape,
        position_a = bottom.position,
        rotation_a = bottom.angle,
        shape_b = top.shape,
        position_b = top.position,
        rotation_b = top.angle,
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
    
    return resulting_shapes
end

local function soft_duplicate_object(obj)
    local duplicate = Scene:add_circle{
        position = obj:get_position(),
        radius = 1,
        color = obj:get_color(),
        body_type = obj:get_body_type(),
    }
    duplicate:set_shape(obj:get_shape())
    duplicate:set_angle(obj:get_angle())
    return duplicate
end

local function make_object_from_args(args)
    local obj = Scene:add_circle(args)
    obj:set_angle(args.angle)
    obj:set_shape(args.shape)
    return obj
end

local function union_connected_objects(obj_params, delete_list)
    -- Imperfect function to mostly union connected objects
    -- Works most of the time but may miss objects
    -- This happens if objects are weird shapes and with weird positions
    --[[
    As long as objects that have more degrees of separation from
    the original object are correspondingly farther away in
    position, it'll be fine
    --]]

    local real_obj = Scene:get_object(obj_params.id)

    local connected_objects = real_obj:get_all_bolted() -- ideally this is other attachments too but whatever not doin that

    -- Sort by closeness to the original object 
    table.sort(connected_objects, function(a, b)
        return (a:get_position() - obj_params.position):magnitude() < (b:get_position() - obj_params.position):magnitude()
    end)

    print("Connected objects found for union operation:")
    for i, connected_obj in ipairs(connected_objects) do
        print("Connected object " .. i .. ": " .. tostring(connected_obj.id))
    end

    -- Iterate through connected objects and union them
    for i, connected_obj in ipairs(connected_objects) do
        if connected_obj.id ~= obj_params.id then
            local new_shapes = perform_boolean_operation(
                obj_to_obj_params(connected_obj),
                obj_params,
                "or", -- always use "or", for unioning
                false -- don't make convex here
            )

            if new_shapes and #new_shapes == 1 then
                obj_params.shape = new_shapes[1] -- Update the shape of the original object with the new shape from the union
                -- Add to delete list
                delete_list[connected_obj.id] = true
            end
        end
    end

    return obj_params, delete_list
end

local function get_selected_objects(point, use_connected_objects)
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

    local delete_list = {}
    delete_list[objs[1].id] = true
    delete_list[objs[2].id] = true

    local obj_params = {obj_to_obj_params(objs[1]), obj_to_obj_params(objs[2])}

    if use_connected_objects then
        obj_params[1], delete_list = union_connected_objects(obj_params[1], delete_list)
        obj_params[2], delete_list = union_connected_objects(obj_params[2], delete_list)
    end

    print("Selected objects for boolean operation:")
    for i = 1, #obj_params do
        print("Object " .. i .. ":")
        print("Position: " .. tostring(obj_params[i].position))
        print("Angle: " .. tostring(obj_params[i].angle))
        print("Shape: " .. tostring(obj_params[i].shape))
        print("Color: " .. tostring(obj_params[i].color))
        print("Body Type: " .. tostring(obj_params[i].body_type))
    end
    
    return obj_params, delete_list
end

local function put_together_args(shapes, bottom)
    local args = {}
    for i = 1, #shapes do
        args[i] = {
            position = bottom.position,
            radius = 1,
            body_type = bottom.body_type,
            color = bottom.color,
            angle = bottom.angle,
            shape = shapes[i],
        }
    end
    return args
end

local function make_args(top, bottom, operation, make_convex)
    local shapes = perform_boolean_operation(
        top, bottom, operation, make_convex
    )
    local args = put_together_args(shapes, bottom)

    print("Resulting shapes from boolean operation:")
    for i = 1, #shapes do
        print("Shape " .. i .. ":")
        print("Shape: " .. tostring(shapes[i]))
    end
    if not args or #args == 0 then
        print("No resulting shapes to create objects from")
        return {}
    else
        print("Successfully created " .. #args .. " resulting shapes from boolean operation")
    end

    return args
end

local function create_result_objects(args, bolt_products)
    local last_object = nil
    
    for i = 1, #args do
        -- Make circle
        local result_circle = make_object_from_args(args[i])

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
    local params = get_input_params(input) -- input not used after this point
    
    -- Get selected objects
    local obj_params, delete_list = get_selected_objects(params.point, params.use_connected_objects)
    if not obj_params then
        print("No valid objects selected for boolean operation")
        return
    end

    local top = obj_params[1]
    local bottom = obj_params[2]
    
    -- Get args for objects
    local args = make_args(top, bottom, params.operation, params.make_convex)
    
    -- Create result objects
    create_result_objects(args, params.bolt_products)
    
    -- Handle original objects if needed
    if params.delete_original_objects then
        if not delete_list then
            print("No valid objects to delete for boolean operation")
        else
            for i,v in pairs(delete_list) do
                Scene:get_object(i):destroy()
            end
        end
    end

    Scene:push_undo() -- Always push undo
end
