local deliveryLocations = {}
local carryingBox = false
local config = {}

TriggerEvent('QBCore:GetObject', function(obj) config = obj end)

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function DrawDeliveryMarkers()
    for _, location in pairs(config.DeliveryLocations) do
        local blip = AddBlipForCoord(location.x, location.y, location.z)
        SetBlipSprite(blip, config.BlipSprite)
        SetBlipColour(blip, 5)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Delivery Location")
        EndTextCommandSetBlipName(blip)
    end
end

function CarryBoxAnimation()
    LoadAnimDict("anim@heists@box_carry@")
    TaskPlayAnim(PlayerPedId(), "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 1, 0, false, false, false)
    carryingBox = true
end

function StopCarryBoxAnimation()
    ClearPedTasks(PlayerPedId())
    carryingBox = false
end

function StartDelivery(location)
    local deliveryBlip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipRoute(deliveryBlip, true)
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(vector3(location.x, location.y, location.z) - playerCoords)
            local vehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 5.0, 0, 70)
            local vehicleCoords = GetEntityCoords(vehicle)
            local vehicleHeading = GetEntityHeading(vehicle)
            if distance < 5.0 then
                if not carryingBox then
                    DrawText3D(location.x, location.y, location.z, "~g~[E]~w~ - Pick up the package")
                    if IsControlJustReleased(0, 38) and IsVehicleModel(vehicle, GetHashKey("boxville2")) and IsNearVehicleBack(playerCoords, vehicleCoords, vehicleHeading) then -- 'E' key
                        CarryBoxAnimation()
                    end
                else
                    DrawText3D(location.x, location.y, location.z, "~g~[E]~w~ - Deliver the package")
                    if IsControlJustReleased(0, 38) then -- 'E' key
                        StopCarryBoxAnimation()
                        TriggerEvent('notification', 'You have completed the delivery!', 1) -- Display a notification to the player
                        TriggerServerEvent('sm-amazonjob:server:CompleteDelivery', location.payment) -- Send the payment amount to the server
                        RemoveBlip(deliveryBlip)
                        break
                    end
                end
            end
        end
    end)
end

function IsNearVehicleBack(playerCoords, vehicleCoords, vehicleHeading)
    local front = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, 4.0, 0.0)
    local back = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, -3.0, 0.0)
    local playerHeading = GetEntityHeading(PlayerPedId())
    local angle = math.abs(playerHeading - vehicleHeading)
    return #(playerCoords - back) < 2.5 and angle < 60
end


RegisterNetEvent('sm-amazonjob:client:UpdateDeliveryLocations')
AddEventHandler('sm-amazonjob:client:UpdateDeliveryLocations', function(locations)
    deliveryLocations = locations
    DrawDeliveryMarkers()
end)
