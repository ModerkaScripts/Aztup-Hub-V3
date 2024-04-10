local Utility = sharedRequire('@utils/Utility.lua');
local Maid = sharedRequire('@utils/Maid.lua');
local Services = sharedRequire('@Utils/Services.lua');
local ToastNotif = sharedRequire('@classes/ToastNotif.lua');
local basicsHelpers = sharedRequire('@utils/helpers/basics.lua');
local Webhook = sharedRequire('@utils/Webhook.lua');
local makeESP = sharedRequire('@utils/makeESP.lua');

local library = sharedRequire('@UILibrary.lua');
local column1, column2 = unpack(library.columns);

local mobfarmUtility = sharedRequire('@utils/helpers/mobfarm.lua');
local funcs = {};

local ReplicatedStorage, Players, RunService, MemStorageService, CollectionService, PathfindingService, TeleportService = Services:Get('ReplicatedStorage', 'Players', 'RunService', 'MemStorageService', 'CollectionService', 'PathfindingService', 'TeleportService');
local LocalPlayer = Players.LocalPlayer;

local allMobs = {};
local allCraft = {};
local allMobsDistances = {};
local allItemTypes = {};

local mobTypes = {'Crimson', 'Magical', 'Corrupt', 'Legendary', 'Bloody'};
local getNPCNameNonCorrupt;

local dungeonsData = require(ReplicatedStorage.Data.DungeonData);
local notifsQueue = {};

local addNotif, removeNotif;
local mobFarmLocationLabel;

local playerGui = LocalPlayer:WaitForChild('PlayerGui', math.huge);
local coreUI = playerGui:WaitForChild('Core', math.huge);
local loadingScreen = coreUI:WaitForChild('LoadingScreen', math.huge);

repeat
    task.wait();
until not loadingScreen.Visible;

