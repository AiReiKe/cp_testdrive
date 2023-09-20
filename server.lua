if not ESX then
    TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)
end

local vehicles, categories, testVeh = {}, {}, {}
local sqlLoad = false

MySQL.ready(function()
    categories = MySQL.query.await("SELECT * FROM `vehicle_categories`", {})
    local data = MySQL.query.await("SELECT * FROM `vehicles`")
    for i = 1, #data, 1 do
        if data[i].category and not vehicles[data[i].category] then
            vehicles[data[i].category] = {}
        end
        table.insert(vehicles[data[i].category], {
            name = data[i].name,
            model = data[i].model,
            price = data[i].price
        })
    end
    sqlLoad = true
end)

ESX.RegisterServerCallback("cp_testdrive:getVehicleList", function(source, cb)
    while not sqlLoad do
        Wait(100)
    end
    cb(vehicles, categories)
end)

ESX.RegisterServerCallback("cp_testdrive:haveEnoughMoney", function(source, cb, vehLabel)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getMoney() >= Config.TestPrice then
        xPlayer.removeMoney(Config.TestPrice)
        TriggerClientEvent("esx:showNotification", source, _U("testVeh", Config.TestPrice, vehLabel), 'success')
        cb(true)
    else
        cb(false)
    end
end)

RegisterNetEvent("cp_testdrive:setTestVehcle")
AddEventHandler("cp_testdrive:setTestVehcle", function(netID)
    local src = source
    if netID then
        testVeh[tostring(src)] = NetworkGetEntityFromNetworkId(netID)
    else
        testVeh[tostring(src)] = nil
    end
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
    if testVeh[tostring(playerId)] then
        DeleteEntity(testVeh[tostring(playerId)])
        testVeh[tostring(playerId)] = nil
    end
end)

print("This script is created by AiReiKe")