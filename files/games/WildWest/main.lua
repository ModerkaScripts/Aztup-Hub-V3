local Services = sharedRequire('../../utils/Services.lua');
local Utility = sharedRequire('../../utils/Utility.lua');
local library = sharedRequire('../../UILibrary.lua');

local prettyPrint = sharedRequire('../../utils/prettyPrint.lua');

local IsA = game.IsA;
local ReplicatedStorage, Players = Services:Get('ReplicatedStorage', 'Players');

local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local column1, column2 = unpack(library.columns);

local noRain;
local autoGetUp;
local instantBreakFree;
local disableAntiTeleport;

--[[
local Network = require(game:GetService("ReplicatedStorage").SharedModules.Global.Network);
local PlayerCharacter = require(game:GetService("ReplicatedStorage").Modules.Character.PlayerCharacter);

local thingToCheck = getupvalue(Network.FireServer, 4)[6];

for _, v in next, getgc() do
	if (typeof(v) == 'function' and not is_synapse_function(v) and islclosure(v)) then
		local stackData = getupvalues(v)[1];

		if (typeof(stackData) == 'table' and rawget(stackData, 'NumUpvalues')) then
			pcall(function()
				local upvalues = getupvalue(v, 4);

				if (upvalues[6] == thingToCheck) then
					print('found', upvalues[2]);
				end;
			end);
		end;
	end;
end;
-- Get protected functions
]]

