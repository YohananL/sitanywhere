--- ============================
---          Constants
--- ============================

local SitScenarios = {
    PROP_HUMAN_SEAT_BENCH = 'PROP_HUMAN_SEAT_BENCH',
    PROP_HUMAN_SEAT_CHAIR = 'PROP_HUMAN_SEAT_CHAIR',
    PROP_HUMAN_SEAT_CHAIR_MP_PLAYER = 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER',
    WORLD_HUMAN_SEAT_LEDGE = 'WORLD_HUMAN_SEAT_LEDGE',
    WORLD_HUMAN_SEAT_STEPS = 'WORLD_HUMAN_SEAT_STEPS',
    WORLD_HUMAN_LEANING = 'WORLD_HUMAN_LEANING',
    WORLD_HUMAN_PICNIC = 'WORLD_HUMAN_PICNIC',
}

local HeightLevels = {
    Min = -1.5,
    Ground = -0.90,
    Steps = -0.65,
    Max = 0.4,
}

local ForwardDistance = 0.60

local TraceFlag = 1 | 2 | 4 | 16 -- World | Vehicles | PedSimpleCollision | Objects

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
            RayHandle = StartShapeTestRay(CoA.x, CoA.y, CoB.z, CoB.x, CoB.y, CoB.z, TraceFlag, Ped, 0)
        else
            RayHandle = StartShapeTestRay(CoB.x, CoB.y, CoB.z + 0.1, CoB.x, CoB.y, CoB.z, TraceFlag, Ped, 0)
        end

        local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(RayHandle)

        -- while true do
        --     DrawLine(CoB.x, CoB.y, CoB.z + 0.1, CoB.x, CoB.y, CoB.z, color.r, color.g, color.b,
        --         color.a)
        --     DrawMarker(28, CoB.x, CoB.y, CoB.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r,
        --         color.g, color.b, color.a, false, true, 2, nil, nil, false, false)
        --     if IsControlJustReleased(0, 38) then
        --         break
        --     end
        --     Wait(0)
        -- end

        if hit == 1 then
            return heightIndex, hit, endCoords, surfaceNormal, _, entityHit
        end

        heightIndex = heightIndex - 0.1

        Wait(1)
    end
end

function GetDistanceFromTarget(Ped, heightIndex, isLedge)
    color = { r = 0, g = 255, b = 0, a = 200 }

    local CoA = GetOffsetFromEntityInWorldCoords(Ped, 0.0, -ForwardDistance, heightIndex)
    local CoB = GetOffsetFromEntityInWorldCoords(Ped, 0.0, ForwardDistance, heightIndex)
    if isLedge then
        RayHandle = StartShapeTestRay(CoB.x, CoB.y, CoB.z, CoA.x, CoA.y, CoB.z, TraceFlag, Ped, 0)
    else
        RayHandle = StartShapeTestRay(CoA.x, CoA.y, CoB.z, CoB.x, CoB.y, CoB.z, TraceFlag, Ped, 0)
    end

    local _, _, endCoords, _, _ = GetShapeTestResult(RayHandle)

    -- while true do
    --     DrawLine(CoA.x, CoA.y, CoB.z, CoB.x, CoB.y, CoB.z, color.r, color.g, color.b,
    --         color.a)
    --     DrawMarker(28, CoB.x, CoB.y, CoB.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, color.r,
    --         color.g, color.b, color.a, false, true, 2, nil, nil, false, false)
    --     if IsControlJustReleased(0, 38) then
    --         break
    --     end
    --     Wait(0)
    -- end

    return endCoords
end

function loadModel(modelHash)
    RequestModel(modelHash)
    repeat
        Wait(1)
    until HasModelLoaded(modelHash)
end

--- ============================
---          Commands
--- ============================

local isSitting = false
local shouldResetCoords = false

