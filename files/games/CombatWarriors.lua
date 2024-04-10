local library = sharedRequire('../UILibrary.lua');
local Services = sharedRequire('../utils/Services.lua');
local Maid = sharedRequire('../utils/Maid.lua');
local Utility = sharedRequire('../utils/Utility.lua');
local ToastNotif = sharedRequire('../classes/ToastNotif.lua');

local ReplicatedStorage, RunService, Players, VirtualInputManager, CollectionService, MarketplaceService, Stats = Services:Get('ReplicatedStorage', 'RunService', 'Players', 'VirtualInputManager', 'CollectionService', 'MarketplaceService', 'Stats');
local column1, column2 = unpack(library.columns);

local LocalPlayer = Players.LocalPlayer;

local main = column1:AddSection('Main Cheats');
local rangedMods = column2:AddSection("Ranged Mods");

local gameRequire;

local functions = {};
local maid = Maid.new();

local IsA = game.IsA;

-- Functions
do
    local Nevermore = require(ReplicatedStorage.Framework.Nevermore);

    function gameRequire(moduleName)
        local modules = getupvalue(rawget(Nevermore, '_require'), 2);
        assert(typeof(modules) == 'table');
        assert(not getmetatable(modules));

        while true do
            for currentModuleName, module in next, modules do
                if (typeof(module) == 'Instance' and currentModuleName == moduleName) then
                    syn.set_thread_identity(2);
                    local result = {getrenv().require(module)};
                    syn.set_thread_identity(7);

                    return unpack(result);
                end;
            end;

            task.wait();
        end
    end;

    _G.gameRequire = gameRequire;

    local AirConstants = gameRequire('AirConstants');
    local Network = gameRequire('Network');
    local RoduxStore = gameRequire('RoduxStore');
    local DefaultStaminaHandler = gameRequire('DefaultStaminaHandlerClient');
    local DashConstants = gameRequire('DashConstants');
    local CharacterHandler = gameRequire('CharacterHandler');
    local JumpHandlerClient = gameRequire('JumpHandlerClient');
    local AntiCheatHandlerClient = gameRequire('AntiCheatHandlerClient');
    local UtilityMetadata = gameRequire('UtilityMetadata');
    local WeaponMetadata = gameRequire('WeaponMetadata');
    local RangedWeaponClient = gameRequire('RangedWeaponClient');
    local SpawnhandlerClient = gameRequire('SpawnHandlerClient');
    local RaycastUtilClient = gameRequire('RaycastUtilClient');
    local RangedWeaponHandler = gameRequire('RangedWeaponHandler');

    Network = getupvalue(rawget(getmetatable(Network), '__index'), 1);

    -- Hooks
    do
        local oldNamecall;
        local oldIndex;

        local oldUnequipTools;
        local oldGetCanJump;
        local oldRecoilCamera;
        local oldGetMouseHitPosition;

        function fireServerWrapper(self, name, ...)
            if (name == 'TakeFallDamage' and library.flags.noFallDamage) then
                return;
            elseif (name == 'MeleeDamage') then
                local args = {...};

                if (typeof(args[2]) == 'Instance' and library.flags.antiParry) then
                    local shield = args[2].Parent:FindFirstChild('FlareParticles', true);
                    if (shield and shield.Enabled) then return print('no dmg?'); end;
                end;
            elseif (name == 'GotHitRE' and library.flags.noFireDamage) then
                return;
            elseif (name == 'BAC') then
                return print('brrrrr', ...);
            elseif (name == "RangedFire" and library.flags.magicBullet) then
                local args = {...};
                local shotId;

                table.foreach(args[3], function(i) shotId = i; end)

                local targetChar = Utility:getClosestCharacter().Character;
                if not targetChar then return; end


                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
                local metaData = tool and WeaponMetadata[tool:GetAttribute('ItemId')];

                local rootPart = Utility:getPlayerData().rootPart;
                local targetHead = targetChar and targetChar:FindFirstChild('Head');

                if (targetHead and tool and rootPart) then
                    local timeToShoot = (rootPart.Position - targetHead.Position).Magnitude / metaData.speed;

                    task.delay(timeToShoot, function()
                        Network:FireServer("RangedHit",unpack({
                            tool,
                            targetChar.Head,
                            targetChar.Head.Position,
                            targetChar.Head.CFrame:ToObjectSpace(CFrame.new(targetChar.Head.Position)),
                            Vector3.new(0,0,0),
                            shotId
                        }))
                    end)
                end;
            end;

            return oldFireServer(self, name, ...);
        end;

        oldFireServer = hookfunction(rawget(Network, 'FireServer'), function(...)
            return fireServerWrapper(...);
        end);

        oldNamecall = hookmetamethod(game, '__namecall', function(self, ...)
            SX_VM_CNONE();
            local method = getnamecallmethod();

            if (method == 'FireServer' and IsA(self, 'RemoteEvent') and self.Name == 'GotHitRE' and library.flags.noSelfDamage) then
                return;
            end;

            return oldNamecall(self, ...);
        end);

        local plasic = Enum.Material.Plastic;

        oldIndex = hookmetamethod(game, '__index', function(self, p)
            SX_VM_CNONE();
            if (p == 'FloorMaterial' and library.flags.noFallDamage and IsA(self, 'Humanoid') and debug.info(isSynapseV3 and 2 or 3, 's'):find('FallDamageHandlerClient')) then
                return plasic;
            end;

            return oldIndex(self, p);
        end);

        function unequipToolsWrapper(...)
            if (library.flags.antiUnequipTools) then return end;
            return oldUnequipTools(...);
        end;

        oldUnequipTools = hookfunction(CharacterHandler.unequipTools, function(...)
            return unequipToolsWrapper(...);
        end);

        oldGetCanJump = hookfunction(JumpHandlerClient.getCanJump, function(...)
            if (library.flags.noJumpCooldown) then return true end;

            return oldGetCanJump(...);
        end);

        oldCancelReload = hookfunction(RangedWeaponClient.cancelReload,function(...)
            if (library.flags.noReloadCancel) then return {} end

            return oldCancelReload(...);
        end)

        oldRecoilCamera = hookfunction(RangedWeaponClient.recoilCamera,function(...)
            if (library.flags.noRecoil) then return {} end

            return oldRecoilCamera(...);
        end)

        local function getMouseHitPositionWrapper(...)
            if (not debug.info(3, 's'):find('RangedWeaponClient')) then return oldGetMouseHitPosition(...) end;

            if (library.flags.silentAim) then
                local target = Utility:getClosestCharacter().Character;
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
                local metaData = tool and WeaponMetadata[tool:GetAttribute('ItemId')];

                local rootPart = Utility:getPlayerData().rootPart;
                local targetHead = target and target:FindFirstChild('Head');

                if (targetHead and tool and rootPart) then
                    local timeToShoot = (rootPart.Position - targetHead.Position).Magnitude / metaData.speed;
                    print(timeToShoot, metaData.gravity.Y);
                    local prediction = metaData.gravity and 0.5 * metaData.gravity.Y  * timeToShoot ^ 2 or 0;

                    return targetHead, targetHead.Position - Vector3.new(0, prediction, 0);
                end;
            end;

            return oldGetMouseHitPosition(...);
        end

        oldGetMouseHitPosition = hookfunction(RaycastUtilClient.getMouseHitPosition, function(...)
            return getMouseHitPositionWrapper(...);
        end);

        oldCalculateFireDirection = hookfunction(RangedWeaponHandler.calculateFireDirection, function(a, ...)
            if (not library.flags.noSpread) then return oldCalculateFireDirection(a, ...) end;
            return a.LookVector;
        end);

        hookfunction(AntiCheatHandlerClient.punish, function() end);
    end;

    -- Infinite Oxygen
    do
        function functions.infiniteOxygen(t)
            AirConstants.AIR_TO_ADD_PER_SECOND_WHILE_SWIMMING = t and 0 or -15;
        end;

        function functions.autoRevive(t)
            if (not t) then
                maid.autoRevive = nil;
                return;
            end;

            local lastAutoReviveAttemptAt = 0;

            maid.autoRevive = RunService.Heartbeat:Connect(function()
                if (RoduxStore.store:getState().down.isDowned and tick() - lastAutoReviveAttemptAt > 0.5) then

                    print('we attempt?');
                    lastAutoReviveAttemptAt = tick();
                    Network:FireServer('SelfReviveStart');
                    Network:FireServer('SelfRevive');
                end;
            end);
        end;
    end;

    -- Auto Parry
    do
        local animations = {};

        for _, v in next, ReplicatedStorage.Shared.Assets.Melee:GetDescendants() do
            if (v:IsA('Animation') and v.Name:match('Slash')) then
                animations[v.AnimationId:match('%d+')] = v;
            end;
        end;

        Utility.listenToChildAdded(workspace.PlayerCharacters, function(char)
            if (char == LocalPlayer.Character) then return end;

            local humanoid = char:WaitForChild('Humanoid', 10);
            if (not humanoid) then return end;

            local rootPart = char:WaitForChild('HumanoidRootPart', 10);
            if (not rootPart) then return end;

            local rightArm = char:WaitForChild('Right Arm', 10);
            if (not rightArm) then return end;

            humanoid.AnimationPlayed:Connect(function(animationTrack)
                if (not animations[animationTrack.Animation.AnimationId:match('%d+')] or not library.flags.autoParry) then return end;

                local myRoot = Utility:getPlayerData().rootPart;
                if (not myRoot) then return end;

                local tool = char:FindFirstChildWhichIsA('Tool');
                if (not tool or not tool:FindFirstChild('Hitboxes')) then return end;

                local hitbox = tool.Hitboxes:FindFirstChild('Hitbox') or tool.Hitboxes:FindFirstChild('FullBodyHitbox');
                if (not hitbox) then return end;
                if ((myRoot.Position - rootPart.Position).Magnitude > rightArm.Size.Magnitude+hitbox.Size.Magnitude+1.5) then return end;

                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game);
                task.wait();
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game);
            end);
        end);
    end;

    function functions.infiniteStamina(t)
        if (not t) then
            maid.infiniteStamina = nil;
            return;
        end;

        maid.infiniteStamina = RunService.Heartbeat:Connect(function()
            local currentStaminaHandler = DefaultStaminaHandler:getDefaultStamina();
            currentStaminaHandler:setStamina(currentStaminaHandler:getMaxStamina());
        end);
    end;

    function functions.noDashCooldown(t)
        DashConstants.DASH_COOLDOWN = t and 0 or 3;
    end;

    function functions.instaUse(t)
        for _, utilityToolMetaData in next, UtilityMetadata do
            if (not utilityToolMetaData.useTime) then continue end;
            if (not utilityToolMetaData._oldUseTime) then
                utilityToolMetaData._oldUseTime = utilityToolMetaData.useTime;
            end;

            utilityToolMetaData.useTime = t and 0 or utilityToolMetaData._oldUseTime;
        end;
    end;

    function functions.fastRespawn(t)
        if (not t) then
            maid.fastRespawnOne = nil;
            maid.fastRespawnTwo = nil;
            return;
        end;

        local lastRanAt = 0;
        local lastRanAt2 = 0;

        maid.fastRespawnOne = RunService.Heartbeat:Connect(function()
            if (tick() - lastRanAt < 0.1) then return end;
            if (RoduxStore.store:getState().health.current > 0) then return end;
            lastRanAt = tick();

            print('Despawn attempt');

            Network:FireServer('StartFastRespawn');
            Network:InvokeServer('CompleteFastRespawn');
        end);

        maid.fastRespawnTwo = RunService.Heartbeat:Connect(function()
            if (tick() - lastRanAt2 < 0.1) then return end;
            if (not RoduxStore.store:getState().mainMenuClient.isIn) then return end;
            lastRanAt2 = tick();

            print('Spawn attempt');

            SpawnhandlerClient.spawnCharacter(true);
        end);
    end;

    function functions.wallBang(t)
        if (t) then
            CollectionService:AddTag(workspace.Map, 'RANGED_CASTER_IGNORE_LIST');
        else
            CollectionService:RemoveTag(workspace.Map, 'RANGED_CASTER_IGNORE_LIST');
        end;
    end;
