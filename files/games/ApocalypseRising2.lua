local library = sharedRequire('../UILibrary.lua');
local Services = sharedRequire('../utils/Services.lua');
local Utility = sharedRequire('../utils/Utility.lua');
local Maid = sharedRequire('../utils/Maid.lua');

local ControlModule = sharedRequire('../classes/ControlModule.lua');

local createBaseESP = sharedRequire('../utils/createBaseESP.lua');
local prettyPrint = sharedRequire('../utils/prettyPrint.lua');

local ReplicatedFirst, Players, RunService, Lighting, ReplicatedStorage, UserInputService = Services:Get(
    'ReplicatedFirst',
    'Players',
    'RunService',
    'Lighting',
    'ReplicatedStorage',
    'UserInputService'
);

local column1, column2 = unpack(library.columns);

local LocalPlayer = Players.LocalPlayer;
local framework;
local setupLootEsp;

local disableZombies;
local toggleLootEsp;
local noJumpCooldown;
local infiniteJump;
local killAura;
local autoHeal;
local autoEat;
local autoDrink;
local mapEsp;
local fullBright;
local autoOpenDoor;
local noFog;
local bringLoots;

local MapEsp = {};
MapEsp.__index = MapEsp;
MapEsp.ClassName = 'MapEsp';

local network, bullets, animators, raycasting, players, resources, world;

do -- // Scanning
    local frameworkModule = ReplicatedFirst:WaitForChild('Framework');
    local playerGui = LocalPlayer:WaitForChild('PlayerGui');

    repeat
        task.wait();
    until playerGui:FindFirstChild('Interface Main') and not playerGui['Interface Main']:FindFirstChild('LoadingGui');

    framework = require(frameworkModule);

    local frameworkLoad = rawget(framework, 'load');
    if(not frameworkLoad) then return LocalPlayer:Kick('[AR2] Error 1, dm Aztup.') end;

    repeat
        print('[AR2] Getting framework...');
        task.wait(0.1);
    until typeof(getupvalue(frameworkLoad, 2)) == 'table';

    framework = getupvalue(frameworkLoad, 2);
    _G.framework = framework;
end;