RegisterKeyMapping('+sit', 'Sit', 'keyboard', Config.Settings.sitKeyBind)
RegisterCommand('+sit', function()
    local playerPed = PlayerPedId()

    -- Check if already sitting, then cancel the animation
    if isSitting then
        -- Clear tasks
        ClearPedTasksImmediately(playerPed)

        if shouldResetCoords then
            local playerCoords = GetEntityCoords(playerPed)
            SetEntityCoords(playerPed, playerCoords.x, playerCoords.y, playerCoords.z + 0.1, true, false, false, false)
            shouldResetCoords = false
        end

        -- Unfreeze if frozen
        if IsEntityPositionFrozen(playerPed) then
            FreezeEntityPosition(playerPed, false)
        end

        -- Reset isSitting property
        isSitting = false
        return
    end

    -- Get if there's object in front of the ped
    local heightIndex, _, endCoords, _, _, _ = GetEntInFrontOfPlayer(playerPed)

    -- Get the current heading so the ped will turn around when sitting
    local heading = GetEntityHeading(playerPed)

    -- No ground in front
    if heightIndex == nil then
        -- Sit from ledge
        local _, _, z = table.unpack(GetEntityCoords(playerPed))
        local zOffset = 1.0312
        local ledgeCoords = GetDistanceFromTarget(playerPed, -1.02, true)
        local forwardCoords = ledgeCoords - GetEntityForwardVector(playerPed) * 0.30
        TaskStartScenarioAtPosition(playerPed, SitScenarios.WORLD_HUMAN_SEAT_LEDGE,
            forwardCoords.x, forwardCoords.y, z - zOffset, heading, 0, false, true)

        -- Freeze so ped doesn't fall
        FreezeEntityPosition(playerPed, true)
        shouldResetCoords = true
    elseif heightIndex <= HeightLevels.Steps and heightIndex > HeightLevels.Ground then
        -- Sit on steps
        heading = heading + 180
        local targetCoords = GetDistanceFromTarget(playerPed, heightIndex, false)
        local forwardCoords = targetCoords + GetEntityForwardVector(playerPed) * 0.05
        TaskStartScenarioAtPosition(playerPed, SitScenarios.WORLD_HUMAN_SEAT_STEPS,
            forwardCoords.x, forwardCoords.y, endCoords.z + 0.01, heading, 0, false, true)
    elseif heightIndex <= HeightLevels.Ground then
        -- At ground, sit on floor
        TaskStartScenarioInPlace(playerPed, SitScenarios.WORLD_HUMAN_PICNIC, 0, false)
    elseif heightIndex == HeightLevels.Max then
        -- Too high, lean
        heading = heading + 180
        local playerCoords = GetEntityCoords(playerPed)
        local forwardCoords = endCoords - GetEntityForwardVector(playerPed) * 0.3
        TaskStartScenarioAtPosition(playerPed, SitScenarios.WORLD_HUMAN_LEANING,
            forwardCoords.x, forwardCoords.y, playerCoords.z, heading, 0, false, true)
    else
        -- Sit in chair
        heading = heading + 180
        local targetCoords = GetDistanceFromTarget(playerPed, heightIndex, false)
        local forwardCoords = targetCoords + GetEntityForwardVector(playerPed) * 0.35
        TaskStartScenarioAtPosition(playerPed, SitScenarios.PROP_HUMAN_SEAT_BENCH,
            forwardCoords.x, forwardCoords.y, endCoords.z + 0.03, heading, 0, false, true)

        shouldResetCoords = true
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
        0.01, 0.01, -0.01, -30.0, -15.0, 75.0,
        true, true, false, false, 2, true)

    -- Load the asset
    RequestNamedPtfxAsset(cigParticleAsset)
    repeat
        Wait(0)
    until HasNamedPtfxAssetLoaded(cigParticleAsset)

    -- Specify the asset before starting the particle
    UseParticleFxAsset(cigParticleAsset)

    -- Start the particle looped animation on the cigarette
    cigParticleHandle = StartNetworkedParticleFxLoopedOnEntity(cigParticleName, cigObj,
        -0.07, 0.0, 0.0, 0.0, 0.0, 0.0, 1.5,
        true, true, true)

    -- Do the smoke animation
    TaskPlayAnim(playerPed, SmokeAnimations.smoke.dictionary, SmokeAnimations.smoke.name,
        8.0, 8.0, -1, SmokeAnimations.smoke.flag, 0.0, false, false, false)

    -- Thread for smoke coming out of ped's mouth
    CreateThread(function()
        local smokeAnimTime = GetAnimDuration(SmokeAnimations.smoke.dictionary, SmokeAnimations.smoke.name)
        while isSmoking do
            -- Wait until ped blows smoke
            Wait(smokeAnimTime * 825)

            -- Specify the asset before starting the particle
            UseParticleFxAsset(cigParticleAsset)

            -- Start the particle looped animation on the ped's mouth
            StartNetworkedParticleFxNonLoopedOnEntityBone(cigParticleName2, playerPed,
                0.1, 0.0, 0.0, 0.0, 0.0, 0.0, GetPedBoneIndex(playerPed, 0xB987), 2.0,
                true, true, true)

            -- Wait until animation reset
            Wait(smokeAnimTime * 175)
        end
    end)

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