end;

main:AddToggle({
    text = 'Auto Revive',
    tip = 'Will revive yourself as soon as you\'re down (slow)',
    callback = functions.autoRevive
});

main:AddToggle({
    text = 'Fast Respawn',
    tip = 'Will automatically respawn you if you are dead',
    callback = functions.fastRespawn
});

main:AddToggle({
    text = 'Insta Use',
    tip = 'Allows you to use beartrap, ghost potion, etc instantly',
    callback = functions.instaUse
});

main:AddToggle({
    text = 'Auto Parry',
    tip = 'Automatically parries attacks',
});

main:AddToggle({
    text = 'Anti Unequip Tools',
    tip = 'Prevent you from unequipping your tool when stunned.',
    callback = functions.autoRevive
});

main:AddToggle({
    text = 'Infinite Stamina',
    tip = 'Gives you infinite stamina.',
    callback = functions.infiniteStamina
});

main:AddToggle({
    text = 'No Jump Cooldown',
    tip = 'Removes jump cooldown.',
    callback = functions.infiniteStamina
});

main:AddToggle({
    text = 'Anti Parry',
    tip = 'Prevents from being stunned if someone parries at you and you swing at him'
});

main:AddToggle({
    text = 'Infinite Oxygen',
    tip = 'Gives you infinite oxygen.',
    callback = functions.infiniteOxygen
});

