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
    Ground = -0.9,
    Max = 0.4,
}

--- ============================
---          Functions
--- ============================

function GetEntInFrontOfPlayer(Ped)
    color = { r = 0, g = 255, b = 0, a = 200 }

    local forwardDistance = 0.6
    local heightIndex = HeightLevels.Max
    while heightIndex >= HeightLevels.Min do
        local CoB = GetOffsetFromEntityInWorldCoords(Ped, 0.0, forwardDistance, heightIndex)
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

        if hit == 1 then
            return heightIndex, hit, endCoords, surfaceNormal, materialHash, entityHit
        end

        heightIndex = heightIndex - 0.1

        Wait(1)
    end

    -- while true do
    --     local heightIndex = 2
    --     local CoA = GetEntityCoords(Ped, true)
    --     local CoB = GetOffsetFromEntityInWorldCoords(Ped, 0.0, forwardDistance, HeightLevels.Max)
    --     local RayHandle = StartExpensiveSynchronousShapeTestLosProbe(CoA.x, CoA.y, CoA.z,
    --         CoB.x, CoB.y, CoB.z, -1, Ped, 0) -- -1 = Everything
    --     local shapeTestHandle, hit, endCoords, surfaceNormal, materialHash, entityHit =
    --         GetShapeTestResultIncludingMaterial(RayHandle)

    --     DrawLine(CoA.x, CoA.y, CoA.z, CoB.x, CoB.y, CoB.z, color.r, color.g, color.b,
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

RegisterCommand('sit', function()
    local playerPed = PlayerPedId()

    -- Check if already sitting, then cancel the animation
    if isSitting then
        ClearPedTasksImmediately(playerPed)
        isSitting = false

        if IsEntityPositionFrozen(playerPed) then
            FreezeEntityPosition(playerPed, false)
        end

        return
    end

    -- Load all sit animations
    loadSitAnimations()

    -- Get if there's object in front of the ped
    local heightIndex, hit, endCoords, surfaceNormal, materialHash, entityHit = GetEntInFrontOfPlayer(playerPed)

    -- Get the current heading so the ped will turn around when sitting
    local heading = GetEntityHeading(playerPed)

    -- No ground in front, hang
    if heightIndex == nil then
        local playerCoords = GetEntityCoords(playerPed)
        local forwardCoords = playerCoords + GetEntityForwardVector(playerPed) * 0.02
        TaskStartScenarioAtPosition(playerPed, SitScenarios.PROP_HUMAN_SEAT_CHAIR,
            forwardCoords.x, forwardCoords.y, forwardCoords.z - 0.95, heading, 0, false, true)

        -- Freeze so ped doesn't fall
        FreezeEntityPosition(playerPed, true)
    elseif heightIndex <= HeightLevels.Ground then -- At ground, sit on floor
        TaskPlayAnim(playerPed, SitAnimations.floor.dictionary, SitAnimations.floor.name,
            8.0, 8.0, -1, SitAnimations.floor.flag, 0.0, false, false, false)
    elseif heightIndex == HeightLevels.Max then -- Too high, lean
        SetEntityHeading(playerPed, heading + 180)
        TaskPlayAnim(playerPed, SitAnimations.lean.dictionary, SitAnimations.lean.name,
            8.0, 8.0, -1, SitAnimations.lean.flag, 0.0, false, false, false)
    else
        print('')
        print('heightIndex: ' .. tostring(heightIndex))
        print('hit: ' .. tostring(hit))
        print('endCoords: ' ..
            tostring(endCoords.x) .. ', ' .. tostring(endCoords.y) .. ', ' .. tostring(endCoords.z))
        print('surfaceNormal: ' .. tostring(surfaceNormal))
        print('materialHash: ' .. tostring(materialHash))
        print('entityHit: ' .. tostring(entityHit))
        for key, value in pairs(MaterialHash) do
            if materialHash == value then
                print('MaterialType: ' .. tostring(key))
            end
        end
        local entityType = 0
        local entityModel = 0
        entityType = GetEntityType(entityHit)
        print('entityType: ' .. tostring(entityType))
        if hit == 1 and entityType ~= 0 then
            entityModel = GetEntityModel(entityHit)
            print('entityModel: ' .. tostring(entityModel))
        else
            print('No entity model')
        end
        print('')

        local coords = endCoords + GetEntityForwardVector(entityHit) * 0.18
        TaskStartScenarioAtPosition(playerPed, SitScenarios.PROP_HUMAN_SEAT_BENCH,
            coords.x, coords.y, coords.z + 0.03, heading + 180, 0, false, true)
    end

    -- Set setting to true
    isSitting = true
end, false)




local grabLedgeEnabled = false
local grabLedgeOnCooldown = false
RegisterCommand('grabledge', function()
    grabLedgeEnabled = not grabLedgeEnabled

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
