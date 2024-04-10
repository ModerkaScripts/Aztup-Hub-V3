local function print() end;
local function warn() end;

print('waiting for shared.require');
repeat task.wait(); until getrenv().shared.require;

local function SX_VM_CNONE() end;

local Debris = game:GetService('Debris');
local Players = game:GetService('Players');

local LocalPlayer = Players.LocalPlayer;
local commEvent = getgenv().syn.get_comm_channel(...);

local requireCache = rawget(getupvalue(getrenv().shared.require, 1), '_cache');
assert(requireCache);

print('waiting for game scan');

local network, effect, particle;

repeat
    for _, v in next, getgc(true) do
        if type(v) == 'table' then
            if rawget(v, 'send') then
                network = v;
            elseif rawget(v, 'bullethit') then
                effect = v;
            elseif rawget(v, 'new') and rawget(v, 'step') and rawget(v, 'reset') then
                particle = v;
            end;
        end;
    end;
    task.wait();
until network and effect and particle;

local flags = {};
local gunModMaid = {};

local function gameRequire(moduleName)
    print('waiting for', moduleName);

    repeat
        task.wait()
    until requireCache[moduleName] and requireCache[moduleName].module;

    return requireCache[moduleName].module;
end;

-- Replication
local repInterface = gameRequire('ReplicationInterface');

-- Character
local characterInterface = gameRequire('CharacterInterface');
local characterEvents = gameRequire('CharacterEvents');
local characterObject = gameRequire('CharacterObject');

-- Weapons
local weaponControllerInterface = gameRequire('WeaponControllerInterface');
local weaponControllerEvents = gameRequire('WeaponControllerEvents');

-- Game UI
local menuScreenGui = gameRequire('MenuScreenGui');
local weaponController;

local function updateAllEntries()
    SX_VM_CNONE();
    debug.profilebegin('update all entries');
    local batch = {};

    for player, entry in next, getupvalue(repInterface.getEntry, 1) do
        local thirdPersonObject = entry:getThirdPersonObject();
        if (not thirdPersonObject) then continue end;
        local currentHealth, maxHealth = entry:getHealth();

        batch[tostring(player)] = {
            isAlive = entry:isAlive(),
            player = player,
            currentHealth = currentHealth,
            maxHealth = maxHealth,
            head = entry:getThirdPersonObject():getBodyPart('head'),
            torso = entry:getThirdPersonObject():getBodyPart('torso')
        };
    end;

    commEvent:Fire(1, batch);
    commEvent:Fire(8, menuScreenGui.isEnabled());
    debug.profileend();
end;

local char;
local aimPart;

local function onCharacterAdded()
    char = characterInterface:getCharacterObject();
end;

onCharacterAdded();
characterEvents.onSpawned:connect(onCharacterAdded);

-- Character Object Hooks
do
    local oldSetBaseWalkspeed = characterObject.setBaseWalkSpeed;

    function characterObject:setBaseWalkSpeed(...)
        if (not char or self ~= char) then return oldSetBaseWalkspeed(self, ...) end;
        local args = {...};

        if(flags.walkspeed) then
            args[2] = flags.walkspeedValue
        end;

        table.foreach(args, warn);
        return oldSetBaseWalkspeed(self, unpack(args))
    end;
end;

do -- Weapon Controller Hooks
    local oldSpawn = weaponControllerInterface.spawn;

    local function onWeaponControllerChanged()
        weaponController = weaponControllerInterface:getController();
        warn('[Weapon Controller] Got new controller', weaponController);
    end;

    function weaponControllerInterface.spawn(...)
        local res = {oldSpawn(...)};
        onWeaponControllerChanged();
        return unpack(res);
    end;

    onWeaponControllerChanged();
end;

local physics = {};

do -- Physics (not made by me lol)
    local v3 = Vector3.new;
    local dot = v3().Dot;
    local gravity = v3(0, 196.2, 0);

    physics.solvebiquadratic = function(a, b, c)
        local p = (b * b - 4 * a * c) ^ 0.5;
        local r0 = (-b - p) / (2 * a);
        return r0 ^ 0.5;
    end;

    physics.trajectory = function(o, t, v)
        local vec = t - o;
        local r = physics.solvebiquadratic(dot(gravity, gravity) / 4, dot(gravity, vec) - v * v, dot(vec, vec));
        return (r and gravity * r / 2 + vec / r), r;
    end;
