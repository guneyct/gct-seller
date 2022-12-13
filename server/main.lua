local QBCore = exports["qb-core"]:GetCoreObject()

RegisterNetEvent("gct-seller:server:SellItem", function(data)
    local item = data.item
    local Player = QBCore.Functions.GetPlayer(source)

    if Player == nil then return end

    if Player.Functions.GetItemByName(item) == nil or Player.Functions.GetItemByName(item).amount == nil or Player.Functions.GetItemByName(item).amount <= 0 then 
        TriggerClientEvent('QBCore:Notify', source, "Üzerinde Bu Eşya Yok!", "error")
        return
    end

    local itemAmount = Player.Functions.GetItemByName(item).amount

    local itemPrice = Config.Items[data.category][item].price

    local totalPrice = math.floor(itemAmount * itemPrice)

    MySQL.query("SELECT * FROM players WHERE `citizenid` = @id", {
        ["@id"] = Player.PlayerData.citizenid
    }, function(result)
        local playerDaily = tonumber(result[1].daily)

        if playerDaily >= Config.DailyLimit then 
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, "Günlük Limitiniz Dolmuş!")
            return
        end

        if (playerDaily + totalPrice) >= Config.DailyLimit then
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, "Günlük Limitinizi Aşamazsınız! Daha az eşya satmayı deneyin!")
            return
        end

        if Player.Functions.RemoveItem(item, itemAmount) then
            Player.Functions.AddMoney("cash", totalPrice)

            MySQL.update("UPDATE players SET daily = @daily WHERE citizenid = @id", {
                ["@daily"] = playerDaily + totalPrice,
                ["@id"] = Player.PlayerData.citizenid
            })

            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, itemAmount.." Tane "..QBCore.Shared.Items[item].label.." $"..totalPrice.." Fiyatına Satıldı!", "success")
        else
            TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, "Bir Hata Oluştu!")
        end
    end)
end)

RegisterNetEvent("gct-seller:server:updateDaily", function(payment, item)
    if item then
        local Player = QBCore.Functions.GetPlayer(source)

        MySQL.query("SELECT * FROM players WHERE `citizenid` = @id", {
            ["@id"] = Player.PlayerData.citizenid
        }, function(result)
            local playerDaily = tonumber(result[1].daily)
            if playerDaily and playerDaily >= 0 then
                if playerDaily < Config.DailyLimit then
                    Player.Functions.AddMoney("cash", payment)
                    Player.Functions.RemoveItem(item.name, item.amount)
                    
                    MySQL.update("UPDATE players SET daily = @daily WHERE citizenid = @id", {
                        ["@daily"] = playerDaily + payment,
                        ["@id"] = Player.PlayerData.citizenid
                    })
                end
            end
        end)
    else
        local Player = QBCore.Functions.GetPlayer(source)

        MySQL.query("SELECT * FROM players WHERE `citizenid` = @id", {
            ["@id"] = Player.PlayerData.citizenid
        }, function(result)
            local playerDaily = tonumber(result[1].daily)
            if playerDaily and playerDaily >= 0 then
                if playerDaily < Config.DailyLimit then
                    Player.Functions.AddMoney("cash", payment)

                    MySQL.update("UPDATE players SET daily = @daily WHERE citizenid = @id", {
                        ["@daily"] = playerDaily + payment,
                        ["@id"] = Player.PlayerData.citizenid
                    })
                end
            end
        end)
    end
end)

QBCore.Functions.CreateCallback("gct-seller:server:checkDaily", function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)

    if Player then
        MySQL.query("SELECT * FROM players WHERE `citizenid` = @id", {
            ["@id"] = Player.PlayerData.citizenid
        }, function(result)
            local playerDaily = tonumber(result[1].daily)
            if playerDaily and playerDaily >= 0 then
                if playerDaily < Config.DailyLimit then
                    return true

                else
                    return false
                end
            end
        end)
    else
        return false
    end
end)

function DailyLimitInteval()
    MySQL.query("UPDATE players SET `daily` = @daily", {["@daily"] = 0})
    SetTimeout(Config.DailyReset * (60 * 1000), DailyLimitInteval)
end

DailyLimitInteval()