main:AddToggle({
    text = 'No Fall Damage',
    tip = 'Prevents you from taking fall damage.'
});

main:AddToggle({
    text = 'No Dash Cooldown',
    tip = 'Remove dash cooldown.',
    callback = functions.noDashCooldown
});

main:AddToggle({
    text = 'No Self Damage',
    tip = 'Prevents you from taking damage from fire, traps, etc.'
});

rangedMods:AddToggle({
    text = 'Silent Aim',
    tip = 'Automatically hits the person closest to your mouse.'
});

rangedMods:AddToggle({
    text = 'Wall Bang',
    tip = 'Makes you able to hit through walls.',
    callback = functions.wallBang
});

rangedMods:AddToggle({
    text = 'Magic Bullet',
    tip = 'Automatically hits the person closest to your mouse.'
});

rangedMods:AddToggle({
    text = 'No Recoil',
    tip = 'Makes it so your weapon has no recoil'
});

rangedMods:AddToggle({
    text = 'No Spread',
    tip = 'Makes it so your weapon has no spread'
});

rangedMods:AddToggle({
    text = 'No Bloom',
    tip = 'Removes the bloom while moving'
});

rangedMods:AddToggle({
    text = 'No Reload Cancel',
    tip = 'Makes you unable to reload cancel.'
});