end;

local weaponVars = {
    NoRecoil = {
        {'camkickmin', Vector3.zero};
        {'camkickmax', Vector3.zero};
        {'aimcamkickmin', Vector3.zero};
        {'aimcamkickmax', Vector3.zero};
        {'aimtranskickmin', Vector3.zero};
        {'aimtranskickmax', Vector3.zero};
        {'transkickmin', Vector3.zero};
        {'transkickmax', Vector3.zero};
        {'rotkickmin', Vector3.zero};
        {'rotkickmax', Vector3.zero};
        {'aimrotkickmin', Vector3.zero};
        {'aimrotkickmax', Vector3.zero};
    };
    NoSway = {
        {'swayamp', 0};
        {'swayspeed', 0};
        {'steadyspeed', 0};
        {'breathspeed', 0};
    };
    NoSpread = {
        {'hipfirespread', 0.00001};
        {'hipfirestability', 0.00001};
        {'hipfirespreadrecover', 0.00001};
    };
    FullAuto = {
        {'firemodes', {true, 3, 1}}
    };
    NoFlash = {
        {'hideflash', true};
        {'hideminimap', true};
    };
    InstantEquip = {
        {'equipspeed', 100};
    };
    InstantReload = function(req)
        table.foreach(req, warn);
        if (not req.animations) then return end;
        for k,x in next, req.animations do
            if (k:lower():find('reload') or k:lower():find('pullbolt') or k:lower():find('onfire')) and type(x) == 'table' then
                print('passed');
                x.timescale = 0
            end
        end
        return req.animations;
    end;
}

local function applyGunModifications(editType, isEnabled)
    local currentGun;

    local function onGunUpdate()
        local gun = weaponController and weaponController:getActiveWeapon();
        if (gun == currentGun) then return end;

        currentGun = gun;
        commEvent:Fire(5, {weaponType = gun:getWeaponType()});

        if (not gun._oldWeaponData) then
            gun._oldWeaponData = {};
        end;

        local weaponDatas = table.clone(gun:getActiveAimStats());
        table.insert(weaponDatas, gun:getWeaponData());

        for _, weaponData in next, weaponDatas do
            local vars = weaponVars[editType];
            if (not vars) then warn('[WeaponController] no vars for', editType); continue end;

            if (typeof(vars) == 'function') then
                if (not gun._oldWeaponData.animations) then
                    gun._oldWeaponData.animations = weaponData.animations;
                end;

                weaponData.animations = isEnabled and vars(weaponData) or gun._oldWeaponData.animations;
            else
                for _, modifyData in next, vars do
                    local varName, varValue = unpack(modifyData);

                    if (not gun._oldWeaponData[varName]) then
                        print('[WeaponController] We saved', varName, 'weapon data');
                        gun._oldWeaponData[varName] = weaponData[varName];
                    end;

                    weaponData[varName] = isEnabled and varValue or gun._oldWeaponData[varName];
                    print('[WeaponController] We modified', varName, 'weapon data');
                end;
            end;
        end;
    end;

    if (gunModMaid[editType]) then
        gunModMaid[editType]:Disconnect();
        gunModMaid[editType] = nil;
    end;

    if (isEnabled) then
        local con;
        con = weaponControllerEvents.onControllerFlag:Connect(function(gun, flagName, t)
            if (flagName ~= 'equipFlag') then return end;
            print('UPDATE', editType, gun, flagName);
            onGunUpdate();
        end);

        gunModMaid[editType] = con;
    end;

    onGunUpdate();
end;

commEvent:Connect(function(updateType, t, ...)
    SX_VM_CNONE();
    if (updateType == 1) then return end;

    if (updateType == 2) then
        flags = t;
    elseif (updateType == 3) then
        applyGunModifications(t, ...);
    elseif (updateType == 4) then
        aimPart = t;
    elseif (updateType == 6) then
        network:send(t, ...);
    elseif (updateType == 7) then
        if (not char) then return end;
        char:setBaseWalkSpeed(t);
    else
        print(updateType, typeof(updateType), t, ...);
    end;
end);

local oldIndex;

