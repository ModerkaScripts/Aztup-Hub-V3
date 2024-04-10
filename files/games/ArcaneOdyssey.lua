local library = sharedRequire('../UILibrary.lua');

local Utility = sharedRequire('../utils/Utility.lua');
local Maid = sharedRequire('../utils/Maid.lua');
local Services = sharedRequire('../utils/Services.lua');

local ControlModule = sharedRequire('../classes/ControlModule.lua');
local createBaseESP = sharedRequire('@utils/createBaseESP.lua');
local EntityESP = sharedRequire('@classes/EntityESP.lua');
local ToastNotif = sharedRequire('@classes/ToastNotif.lua');
local Textlogger = sharedRequire('@classes/TextLogger.lua');

local column1, column2 = unpack(library.columns);

local ReplicatedStorage, Players, RunService, CollectionService, Lighting, UserInputService, VirtualInputManager, TeleportService, MemStorageService, TweenService, HttpService, Stats, NetworkClient, GuiService = Services:Get(
	'ReplicatedStorage',
	'Players',
	'RunService',
	'CollectionService',
	'Lighting',
	'UserInputService',
	getServerConstant('VirtualInputManager'),
	'TeleportService',
	'MemStorageService',
	'TweenService',
	'HttpService',
	'Stats',
	'NetworkClient',
	'GuiService'
);

local chatLogger = Textlogger.new({
	title = 'Chat Logger',
	preset = 'chatLogger',
	buttons = {'Copy Username', 'Copy User Id', 'Copy Text', 'Report User'}
});

do -- // Chat Logger
    chatLogger.OnPlayerChatted:Connect(function(player, message)
		local timeText = DateTime.now():FormatLocalTime('H:mm:ss', 'en-us');
		local playerName = player.Name;

		message = ('[%s] [%s] %s'):format(timeText, playerName, message);

		chatLogger:AddText({
			text = message,
			player = player
		});
    end);
end;

local maid = Maid.new();

local LocalPlayer = Players.LocalPlayer;

local functions = {};

local IsA = game.IsA;

local map = workspace.Map;
local RS = ReplicatedStorage:WaitForChild('RS',9e9)
local Remotes = RS:WaitForChild('Remotes',9e9);
local Modules = RS.Modules;

local updateLastSeen = Remotes.Misc.UpdateLastSeen;
local staminaCost = Remotes.Combat.StaminaCost;
local toolAction = Remotes.Misc.ToolAction;
local setTarget = Remotes.NPC.SetTarget;
local actionTrigger = Remotes.NPC.ActionTrigger;
local targetBehavior = Remotes.NPC.TargetBehavior;
local updateHunger = Remotes.UI.UpdateHunger;
local fishClock = Remotes.Misc.FishClock;
local fishState = Remotes.Misc.FishState

--Modules
local attackClient = require(RS.Modules.AttackClient);
local sharkModule = require(RS.Modules.Sharks);
local figureActions = require(RS.Modules.FigureActions);
local cam = workspace.CurrentCamera;

--Useful Functions
local function findTool(toolName)
    local tool = LocalPlayer.PlayerGui.Backpack:FindFirstChild(toolName,true);
    if not tool then return; end

    return tool.Tool.Value;
end

