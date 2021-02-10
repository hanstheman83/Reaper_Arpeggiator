------------------------------------------------------------------
-------------------- Helper Functions ----------------------------
return 
{
   

    Round = function (num, numDecimalPlaces) -- try GUI.round(num[, places])
        local mult = 10^(numDecimalPlaces or 0)
        return math.floor(num * mult + 0.5) / mult
    end,

    BoolToInt = function (bool)
        local convert = {[true] = 1, [false] = 0}
        return convert[bool]
    end,
    
    BoolToString = function (bool)
        local convert = {[true] = "true", [false] = "false"}
        return convert[bool]
    end


    
    

    

}