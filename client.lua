if not ESX then
    TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)
end


local categories = {}
local inZone, displayVeh, inShop, testVeh, returnBlip = false, nil, false, nil, nil

local function ShowReturnBlip()
    returnBlip = AddBlipForCoord(Config.ReturnCoords)
    SetBlipSprite(returnBlip, 225)
    SetBlipColour(returnBlip, 1)
    SetBlipScale(returnBlip, 0.6)
    SetBlipDisplay(returnBlip, 4)
    SetBlipAsShortRange(returnBlip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(_U('return_blip'))
    EndTextCommandSetBlipName(returnBlip)
end

local function DeleteReturnBlip()
    if returnBlip then
        RemoveBlip(returnBlip)
        returnBlip = nil
    end
end

local DisplayText = function(text, x, y)
    SetTextFont(0)
	SetTextScale(0.4, 0.4)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0,255)
	SetTextDropShadow()
	
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(x - 1.0 / 2, y - 1.0 / 2 + 0.005)
end

local function DeleteDisplayVehicle()
    local attempt = 0

	if displayVeh and DoesEntityExist(displayVeh) then
		while DoesEntityExist(displayVeh) and not NetworkHasControlOfEntity(displayVeh) and attempt < 100 do
			Wait(100)
			NetworkRequestControlOfEntity(displayVeh)
			attempt = attempt + 1
		end

		if DoesEntityExist(displayVeh) and NetworkHasControlOfEntity(displayVeh) then
			ESX.Game.DeleteVehicle(displayVeh)
		end
	end
    displayVeh = nil
end

local function WaitForVehicleToLoad(modelHash)
	modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

	if not HasModelLoaded(modelHash) then
		RequestModel(modelHash)

		BeginTextCommandBusyspinnerOn('STRING')
		AddTextComponentSubstringPlayerName(_U('awaiting_model'))
		EndTextCommandBusyspinnerOn(4)

		while not HasModelLoaded(modelHash) do
			Wait(0)
			DisableAllControlActions(0)
		end

		BusyspinnerOff()
	end
end

local function TestDriveVehicle(model)
    local ped = PlayerPedId()
    SetEntityCoords(ped, Config.TestCoords.xyz)
    FreezeEntityPosition(ped, false)

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    ESX.Game.SpawnVehicle(model, Config.TestCoords.xyz, Config.TestCoords.w, function(spawnVeh)
        testVeh = spawnVeh
        SetVehicleNumberPlateText(testVeh, "TEST"..math.random(0000,9999))
        TaskWarpPedIntoVehicle(ped, testVeh, -1)
        SetEntityVisible(ped, true, 0)
        SetModelAsNoLongerNeeded(model)
        GiveKey(testVeh)
        SetFuel(testVeh, 100)
    end)
    inShop = false
    while not IsPedInVehicle(ped, testVeh) do
        Wait(0)
    end
    local testTime = Config.TestTime
    Citizen.CreateThread(function()
        while testTime > 0 and IsPedInVehicle(ped, testVeh) do
            testTime = testTime - 1
            Citizen.Wait(1000)
        end
        testTime = 0
    end)
    Citizen.CreateThread(function()
        while testTime > 0 do
            DisableControlAction(0, 75, true)  -- Disable exit vehicle when stop
            DisableControlAction(27, 75, true) -- Disable exit vehicle when Driving
            DisplayText(_U('testTime', testTime), 0.72, 1.41)
            DisplayText(_U('press_stop_test'), 0.72, 1.44)
            Citizen.Wait(0)
        end
        if DoesEntityExist(testVeh) then
            DeleteEntity(testVeh)
        end
        testVeh = nil
        if Config.TeleportEnd then
            SetEntityCoords(ped, Config.ShopCoords)
        end
    end)
    Citizen.CreateThread(function()
        while testTime > 0 do
            local dist = Vdist(GetEntityCoords(ped), Config.ReturnCoords)
            if dist <= 50 then
                DrawMarker(1, Config.ReturnCoords-vec3(0, 0, 0.92), 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.0, 2.0, 1.5, 50, 50, 204, 120, false, true, 2, false, false, false, false)
                if dist <= 3.5 then
                    if not inZone then
                        inZone = true
                        if Config.UseTextUI then
                            ESX.TextUI(_U("press_to_return"))
                        end
                    end
                    if not Config.UseTextUI then
                        ESX.ShowHelpNotification(_U("press_to_return"))
                    end
                    if IsControlJustReleased(0, 38) then
                        testTime = 0
                    end
                else
                    if inZone then
                        inZone = false
                        if Config.UseTextUI then
                            ESX.HideUI()
                        end
                    end
                end
            else
                Wait(500)
            end
            Wait(0)
        end
        DeleteReturnBlip()
    end)
    ShowReturnBlip()
