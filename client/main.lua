local QBCore = exports["qb-core"]:GetCoreObject()
local pedSpawned = false
local ShopPed = {}
local blips = {}

function createBlips()
	for k, v in pairs(Config.Seller) do
        local blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
        SetBlipSprite(blip, v.blip.sprite)
        SetBlipScale(blip, v.blip.scale)
        SetBlipDisplay(blip, 4)
        SetBlipColour(blip, v.blip.colour)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(v.blip.label)
        EndTextCommandSetBlipName(blip)
        table.insert(blips, blip)
    end
end

local function createPeds()
    for k, v in pairs(Config.Seller) do
        if v.pedSpawned then return end

        if not ShopPed[k] then ShopPed[k] = {} end

        local current = v.ped
        current = type(current) == 'string' and GetHashKey(current) or current
        RequestModel(current)
        while not HasModelLoaded(current) do
            Wait(0)
        end

        ShopPed[k] = CreatePed(0, current, v.coords.x, v.coords.y, v.coords.z-1, v.coords.w, false, false)
        TaskStartScenarioInPlace(ShopPed[k], v.scenario, true)
        FreezeEntityPosition(ShopPed[k], true)
        SetEntityInvincible(ShopPed[k], true)
        SetBlockingOfNonTemporaryEvents(ShopPed[k], true)

        if Config.UseTarget then
            exports['qb-target']:AddTargetEntity(ShopPed[k], {
                options = {
                {
                    label = v.label,
                    icon = "fas fa-sign-in-alt",
                    action = function()
                        openSellMenu()
                    end,
                },
            },
                distance = 2.0
            })
        end

        v.pedSpawned = true
    end
end

local function deletePeds()
    if pedSpawned then
        DeletePed(ShopPed)
        pedSpawned = false
    end
end

function openSellMenu()
    local sellMenu = {
        {
            header = "Toptanc??",
            isMenuHeader = true,
        },
    }

    for k, v in pairs(Config.Categorys) do
        sellMenu[#sellMenu + 1] = {
            header = v.label,
            txt = "Bu meslek sonucu elde edilen e??yalar",
            params = {
                event = "gct-seller:client:SetupCategory",
                args = {
                    category = k,
                    items = v.items
                }
            }
        }
    end

    sellMenu[#sellMenu + 1] = {
        header = "????k????",
        txt = "Men??y?? Kapat",
        params = {
            event = "qb-menu:client:closeMenu",
        }
    }

    exports['qb-menu']:openMenu(sellMenu)
end

RegisterNetEvent('gct-seller:client:openMenu', function()
    openSellMenu()
end)

RegisterNetEvent('gct-seller:client:SetupCategory', function(data)
    local catMenu = {
        {
            header = "Toptanc??",
            isMenuHeader = true,
        },
    }

    for k, v in pairs(data.items) do
        catMenu[#catMenu + 1] = {
            header = QBCore.Shared.Items[k].label,
            txt = "Tane Fiyat??: $".. v.price,
            params = {
                event = "gct-seller:client:SellItem",
                args ={
                    item = k,
                    category = data.category
                }
            }
        }
    end

    catMenu[#catMenu + 1] = {
        header = "??? Geri",
        txt = "Bir ??nceki Men??",
        params = {
            event = "gct-seller:client:openMenu",
        }
    }

    exports['qb-menu']:openMenu(catMenu)
end)

RegisterNetEvent('gct-seller:client:SellItem', function(data)
    TriggerServerEvent("gct-seller:server:SellItem", data)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    createBlips()
    createPeds()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    deletePeds()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        createBlips()
        createPeds()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        deletePeds()
    end
end)