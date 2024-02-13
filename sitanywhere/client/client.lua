--- ============================
---          Constants
--- ============================

local AnimationFlags =
{
    ANIM_FLAG_REPEAT = 1,
};

local SitAnimations = {
    -- base = { name = 'base', dictionary = 'amb@prop_human_seat_chair_mp@male@generic@base', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    -- floor = { name = 'sit_phone_phonepickup_nowork', dictionary = 'anim@amb@business@bgen@bgen_no_work@', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    floor = { name = 'owner_idle', dictionary = 'anim@heists@fleeca_bank@ig_7_jetski_owner', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    lean = { name = 'idle_a', dictionary = 'amb@world_human_leaning@male@wall@back@foot_up@idle_a', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    hang = { name = 'idle_a_jimmy', dictionary = 'timetable@jimmy@mics3_ig_15@', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    -- hang = { name = 'intro_loop_ped_a', dictionary = 'anim@heists@fleeca_bank@hostages@intro', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    -- hang = { name = 'base', dictionary = 'timetable@maid@couch@', flag = AnimationFlags.ANIM_FLAG_REPEAT },
    chair = { name = 'hanging_out_operator', dictionary = 'anim@amb@business@cfm@cfm_machine_no_work@', flag = AnimationFlags.ANIM_FLAG_REPEAT },
}

local SitScenarios = {
    PROP_HUMAN_SEAT_BENCH = 'PROP_HUMAN_SEAT_BENCH',
    PROP_HUMAN_SEAT_CHAIR = 'PROP_HUMAN_SEAT_CHAIR',
    PROP_HUMAN_SEAT_CHAIR_DRINK_BEER = 'PROP_HUMAN_SEAT_CHAIR_DRINK_BEER',
    PROP_HUMAN_SEAT_CHAIR_FOOD = 'PROP_HUMAN_SEAT_CHAIR_FOOD',
    PROP_HUMAN_SEAT_CHAIR_MP_PLAYER = 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER',
}
--- ============================
---          Functions
--- ============================

function GetEntInFrontOfPlayer(Ped, Distance)
    local Ent = nil
    local CoA = GetEntityCoords(Ped, true)
    local CoB = GetOffsetFromEntityInWorldCoords(Ped, 0.0, Distance, 0.0)
    local RayHandle = StartExpensiveSynchronousShapeTestLosProbe(CoA.x, CoA.y, CoA.z,
        CoB.x, CoB.y, CoB.z - 0.5, -- Look down
        16, Ped, 0)                -- 16 = Objects
    local A, B, C, D, Ent = GetRaycastResult(RayHandle)
    return Ent
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
    -- Request the model and wait for it to load
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
        ClearPedTasks(playerPed)
        isSitting = false
        return
    end

    -- Load all sit animations
    loadSitAnimations()

    -- Stores the coordinates the ped will sit in
    local x, y, z

    -- Get if there's object in front of the ped
    local obj = GetEntInFrontOfPlayer(playerPed, 5.0)

    -- Get the current heading so the ped will turn around when sitting
    local heading = GetEntityHeading(playerPed)

    -- If there's an object in front of the player
    if obj ~= 0 then
        -- Get the object hash
        local objHash = GetEntityModel(obj)
        -- Get the object max dimensions
        local _, objMaxDimensions = GetModelDimensions(objHash)
        -- Set the coordinates to sit on
        x, y, z = table.unpack(GetEntityCoords(obj))
        -- Add the object height to the z dimension
        z = z + objMaxDimensions.z

        print('Object height: ' .. tostring(objMaxDimensions.z))

        -- Check if object is low, sit on it like a chair
        if objMaxDimensions.z < 1.0 then
            -- Sit using scenario, reduce z and make ped turn around
            TaskStartScenarioAtPosition(playerPed, SitScenarios.PROP_HUMAN_SEAT_BENCH,
                x, y, z - 0.5, heading + 180, 0, false, true)
        elseif objMaxDimensions.z < 1.5 then -- Check if height is reachable enough to climb and sit on
            -- Set the ped to the object coords with increased height
            SetEntityCoords(playerPed, x, y, z, true, false, false, false)
            -- Make the player turn around
            SetEntityHeading(playerPed, heading + 180)
            -- Sit while on top of the object
            TaskPlayAnim(playerPed, SitAnimations.floor.dictionary, SitAnimations.floor.name,
                8.0, 8.0, -1, SitAnimations.floor.flag, 0.0, false, false, false)
        else -- Check if height is too high to sit on (e.g. post)
            -- Make the player turn around
            SetEntityHeading(playerPed, heading + 180)
            -- Lean on the object
            TaskPlayAnim(playerPed, SitAnimations.lean.dictionary, SitAnimations.lean.name,
                8.0, 8.0, -1, SitAnimations.lean.flag, 0.0, false, false, false)
        end

        -- Set sitting to true
        isSitting = true

        -- Return and stop execution
        return
    end

    -- No object, create an object in front of the player to get the ground coordinates
    -- Get the player forward coords
    local playerCoords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local forwardCoords = playerCoords + forward * 0.5

    -- Load object
    local objHash = `prop_tool_blowtorch`
    loadModel(objHash)
    -- Create object in front of player with increased z dimension
    obj = CreateObject(objHash, forwardCoords.x, forwardCoords.y, forwardCoords.z + 1.0, false, false, false)
    -- Place the object on the ground
    PlaceObjectOnGroundProperly(obj)
    -- Get the object's coordinates
    x, y, z = table.unpack(GetEntityCoords(obj))
    -- Delete the object
    DeleteEntity(obj)

    -- print('Player coords: ' .. tostring(playerCoords.z))
    -- print('Obj coords: ' .. tostring(z))

    local zDifference = z - playerCoords.z
    print('zDifference: ' .. tostring(zDifference))

    -- Check if no ground in front
    if zDifference <= -2.0 then
        -- Sit in spot without moving and turning
        TaskPlayAnim(playerPed, SitAnimations.hang.dictionary, SitAnimations.hang.name,
            8.0, 8.0, -1, SitAnimations.hang.flag, 0.0, false, false, false)
    elseif zDifference <= -0.55 then -- Check if only ground in front
        -- Sit in spot without moving and turning
        TaskPlayAnim(playerPed, SitAnimations.floor.dictionary, SitAnimations.floor.name,
            8.0, 8.0, -1, SitAnimations.floor.flag, 0.0, false, false, false)
    elseif zDifference < 0.1 then -- Check if a higher platform in ront
        -- Set the ped to the object coords with increased height
        SetEntityCoords(playerPed, x, y, z, true, false, false, false)
        -- Make the player turn around
        SetEntityHeading(playerPed, heading + 180)
        -- Sit while on top of platform
        TaskPlayAnim(playerPed, SitAnimations.floor.dictionary, SitAnimations.floor.name,
            8.0, 8.0, -1, SitAnimations.floor.flag, 0.0, false, false, false)
    else -- Check if wall in front
        -- Make the player turn around
        SetEntityHeading(playerPed, heading + 180)
        -- Lean on the object
        TaskPlayAnim(playerPed, SitAnimations.lean.dictionary, SitAnimations.lean.name,
            8.0, 8.0, -1, SitAnimations.lean.flag, 0.0, false, false, false)
    end

    -- Set setting to true
    isSitting = true
end, false)