do --Hooks
    local oldDealsStrengthDamage = attackClient.DealsStrengthDamage;
    local oldDealsWeaponDamage = attackClient.DealsWeaponDamage;
    local oldAOESpellDamage = attackClient.AOESpellDamage;
    local oldDealBossDamage = attackClient.DealBossDamage;
    local oldSharkBiteDamage = sharkModule.SharkBiteDamage;
    local oldSideDamageTouch = figureActions.SideDamageTouch;

    local function newDealsStrengthDamage(num,character,...)
        if character == LocalPlayer.Character and library.flags.hitMultiplier then
            for i = 1, library.flags.hitMultiplierValue-1 do
                oldDealsStrengthDamage(num,character,...);
            end
        end
        if character ~= LocalPlayer and library.flags.disableMobDamage then
            return;
        end
        return oldDealsStrengthDamage(num,character,...);
    end

    local function newDealsWeaponDamage(num,character,...)
        if character == LocalPlayer.Character and library.flags.hitMultiplier then
            for i = 1, library.flags.hitMultiplierValue-1 do
                oldDealsWeaponDamage(num,character,...);
            end
        end
        if character ~= LocalPlayer and library.flags.disableMobDamage then
            return;
        end
        return oldDealsWeaponDamage(num,character,...);
    end

    local function newAOESpellDamage(character,...)
        if character == LocalPlayer.Character and library.flags.hitMultiplier then
            for i = 1, library.flags.hitMultiplierValue-1 do
                oldAOESpellDamage(character,...);
            end
        end
        if character ~= LocalPlayer and library.flags.disableMobDamage then
            return;
        end
        return oldAOESpellDamage(character,...);
    end

    local function newDealBossDamage(...)
        if library.flags.disableMobDamage then
            return;
        end
        return oldDealBossDamage(...);
    end

    local function newSharkDamage(...)
        if library.flags.disableMobDamage then
            return;
        end
        return oldSharkBiteDamage(...);
    end

    local function newSideDamageTouch(...)
        local args = {...};
        if library.flags.disableMobDamage and args[3] ~= true then
            return;
        end
        return oldSideDamageTouch(...);
    end

    attackClient.DealsStrengthDamage = newDealsStrengthDamage;
    attackClient.DealsWeaponDamage = newDealsWeaponDamage;
    attackClient.AOESpellDamage = newAOESpellDamage;
    attackClient.DealBossDamage = newDealBossDamage;
    sharkModule.SharkBiteDamage = newSharkDamage;
    figureActions.SideDamageTouch = newSideDamageTouch;

    local oldNamecall;

    local function onNamecall(self, ...)
		SX_VM_CNONE();

		local method = getnamecallmethod();

		if (method == 'FireServer' and IsA(self, getServerConstant('RemoteEvent'))) then
            if (self == setTarget or self == actionTrigger) and library.flags.disableMobAggro then
                return;
            end
		elseif (method == 'InvokeServer' and IsA(self, getServerConstant('RemoteFunction'))) then
            if (self == targetBehavior and library.flags.disableMobAggro) then
                return;
            end
        end

		return oldNamecall(self, ...);
	end;

    oldNamecall = hookmetamethod(game, '__namecall', onNamecall);

end