end

local function OpenTestShop()
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
	SetEntityVisible(ped, false)
	SetEntityCoords(ped, Config.DisplayCoords.xyz)

    local elements = {}
    for i = 1, #categories, 1 do
        local elements2 = {}
        for j = 1, #categories[i].vehicles, 1 do
            local vehData = categories[i].vehicles[j]
            table.insert(elements2, ('%s <span style="color:green;">%s</span>'):format(vehData.name, _U('generic_shopitem', ESX.Math.GroupDigits(vehData.price))))
        end
        table.insert(elements, {
			category    = i,
			label   = categories[i].label,
			value   = 0,
			type    = 'slider',
			max     = #elements2-1,
			options = elements2
		})
    end

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'testdrive', {
		title    = _U('testdrive', Config.TestPrice),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		local vehicleData = categories[data.current.category].vehicles[data.current.value + 1]

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'testdrive_confirm', {
			title = _U('testdrive_vehicle', vehicleData.name, ESX.Math.GroupDigits(vehicleData.price), Config.TestPrice),
			align = 'top-left',
			elements = {
				{label = _U('no'),  value = 'no'},
				{label = _U('yes'), value = 'yes'}
		}}, function(data2, menu2)
			if data2.current.value == 'yes' then
                if not testVeh then
                    if IsModelInCdimage(vehicleData.model) then
                        if ESX.Game.IsSpawnPointClear(Config.TestCoords.xyz, 6.0) then
                            ESX.TriggerServerCallback("cp_testdrive:haveEnoughMoney", function(have)
                                if have then
                                    menu2.close()
                                    menu.close()
                                    DeleteDisplayVehicle()
                                    TestDriveVehicle(vehicleData.model)
                                else
                                    ESX.ShowNotification(_U("not_enough_money", Config.TestPrice), 'error')
                                end
                            end, vehicleData.name)
                        else
                            ESX.ShowNotification(_U("no_vehicle_space"), 'error')
                        end
                    else
                        ESX.ShowNotification(_U('vehicle_not_exist', vehicleData.name), 'error')
                        menu2.close()
                    end
                end
			else
				menu2.close()
			end
		end, function(data2, menu2)
			menu2.close()
		end)
	end, function(data, menu)
		menu.close()
		DeleteDisplayVehicle()

        FreezeEntityPosition(ped, false)
		SetEntityVisible(ped, true)
		SetEntityCoords(ped, Config.ShopCoords)
        ClearAreaOfVehicles(Config.DisplayCoords.xyz, 6.5)

		inShop = false
	end, function(data, menu)
        local vehicleData = categories[data.current.category].vehicles[data.current.value + 1]

		if IsModelInCdimage(vehicleData.model) then
            WaitForVehicleToLoad(vehicleData.model)
            ESX.Game.SpawnLocalVehicle(vehicleData.model, Config.DisplayCoords.xyz, Config.DisplayCoords.w, function(spawnVeh)
                DeleteDisplayVehicle()
                displayVeh = spawnVeh
                FreezeEntityPosition(displayVeh, true)
                SetModelAsNoLongerNeeded(vehicleData.model)
                SetPedIntoVehicle(ped, displayVeh, -1)
            end)
        end
	end)

    if categories[1] and categories[1].vehicles[1] then
        local vehicleData = categories[1].vehicles[1]

		if IsModelInCdimage(vehicleData.model) then
            WaitForVehicleToLoad(vehicleData.model)
            ESX.Game.SpawnLocalVehicle(vehicleData.model, Config.DisplayCoords.xyz, Config.DisplayCoords.w, function(spawnVeh)
                DeleteDisplayVehicle()
                displayVeh = spawnVeh
                SetPedIntoVehicle(ped, displayVeh, -1)
                FreezeEntityPosition(displayVeh, true)
                SetModelAsNoLongerNeeded(vehicleData.model)
            end)
        end
    end
