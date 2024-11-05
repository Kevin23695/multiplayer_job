-- Client.lua

local isOnJob = false
local teamMembers = {} -- Daftar anggota tim
local currentDeliveryLocation = nil
local lastJobTime = 0

-- Fungsi untuk mendeteksi pemain lain di sekitar dan mengirim undangan
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        -- Hanya pemimpin tim yang bisa mengundang
        if not isOnJob and #teamMembers < Config.MaxTeamSize then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local closestPlayer, closestDistance = GetClosestPlayer()

            -- Jika ada pemain terdekat dalam jarak 3 meter, tampilkan opsi undangan
            if closestPlayer ~= -1 and closestDistance < 3.0 then
                DrawText3D(playerCoords.x, playerCoords.y, playerCoords.z + 1.0, "[E] Undang pemain ke tim")
                
                if IsControlJustPressed(0, 38) then -- Tekan E
                    local playerServerId = GetPlayerServerId(closestPlayer)
                    TriggerServerEvent("job:invitePlayer", playerServerId)
                end
            end
        end
    end
end)

-- Fungsi untuk mendapatkan pemain terdekat
function GetClosestPlayer()
    local players = GetActivePlayers()
    local closestPlayer = -1
    local closestDistance = -1
    local ply = PlayerPedId()
    local plyCoords = GetEntityCoords(ply, 0)

    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local target = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(target, 0)
            local distance = #(plyCoords - targetCoords)

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = player
                closestDistance = distance
            end
        end
    end

    return closestPlayer, closestDistance
end

-- Fungsi untuk menerima undangan
RegisterNetEvent("job:receiveInvite")
AddEventHandler("job:receiveInvite", function(leaderId)
    print("Anda telah diundang ke tim oleh pemain ID " .. leaderId .. ". Tekan [E] untuk menerima.")

    Citizen.CreateThread(function()
        local timeout = 10000 -- Undangan berlaku 10 detik
        local startTime = GetGameTimer()

        while (GetGameTimer() - startTime) < timeout do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 38) then -- Tekan E untuk menerima
                TriggerServerEvent("job:acceptInvite", leaderId)
                return
            end
        end

        print("Undangan telah kadaluarsa.")
    end)
end)

-- Memulai pekerjaan bersama anggota tim
function StartJob()
    if (GetGameTimer() - lastJobTime) < (Config.JobCooldown * 1000) then
        print("Tunggu beberapa saat sebelum memulai pekerjaan baru.")
        return
    end
    
    isOnJob = true
    lastJobTime = GetGameTimer()
    SetNewDeliveryLocation()
    print("Anda dan tim Anda telah memulai pekerjaan sebagai kurir. Pergi ke lokasi tujuan!")

    -- Notifikasi ke semua anggota tim bahwa pekerjaan telah dimulai
    TriggerServerEvent("job:notifyTeamStart")
end


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isOnJob and currentDeliveryLocation then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(currentDeliveryLocation.x, currentDeliveryLocation.y, currentDeliveryLocation.z))

            if distance < 5.0 then
                DrawText3D(currentDeliveryLocation.x, currentDeliveryLocation.y, currentDeliveryLocation.z, "[E] Untuk mengantarkan paket")

                if IsControlJustPressed(0, 38) then -- Key E
                    CompleteDelivery()
                end
            end
        end
    end
end)

function SetNewDeliveryLocation()
    local randomIndex = math.random(1, #Config.DeliveryLocations)
    currentDeliveryLocation = Config.DeliveryLocations[randomIndex]
    SetNewWaypoint(currentDeliveryLocation.x, currentDeliveryLocation.y)
end

function CompleteDelivery()
    print("Pengantaran selesai! Anda dan tim Anda menerima $" .. Config.DeliveryPay)
    TriggerServerEvent("job:payTeam")
    isOnJob = false
    currentDeliveryLocation = nil
end

function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end