-- Funcs
do
    local maid = Maid.new();
    local NPCsFolder = workspace.NPCS;
    local interactables = workspace.Interactables;
    local others = workspace.Others;
    local infusers = workspace.Infusers;

    local events = ReplicatedStorage.Events;
    local swingSword = events.SwingSword;
    local equipWeapon = events.EquipWeapon;
    local zonesFolder = ReplicatedStorage.MusicZone;
    local weaponArt = events.WeaponArt;
    local rune = events.Rune;
    local dialogEffect = events.DialogEffect;
    local craftItem = events.CraftItem;
    local destroyItem = events.DestroyItem;
    local startLobby = events.StartLobby;
    local playGame = events.PlayGame;
    local equipArmor = events.EquipArmor;
    local swapSet = events.SwapSet;

    local charHandler = require(LocalPlayer.PlayerScripts.Core.Controllers.CharHandler);
    local craftData = require(ReplicatedStorage.Data.CraftingData);
    local itemsData = require(ReplicatedStorage.Data.ItemData);

    for name in next, craftData do
        table.insert(allCraft,name);
    end;

    for _, itemData in next, itemsData do
        if (not table.find(allItemTypes, itemData.Type)) then
            table.insert(allItemTypes, itemData.Type);
        end;
    end;

    table.sort(allCraft, function(a, b) return a < b; end);
    table.sort(allItemTypes, function(a, b) return a < b; end);

    local healNpcs = {};

    local function isMobDead(mob)
        if (not mob) then return false; end;
        if (not library.flags.mobAutoFarm) then return true; end;
        return not mob.Parent or mob:GetAttribute('Dead');
    end;

    local function getMobRoot(mob)
        return mob;
    end;

    local function onNPCAdded(obj, espConstructor)
        local npcName = obj:GetAttribute('NPCName');
        if (not npcName) then return end;

        if (obj:GetAttribute('AIType')) then return end; -- All NPCs and Mobs have a tag called NPC
        espConstructor.new(obj, npcName, nil, true);
    end;

    local function onMobAdded(obj, espConstructor)
        if (not obj:GetAttribute('AIType')) then return end;
        local mobType = obj:GetAttribute('Type');
        local mobName, corrupted = getNPCNameNonCorrupt(obj:GetAttribute('NPCAppearance'));
        local notifData;

        -- For whatever reason CName are corrupted but their Type is Basic
        if (corrupted) then
            mobType = 'Corrupt';
        end;

        if (mobType ~= 'Basic') then
            mobName = string.format('%s(%s)', mobName, mobType);
            notifData = { name = 'Variant', text = string.format('%s has spawned turn on the ESP to see it', mobName) }
            addNotif(notifData);
        end;

        local esp = espConstructor.new(obj, {displayName = mobName, tag = mobType});
        local con;

        con = obj:GetPropertyChangedSignal('Parent'):Connect(function()
            if (obj.Parent) then return end;
            esp:Destroy();
            con:Disconnect();

            if (notifData) then
                removeNotif(notifData);
            end;
        end);

        if (mobName == 'IronSlayer') then
            notifData = { name = 'Iron Slayer', text = string.format('%s has spawned turn on the ESP to see it', mobName) };
            addNotif(notifData);
        end;
    end;

    local function getNameOfArea(obj)
        local nameOfArea;

        if (obj.Name == '???') then
            nameOfArea = 'Vampire Cave';
        elseif (obj:FindFirstChild('Configs')) then
            nameOfArea = obj.Configs.NameOfArea.Value;
        elseif (obj:FindFirstChild('Linked')) then
            return getNameOfArea(obj.Linked.Value);
        end;

        return nameOfArea;
    end

    local function onAreaAdded(obj, espConstructor)
        local nameOfArea = getNameOfArea(obj);
        if (not nameOfArea) then return; end;

        espConstructor.new(obj, nameOfArea);
    end;

    local function onShopItemAdded(obj, espConstructor)
        local shop = obj:FindFirstChild('Shop');
        if (not shop or not shop:IsA('ProximityPrompt')) then return end;

        espConstructor.new(obj, string.format('%s - %s$', obj:GetAttribute('Shop'), obj:GetAttribute('Cost')), nil, true);
    end;

    local function onDungeonAdded(obj, espConstructor)
        if (not obj:FindFirstChild('Dungeon')) then return end;
        espConstructor.new(obj, string.format('%s Dungeon', obj.Name:match('(.+)Dungeon')), nil, true);
    end;

    local function onInfuserAdded(obj, espConstructor)
        espConstructor.new(obj:FindFirstChildWhichIsA('BasePart', true), obj.Name, nil, true);
    end;

    local function oncraftingStationAdded(obj, espConstructor)
        espConstructor.new(obj, 'Crafting Station', nil, true);
    end;

    local function onShrineAdded(obj, espConstructor)
        local primaryPart = obj.PrimaryPart;
        if (not primaryPart) then return end;
        espConstructor.new(primaryPart, obj.Name, nil, true);
    end;

    local function onRiftAdded(obj, espConstructor)
        local union = obj:findFirstChild('Union');
        if (not union) then return end;

        local espObject;

        local function onUnionTransparencyChanged()
            if (union.Transparency == 1 and espObject) then
                espObject:Destroy();
                espObject = nil;
            elseif (union.Transparency == 0) then
                espObject = espConstructor.new(union, 'Rift', nil, true);
            end;
        end;

        union:GetPropertyChangedSignal('Transparency'):Connect(onUnionTransparencyChanged);
        onUnionTransparencyChanged();
    end;

    makeESP({
        sectionName = 'NPCs',
        type = 'tagAdded',
        args = 'NPC',
        callback = onNPCAdded
    });

    makeESP({
        sectionName = 'Crafting Stations',
        type = 'tagAdded',
        args = 'Crafting',
        callback = oncraftingStationAdded
    });

    makeESP({
        sectionName = 'Shrines',
        type = 'childAdded',
        args = workspace.Shrines,
        callback = onShrineAdded
    });

    makeESP({
        sectionName = 'Areas',
        type = 'childAdded',
        args = zonesFolder,
        callback = onAreaAdded
    });

    makeESP({
        sectionName = 'Buyables',
        type = 'childAdded',
        args = interactables,
        callback = onShopItemAdded
    });

    makeESP({
        sectionName = 'Dungeons',
        type = 'childAdded',
        args = others,
        callback = onDungeonAdded
    });

    makeESP({
        sectionName = 'Infusers',
        type = 'childAdded',
        args = infusers,
        callback = onInfuserAdded
    });

    makeESP({
        sectionName = 'Rifts',
        type = 'childAdded',
        args = interactables,
        callback = onRiftAdded
    });

    makeESP({
        sectionName = 'Mobs',
        type = 'tagAdded',
        args = 'NPC',
        callback = onMobAdded,
        onLoaded = function(section)
            local list = {};

            section:AddToggle({
                text = 'Show Health',
                flag = 'Mobs Show Health'
            });

            for _, mobType in next, mobTypes do
                table.insert(list, section:AddColor({
                    text = string.format('%s Mob Color', mobType),
                    flag = string.format('%s Color', mobType)
                }));
            end;

            return {list = list};
        end
    });

    do -- Grab Health NPCs
        local dialogTable = require(LocalPlayer.PlayerScripts.Core.Controllers.DialogTable);

        local function findDialogue(text)
            local result = {};

            for npcName, dialogData in next, dialogTable do
                local textFunc = rawget(dialogData, 'Text');
                if (typeof(textFunc) ~= 'function') then continue end;

                for _, v2 in next, getconstants(textFunc) do
                    if (typeof(v2) == 'string' and v2:find(text)) then
                        table.insert(result, {
                            npcName = npcName,
                            choice = v2
                        });
                        break;
                    end;
                end;
            end;

            return result;
        end;

        healNpcs = findDialogue('Heal %[');
    end;

    local lastFireAt = 0;
    local forcedHeightAdjust = 0;

    local explodingBombers = {};
    local effectsData = {};
    local isDungeon = false;

    -- Used for Bomber NPCs cause they make you take damage when they explode
    function effectsData.BomberGlow(effectData)
        table.insert(explodingBombers, effectData.Target);
        task.delay(10, function()
            local exists = table.find(explodingBombers, effectData.Target);
            if (not exists) then return end;
            table.remove(explodingBombers, exists);
            -- We would assume that after 10 sec the mob is dead
        end);
    end;

    function effectsData.PlayAnimation(effectData)
        table.foreach(effectData, warn);
        if (effectData.Animation == 'Breath' and getNPCNameNonCorrupt(effectData.Target:GetAttribute('NPCName')) == 'Dragigator' and isDungeon and library.flags.mobAutoFarm) then
            print('DRAGIGATOR???');

            local heightAdjust = 15;
            local rootPart = Utility:getPlayerData().rootPart;

            if (rootPart.Position.Y >= 240) then
                print('adjust higher');
                -- If we are too high then we go down this is so we don't get kicked for being out of bounds
                heightAdjust = -heightAdjust;
            end;

            -- We need to do this cause our character is sometimes rotated and sometimes not
            print('go up');
            task.wait(1);
            rootPart.CFrame = CFrame.new(-49.80000305175781, 3, -1483.300048828125)
            task.wait(1.5);
            print('go down');
        end;
    end;

    local blacklistedEffects = {'PlayAnimation', 'Punch', 'Damage', 'WindSlash', 'Notify', 'Alert', 'Death', 'Stun', 'HeavyPunch', 'Screenshake'};
    library.unloadMaid:GiveTask(events.Effect.OnClientEvent:Connect(function(effectData)
        if (effectData.Name and not table.find(blacklistedEffects, effectData.Name)) then
            -- print('-------------');
            -- table.foreach(effectData, warn);
        end;

        if (not effectData.Name or not effectsData[effectData.Name]) then return end;
        effectsData[effectData.Name](effectData);
    end));

    local function doHealLogic(closestNpc, distance2)
        local rootPart = Utility:getPlayerData().rootPart;

        if (library.flags.autoHealUsePotion) then
            -- If we find a potion use it instead

            for itemId, item in next, charHandler.Inventory do
                if (item.ItemName == 'ThrowableHealingPotion' or item.ItemName == 'HealthPotion') then
                    forcedHeightAdjust += 20;
                    rootPart.CFrame = CFrame.new(rootPart.CFrame.Position + Vector3.new(0, 20, 0)) * rootPart.CFrame.Rotation;
                    equipArmor:InvokeServer(itemId, false); -- 2nd arg true is for cosmetics
                    task.delay(1, function()
                        forcedHeightAdjust -= 20;
                        rootPart.CFrame = CFrame.new(rootPart.CFrame.Position + Vector3.new(0, -20, 0)) * rootPart.CFrame.Rotation;
                    end);

                    task.wait(1);
                    return true;
                end;
            end;
        end;

        -- If we find a NPC to Heal then go to it
        if (closestNpc) then
            mobfarmUtility:tweenTeleport(CFrame.new(closestNpc.Position));

            if (distance2 <= 5) then
                local humanoid = Utility:getPlayerData().humanoid;
                if (not humanoid) then return true; end;

                local lastHealth = humanoid.Health;

                dialogEffect:FireServer(closestNpc, 'Heal');
                local startedAt = tick();
                repeat
                    task.wait();
                until humanoid.Health ~= lastHealth or tick() - startedAt > 5;
            end;

            return true;
        end;
    end;

    local function attackMob(rateLimit)
        if (tick() - lastFireAt < (rateLimit or 0.05)) then return end;

        if (not LocalPlayer:GetAttribute('EquippedSword')) then
            equipWeapon:InvokeServer();
            task.wait(0.5);
        end;

        lastFireAt = tick();
        swingSword:FireServer(library.flags.useM2 and 'R' or 'L');

        if (library.flags.useSkill) then
            weaponArt:FireServer();
        end;

        if (library.flags.useRune) then
            rune:FireServer();
        end;
    end;

    local cachedPath;
    local queenBeeSetup;

    local lastCachedPathUpdateAt = 0;
    local SHRINE_ACTIVE_COLOR = Color3.fromRGB(255, 0, 0);

    local function beeDungeonLogic(dungeon, arena)
        if (arena or not dungeon:FindFirstChild('Start')) then return end;

        local prompts = CollectionService:GetTagged('Prompt');

        local chest, chestDistance = mobfarmUtility:getClosest(prompts, {
            getRoot = function(obj) return obj.Parent:IsA('BasePart') and obj.Parent end,
            filter = function(obj) return obj.Name == 'HoneyChest' end,
            isAlive = function(obj)
                if (obj:GetAttribute('Cooldown')) then return false; end;
                local rootPart = obj.Parent;
                local top = rootPart.Parent:FindFirstChild('Top');

                return top and rootPart and (rootPart.Position - top.Position).Magnitude < 3.5;
            end,
        });

        if (chest) then
            mobfarmUtility:tweenTeleport(CFrame.new(chest.Parent.Position + Vector3.new(0, 5, 0)), {
                instant = true
            });

            if (chestDistance <= 20) then
                fireproximityprompt(chest);
            end;

            return true;
        end;

        local endPart = dungeon:FindFirstChild('End');

        if not endPart then
            LocalPlayer:Kick("The maze was bugged, no end.");
            TeleportService:Teleport(8651781069);
        end;

        -- We force path finding service to update path every 0.5s incase there was an issue
        if (not cachedPath or tick() - lastCachedPathUpdateAt > 0.5) then
            lastCachedPathUpdateAt = tick();
            local START_POSITION = Vector3.new(14.394362449645996, 2.487703323364258, 8.34000015258789);
            local path = PathfindingService:CreatePath();

            print('Waiting for path to be completed');

            for _, v in next, dungeon:GetChildren() do
                if (v:FindFirstChild('DoorHitbox')) then
                    v.Door.CanCollide = false;
                    v.DoorHitbox.CanCollide = false;
                end;

                if (v:FindFirstChild('Fountain')) then
                    for i,v in next, v.Fountain:GetChildren() do
                        if not v:IsA("BasePart") then continue; end
                        v.CanCollide = false;
                    end;
                end;
            end;

            for _, v in next, endPart.Hole:GetChildren() do
                if (v:IsA('BasePart')) then
                    v.CanCollide = false; -- Fix the issue where Hole is blocking path finding service?
                end;
            end;

            local ranSince = tick();

            repeat
                path:ComputeAsync(START_POSITION, endPart.Position + Vector3.new(0, 9, 0)); -- Fix the issue where endPart is too below ground?
                print(path.Status);
            until path.Status == Enum.PathStatus.Success or tick() - ranSince > 1;

            cachedPath = path;
            print('Got path');
        end;

        local npcs = CollectionService:GetTagged('NPC');

        for _, waypoint in next, cachedPath:GetWaypoints() do
            print(waypoint);

            if (debugMode) then
                local p = Instance.new("Part",workspace);
                p.CanCollide = false;
                p.Anchored = true;
                p.Size = Vector3.new(1,1,1);
                p.CFrame = CFrame.new(waypoint.Position);
            end;

            local doorNearby = mobfarmUtility:getClosest(npcs, {
                filter = function(obj) return obj.Name == 'DoorHitbox' end,
                getRoot = function(obj) return obj end,
                rootOverride = waypoint,
                maxDistance = 15
            });

            if (not doorNearby) then continue end;

            local breakingStartedAt = tick();

            repeat
                if not library.flags.mobAutoFarm then break; end
                mobfarmUtility:tweenTeleport(doorNearby.CFrame*CFrame.new( 8, 7, 0) * CFrame.Angles(0, math.rad(90),0), {
                    instant = true
                });
                attackMob(0.2);
                task.wait();
            until not doorNearby.Parent or tick() - breakingStartedAt > 8;

            -- We believe path finding service Path is most likely broken so we'll recompute it
            if (tick() - breakingStartedAt > 8) then
                break;
            end;
        end;

        if (library.flags.destroyShrines) then
            while true do
                local shrine = mobfarmUtility:getClosest(npcs, {
                    getRoot = function(obj) return obj; end,
                    filter = function(obj)
                        return obj.Parent and obj.Parent.Name == 'Shrine' and obj.Parent.Eyes.Color ~= SHRINE_ACTIVE_COLOR;
                    end
                });

                if (not shrine) then
                    warn('no shrine found!');
                    break;
                end;

                repeat
                    if not library.flags.mobAutoFarm then break; end
                    mobfarmUtility:tweenTeleport(CFrame.new(shrine.Position - Vector3.new(3, 0, 0), shrine.Position), {
                        instant = true
                    });
                    attackMob(0.2);
                    task.wait();
                until shrine.Parent.Eyes.Color == SHRINE_ACTIVE_COLOR or not library.flags.dungeonAutoFarm;
            end;
        end;

        if not library.flags.mobAutoFarm then return; end

        mobfarmUtility:tweenTeleport(endPart.Position, {
            instant = true
        });
        task.wait(5);
        cachedPath = nil;

        return true;
    end;

    function funcs.mobAutoFarm(toggle)
        local placeId = game.PlaceId;
        local isDungeonLocal, dungeonName = Utility.find(dungeonsData, function(v) return tonumber(v.ID) == placeId; end);
        isDungeon = isDungeonLocal;

        if (not toggle) then
            maid.mobNoclip = nil;
            mobfarmUtility.turnOffAutoFarm();

            local humanoid = Utility:getPlayerData().humanoid;
            if not humanoid then return; end

            humanoid.JumpPower = 50;
            return;
        end;

        maid.mobNoclip = RunService.Stepped:Connect(function()
            local playerData = Utility:getPlayerData();
            local humanoid = playerData.humanoid;
            local rootPart = playerData.rootPart;
            if (not humanoid or not rootPart) then return end;

            -- This is required cause spamming jump make you fall to the ground with noclip
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0.95, 0);

            for _, part in next, playerData.parts do
                part.CanCollide = false;
            end;

            humanoid:ChangeState('Jumping');
            humanoid.JumpPower = 0;
        end);

        local lastMobSpawnedAt = tick();

        while true do
            task.wait();
            if (not library.flags.mobAutoFarm) then break end;

            local useFixedZone = library.flags.useFixedZone;
            local fixedZoneRange = library.flags.fixedZoneRange;
            local fixedZonePosition = library.configVars.voxlbladeAutoFarmLocation;
            fixedZonePosition = fixedZonePosition and Vector3.new(unpack(fixedZonePosition:split(',')));

            local dungeon =  isDungeon and workspace.Map:FindFirstChild('Dungeon');
            local arena = workspace.Map:FindFirstChild('Arena');
            -- Arena is the end of the Queen Bee Dungeon

            local mob = mobfarmUtility:getClosest(NPCsFolder, {
                getRoot = getMobRoot,
                isAlive = function(obj) return not isMobDead(obj) end,
                prioritize = function(obj)
                    if (isDungeon and getNPCNameNonCorrupt(obj:GetAttribute('NPCName')) == 'Dragigator') then
                        return true;
                    end;
                end,
                filter = function(mob)
                    -- If bee dungeon force mob auto farm to ONLY attack QueenBee
                    if (arena) then
                        local isQueenBee = getNPCNameNonCorrupt(mob:GetAttribute('NPCName')) == 'QueenBee';

                        if (isQueenBee and not queenBeeSetup) then
                            queenBeeSetup = true;
                            mob:GetAttributeChangedSignal('HP'):Connect(function()
                                if (mob:GetAttribute('HP') <= 0 and library.flags.infiniteDungeon) then
                                    print('IT DIED');
                                    task.wait(1);
                                    LocalPlayer:Kick();
                                    TeleportService:Teleport(8651781069);
                                    print(game.Players.LocalPlayer:GetAttribute('BeeDungeonCD'));
                                end;
                            end);
                        end;

                        return isQueenBee;
                    end;

                    -- Filters should not run in Dungeons to prevent breaking it lol
                    if (isDungeon) then return true; end;

                    local filterPassed = false;
                    filterPassed = not library.flags.enableMobFilter or library.flags.mobFilter[mob:GetAttribute('NPCAppearance')];
                    filterPassed = filterPassed and (not library.flags.enableMobTypesFilter or library.flags.mobTypesFilter[mob:GetAttribute('Type')]);

                    if (useFixedZone) then
                        filterPassed = filterPassed and (mob.Position - fixedZonePosition).Magnitude <= fixedZoneRange;
                    end;

                    return filterPassed;
                end
            });

            -- Dungeon Logic
            if (isDungeon) then
                if (dungeonName == 'BeeDungeon' and beeDungeonLogic(dungeon, arena)) then
                    continue;
                end;
            end;

            if (mob) then
                lastMobSpawnedAt = tick();
            end;

            -- If no mobs for 30 seconds and we have use fixed zone turned on and we are not in dungeon tp to the fixed zone position
            if (tick() - lastMobSpawnedAt > 30 and library.flags.useFixedZone and fixedZonePosition and not isDungeon) then
                mobfarmUtility:tweenTeleport(CFrame.new(fixedZonePosition));
                continue;
            end;

            repeat
                task.wait();

                -- If we are not in a dungeon but dungeonAutoFarm is turned on do nothing
                if (not isDungeon and library.flags.dungeonAutoFarm) then break; end;
                if (not mob or not library.flags.mobAutoFarm) then break end;

                local playerData = Utility:getPlayerData();
                local rootPart, humanoid = playerData.rootPart, playerData.humanoid;
                if (not rootPart or not humanoid) then continue end;

                local distance = Utility:roundVector(mob.Position - rootPart.Position).Magnitude;
                local mobName = getNPCNameNonCorrupt(mob:GetAttribute('NPCName'));

                local shouldHeal = library.flags.autoHeal and (humanoid.Health / humanoid.MaxHealth) * 100 <= library.flags.autoHealPercentage;

                if (shouldHeal) then
                    local closestNpc, distance2 = mobfarmUtility:getClosest(interactables, {
                        getRoot = getMobRoot,
                        filter = function(npc)
                            return Utility.find(healNpcs, function(v) return v.npcName == npc.Name end)
                        end
                    });

                    local dialogData = Utility.find(healNpcs, function(v) return v.npcName == closestNpc:GetAttribute('NPCName'); end);
                    local amountNeeded = dialogData and tonumber(dialogData.choice:match('%p(%d+)')) or 0;

                    if ((LocalPlayer:GetAttribute('Voxos') or 0) >= amountNeeded) then
                        doHealLogic(closestNpc, distance2);
                        continue;
                    end;
                end;

                local mobHeight = library.flags.useGlobalDistance and library.flags.globalDistance or library.flags[string.format('%sHeight', mobName:lower())] or 10;
                mobHeight += forcedHeightAdjust;

                mobfarmUtility:tweenTeleport(CFrame.new(mob.Position), {
                    offset = CFrame.new(0, mobHeight, 0) * CFrame.Angles(math.rad(-90), 0, 0),
                    instant = isDungeon
                });

                -- We round Vector it so it should work fine
                if (distance <= 2.5) then
                    attackMob();
                end;
            until isMobDead(mob);
        end;
    end;

    function funcs.noKnockback(toggle)
        if (not toggle) then
            maid.noKnockback = nil;
            return;
        end;

        maid.noKnockback = RunService.Stepped:Connect(function()
            local rootPart = Utility:getPlayerData().rootPart;
            if (not rootPart or not rootPart:FindFirstChild('Knockback')) then return end;

            rootPart.Knockback:Destroy();
        end);
    end;

    local lastShown;
    function funcs.mobDistances()
        local mobSelected = library.flags.mobDistances;

        if (lastShown) then
            lastShown.main.Visible = false;
        end;

        lastShown = allMobsDistances[mobSelected];
        lastShown.main.Visible = true;
    end;

    function funcs.itemCrafter()
        local toCraft = library.flags.itemName;

        local _, distance = mobfarmUtility:getClosest(interactables, {
            filter = function(obj) return obj.Name == 'Crafting' end,
            getRoot = function(obj) return obj end
        });

        if (distance >= 20) then
            ToastNotif.new({text = 'You are too far away from a crafting table'});
            return;
        end;

        for _ = 1, library.flags.craftAmount do
            task.spawn(function()
                craftItem:InvokeServer(toCraft);
            end);
        end;
    end;

    function funcs.autoSell()
        local _, distance = mobfarmUtility:getClosest(interactables, {
            filter = function(obj) return CollectionService:HasTag(obj, 'Shopkeeper') end,
            getRoot = function(obj) return obj; end
        });

        if (distance >= 20) then
            ToastNotif.new({text = 'You are too far away from a shop keeper.'});
            return;
        end;

        local toSell = {};
        local foundItems = false;

        for i, item in next, charHandler.Inventory do
            local itemData = itemsData[item.ItemName];
            local isEnchanted = #item.Enchantments > 0;

            if (isEnchanted and library.flags.doNotSellEnchantedItem) then continue end;
            if (not library.flags.autoSellTypes[itemData.Type]) then continue end;

            toSell[i] = item.Amount or 1;
            foundItems = true;
        end;

        if (not foundItems) then return end;
        destroyItem:InvokeServer(toSell);
    end;

    function funcs.setFixedZonePosition()
        local rootPart = Utility:getPlayerData().rootPart;
        if (not rootPart) then return end;

        library.configVars.voxlbladeAutoFarmLocation = tostring(rootPart.Position);
        mobFarmLocationLabel.Text = string.format('Position: %d,%d,%d', math.floor(rootPart.Position.X), math.floor(rootPart.Position.Y), math.floor(rootPart.Position.Z));
    end;

    local oldSet;
    function funcs.setDataloss(t)
        if (not oldSet) then
            oldSet = LocalPlayer:GetAttribute('Set') or '1';
        end;

        originalFunctions.invokeServer(swapSet, t and string.char(128) or oldSet);
        ToastNotif.new({
            text = t and 'Dataloss set!' or 'Dataloss unset!'
        });
    end;

    do -- Notifier Utils
        local notifiersToUpdate = {};

        function addNotif(data)
            table.insert(notifsQueue, data);
            for _, f in next, notifiersToUpdate do task.spawn(f); end;
        end;

        function removeNotif(data)
            table.remove(notifsQueue, table.find(notifsQueue, data));
        end;

        function funcs.makeNotifier(name)
            local toggled = false;
            local function updateQueue()
                if (not toggled) then return end;

                for _, notifData in next, notifsQueue do
                    if (notifData.name ~= name) then continue; end;

                    ToastNotif.new({
                        text = notifData.text
                    });

                    table.remove(notifsQueue, table.find(notifsQueue, notifData));
                end;
            end;

            table.insert(notifiersToUpdate, updateQueue);

            return function (toggle)
                toggled = toggle;
                if (not toggle) then return end;
                updateQueue();
            end;
        end;

        library.OnLoad:Connect(function()
            for _, f in next, notifiersToUpdate do task.spawn(f); end;
        end);
    end;

    do -- Dungeon Auto Farm
        local function canDoDungeon(dungeonName)
            return ReplicatedStorage.Clock.Value > LocalPlayer:GetAttribute(dungeonName .. 'CD');
        end;

        function funcs.dungeonAutoFarm(toggle)
            if (not toggle) then
                mobfarmUtility.turnOffAutoFarm();
                return;
            end;

            if (library.OnLoad) then
                library.OnLoad:Wait(); -- Wait for library to be loaded to get actual dropdown value
            end;

            -- Grab dungeon data
            local dungeonToFarm = library.flags.dungeonToFarm;
            local dungeonData, dungeonName = Utility.find(dungeonsData, function(v) return v.TrueName == dungeonToFarm end);
            local additionalMods = {};

            -- If we are in a Dungeon do not run this code it's only used to start the dungeon
            if (game.PlaceId == tonumber(dungeonData.ID)) then
                return;
            end;

            local dungeonLocation = others:WaitForChild(dungeonName, 5);
            if (not dungeonLocation) then return error('No dungeon found? ' .. dungeonToFarm); end;

            -- Spawn in character
            if (not LocalPlayer:GetAttribute('Loaded')) then
                if (not MemStorageService:HasItem('Slot')) then
                    ToastNotif.new({
                        text = 'Please spawn in first!'
                    });
                else
                    playGame:InvokeServer(MemStorageService:GetItem('Slot'));
                end;

                repeat task.wait(); until LocalPlayer:GetAttribute('Loaded');
            end;

            local rootPart;

            repeat
                rootPart = Utility:getPlayerData().rootPart;
                task.wait();
            until rootPart;

            local distance = (rootPart.Position - dungeonLocation.Position).Magnitude;

            if (distance > 20) then
                ToastNotif.new({
                    text = 'Too far from dungeon. Teleporting to it'
                });

                rootPart.CFrame = CFrame.new(Utility:roundVector(rootPart.CFrame.Position) + Vector3.new(0, dungeonLocation.Position.Y + 2000, 0));
                repeat
                    task.wait();
                    distance = Utility:roundVector(rootPart.Position - dungeonLocation.Position).Magnitude;
                    mobfarmUtility:tweenTeleport(CFrame.new(dungeonLocation.Position), {
                        tweenSpeedIgnoreY = true,
                        offset = CFrame.new(0, 2000, 0)
                    });
                until distance <= 5 or not library.flags.dungeonAutoFarm;
            end;

            mobfarmUtility.destroyTweens();

            -- User toggled if off we don't do anything
            if (not library.flags.dungeonAutoFarm) then return end;

            rootPart.CFrame = dungeonLocation.CFrame;
            task.wait(1);

            if (library.flags.doCorruptDungeon and not dungeonLocation:GetAttribute('Corrupted') and dungeonName == 'FroggDungeon') then
                local bindedCorruption = Utility.find(charHandler.Inventory, function(v) return v.ItemName == 'BindedCorruption' end);

                if (bindedCorruption and bindedCorruption.Amount > 0) then
                    -- TP to frogg status
                    local froggStatue = interactables.CorruptFroggShrine.FroggStatue;
                    local tween = mobfarmUtility:tweenTeleport(froggStatue.CFrame * CFrame.new(0, 0, 10));
                    tween.Completed:Wait();

                    dialogEffect:FireServer(froggStatue, 'SlotBinded');
                    task.wait(1);
                    mobfarmUtility:tweenTeleport(CFrame.new(dungeonLocation.Position));
                end;
            end;

            if (dungeonLocation:GetAttribute('Corrupted')) then
                table.insert(additionalMods, 'Corrupt');
            end;

            -- Wait for cooldown to go away or toggle to go off
            if (not canDoDungeon(dungeonName) and library.flags.dungeonAutoFarm) then
                ToastNotif.new({text = string.format('You are on cooldown for %s. The script will wait for the cooldown to finish.', dungeonToFarm)});
                repeat task.wait(); until canDoDungeon(dungeonName) or not library.flags.dungeonAutoFarm;
            end;

            -- User toggled if off we don't do anything
            if (not library.flags.dungeonAutoFarm) then return end;

            MemStorageService:SetItem('DungeonFarmPlaceId', dungeonData.ID);
            MemStorageService:SetItem('Slot', LocalPlayer.Slot.Value);

            -- Start dungeon with specific options as Solo (2nd arg)
            -- Need to be spammed cause roblox moment
            while true do
                if (not library.flags.dungeonAutoFarm) then return end;

                originalFunctions.invokeServer(startLobby, {
                    Difficulty = library.flags.dungeonDifficulty,
                    DungeonType = dungeonName,
                    FriendsOnly = false,
                    DailyChallenge = false,
                    AdditionalMods = additionalMods,
                    Players = {
                        [LocalPlayer.Name] = LocalPlayer
                    }
                }, true);

                task.wait(5);
            end;
        end;

        library.OnLoad:Connect(function()
            if (not MemStorageService:HasItem('DungeonFarmPlaceId')) then return end;

            local placeId = tonumber(MemStorageService:GetItem('DungeonFarmPlaceId'));
            MemStorageService:RemoveItem('DungeonFarmPlaceId');

            -- Mob auto farm is all compatible so we should be fine
            if (placeId == game.PlaceId and not library.flags.mobAutoFarm) then
                library.options.mobAutoFarm:SetState(true);
            end;
        end);
    end;

    do -- Grab all mobs
        for _, v in next, ReplicatedStorage.NPCs:GetChildren() do
            if (v:GetAttribute('Active') ~= nil or not v:FindFirstChild('HPBar', true) or not v:FindFirstChild('HPBar', true).Enabled) then continue end;
            table.insert(allMobs, v.Name);
        end;

        local toRemove = {};
        local allCorrupts = {};

        -- Remove CMob, etc as we have Mob Types filter
        for _, mobType in next, allMobs do
            local withoutC = mobType:sub(2); -- CMob

            if (table.find(allMobs, withoutC)) then
                table.insert(toRemove, mobType);
                allCorrupts[mobType] = withoutC;
            end;
        end;

        function getNPCNameNonCorrupt(name)
            local corruptName = allCorrupts[name];
            if (corruptName) then return corruptName, true; end;

            return name, false;
        end;

        for _, v in next, toRemove do
            table.remove(allMobs, table.find(allMobs, v));
        end;

        table.sort(allMobs, function(a, b) return a < b; end);
    end;
