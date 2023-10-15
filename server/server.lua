QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('sm-amazonjob:server:GetDeliveryLocations', function(source, cb)
    cb(Config.DeliveryLocations)
end)

RegisterServerEvent('sm-amazonjob:server:CompleteDelivery')
AddEventHandler('sm-amazonjob:server:CompleteDelivery', function(payment)
    local source = source
    -- Example code for processing the payment and any other relevant actions
    -- You can add your own implementation here, such as giving the player the specified payment
    -- For example, the following code adds the payment to the player's account:
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if xPlayer then
        xPlayer.addMoney(payment)
        TriggerClientEvent('QBCore:Notify', source, 'You have received $' .. payment .. ' for the delivery', 'success')
    end
end)