do -- // Hooks
    local banActions = {"Player Chat Mute Report","Get Player Stance Speed","Force Charcter Save","Sync Near Chunk Loot","Resync Character Physics", "Zombie State Resync Attempt", "Firearm Ammo Sync"};

    repeat
        network = framework.Libraries.Network;
        bullets = framework.Libraries.Bullets;
        animators = framework.Classes.Animators;
        players = framework.Classes.Players;
        raycasting = framework.Libraries.Raycasting;
        resources = framework.Libraries.Resources;
        world = framework.Libraries.World;

        task.wait()
    until network and bullets and animators and raycasting;

    local oldCharacterGroundCast = raycasting.CharacterGroundCast;
    local oldBulletCast = raycasting.BulletCast;

    local part = Instance.new('Part');

    function raycasting:CharacterGroundCast(cf, depth)
        local caller = rawget(getfenv(2), 'script')

        if(library.flags.noFallDamage and typeof(caller) == 'Instance' and caller.Name == 'Characters') then
            return part;
        end;

        return oldCharacterGroundCast(self, cf, depth);
    end;

    function Utility:getCharacter(player)
        local health = player.Character and player.Character:FindFirstChild('Stats');
        health = health and health.Health.Base.Value;
        if(not health) then return end;

        return player.Character, 100, health, health;
    end;

    local oldFetch = network.Fetch;

    local oldSend = network.Send;
    local oldAnimatorPost = animators.Post;

    local oldBulletFire = bullets.Fire;
    local oldGetSpreadAngle = getupvalue(oldBulletFire, 1);

    for i, v in next, getgc() do
        if(typeof(v) == 'function' and islclosure(v) and not is_synapse_function(v)) then
            local constants = getconstants(v);
            if(table.find(constants, 'Sit')) then
                local old;
                old = hookfunction(v, function(...)
                    if(not library.flags.noWait) then
                        return old(...)
                    end;

                    local args = {old(...)};
                    args[4] = 0;
                    return unpack(args);
                end);

                break;
            end;
        end;
    end;

    local blacklistedRemotes = {'Animator Camera Position Report', 'Set Character State', 'Ping Return', 'Ping'};

    local function onNetworkSend(self, remoteName, ...)
        if(table.find(banActions, remoteName)) then
            local tra = debug.traceback();
            -- The game do calls Send on a client invoke and if it doesnt get send it not happy
            print(tra);

            if (not string.find(tra, 'Libraries.Network')) then
                warn('[Network] Real Ban Attempt');
                return task.wait(9e9);
            end;

            warn('WENT THROW OP', remoteName);
        end;

        if(debugMode and not table.find(blacklistedRemotes, remoteName)) then
            print(prettyPrint({_type = remoteName, traceback = debug.traceback(), ...}));
        end;

        return pcall(oldSend, self, remoteName, ...);
    end;

    local function onNetworkFetch(self, remoteName, ...)
        local returnData = {select(2, pcall(oldFetch, self, remoteName, ...))};

        if(remoteName ~= 'Get Server Debug State' and remoteName ~= 'Ping Return' and remoteName ~= 'Set Character State'  and remoteName ~= 'Ping' and debugMode) then
            print(prettyPrint({_type = remoteName, traceback = debug.traceback(), returnData = returnData, ...}));
        end;

        return unpack(returnData);
    end

    oldSend = hookfunction(oldSend, function(self, remoteName, ...)
        return onNetworkSend(self, remoteName, ...);
    end);

    oldFetch = hookfunction(oldFetch, function(self, remoteName, ...)
        return onNetworkFetch(self, remoteName, ...);
    end);

    function animators:Post(action, ...)
        local character = LocalPlayer.Character;
        if(action == 'FireImpulse' and library.flags.noRecoil and character and self.Instance == character) then
            return warn('[No Recoil] returned')
        end;

        return oldAnimatorPost(self, action, ...);
    end;

    function bullets:Fire(a, b, weapon, d, direction)
        local player = players:get();
        local myCharacter = player.Character;

        if(weapon.Attachments and weapon.Attachments.Ammo and weapon.Attachments.Ammo.Amount == 0 and library.flags.autoReload) then
            weapon:OnReload(myCharacter);
        end;

        if(not library.flags.silentAim) then
            return oldBulletFire(self, a, b, weapon, d, direction)
        end;

        local myRootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;

        local character = Utility:getClosestCharacter();
        character = character and character.Character;

        if(myRootPart and character and character.PrimaryPart) then
            local direction = (character.PrimaryPart.Position - myRootPart.Position);
            local distance = direction.Magnitude;

            local gravity = 30.90;
            local timeToHit = distance / weapon.FireConfig.MuzzleVelocity;
            local bulletDrop = 0.5 * gravity * timeToHit ^ 2;

            print('Bullet drop prediction', bulletDrop);

            direction = (direction + Vector3.new(0, bulletDrop, 0)).Unit;

            warn('[Silent Aim] Spoofed', direction);

            return oldBulletFire(self, a, b, weapon, d, direction);
        end;

        return oldBulletFire(self, a, b, weapon, d, direction);
    end;

    setupvalue(oldBulletFire, 1, function(...)
        if(library.flags.noSpread) then
            return 0;
        end;

        return oldGetSpreadAngle(...);
    end);
end;

