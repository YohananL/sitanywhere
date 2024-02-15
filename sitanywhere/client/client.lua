--- ============================
---          Constants
--- ============================

local AnimationFlags =
{
    ANIM_FLAG_REPEAT = 1,
};

local SitAnimations = {
    floor = { name = 'owner_idle', dictionary = 'anim@heists@fleeca_bank@ig_7_jetski_owner', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    lean = { name = 'idle_a', dictionary = 'amb@world_human_leaning@male@wall@back@foot_up@idle_a', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    platform = { name = 'idle_a_jimmy', dictionary = 'timetable@jimmy@mics3_ig_15@', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    hang = { name = 'base', dictionary = 'amb@prop_human_seat_chair@male@elbows_on_knees@base', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    chair = { name = 'hanging_out_operator', dictionary = 'anim@amb@business@cfm@cfm_machine_no_work@', flag = AnimationFlags.ANIM_FLAG_REPEAT },
}

local SitScenarios = {
    PROP_HUMAN_SEAT_BENCH = 'PROP_HUMAN_SEAT_BENCH',
    PROP_HUMAN_SEAT_CHAIR = 'PROP_HUMAN_SEAT_CHAIR',
    PROP_HUMAN_SEAT_CHAIR_DRINK_BEER = 'PROP_HUMAN_SEAT_CHAIR_DRINK_BEER',
    PROP_HUMAN_SEAT_CHAIR_FOOD = 'PROP_HUMAN_SEAT_CHAIR_FOOD',
    PROP_HUMAN_SEAT_CHAIR_MP_PLAYER = 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER',
}

local HeightLevels = {
    Min = -1.5,
    Ground = -0.85,
    Max = 0.4,
}

local ForwardDistance = 0.7

--- ============================
---          Functions
--- ============================

function GetEntInFrontOfPlayer(Ped)
    color = { r = 0, g = 255, b = 0, a = 200 }

    local heightIndex = HeightLevels.Max
    while heightIndex >= HeightLevels.Min do
        local CoB = GetOffsetFromEntityInWorldCoords(Ped, 0.0, ForwardDistance, heightIndex)
        local RayHandle
        if heightIndex == HeightLevels.Max then
            local CoA = GetEntityCoords(Ped, true)
            RayHandle = StartExpensiveSynchronousShapeTestLosProbe(CoA.x, CoA.y, CoB.z,
                CoB.x, CoB.y, CoB.z, -1, Ped, 0) -- -1 = Everything
        else
            RayHandle = StartExpensiveSynchronousShapeTestLosProbe(CoB.x, CoB.y, CoB.z + 0.1,
                CoB.x, CoB.y, CoB.z, -1, Ped, 0) -- -1 = Everything
        end

        local _, hit, endCoords, surfaceNormal, materialHash, entityHit =
            GetShapeTestResultIncludingMaterial(RayHandle)

        -- Ignore water
        if hit == 1 and materialHash ~= MaterialHash.Water then
            -- Ignore bushes without collision
            -- if materialHash ~= MaterialHash.Bushes or heightIndex >= -0.4 then
            --     return heightIndex, hit, endCoords, surfaceNormal, materialHash, entityHit
            -- end

            return heightIndex, hit, endCoords, surfaceNormal, materialHash, entityHit
        end

        heightIndex = heightIndex - 0.1

        Wait(1)
    end

    -- while true do
    --     local heightIndex = -0.7
    --     local CoA = GetEntityCoords(Ped, true)
    --     local CoB = GetOffsetFromEntityInWorldCoords(Ped, 0.0, ForwardDistance, heightIndex)
    --     local RayHandle = StartExpensiveSynchronousShapeTestLosProbe(CoB.x, CoB.y, CoB.z + 0.1,
    --         CoB.x, CoB.y, CoB.z, -1, Ped, 0) -- -1 = Everything
    --     local shapeTestHandle, hit, endCoords, surfaceNormal, materialHash, entityHit =
    --         GetShapeTestResultIncludingMaterial(RayHandle)

    --     DrawLine(CoB.x, CoB.y, CoB.z + 0.1, CoB.x, CoB.y, CoB.z, color.r, color.g, color.b,
    --         color.a)
    --     DrawMarker(28, CoB.x, CoB.y, CoB.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r,
    --         color.g, color.b, color.a, false, true, 2, nil, nil, false, false)

    --     if IsControlJustReleased(0, 38) then
    --         print(hit)
    --         return heightIndex, hit, endCoords, surfaceNormal, materialHash, entityHit
    --     end

    --     Wait(1)
    -- end
end

function GetDistanceFromEdge(Ped)
    color = { r = 0, g = 255, b = 0, a = 200 }

    local floorDistance = ForwardDistance
    local zOffSet = 1.0
    while floorDistance >= 0.0 do
        local CoB = GetOffsetFromEntityInWorldCoords(Ped, 0.0, floorDistance, HeightLevels.Min)
        local RayHandle = StartExpensiveSynchronousShapeTestLosProbe(CoB.x, CoB.y, CoB.z + zOffSet,
            CoB.x, CoB.y, CoB.z, -1, Ped, 0) -- -1 = Everything

        local _, hit, _, _, materialHash, _ = GetShapeTestResultIncludingMaterial(RayHandle)

        if hit == 1 or materialHash == MaterialHash.Water then
            return floorDistance
        end

        floorDistance = floorDistance - 0.1

        Wait(1)
    end

    -- while true do
    --     local CoB = GetOffsetFromEntityInWorldCoords(Ped, 0.0, floorDistance, HeightLevels.Min)
    --     local RayHandle = StartExpensiveSynchronousShapeTestLosProbe(CoB.x, CoB.y, CoB.z + zOffSet,
    --         CoB.x, CoB.y, CoB.z, -1, Ped, 0) -- -1 = Everything

    --     local _, hit, endCoords, _, _, _ = GetShapeTestResultIncludingMaterial(RayHandle)

    --     DrawLine(CoB.x, CoB.y, CoB.z + zOffSet, CoB.x, CoB.y, CoB.z, color.r, color.g, color.b,
    --         color.a)
    --     DrawMarker(28, CoB.x, CoB.y, CoB.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r,
    --         color.g, color.b, color.a, false, true, 2, nil, nil, false, false)

    --     if IsControlJustReleased(0, 38) then
    --         print(hit)
    --         return forwardDistance, hit, endCoords, _, _, _
    --     end

    --     Wait(1)
    -- end
end

function requestAnimation(dictionary)
    RequestAnimDict(dictionary)
    repeat
        Wait(100)
    until HasAnimDictLoaded(dictionary)

    return true
end

function loadSitAnimations()
    for _, value in pairs(SitAnimations) do
        if not (HasAnimDictLoaded(value.dictionary)) then
            requestAnimation(value.dictionary)
        end
    end
end

function loadModel(modelHash)
    RequestModel(modelHash)
    repeat
        Wait(100)
    until HasModelLoaded(modelHash)
end

--- ============================
---          Commands
--- ============================

local isSitting = false

RegisterCommand('sit', function(_, args, _)
    local playerPed = PlayerPedId()

    -- Check if already sitting, then cancel the animation
    if isSitting then
        -- Clear tasks
        ClearPedTasksImmediately(playerPed)

        -- Unfreeze if frozen
        if IsEntityPositionFrozen(playerPed) then
            FreezeEntityPosition(playerPed, false)
        end

        -- Reset isSitting property
        isSitting = false

        return
    end

    -- Load all sit animations
    loadSitAnimations()

    -- Get if there's object in front of the ped
    local heightIndex, hit, endCoords, surfaceNormal, materialHash, entityHit = GetEntInFrontOfPlayer(playerPed)

    print('heightIndex: ' .. tostring(heightIndex))

    -- Get the current heading so the ped will turn around when sitting
    local heading = GetEntityHeading(playerPed)

    -- No ground in front
    if heightIndex == nil then
        -- Get the distance of the ped from the edge of the floor
        local floorDistance = GetDistanceFromEdge(playerPed) or 0.0
        print(string.format('floorDistance: %2f', floorDistance))

        local forwardMultiplier
        if floorDistance >= -0.01 and floorDistance <= 0.01 then
            forwardMultiplier = -0.25
        elseif floorDistance >= 0.09 and floorDistance <= 0.11 then
            forwardMultiplier = -0.12
        elseif floorDistance >= 0.19 and floorDistance <= 0.21 then
            forwardMultiplier = -0.05
        elseif floorDistance >= 0.29 and floorDistance <= 0.31 then
            forwardMultiplier = 0.05
        elseif floorDistance >= 0.39 and floorDistance <= 0.41 then
            forwardMultiplier = 0.1
        elseif floorDistance >= 0.49 and floorDistance <= 0.51 then
            forwardMultiplier = 0.27
        elseif floorDistance >= 0.59 and floorDistance <= 0.61 then
            forwardMultiplier = 0.38
        end

        print('forwardMultiplier: ' .. tostring(forwardMultiplier))

        -- Move the ped forward based on the distance from the edge
        local playerCoords = GetEntityCoords(playerPed)
        local forwardCoords = playerCoords + GetEntityForwardVector(playerPed) * forwardMultiplier

        -- Sit from ledge
        TaskStartScenarioAtPosition(playerPed, SitScenarios.PROP_HUMAN_SEAT_CHAIR,
            forwardCoords.x, forwardCoords.y, forwardCoords.z - 0.94, heading, 0, false, true)
    elseif heightIndex <= HeightLevels.Ground then
        -- At ground, sit on floor
        TaskPlayAnim(playerPed, SitAnimations.floor.dictionary, SitAnimations.floor.name,
            8.0, 8.0, -1, SitAnimations.floor.flag, 0.0, false, false, false)
    elseif heightIndex == HeightLevels.Max then
        -- Too high, lean
        SetEntityHeading(playerPed, heading + 180)
        TaskPlayAnim(playerPed, SitAnimations.lean.dictionary, SitAnimations.lean.name,
            8.0, 8.0, -1, SitAnimations.lean.flag, 0.0, false, false, false)
    else
        -- print('')
        -- print('hit: ' .. tostring(hit))
        -- print('endCoords: ' ..
        --     tostring(endCoords.x) .. ', ' .. tostring(endCoords.y) .. ', ' .. tostring(endCoords.z))
        -- print('surfaceNormal: ' .. tostring(surfaceNormal))
        -- print('materialHash: ' .. tostring(materialHash))
        -- print('entityHit: ' .. tostring(entityHit))
        -- for key, value in pairs(MaterialHash) do
        --     if materialHash == value then
        --         print('MaterialType: ' .. tostring(key))
        --     end
        -- end
        -- local entityType = 0
        -- local entityModel = 0
        -- entityType = GetEntityType(entityHit)
        -- print('entityType: ' .. tostring(entityType))
        -- if hit == 1 and entityType ~= 0 then
        --     entityModel = GetEntityModel(entityHit)
        --     print('entityModel: ' .. tostring(entityModel))
        -- else
        --     print('No entity model')
        -- end
        -- print('')

        local zOffset = 0.03


        -- Sit normally, check if chair is specified
        if GetEntityType(entityHit) ~= 0 and args[1] ~= nil then
            -- Get the heading of the chair entity
            heading = GetEntityHeading(entityHit)

            -- If chair, get the coords of the chair
            if args[1] == 'chair' then
                -- Set the end coords to the coords of the entity
                endCoords = GetEntityCoords(entityHit)

                -- Sit further back in the chair
                endCoords = endCoords + GetEntityForwardVector(entityHit) * 0.1

                -- Use the zOffset for chairs
                zOffset = 0.0
            end

            -- If bench,
            if args[1] == 'bench' then
                -- Sit further in front of the bench
                endCoords = endCoords + GetEntityForwardVector(entityHit) * -0.11
            end
        end

        -- Make ped sit in the opposite direction
        heading = heading + 180

        TaskStartScenarioAtPosition(playerPed, SitScenarios.PROP_HUMAN_SEAT_BENCH,
            endCoords.x, endCoords.y, endCoords.z + zOffset, heading, 0, false, true)
    end

    -- -- Freeze so ped doesn't fall
    -- FreezeEntityPosition(playerPed, true)

    -- Set setting to true
    isSitting = true
end, false)

--- ============================
---          Grab Ledge
--- ============================

local grabLedgeEnabled = false
RegisterCommand('grabledge', function()
    grabLedgeEnabled = not grabLedgeEnabled

    local grabLedgeOnCooldown = false
    CreateThread(function()
        while grabLedgeEnabled do
            playerPed = PlayerPedId()

            if IsControlJustPressed(0, 22) then
                if IsPedJumping(playerPed) and not grabLedgeOnCooldown then
                    TaskClimb(playerPed, false)
                    grabLedgeOnCooldown = true
                end
            end

            if grabLedgeOnCooldown then
                Wait(1000)
                grabLedgeOnCooldown = false
            end

            Wait(0)
        end
    end)
end, false)