end

Citizen.CreateThread(function()
    if Config.Blip then
        local blip = AddBlipForCoord(Config.ShopCoords)
        SetBlipSprite(blip, Config.Blip.sprite or 483)
        SetBlipColour(blip, Config.Blip.color or 0)
        SetBlipScale(blip, Config.Blip.scale or 0.6)
        SetBlipDisplay(blip, 4)
        SetBlipAsShortRange(blip, true)

        BeginTextCommandSetBlipName('STRING')
	    AddTextComponentSubstringPlayerName(_U('map_blip'))
	    EndTextCommandSetBlipName(blip)
    end
end)

Citizen.CreateThread(function()
    Config.UseTextUI = GetResourceState('esx_textui') == 'started'
    ESX.TriggerServerCallback("cp_testdrive:getVehicleList", function(cbVeh, cbCate)
        for i = 1, #cbCate, 1 do
            table.insert(categories, {
                label = cbCate[i].label,
                vehicles = cbVeh[cbCate[i].name]
            })
        end
    end)
end)

Citizen.CreateThread(function()
    while true do
        local dist = Vdist(GetEntityCoords(PlayerPedId()), Config.ShopCoords)
        if dist <= 50 and not testVeh then
            DrawMarker(27, Config.ShopCoords-vec3(0, 0, 0.92), 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, 150, 150, 150, 120, false, true, 2, false, false, false, false)
            if dist <= 1.1 then
                if not inZone then
                    inZone = true
                    if Config.UseTextUI then
                        ESX.TextUI(_U("press_to_test"))
                    end
                end
                if not Config.UseTextUI then
                    ESX.ShowHelpNotification(_U("press_to_test"))
                end
                if IsControlJustReleased(0, 38) and not inShop then
                    inShop = true
                    OpenTestShop()
                end
            else
                if inZone then
                    inZone = false
                    if Config.UseTextUI then
                        ESX.HideUI()
                    end
                end
            end
        else
            Wait(400)
        end
        Citizen.Wait(0)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == 'esx_textui' then
        Config.UseTextUI = false
        if inZone then
            ESX.HideUI()
        end
    end
    if resource == GetCurrentResourceName() then
        if inZone and Config.UseTextUI then
            ESX.HideUI()
        end
        if inShop then
            ESX.UI.Menu.CloseAll()
            DeleteDisplayVehicle()
            local ped = PlayerPedId()
            SetEntityVisible(ped, true, 0)
            FreezeEntityPosition(ped, false)
            ClearAreaOfVehicles(Config.DisplayCoords.xyz, 6.5)
            ESX.ShowNotification(_U("testdrive_close"), 'error')
            if Config.TeleportEnd then
                SetEntityCoords(ped, Config.ShopCoords)
            end
        end
        if testVeh then
            DeleteReturnBlip()
            if DoesEntityExist(testVeh) then
                DeleteEntity(testVeh)
            end
            testVeh = nil
            ESX.ShowNotification(_U("testdrive_close"), 'error')
            if Config.TeleportEnd then
                SetEntityCoords(PlayerPedId(), Config.ShopCoords)
            end
        end
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == 'esx_textui' then
        Config.UseTextUI = true
        if inZone then
            if testVeh then
                ESX.TextUI(_U("press_to_return"))
            else
                ESX.TextUI(_U("press_to_test"))
            end
        end
    end
end)