end;

do -- UI
    local autoFarm = column1:AddSection('Auto Farm');
    local localCheats = column2:AddSection('Movement');
    local misc = column2:AddSection('Misc');
    local dataloss =column2:AddSection('Dataloss');
    local debugWebhook = Webhook.new('');

    do -- // Dataloss
        -- dataloss:AddButton({
        --     text = 'Set dataloss',
        --     callback = function() funcs.setDataloss(true); end,
        -- });

        -- dataloss:AddButton({
        --     text = 'Undo dataloss',
        --     callback = function() funcs.setDataloss(false); end,
        -- });
        dataloss:AddButton({
            text = 'Rejoin Server',
            callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId); end,
        });
    end;

    do -- // Auto Farm
        autoFarm:AddToggle({
            text = 'Mob Auto Farm',
            callback = funcs.mobAutoFarm
        });

        autoFarm:AddToggle({
            text = 'Dungeon Auto Farm',
            callback = funcs.dungeonAutoFarm
        });

        autoFarm:AddToggle({
            text = 'Do Corrupt Dungeon',
        });

        autoFarm:AddToggle({
            text = 'Destroy Shrines',
        });

        autoFarm:AddToggle({
            text = 'Infinite Dungeon',
            tip = 'Only works for Queen Bee Dungeon and you\'ll not get the loot at the end.'
        });

        autoFarm:AddToggle({
            text = 'Use M2'
        });

        autoFarm:AddToggle({
            text = 'Use Skill'
        });

        autoFarm:AddToggle({
            text = 'Use Rune'
        });

        autoFarm:AddToggle({
            text = 'Use Fixed Zone'
        });

        autoFarm:AddButton({
            text = 'Set Fixed Zone Position',
            callback = funcs.setFixedZonePosition
        });

        autoFarm:AddSlider({
            text = 'Fixed Zone Range',
            textpos = 2,
            min = 50,
            max = 5000
        });

        mobFarmLocationLabel = autoFarm:AddLabel();

        library.OnLoad:Connect(function()
            local savedLocation = library.configVars.voxlbladeAutoFarmLocation;
            savedLocation = savedLocation and Vector3.new(unpack(savedLocation:split(',')));

            local locationText = savedLocation and string.format('Position: %d,%d,%d', math.floor(savedLocation.X), math.floor(savedLocation.Y), math.floor(savedLocation.Z));

            mobFarmLocationLabel.Text = locationText or 'Position: Not set.';
        end);

        autoFarm:AddSlider({
            text = 'Dungeon Difficulty',
            textpos = 2,
            min = 0,
            value = 1,
            float = 0.1,
            max = 2,
        });

        autoFarm:AddList({
            text = 'Dungeon To Farm',
            values = Utility.map(dungeonsData, function(v) return v.TrueName end)
        });

        autoFarm:AddToggle({
            text = 'Auto Heal'
        }):AddSlider({
            text = 'Auto Heal %',
            flag = 'Auto Heal Percentage',
            min = 5,
            max = 90
        });

        autoFarm:AddToggle({
            text = 'Auto Heal Use Potion'
        });

        autoFarm:AddSlider({
            text = 'Tween Speed',
            textpos = 2,
            min = 10,
            max = 50
        });

        autoFarm:AddToggle({
            text = 'Enable Mob Filter'
        });

        autoFarm:AddToggle({
            text = 'Enable Mob Types Filter'
        });

        autoFarm:AddList({
            text = 'Mob Filter',
            values = allMobs,
            multiselect = true,
            tooltip = 'Mobs prefixed with a C are corrupted'
        });

        autoFarm:AddList({
            text = 'Mob Types Filter',
            values = mobTypes,
            multiselect = true
        });

        autoFarm:AddToggle({
            text = 'Use Global Distance'
        })

        autoFarm:AddSlider({
            text = 'Global Distance',
            textpos = 2,
            min = 0,
            value = 10,
            max = 20
        });

        autoFarm:AddList({
            text = 'Mob Distances',
            callback = funcs.mobDistances,
            values = allMobs
        });

        for _, mobType in next, allMobs do
            allMobsDistances[mobType] = autoFarm:AddSlider({
                text = string.format('%s Height', mobType),
                min = 0,
                textpos = 2,
                value = 10,
                max = 20,
            });

            library.OnLoad:Connect(function()
                allMobsDistances[mobType].main.Visible = false;
            end);
        end;
    end;

    do -- Local Cheats
        localCheats:AddToggle({
            text = 'Speed',
            callback = basicsHelpers.speedHack
        }):AddSlider({
            flag = 'Speed Hack Value',
            min = 16,
            max = 50
        });

        localCheats:AddToggle({
            text = 'Fly',
            callback = basicsHelpers.flyHack
        }):AddSlider({
            flag = 'Fly Hack Value',
            min = 16,
            max = 50
        });

        localCheats:AddToggle({
            text = 'Noclip',
            callback = basicsHelpers.noclip
        });

        localCheats:AddToggle({
            text = 'No Knockback',
            callback = funcs.noKnockback
        });

        localCheats:AddToggle({
            text = 'Infinite Jump',
            callback = basicsHelpers.infiniteJump
        }):AddSlider({
            min = 50,
            max = 250,
            flag = 'Infinite Jump Height'
        });
    end;

    do -- Misc
        misc:AddToggle({
            text = 'No Fog',
            callback = basicsHelpers.noFog
        });

        misc:AddButton({
            text = 'Auto Sell',
            callback = funcs.autoSell
        });

        misc:AddToggle({
            text = 'Do Not Sell Enchanted Item'
        });

        misc:AddList({
            text = 'Auto Sell Types',
            values = allItemTypes,
            multiselect = true
        });

        misc:AddToggle({
            text = 'Iron Slayer Notifier',
            callback = funcs.makeNotifier('Iron Slayer')
        });

        misc:AddToggle({
            text = 'Variants Notifier',
            callback = funcs.makeNotifier('Variant')
        });

        misc:AddToggle({
            text = 'No Blur',
            callback = basicsHelpers.noBlur
        });

        misc:AddToggle({
            text = 'Fullbright',
            callback = basicsHelpers.fullBright
        });

        misc:AddList({
            text = 'Item Name',
            values = allCraft,
        });

        misc:AddSlider({
            text = 'Craft Amount',
            min = 1,
            max = 100,
            textpos = 2
        });

        misc:AddButton({
            text = 'Craft',
            callback = funcs.itemCrafter
        });
    end;
end;