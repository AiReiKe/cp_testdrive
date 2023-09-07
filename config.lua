Config = {}

Config.Locale = GetConvar('esx:locale', 'tc')

--Config.Blip = false   -- 不要顯示地圖小圖標填false
Config.Blip = {
    sprite = 483,
    color = 0,
    scale = 0.6,
}

Config.ShopCoords = vector3(-57.144119262695, -1097.2093505859, 26.422342300415)    -- 試駕中心進入點
Config.DisplayCoords = vector4(-46.666469573975, -1097.6800537109, 26.34467124939, 12.305948257446) -- 車輛預覽位置
Config.TestPrice = 150  -- 試駕金額
Config.TestTime = 90    -- 試駕時長, 單位: sec
Config.TestCoords = vector4(-48.801502227783, -1074.7303466797, 26.745931625366, 70.25952911377)    -- 試駕車輛生成點
Config.TeleportEnd = true   -- 試駕完後是否傳回進入點
Config.ReturnCoords = vector3(-12.552647590637, -1081.3544921875, 26.599618911743)  -- 車輛歸還點

if not IsDuplicityVersion() then
    function GiveKey(vehicle)
        --exports['xd_locksystem']:givePlayerKeys(GetVehicleNumberPlateText(vehicle))
        --exports['t1ger_keys']:GiveTemporaryKeys(GetVehicleNumberPlateText(vehicle), GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))), "試駕車輛")
    end

    function SetFuel(vehicle, fuel)
        SetVehicleFuelLevel(vehicle, fuel)
        --exports['LegacyFuel']:SetFuel(vehicle, fuel)
    end
end