local library = sharedRequire('../UILibrary.lua');

local Utility = sharedRequire('../utils/Utility.lua');
local Maid = sharedRequire('../utils/Maid.lua');
local Services = sharedRequire('../utils/Services.lua');

local ToastNotif = sharedRequire('../classes/ToastNotif.lua');
local makeESP = sharedRequire('@utils/makeESP.lua');

local ReplicatedStorage, Players, RunService = Services:Get(
	'ReplicatedStorage',
	'Players',
	'RunService'
);

local LocalPlayer = Players.LocalPlayer;
local FindFirstChild = game.FindFirstChild;

local column1, column2 = unpack(library.columns);

local functions = {};
local maid = Maid.new();

column1:AddSection()

local ItemData  = ReplicatedStorage:WaitForChild("ItemData");
local Remotes = ReplicatedStorage:WaitForChild("Remotes");
local Stats = LocalPlayer:WaitForChild("stats");
local Map = workspace:WaitForChild("Map");

local ItemTypes = {
    ["Melee"]   = {
        ["Hammer"] = true,
        ["Dagger"] = true,
        ["Axe"] = true,
        ["Spear"] = true,
        ["Sword"] = true,
        ["Rapier"] = true,
        ["Polearm"] = true,
        ["Greatsword"] = true,
        ["Katana"] = true,
		["TowerShield"] = true
    },
    Bow = {
        ["Bow"] = true,
        ["Crossbow"] = true,
    },
    Staff   = {
        ["Staff"] = true,
        ["Wand"] = true,
        ["Book"] = true,
    }
}

local Rarities = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Mythic",
	"Legendary",
	"Godlike"
}

local function getWeapons()
	local toCheck = {
        Stats.Equipped:FindFirstChild("Wep1"),
        Stats.Equipped:FindFirstChild("Wep2"),
    }
	return toCheck;
end

local function getWeaponType()
	local toCheck   = {
        Stats.Equipped:FindFirstChild("Wep1"),
        Stats.Equipped:FindFirstChild("Wep2"),
    }
	local weaponTypes = {};

	for wepType,wepTab in next, ItemTypes do
		for _, wep in next, toCheck do
			if wepTab[wep.ItemType.Value] then
				table.insert(weaponTypes,wepType);
			end
		end
	end

	return weaponTypes;
end

local function getWeaponInfo()
	local weps = getWeapons();
	local wep1,wep2 = weps[1],weps[2];

	local weaponInfo = {};
	if wep1 then table.insert(weaponInfo,ItemData:FindFirstChild(wep1.ItemID.Value,true)); end
	if wep2 then table.insert(weaponInfo,ItemData:FindFirstChild(wep2.ItemID.Value,true)); end

	return weaponInfo;
end

local function getAttackSpeed()
	local weps = getWeapons();
	local weapon1,weapon2 = weps[1],weps[2];

	local weaponInfo = getWeaponInfo()
	local wepInfo1, wepInfo2 = weaponInfo[1], weaponInfo[2];

	local attackSpeed;
	if weapon1 and FindFirstChild(wepInfo1,"AttackSpeed") then
		attackSpeed = (1 / (wepInfo1.AttackSpeed.Value * 1.03 ^ (weapon1.Rarity.Value - wepInfo1.BaseRarity.Value) * (1 + 0 / 100)));
	end

	if weapon2 and FindFirstChild(wepInfo2,"AttackSpeed") then
		local tempSpeed = (1 / (wepInfo2.AttackSpeed.Value * 1.03 ^ (weapon2.Rarity.Value - wepInfo2.BaseRarity.Value) * (1 + 0 / 100)));
		if attackSpeed > tempSpeed then attackSpeed = tempSpeed; end
	end

	return attackSpeed;
end