do --Misc Functions
    local coldFreshWaterObject;
    local warmFreshWaterObject

    local function getColdWater()
        for i,v in next, workspace.Map.Whitesummit:GetDescendants() do
            if not v:IsA('StringValue') or v.Value ~= 'Freshwater' then continue; end

            coldFreshWaterObject = v.Parent;
            break;
        end
        if coldFreshWaterObject then return coldFreshWaterObject; end

        for i,v in next, RS.UnloadIslands.Whitesummit:GetDescendants() do
            if not v:IsA('StringValue') or v.Value ~= 'Freshwater' then continue; end

            coldFreshWaterObject = v.Parent;
            break;
        end

        return coldFreshWaterObject;
    end

    local function getWarmWater()
        for i,v in next, workspace.Map['Sandfall Isle']:GetDescendants() do
            if not v:IsA('StringValue') or v.Value ~= 'Freshwater' then continue; end

            warmFreshWaterObject = v.Parent;
            break;
        end

        if warmFreshWaterObject then return warmFreshWaterObject; end

        for i,v in next, RS.UnloadIslands['Sandfall Isle']:GetDescendants() do
            if not v:IsA('StringValue') or v.Value ~= 'Freshwater' then continue; end

            warmFreshWaterObject = v.Parent;
            break;
        end

        return warmFreshWaterObject;
    end

    coldFreshWaterObject = getColdWater();
    warmFreshWaterObject = getWarmWater();

    local saltWaterPos = Vector3.new(2790, 395, 6288);
    local warmFreshWaterPos = warmFreshWaterObject.Position;
    local coldFreshWaterPos = coldFreshWaterObject.Position;

    function functions.revealMap()
        for i,v in next, map:GetChildren() do
            if not v:FindFirstChild('DetailsLoaded') then continue; end
            updateLastSeen:FireServer(v.Name,'')
        end
    end

    --Auto Eat Is Simple
    function functions.autoEat(t)
        if not t then maid.autoEat = nil; return; end

        local hungerFunc = getconnections(updateHunger.OnClientEvent)[1].Function;
        local currentHunger = getupvalue(hungerFunc,1);

        updateHunger.OnClientEvent:Connect(function(hungerValue) currentHunger = hungerValue; end);

        local last = tick();
        maid.autoEat = RunService.Stepped:Connect(function()
            if (tick()-last <= 0.1) then return; end;
            last = tick();
            if currentHunger >= library.flags.autoEatValue then return; end

            local foodItem = LocalPlayer.PlayerGui.Backpack:FindFirstChild('HungerIcon',true);
            if not foodItem then return; end

            toolAction:FireServer(foodItem.Parent.Parent.Tool.Value);
        end)
    end

    function functions.autoFish(t)
        if not t then maid.autoFishCast = nil; fishClock:FireServer('StopClock'); return; end

        local last = tick();

        maid.autoFishOnChildAdded = Utility.listenToChildAdded(LocalPlayer.Character, function(obj)
            if (obj.Name == 'FishClock') then
                ToastNotif.new({text = 'You just casted a line.', duration = 10});
            end;
        end);

        maid.autoFishCast = RunService.Stepped:Connect(function()
            if (tick()-last <= 0.2) then return; end
            last = tick();

            if not LocalPlayer.Character:FindFirstChild('FishClock') then

                if library.flags.autoFishValue == 'Cold Freshwater' then
                    fishClock:FireServer(findTool('Fishing Rod'),coldFreshWaterObject,coldFreshWaterPos);
                elseif library.flags.autoFishValue == 'Warm Freshwater' then
                    fishClock:FireServer(findTool('Fishing Rod'),warmFreshWaterObject,warmFreshWaterPos);
                else
                    fishClock:FireServer(findTool('Fishing Rod'),nil,saltWaterPos);
                end
            elseif LocalPlayer.Character:FindFirstChild('FishBiteGoal') then
                fishState:FireServer('Reel');
            end
        end)
    end

    local watercolor1,watercolor2;
    Utility.listenToChildAdded(workspace.Camera,function(obj)
        if obj.Name == "WaterBlur1" then
            watercolor1 = obj;
        elseif obj.Name == "WaterBlur2" then
            watercolor2 = obj;
        end
    end)

    function functions.noUnderwaterEffect(t)
        Lighting.ColorCorrection.Enabled = not t;

        local seaDarkness = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("SeaDarkness");
        if seaDarkness then
            seaDarkness.Enabled = not t;
        end

        repeat 
            task.wait();
            if watercolor1 and watercolor2 then
                watercolor1.Transparency = t and 1 or 0;
                watercolor2.Transparency = t and 1 or 0;
            end
        until not library.flags.disableWaterEffects

        watercolor1.Transparency = t and 1 or 0;
        watercolor2.Transparency = t and 1 or 0;
    end

    function functions.teleportToStoryObjective()
        local quest = cam:FindFirstChild('StoryMarker1');

        if not quest then return; end

        LocalPlayer.Character:PivotTo(quest.CFrame);
    end

    function functions.teleportToQuestObjective()
        local quest = cam:FindFirstChild('QuestMarker1');

        if not quest then return; end

        LocalPlayer.Character:PivotTo(quest.CFrame);
    end

    local lastFogDensity = 0;
    function functions.noFog(t)
        if not t then Lighting.Atmosphere.Density = lastFogDensity; maid.noFog = nil; return; end

        maid.noFog = Lighting.Atmosphere:GetPropertyChangedSignal('Density'):Connect(function()
            Lighting.Atmosphere.Density = 0;
        end);

        lastFogDensity = Lighting.Atmosphere.Density;
        Lighting.Atmosphere.Density = 0;
    end

    local oldAmbient, oldBritghtness = Lighting.Ambient, Lighting.Brightness;
    function functions.fullBright(toggle)
        if(not toggle) then
            maid.fullBright = nil;
            Lighting.Ambient, Lighting.Brightness = oldAmbient, oldBritghtness;
            return
        end;

        oldAmbient, oldBritghtness = Lighting.Ambient, Lighting.Brightness;
        maid.fullBright = Lighting:GetPropertyChangedSignal('Ambient'):Connect(function()
            Lighting.Ambient = Color3.fromRGB(255, 255, 255);
            Lighting.Brightness = 1;
        end);
        Lighting.Ambient = Color3.fromRGB(255, 255, 255);
    end;

    function functions.noBlur(t)
        Lighting.Blur.Enabled = not t;
    end

    local fpsBoostMaid = Maid.new();
    local fpsBoostTab = {};
    function functions.fpsBoost(t)
        SX_VM_CNONE();

        if not t then
            fpsBoostMaid:DoCleaning();
            for i,v in next, fpsBoostTab do
                i.Enabled = v;
            end
            table.clear(fpsBoostTab);
            return;
        end

        for _,gui in next, ReplicatedStorage:GetDescendants() do
            if not gui:IsA("BillboardGui") then continue; end

            fpsBoostTab[gui] = gui.Enabled;

            gui.Enabled = false;
            fpsBoostMaid:GiveTask(gui.AncestryChanged:Connect(function()
                if gui:IsDescendantOf(workspace) then
                    gui.Enabled = true;
                elseif gui:IsDescendantOf(game.ReplicatedStorage) then
                    gui.Enabled = false;
                end
            end));
        end
    end

    function functions.chatLogger(t)
        chatLogger:SetVisible(t);
    end;