do -- // Utilities
    local maid = Maid.new();
    local lootEspItems = {};

    local lootEspBase = createBaseESP('lootEsp', lootEspItems);

    function disableZombies(toggle)
        if(not toggle) then
            maid.disableZombiesLoop = nil;
            return;
        end;

        local zombieController = framework.Classes.ZombieControler;
        local zombies = getupvalue(zombieController.find, 1);

        maid.disableZombiesLoop = RunService.Heartbeat:Connect(function()
            for _, v in next, zombies do
                v.Instance.PrimaryPart.Anchored = true;
            end;
        end);
    end;

    function toggleLootEsp(toggle)
        if(not toggle) then
            maid.lootEspLoop = nil;
            maid.lootEspCameraChange = nil;
            lootEspBase:Disable();
            return;
        end;

        local function onCameraChanged(camera)
            if(not camera) then
                maid.lootEspLoop = nil;
                lootEspBase:Disable();
                return;
            end;

            maid.lootEspLoop = camera:GetPropertyChangedSignal('CFrame'):Connect(function()
                debug.profilebegin('Loot Esp Update');
                lootEspBase:UpdateAll();
                debug.profileend();
            end);
        end

        onCameraChanged(workspace.CurrentCamera);
        maid.lootEspCameraChange = workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
            onCameraChanged(workspace.CurrentCamera);
        end);
    end

    function setupLootEsp()
        local function onLootGroupStateChange(behaviorHeritage, part, instance)
            if(instance:GetAttribute('LootGroupState') == 'Fresh') then
                lootEspItems[part] = lootEspBase.new(part, require(ReplicatedStorage.Chunking['Container Data']:FindFirstChild(behaviorHeritage)).DisplayName, nil, true);
            elseif(lootEspItems[part]) then
                lootEspItems[part]:Destroy();
            end;
        end;

        local function newEsp(instance)
            local heritage = instance:GetAttribute('BehaviorHeritage')
            if(not heritage) then return end;
            local part = instance:FindFirstChildWhichIsA('BasePart');
            if(not part) then return warn('no part') end;

            instance:GetAttributeChangedSignal('LootGroupState'):Connect(function()
                onLootGroupStateChange(heritage, part, instance);
            end);

            onLootGroupStateChange(heritage, part, instance);
        end

        for i,v in next, workspace.Map.Shared.LootBins:GetChildren() do
            for i2, v2 in next, v:GetChildren() do
                newEsp(v2);
            end;
        end;

        local c = 0;
        for i, v in next, lootEspItems do
            c = c + 1;
        end

        print(string.format('[Loot Esp] Found %d loots', c))
    end;

    function killAura(toggle)
        if(not toggle) then
            maid.killAura = nil;
            return;
        end;

        local lastSendAt = 0;

        maid.killAura = RunService.Heartbeat:Connect(function()
            local myRootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
            local player = framework.Classes.Players:get();

            if(not myRootPart or not player.Character) then
                return;
            end;

            local characters = workspace.Characters:GetChildren();
            local zombies = workspace.Zombies.Mobs:GetChildren();

            for i, v in next, zombies do
                table.insert(characters, v);
            end;

            local closestMob, closestDistance = nil, math.huge;

            for i, v in next, characters do
                local rootPart = v.PrimaryPart;
                if(not rootPart or v == LocalPlayer.Character) then continue; end;

                local distance = (myRootPart.Position - rootPart.Position).Magnitude;
                if(distance <= closestDistance) then
                    closestMob = v;
                    closestDistance = distance;
                end;
            end;

            if(closestMob and closestDistance < 25 and tick() - lastSendAt >= 0.89) then
                local weaponId = player.Character.Inventory.Equipment.Melee.Id
                lastSendAt = tick();

                network:Send('Character Equip Item', weaponId);
                network:Send('Melee Swing', weaponId, 1);
                network:Send('Melee Hit Register', weaponId, closestMob.Head);
                network:Send('Character Unequip Item', weaponId);
            end;
        end);
    end;

    function noJumpCooldown(toggle)
        if(not toggle) then
            maid.noJumpCooldown = nil;
            return;
        end;

        maid.noJumpCooldown = RunService.Heartbeat:Connect(function()
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid');
            if(humanoid and UserInputService:IsKeyDown(Enum.KeyCode.Space)) then
                humanoid.Jump = true;
            end;
        end);
    end;

    function infiniteJump(toggle)
        if(not toggle) then
            maid.infiniteJump = nil;
            return;
        end;

        maid.infiniteJump = RunService.Heartbeat:Connect(function()
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid');
            local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;

            if(humanoid and rootPart and UserInputService:IsKeyDown(Enum.KeyCode.Space)) then
                local velocity = rootPart.Velocity
                rootPart.Velocity = Vector3.new(velocity.X, 50, velocity.Z);
            end;
        end);
    end;

    function autoHeal(toggle)
        if(not toggle) then
            maid.autoHealLoop = nil;
            return;
        end;

        local lastUpdatedAt = 0;

        maid.autoHealLoop = RunService.Heartbeat:Connect(function()
            if (tick() - lastUpdatedAt < 1) then return end;
            lastUpdatedAt = tick();
            local player = players:get();
            local inventory = player.Character and player.Character.Inventory;
            if(not inventory or not player.Character or player.Character.Health:Get() > 80) then return end;

            for i, v in next, inventory.Containers[1].Occupants do
                if(v.Type == 'Medical' and v.UseValue.Health) then
                    local animLength = resources:Find('ReplicatedStorage.Assets.Animations.' .. v.ConsumeConfig.Animation):GetAttribute('Length');
                    framework.Libraries.Network:Send('Register Consume', v.Id);
                    task.wait(animLength);
                    framework.Libraries.Network:Send('Inventory Use Item', v.Id);
                end;
            end;
        end);
    end;

    function autoEat(toggle)
        if(not toggle) then
            maid.autoEatLoop = nil;
            return;
        end;

        local lastUpdatedAt = 0;

        maid.autoEatLoop = RunService.Heartbeat:Connect(function()
            if (tick() - lastUpdatedAt < 1) then return end;
            lastUpdatedAt = tick();

            local player = players:get();
            local inventory = player.Character and player.Character.Inventory;
            if(not inventory) then return end;

            if(player.Character and player.Character.Energy:Get() < 80) then
                for i, v in next, inventory.Containers[1].Occupants do
                    if(v.Type == 'Consumable' and v.UseValue.Energy and v.UseValue.Energy > 0) then
                        local animLength = resources:Find('ReplicatedStorage.Assets.Animations.' .. v.ConsumeConfig.Animation):GetAttribute('Length');
                        framework.Libraries.Network:Send('Register Consume', v.Id);
                        task.wait(animLength);
                        framework.Libraries.Network:Send('Inventory Use Item', v.Id);
                    end;
                end;
            end;
        end);
    end;

    function autoDrink(toggle)
        if(not toggle) then
            maid.autoDrinkLoop = nil;
            return;
        end;

        local lastUpdatedAt = 0;

        maid.autoDrinkLoop = RunService.Heartbeat:Connect(function()
            if (tick() - lastUpdatedAt < 1) then return end;
            lastUpdatedAt = tick();

            local player = players:get();
            local inventory = player.Character and player.Character.Inventory;
            if(not inventory) then return end;

            if(player.Character and player.Character.Hydration:Get() < 80) then
                for i, v in next, inventory.Containers[1].Occupants do
                    if(v.Type == 'Consumable' and v.UseValue.Hydration and v.UseValue.Hydration > 0) then
                        local animLength = resources:Find('ReplicatedStorage.Assets.Animations.' .. v.ConsumeConfig.Animation):GetAttribute('Length');
                        framework.Libraries.Network:Send('Register Consume', v.Id);
                        task.wait(animLength);
                        framework.Libraries.Network:Send('Inventory Use Item', v.Id);
                    end;
                end;
            end;
        end);
    end;

    function mapEsp(toggle)
        local map = framework.Libraries.Interface:Get('Map');
        syn.set_thread_identity(2);

        if(not toggle) then
            map:DisableGodview();
        else
            map:EnableGodview();
        end;

        syn.set_thread_identity(7);
    end;

    function autoOpenDoor(toggle)
        if(not toggle) then
            maid.autoOpenDoor = nil;
            return;
        end;

        local World = framework.Libraries.World;
        local Interactables = getupvalue(World.GetInteractable, 2);
        local lastRan = 0;

        maid.autoOpenDoor = RunService.Heartbeat:Connect(function()
            local myRootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
            if(not myRootPart or tick() - lastRan <= 0.5) then return end;

            lastRan = tick()

            for i, v in next, Interactables do
                if(v.Type == 'Door' and v.State == 'Closed' and (myRootPart.Position - v.Instance.PrimaryPart.Position).Magnitude <= 25) then
                    v:Interact();
                end;
            end;
        end);
    end;

    function fullBright(toggle)
        if(not toggle) then
            maid.fullBright = nil;
            Lighting.Ambient = Color3.fromRGB(168, 168, 168);
            return;
        end;

        maid.fullBright = RunService.Heartbeat:Connect(function()
            Lighting.Ambient = Color3.fromRGB(255, 255, 255);
        end);
    end;

    function noFog(toggle)
        for i,v in next, getconnections(Lighting.Changed) do
            v[toggle and 'Disable' or 'Enable'](v);
        end;

        if(toggle) then
            maid.noFog = Lighting:GetPropertyChangedSignal('FogStart'):Connect(function()
                Lighting.FogStart = 99999999;
                Lighting.FogEnd = 99999999;
            end);

            Lighting.FogStart = 99999999;
            Lighting.FogEnd = 99999999;
        else
            maid.noFog = nil;
        end;
    end;

    function bringLoots(toggle)
        if (not toggle) then
            maid.bringLoots = nil;
            return;
        end;

        local lastUpdateAt = 0;
        maid.bringLoots = RunService.Heartbeat:Connect(function()
            if (tick() - lastUpdateAt < 1) then return end;
            lastUpdateAt = tick();

            local nearChunks = world:GetNearChunkNames(workspace.CurrentCamera.CFrame.Position, 1)
            local filteredTypes = library.options.bringLootsValues.value;
            local character = players:get().Character
            local inventory = character and character.Inventory;
            if (not inventory) then return print('[Bring Loot] Inventory not found') end;

            local myPosition = workspace.CurrentCamera.CFrame.Position;

            for chunkName in next, nearChunks do
                local chunk = workspace.Map.Shared.LootBins:FindFirstChild(chunkName);
                if (not chunk) then continue end;

                for _, group in next, chunk:GetChildren() do
                    local position = group:GetAttribute('Position');
                    if (not position or (position - myPosition).Magnitude > 20) then continue end;

                    local canFetch = network:Fetch('Inventory Container Group Connect', group);
                    if (not canFetch) then continue end;

                    for _, container in next, inventory.Containers do
                        if (container.DisplayName == 'Pockets' or container.IsCarried) then continue end;

                        for _, occupant in next, container.Occupants do
                            if (not filteredTypes[occupant.Type]) then continue end;
                            network:Send('Inventory Pickup Item', occupant.Id);
                        end;
                    end;
                end;
            end;
        end);
    end;
