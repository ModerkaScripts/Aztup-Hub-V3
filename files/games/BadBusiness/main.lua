local UserInputService = game:GetService("UserInputService")
local library = sharedRequire('../../UILibrary.lua');
local Utility = sharedRequire('../../utils/Utility.lua');
local Services = sharedRequire('../../utils/Services.lua');

local RunService, ReplicatedStorage, Players = Services:Get('RunService', 'ReplicatedStorage', 'Players');
local LocalPlayer = Players.LocalPlayer;

local column1, column2 = unpack(library.columns);
local combat = column1:AddSection('Combat');
local utils = column1:AddSection('Utils');

local makeUnlockSkins;
local unlockAllSkins;

local autoReload;
local gameModules;

do -- // Functions
    local hookRecoilFunction;
    local playerData = ReplicatedStorage.PlayerData:WaitForChild(LocalPlayer.Name);

    local TS = require(ReplicatedStorage.TS);

    for _, v in next, getupvalues(TS) do
        if (typeof(v) == 'table' and getrawmetatable(v) and typeof(rawget(getrawmetatable(v), '__index')) == 'function') then
            gameModules = getupvalue(getrawmetatable(v).__index, 1);
        end;
    end;

    assert(gameModules);

    local lastShootAt = 0;

    function makeUnlockSkins(name)
        local folder = name == 'Charms' and getupvalue(gameModules.Charms.GetConfig, 1) or ReplicatedStorage:FindFirstChild(name, true);

        for _, v in next, folder:GetDescendants() do
            if (v:IsA('ModuleScript')) then
                local folder = Instance.new('Folder');
                local skinName = name == 'Charms' and v.Parent.Name or v.Name;

                folder.Name = skinName;
                folder.Parent = playerData[name];
            end;
        end;
    end;

    do -- // ESP Override
        local characters = getupvalue(gameModules.Characters.GetCharacter, 1);
        local teams = getupvalue(gameModules.Teams.GetPlayerTeam, 1);

        local function getPlayerTeam(player)
            for i, v in next, teams:GetChildren() do
                if v.Players:FindFirstChild(player.Name) then
                    return v.Name;
                end;
            end;
        end;

        function Utility:getCharacter(player)
            local character = characters[player];
            if(not character or not character.Parent) then return end;

            local characterBody = character:FindFirstChild('Body');
            if(not characterBody) then return end;

            local health = character:FindFirstChild('Health');
            if(not health or (player ~= LocalPlayer and health:FindFirstChild('Shield'))) then return end;

            local maxHealth = health:FindFirstChild('MaxHealth');
            if(not maxHealth) then return end;

            return characterBody, maxHealth.Value, (health.Value / maxHealth.Value) * 100, health.Value;
        end;

        function Utility:isTeamMate(player)
            return getPlayerTeam(player) == getPlayerTeam(LocalPlayer);
        end;

        function Utility:getRootPart(player)
            local character = characters[player];
            if(not character) then return end;

            return character.PrimaryPart;
        end;
    end;

    do -- // Utility
        local Network = gameModules.Network;

        local equipSkinsNames = {'EquipSkin', 'EquipCharm', 'EquipSticker'};
        local upvalues = {};

        upvalues.library = library;
        upvalues.playerData = playerData;

        upvalues.oldFireserver = hookfunction(Network.Fire, function(self, actionName, ...)
            local args = {...};
            local actionType = args[1];

            if (actionName == 'Inventory' and upvalues.library.flags.unlockAllSkins) then
                if(table.find(equipSkinsNames, actionType)) then
                    local skinType = args[1]:match('Equip(%w+)');
                    local gunName, skin = args[2], args[3];

                    if (skinType == 'Sticker') then
                        skinType = skinType .. args[3];
                        skin = args[4];
                    end;

                    upvalues.playerData.Weapons[gunName].Customization[skinType].Value = skin;
                    return;
                elseif (actionType == 'EquipClothing') then
                    local loadout = 'Outfit' .. upvalues.playerData.Equipped.Loadout.Value:match('%d');
                    local playerOutfit = upvalues.playerData.Outfits[loadout];
                    local skin, clothType = args[2], args[3];

                    playerOutfit[clothType].Value = skin;
                    return;
                end;
            end;

            return upvalues.oldFireserver(self, actionName, ...);
        end);

        local controllersStats = getupvalue(gameModules.Projectiles.InitProjectile, 1);

        for i, v in next, getconnections(gameModules.Characters.CharacterAdded) do
            if (debug.info(v.Function, 's'):match('ItemAnimateScript')) then
                local characterAddedFunction = getupvalue(v.Function, 2);
                local oldEquippedFunction = getupvalue(characterAddedFunction, 17);

                setupvalue(characterAddedFunction, 17, function(gun)
                    if (library.flags.unlockAllSkins and gun) then
                        local playerGunData = playerData.Weapons:FindFirstChild(gun.Name);
                        if (playerGunData) then
                            for _, v2 in next, playerGunData.Customization:GetChildren() do
                                gun:WaitForChild(v2.Name).Value = v2.Value;
                            end;
                        end;
                    end;

                    return oldEquippedFunction(gun);
                end);

                break;
            end;
        end;

        function hookRecoilFunction(f, flagName, newFunction)
            newFunction = newFunction or function() end;

            local upvalues = {};
            upvalues.library = library;
            upvalues.newFunction = newFunction;
            upvalues.flagName = flagName;

            upvalues.oldFunction = hookfunction(f, function(...)
                if(upvalues.library.flags[upvalues.flagName]) then
                    return upvalues.newFunction();
                end;

                return upvalues.oldFunction(...);
            end);
        end;

        local function getBulletStats()
            for i, v in next, gameModules.Items:GetControllers() do
                if(v.Equipped) then
                    local gunConfig = require(i.Config);
                    if (gunConfig and gunConfig.Projectile and gunConfig.Projectile.Template) then
                        return controllersStats[gunConfig.Projectile.Template];
                    end;
                end;
            end;
        end;

        local function getBulletDirectionForSilentAim()
            if(not library.flags.silentAim) then return end;

            local target = Utility:getClosestCharacter();
            local targetHead = target.Character and target.Character:FindFirstChild('Head');

            if(not targetHead) then return end;

            local bulletStats = getBulletStats();
            if (not bulletStats or not bulletStats.Speed) then return end;

            local targetPosition = (targetHead.Position - workspace.CurrentCamera.CFrame.Position);

            local timeToShoot = targetPosition.Magnitude / bulletStats.Speed;
            local bulletDropPrediction = library.flags.bulletDropPrediction and Vector3.new(0, 0.5 * bulletStats.Gravity * timeToShoot ^ 2, 0) or Vector3.new();

            local playerMovePrediction = library.flags.playerMovePrediction and (Utility:roundVector(targetHead.Velocity) * timeToShoot) or Vector3.new();

            print(playerMovePrediction);

            return (targetPosition + bulletDropPrediction + playerMovePrediction).Unit
        end;

        local upvalues = {};
        upvalues.library = library;
        upvalues.runService = RunService;

        upvalues.oldTimerWait = hookfunction(gameModules.Timer.Wait, function(self, waitTime, ...)
            if(upvalues.library.flags.fireRateModifier and waitTime <= 1) then
                waitTime = upvalues.library.flags.fireRateModifierValue / 1000;
            end;

            return upvalues.oldTimerWait(self, waitTime, ...)
        end);

        hookRecoilFunction(gameModules.Items.FirstPerson.WeaponMovementSpring.Shove, 'noRecoil');
        hookRecoilFunction(gameModules.Items.FirstPerson.WeaponRotationSpring.Shove, 'noRecoil');
        hookRecoilFunction(gameModules.Items.FirstPerson.CameraSpring.Shove, 'noRecoil');

        local oldNamecall;
        local FindFirstChild = game.FindFirstChild;

        oldNamecall = hookmetamethod(game, '__namecall', function(self, ...)
            local method = getnamecallmethod();
            if (method == 'FindPartOnRayWithWhitelist') then
                local n = debug.info(isSynapseV3 and 2 or 3, 'n');

                if (n == 'CastGeometryAndEnemies' and library.flags.wallBang) then
                    local args = {...};
                    local geometry = FindFirstChild(workspace, 'Geometry');

                    if (args[2][1] == geometry) then
                        table.remove(args[2], table.find(args[2], geometry));
                    end;

                    return oldNamecall(self, unpack(args));
                end;
            end;

            return oldNamecall(self, ...);
        end);

        local upvalues = {};
        upvalues.library = library;

        upvalues.oldRecoilFire = hookfunction(gameModules.Camera.Recoil.Update, function(self, ...)
            lastShootAt = self.Init;

            if(upvalues.library.flags.noRecoil) then
                return Vector2.zero;
            end;

            return upvalues.oldRecoilFire(self, ...);
        end);

        hookfunction(gameModules.Input.Reticle.LookVector, function(...)
            return getBulletDirectionForSilentAim() or workspace.CurrentCamera.CFrame.LookVector;
        end);

        function unlockAllSkins()
            makeUnlockSkins('Skins');
            makeUnlockSkins('Charms');
            makeUnlockSkins('Stickers');

            for _, v in next, playerData.Clothes:GetChildren() do
                v.Parent = nil;
            end;

            local clothingFolder = getupvalue(gameModules.Clothing.GetConfig, 2);

            for _, v in next, clothingFolder:GetDescendants() do
                if (v:IsA('ModuleScript')) then
                    local folder = Instance.new('Folder');

                    folder.Name = v.Parent.Name;
                    folder.Parent = playerData.Clothes;
                end;
            end;
        end;

        (function()
            for i, v in next, getgc() do
                if(typeof(v) == 'function' and islclosure(v) and not is_synapse_function(v)) then
                    for i2, v2 in next, getupvalues(v) do
                        if(typeof(v2) == 'function' and debug.info(v2, 'n') == 'GetSpeedDebuff') then
                            setupvalue(v, i2, function()
                                return library.flags.speedhack and -2.5 or 0;
                            end);

                            return;
                        end;
                    end;
                end;
            end;
        end)();
    end;

    function autoReload()
        repeat
            if(tick() - lastShootAt >= 0.8) then
                gameModules.Input:AutomateBegan('Reload');
            end;

            task.wait();
        until not library.flags.autoReload;
    end;
end;

combat:AddToggle({
    text = 'No Recoil'
});

combat:AddToggle({
    text = 'No Spread'
});

combat:AddToggle({
    text = 'Auto Reload',
    callback = autoReload
});

combat:AddToggle({
    text = 'Silent Aim'
});

combat:AddToggle({
    text = 'Bullet Drop Prediction'
});

combat:AddToggle({
    text = 'Player Move Prediction'
});

combat:AddToggle({
    text = 'Wall Bang'
});

combat:AddToggle({
    text = 'Speedhack'
});

combat:AddToggle({
    text = 'Fire Rate Modifier'
}):AddSlider({
    min = 1, max = 1000,
    flag = 'Fire Rate Modifier Value'
});

utils:AddButton({
    text = 'Unlock All Skins',
    callback = unlockAllSkins
});