end

do --Local Cheat Functions
    local oldAttackSizeMulti = attackClient.AttackSizeMulti;

    function functions.hitBoxExpander(t)
        if not t then attackClient.AttackSizeMulti = oldAttackSizeMulti; return; end

        attackClient.AttackSizeMulti = function(character,...)
            local hitRange = oldAttackSizeMulti(character,...);
            if character == LocalPlayer.Character then
                return hitRange*library.flags.hitboxExtenderValue;
            else
                return hitRange;
            end
        end
    end

    function functions.infiniteStamina()
        local last = tick();
        maid.infStamina = RunService.Stepped:Connect(function()
            if (tick()-last <= 0.1) then return; end;
            last = tick();

            staminaCost:FireServer(-1000,'Dodge');
        end)
    end

    function functions.hideName()
        local playerData = Utility:getPlayerData();
		local head = playerData.head;

        if not head or not head:FindFirstChild("Overhead") then return; end

        head.Overhead:ClearAllChildren();
    end

    function functions.fly(toggle)
		if (not toggle) then
			maid.flyHack = nil;
			maid.flyBv = nil;

			return;
		end;

		maid.flyBv = Instance.new('BodyVelocity');
		maid.flyBv.MaxForce = Vector3.new(math.huge, math.huge, math.huge);

		maid.flyHack = RunService.Heartbeat:Connect(function()
			local playerData = Utility:getPlayerData();
			local head, camera = playerData.head, workspace.CurrentCamera;
			if (not head or not camera) then return end;

			maid.flyBv.Parent = head;
			maid.flyBv.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * library.flags.flyHackValue);
		end);
	end;

    function functions.speedHack(toggle)
		if (not toggle) then
			maid.speedHack = nil;
			maid.speedHackBv = nil;

			return;
		end;

		maid.speedHack = RunService.Heartbeat:Connect(function()
			local playerData = Utility:getPlayerData();
			local humanoid, head = playerData.humanoid, playerData.head;
			if (not humanoid or not head) then return end;

			if (library.flags.fly) then
				maid.speedHackBv = nil;
				return;
			end;

			maid.speedHackBv = maid.speedHackBv or Instance.new('BodyVelocity');
			maid.speedHackBv.MaxForce = Vector3.new(100000, 0, 100000);

			maid.speedHackBv.Parent = not library.flags.fly and head or nil;
			maid.speedHackBv.Velocity = (humanoid.MoveDirection.Magnitude ~= 0 and humanoid.MoveDirection or gethiddenproperty(humanoid, 'WalkDirection')) * library.flags.speedHackValue;
		end);
	end;

    function functions.noClip(toggle)
        if (not toggle) then
            maid.noClip = nil;

            local humanoid = Utility:getPlayerData().humanoid;
            if (not humanoid) then return end;

            humanoid:ChangeState('Physics');
            task.wait();
            humanoid:ChangeState('RunningNoPhysics');

            return;
        end;

        maid.noClip = RunService.Stepped:Connect(function()
            local myCharacterParts = Utility:getPlayerData().parts;

            for _, v in next, myCharacterParts do
                v.CanCollide = false;
            end;
        end);
    end;

    function functions.infiniteJump(toggle)
		if (not toggle) then return end;

		repeat
			local playerData = Utility:getPlayerData();
			local rootPart = playerData.primaryPart;
			if(rootPart and UserInputService:IsKeyDown(Enum.KeyCode.Space)) then
				rootPart.Velocity = Vector3.new(rootPart.Velocity.X, library.flags.infiniteJumpHeight, rootPart.Velocity.Z);
			end;
			task.wait(0.1);
		until not library.flags.infiniteJump;
	end;

    function functions.respawn()
        LocalPlayer.Character:BreakJoints();
    end;

    local onTeleport = Remotes.Misc.OnTeleport;

    function functions.teleportToLocation(cf)
        LocalPlayer.Character:PivotTo(cf * CFrame.new(0, 250, 0));
        firesignal(onTeleport.OnClientEvent, cf.Position);
    end

