-- Server.lua

local teams = {} -- Menyimpan daftar tim, tiap tim memiliki ID pemain pemimpin

RegisterServerEvent("job:invitePlayer")
AddEventHandler("job:invitePlayer", function(playerId)
    local source = source
    if not teams[source] then
        teams[source] = { source }
    end

    if #teams[source] >= Config.MaxTeamSize then
        TriggerClientEvent('chat:addMessage', source, { args = { "Tim sudah penuh!" } })
        return
    end

    TriggerClientEvent("job:receiveInvite", playerId, source)
end)

RegisterServerEvent("job:acceptInvite")
AddEventHandler("job:acceptInvite", function(leaderId)
    local source = source
    if not teams[leaderId] then
        teams[leaderId] = { leaderId }
    end

    if #teams[leaderId] >= Config.MaxTeamSize then
        TriggerClientEvent('chat:addMessage', source, { args = { "Tim sudah penuh!" } })
        return
    end

    table.insert(teams[leaderId], source)
    TriggerClientEvent('chat:addMessage', source, { args = { "Anda telah bergabung dengan tim!" } })
end)

RegisterServerEvent("job:payTeam")
AddEventHandler("job:payTeam", function()
    local source = source
    local team = teams[source]

    if team then
        local totalPay = Config.TotalDeliveryPay
        local numMembers = #team
        local payPerMember = totalPay / numMembers -- Bagian pendapatan per anggota tim

        for _, memberId in ipairs(team) do
            -- Contoh: menambahkan uang ke pemain
            -- local xPlayer = ESX.GetPlayerFromId(memberId)
            -- xPlayer.addMoney(payPerMember)
            TriggerClientEvent('chat:addMessage', memberId, { args = { "Pekerjaan", "Anda menerima $" .. payPerMember .. " untuk pengantaran!" } })
        end

        -- Reset tim setelah pembayaran
        teams[source] = nil
    end
end)

RegisterServerEvent("job:notifyTeamStart")
AddEventHandler("job:notifyTeamStart", function()
    local source = source
    local team = teams[source]

    if team then
        for _, memberId in ipairs(team) do
            TriggerClientEvent('chat:addMessage', memberId, { args = { "Pekerjaan", "Tim Anda telah memulai pekerjaan kurir!" } })
        end
    end
end)
