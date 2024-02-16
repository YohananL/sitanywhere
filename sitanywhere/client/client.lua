--- ============================
---          Constants
--- ============================

local AnimationFlags =
{
    ANIM_FLAG_REPEAT = 1,
};

local SitAnimations = {
    hang = { name = 'base', dictionary = 'amb@world_human_seat_wall@male@hands_by_sides@base', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    floor = { name = 'owner_idle', dictionary = 'anim@heists@fleeca_bank@ig_7_jetski_owner', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    chair = { name = 'hanging_out_operator', dictionary = 'anim@amb@business@cfm@cfm_machine_no_work@', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    platform = { name = 'idle_a_jimmy', dictionary = 'timetable@jimmy@mics3_ig_15@', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    lean = { name = 'idle_a', dictionary = 'amb@world_human_leaning@male@wall@back@foot_up@idle_a', flag = AnimationFlags.ANIM_FLAG_REPEAT },
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
        if not HasAnimDictLoaded(value.dictionary) then
            requestAnimation(value.dictionary)
        end
    end
end

function unloadSitAnimations()
    for _, value in pairs(SitAnimations) do
        RemoveAnimDict(value.dictionary)
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
        -- Clear tasks
        ClearPedTasksImmediately(playerPed)

        -- Unfreeze if frozen
        if IsEntityPositionFrozen(playerPed) then
            FreezeEntityPosition(playerPed, false)
        end

        -- Unload all sit animations
        unloadSitAnimations()

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
            forwardMultiplier = -0.17
        elseif floorDistance >= 0.09 and floorDistance <= 0.11 then
            forwardMultiplier = -0.07
        elseif floorDistance >= 0.19 and floorDistance <= 0.21 then
            forwardMultiplier = 0.00
        elseif floorDistance >= 0.29 and floorDistance <= 0.31 then
            forwardMultiplier = 0.10
        elseif floorDistance >= 0.39 and floorDistance <= 0.41 then
            forwardMultiplier = 0.18
        elseif floorDistance >= 0.49 and floorDistance <= 0.51 then
            forwardMultiplier = 0.29
        elseif floorDistance >= 0.59 and floorDistance <= 0.61 then
            forwardMultiplier = 0.41
        elseif floorDistance >= 0.69 and floorDistance <= 0.71 then
            forwardMultiplier = 0.45
        end

        print('forwardMultiplier: ' .. tostring(forwardMultiplier))

        -- Move the ped forward based on the distance from the edge
        local playerCoords = GetEntityCoords(playerPed)
        local forwardCoords = playerCoords + GetEntityForwardVector(playerPed) * forwardMultiplier

        -- Sit from ledge
        TaskPlayAnimAdvanced(playerPed, SitAnimations.hang.dictionary, SitAnimations.hang.name,
            forwardCoords.x, forwardCoords.y, forwardCoords.z - 0.65,
            0.0, 0.0, GetEntityHeading(playerPed),
            8.0, 8.0, -1, SitAnimations.hang.flag, 0.0, false, false, false)

        -- Freeze so ped doesn't fall
        FreezeEntityPosition(playerPed, true)
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
        -- Make ped sit in the opposite direction
        heading = heading + 180

        -- Sit down
        TaskStartScenarioAtPosition(playerPed, SitScenarios.PROP_HUMAN_SEAT_BENCH,
            endCoords.x, endCoords.y, endCoords.z + 0.03, heading, 0, false, true)
    end

    -- Set setting to true
    isSitting = true
end, false)

--- ============================
---           Smoking
--- ============================

RegisterCommand('smokeInPlace', function()
    local playerPed = PlayerPedId()
    local smokeScenario = 'WORLD_HUMAN_SMOKING_CLUBHOUSE'

    if IsPedUsingScenario(playerPed, smokeScenario) then
        ClearPedTasks(playerPed)
        return
    end

    TaskStartScenarioInPlace(playerPed, smokeScenario, 0, true)
end, false)

-- Cigarette hash and entity id
local cigHash = `ng_proc_cigarette01a`
local cigObj = 0

-- Smoke animation
local SmokeAnimations = {
    smoke = { name = 'base', dictionary = 'amb@world_human_smoking@male@male_a@base', flag = 49 },
    exit = { name = 'exit', dictionary = 'amb@world_human_smoking@male@male_a@exit', flag = 48 },
}

-- Load all smoke animations
function loadSmokeAnimations()
    for _, value in pairs(SmokeAnimations) do
        if not HasAnimDictLoaded(value.dictionary) then
            requestAnimation(value.dictionary)
        end
    end
end

-- Unload all smoke animations
function unloadSmokeAnimations()
    for _, value in pairs(SmokeAnimations) do
        RemoveAnimDict(value.dictionary)
    end
end

-- Smoke effects
local cigParticleAsset = 'scr_mp_cig'
local cigParticleName = 'ent_anim_cig_smoke'
local cigParticleName2 = 'ent_anim_cig_exhale_mth'
local cigParticleHandle = 0

local isSmoking = false

RegisterCommand('smoke', function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    -- Check if already smoking
    if isSmoking then
        -- Stop the smoking animation
        StopEntityAnim(playerPed, SmokeAnimations.smoke.name, SmokeAnimations.smoke.dictionary, 0)

        -- Stop the particle animations
        StopParticleFxLooped(cigParticleHandle, false)

        -- Remove the asset after use
        RemoveNamedPtfxAsset(cigParticleAsset)

        -- Do the exit smoke animation
        TaskPlayAnim(playerPed, SmokeAnimations.exit.dictionary, SmokeAnimations.exit.name,
            8.0, 8.0, -1, SmokeAnimations.exit.flag, 0.0, false, false, false)

        -- Wait halfway through the animation before detaching
        Wait(GetAnimDuration(SmokeAnimations.exit.dictionary, SmokeAnimations.exit.name) * 600)

        -- Detach the cigarette
        DetachEntity(cigObj, true, true)

        -- Wait a second for cigarette to drop to the ground
        Wait(1000)

        -- Delete the cigarette object
        DeleteEntity(cigObj)

        -- Unload all smoking animations
        unloadSmokeAnimations()

        -- Reset the isSmoking property
        isSmoking = false

        return
    end

    -- Load the smoke animation
    loadSmokeAnimations()

    -- Load and create the cigarette object
    loadModel(cigHash)
    cigObj = CreateObject(cigHash, playerCoords.x, playerCoords.y, playerCoords.z, true,
        true, false)
    SetModelAsNoLongerNeeded(cigHash)

    -- Attach the cigarette to the player's right index finger
    AttachEntityToEntity(cigObj, playerPed, GetEntityBoneIndexByName(playerPed, 'BONETAG_R_FINGER11'),
        0.0, 0.02, -0.01, 0.0, 0.0, 70.0,
        true, true, false, false, 2, true)

    -- Do the smoke animation
    TaskPlayAnim(playerPed, SmokeAnimations.smoke.dictionary, SmokeAnimations.smoke.name,
        8.0, 8.0, -1, SmokeAnimations.smoke.flag, 0.0, false, false, false)

    -- Load the asset
    RequestNamedPtfxAsset(cigParticleAsset)
    repeat
        Wait(0)
    until HasNamedPtfxAssetLoaded(cigParticleAsset)

    -- Use the asset
    UseParticleFxAsset(cigParticleAsset)

    -- Start the particle looped animation on the cigarette
    cigParticleHandle = StartNetworkedParticleFxLoopedOnEntity(cigParticleName, cigObj,
        -0.06, 0.0, 0.0, 0.0, 0.0, 70.0, 1.5,
        true, true, true)

    -- -- Start the particle looped animation on the ped's mouth
    -- StartNetworkedParticleFxNonLoopedOnEntityBone(cigParticleName2, playerPed,
    --     0.05, 0.0, 0.0, 0.0, 0.0, 0.0, GetPedBoneIndex(playerPed, 0xB987), 2.0,
    --     true, true, true)

    -- Set isSmoking to true
    isSmoking = true
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