end

do -- Player ESP
    -- TODO: Add magic to player esp
    local playersData = {};

    local function onPlayerAdded(player)
        local bin = player:WaitForChild('bin', 10); -- bin is like the player datas
        local playerDatas = {};

        local function connectPlayerData(name, object)
            playerDatas[name] = object.Value ~= '' and object.Value or 'None';
            object:GetPropertyChangedSignal('Value'):Connect(function()
                playerDatas[name] = object.Value ~= '' and object.Value or 'None';
            end);
        end;

        local function onDataAdded(object)
            if (object.Name == 'Level') then
                connectPlayerData('level', object);
            elseif (object.Name == 'Awakening') then
                connectPlayerData('awakening', object);
            end;
        end;

        Utility.listenToChildAdded(bin, onDataAdded);
        playersData[player] = playerDatas;
    end;

    local function onPlayerRemoving(player)
        playersData[player] = nil;
    end;

	function EntityESP:Plugin()
		SX_VM_CNONE();

		local playerStats = playersData[self._player] or {};

		return {
			text = string.format('\n[Level: %s] [Awakening: %s]', playerStats.level or 'None', playerStats.awakening or 'None')
		}
	end;

    Utility.listenToChildAdded(Players, onPlayerAdded);
    Utility.listenToChildRemoving(Players, onPlayerRemoving);
end;

local localCheats = column1:AddSection('Local Chests');
local misc = column2:AddSection('Misc');