oldIndex = hookmetamethod(game, '__index', function(self, p)
    SX_VM_CNONE();
    if (checkparallel()) then return oldIndex(self, p); end;

    if (p == 'CFrame') then
        local currentGun = weaponController and weaponController:getActiveWeapon();

        if (currentGun and (self == currentGun._barrelPart or oldIndex(self, 'Name') == 'SightMark')) then
            if aimPart then
                local _, TimeToHit = physics.trajectory(self.Position, aimPart.Position, currentGun:getWeaponStat('bulletspeed'));
                return CFrame.new(self.Position, aimPart.Position + (Vector3.new(0, 98.1, 0) * (TimeToHit ^ 2)));
            end;
        end;
    end;

    return oldIndex(self, p);
end);

local function getClosestCharacterFromDist()
    local closest;
    local last = math.huge;

    for _, v in next, Players:GetPlayers() do
        local head = repInterface.getEntry(v):getThirdPersonObject():getBodyPart('head');
        if v ~= LocalPlayer and head and v.Team ~= LocalPlayer.Team then
            local mag = (LocalPlayer.Character.HumanoidRootPart.Position - head.Position).Magnitude;
            if last > mag then
                last = head;
                closest = v;
            end;
        end;
    end;

    return closest;
end;

local function bulletTracer(Origin, Destination, LifeTime)
    local beam = Instance.new('Part');

    beam.Anchored = true;
    beam.CanCollide = false;
    beam.Material = flags.bulletTracersMaterial;
    beam.Color = flags.bulletTracersColor;
    beam.Size = Vector3.new(0.1, 0.1, (Destination - Origin).Magnitude);
    beam.CFrame = CFrame.new(Origin, Destination) * CFrame.new(0, 0, -beam.Size.Z / 2);
    beam.Transparency = flags.bulletTracersAlpha / 10;
    beam.Parent = workspace;

    Debris:AddItem(beam, LifeTime);
end;

local oldNetworkSend = network.send;
local oldParticleNew = particle.new;
local oldBulletHit = effect.bullethit;

network.send = function(self, ...)
    SX_VM_CNONE();
    local args = {...};

    if args[1] == 'falldamage' and flags.noFallDamage then
        return;
    end;

    if (flags.antiAim and args[1] == 'repupdate') then
        args[3] = Vector2.new(-1.47, math.random(-50, 50));
    end;

    if (args[1] == 'newgrenade' and args[2] == 'FRAG' and flags.fragTeleport) then
        local head = getClosestCharacterFromDist()
        if (head) then
            args[3].frames[#args[3].frames] = {
                v0 = Vector3.zero,
                glassbreaks = {},
                t0 = 0,
                offset = Vector3.zero,
                rot0 = CFrame.identity,
                a = Vector3.zero,
                p0 = head.Position,
                rotv = Vector3.zero
            }
            args[3].blowuptime = 0.001;
        end;
    end;

    if (flags.bulletTracers and args[1] == 'newbullets') then
        print('OK');
        task.spawn(function()
            local gun = weaponController and weaponController:getActiveWeapon();
            if (not gun) then return end;

            for i = 1, #args[2].bullets do
                task.spawn(bulletTracer, gun._barrelPart.Position, (gun._barrelPart.Position + args[2].bullets[i][1]), flags.bulletTracersLifetime);
            end;
        end);
    end;

    return oldNetworkSend(self, unpack(args));
end;

function effect:bullethit(...)
    local args = {...};

    if (aimPart) then
        args[2] = aimPart.Position;
    end;

    return oldBulletHit(self, unpack(args));
end;

setreadonly(particle, false);

particle.new = function(data, ...)
    SX_VM_CNONE();
    local currentGun = weaponController and weaponController:getActiveWeapon();

    if aimPart and data.visualorigin == currentGun._barrelPart.Position then
        data.position = aimPart.Position;
        data.velocity = physics.trajectory(currentGun._barrelPart.Position, data.position, currentGun:getWeaponStat('bulletspeed'));
    end;

    return oldParticleNew(data, ...);
end;

setreadonly(particle, true);

task.spawn(function()
    while task.wait() do
        updateAllEntries();
    end;
end);

print('Running on actor', ...);
commEvent:Fire('ready');