do -- // Functions
	-- // Require Modules
	local oldNewIndex;
	oldNewIndex = hookmetamethod(game, '__newindex', function(self, p, v)
		SX_VM_CNONE();
		if (IsA(self, 'Terrain') and p == 'Color' and string.find(debug.traceback(), 'Environment')) then
			warn('ban packet has been blocked!');
			return;
		end;

		return oldNewIndex(self, p, v);
	end);

	local load = require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('Load'));
	local loadShared = require(ReplicatedStorage:WaitForChild('SharedModules'):WaitForChild('Load'));

	load = getupvalue(load, 1);
	loadShared = getupvalue(loadShared, 1);

	if (typeof(load) ~= 'table' or typeof(loadShared) ~= 'table' or getrawmetatable(load) or getrawmetatable(loadShared)) then
		return LocalPlayer:Kick('DM Aztup');
	end;

	-- // Load Local
	local playerCharacter = load.PlayerCharacter;
	local replicatedState = load.ReplicatedState;
	local repCharHandler = load.RepCharHandler;
	local rain = load.Rain;
	local horse = load.Horse;
	local gunItem = load.GunItem;

	local function getOriginalFunction(f)
		local vmStack = getupvalues(f)[1];
		if (typeof(vmStack) ~= 'table' or not rawget(vmStack, 'NumUpvalues')) then
			warn(debug.info(f, 'lsnfa'), 'is not protected');
			return f;
		end;

		local upvalues = getupvalues(f)[4];
		if (not upvalues) then return LocalPlayer:Kick('There was an error. DM Aztup [0]'); end;

		local originalFunction = upvalues[11];

		if (typeof(originalFunction) ~= 'function') then
			return LocalPlayer:Kick('Error occured, dm Aztup [1]');
		end;

		return originalFunction;
	end;

	do
		local internal = rawget(repCharHandler, 'Flags');
		if (typeof(internal) ~= 'table') then
			return LocalPlayer:Kick('Error occured, dm Aztup');
		end;

		local internalMetatable = getrawmetatable(internal);
		local oldNewIndex = internalMetatable.__newindex;
		print(debug.info(oldNewIndex, 'lsnfa'));

		local flags = {'DamageSelf', 'LowerStamina', 'CharacterReplicate'};

		function internalMetatable.__newindex(self, p, v)
			if (p == 'DamageSelf' and library.flags.noFallDamage) then
				return;
			elseif (p == 'LowerStamina' and library.flags.infiniteStamina) then
				return;
			elseif (not table.find(flags, p)) then
				if (debugMode) then
					return LocalPlayer:Kick(p);
				end;

				return LocalPlayer:Kick('WildWest has attempted to detect the script please, DM Aztup');
			end;

			return oldNewIndex(self, p, v);
		end;
	end;

	-- // Load Shared
	local network = loadShared.Network;
	local projectileHandler = loadShared.ProjectileHandler;

	do -- // Network hook
		_G.blacklisted = {};
		_G.blacklisted.CharUpdate = true;
		_G.blacklisted.UpdateCharacterSpring = true;
		_G.blacklisted.CamPosReplicate = true;
		_G.blacklisted.StopSpectate = true;
		_G.blacklisted.UpdateCharacterAnimation = true;

		local fireServer = getOriginalFunction(network.FireServer);

		hookUV1 = {};
		hookUV1.prettyPrint = prettyPrint;
		hookUV1.debugMode = debugMode;
		hookUV1.library = library;
		hookUV1.print = print;
		hookUV1._G = _G;

		local function test(self, remote, ...)
			local args = {...};

			if(remote == 'DamageSelf' and hookUV1.library.flags.noFallDamage) then
				return;
			end;

			if(hookUV1.debugMode and not hookUV1._G.blacklisted[remote]) then
				hookUV1.print(hookUV1.prettyPrint({__remote = remote, ...}));
			end;

			return hookUV1.oldFireServer(self, remote, ...);
		end;

		table.foreach(getupvalues(test), warn);
		hookUV1.oldFireServer = hookfunction(fireServer, test);
	end;

	do -- // Infinite Stamina
		local lowerStamina = getOriginalFunction(playerCharacter.LowerStamina);
		local oldLowerStamina;

		oldLowerStamina = hookfunction(lowerStamina, function(...)
			if(library.flags.infiniteStamina) then return end;
			disableenvprotection();
			local a = {oldLowerStamina(...)};
			enableenvprotection();

			return unpack(a);
		end);
	end;

	do -- // New Gun cheats
		local oldCalculateRecoil = gunItem.CalculateRecoil; --, setCalculateRecoil = getOriginalFunction(gunItem.CalculateRecoil);

		function gunItem.CalculateRecoil(...)
			if(library.flags.noRecoil) then return 0 end;
			disableenvprotection();
			local a = {oldCalculateRecoil(...)};
			enableenvprotection();

			return unpack(a);
		end;
	end;

	do -- // Anti Ragdoll
		local enterRagdoll = getOriginalFunction(playerCharacter.Ragdoll);
		local oldEnterRagdoll;

		oldEnterRagdoll = hookfunction(enterRagdoll, function(...)
			if (library.flags.antiRagdoll) then return end;
			disableenvprotection();
			local a = {oldEnterRagdoll(...)};
			enableenvprotection();

			return unpack(a);
		end);
	end;

	do -- // IsTeamMate
		function Utility:isTeamMate(player)
			local playerInfo = repCharHandler:GetRepChar(player);
			if(not playerInfo.CharInfo) then
				return false;
			end;

			if(playerInfo.CharInfo.ProtectionStatus) then
				return true;
			end;

			if (not player.Team) then
				return false
			end

			if(not playerCharacter.State.WeaponSafetyEnabled) then
				return false;
			end;

			return player.Team == LocalPlayer.Team;
		end;

		function Utility:getCharacter(player)
			local playerState = replicatedState:GetPlayerState(player).ReplicatedState.Root;
			local health = playerState.Health or 0;
			local floatHealth = (health / 100) * 100;

			return player.Character, 100, floatHealth, math.floor(health);
		end;
	end;

	do -- // Silent Aim
		local initProjectile = getOriginalFunction(projectileHandler.InitProjectiles);
		local playersData = {};

		local upvalues = {};
		upvalues.playersData = playersData;
		upvalues.library = library;
		upvalues.Utility = Utility;

		local function onCharacterAdded(character)
			local destroyed = false;

			character.Destroying:Connect(function()
				destroyed = true;
				task.cancel(playersData[character].task);
				playersData[character] = nil;
			end);

			local rootPart = character:WaitForChild('HumanoidRootPart', 10);
			if (not rootPart or destroyed) then return end;

			local playerData;
			playerData = {
				lastPosition = rootPart.Position,
				velocity = Vector3.zero,
				task = task.spawn(function()
					while true do
						local delta = task.wait();
						local velocity = (rootPart.Position - playerData.lastPosition) / delta;

						playerData.lastPosition = rootPart.Position;
						playerData.velocity = velocity;
					end;
				end)
			};

			playersData[character] = playerData;
		end

		workspace.WORKSPACE_Entities.Players.ChildAdded:Connect(onCharacterAdded);

		for _, player in next, workspace.WORKSPACE_Entities.Players:GetChildren() do
			task.spawn(onCharacterAdded, player);
		end;

		upvalues.oldInitProjectile = hookfunction(initProjectile, function(self, projectileType, sharedData, info, callback, ...)
			if (upvalues.library.flags.silentAim) then
				local target = upvalues.Utility:getClosestCharacter();
                local targetHead;

                if (library.flags.headShotRate < Random.new():NextInteger(1,100)) then
					targetHead = target.Character and target.Character:FindFirstChild('UpperTorso');
                else
					targetHead = target.Character and target.Character:FindFirstChild('Head');
                end

				if (targetHead) then
					local projectileSpeed = sharedData.ProjectilePower;
					local timeToHit = (info.origin - targetHead.Position).Magnitude / projectileSpeed;
					local bulletDrop = upvalues.library.flags.bulletDropPrediction and 0.5 * 32 * timeToHit ^ 2 or 0;
					local targetPosition = (targetHead.Position - info.origin) + Vector3.new(0, bulletDrop, 0);

					local playerData = upvalues.playersData[target.Character];
					if (playerData) then
						targetPosition += playerData.velocity * timeToHit;
					end;

					info.accuracy = 1;
					info.direction = targetPosition.Unit;
				end;
			end;

			disableenvprotection();
			local data = {upvalues.oldInitProjectile(self, projectileType, sharedData, info, callback, ...)};
			enableenvprotection();

			return unpack(data);
		end);
	end;

	do -- // New Horse Speed
		local oldControlUpdate = horse.ControlUpdate; --, setControlUpdate = getOriginalFunction(horse.ControlUpdate);

		function horse.ControlUpdate(self, ...)
			oldControlUpdate(self, ...);

			if(not self._maxSpeed) then
				self._maxSpeed = self.MaxSpeed;
			end;

			if(library.flags.horseSpeed) then
				self.InputReleasedDecelerateTime = 0;
				self.WalkSpeedGoal = self._maxSpeed * 1.5;
				self.WalkSpeed = self._maxSpeed * 1.5;
				self.LastMaxSpeedGoal = self._maxSpeed * 1.5;
				self.MaxSpeed = self._maxSpeed * 1.5;
			else
				self.MaxSpeed = self._maxSpeed;
			end;
		end;
	end;

	function noRain(toggle)
		if (not toggle) then return end;

		repeat
			rain:Disable();
			wait(0.5);
		until not library.flags.noRain;
	end;

	-- // TODO: Remake this
	function autoGetUp(toggle)
		if (not toggle) then return end;

		repeat
			task.wait();

			if (not playerCharacter:CanGetUp()) then continue end;
			playerCharacter:GetUp();
		until not library.flags.autoGetUp;
	end;

	function instantBreakFree(toggle)
		if (not toggle) then return end;

		repeat
			task.wait();

			if (not playerCharacter:CanBreakFree()) then continue end;
			network:FireServer('AttemptBreakFree');
			task.wait(0.5);
		until not library.flags.instantBreakFree;
	end;
end;

local Main = column1:AddSection('Main');
local GunCheats = column2:AddSection('Guns');
local Misc = column2:AddSection('Misc');

Main:AddToggle({text = 'Infinite Stamina'});
Main:AddToggle({text = 'No Fall Damage'});
Main:AddToggle({text = 'Anti Ragdoll'});
Main:AddToggle({text = 'Auto Get Up', callback = autoGetUp});
Main:AddToggle({text = 'Instant Break Free', callback = instantBreakFree});
Main:AddToggle({text = 'Horse Speed'});

GunCheats:AddToggle({text = 'Silent Aim'})
GunCheats:AddSlider({
    text = 'Head Shot Rate',
    tip = 'Determines the rate of a headshot',
    suffix = '%',
    min = 0,
    max = 100,
    float = 1,
    value = 100
});

GunCheats:AddToggle({text = 'Bullet Drop Prediction'});
GunCheats:AddToggle({text = 'No Recoil'});

Misc:AddToggle({text = 'No Rain', callback = noRain});