do -- ESP
    local locations = require(Modules.Locations);
    local regions = locations.Regions; -- All islands of the game

    local islandESP = createBaseESP('islands');
    local enemiesESP = createBaseESP('enemies');
    local npcsESP = createBaseESP('npcs');
    local chestsESP = createBaseESP('chests');

    local islandsName = {};
    local islands = {};

    for regionName, region in next, regions do
        islandESP.new(CFrame.new(region.Center), regionName, nil, true);

        islands[regionName] = region;
        table.insert(islandsName, regionName);
    end;

    table.sort(islandsName, function(a, b)
        return a < b;
    end);

    misc:AddList({text = 'Teleport to island', values = islandsName, noload = true, skipflag = true, callback = function(name)
        functions.teleportToLocation(CFrame.new(islands[name].Center));
    end})

	function Utility:renderOverload(data)
		local sectionNumber = 1;

        local function makeList(folder, section, list)
            local seen = {};

            for name in next, folder do
                if (seen[name]) then continue end;

                seen[name] = true;
                table.insert(list, name);
            end;

            table.sort(list, function(a, b)
                return a < b;
            end);

            for i, name in next, list do
                local toggle = section:AddToggle({
                    text = name,
                    flag = string.format('Show %s', name),
                    state = true
                }):AddColor({
                    text = string.format('%s Color', name),
                    color = Color3.fromRGB(255, 255, 255)
                });

                list[i] = toggle;
            end;
        end

		local function makeEsp(sectionName, espItemHandler)
			sectionNumber = (sectionNumber % 2) + 1;

            local toggles = {};

			local function updateEsp(toggle)
                for _, v in next, toggles do
                    v.visualize.Parent.Visible = toggle;
                end;

				if (not toggle) then
					espItemHandler:Disable();
					maid[sectionName] = nil;
					return;
				end;

				maid[sectionName] = RunService.RenderStepped:Connect(function()
					debug.profilebegin(sectionName .. ' ESP Update');
					espItemHandler:UpdateAll();
					debug.profileend();
				end);
			end;

			local espSection = data['column' .. sectionNumber]:AddSection(sectionName);
			espSection:AddToggle({
				text = 'Enable',
				flag = sectionName,
				callback = updateEsp
			});

			espSection:AddToggle({
				text = 'Show Distance',
				flag = sectionName .. ' Show Distance'
			});

			espSection:AddSlider({
				text = 'Max Distance',
				flag = sectionName .. ' Max Distance',
				min = 100,
				value = 100000,
				max = 100000,
				float = 100,
				textpos = 2
			});

			return espSection, toggles;
		end;

        local islandSection, toggles = makeEsp('Islands', islandESP);
        makeList(regions, islandSection, toggles);


        local function makeNpcForFolders(folders, esp, options)
            local espSection = makeEsp(options.espName, esp);

            if (options.showHealth) then
                espSection:AddToggle({text = 'Show Health', flag = options.showHealthFlag});
            end;

            local seenEnemies = {};

            for _, enemy in next, folders do
                Utility.listenToChildAdded(enemy, function(obj)
                    if (seenEnemies[obj]) then return end;
                    seenEnemies[obj] = true;
                    local root = obj:WaitForChild('HumanoidRootPart', 1);

                    local espObject = esp.new(root, obj.Name, nil);
                    obj.Destroying:Connect(function()
                        seenEnemies[obj] = nil;
                        espObject:Destroy();
                    end);
                end);
            end;
        end;

        makeNpcForFolders({RS.UnloadEnemies, workspace.Enemies}, enemiesESP, {espName = 'Enemies', showHealthFlag = 'Enemies Show Health'});
        makeNpcForFolders({RS.UnloadNPCs}, npcsESP, {espName = 'NPCs'});

        -- Chest ESP
        local islandFolders = {RS.UnloadIslands, workspace.Map};

        for _, islandFolder in next, islandFolders do
            Utility.listenToChildAdded(islandFolder, function(island)
                local chestsFolder = island:FindFirstChild('Chests') or island:FindFirstChild('TempChests');
                if (not chestsFolder) then return end;

                Utility.listenToChildAdded(chestsFolder, function(obj)
                    local ocf = obj:WaitForChild('OCF', 1); -- chest cframe value
                    if (not ocf) then return end;

                    local root = obj.PrimaryPart;
                    if (not root) then return end;

                    local espObject;
                    local chestName = obj.Name;

                    if (root.Transparency == 0) then
                        espObject = chestsESP.new(ocf.Value, chestName, nil, true);
                    end;

                    root:GetPropertyChangedSignal('Transparency'):Connect(function()
                        if (espObject) then espObject:Destroy(); end;

                        if (root.Transparency == 0) then
                            espObject = chestsESP.new(ocf.Value, chestName, nil, true);
                        end;
                    end);
                end);
            end);
        end;

        local section = makeEsp('Chests', chestsESP);

        local chestTypes = { --t hx chat gpt <3
            "Food Crate",
            "Uncommon Food Crate",
            "Rare Food Crate",
            "Scroll Chest",
            "Uncommon Scroll Chest",
            "Sailor Chest",
            "Ingredient Bag",
            "Rare Ingredient Bag",
            "Uncommon Ingredient Bag",
            "Treasure Chest",
            "Rare Scroll Chest",
            "Armor Chest",
            "Great Armor Chest",
            "Elite Armor Chest",
            "Weapon Chest",
            "Great Weapon Chest",
            "Elite Weapon Chest",
            "Private Storage",
            "Silver Chest",
            "Great Sailor Chest",
            "Elite Sailor Chest",
            "Golden Chest"
        }

        for _, chestType in next, chestTypes do
            section:AddToggle({
                text = string.format('Show %s', chestType)
            }):AddColor({
                text = string.format('%s Color', chestType)
            });
        end;
	end;
end;