do --functions

    local pingTask;
    local oldNamecall;
    local pingRemote = Remotes.Ping;
	local meleeRemote = Remotes.Action.MeleeAttack;
	local activateRemote = Remotes.Action.ActivateAbility;
	local sellRemote = Remotes.UI.MassSell;
	local replayRemote = Remotes.UI.EndDungeon.EndOfDungeonVote;

	local npcs = {};
	local itemsToSell = {};

    local function onNamecall(self,...)
		SX_VM_CNONE();
        if self == pingRemote and getnamecallmethod() == "InvokeServer" and ({...})[1] == "ping" and (#({...})) == 1 and library.flags.speedHack then
			return;
        end
		if self == meleeRemote and getnamecallmethod() == "FireServer" and library.flags.attackRate then
			local args = {...};
			local newTargets = {};
			for _, target in next, args[2].Targets do
				for i = 1, library.flags.attackRateValue do
					table.insert(newTargets,target)
				end
			end
			args[2].Targets = newTargets;

            return originalFunctions.fireServer(self, unpack(args));
		end
        return oldNamecall(self,...);
    end

    function functions.speedHack(toggle)
		if (not toggle) then
			maid.speedHack = nil;
			maid.speedHackBv = nil;

			if not pingTask then return; end

            pingRemote.OnClientInvoke = function() return; end
            task.cancel(pingTask);
			return;
		end;

		ToastNotif.new({text = "Please allow up to 5 for the speed hack to initialize",duration = 10});

        pingTask = task.spawn(function()
            while true do
				pingRemote.OnClientInvoke = function() task.wait(5) return; end
                originalFunctions.invokeServer(pingRemote, 'ping');
				task.wait(5);
            end
        end)

		maid.speedHack = RunService.Heartbeat:Connect(function()
			local character = LocalPlayer.Character;
			if (not character) then return end;

			local humanoid = character:FindFirstChildWhichIsA('Humanoid');
			local rootPart = character.PrimaryPart;

			if (library.flags.fly) then
				maid.speedHackBv = nil;
				return;
			end;

			if (not humanoid or not rootPart) then return end;

			maid.speedHackBv = maid.speedHackBv or Instance.new('BodyVelocity');
			maid.speedHackBv.MaxForce = Vector3.new(100000, 0, 100000);

			maid.speedHackBv.Parent = not library.flags.fly and rootPart or nil;
			maid.speedHackBv.Velocity = humanoid.MoveDirection * library.flags.speedHackValue;
		end);
	end;

	function functions.killAura(toggle)
		if not toggle then
			maid.killAura = nil;
			maid.killAuraCon = nil;
			table.clear(npcs);
			return;
		end

		print(getWeaponType()[1],getWeaponType()[2] )
		if (getWeaponType()[1] ~= "Melee" and getWeaponType()[2] ~= "Melee") then ToastNotif.new({text ="Only Melee weapons can use this feature",duration = 10}); library.options.killAura:SetState(false); end

		maid.killAuraCon = Utility.listenToChildAdded(workspace.NPCS, function(obj)
			local rootPart = obj:WaitForChild('HumanoidRootPart', 10);
			local humanoid = obj:WaitForChild('Humanoid', 10);
			if (not rootPart or not humanoid) then return end;

			local t = {
				rootPart = rootPart,
				humanoid = humanoid,
				character = obj
			};

			table.insert(npcs, t);

			humanoid.Died:Connect(function()
				for i,v in next, npcs do
					if v == t then
						npcs[i] = nil;
					end
				end
			end);

			obj.Destroying:Connect(function()
				for i,v in next, npcs do
					if v == t then
						npcs[i] = nil;
					end
				end
			end);
		end);

		local didAt = 0;
		local attackSpeed = getAttackSpeed();
		maid.killAura = RunService.Heartbeat:Connect(function()
			local t = {};
			if not LocalPlayer.Character then return; end

			local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart");
			if not rootPart then return; end

			local rootPartPos = rootPart.Position;

			for _, npc in next, npcs do
				if ((npc.rootPart.Position - rootPartPos).Magnitude > library.flags.killAuraDistance or npc.humanoid.Health <= 0) then continue end;
				table.insert(t, {
					TargetCharacter = npc.character,
					KnockbackDirection = Vector3.zero
				})
			end;

			if (#t <= 0 or tick() - didAt < attackSpeed) then return end;
			didAt = tick();

			meleeRemote:FireServer(1, {Targets = t});
		end);
	end

	function functions.attackRate(toggle)
		if not toggle then return; end
		if (getWeaponType()[1] ~= "Melee" and getWeaponType()[2] ~= "Melee") then ToastNotif.new({text ="Only Melee weapons can use this feature",duration = 10}); library.options.attackRate:SetState(false); end
	end

	function functions.autoPotion(toggle)
		if not toggle then maid.autoPotion = nil; return; end

		maid.autoPotion = RunService.Heartbeat:Connect(function()
			local character = LocalPlayer.Character;
			if (not character) then return end;

			local humanoid = character:FindFirstChildWhichIsA('Humanoid');
			if not humanoid then return; end

			if (humanoid.Health/humanoid.MaxHealth*100) <= library.flags.autoPotionValue then
				activateRemote:FireServer(6)
			end
		end)
	end

	function functions.autoSell(toggle)
		if not toggle then maid.autoSell = nil; table.clear(itemsToSell); return; end

		local lastAutoSell = tick();

		maid.autoSell = Utility.listenToChildAdded(Stats.Inventory,function(obj)
			if not obj:FindFirstChild("Rarity") then return; end

			local objRarity = obj.Rarity.Value; --This is a int value need to be compared against Rarities table

			for rarity,bool in next, library.flags.autoSellValue do
				if bool and (rarity == Rarities[objRarity+1]) then
					table.insert(itemsToSell,{Item = obj,Count = 1})
				end
			end
		end)


		maid.autoSellLoop = RunService.Heartbeat:Connect(function()
			if tick() - lastAutoSell <= 1 or #itemsToSell == 0 then return; end --Don't fire remote unnecessarily

			lastAutoSell = tick();
			sellRemote:FireServer(itemsToSell);
			table.clear(itemsToSell);
		end)
	end

	function functions.autoReplay(toggle)
		if not toggle then maid.autoReplay = nil; return; end

		maid.autoReplay = Map.DescendantAdded:Connect(function(child)
			if child.Name == "LootPrompt" then
				replayRemote:FireServer("ReplayDungeon");
			end
		end)

		if Map:FindFirstChild("LootPrompt",true) then
			replayRemote:FireServer("ReplayDungeon");
		end
	end;

	function functions.maxLevelBattlePass()
		for _, v in next, getconnections(ReplicatedStorage.Remotes.UI.Message.OnClientEvent) do
			v:Disable();
		end;

		for i = 1, 30000 do
			originalFunctions.fireServer(ReplicatedStorage.Remotes.UI.VenturePass.PurchaseLevel, 0.00142)
		end;
	end;

	oldNamecall = hookmetamethod(game,"__namecall",onNamecall);
end;

local localCheats = column1:AddSection("Local Cheats");
local misc = column2:AddSection("Misc");

do --//Mob ESP
	local function onNewMobAdded(mob, espConstructor)
		local code = [[
			local FindFirstChild = game.FindFirstChild;
			local FindFirstChildWhichIsA = game.FindFirstChildWhichIsA;
			local mob = ...;

			return setmetatable({
				FindFirstChildWhichIsA = function(_, ...)
					return FindFirstChildWhichIsA(mob, ...);
				end,
			}, {
				__index = function(_, p)
					if (p == 'Position') then
						local mobRoot = FindFirstChild(mob, 'HumanoidRootPart');
						return mobRoot and mobRoot.Position;
					end;
				end,
			});
		]];

		local mobEsp = espConstructor.new({code = code, vars = {mob}}, mob.Name);

		local connection;
		connection = mob:GetPropertyChangedSignal('Parent'):Connect(function()
			if (not mob.Parent) then
				connection:Disconnect();
				mobEsp:Destroy();
			end;
		end);
	end;

	makeESP({
		sectionName = 'Mobs',
		type = 'childAdded',
		args = workspace.NPCS,
		callback = onNewMobAdded,
		onLoaded = function(section)
			section:AddToggle({
				text = 'Show Health',
				flag = 'Mobs Show Health'
			});
		end
	});
end


do -- // Local Cheats
	localCheats:AddButton({
		text = 'Max Level Battle Pass',
		callback = functions.maxLevelBattlePass
	});

	localCheats:AddToggle({
		text = 'Speedhack',
		callback = functions.speedHack
	}):AddSlider({
		min = 16,
		max = 45,
		flag = 'Speed Hack Value'
	});

	localCheats:AddToggle({
		text = 'Damage Multiplier',
		flag = 'Attack Rate',
		callback = functions.attackRate
	}):AddSlider({
		min = 0,
		max = 100,
		flag = 'Attack Rate Value'
	});

	localCheats:AddToggle({
		text = 'Kill Aura',
		callback = functions.killAura
	}):AddSlider({
		min = 0,
		max = 15,
		flag = 'Kill Aura Distance'
	});

	misc:AddToggle({
		text = "Auto Potion",
		callback = functions.autoPotion
	}):AddSlider({
		min = 0,
		max = 100,
		flag = "Auto Potion Value"
	})

	misc:AddToggle({
		text = "Auto Sell",
		callback = functions.autoSell
	}):AddList({
		text = "Select Rarities",
		flag = "Auto Sell Value",
		multiselect = true,
		values = Rarities
	})

	misc:AddToggle({
		text = "Auto Replay",
		callback = functions.autoReplay
	})


end

--Mob ESP