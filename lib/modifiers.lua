return {
    ctrl = function()
        return self:key_pressed("ControlLeft") or self:key_pressed("ControlRight")
    end,
    shift = function()
        return self:key_pressed("ShiftLeft") or self:key_pressed("ShiftRight")
    end,
    alt = function()
        return self:key_pressed("AltLeft") or self:key_pressed("AltRight")
    end,
    super = function()
        return self:key_pressed("SuperLeft") or self:key_pressed("SuperRight")
    end,
}