localCheats:AddToggle({
    text = 'Fly',
    callback = functions.fly
}):AddSlider({
    min = 16,
    max = 200,
    flag = 'Fly Hack Value'
});

localCheats:AddToggle({
    text = 'Speedhack',
    callback = functions.speedHack
}):AddSlider({
    min = 16,
    max = 200,
    flag = 'Speed Hack Value'
});

localCheats:AddToggle({
    text = 'Infinite Jump',
    callback = functions.infiniteJump
}):AddSlider({
    min = 50,
    max = 250,
    flag = 'Infinite Jump Height'
});

localCheats:AddToggle({
    text = 'No Clip',
    callback = functions.noClip
});

localCheats:AddButton({text = 'Infinite Stamina (risky)', tip = 'Gives you infinite stamina', callback = functions.infiniteStamina});
localCheats:AddButton({text = 'Hide Name', tip = 'Hides your name from other players', callback = functions.hideName});

localCheats:AddToggle({ ----DealWeaponDamage,DealStrengthDamage hook: If you are the 2nd damage argument then fire the remote multiple times
    text = 'Hit Multiplier',
    tip = 'Makes mobs not attack/notice you'
}):AddSlider({
    min = 1,
    max = 10,
    float = 1,
    value = 1,
    flag = 'Hit Multiplier Value'
});

localCheats:AddToggle({ ----DealWeaponDamage,DealStrengthDamage hook: If you are the 2nd damage argument then fire the remote multiple times
    text = 'Hitbox Extender',
    tip = 'Increases your attack range',
    callback = functions.hitBoxExpander
}):AddSlider({
    min = 1,
    max = 100,
    float = 1,
    value = 1,
    flag = 'Hitbox Extender Value'
});

localCheats:AddToggle({text = 'Disable Mob Aggro', tip = 'Makes mobs not attack/notice you'}); --SetTarget and ActionTrigger hook make it return

localCheats:AddToggle({text = 'Disable Mob Damage', tip = 'Makes mob attacks do no damage to you'}); --DealWeaponDamage,DealStrengthDamage hook: 2nd argument should always be your player not the enemy

--Misc Section
misc:AddButton({text = 'Reveal Map', tip = 'Makes you learn the entire map instantly', callback = functions.revealMap});

misc:AddButton({text = 'Teleport To Story Marker',tip = 'Teleports you to your current story objective if you have one', callback = functions.teleportToStoryObjective});
misc:AddButton({text = 'Teleport To Quest Marker',tip = 'Teleports you to your current quest objective if you have one', callback = functions.teleportToQuestObjective});

misc:AddButton({text = 'Respawn', callback = functions.respawn});

misc:AddToggle({
    text = 'Auto Eat',
    tip = 'Will eat any item in your hotbar if its below the value specified',
    callback = functions.autoEat
}):AddSlider({
    min = 1,
    max = 100,
    float = 1,
    value = 1,
    flag = 'Auto Eat Value'
});

misc:AddToggle({
    text = 'Auto Fish',
    tip = 'Will automatically fish for you, keep your fishing rod in your hotbar/inventory',
    callback = functions.autoFish
}):AddList({
    text = 'Water Type',
    flag = 'Auto Fish Value',
    values = {'Saltwater','Cold Freshwater', 'Warm Freshwater'},
});

misc:AddToggle({
    text = "Fps Booster",
    tip = "Does some changes to the game to improve overall fps",
    callback = functions.fpsBoost
});

misc:AddToggle({text = 'Chat Logger', callback = functions.chatLogger});

misc:AddToggle({text = "Disable Shadows", tip = "Enabling this will also increase your fps", callback = function(toggle)
    Lighting.GlobalShadows = not toggle;
end});

misc:AddToggle({
    text = "No Fog",
    tip = "Disables fog",
    callback = functions.noFog
});

misc:AddToggle({
    text = "Full Bright",
    tip = "Makes the game brighter",
    callback = functions.fullBright
});

misc:AddToggle({
    text = "No Blur",
    tip = "Disables the ingame blur",
    callback = functions.noBlur
});

misc:AddToggle({
    text = "Disable Water Effects",
    tip = "Disables the effects like color, and obscured vision while underwater",
    callback = functions.noUnderwaterEffect
});