end;

local lootTypes = {'Accessory', 'Ammo', 'Attachment', 'Backpack', 'Belt', 'Clothing', 'Consumable', 'Firearm', 'Hat', 'Medical', 'Melee', 'Utility', 'RepairTool', 'Vest'};

local Main = column1:AddSection('Main');
local AR2Misc = column2:AddSection('Misc');
local AR2Gun = column2:AddSection('Guns');
local LootEsp = column2:AddSection('Loots Esp');

AR2Gun:AddToggle({text = 'Silent Aim'});
AR2Gun:AddToggle({text = 'No Spread'});
AR2Gun:AddToggle({text = 'No Recoil'});
AR2Gun:AddToggle({text = 'Auto Reload'});

AR2Misc:AddToggle({text = 'Map Esp', callback = mapEsp});
AR2Misc:AddToggle({text = 'Auto Open Door', callback = autoOpenDoor});
AR2Misc:AddToggle({text = 'Full Bright', callback = fullBright});
AR2Misc:AddToggle({text = 'No Fog', callback = noFog});

Main:AddToggle({text = 'Kill Aura', callback = killAura});
Main:AddToggle({text = 'No Wait'});
Main:AddToggle({text = 'Auto Heal', callback = autoHeal});
Main:AddToggle({text = 'Auto Eat', callback = autoEat});
Main:AddToggle({text = 'Auto Drink', callback = autoDrink});
Main:AddToggle({text = 'No Jump Cooldown', callback = noJumpCooldown});
Main:AddToggle({text = 'Infinite Jump', callback = infiniteJump});
Main:AddToggle({text = 'No Fall Damage'});
Main:AddToggle({text = 'Disable Zombies', callback = disableZombies});
Main:AddToggle({text = 'Bring Loots', callback = bringLoots}):AddList({flag = 'Bring Loots Values', values = lootTypes, multiselect = true});

LootEsp:AddToggle({text = 'Toggle Loots Esp', flag = 'Loot Esp', callback = toggleLootEsp});
LootEsp:AddToggle({text = 'Loot Esp Show Distance'})
LootEsp:AddSlider({text = 'Loot Esp Max Distance', value = 2500, min = 100, max = 5000})

setupLootEsp();