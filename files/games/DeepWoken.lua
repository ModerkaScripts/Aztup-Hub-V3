local library = sharedRequire('../UILibrary.lua');

local AudioPlayer = sharedRequire('@utils/AudioPlayer.lua');
local makeESP = sharedRequire('@utils/makeESP.lua');

local Utility = sharedRequire('../utils/Utility.lua');
local Maid = sharedRequire('../utils/Maid.lua');
local AnalyticsAPI = sharedRequire('../classes/AnalyticsAPI.lua');

local Services = sharedRequire('../utils/Services.lua');
local createBaseESP = sharedRequire('../utils/createBaseESP.lua');

local EntityESP = sharedRequire('../classes/EntityESP.lua');
local ControlModule = sharedRequire('../classes/ControlModule.lua');
local ToastNotif = sharedRequire('../classes/ToastNotif.lua');

local BlockUtils = sharedRequire('../utils/BlockUtils.lua');
local TextLogger = sharedRequire('../classes/TextLogger.lua');
local fromHex = sharedRequire('../utils/fromHex.lua');
local toCamelCase = sharedRequire('../utils/toCamelCase.lua');
local Webhook = sharedRequire('../utils/Webhook.lua');
local Signal = sharedRequire('../utils/Signal.lua');

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

local droppedItemsNames = originalFunctions.jsonDecode(HttpService, sharedRequire('@games/DeepwokenItemsNames.json'));

local LocalPlayer = Players.LocalPlayer;
local playerMouse = LocalPlayer:GetMouse();

local functions = {};

local myRootPart;

local IsA = game.IsA;
local FindFirstChild = game.FindFirstChild;
local FindFirstChildWhichIsA = game.FindFirstChildWhichIsA;
local IsDescendantOf = game.IsDescendantOf;

local blockRemote;
local unblockRemote;

local dodgeRemote;
local stopDodgeRemote;
local rightClickRemote;
local dialogueRemote;
local leftClickRemote;
local dropToolRemote;
local serverSwimRemote;
local fallRemote;

local maid = Maid.new();

-- Player is server hopping

if (game.PlaceId == 4111023553) then
	if (MemStorageService:HasItem('DataSlot')) then
		ToastNotif.new({
			text = 'Server hopping...'
		});

		ReplicatedStorage.Requests.StartMenu.Start:FireServer(MemStorageService:GetItem('DataSlot'), {
			PrivateTest = false
		});

		task.wait(0.3);

		ReplicatedStorage.Requests.StartMenu.PickServer:FireServer('none');
		MemStorageService:RemoveItem('DataSlot');
	else
		ToastNotif.new({
			text = 'Script will not run in lobby'
		});
	end;

	return task.wait(9e9);
end;

local remoteEvent = Instance.new('RemoteEvent');
local onParryRequest = function() warn('onParryRequest not implemented'); end;

local inputClient;

local function logError(msg)
	task.spawn(syn.request, {
		Url = '',
		Method = 'POST',
		Headers = {['Content-Type'] = 'application/json'},
		Body = HttpService:JSONEncode({content = msg .. ' ' .. accountData.username})
	});
end;

local debugWebhook = Webhook.new('');

do -- // Hooks
	local oldNamecall;
	local oldNewIndex;

	local oldFireserver;
	local oldDestroy;

	local characterHandler;
	local atmosphere;

	task.spawn(function()
		atmosphere = Lighting:WaitForChild('Atmosphere', math.huge);
	end)

	local getMouse = ReplicatedStorage.Requests.GetMouse;
	local getCameraToMouse = ReplicatedStorage.Requests.GetCameraToMouse;

	local GET_KEY_FUNCTION_HASH = 'dfdcd587cdc8368a9afd04160251e5d69caaa1e6eb19504ddbe0d6243322d035e5b408a2ef283e35dab5be48cdee7f98';

	local getKeyFunction = (function(o)
		SX_VM_CNONE();

		for _, v in next, getgc() do
			if (typeof(v) == getServerConstant('function') and not is_synapse_function(v) and islclosure(v) and debug.info(v, 'n') == getServerConstant('gk') and debug.info(v, 's'):find('InputClient') and typeof(getupvalues(v)[1]) == 'table' and (isSynapseV3 or Utility.getFunctionHash(v) == GET_KEY_FUNCTION_HASH)) then
				return v;
			end;
		end;
	end);

	local getKey;

	if (not LocalPlayer.Character) then
		if (MemStorageService:HasItem('oresFarm') or MemStorageService:HasItem('doWipe')) then
			ReplicatedStorage.Requests.StartMenu.Start:FireServer();
		end;
	end;

	-- If we are in a dungeon instance we wait for the game to fully load cause some stuff could be missing
	if (game.PlaceId == 8668476218) then
		repeat
			if (workspace:FindFirstChild('One') and workspace.One:FindFirstChild('TrialOfOne')) then break end;
			print('Waiting for get getkey func');
			getKey = getKeyFunction();
			task.wait(1);
		until getKey;
	end;

	local setscriptes = isSynapseV3 and function() end or getupvalue(getgenv().syn.secure_call, 9);

	local function isRemoteInvalid(remote)
		SX_VM_CNONE();

		if (not remote) then return true; end;
		return not IsDescendantOf(remote, game);
	end;

	local sent = false;

	local function onCharacterAdded(character)
		local humanoid = character:WaitForChild('Humanoid');
		local currentHealth = humanoid.Health;

		humanoid.HealthChanged:Connect(function(newHealth)
			if (newHealth < currentHealth) then
				warn('[Player] Took damage!', tick());
			end;

			currentHealth = newHealth;
		end);

		myRootPart = character:WaitForChild('HumanoidRootPart', math.huge);
		characterHandler = character:WaitForChild('CharacterHandler', math.huge);
		inputClient = characterHandler:WaitForChild('InputClient', math.huge);

		if (not getKey) then
			repeat
				print('Waiting for get getkey func');
				getKey = getKeyFunction();
				task.wait(1);
			until getKey;
		end;

		if (debugMode) then
			getgenv().myRootPart = myRootPart;
		end;

		local oldGetKey = getKey;

		local getKey = not isSynapseV3 and getKey or function(name, pwd)
			local sprint = filtergc('function', {Name = 'Sprint'}, true);

			if (sprint and inputClient) then
				local suc, data = syn.trampoline_call(oldGetKey, {debug.getinfo(sprint)}, {
					identity = 2,
					thread = getscriptthread(inputClient),
					env = getfenv(sprint),
					script = inputClient
				}, name, pwd);

				return suc and data;
			end;
		end;

		local function safeGetKey(...)
			setscriptes(inputClient);
			syn.set_thread_identity(2);

			-- Call keyhandler

			local remote = getKey(...);
			local hasErrored = false;

			if (not remote or not IsDescendantOf(remote, game)) then
				repeat
					task.wait(0.1);
					if (typeof(getupvalue(getKey, 1)) ~= 'table') then
						if (not hasErrored) then
							hasErrored = true;
							logError('failed to get it', typeof(getupvalue(getKey, 1)));
						end;

						continue;
					end;

					remote = getKey(...);
				until remote and IsDescendantOf(remote, game);
			end;

			if (hasErrored) then
				logError('actually got it omg!');
			end;

			syn.set_thread_identity(7);
			setscriptes();

			print('We returned', remote:GetFullName());
			return remote;
		end;

		fallRemote = safeGetKey('FallDamage', 'plum');
		dialogueRemote = safeGetKey('SendDialogue', 'plum');
		blockRemote = safeGetKey('Block', 'plum');
		unblockRemote = safeGetKey('Unblock', 'plum');
		dodgeRemote = safeGetKey('Dodge', 'plum');
		leftClickRemote = safeGetKey('LeftClick', 'plum');
		rightClickRemote = safeGetKey('RightClick', 'plum');
		stopDodgeRemote = safeGetKey('StopDodge', 'plum');
		dropToolRemote = safeGetKey('DropTool', 'plum');
		serverSwimRemote = safeGetKey('ServerSwim','plum');

		getgenv().remotes = {
			fallRemote = fallRemote,
			dialogueRemote = dialogueRemote,
			leftClickRemote = leftClickRemote,
			blockRemote = blockRemote,
			dodgeRemote = dodgeRemote,
			rightClickRemote = rightClickRemote,
			stopDodgeRemote = stopDodgeRemote,
			unblockRemote = unblockRemote,
			dropToolRemote = dropToolRemote,
			serverSwimRemote = serverSwimRemote
		};

		if ((not blockRemote or not IsDescendantOf(blockRemote, game)) and not sent) then
			sent = true;
			task.spawn(function()
				logError('NO FALLR EMOTE?????')
				print(fallRemote);
			end);
		end;

		-- This is an old check and shouldn't fail because of safeGetKey
		if (isRemoteInvalid(fallRemote) or isRemoteInvalid(dialogueRemote) or isRemoteInvalid(blockRemote) or isRemoteInvalid(dodgeRemote) or isRemoteInvalid(leftClickRemote) or isRemoteInvalid(unblockRemote) or isRemoteInvalid(stopDodgeRemote) or isRemoteInvalid(rightClickRemote)) then
			print('failed to grab remotes!');
			error('oh no 0x01');
			task.delay(1, function()
				print('[Anti Cheat Bypass] Failed to grab remotes!');
			end);
		else
			print('[Anti Cheat Bypass] Got remotes!', dodgeRemote);
		end;
	end;

	if (LocalPlayer.Character) then
		task.spawn(onCharacterAdded, LocalPlayer.Character);
	end;

	LocalPlayer.CharacterAdded:Connect(onCharacterAdded);

	local gestureAnims = {};
	local gestures = ReplicatedStorage.Assets.Anims.Gestures;

	for _, v in next, gestures:GetChildren() do
		if not v:FindFirstChild('Pack1') and not v:FindFirstChild('MetalPromo') then continue; end;
		gestureAnims[v.Name] = v;
	end;

	local function onNamecall(self, ...)
		SX_VM_CNONE();

		if (checkcaller()) then return oldNamecall(self, ...) end;

		local method = getnamecallmethod();

		if (method == 'FireServer' and IsA(self, getServerConstant('RemoteEvent'))) then
			if (self.Name == getServerConstant('AcidCheck') and library.flags.antiAcid) then
				return;
			elseif (self == fallRemote and library.flags.noFallDamage and not checkcaller()) then
				return;
			elseif (self.Name == 'Gesture' and library.flags.giveAnimGamepass) then
				local args = {...};
				local animName = args[1];

				if (gestureAnims[animName]) then
					args[1] = 'Lean Back';

					task.spawn(function()
						local playerData = Utility:getPlayerData();
						local humanoid = playerData.humanoid;
						local animator = humanoid and humanoid:FindFirstChild('Animator');
						if (not animator) then return end;

						local onAnimationPlayed;
						local timeoutTask;
						local loadedAnim = animator:LoadAnimation(gestureAnims[animName]);

						onAnimationPlayed = animator.AnimationPlayed:Connect(function(animTrack)
							local animId = animTrack.Animation.AnimationId;
							if (animId ~= 'rbxassetid://6380990210') then return end;

							animTrack:Stop();
							loadedAnim:Play();

							humanoid:GetPropertyChangedSignal('MoveDirection'):Once(function()
								loadedAnim:Stop();
								onAnimationPlayed:Disconnect();
								task.cancel(timeoutTask);
							end);
						end);

						timeoutTask = task.delay(5, function()
							print('TIMED OUT!');
							onAnimationPlayed:Disconnect();
						end);
					end);

					return oldNamecall(self, unpack(args));
				end;
			end;
		elseif (method == 'Play' and IsA(self, getServerConstant('Tween')) and self.Instance == atmosphere and library.flags.noFog) then
			return;
		end;

		return oldNamecall(self, ...);
	end;

	local function onNewIndex(self, p, v)
		SX_VM_CNONE();

		if (self == characterHandler and p == 'Parent') then
			warn('[Anti Cheat Bypass] Got a ban attempt from charHandler.Parent = nil');
			return;
		elseif (self == Lighting and p == 'Ambient' and library.flags.fullBright) then
			local value = library.flags.fullBrightValue * 10;
			value += 100;

			v = Color3.fromRGB(value, value, value);
		elseif (self == atmosphere and p == 'Density' and library.flags.noFog) then
			v = 0;
		elseif (p == 'BackgroundColor3' and IsA(self, 'TextButton') and typeof(v) == 'Color3') then
			local s, l = debug.info(isSynapseV3 and 2 or 3, 'sl');
			if (l == 25 and s:find('ChoiceClient')) then
				return oldNewIndex(self,"AutoButtonColor", true);
			end;
		end;

		return oldNewIndex(self, p, v);
	end;

	local function onFireserver(self, ...)
		SX_VM_CNONE();

		if (leftClickRemote and self == leftClickRemote and library.flags.blockInput and not _G.canAttack) then
			return;
		end;

		if (blockRemote and self == blockRemote) then
			task.spawn(onParryRequest);
		end;

		return oldFireserver(self, ...);
	end;

	local function onDestroy(self)
		SX_VM_CNONE();

		if (characterHandler and self == characterHandler) then
			warn('[Anti Cheat Bypass] Got a ban attempt from characterhandler.destroy');
			return;
		end;

		return oldDestroy(self);
	end;

	warn('[Anti Cheat Bypass] Hooking game functions ...');

	oldNamecall = hookmetamethod(game, '__namecall', onNamecall);
	oldNewIndex = hookmetamethod(game, '__newindex', onNewIndex);

	oldFireserver = hookfunction(remoteEvent.FireServer, onFireserver);
	oldDestroy = hookfunction(game.Destroy, onDestroy);

	local stepped = game.RunService.Stepped;

	local function checkName(name)
		if (name and (name:find('InputClient') or name:find('ClientEffects') or name:find('EffectsClient') or name:find('WorldClient'))) then
			return true;
		end;
	end;

	local rayParams = RaycastParams.new();
	rayParams.FilterDescendantsInstances = {
		workspace.NPCs,
		workspace.Thrown,
		workspace.SnowSurfaces
	};

	local worldToViewportPoint = workspace.CurrentCamera.WorldToViewportPoint;
	local wiewportPointToRay = workspace.CurrentCamera.ViewportPointToRay;

	do -- // Silent Aim
		local function onCharacterAdded(character)
			if (not character) then return end;
			local getMouseFunction;

			repeat task.wait(); until character.Parent == workspace.Live or not character.Parent;
			if (not character.Parent) then return end;

			repeat
				debug.profilebegin('this is slow 2!');
				for _, v in next, getgc() do
					if (typeof(v) == 'function' and not is_synapse_function(v) and islclosure(v) and debug.info(v, 's'):find('InputClient')) then
						local constants = getconstants(v);

						if (table.find(constants, 'MouseTracker')) then
							getMouseFunction = v;
							break;
						end;
					end;
				end;
				debug.profileend();
				task.wait(1);
			until getMouseFunction;

			print('Got get mouse function!');

			getMouse.OnClientInvoke = function()
				setscriptes(inputClient);
				syn.set_thread_identity(2);

				local mouse, keys = getMouseFunction();

				if (library.flags.silentAim) then
					local target = Utility:getClosestCharacterWithEntityList(workspace.Live:GetChildren(), rayParams, {maxDistance = 500});
					target = target and target.Character;

					local cam = workspace.CurrentCamera;

					if (target and target.PrimaryPart) then
						local pos = worldToViewportPoint(cam, target.PrimaryPart.Position);

						mouse.Hit = target.PrimaryPart.CFrame;
						mouse.Target = target.PrimaryPart;
						mouse.X = pos.X;
						mouse.Y = pos.Y;
						mouse.UnitRay = wiewportPointToRay(cam, pos.X, pos.Y, 1)
						mouse.Hit = target.PrimaryPart.CFrame;
					end;
				end;

				return mouse, keys;
			end;

			getCameraToMouse.OnClientInvoke = function()
				if (library.flags.silentAim) then
					local target = Utility:getClosestCharacterWithEntityList(workspace.Live:GetChildren(), rayParams, {maxDistance = 500});
					target = target and target.Character;

					if (target and target.PrimaryPart) then
						return CFrame.new(workspace.CurrentCamera.CFrame.Position, target.PrimaryPart.Position);
					end;
				end;

				return CFrame.new(workspace.CurrentCamera.CFrame.Position, getMouseFunction().Hit.p);
			end;
		end;

		LocalPlayer.CharacterAdded:Connect(onCharacterAdded);
		task.spawn(onCharacterAdded, LocalPlayer.Character);
	end;

	do -- // Optimize backpack
		local function updateBackpackHook(character)
			if (not character) then return end;

			repeat task.wait(); until character.Parent == workspace.Live or not character.Parent;
			if (not character.Parent) then return end;

			local wasCalled;
			local renderFunction;
			local backpackClient;

			if (isSynapseV3) then return warn('warning: we do not hook renderbackpack on syn v3!'); end;

			repeat
				debug.profilebegin('this is slow!');
				for _, v in next, getgc() do
					if (typeof(v) == 'function' and debug.info(v, 'n') == 'render' and debug.info(v, 's'):find('BackpackClient')) then
						local scr = rawget(getfenv(v), 'script');

						if (typeof(scr) == 'Instance' and string.find(scr:GetFullName(), 'BackpackGui.BackpackClient')) then
							backpackClient = scr;
							print('we hooked', scr);
							local originalFunc = hookfunction(v, function() wasCalled = true; end);
							if (not renderFunction) then
								renderFunction = originalFunc;
							end;
						end;
					end;
				end;
				debug.profileend();
				task.wait(1);
			until renderFunction;

			maid.backpackHookTask = task.spawn(function()
				while task.wait(1 / 20) do
					if (not wasCalled) then continue end;
					wasCalled = false;
					setscriptes(backpackClient);
					syn.set_thread_identity(2);
					-- debug.profilebegin('renderFunction()');
					renderFunction();
					-- debug.profileend();
				end;
			end);
		end;

		LocalPlayer.CharacterAdded:Connect(updateBackpackHook);
		task.spawn(updateBackpackHook, LocalPlayer.Character);
	end;

	do -- // FPS Boost
		local fpsBoostMaid = Maid.new();
		local hooked = {};

		function functions.fpsBoost(t)
			table.clear(hooked);
		end;

		task.spawn(function()
			if (isSynapseV3) then return warn('warning: we do not run fps boost on syn v3!'); end;
			while task.wait(1) do
				for _, v in next, getconnections(RunService.RenderStepped) do
					if (not v.Function) then continue end;
					local conScript = getinstancefromstate(v.State);
					if (not conScript or not checkName(conScript.Name)) then continue end;
					if (hooked[v.Function]) then continue end;
					fpsBoostMaid[conScript] = nil;

					local f = v.Function;

					hooked[f] = true;

					if (not library.flags.fpsBoost) then
						v:Enable();
					else
						v:Disable();
						fpsBoostMaid[conScript] = stepped:Connect(function(_, dt)
							if (not v.Function) then
								fpsBoostMaid[conScript] = nil;
								hooked[f] = nil;
								v:Enable();
								return print('no more func!');
							end;

							setscriptes(conScript);
							syn.set_thread_identity(2);
							pcall(v.Function, dt);
						end);
					end;
				end;
			end;
		end);
	end;

	warn('[Anti Cheat Bypass] game functions hooked and destroyed maid');
end;

local myChatLogs = {};

local chatLogger = TextLogger.new({
	title = 'Chat Logger',
	preset = 'chatLogger',
	buttons = {'Spectate', 'Copy Username', 'Copy User Id', 'Copy Text', 'Report User'}
});

local autoParryHelperLogger = TextLogger.new({
	title = 'Auto Parry Helper Logger',
	buttons = {'Copy Animation Id', 'Add To Ignore List', 'Delete Log', 'Clear All'}
});

local assetsList = {'ModeratorJoin.mp3', 'ModeratorLeft.mp3'};
local audios = {};

local apiEndpoint = USE_INSECURE_ENDPOINT and 'http://test.aztupscripts.xyz/' or 'https://aztupscripts.xyz/';

for i, v in next, assetsList do
	audios[v] = AudioPlayer.new({
		url = string.format('%s%s', apiEndpoint, v),
		volume = 10,
		forcedAudio = true
	});
end;

local function loadSound(soundName)
	if ((soundName == 'ModeratorJoin.mp3' or soundName == 'ModeratorLeft.mp3') and not library.flags.modNotifier) then
		return;
	end;

	audios[soundName]:Play();
end;

_G.loadSound = loadSound;

local setCameraSubject;
local isInDanger;

local moderators = {};

do -- // Mod Logs and chat logger
	-- Y am I hardcoding this?

	local apiEndpoint = USE_INSECURE_ENDPOINT and 'http://test.aztupscripts.xyz/api/v1/' or 'https://aztupscripts.xyz/api/v1/';

	local moderatorIdsRequest = syn.request({
		Url = string.format('%smoderatorDetection', apiEndpoint),
		Headers = {['X-API-Key'] = websiteKey}
	});

	local moderatorIds = moderatorIdsRequest.Body;

	local suc, err = pcall(function()
		moderatorIds = syn.crypto.custom.decrypt(
			'aes-cbc',
			syn.crypt.base64.encode(moderatorIds),
			cipherKey,
			cipherIV
		);

		moderatorIds = string.match(moderatorIds, '%[(.-)%]');
		moderatorIds = string.split(moderatorIds, ',');
	end);

	if (not suc) then
		if (debugMode) then
			task.spawn(error, err);
		end;

		if (not moderatorIds) then
			ToastNotif.new({text = 'Script has failed to setup moderator detection. Error Code 1'});
		else
			ToastNotif.new({text = 'Script has failed to setup moderator detection. Error Code 2.' .. (moderatorIds.StatusCode or -1)});
		end;

		moderatorIds = {};
	end;

	local function isInGroup(player, groupId)
		local suc, err = pcall(player.IsInGroup, player, groupId);

		if(not suc) then return false end;
		return err;
	end;

	local function onPlayerChatted(player, message)
		local timeText = DateTime.now():FormatLocalTime('H:mm:ss', 'en-us');
		local playerName = player.Name;
		local playerIngName = player:GetAttribute('CharacterName') or 'N/A';

		message = ('[%s] [%s] [%s] %s'):format(timeText, playerName, playerIngName, message);

		local textData = chatLogger:AddText({
			text = message,
			player = player
		});

		if (player == LocalPlayer) then
			table.insert(myChatLogs, textData);
			functions.streamerMode(library.flags.streamerMode);
		end;
	end;

	local function onPlayerAdded(player)
		if (player == LocalPlayer) then return end;

		local userId = player.UserId;

		if library.flags.modNotifier and (table.find(moderatorIds, tostring(userId)) or isInGroup(player, 5212858)) then
			moderators[player] = true;

			loadSound('ModeratorJoin.mp3');
			ToastNotif.new({
				text = ('Moderator Detected [%s]'):format(player.Name),
			});
		end;
	end;

	local function onPlayerRemoving(player)
		if (player == LocalPlayer) then return end;

		if (moderators[player]) then
			ToastNotif.new({
				text = ('Moderator Left [%s]'):format(player.Name),
			});

			loadSound('ModeratorLeft.mp3');
			moderators[player] = nil;
		end;
	end;

	library.OnLoad:Connect(function()
		local chatLoggerSize = library.configVars.chatLoggerSize;
		chatLoggerSize = chatLoggerSize and Vector2.new(unpack(chatLoggerSize:split(',')));

		local chatLoggerPosition = library.configVars.chatLoggerPosition;
		chatLoggerPosition = chatLoggerPosition and Vector2.new(unpack(chatLoggerPosition:split(',')));

		if (chatLoggerSize) then
			chatLogger:SetSize(UDim2.fromOffset(chatLoggerSize.X, chatLoggerSize.Y));
		end;

		if (chatLoggerPosition) then
			chatLogger:SetPosition(UDim2.fromOffset(chatLoggerPosition.X, chatLoggerPosition.Y));
		end;

		chatLogger:UpdateCanvas();
	end);

	library.OnLoad:Connect(function()
		Utility.listenToChildAdded(Players, onPlayerAdded);
		Utility.listenToChildRemoving(Players, onPlayerRemoving);
	end);

	chatLogger.OnPlayerChatted:Connect(onPlayerChatted);
end;

local function formatMobName(mobName)
	if (not mobName:match('%.(.-)%d+')) then return mobName end;
	local allMobLetters = mobName:match('%.(.-)%d+'):gsub('_', ' '):split(' ');

	for i, v in next, allMobLetters do
		local partialLetters = v:split('');
		partialLetters[1] = partialLetters[1]:upper();

		allMobLetters[i] = table.concat(partialLetters);
	end;

	return table.concat(allMobLetters, ' ');
end;

-- // Entity esp overwrite
do
	local playersStats = {};
	local seenPerm = {};

	local function getPlayerLevel(character)
		if (not character) then return 0; end;
		local attributes = character:GetAttributes();
		local count = 0;

		for i,v in next, attributes do
			if (not string.match(i, 'Stat_')) then continue; end;
			count += v;
		end;

		return math.clamp(math.floor(count / 315 * 20), 1, 20);
	end;

	local function onBackpackAdded(player, backpack)
		task.wait();

		local seen = {};
		local seenJSON = {};
		local seenObj = {};

		local function onChildAdded(obj)
			local name = obj.Name;

			if (not seenObj[obj]) then
				seenObj[obj] = true;

				if (not seenPerm[player] and name:lower():find('grasp of eylis') and library.flags.voidWalkerNotifier) then
					seenPerm[player] = true;
					local t = ToastNotif.new({text = string.format('%s is a void walker.', player.Name)});
					local con;
					con = player:GetPropertyChangedSignal('Parent'):Connect(function()
						if (player.Parent) then return end;
						seenPerm[player] = nil;
						ToastNotif.new({text = string.format('[Void Walker Notif] %s left the game.', player.Name), duration = 10});
						t:Destroy();
						con:Disconnect();
					end);
				end;
			end;

			local weaponData = obj:FindFirstChild('WeaponData');
			local rarity = obj:FindFirstChild('Rarity');
			local foundWeaponData = weaponData;

			if (library.flags.mythicItemNotifier and weaponData and not seenJSON[weaponData] and rarity.Value == 'Mythic' and rarity) then
				xpcall(function()
					weaponData = seenJSON[weaponData] or HttpService:JSONDecode(weaponData.Value);
				end, function()
					weaponData = syn.crypt.base64.decode(weaponData.Value);
					weaponData = weaponData:sub(1, #weaponData - 2);

					weaponData = HttpService:JSONDecode(weaponData);
				end);

				if (foundWeaponData and not weaponData and debugMode) then
					task.spawn(error, 'Invalid Weapon Data');
				end;

				if (weaponData) then
					seenJSON[weaponData] = true;
				end;

				if (typeof(weaponData) == 'table' and not weaponData.Enchant and not (weaponData.SoulBound or weaponData.Soulbound) and not seen[obj]) then
					seen[obj] = true;

					ToastNotif.new({
						text = ('%s has %s'):format(player.Name, obj.Name:match('(.-)%$')),
					});
				end;
			end;

			playersStats[player] = {
				level = getPlayerLevel(player.Character)
			};

			return function()
				playersStats[player] = {
					level = getPlayerLevel(player.Character)
				};
			end;
		end;

		Utility.listenToChildAdded(backpack, onChildAdded, {listenToDestroying = true});
	end;

	local function onPlayerAdded(player)
		if (player == LocalPlayer) then return end;
		player.ChildAdded:Connect(function(obj)
			if (not IsA(obj, 'Backpack')) then return end;

			onBackpackAdded(player, obj);
		end);

		local backpack = player:FindFirstChildWhichIsA('Backpack');

		if (backpack) then
			task.spawn(onBackpackAdded, player, backpack);
		end;
	end;

	local function onPlayerRemoving(player)
		playersStats[player] = nil;
	end;

	library.OnLoad:Connect(function()
		Players.PlayerRemoving:Connect(onPlayerRemoving);
		Utility.listenToChildAdded(Players, onPlayerAdded);
	end);

	function EntityESP:Plugin()
		SX_VM_CNONE();

		local playerStats = playersStats[self._player] or {level = 1};
		local shouldSpoofName = library.flags.streamerMode and library.flags.hideEspNames;

		if (shouldSpoofName and not self._fakeName) then
			self._fakeName = string.format('%s %s', BrickColor.random().Name, self._id);
		end;

		local dangerText = '';

		if (library.flags.showDangerTimer) then
			local humanoid = Utility:getPlayerData(self._player).humanoid;
			local expirationTime = humanoid and humanoid:GetAttribute('DangerExpiration')

			if (expirationTime and expirationTime ~= -1) then
				dangerText = string.format(' [%ds]', expirationTime - workspace:GetServerTimeNow());
			end;
		end;

		return {
			text = string.format('\n[Level: %d]%s', playerStats.level, dangerText),
			playerName = shouldSpoofName and self._fakeName or self._playerName,
		}
	end;
end;

local markerWorkspace = ReplicatedStorage:WaitForChild('MarkerWorkspace');
local isLayer2 = ReplicatedStorage:FindFirstChild('LAYER2_DUNGEON');

do -- // Functions
	function functions.speedHack(toggle)
		if (not toggle) then
			maid.speedHack = nil;
			maid.speedHackBv = nil;

			return;
		end;

		maid.speedHack = RunService.Heartbeat:Connect(function()
			local playerData = Utility:getPlayerData();
			local humanoid, rootPart = playerData.humanoid, playerData.primaryPart;
			if (not humanoid or not rootPart) then return end;

			if (library.flags.fly) then
				maid.speedHackBv = nil;
				return;
			end;

			maid.speedHackBv = maid.speedHackBv or Instance.new('BodyVelocity');
			maid.speedHackBv.MaxForce = Vector3.new(100000, 0, 100000);

			if (not CollectionService:HasTag(maid.speedHackBv, 'AllowedBM')) then
				CollectionService:AddTag(maid.speedHackBv, 'AllowedBM');
			end;

			maid.speedHackBv.Parent = not library.flags.fly and rootPart or nil;
			maid.speedHackBv.Velocity = (humanoid.MoveDirection.Magnitude ~= 0 and humanoid.MoveDirection or gethiddenproperty(humanoid, 'WalkDirection')) * library.flags.speedHackValue;
		end);
	end;

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
			local rootPart, camera = playerData.rootPart, workspace.CurrentCamera;
			if (not rootPart or not camera) then return end;

			if (not CollectionService:HasTag(maid.flyBv, 'AllowedBM')) then
				CollectionService:AddTag(maid.flyBv, 'AllowedBM');
			end;

			maid.flyBv.Parent = rootPart;
			maid.flyBv.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * library.flags.flyHackValue);
		end);
	end;

	local depthOfField = Lighting:WaitForChild('DepthOfField', math.huge);
	local effectReplicator = require(ReplicatedStorage:WaitForChild('EffectReplicator', math.huge));

	local playerBlindFold;
	local lastBlurValue = 0;

	function functions.noFog(toggle)
		if (not toggle) then
			maid.noFog = nil;
			depthOfField.Enabled = true;

			return;
		end;

		depthOfField.Enabled = false;

		maid.noFog = RunService.RenderStepped:Connect(function()
			Lighting.FogEnd = 1000000;

			local atmosphere = Lighting:FindFirstChild('Atmosphere');
			if (not atmosphere) then return end;

			atmosphere.Density = 0;
		end);
	end;

	function functions.noBlind(toggle)
		if (not toggle) then
			maid.noBlind = nil;

			if (playerBlindFold) then
				playerBlindFold.Parent = LocalPlayer.Backpack;
				playerBlindFold = nil;
			end;

			return;
		end;

		maid.noBlind = RunService.Heartbeat:Connect(function()
			local backpack = LocalPlayer:FindFirstChild('Backpack');
			if (not backpack) then return end;

			local blindFold = backpack:FindFirstChild('Talent:Blinded') or backpack:FindFirstChild('Flaw:Blind');
			if (not blindFold) then return end;

			blindFold.Parent = nil;
			playerBlindFold = blindFold;
		end);
	end;

	function functions.noBlur(toggle)
		if (not toggle) then
			maid.noBlur = nil;
			Lighting.GenericBlur.Size = lastBlurValue;
			lastBlurValue = 0;

			return;
		end;

		lastBlurValue = Lighting.GenericBlur.Size;

		maid.noBlur = RunService.Heartbeat:Connect(function()
			Lighting.GenericBlur.Size = 0;
		end);
	end;

	-- NoClip
	do
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
				debug.profilebegin('noclip');

				local myCharacterParts = Utility:getPlayerData().parts;
				local isKnocked = effectReplicator:FindEffect('Knocked');
				local disableNoClipWhenKnocked = library.flags.disableNoClipWhenKnocked;

				for _, v in next, myCharacterParts do
					if (disableNoClipWhenKnocked) then
						v.CanCollide = not not isKnocked;
					else
						v.CanCollide = false;
					end;
				end;
				debug.profileend();
			end);
		end;
	end;

	function functions.clickDestroy(toggle)
		if (not toggle) then
			maid.clickDestroy = nil;
			return;
		end;

		maid.clickDestroy = UserInputService.InputBegan:Connect(function(input, gpe)
			if (input.UserInputType ~= Enum.UserInputType.MouseButton1 or gpe) then return end;

			local target = playerMouse.Target;
			if (not target or target:IsA('Terrain')) then return end;

			target:Destroy();
		end)
	end;

	function functions.serverHop(bypass)
		if(bypass or library:ShowConfirm('Are you sure you want to switch server?')) then
			library:UpdateConfig();
			local dataSlot = LocalPlayer:GetAttribute('DataSlot');
			MemStorageService:SetItem('DataSlot', dataSlot);

			BlockUtils:BlockRandomUser();
			TeleportService:Teleport(4111023553);
		end;
	end;

	local function tweenTeleport(rootPart, position, noWait)
		local distance = (rootPart.Position - position).Magnitude;
		local tween = TweenService:Create(rootPart, TweenInfo.new(distance / 120, Enum.EasingStyle.Linear), {
			CFrame = CFrame.new(position)
		});

		tween:Play();

		if (not noWait) then
			tween.Completed:Wait();
		end;

		return tween;
	end;

	do -- // Bots

		local function findFortMeritNPC(rootPart)
			for _, v in next, workspace.Live:GetChildren() do
				local mobRoot = v:FindFirstChild('HumanoidRootPart');
				if (not CollectionService:HasTag(v, 'Mob') or not mobRoot or formatMobName(v.Name) ~= 'Hostage Etrean' or (mobRoot.Position - rootPart.Position).Magnitude > 500) then continue end;

				return v;
			end;
		end

		function functions.fortMeritFarm(toggle)
			if (not toggle) then
				maid.fortMeritBv = nil;
				return
			end;

			-- // Check if player is near fort merit boat
			local fortMeritBoatLocation = Vector3.new(-9725.6982421875, 3.9712052345276, 2617.1892089844);
			local fortMeritPrisonLocation = Vector3.new(-9318.13671875, 423.30514526367, 2772.7346191406);
			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');

			if (not rootPart) then return warn('[Fort Merit Bot] HumanoidRootPart not found') end;

			while true do
				if (not library.flags.fortMeritFarm) then return end;
				if (rootPart.Position - fortMeritBoatLocation).Magnitude > 200 then
					ToastNotif.new({
						text = 'You are too far away from fort merit boat.',
						duration = 5
					});
				else
					break;
				end;

				task.wait(1);
			end;

			local bodyVelocity = Instance.new('BodyVelocity');
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
			bodyVelocity.Velocity = Vector3.new();

			maid.fortMeritBv = bodyVelocity;

			CollectionService:AddTag(bodyVelocity, 'AllowedBM');
			bodyVelocity.Parent = LocalPlayer.Character:FindFirstChild('Head');

			while (library.flags.fortMeritFarm) do
				tweenTeleport(rootPart, fortMeritPrisonLocation);

				local fortMeritNPC;
				local startedAt = tick();

				repeat
					fortMeritNPC = findFortMeritNPC(rootPart);
					task.wait(0.5);
				until fortMeritNPC or tick() - startedAt > 30 or not library.flags.fortMeritFarm;

				if (not fortMeritNPC) then
					task.wait(5);
					continue;
				end;

				local mobRoot = fortMeritNPC:FindFirstChild('HumanoidRootPart');

				tweenTeleport(rootPart, mobRoot.Position);
				task.wait(0.5);
				LocalPlayer.Character.CharacterHandler.Requests.Carry:FireServer();

				startedAt = tick();

				repeat
					task.wait();
				until effectReplicator:FindEffect('Carrying') or tick() - startedAt > 2.5;

				task.wait(0.5);
				tweenTeleport(rootPart, fortMeritPrisonLocation);
				task.wait(0.5);
				tweenTeleport(rootPart, fortMeritBoatLocation);
				task.wait(0.5);

				fireproximityprompt(workspace.NPCs['Etrean Guardmaster'].InteractPrompt);
				task.wait(1);

				dialogueRemote:FireServer({exit = true});
				task.wait(1);

				for _, v in next, workspace.Thrown:GetChildren() do
					if (not CollectionService:HasTag(v, 'ClosedChest')) then continue end;
					local chestRoot = v.PrimaryPart;

					if (chestRoot and (chestRoot.Position - rootPart.Position).Magnitude < 25) then
						local interact = v:FindFirstChild('InteractPrompt');
						if (interact) then
							fireproximityprompt(interact);
							task.wait(5);
						end;
					end;
				end;
			end;
		end;

		local ORE_FARM_MAX_RANGE = 500;
		local PLAYER_DIST_CHECK_MAX_RANGE = 200;
		local MOB_DIST_CHECK_MAX_RANGE = 100;

		local wantedOres = {'Astruline', 'Umbrite'};
		local forceKick = false;

		function functions.oresFarm(toggle)
			if (not toggle) then return end;
			MemStorageService:SetItem('oresFarm', 'true');

			if (not library.configVars.oresFarmPosition) then
				ToastNotif.new({text = 'Please set your position first!'});
				library.options.oresFarm:SetState(false);
				return;
			end;

			local notif = Webhook.new(library.flags.oresFarmWebhookNotifier);

			while (library.flags.oresFarm) do
				task.wait();

				local originalPosition = Vector3.new(unpack(library.configVars.oresFarmPosition:split(',')));

				if (not LocalPlayer.Character) then
					print('Attempt to spawn in');
					firesignal(UserInputService.InputBegan, {UserInputType = Enum.UserInputType.Keyboard, KeyCode = Enum.KeyCode.Unknown});
					task.wait(1);
					continue;
				end;

				local rootPart = LocalPlayer.Character:WaitForChild('HumanoidRootPart', 2);
				local humanoid = LocalPlayer.Character:WaitForChild('Humanoid', 2);
				local backpack = LocalPlayer:WaitForChild('Backpack', 2);

				if (not rootPart or not humanoid or not backpack) then
					-- Abort the bot
					warn('no root part / humanoid / backpack');
					continue;
				end;

				-- Wait for game to spawn in character
				repeat task.wait(); until CollectionService:HasTag(backpack, 'Loaded');

				if ((rootPart.Position - originalPosition).Magnitude > 500) then
					forceKick = true;
					LocalPlayer:Kick();
					GuiService:ClearError();
					ToastNotif.new({text = '[Ores Farm] You were too far from your last pos please click on the set location btn to reset your position and then rejoin the server.'});
					return;
				end;

				print('player spawned in!');

				local function isEntityNearby()
					if (Utility:countTable(moderators) > 0) then return true end;
					for _, entity in next, workspace.Live:GetChildren() do
						local root = entity:FindFirstChild('HumanoidRootPart');
						local isMob = CollectionService:HasTag(entity, 'Mob');
						if (not root or root == rootPart) then continue end;
						if ((root.Position - rootPart.Position).Magnitude <= (isMob and MOB_DIST_CHECK_MAX_RANGE or PLAYER_DIST_CHECK_MAX_RANGE)) then
							ToastNotif.new({text = string.format('too close %s %s', entity.Name, (root.Position - rootPart.Position).Magnitude)});
							return true;
						end;
					end;

					return false;
				end;

				task.spawn(function()
					while true do
						if (isEntityNearby()) then
							print('someone is nearby!!!');
							repeat task.wait(); until not effectReplicator:FindEffect('Danger');
							LocalPlayer:Kick('');
							functions.serverHop(true);

							return;
						elseif (not NetworkClient:FindFirstChild('ClientReplicator') and not forceKick) then
							functions.serverHop(true);
						end;

						task.wait();
					end;
				end);

				-- run player checks ere

				if ((rootPart.Position - originalPosition).Magnitude > 10) then
					tweenTeleport(rootPart, originalPosition);
					task.wait(5);
				end;

				local ores = {};
				local myPosition = rootPart.Position;

				local function onIngredientAdded(obj)
					if (table.find(wantedOres, obj.Name) and (obj.Position - myPosition).Magnitude <= ORE_FARM_MAX_RANGE) then
						table.insert(ores, obj);
					end;
				end;

				Utility.listenToChildAdded(workspace.Ingredients, onIngredientAdded);
				local maxCarryLoad = false;

				for _, ore in next, ores do
					if((humanoid:GetAttribute('CarryMax') or 100) * 1.2 <= humanoid:GetAttribute('CarryLoad')) then maxCarryLoad = true; break end;
					if (not library.flags.oresFarm) then break; end;
					tweenTeleport(rootPart, ore.Position);
					local prompt = ore:WaitForChild('InteractPrompt', 5);
					if (not prompt) then continue end;
					task.wait(0.2);

					local miningStartedAt = tick();
					fireproximityprompt(prompt);
					repeat task.wait(); until not ore.Parent or tick() - miningStartedAt > 10;
				end;

				if (maxCarryLoad) then
					ToastNotif.new({text = 'Max carry load!'});
					notif:Send(string.format('@everyone | %s | You are on max carry load', LocalPlayer.Name));
					task.wait(5);
				end;

				tweenTeleport(rootPart, originalPosition);
				task.wait(1);

				local astruline = LocalPlayer.Backpack:FindFirstChild('Astruline');

				if (astruline) then
					dropToolRemote:FireServer(astruline, true);
				end;

				task.wait(1);

				repeat task.wait(); until not effectReplicator:FindEffect('Danger');
				LocalPlayer:Kick('');
				functions.serverHop(true);

				break;
			end;
		end;

		function functions.setOresFarmPosition()
			local rootPart = Utility:getPlayerData().rootPart;
			if (not rootPart) then return end;

			library.configVars.oresFarmPosition = tostring(rootPart.Position);
			ToastNotif.new({text = 'Location set!'});
		end;

		local function isCharacterLoaded()
			local backpack = LocalPlayer:FindFirstChild('Backpack');
			if (not backpack) then return false end;

			return CollectionService:HasTag(backpack, 'Loaded');
		end;

		do -- Temp Farms
			do -- Echoes Farm
				local Requests = ReplicatedStorage:WaitForChild("Requests");
				local modifiers = require(ReplicatedStorage.Info.MetaData).Modifiers;
				local weaponData = require(ReplicatedStorage.Info.WeaponData).weapon_classes;

				local craft = Requests.Craft;
				local finishCreation = Requests.CharacterCreator.FinishCreation;
				local pickSpawn = Requests.CharacterCreator.PickSpawn;
				local modifyRemote = Requests.MetaModifier;
				local updateMeta = Requests.UpdateMeta;
				local increaseAttribute = Requests.IncreaseAttribute;

				local inDepths = game.PlaceId == 5735553160;

				local function startEchoFarm()
					if (not MemStorageService:HasItem('serverHop')) then
						pickSpawn:InvokeServer("Etris");

						for i in next, modifiers do --Enables all modifiers
							local waiting = true;

							local con;
							con = updateMeta.OnClientEvent:Connect(function(tab)
								if not string.find(tab.Modifiers,i) then return; end
								print('go');
								waiting = false;
							end)

							modifyRemote:FireServer(i);

							repeat
								task.wait(0.1);
								if not waiting then break; end;
								modifyRemote:FireServer(i);
							until not waiting;
							con:Disconnect();
						end

						finishCreation:InvokeServer();
					else
						MemStorageService:RemoveItem('serverHop');
					end;

					repeat task.wait(); until LocalPlayer.Character and (LocalPlayer.Character.Parent == workspace.Live);

					local rootPart = LocalPlayer.Character:WaitForChild('HumanoidRootPart', 10);
					local backpack = LocalPlayer:WaitForChild('Backpack', 10);

					repeat task.wait(); until CollectionService:HasTag(backpack, 'Loaded'); --Wait for us to spawn in

					--Make sure that a browncap and dentifilo is near and Y: 401 is below it

					--Toggle Noclip
					library.options.noClip:SetState(true);
					--Toggly Fly
					library.options.fly:SetState(true);

					local function pickupIngredients()
						local closests = {};
						local closestsParts = {};

						if (getgenv().breakPickup) then
							return false;
						end;

						for _, ingredient in next, workspace.Ingredients:GetChildren() do
							-- Make sure ingredient name is valid
							if (ingredient.Name == 'Dentifilo' or ingredient.Name == 'Browncap') then
								local interactPrompt = ingredient:FindFirstChild('InteractPrompt');
								if (not interactPrompt) then continue end;

								if (not closests[ingredient.Name]) then
									closests[ingredient.Name] = math.huge;
								end;

								local distance = (myRootPart.Position - ingredient.Position).Magnitude;

								if (distance < closests[ingredient.Name] and distance <= 250) then
									closests[ingredient.Name] = distance;
									closestsParts[ingredient.Name] = ingredient;
								end;
							end;
						end;

						-- Find closest ingredient and returns them

						if (not closestsParts.Dentifilo or not closestsParts.Browncap) then return false end;

						for _, ingredient in next, closestsParts do
							local ingPos = ingredient.Position;

							LocalPlayer.Character:PivotTo(CFrame.new(rootPart.Position.X,401.5,rootPart.Position.Z)); --Teleporting them below the Inn
							tweenTeleport(myRootPart, Vector3.new(ingPos.X, 401.5, ingPos.Z));

							-- Pickup the ingredient

							local startedAt = tick();
							local interactPrompt = ingredient:FindFirstChild('InteractPrompt');

							repeat
								if (not interactPrompt) then return false end;
								fireproximityprompt(interactPrompt);
								task.wait(1);
							until not ingredient.Parent or tick() - startedAt > 5;

							if (tick() - startedAt > 5) then
								-- We couldn't pick up the ingredient
								return false;
							end;
						end;

						return true;
					end;

					if (not pickupIngredients()) then
						-- If there is no mushroom then we wait to get new mushroom

						local startedAt = tick();

						repeat
							print('no browncap/dentifilo :(');
							task.wait(1);
						until pickupIngredients() or tick() - startedAt > 20;

						if (tick() - startedAt > 20) then
							MemStorageService:SetItem('serverHop', 'true');
							functions.serverHop(true);
							return;
						end;
					end;

					--Tween to the campfire
					tweenTeleport(myRootPart, Vector3.new(2509.039, 401.5, -5562.163));

					repeat
						task.wait(0.1);
					until craft:InvokeServer({Dentifilo = true, Browncap = true}); --Craft the Mushroom Soup

					originalFunctions.fireServer(fallRemote, math.random(900,1000),false);
					MemStorageService:SetItem('doWipe', 'true');
				end;

				local function fireChoices(choices, responseChoices)
					--There might be a debounce on these gotta test later
					for i, v in next, choices do -- Run Through Choices
						local completed = false;

						local con;
						con = dialogueRemote.OnClientEvent:Connect(function(tab)
							local text = tab.text;

							if (text ~= responseChoices[i] and not tab.exit) then
								-- Invalid data?
								return;
							end;

							completed = true;
						end);

						local waitTime = 0.25;

						repeat
							dialogueRemote:FireServer(v);
							task.wait(waitTime);
							waitTime += math.min(waitTime + 0.25, 1); -- Increase wait time for each failed attempts incase of a debounce or idk
						until completed;

						con:Disconnect();
					end;
				end;

				local function doWipe()
					local choices = {{["choice"] = "What do you mean?"}, {["choice"] = "But I don't want to go."}, {["choice"] = "Isn't there something we can do?"}, {["choice"] = "What is all this?"}, {["choice"] = "So, is this really the end?"}, {["exit"] = true}};
					local responseChoices = {
						'You know what I mean. You\'re me, after all. This is where we as a person end.',
						'[i]*Sigh.*[/i] There was so much left for us to do, wasn\'t there?',

						'[i]*You see your face racked with a pained expression.*[/i] No. You know there isn\'t.',
						'This... All of this around us... Is all our mind is able to make sense of right now. It\'s just holding on to all it can still remember.',
						'Yeah, I suppose it is. Come speak to me again when you want to... Well... You know.',
					};

					repeat task.wait(); until fallRemote and isCharacterLoaded(); --Wait for us to spawn in
					LocalPlayer.Character:PivotTo(myRootPart.CFrame * CFrame.new(0, -100, 0));

					--Remove ForceField
					local myChar = LocalPlayer.Character;

					library.options.noKillBricks:SetState(false);

					print('wiating');
					repeat
						local pos = LocalPlayer.Character:GetPivot().Position;
						LocalPlayer.Character:PivotTo(CFrame.new(pos.X, -2871, pos.Z));
						task.wait(0.5);
					until LocalPlayer.Character ~= myChar and LocalPlayer.Character ~= nil;
					print('ok');

					repeat task.wait(); until isCharacterLoaded(); --Wait for us to spawn in
					task.wait(2); -- 2 seem to be the fastest we can

					local dialogueUI = LocalPlayer.PlayerGui:WaitForChild('DialogueGui'):WaitForChild('DialogueFrame');

					local npcSelf = workspace:WaitForChild('NPCs'):WaitForChild('Self');
					local selfInteract = npcSelf.InteractPrompt;

					local npcSelfCF = npcSelf:GetPivot() * CFrame.new(0, -5, 0);
					local lastProximityPromptFire = 0;
					local stages = {};

					local function talkToSelf()
						repeat
							LocalPlayer.Character:PivotTo(npcSelfCF); --Teleport under Self
							if (tick() - lastProximityPromptFire > 0.5) then
								fireproximityprompt(selfInteract);
								lastProximityPromptFire = tick();
							end;
							task.wait();
						until dialogueUI.Visible;
					end;

					task.delay(60, function()
						if (not LocalPlayer.Character or not LocalPlayer.Character.Parent) then return end;
						debugWebhook:Send('Took more than 60 seconds ' .. table.concat(stages, ', '));

						while true do
							debugWebhook:Send(LocalPlayer.Character and LocalPlayer.Character.Parent and 'char found' or 'no char');
							task.wait(10);
						end;
					end);

					dialogueRemote.OnClientEvent:Connect(function(tab)
						if (not tab.text) then return; end;
						table.insert(stages,tab.text..'\n');
					end)

					-- Talk to self 1st part
					talkToSelf();
					fireChoices(choices, responseChoices);

					-- Talk to self 2nd part
					task.spawn(function()
						while true do
							talkToSelf();
							fireChoices({
								{choice = '[The End]'},
							}, {});
						end;
					end);

					while true do
						ReplicatedStorage.Requests.GetScore:FireServer();
						task.wait(0.1);
					end;
				end;

				function functions.echoFarm(t)
					if (not t) then return end;
					-- Don't enable echo farm in to1
					if (game.PlaceId == 8668476218) then return end;

					repeat
						ReplicatedStorage.Requests.StartMenu.Start:FireServer();
						task.wait(1);
					until LocalPlayer.Character;

					if (inDepths) then
						if (not MemStorageService:HasItem('doWipe')) then
							return ToastNotif.new({text = 'Echo farm is turned on but echo farm did not pass first stage so it wont wipe you.'});
						end;

						MemStorageService:RemoveItem('doWipe')
						doWipe();
					else
						if (not MemStorageService:HasItem('serverHop')) then
							local ran = false;
							task.delay(5, function()
								if (ran) then return end;
								ToastNotif.new({text = 'You must be in character creation menu to use the echo farm'});
							end);

							repeat task.wait(); until LocalPlayer.PlayerGui:FindFirstChild('CharacterCreator');
							ran = true;
						end;

						startEchoFarm();
					end;
				end;

				local animalKingFarmRan = false;

				function functions.animalKingFarm(t)
					if (not t) then return end;

					repeat
						ReplicatedStorage.Requests.StartMenu.Start:FireServer();
						task.wait(1);
					until LocalPlayer.Character;

					if (inDepths) then
						if (not MemStorageService:HasItem('doWipe')) then return end;
						MemStorageService:RemoveItem('doWipe')
						doWipe();
						return;
					end;

					if (animalKingFarmRan) then return; end;
					animalKingFarmRan = true;

					-- Toggle noclip
					library.options.noClip:SetState(true);
					--Toggly Fly
					library.options.fly:SetState(true);
					-- Disable echof arm
					library.options.echoFarm:SetState(false);

					-- Select minityrsa and spawn
					if (game.PlaceId ~= 8668476218) then
						repeat task.wait(); until LocalPlayer.PlayerGui:FindFirstChild('CharacterCreator');

						local ran = false;
						task.delay(5, function()
							if (ran) then return end;
							ToastNotif.new({text = 'You must be in character creation menu to use the animal king farm'});
						end);

						repeat task.wait(); until LocalPlayer.PlayerGui:FindFirstChild('CharacterCreator');
						ran = true;

						if (not pickSpawn:InvokeServer('Minityrsa')) then
							ToastNotif.new({text = 'You must have lone warrior origin to use the animal king farm'});
							return;
						end;

						finishCreation:InvokeServer();
						return;
					end;

					repeat task.wait(); until isCharacterLoaded();

					local startPosition = myRootPart.Position;
					local dialogueUI = LocalPlayer.PlayerGui:WaitForChild('DialogueGui'):WaitForChild('DialogueFrame');

					local oneModel = workspace:WaitForChild('One');
					local startTrialOfOne = oneModel.OneTrigger;
					local campfire = oneModel.Campfire.CampfirePart;

					-- Do first stage of trial of one (orbs)
					tweenTeleport(myRootPart, startTrialOfOne.Position);
					repeat task.wait() until dialogueUI.Visible;
					tweenTeleport(myRootPart, startPosition);

					-- Wait until campfire goes back down
					repeat task.wait(); until campfire.Position.Y <= 1178;

					-- Tp to campfire
					tweenTeleport(myRootPart, Vector3.new(campfire.Position.X, 1140, campfire.Position.Z));

					-- Spend points
					local weapon = LocalPlayer.Backpack:FindFirstChild('Weapon');
					local weaponType = weaponData[weapon:GetAttribute('DisplayName')] or weapon:GetAttribute('DisplayName');

					if (weaponType == 'Gun') then
						weaponType = 'WeaponLight'
					else
						weaponType = 'Weapon' .. weaponType:match('(.-)Weapon');
					end;

					local sharkoController;
					repeat
						task.wait(0.5);
						increaseAttribute:InvokeServer(weaponType, true, true);
						sharkoController = workspace.Live:FindFirstChild('MegalodauntController', true)
					until sharkoController;
					-- Spend attribute points until sharko spawns

					local sharko = sharkoController.Parent;
					local sharkoTarget = sharko:WaitForChild('Target');

					local startedAt = tick();

					-- Wait until sharko target is us or timeout reached
					repeat
						task.wait();
					until sharkoTarget.Value == LocalPlayer.Character or tick() - startedAt > 20;

					-- If timeout reached then we have animal king otherwsie we wipe
					if (tick() - startedAt > 20 or not sharkoTarget.Value) then
						print('OMG LE ANIMAL KING');
						logError(string.format('%s someone got animal king?', LocalPlayer.Name));
						Webhook.new(library.flags.animalKingWebhookNotifier):Send(string.format('@everyone | %s got animal king', LocalPlayer.Name));
						repeat task.wait(); until not isInDanger();
						LocalPlayer:Kick('Animal King!');
					else
						MemStorageService:SetItem('doWipe', 'true');
						originalFunctions.fireServer(fallRemote, math.random(900,1000),false);
					end;
				end;
			end;
		end;
	end;

	function functions.charismaFarm(toggle)
		if (not toggle) then
			maid.charismaFarm = nil;
			return;
		end;

		local lastFarmRanAt = 0;

		maid.charismaFarm = RunService.Heartbeat:Connect(function()
			if (tick() - lastFarmRanAt < 1) then return end;

			lastFarmRanAt = tick();

			local tool = LocalPlayer.Backpack:FindFirstChild('How to Make Friends') or LocalPlayer.Character:FindFirstChild('How to Make Friends');
			if (not tool) then
				return ToastNotif.new({
					text = 'You need to have How to Make Friends in your inventory for the farm to work',
					duration = 1
				});
			end;

			tool.Parent = LocalPlayer.Character;

			tool:Activate();

			local singlePrompt = LocalPlayer.PlayerGui:FindFirstChild('SimplePrompt');
			if (not singlePrompt) then return end;

			local chatText = singlePrompt.Prompt.Text:match('\'(.+)\'');
			if (not chatText) then return end;

			warn('should say', chatText);

			library.dummyBox:SetTextFromInput(chatText);
			Players:Chat(chatText);
		end);
	end;

	function functions.intelligenceFarm(toggle)
		if (not toggle) then
			maid.intelligenceFarm = nil;
			return;
		end;

		local lastFarmRanAt = 0;

		maid.intelligenceFarm = RunService.Heartbeat:Connect(function()
			if (tick() - lastFarmRanAt < 1) then return end;
			lastFarmRanAt = tick();

			local tool = LocalPlayer.Backpack:FindFirstChild('Math Textbook') or LocalPlayer.Character:FindFirstChild('Math Textbook');
			if (not tool) then
				return ToastNotif.new({
					text = 'You need to have Math Textbook in your inventory for the farm to work',
					duration = 1
				});
			end;

			tool.Parent = LocalPlayer.Character;

			tool:Activate();

			local choicePrompt = LocalPlayer.PlayerGui:FindFirstChild('ChoicePrompt');
			if (not choicePrompt) then return end;

			local question = choicePrompt.ChoiceFrame.DescSheet.Desc.Text:gsub('[^%w%p%s]', '');
			local operationType = question:match('%d+ (.-) ');

			local number1 = question:match('What is (.-) ');
			local number2 = question:match(operationType .. ' (.-)%?');

			number2 = number2:gsub('by', '');
			number1 = tonumber(number1);
			number2 = tonumber(number2);

			local result = 0;

			if (operationType == 'minus') then
				result = number1 - number2;
			elseif (operationType == 'divided') then
				result = number1 / number2;
			elseif (operationType == 'plus') then
				result = number1 + number2;
			elseif (operationType == 'times') then
				result = number1 * number2;
			end;

			for i, v in next, choicePrompt.ChoiceFrame.Options:GetChildren() do
				if (not v:IsA('TextButton')) then continue end;

				print(math.abs(tonumber(v.Name)-result));
				if (math.abs(tonumber(v.Name)-result)<=1) then
					choicePrompt.Choice:FireServer(v.Name);
					break;
				end;
			end;
		end);
	end;

	function functions.fishFarm(toggle)
		if (not toggle) then
			maid.fishFarmAutoClicker = nil;
			maid.fishFarmAutoPull = nil;
			return;
		end;

		if (not LocalPlayer.Character or not LocalPlayer:FindFirstChildWhichIsA('Backpack')) then
			return ToastNotif.new({
				text = 'Error trying to run fish farm, please try again.',
				duration = 1
			});
		end;

		local fishingRod = LocalPlayer.Backpack:FindFirstChild('Fishing Rod') or LocalPlayer.Character:FindFirstChild('Fishing Rod');
		local rootPart = LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
		local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');

		if (not fishingRod or not rootPart) then
			ToastNotif.new({
				text = 'You need a fishing rod to use the fish farm.',
				duration = 5,
			});
			return;
		end;

		fishingRod.Parent = LocalPlayer.Character;
		task.wait(1);

		local reelLongSong = fishingRod.Handle.FishingLoop;
		local fishingRodRemote = fishingRod.FishinScript.RemoteEvent;

		local lastPullDirection;

		local function pullFishingRod(direction)
			if (direction == lastPullDirection) then return warn('same direction, we dont change') end;
			print('pulling', direction);

			if (lastPullDirection) then
				fishingRodRemote:FireServer(lastPullDirection, false);
			end;

			fishingRodRemote:FireServer(direction, true);
			lastPullDirection = direction;
		end;

		local function attachBait()
			local fishFarmBaits = library.flags.fishFarmBait:split(',');
			local bait = fishingRod.Bait.Value;
			local canBait = fishingRod.CanBait.Value;

			for i, v in next, fishFarmBaits do
				for i2, v2 in next, LocalPlayer.Backpack:GetChildren() do
					if (v:lower() == v2.Name:lower() and CollectionService:HasTag(v2, 'Edible') and canBait and not bait) then
						fishingRod.AddBait:FireServer(v2);

						local lastAttachBaitAt = tick();

						repeat
							task.wait();
						until fishingRod.Bait.Value or tick() - lastAttachBaitAt > 5;

						task.wait(0.5);

						return;
					end;
				end;
			end;
		end;

		maid.fishFarmAutoPull = humanoid.AnimationPlayed:Connect(function(anim)
			local animationId = anim.Animation.AnimationId:match('%d+');

			if (animationId == '6415331110') then
				-- Pull left
				pullFishingRod('a');
			elseif (animationId == '6415331617') then
				-- Pull right
				pullFishingRod('d');
			elseif (animationId == '6415330705') then
				-- Pull back
				pullFishingRod('s');
			end;
		end);

		maid.fishFarmAutoClicker = reelLongSong:GetPropertyChangedSignal('Playing'):Connect(function()
			if (reelLongSong.Playing) then
				task.wait(0.2);

				while (reelLongSong.Playing) do
					fishingRod:Activate();
					task.wait(1 / 10);
					-- Clicking 10 time per second
				end;
			end;
		end);

		local fishingStartedAt = tick();

		task.spawn(function()
			while (library.flags.fishFarm) do
				local hook = fishingRod.Handle.Rod.bobby.hook;

				if ((rootPart.Position - hook.Position).Magnitude < 10) then
					-- If the hook is too close it mean the player is not fishing so we start fishing again.

					attachBait();


					fishingRod:Activate();
					task.wait(library.flags.fishFarmHoldTime);
					fishingRod:Deactivate();
					task.wait(1);
					fishingStartedAt = tick();
				elseif (tick() - fishingStartedAt >= 120) then
					-- If player is fishing for more than 120 second without any fish, we stop fishing and retry.
					fishingRod.Parent = LocalPlayer.Backpack;
					task.wait(1);
					fishingRod.Parent = LocalPlayer.Character;
				end;

				task.wait(0.1);
			end;
		end);
	end;

	function functions.autoLoot(toggle)
		if (not toggle) then
			maid.autoLoot = nil;
			return;
		end;

		local colors = {
			['875252'] = 'Rare',
			['a38e64'] = 'Uncommon',
			['40504c'] = 'Common',
			['9057ac'] = 'Epic',
			['e2ffe6'] = 'Enchant',
			['46ccaf'] = 'Legendary'
		};

		local icons = {
			[tostring(Vector2.new(0, 0))] = 'Ring',
			[tostring(Vector2.new(20, 0))] = 'Gloves',
			[tostring(Vector2.new(40, 0))] = 'Shoes',
			[tostring(Vector2.new(60, 0))] = 'Helmets',
			[tostring(Vector2.new(80, 0))] = 'Glasses',
			[tostring(Vector2.new(100, 0))] = 'Earrings',
			[tostring(Vector2.new(120, 0))] = 'Schematics',
			[tostring(Vector2.new(140, 0))] = 'Weapons',
			[tostring(Vector2.new(160, 0))] = 'Daggers',
			[tostring(Vector2.new(180, 0))] = 'Necklace',
			[tostring(Vector2.new(200, 0))] = 'Trinkets'
		};

		local weaponAttributes = {
			'HP',
			'ETH',
			'RES',
			'Posture',
			'SAN',
			'Monster Armor',
			'PHY Armor',
			'Monster DMG',
			'ELM Armor'
		}

		local starIcon = fromHex('E29885');
		local fired = {};

		local function firstToUpper(str) --Totally not somewhat ripped from devforum cuz lazy
			return str:gsub("^%l", string.upper)
		end

		local function checkItemAttributes(weaponType,itemAttributes) --This function could be more efficient if i didn't check the ones at 0 but whatevs
			local foundMatch = false;
			if library.flags['autoLootWhitelistMatchAll'..weaponType] then --All things have to match gte for it to return true
				local attributeAmount = #weaponAttributes;
				local timesMatched = 0;

				for _,statName in next, weaponAttributes do
					statName = firstToUpper(toCamelCase(statName));

					local weaponTypeValue = library.flags['autoLootWhitelist'..statName..weaponType];
					local itemValue = itemAttributes[statName] or 0;

					if weaponTypeValue and itemValue and itemValue >= weaponTypeValue then
						timesMatched = timesMatched+1;
					end

				end
				foundMatch = attributeAmount == timesMatched;
			else --Only one thing has to match to return true

				for statName, itemValue in next, itemAttributes do --This check is annoying because if its greater than 0 but probably nobody gonna want a 0 stat thing so...
					local weaponTypeValue = library.flags['autoLootWhitelist'..statName..weaponType]; --This is incredibly demonic at this point... autoLootWhitelistHPWeapon

					if weaponTypeValue and itemValue >= weaponTypeValue and weaponTypeValue ~= 0 then
						foundMatch = true;
						break;
					end
				end
			end

			return foundMatch;
		end

		local function canGrabItem(starAmount, weaponRarity, weaponType, itemAttributes, itemName)
			if (weaponRarity == 'Enchant' and library.flags.alwaysPickupEnchant) then
				return true;
			end;
			if (itemName == "Kyrsan Medallion" and library.flags.alwaysPickupMedallion) then
				return;
			end

			if (library.flags['autoLootFilter' .. weaponType]) then
				local priority = library.flags['autoLootWhitelistPriorities' .. weaponType];
				local starsFlag = library.flags['autoLootWhitelistStars' .. weaponType];

				if (priority == 'Stars' and starsFlag[starAmount .. ' Stars']) then
					return true;
				elseif priority == 'Stats' and library.flags['autoLootWhitelistUseAttributes' .. weaponType] and checkItemAttributes(weaponType,itemAttributes) then
					return true;
				end

				local hasOneStarSelected = Utility.find(starsFlag, function(v) return v == true end);

				if (not library.flags['autoLootWhitelistRarities' .. weaponType][weaponRarity]) then
					return false;
				end;

				if (not starsFlag[starAmount .. ' Stars'] and hasOneStarSelected) then
					return false;
				end;

				if (library.flags['autoLootWhitelistUseAttributes' .. weaponType] and not checkItemAttributes(weaponType,itemAttributes)) then
					return false;
				end

				return true;
			end;

			return true;
		end;

		_G.canGrabItem = canGrabItem;

		local lastRan = 0;

		maid.autoLoot = RunService.Heartbeat:Connect(function()
			local choicePrompt = LocalPlayer.PlayerGui:FindFirstChild('ChoicePrompt');

			-- Note to myself the description check could break if game add translation in the future.
			if (not choicePrompt or choicePrompt.ChoiceFrame.Title.Text ~= 'Treasure Chest') then return end;

			local remote = choicePrompt:FindFirstChild('Choice');
			if (not remote or tick() - lastRan <= 0.1) then return end;

			for _, v in next, choicePrompt.ChoiceFrame.Options:GetChildren() do
				if (not IsA(v, 'TextButton') or v.Name == 'Nothing') then continue end;

				local canClick = v.AutoButtonColor;
				if (not canClick) then print('NOOOON'); continue end;

				local weaponRarity = colors[v.BackgroundColor3:ToHex()];
				local weaponType = v.Title.Text:find('Ring') and 'Ring' or icons[tostring(v.Icon.ImageRectOffset)];

				local splitText = v.Text:split(starIcon);
				local starAmount = #splitText - 1;
				local itemName = splitText[1];
				local itemAttributes = {};

				if v.Stats.Visible then
					local itemStats = v.Stats.Text;
					local strippedString = string.match(itemStats,"^.*%>; (.*)") or string.match(itemStats,".*");

					string.gsub(strippedString,'[+-]?%d%%?[^;]*',function(x)
						itemAttributes[firstToUpper(toCamelCase(string.match(x,'%A+(.*)')))] = tonumber(string.match(x,'%d+'));
					end)
				end
				-- print(weaponType, weaponRarity);

				if (not canGrabItem(starAmount, weaponRarity, weaponType, itemAttributes, itemName)) then continue end;

				if (not fired[v]) then
					lastRan = tick();
					remote:FireServer(v.Name);
					fired[v] = true;
					task.delay(0.1, function()
						fired[v] = nil;
					end);
				end;

				return;
			end;

			if (not fired[remote] and library.flags.autoCloseChest) then
				fired[remote] = true;
				remote:FireServer('EXIT');

				task.delay(0.1, function()
					fired[remote] = nil;
				end);
			end;
		end);
	end;

	-- Auto Loot Analytics
	task.spawn(function()
		if (true) then return end;
		-- Disable auto loot analytics

		local sentColors = {
			['875252'] = 'Rare',
			['a38e64'] = 'Uncommon',
			['40504c'] = 'Common',
			['9057ac'] = 'Epic',
			['e2ffe6'] = 'Enchant',
			['46ccaf'] = 'Legendary'
		};

		local lastRanAt = 0;

		local icons = {
			[tostring(Vector2.new(0, 0))] = 'Ring',
			[tostring(Vector2.new(20, 0))] = 'Gloves',
			[tostring(Vector2.new(40, 0))] = 'Shoes',
			[tostring(Vector2.new(60, 0))] = 'Helmets',
			[tostring(Vector2.new(80, 0))] = 'Glasses',
			[tostring(Vector2.new(100, 0))] = 'Earrings',
			[tostring(Vector2.new(120, 0))] = 'Coats',
			[tostring(Vector2.new(140, 0))] = 'Weapons',
			[tostring(Vector2.new(160, 0))] = 'Daggers',
			[tostring(Vector2.new(180, 0))] = 'Necklace',
			[tostring(Vector2.new(200, 0))] = 'Trinkets'
		};

		local starIcon = fromHex('E29885');

		RunService.Heartbeat:Connect(function()
			if (tick() - lastRanAt < 0.2) then return end;
			lastRanAt = tick();

			local choicePrompt = LocalPlayer.PlayerGui:FindFirstChild('ChoicePrompt');

			-- Note to myself the description check could break if game add translation in the future.
			if (not choicePrompt or choicePrompt.ChoiceFrame.DescSheet.Desc.Text ~= 'What do you take?') then return end;

			local remote = choicePrompt:FindFirstChild('Choice');
			if (not remote) then return end;

			for _, v in next, choicePrompt.ChoiceFrame.Options:GetChildren() do
				if (not IsA(v, 'TextButton') or v.Name == 'Nothing') then continue end;

				local canClick = v.AutoButtonColor;
				local color = v.BackgroundColor3:ToHex();

				if (not canClick or sentColors[color]) then continue end;

				local icon = icons[tostring(v.Icon.ImageRectOffset)] or tostring(v.Icon.ImageRectOffset);
				sentColors[color] = true;

				local starAmount = #v.Text:split(starIcon) - 1;

				syn.request({
					Url = '',
					Method = 'POST',
					Body = HttpService:JSONEncode({
						content = string.format('v2 | Icon:%s | Color:%s | Name:%s | Stars:%s', icon, color, v.Name, starAmount)
					}),
					Headers = {['Content-Type'] = 'application/json'}
				});
			end;
		end);
	end);

	function functions.autoSprint(toggle)
		if (not toggle) then
			maid.autoSprint = nil;
			return;
		end;

		local moveKeys = {Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D};
		local lastRan = 0;

		maid.autoSprint = UserInputService.InputBegan:Connect(function(input, gpe)
			if (gpe or tick() - lastRan < 0.1) then return end;

			if (table.find(moveKeys, input.KeyCode)) then
				lastRan = tick();
				VirtualInputManager:SendKeyEvent(true, input.KeyCode, false, game);
			end;
		end);
	end;

	function functions.chatLogger(toggle)
		chatLogger:SetVisible(toggle);
	end;

	local autoParryHelperMaid = Maid.new();

	local animTimes = {};
	local allAnimations = {};
	local mobsAnims = {};
	local fetchingNames = {};

	autoParryHelperLogger.ignoreList = {'8174890073', '180435571', '4087826639', '5554732065', '180436148', '9323073748', '5168319343', '180435792'};

	function functions.autoParryHelper(toggle)
		autoParryHelperLogger:SetVisible(toggle);

		if (not toggle) then
			autoParryHelperMaid:Destroy();
			return;
		end;

		local function onNewEntityAdded(entity)
			if (entity == LocalPlayer.Character) then return end;

			local rootPart = entity:WaitForChild('HumanoidRootPart', 10);
			if (not rootPart) then return end;

			local humanoid = entity:WaitForChild('Humanoid', 10);
			if (not humanoid) then return end;

			local entityMaid = Maid.new();

			entityMaid:GiveTask(entity.Destroying:Connect(function()
				entityMaid:Destroy();
			end));

			entityMaid:GiveTask(humanoid.AnimationPlayed:Connect(function(animationTrack)
				local animationId = animationTrack.Animation.AnimationId:match('%d+');
				local maxLoggerRange = library.flags.helperMaxRange;

				if (table.find(autoParryHelperLogger.ignoreList, animationId) or (myRootPart.Position - rootPart.Position).Magnitude > maxLoggerRange) then
					return;
				end;

				local entityName = entity.Name;

				if (CollectionService:HasTag(entity, 'Mob')) then
					entityName = formatMobName(entityName);
				end;

				local animName = allAnimations[animationId];

				if (not animName and not fetchingNames[animationId]) then
					fetchingNames[animationId] = true;

					task.spawn(function()
						allAnimations[animationId] = '?_' .. game:GetService('MarketplaceService'):GetProductInfo(tonumber(animationId), Enum.InfoType.Asset).Name;
					end);
				end;

				autoParryHelperLogger:AddText({
					text = string.format('Animation <font color=\'#2ecc71\'>%s</font> (%s) played from <font color=\'#3498db\'>%s</font>', animationId, animName or 'no_name', entityName),
					animationId = animationId,
				});
			end));

			autoParryHelperMaid:GiveTask(function()
				entityMaid:Destroy();
			end);
		end;

		autoParryHelperMaid:GiveTask(workspace.Live.ChildAdded:Connect(onNewEntityAdded));

		for i, v in next, workspace.Live:GetChildren() do
			task.spawn(onNewEntityAdded, v);
		end;

		autoParryHelperMaid:GiveTask(autoParryHelperLogger.OnClick:Connect(function(actionName, context)
			if (actionName == 'Add To Ignore List' and not table.find(autoParryHelperLogger.ignoreList, context.animationId)) then
				table.insert(autoParryHelperLogger.ignoreList, context.animationId);
			elseif (actionName == 'Delete Log') then
				context:Destroy();
			elseif (actionName == 'Copy Animation Id') then
				setclipboard(context.animationId);
			elseif (actionName == 'Clear All') then
				for i, v in next, autoParryHelperLogger.allLogs do
					v.label:Destroy();
				end;

				table.clear(autoParryHelperLogger.allLogs);
			end;
		end));
	end;

	local function getWorldInfo()
		local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
		if (not playerGui) then return end;

		local worldInfo = playerGui:FindFirstChild('WorldInfo');
		if (not worldInfo) then return end;

		return worldInfo;
	end;

	local function getBackpackGui()
		local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
		if (not playerGui) then return end;

		local backpackGui = playerGui:FindFirstChild('BackpackGui');
		if (not backpackGui) then return end;

		return backpackGui;
	end;

	local function getChoicePrompt()
		local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
		if (not playerGui) then return end;

		local choicePrompt = playerGui:FindFirstChild('ChoicePrompt');
		if (not choicePrompt) then return end;

		return choicePrompt;
	end;

	local oldDisplayName;
	local oldSlotText;

	function functions.streamerMode(toggle)
		local streamerModeType = library.flags.streamerModeType;

		if (not toggle) then
			maid.streamerMode = nil;
			maid.streamerModeIdSpoofer = nil;

			LocalPlayer:SetAttribute('Hidden', false);

			for _, v in next, myChatLogs do
				v.label.Text = v.text;
				v.label.Visible = true;
			end;

			chatLogger:UpdateCanvas();

			local worldInfo = getWorldInfo();
			local backpackGui = getBackpackGui();

			if (backpackGui and oldDisplayName) then
				backpackGui.JournalFrame.CharacterName.Text = oldDisplayName;
				backpackGui.JournalFrame.CharacterName.Visible = true;
			end;

			if (worldInfo and oldSlotText) then
				worldInfo.InfoFrame.CharacterInfo.Visible = true;
				worldInfo.InfoFrame.CharacterInfo.Slot.Text = oldSlotText or worldInfo.InfoFrame.CharacterInfo.Slot.Text;

				worldInfo.InfoFrame.ServerInfo.Visible = true;
				worldInfo.InfoFrame.GameInfo.Visible = true;
				worldInfo.InfoFrame.AgeInfo.Visible = true;
				worldInfo.InfoFrame.WorldInfo.Visible = true;

				oldSlotText = nil;
			end;

			local character = LocalPlayer.Character;
			if (not character) then return end;

			local humanoid = character:FindFirstChildWhichIsA('Humanoid');
			if (not humanoid or not oldDisplayName) then return end;

			humanoid.DisplayName = oldDisplayName;
			oldDisplayName = nil;

			return;
		end;

		LocalPlayer:SetAttribute('Hidden', true);

		local players = {};

		for _, v in next, Players:getPlayers() do
			if (v ~= LocalPlayer and v:GetAttribute('CharacterName')) then
				table.insert(players, v);
			end;
		end;

		local chosenPlayer = library.configVars.streamerModeTarget or #players > 0 and players[math.random(1, #players)];
		if (not chosenPlayer) then
			return ToastNotif.new({
				text = 'For security reasons, you can\'t use streamer mode without any players in your server.',
				duration = 10
			});
		end;

		local chosenPlayerName = typeof(chosenPlayer) == 'table' and chosenPlayer.CharacterName or chosenPlayer:GetAttribute('CharacterName');
		local chosenPlayerId = chosenPlayer.UserId;
		local chosenPlayerAccountAge = math.random(1, 50);

		local chosenPlayerLevel = typeof(chosenPlayer) == 'table' and chosenPlayer.AccountLevelSmaller or math.random(1, 20);

		library.configVars.streamerModeTarget = {
			Name = chosenPlayer.Name,
			UserId = chosenPlayer.UserId,
			AccountAge = chosenPlayer.AccountAge,
			AccountLevelSmaller = chosenPlayerLevel,
			CharacterName = chosenPlayerName
		};

		for _, v in next, myChatLogs do
			if (streamerModeType == 'Hide') then
				v.label.Visible = false;
				continue;
			end;

			local timeText = v.text:match('(%[.-%])');
			local rawText = v.text:match('.-%] .-%] .-%] (.+)');

			v.label.Text = ('%s [%s] [%s] %s'):format(timeText, chosenPlayer.Name, chosenPlayerName, rawText);
			v.label.Visible = true;
		end;

		chatLogger:UpdateCanvas();

		maid.streamerModeIdSpoofer = LocalPlayer.DescendantAdded:Connect(function(obj)
			if (obj.Name == 'DeathID' or obj.Name == 'KillerCharacter' or obj.Name == 'KillerPlayer') then
				repeat
					obj.Text = '';
					task.wait();
				until not obj.Parent;
			end;
		end);

		maid.streamerMode = RunService.Heartbeat:Connect(function()
			debug.profilebegin('streamer mode');
			local ultraStreamerMode = library.flags.ultraStreamerMode;
			local hideAllServerInfo = library.flags.hideAllServerInfo;

			local myCharacter = LocalPlayer.Character;

			if (ultraStreamerMode) then
				for _, entity in next, workspace.Live:GetChildren() do
					if (entity == myCharacter) then continue end;
					local humanoid = entity:FindFirstChildWhichIsA('Humanoid');
					if (not humanoid) then continue end;

					humanoid.DisplayName = 'BUY AZTUP HUB';
				end;
			end;

			local worldInfo = getWorldInfo();
			local backpackGui = getBackpackGui();
			local choicePrompt = getChoicePrompt();

			streamerModeType = library.flags.streamerModeType;

			if (worldInfo) then
				if (not oldSlotText) then
					oldSlotText = worldInfo.InfoFrame.CharacterInfo.Slot.Text;
				end;

				worldInfo.InfoFrame.CharacterInfo.Visible = streamerModeType == 'Spoof';
				worldInfo.InfoFrame.CharacterInfo.Slot.Text = ('%d:A|%d [Lv.%d]'):format(chosenPlayerId, chosenPlayerAccountAge, chosenPlayerLevel);

				worldInfo.InfoFrame.ServerInfo.Visible = not hideAllServerInfo;
				worldInfo.InfoFrame.GameInfo.Visible = not hideAllServerInfo;
				worldInfo.InfoFrame.AgeInfo.Visible = not hideAllServerInfo;
				worldInfo.InfoFrame.WorldInfo.Visible = not hideAllServerInfo;
			end;

			if (backpackGui) then
				backpackGui.JournalFrame.CharacterName.Visible = streamerModeType == 'Spoof';
				backpackGui.JournalFrame.CharacterName.Text = chosenPlayerName;

				if (ultraStreamerMode) then
					backpackGui.JournalFrame.FactSheet.Container.Age.Value.Text = '???';
					backpackGui.JournalFrame.FactSheet.Container.Born.Value.Text = '???';
					backpackGui.JournalFrame.FactSheet.Container.Level.Value.Text = '???';
					backpackGui.JournalFrame.FactSheet.Container.Race.Value.Text = '???';
				end;
			end;

			if (choicePrompt and ultraStreamerMode and choicePrompt.ChoiceFrame.Title.Text ~= 'Treasure Chest') then
				choicePrompt.ChoiceFrame.Title.Text = '???';
			end;

			local character = LocalPlayer.Character;
			if (not character) then return end;

			local humanoid = character:FindFirstChildWhichIsA('Humanoid');
			if (not humanoid) then return end;

			if (not oldDisplayName) then
				oldDisplayName = humanoid.DisplayName;
			end;

			humanoid.DisplayName = chosenPlayerName;
			debug.profileend();
		end);
	end;

	function functions.rebuildStreamerMode()
		library.configVars.streamerModeTarget = nil;
		functions.streamerMode(library.flags.streamerMode);
	end;

	local function pingWait(n)
		if library.flags.useCustomDelay then
			n+=library.flags.customDelay/1000;
		else
			local playerPing = Stats.PerformanceStats.Ping:GetValue()/1000;
			n -= (playerPing*(library.flags.pingAdjustmentPercentage/100));
		end

		return task.wait(n);
	end;

	-- Get all animations for auto parry debug
	do
		local mobsAnimsFolder = ReplicatedStorage.Assets.Anims.Mobs;
		local seenAnims = {};
		local toRemove = {};

		for _, v in next, ReplicatedStorage.Assets.Anims:GetDescendants() do
			if (not IsA(v, 'Animation')) then continue end;
			local animationId = v.AnimationId:match('%d+');
			local isMobsFolder = v:IsDescendantOf(mobsAnimsFolder);

			allAnimations[animationId] = string.format('%s-%s', v.Parent.Name, v.Name);

			if (table.find(seenAnims, animationId)) then
				table.insert(toRemove, animationId);
			end;

			if (not isMobsFolder) then
				table.insert(seenAnims, animationId);
			else
				table.insert(mobsAnims, animationId);
			end;
		end;

		for _, animId in next, toRemove do
			if (not table.find(mobsAnims, animId)) then continue end;
			print('removed', animId);
			table.remove(mobsAnims, table.find(mobsAnims, animId));
		end;
	end;

	local didRoll = false;
	local canDodge = true;

	_G.getCanDodge = function()
		return canDodge;
	end;

	local isBlocking = false;
	local rollOnNextAttacks = {};

	local function checkRange(range, part)
		if (not myRootPart or not part) then
			return false;
		end;

		range += library.flags.distanceAdjustment;

		if (typeof(part) == 'Vector3') then
			part = {Position = part};
		end;

		return (myRootPart.Position - part.Position).Magnitude <= range;
	end;

    local function checkRangeFromPing(obj, rangeCheck, speed)
        if (not myRootPart) then return false end;

        local distance = (obj.Position - myRootPart.Position).Magnitude;
        local playerPing = Stats.PerformanceStats.Ping:GetValue() * 2;

        distance = (obj.Position - myRootPart.Position).Magnitude;
        distance -= speed * (playerPing / 1000);

        return distance <= rangeCheck, distance, playerPing / speed;
    end;

	local function dodgeAttack()
		local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool')
		if (not tool) then return end;

		print('dodge attempt');
		canDodge = false;

		if (library.flags.blatantRoll) then
			dodgeRemote:FireServer('roll', nil, nil, false);

			local humanoid = Utility:getPlayerData().humanoid;
			if (not humanoid) then return end;

			local cancelRight = ReplicatedStorage.Assets.Anims.Movement.Roll.CancelRight
			local track = humanoid:LoadAnimation(cancelRight);
			track:Play();
		else
			if (library.flags.autoFeint and tool and (effectReplicator:FindEffect('MidAttack') or effectReplicator:FindEffect('UsingMove'))) then

				mouse2click();
			end

			for i = 1, 3 do
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game);
				task.wait();
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game);
				task.wait();

				if (not library.flags.rollCancel) then continue end;
				task.delay(library.flags.rollCancelDelay, function()
					VirtualInputManager:SendMouseButtonEvent(1, 1, 1, true, game, 1);
					task.wait();
					VirtualInputManager:SendMouseButtonEvent(1, 1, 1, false, game, 1);
				end);
			end;
		end;
	end;


	_G.playerFPS = 0;
	task.spawn(function() --beautiful code aztup always LOVE
		local i = 0;
		local fps = 0;
		while true do
			fps=fps+1;
			i+=task.wait();
			if i >= 1 then --We basically looping for 1 second in frames and count how many frames it took
				_G.playerFPS = fps;
				fps = 0;
				i = 0;
			end
		end

	end)

	local blockingSignal = Signal.new();

	local function blockAttack(bypassDodge)
		if (not blockRemote or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChildWhichIsA('Tool')) then return end;

        if (library.flags.parryChance < Random.new():NextInteger(1,100)) then return; end
		if (not library.flags.parryWhenDodging and (effectReplicator:FindEffect("DodgeFrame") or effectReplicator:FindEffect("iframe"))) then return; end

		if (library.flags.parryRoll and canDodge and not bypassDodge) then
			didRoll = true;
			dodgeAttack();
			return;
		end;

		isBlocking = true;

		local loopAmount = math.floor(_G.playerFPS*0.1)+1;
		loopAmount = loopAmount >= 12 and 12 or loopAmount;

		local callAmount = math.ceil(12/loopAmount);

		for _ = 1,loopAmount do --How many times to call task.wait
			for _ = 1, callAmount do --How many times we fire the remote between frames
				blockRemote.FireServer(blockRemote);
			end
			task.wait();
		end

		isBlocking = false;
		blockingSignal:Fire();
	end;

	local function unblockAttack()
		if (not unblockRemote or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChildWhichIsA('Tool')) then return end;

		-- if (isBlocking) then
		-- 	blockingSignal:Wait();
		-- end;

		repeat
			task.wait();
		until not isBlocking;

		if (didRoll) then
			didRoll = false;
			return;
		end;

		unblockRemote:FireServer();
	end;

	local function makeDelayBlockWithRange(range, time)
		return {
			waitTime = time,
			maxRange = range
		};
	end;

	--New stuff weird nya

	local function calculatePingWait(n)
		if library.flags.useCustomDelay then
			n+=library.flags.customDelay/1000;
		else
			local playerPing = Stats.PerformanceStats.Ping:GetValue()/1000;
			n -= (playerPing*(library.flags.pingAdjustmentPercentage/100));
		end

		return n;
	end;

	local function parry(timing, rootPart, animationTrack, maxRange)
        local start = tick();

        task.delay(timing/2,function()

			if (not checkRange(maxRange, rootPart)) then
				warn('[Auto Parry] Mob too far away ! Will not feint!!!' .. tostring((rootPart.Position - myRootPart.Position).Magnitude), maxRange);
				return;
			end;

            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
            if (library.flags.autoFeint and tool and (effectReplicator:FindEffect('MidAttack') or effectReplicator:FindEffect('UsingMove'))) then
                if not effectReplicator:FindEffect('UsingSpell') or not library.flags.autoFeintMantra then
					mouse2click();
				end
            end;
        end)

        task.wait(timing);

        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');

        if (not animationTrack.IsPlaying) then
			_G.canAttack = true;
			warn('[Auto Parry] Will return due to the animation no longer playing!');
			return 0;
		end;

		if (library.flags.checkIfTargetFaceYou) then
			local dotProduct = (myRootPart.Position - rootPart.Position):Dot(rootPart.CFrame.LookVector);
			if (dotProduct <= 0) then
				warn('[Auto Parry] Will return due to dot product!');
				return 0;
			end
		end;

        print('anim state', animationTrack.IsPlaying);

        if (not checkRange(maxRange, rootPart)) then
            warn('[Auto Parry] Mob too far away !' .. tostring((rootPart.Position - myRootPart.Position).Magnitude), maxRange);
            _G.canAttack = true;
            return 0;
        end;

		if (library.flags.autoFeint and tool and (effectReplicator:FindEffect('MidAttack') or effectReplicator:FindEffect('UsingMove'))) then
            if not effectReplicator:FindEffect('UsingSpell') or not library.flags.autoFeintMantra then
				mouse2click();
			end
        end;

		local character = rootPart.Parent;
		local particle = character and character:FindFirstChild('MegalodauntBroken', true);
		if (particle and IsA(particle, 'ParticleEmitter') and particle.Enabled) then return 0; end;

		if (rollOnNextAttacks[character] and effectReplicator:FindEffect('ParryCool')) then
			rollOnNextAttacks[character] = nil;
			dodgeAttack();
			warn('[Auto Parry] Dodged due to parry cooldown!!');
			return (tick() - start);
		end;

		blockAttack();
		unblockAttack();

        return (tick()-start);
    end

	local function parryAttack(timings,rootPart,animationTrack,maxRange,useAnimSpeed)
		warn(" CALLED PARRY ATTACK!!!!!")

		local convertedWait = 0;
		local waited = 0;
		local offset = 0;

		_G.canAttack = false;

		for i,timing in next, timings do
			convertedWait = calculatePingWait(timing/(useAnimSpeed and animationTrack.Speed or 1));

			waited = parry(convertedWait-offset,rootPart,animationTrack,maxRange,i);
			warn("WE WAITED "..waited,"CURRENT TIME|"..convertedWait);
			offset = waited-convertedWait;
		end

		_G.canAttack = true;
	end

	local function getSwingSpeed(mob,ignore)
		local hasHeavyHands = false;
		if not ignore then
			for _,v in next, mob:GetChildren() do
				if v.Name ~= 'Ring' or v:GetAttribute("EquipmentRef") ~= "Heavy Hands Ring" then continue; end

				hasHeavyHands = true;
				break;
			end
		end

		local handWeapon = mob:FindFirstChild('HandWeapon', true);
		if (not handWeapon) then return end;

		local swingSpeed = handWeapon:FindFirstChild('SwingSpeed', true);
		if (not swingSpeed) then return end;

		swingSpeed = swingSpeed.Value;

		if hasHeavyHands then
			swingSpeed = swingSpeed - 0.08;
		end

		return swingSpeed+1;
	end

	getgenv().getSwingSpeed = getSwingSpeed;
	getgenv().parryAttack = parryAttack;

	--Resonance Mantra

	animTimes['9236066780'] = function(_, mob) -- Shard Bow
		local distance = (mob.HumanoidRootPart.Position - myRootPart.Position).Magnitude;
		if (distance > 200) then return end;

		pingWait(0.5);

		if (distance > 15) then
			for _, v in next, workspace.Thrown:GetChildren() do
				if (v.Name ~= 'Clip') then continue; end
				if not IsA(v,'BasePart') then continue; end
				task.spawn(function()
					repeat
						task.wait();
					until not v.Parent or checkRange(15,v);

					if not v.Parent then return; end
					blockAttack();
					unblockAttack();
				end)
			end;
		else
			blockAttack();
			unblockAttack();
		end;
	end;

	-- Physical Mantras

	animTimes['8066909599'] = 0.47; -- Revenge
	animTimes['7608490737'] = 0.6; -- HeavenlyWind (Need to be checked)
	animTimes['12706574441'] = 0.45; -- Prominence Draw
	animTimes['6510127521'] = 0.6; -- Prominence Draw 2nd part

	animTimes['8085349676'] = 0.37; -- Strong Left
	animTimes['8198492537'] = 0.3; --Exhaustion Strike

	animTimes['8375086403'] = makeDelayBlockWithRange(40, 0.24); -- Masters Flourish
	animTimes['8379406836'] = makeDelayBlockWithRange(35,0.4); --Rapid Slashes (timing is a big wrong)

	animTimes['8150828674'] = function(_, mob) -- Rapid Punches
		local mobRoot = mob:FindFirstChild('HumanoidRootPart');
		if (not mobRoot and not checkRange(100, mobRoot)) then return end;
		pingWait(0.4);

		if (checkRange(10, mobRoot)) then
			blockAttack();
			unblockAttack();
			return;
		end;

		local didAt, lastParryAt = tick(), 0;

		repeat
			RunService.Stepped:Wait();

			if (checkRange(20, mobRoot) and tick() - lastParryAt > 0.2) then
				lastParryAt = tick();
				blockAttack();
				unblockAttack();
			end;
		until tick() - didAt > 1.1;
		if (tick() - didAt > 1.1) then return print('timed out') end;
	end;

	--Flame Mantra
	animTimes['8378263543'] = 0.3; --Fire Eruption
	animTimes['5953326460'] = 0.35; --Rising Flame

	animTimes['8199600822'] = function(_, mob) --Ash Slam
		parryAttack({0.3,0.3},mob.PrimaryPart,_,30)
	end

	animTimes['5963021481'] =  function(_, mob) --Meteor Slam (Rising Flame Pt2)
		if (not checkRange(10, mob.PrimaryPart)) then return end;

		pingWait(0.3);
		blockAttack();
		unblockAttack();
	end

	animTimes['7693947084'] = makeDelayBlockWithRange(10,0.3); --Flame Grab Close
	animTimes['5750353585'] = function(animationTrack, mob) -- Flame Grab Further
		repeat
			task.wait();
		until not animationTrack.IsPlaying or checkRange(15, mob.PrimaryPart);
		blockAttack();
		unblockAttack();
	end;

	animTimes['7608480718'] = function(_, mob) --Fire Forge
		if (not checkRange(30, mob.PrimaryPart) or not myRootPart) then return end;
		local mobRoot = mob:FindFirstChild('HumanoidRootPart');
		if (not mobRoot) then return end;

		local distance = (myRootPart.Position - mobRoot.Position).Magnitude;
		pingWait(0.05*distance-0.05);

		blockAttack();
		unblockAttack();
	end;

	animTimes['7542502881'] = function(_, mob) --Flame Leap
		if (not checkRange(15, mob.PrimaryPart) or not myRootPart) then return end;

		local mobRoot = mob:FindFirstChild('HumanoidRootPart');
		if (not mobRoot) then return end;
		pingWait(0.3);
		dodgeAttack();
	end;

	animTimes['5769343416'] = function(_, mob) --Burning Servants
		if (not checkRange(10, mob.PrimaryPart) or not myRootPart) then return end;
		local originalPos = mob.PrimaryPart.Position;
		local distance;
		pingWait(0.3);
		task.spawn(function()
			distance = (originalPos - myRootPart.Position).Magnitude;
			if distance > 10 then return; end

			blockAttack();
			unblockAttack();
		end)
		pingWait(1.8);
		distance = (originalPos - myRootPart.Position).Magnitude;
		if distance > 10 then return; end

		blockAttack();
		unblockAttack();
	end;

	animTimes['7585268054'] = function(_, mob) -- Flame Blind
		if (not checkRange(30, mob.PrimaryPart)) then return end;

		pingWait(0.7);
		dodgeAttack();
	end;

	--Thunder Mantra
	animTimes['7599168630'] = 0.2; --Lightning Blade
	animTimes['8183996606'] = makeDelayBlockWithRange(35, 0.4); -- Grand Javelin Small Range
	animTimes['7617742471'] = makeDelayBlockWithRange(60,0.2); --Lightning Beam

	animTimes['5750296638'] = function(_, mob) -- Jolt Grab
		pingWait(0.3);
		if (not checkRange(35, mob.PrimaryPart)) then return end;

		table.foreach(mob:GetChildren(), warn);

		if (not mob:FindFirstChild('ShadowHand')) then
			print('we use other');
			pingWait(0.2);
		end;

		blockAttack();
		unblockAttack();
	end;

	animTimes['5968282214'] = function(_, mob) -- Lightning Assault (The tp move)
		local target = mob:FindFirstChild('Target');
		if (target or not checkRange(85, mob.PrimaryPart)) then return end;

		pingWait(0.4);
		blockAttack();
		unblockAttack();
	end;

	animTimes['7861127585'] = 0.45; -- Thunder Kick
	animTimes['12333753799'] = 0.3; -- Thunder Rising windup

	animTimes['12333759044'] = function(_, mob) -- Thunder Rising Cast
		pingWait(0.3);

		repeat
			task.wait();
		until checkRange(30, mob.PrimaryPart) or not _.IsPlaying;
		if (not _.IsPlaying and not checkRange(30, mob.PrimaryPart)) then return print('stopped'); end;
		print('he close');

		blockAttack();
		unblockAttack();
	end;

	animTimes['5968796999'] = function(_, mob) -- Lightning Stream
		local distance = (mob.HumanoidRootPart.Position - myRootPart.Position).Magnitude;
		if (distance > 200) then return end;

		pingWait(0.4);
		local ranAt = tick();

		if (distance > 15) then
			repeat
				for _, v in next, workspace.Thrown:GetChildren() do
					if (v.Name == 'STREAMPART' and IsA(v, 'BasePart')) then
						local rocket = v:FindFirstChild('RocketPropulsion');
						local rocketTarget = rocket and rocket.Target;
						if (rocketTarget ~= myRootPart) then continue end;
						if(not checkRangeFromPing(v, 20, 30)) then continue end;

						blockAttack();
						unblockAttack();
						break;
					end;
				end;

				task.wait();
			until tick() - ranAt > 3.5;
		else
			blockAttack();
			unblockAttack();
		end;
	end;

	-- Silent Heart
	animTimes['12564120372'] = 0.3; -- Silent heart slide m1

	-- Dawn Walker
	animTimes['10622235550'] = function(anim,mob) -- Blinding Dawn
		pingWait(0.5);
		local start = tick();
		repeat
			if checkRange(37,mob.PrimaryPart) then
				blockAttack();
				unblockAttack();
			end
			task.wait(0.1);
		until not anim.IsPlaying or tick()-start >= 2;
		print("FINISHED")
	end

	-- Link Strider
	animTimes['10104294736'] = 0.3; -- Symbiotic Link

	-- Arc Warder
	animTimes['9481400792'] = makeDelayBlockWithRange(20,0.3); -- Arc Beam
	animTimes['9536688585'] = makeDelayBlockWithRange(30,0.4); -- Arc Wave

	-- Star Kindered (No element)
	animTimes['9941118927'] = 0.3; -- Celestial Assault

	animTimes['9461513613'] = function(anim,mob) -- Ascension
		repeat task.wait() until checkRange(25,mob.HumanoidRootPart) or not anim.IsPlaying
		if not anim.IsPlaying then return; end

		dodgeAttack();
	end;

	-- Star Kindered Fire
	animTimes['9717753391'] = function(anim,mob) -- Celestial Fireblade
		pingWait(1);
		local start = tick();
		repeat
			if (checkRange(50, mob.PrimaryPart)) then
				blockAttack();
				unblockAttack();
			end;
			task.wait(0.1);
		until not anim.IsPlaying or tick() - start >= 2;
	end

	animTimes['9919986614'] = function(anim,mob) -- Sinister Halo
		pingWait(0.4);

		if not checkRange(25,mob.PrimaryPart) or not anim.IsPlaying then return; end
		blockAttack();
		unblockAttack();
		pingWait(0.6);
		if not checkRange(25,mob.PrimaryPart) then return; end;

		for i = 1,5 do
			blockAttack();
			unblockAttack();
		end;
	end;

	-- Contractor
	animTimes['9726608174'] = makeDelayBlockWithRange(50, 0.5); -- Contractor Judgement
	animTimes['11862841821'] = 0.3; -- Contractor Equalizer
	animTimes['11328614766'] = function(_, mob) -- Contractor Pull
		pingWait(0.4);
		repeat task.wait(); until checkRange(20, mob.PrimaryPart) or not _.IsPlaying;
		if (not _.IsPlaying) then return print('timed out'); end;
		blockAttack();
		unblockAttack();
	end;

	--Monster Mantra
	animTimes['11219902982'] = function(anim,mob) -- Dread Breath
		pingWait(0.5);
		local start = tick();
		repeat
			if checkRange(40,mob.PrimaryPart) then
				blockAttack();
				unblockAttack();
			end
			task.wait(0.1);
		until not anim.IsPlaying or tick()-start >= 2;
	end

	--Ice Mantra
	animTimes['7598898608'] = 0.45; --Ice Smash
	animTimes['6396523003'] = 0.3; -- Crystal Knee
	animTimes['7616100008'] = function(animTrack, mob) -- Ice Beam
		if (not checkRange(85, mob.PrimaryPart)) then return end;

		local t = 0.00142*(mob.PrimaryPart.Position - myRootPart.Position).Magnitude + 0.58;
		parryAttack({t}, mob.PrimaryPart, animTrack, 85);
	end;

	animTimes['5786525661'] = function(_,mob) -- Warden Blades
		local elapsedAt = tick();
		pingWait(0.45);

		if (checkRange(25, mob.PrimaryPart)) then
			blockAttack();
			unblockAttack();
		end;

		repeat
			if (not checkRange(25, mob.PrimaryPart)) then task.wait() continue end;
			pingWait(0.8);
			task.spawn(function()
				blockAttack();
				unblockAttack();
			end);
		until tick() - elapsedAt > 3;
	end;

	animTimes['8018953639'] = function() -- Ice Chains
		pingWait(1.1);
		local chainPortalIce = workspace.Thrown:FindFirstChild('ChainPortalIce');
		if (not checkRange(20, chainPortalIce)) then return end;
		dodgeAttack();
	end;

	animTimes['8265980703'] = function(_, mob) --Ice Lance
		if (not checkRange(50, mob.PrimaryPart) or not myRootPart) then return end;
		local mobRoot = mob:FindFirstChild('HumanoidRootPart');
		if (not mobRoot) then return end;

		local distance = (myRootPart.Position - mobRoot.Position).Magnitude;

		if (distance < 15) then
			print('melee');
			pingWait(0.3);
		elseif (distance < 20) then
			print('far melee');
			pingWait(0.8);
		elseif (distance < 30) then
			print('far');
			pingWait(0.9);
		elseif (distance < 40) then
			print('rly far');
			pingWait(1);
		end;

		blockAttack();
		unblockAttack();
	end;

	-- Wind Mantra
	animTimes['7618754583'] = makeDelayBlockWithRange(40, 0.3); -- Gale Punch/Flame Palm
	animTimes['6470684331'] = makeDelayBlockWithRange(40, 0.45); -- Astral Wind
	animTimes['8310877920'] = makeDelayBlockWithRange(20, 0.4) -- Wind Gun
	animTimes['5828315760'] = makeDelayBlockWithRange(50, 0.3); -- Air Force

	animTimes['6466993564'] = 0.38; -- Wind Carve
	animTimes['9629695751'] = 0.35; --Champions Whirl Throw
	animTimes['10357806593'] = makeDelayBlockWithRange(15, 0.3); -- Tornado Kick

	animTimes['6030770341'] = function(_, mob) --Heavenly Wind
		pingWait(0.2);
		if (not checkRange(50, mob.PrimaryPart)) then return end;
		blockAttack();
		unblockAttack();
	end;

	animTimes['7794260173'] = function(_, mob) -- Wind Rising
		if (not checkRange(15, mob.PrimaryPart)) then return end;
		pingWait(0.4);
		blockAttack();
		unblockAttack();
	end;

	animTimes['9400896040'] = function(_, mob) -- Shoulder Bash
		local startedAt = tick();
		pingWait(0.3);

		repeat
			task.wait();
		until tick() - startedAt >= 5 or checkRange(20, mob.PrimaryPart);
		blockAttack();
		unblockAttack();
	end;

	animTimes['6017393708'] = makeDelayBlockWithRange(15, 0.3); -- Gale Lunge
	animTimes['6017418456'] = function(_, mob) -- Gale Lunge Launch Anim
		local mobRoot = mob:FindFirstChild('HumanoidRootPart');
		if (not mobRoot or not checkRange(35, mobRoot)) then return end;
		local distance = (mobRoot.Position - myRootPart.Position).Magnitude;
		pingWait(0.01*distance + 0.25);

		blockAttack();
		unblockAttack();
	end;

	animTimes['8375571405'] = function(animationTrack, mob) -- Pressure Blast
		if (not checkRange(40, mob.PrimaryPart)) then return end;
		pingWait(0.5);
		blockAttack();
		repeat
			task.wait();
		until not animationTrack.IsPlaying or not checkRange(40, mob.PrimaryPart);
		unblockAttack();
	end;

	-- Uppercut
	animTimes['11887898774'] = 0.3;
	animTimes['11887938902'] = 0.3;
	animTimes['11887876811'] = 0.3;
	animTimes['11887887621'] = 0.3;
	animTimes['11887892548'] = 0.3;
	animTimes['11887901212'] = 0.3;
	animTimes['11887874227'] = 0.3;

	-- Scythe
	animTimes['11493920418'] = 0.3; -- Slash 1
	animTimes['11493923277'] = 0.3; -- Slash 2
	animTimes['9597289518'] = 0.3; -- Slash 3
	animTimes['11493924588'] = 0.4; -- Running Attack

	do -- Great Axe
		local function getSpeed(x)
			return -1*x+2.05;
		end;

		local function f(animTrack, mob)

			local ignoreHeavyHand = false;
			for i,v in next, mob.Humanoid:GetPlayingAnimationTracks() do
				if v.Animation.AnimationId ~= 'rbxassetid://5971953898' or not v.IsPlaying then continue; end

				ignoreHeavyHand = true;
			end
			local swingSpeed = getSwingSpeed(mob,ignoreHeavyHand) or 1;

			parryAttack({getSpeed(swingSpeed)},mob.PrimaryPart,animTrack,15);
		end;

		animTimes['5064195992'] = f; -- Slash1
		animTimes['5067105317'] = f; -- Slash2
		animTimes['5067090007'] = f; -- Slash3 Also running attack
		animTimes['9484850093'] = 0.3; -- Slash4 (Kick)

		animTimes['7388133473'] = 0.65; -- Critical
		animTimes['10768748584'] = 0.6; -- Enforcer Axe Critical

		animTimes['11363599835'] = function(_, mob) -- Heavy Aerial
			pingWait(0.4);

			repeat
				task.wait();
			until checkRange(20, mob.PrimaryPart) or not _.IsPlaying;
			if (not _.IsPlaying) then return end;

			blockAttack();
			unblockAttack();
		end;
	end;

	animTimes['5805138186'] = 0.38;
	animTimes['4880830128'] = 0.35;
	animTimes['4880833465'] = 0.35;

	-- Railblade
	animTimes['9832721746'] = 0.4; -- Slash1
	animTimes['9832724876'] = 0.4; -- Slash2
	animTimes['9832727905'] = 0.4; -- Slash3
	animTimes['9597289518'] = 0.3; -- Slash4
	animTimes['9893133020'] = 0.4; -- Air Critical
	animTimes['9863424290'] = function(_, mob) -- Ground Critical
		task.spawn(function()
			pingWait(1.1);
			if (not _.IsPlaying or not checkRange(40, mob.PrimaryPart)) then return print('hi') end;
			dodgeAttack();
		end);

		pingWait(0.5);
		repeat
			task.wait();
		until not _.IsPlaying or checkRange(20, mob.PrimaryPart);
		if (not _.IsPlaying) then return print('timed out not playing') end;
		blockAttack();
		unblockAttack();
	end;

	-- Dagger
	do
		local function getSpeed(x)
			return -0.5*x + 1.275;
		end;

		local function f(animTrack, mob)
			local swingSpeed = getSwingSpeed(mob) or 1;

			parryAttack({getSpeed(swingSpeed)},mob.PrimaryPart,animTrack,15);
		end;

		animTimes['7627854272'] = f; -- Slash1
		animTimes['7627889074'] = f; -- Slash2
		animTimes['5950080662'] = 0.3; -- Slash4 (Kick)
		animTimes['5063313656'] = 0.39; -- Running Attack
		animTimes['7576614609'] = 0.39; -- Aerial Stab
	end;

	do --Spear Timings
		local function getSpeed(x)
			return -1*x+2.07;
		end;

		local function f(animTrack, mob)
			local swingSpeed = getSwingSpeed(mob) or 1;

			parryAttack({getSpeed(swingSpeed)},mob.PrimaryPart,animTrack,15);
		end;

		animTimes['7626771915'] = f; -- One Hand Slash 3
		animTimes['7627049402'] = f; -- One Hand Slash 4

		animTimes['7627558238'] = f; -- Two Hand Slash 2
		animTimes['7627372304'] = f; -- Two Hand Slash 3
	end;

	animTimes['5827250000'] = 0.35; -- Running Attack One Handed
	animTimes['5827423063'] = 0.35; -- Slash1

	animTimes['7576748728'] = 0.35; -- Aerial Stab

	-- Crazy Slot
	animTimes['7004327185'] = 0.3; --Crazy Slot Sword Mantra
	animTimes['7003448248'] = 0.6; --Crazy Slot Greatsword Mantra
	animTimes['7007372121'] = 1.8; --Crazy Slot Greataxe Mantra

	animTimes['7007974914'] = function(_,mob)--Crazy Slot Gun Mantra
		parryAttack({0.2,0.4,0.4},mob.PrimaryPart,_,20)
	end;
	animTimes['7005236296'] = makeDelayBlockWithRange(35,0.5); --Crazy Slot Dagger Mantra

	do -- Greatsword
        local function getSpeed(x)
            return -1*x+2.05;
        end;

		local function f(animTrack, mob)
			local swingSpeed = getSwingSpeed(mob) or 1;

			parryAttack({getSpeed(swingSpeed)},mob.PrimaryPart,animTrack,15);
		end;

		animTimes['12071495751'] = makeDelayBlockWithRange(10,0.5); --Petra Crit Start

		animTimes['12071557016'] = function(_, mob) -- Petra Critical
			repeat
				task.wait();
			until not _.IsPlaying or checkRange(20, mob.PrimaryPart);
			if (not _.IsPlaying) then return print('timed out not playing') end;
			blockAttack();
			unblockAttack();
		end;

		animTimes['12071942369'] = 0.6; -- Petra Critical (Pt2)

		animTimes['6675698010'] = f;
		animTimes['6675703249'] = f;

		animTimes['10258479464'] = 0.65; -- DarkSteel Critical
		animTimes['10053070573'] = function(animTrack, mob) --Crescent Cleaver (Timing is a little bit better but still inaccurate due to range)
			local root = mob:FindFirstChild('HumanoidRootPart');
			if (not root) then return end;

			local distance = (myRootPart.Position - root.Position).Magnitude;
			local t = math.max(0.7, 0.03*distance + 0.5);

			pingWait(t);
			if (not checkRange(20, root)) then return end;

			blockAttack();
			unblockAttack();
		end;

		-- Firstlight

		animTimes['13241958217'] = f;
		animTimes['13242083070'] = f;
	end;

	-- Sword
	do
		local function getSpeed(x)
			return -1*x+2.1;
		end;

		local function f(animTrack, mob)
			local swingSpeed = getSwingSpeed(mob) or 1;

			parryAttack({getSpeed(swingSpeed)},mob.PrimaryPart,animTrack,15);
		end;

		animTimes['7600450739'] = f; -- Slash1
		animTimes['7600485223'] = f; -- Slash2
		animTimes['7600160919'] = f; -- Slash3
		animTimes['7600224169'] = f; -- Slash4
	end;

	animTimes['8095864854'] = 0.55; -- Special Critical (Serpent's Edge)

	-- Curve Blade Of Winds
	animTimes['12106091136'] = 0.3; -- Slash1
	animTimes['12106093579'] = 0.3; -- Slash2
	animTimes['12106095892'] = 0.3; -- Slash3

	-- running attack (we use db)
	animTimes['4699358112'] = 0.36;

	animTimes['7827886914'] = 0.47; -- Katana critical
	animTimes['7351158603'] = 0.35; -- Spear critical
	animTimes['7318254065'] = 0.67; -- Sword critical
	animTimes['7350770431'] = 0.45; -- Dagger critical
	animTimes['7367818208'] = 0.73; -- Hammer critical
	animTimes['12921226261'] = 0.5; -- Sacred Hammer Crit
	animTimes['9209255758'] = 0.3; -- Whailing Knife Critical

	-- Karate (Way of Navae)
	do
		local function f(animTrack, mob)
			parryAttack({0.225}, mob.PrimaryPart, animTrack, 15, true);
		end;

		animTimes['6063188218'] = f; -- Slash 1
		animTimes['7616407967'] = f; -- Slash 2
		animTimes['6063195211'] = f; -- Slash 3
	end;

	-- Jus Karita
	animTimes['8278926990'] = 0.25; -- Slash1
	animTimes['8278929677'] = 0.25; -- Slash2
	animTimes['8278931393'] = 0.25; -- Slash3
	animTimes['9597289518'] = 0.3; -- Slash4 (Kick)
	animTimes['8278933540'] = 0.25; -- Slash4 (Kick)

	animTimes['7391446645'] = 0.5; -- Kick
	animTimes['8295145565'] = 0.4; -- Kick Ground?
	animTimes['8367730650'] = 0.3; -- Running Attack
	animTimes['8194213529'] = 0.3; -- Aerial Stab
	animTimes['10168663111'] = function(animationTrack,mob) --Tacet Drop Kick
		parryAttack({0.3},mob.PrimaryPart,animationTrack,30);
	end

	-- Legion Kata
	do
		local function f(animTrack, mob)
			parryAttack({0.2}, mob.PrimaryPart, animTrack, 20, true);
		end;

		animTimes['8161039359'] = f; -- Slash 1
		animTimes['8161043368'] = f; -- Slash 2
		animTimes['8161044711'] = f; -- Slash 3
		animTimes['8161094751'] = 0.3; -- Slash4 (Kick)
		animTimes['8169914770'] = 0.25; --This timing is prob wrong prob ius 0.3 but idk for duke
	end;

	-- Lantern Kata
	animTimes['11186652658'] = 0.3; -- Slash 1
	animTimes['11186654931'] = 0.3; -- Slash 2
	animTimes['11186656574'] = 0.3; -- Slash 3
	animTimes['9597289518'] = 0.3; -- Slash 4

	-- Mace/Club (we use db)
	animTimes['5805183957'] = 0.36; -- Slash1
	animTimes['5805191624'] = 0.41; -- Slash2
	animTimes['5805194816'] = 0.4; -- Slash3
	animTimes['7599410106'] = 0.52; -- Club critical

	-- Rapier
	animTimes['8249175106'] = 0.32; -- Slash
	animTimes['8249177669'] = 0.32; -- Slash
	animTimes['8249271040'] = 0.32; -- Critical

	-- Enforcer Blade (we use db)
	animTimes['6607519294'] = 0.45;
	animTimes['6607538047'] = 0.49;
	animTimes['6669352471'] = 0.39;

	-- Widow
	animTimes['6428519131'] = function(anim, mob) -- Widow Left Swing
		parryAttack({0.43}, mob.PrimaryPart, anim, 100, true);
	end;

	animTimes['6428525211'] = function(anim, mob) -- Widow Doublestab
		parryAttack({0.3}, mob.PrimaryPart, anim, 100);
	end;

	animTimes['6428514850'] = function(anim, mob) -- Widow RightSwing
		parryAttack({0.43}, mob.PrimaryPart, anim, 100, true);
	end;

	animTimes['6428530032'] = function(_, mob) -- Widow Spit
		if (not checkRange(100, mob.PrimaryPart)) then return end;
		pingWait(0.6);
		dodgeAttack();
	end;

	animTimes['6428533082'] = function(_, mob) -- Widow Bite
		if (not checkRange(100, mob.PrimaryPart)) then return end;
		pingWait(0.4);
		dodgeAttack();
	end;

	-- Primadon
	animTimes['8940731625'] = function(_, mob) --Scream
		if (not checkRange(100, mob.PrimaryPart)) then return end;
		pingWait(0.75);
		dodgeAttack();
	end;

	animTimes['8365199156'] = function(_, mob) -- Mid Swipe (Punch)
		if (not checkRange(100, mob.PrimaryPart)) then return end
		pingWait(0.5/_.Speed);

		blockAttack();
		task.wait();
		unblockAttack();
	end;

	animTimes['9225081967']  = function(_, mob) -- Swipe
		if (not checkRange(100, mob.PrimaryPart)) then return end
		pingWait(0.6 / _.Speed)

		blockAttack();
		task.wait();
		unblockAttack();
	end;

	animTimes['9225086332'] = function(_, mob) -- Grab
		if (not checkRange(100, mob.PrimaryPart)) then return end
		pingWait(0.6 / _.Speed);
		print('we dodge', _.TimePosition, _.Speed);

		dodgeAttack(true);
	end;

	animTimes['6438111139'] = function(_, mob) -- Punt
		if (not checkRange(100, mob.PrimaryPart)) then return end
		pingWait(0.75 / _.Speed);
		dodgeAttack();
	end;

	animTimes['9225098544'] = function(_, mob) --Stomp
		parryAttack({0.75}, mob.PrimaryPart, _, 100, true);
	end;

	animTimes['6432260013'] = function(anim, mob) -- Triple Stomp
		parryAttack({0.8, 0.775, 0.75}, mob.PrimaryPart, anim, 100, true);
	end;

	-- Avatar (Ethiron)
	animTimes['11508725111'] = function(_, mob)
		parryAttack({1.5}, mob.PrimaryPart, _, 400, true);
	end;

	-- crabbo
	animTimes['8176091986'] = makeDelayBlockWithRange(50, 1); --Double slam
	animTimes['7942002115'] = makeDelayBlockWithRange(50, 0.4); --Probably double swipe

	animTimes['7938093143'] = function(_, mob) -- grab
		if (not checkRange(50, mob.PrimaryPart)) then return end;

		pingWait(0.5);
		dodgeAttack();
	end;

	animTimes['7961600084'] = function(_,mob) --Jump attack
		if not checkRange(150,mob.PrimaryPart) then return; end
		repeat
			task.wait();
		until not _.IsPlaying or checkRange(15,mob.PrimaryPart)
		if not _.IsPlaying then return; end
		dodgeAttack();
	end;

	--Guns
	do
		local function getSpeed(x)
			return -0.5*x + 1.275; --Should be -0.5*x + 1.05
		end;

		local function f(animTrack, mob)
			local swingSpeed = getSwingSpeed(mob) or 1;

			parryAttack({getSpeed(swingSpeed)},mob.PrimaryPart,animTrack,15);
		end;

		animTimes['6437665734'] = f; -- Primary Shot
		animTimes['6432920452'] = f; -- Offhand shot
		animTimes['7565307809'] = f; -- Aerial Shot
		animTimes['8172871094'] = makeDelayBlockWithRange(20, 0.3); -- Rifle Spear Crit
	end;

	animTimes['9928429385'] = 0.3; -- Rifle
	animTimes['9928485641'] = 0.3; -- Rifle
	animTimes['9930447958'] = 0.3; -- Rifle
	animTimes['9928485641'] = 0.3; -- Rifle
	animTimes['9930618934'] = 0.3; -- Rifle

	animTimes['11468287607'] = 0.4; -- Shadow Hero Blade Critical
	animTimes['11312302005'] = 0.4; -- Wind Hero Blade Critical
	animTimes['11308969885'] = 0.4; --Flame Hero Blade Critical
	animTimes['10904625331'] = 0.4; --Thunder Hero Blade Critical
	animTimes['11183196198'] = makeDelayBlockWithRange(28,0.4); --Frost Hero Blade Critical

	animTimes['12108376249'] = 0.3; -- Eclipse kick
	animTimes['9212883524'] = 0.6; -- Halberd Critical

	animTimes['6415074870'] = function(_, mob) -- Shadow Gun
		if (not checkRange(60, mob.PrimaryPart)) then return end;

		pingWait(0.5);
		blockAttack();
		task.wait(0.3);
		unblockAttack();
	end;

	-- Golem
	animTimes['6500704554'] = function(_, mob) -- Upsmash (Dodge)
		if (not checkRange(50, mob.PrimaryPart)) then return end;

		pingWait(0.4);
		dodgeAttack();
	end;

	animTimes['6501497627'] = function(animationTrack, mob) -- Cyclone
		if (not mob.PrimaryPart) then return end;
		pingWait(3.3);

		repeat
			task.wait(0.1);

			if (not checkRange(50, mob.PrimaryPart)) then
				print('mob too far away :(');
				_G.canAttack = true;
				continue;
			end;

			_G.canAttack = false;
			print(animationTrack.IsPlaying, animationTrack.Parent);
			blockAttack();
			unblockAttack();
		until not animationTrack.IsPlaying or not mob.Parent;
		_G.canAttack = true;
	end;

	animTimes['6499077558'] = makeDelayBlockWithRange(50, 0.4); -- Double Smash
	animTimes['6501044846'] = makeDelayBlockWithRange(50, 0.5); -- Stomp

	-- Ice Mantra
	animTimes['5808939025'] = function(_, mob) -- Ice Eruption
		if (not checkRange(40, mob.PrimaryPart)) then return end;

		pingWait(0.35);
		dodgeAttack();
	end;

	animTimes['5865907089'] = function(_, mob) -- Glacial Arc
		if (not checkRange(40, mob.PrimaryPart)) then return end;

		pingWait(0.6);
		blockAttack();
		unblockAttack();
	end;

	animTimes['7612017515'] = makeDelayBlockWithRange(50, 0.3); -- Ice Blade
	animTimes['7543723607'] = 0.7; -- Ice Spike
	animTimes['7599113567'] = 0.6; -- Ice Dagger
	animTimes['6054920207'] = 0.3; -- Crystal Impale

	-- Shadow
	animTimes['9470857690'] = makeDelayBlockWithRange(40, 0.2); -- Shade Bringer
	animTimes['9359697890'] = 0.3; -- Shadow Devour
	animTimes['11959603858'] = 0.9; -- Shadow Stomp
	animTimes['11468287607'] = 0.4; -- Shadow Sword

	animTimes['9149348937'] = function(_, mob) -- Rising Shadow
		local distance = (mob.HumanoidRootPart.Position - myRootPart.Position).Magnitude;
		if (distance > 200) then return end;

		pingWait(0.4);
		local ranAt = tick();

		print(distance);
		if (distance > 8) then
			repeat
				for _, v in next, workspace.Thrown:GetChildren() do
					if (v.Name == 'TRACKER' and IsA(v, 'BasePart')) then
						if(not checkRangeFromPing(v, 5, 10)) then continue end;

						print('block');
						blockAttack();
						unblockAttack();
						break;
					end;
				end;

				task.wait();
			until tick() - ranAt > 3.5;
		else
			blockAttack();
			unblockAttack();
		end;
	end;

	animTimes['6318273143'] = function(_, mob) -- Shadow Assault
		if (not checkRange(80, mob.PrimaryPart) or not myRootPart) then return end;

		local mobRoot = mob:FindFirstChild('HumanoidRootPart');
		if (not mobRoot) then return end;

		local distance = (mobRoot.Position - myRootPart.Position).Magnitude;
		pingWait(0.3);
		pingWait(distance/60);
		blockAttack();
		unblockAttack();
	end;

	animTimes['8018881257'] = function(_, mob) -- Shadow eruption
		for i = 1, 2 do
			task.spawn(function()
				pingWait(i*0.33);
				if (not checkRange(30, mob.PrimaryPart)) then return end;
				blockAttack();
				unblockAttack();
			end);
		end;
	end;

	animTimes['7620630583'] = function(_, mob) -- Shadow Roar
		repeat
			pingWait(0.2);
			if (not checkRange(40, mob.PrimaryPart)) then continue end;
			task.spawn(function()
				blockAttack();
				unblockAttack();
			end);
		until not _.IsPlaying;
	end;

	animTimes['6038858570'] = function(animationTrack,mob) -- Darkblade
		if (not checkRange(80, mob.PrimaryPart)) then return end
		local distance = (myRootPart.Position - mob.PrimaryPart.Position).Magnitude;
		if distance < 5 then
			pingWait(0.37);
			blockAttack();
			unblockAttack();
			return;
		end
		repeat
			task.wait();
		until not animationTrack.IsPlaying or checkRange(15,mob.PrimaryPart);
		if not animationTrack.IsPlaying then return; end
		blockAttack();
		unblockAttack();
	end

	-- snow golem
	animTimes['8131612979'] = function(_, mob) -- groundPunch
		if (not checkRange(60, mob.PrimaryPart)) then return end

		pingWait(0.7);
		dodgeAttack();
	end;

	animTimes['8131156119'] = function(_, mob) -- Punt
		if (not checkRange(60, mob.PrimaryPart)) then return end

		pingWait(0.2)
		dodgeAttack();
	end;

	animTimes['8130745441'] = makeDelayBlockWithRange(40, 0.3); -- Swing1
	animTimes['8130778356'] = makeDelayBlockWithRange(40, 0.3); -- Swing2

	animTimes['8131374542'] = makeDelayBlockWithRange(100, 0.7); -- Air cutter

	-- squiddo (we use db)
	animTimes['6916513795'] = 0.225;
	animTimes['6916546485'] = 0.225;
	animTimes['6916545890'] = 0.225;

	-- enforcer (we use db)
	animTimes['7018046790'] = makeDelayBlockWithRange(50, 0.45); -- slash 1
	animTimes['7018083796'] = makeDelayBlockWithRange(50, 0.45); -- slash 2
	animTimes['7019686291'] = makeDelayBlockWithRange(50, 0.45); -- kick

	animTimes['7019018522'] = function(animationTrack, mob) -- spin
		print('got spin to win');

		repeat
			pingWait(0.1);

			if (not checkRange(30, mob.PrimaryPart)) then
				print('mob too far away :(');
				continue;
			end;

			blockAttack();
			unblockAttack();
		until not animationTrack.IsPlaying;
	end;

	-- Hive Mech
	animTimes['11834551880'] = function(_,mob)  --Roguemech upsmash
		if not checkRange(40,mob.PrimaryPart) then return; end
		pingWait(0.8);
		dodgeAttack();
	end;

	animTimes['11834549387'] = 0.5; --Roguemech Stomp
	animTimes['11834545925'] = 0.3; --Roguemech  Baragge Stomp
	animTimes['11867360757'] = makeDelayBlockWithRange(40,0.7); --Roguemech GroundPound

	-- crocco (we use db)
	animTimes['8226933122'] = function(_, mob) -- Triple bite
		parryAttack({0.44, 0.44, 0.44}, mob.PrimaryPart, _,  30);
	end;

	animTimes['10976633163'] = function(_, mob) -- Crocco Dig Move
		pingWait(0.7);

		local ranAt = tick();

		repeat
			task.wait();
			print(mob.HumanoidRootPart.Transparency);
		until checkRange(10, mob.HumanoidRootPart) or mob.HumanoidRootPart.Transparency == 0;
		if (tick() - ranAt > 8) then return print('not playing') end;

		print('parry!');

		blockAttack();
		unblockAttack();
	end;

	animTimes['8227583745'] = function(_, mob) --Double shlash Crocco
		parryAttack({0.3, 0.8}, mob.PrimaryPart, _, 30);
	end;

	animTimes['8228293862'] = function(_, mob) -- Breath
		if (not checkRange(75, mob.PrimaryPart)) then return end;

		pingWait(0.35);
		dodgeAttack();
	end;

	animTimes['8229868275'] = function(_, mob) -- Dig
		if (not checkRange(30, mob.PrimaryPart)) then return end;

		pingWait(2);
		dodgeAttack();
	end;

	animTimes['8227878518'] = function(_, mob) -- Tail
		parryAttack({0.65}, mob.PrimaryPart, _, 30);
	end;

	-- Black Tresher
	animTimes['11095471496'] = 0.4; -- Crocco Flip
	animTimes['9474995715'] = function(_,mob)-- CRocco Breath
		if not checkRange(20,mob.PrimaryPart) then return; end
		task.wait(0.2);
		dodgeAttack();
	end;

	-- sharko (we use db)
	animTimes['5117879514'] = function(animTrack, mob) -- Swipe
		parryAttack({0.37}, mob.PrimaryPart, animTrack, 40);
	end;

	animTimes['11710417615'] = function(animationTrack, mob) --Coral Attack
		-- sharko could do aoe attack if lots of player check that

		local target = mob:FindFirstChild('Target');
		target = target and target.Value;
		if (target ~= LocalPlayer.Character) then return end;

		pingWait(0.4);
		blockAttack();

		repeat
			task.wait();
		until not animationTrack.IsPlaying;

		unblockAttack();
	end;

	animTimes['10739102450'] = function(_, mob) -- Cortal Attack But for Player
		parryAttack({0.4}, mob.PrimaryPart, _, 35);
	end;

	animTimes['5121733951'] = function(_, mob) -- sharko double swipe
		parryAttack({0.43,0.58},mob.PrimaryPart,_,40);
	end;

	animTimes['11710290503'] = function(_, mob) -- sharko punt
		if (not checkRange(40, mob.PrimaryPart)) then return end;

		pingWait(0.35)
		dodgeAttack();
	end;

	animTimes['9357410713'] = function(_,mob) -- Mechalodant Beam
		pingWait(1.6);
		if not checkRange(80,mob.PrimaryPart) then return; end
		blockAttack();
		unblockAttack();
	end

	animTimes['9356892933'] = function(animationTrack, mob) -- Mechalodant GunFire
		local target = mob:FindFirstChild('Target');
		target = target and target.Value;
		if (target ~= LocalPlayer.Character) then return end;

		pingWait(0.4);
		blockAttack();

		repeat
			task.wait();
		until not animationTrack.IsPlaying;

		unblockAttack();
	end;

	animTimes['11710316011'] = function(_,mob) -- Sharko Water bite
		pingWait(0.5);
		if not checkRange(50,mob.PrimaryPart) then return; end
		dodgeAttack();
	end;

	animTimes['9903304018'] = function(_, mob) --Teleport Move
		pingWait(0.5);
		if (not checkRange(20, mob.PrimaryPart)) then return print('too far away') end;
		warn('block');
		dodgeAttack();
	end;

	--Ferryman
	local teleportedAt = tick();
	local firstAnim = tick();
	animTimes['5968288116'] = function(_, mob) -- Ferryman Teleport Attack (Doesn't work in second phase...)
		local target = mob:FindFirstChild('Target');
		if (not target or target.Value ~= LocalPlayer.Character) then return  warn('Ferryman Dash: Target is not LocalPlaye') end;

		if (mob.Humanoid.Health/mob.Humanoid.MaxHealth)*100 >= 50 then
			if tick()-teleportedAt > 2 then
				if tick() - firstAnim > 3 then
					firstAnim = tick();
					return;
				end
				teleportedAt = tick();
				parryAttack({0.8},mob.PrimaryPart,_,1000,true)
			else
				teleportedAt = tick();
				parryAttack({0.2},mob.PrimaryPart,_,1000,true)
			end
		else
			if tick()-teleportedAt > 2 then
				if tick() - firstAnim > 3 then
					firstAnim = tick();
					return;
				end
				teleportedAt = tick();
				parryAttack({0.8},mob.PrimaryPart,_,1000,true)
			else
				teleportedAt = tick();
				parryAttack({0.1},mob.PrimaryPart,_,1000,true)
			end
		end
	end;


	-- Owl
	animTimes['7639648215'] = makeDelayBlockWithRange(40, 0.3); -- Swipe (Idk)
	animTimes['7639988883'] = makeDelayBlockWithRange(40, 0.6); -- Slow Swipe (Ok)
	animTimes['7675544287'] = function(_, mob) -- Grab
		local target = mob:FindFirstChild('Target');
		target = target and target.Value;

		if (target ~= LocalPlayer.Character) then return warn('owl grab: target is not localplayer') end;

		pingWait(0.35);
		dodgeAttack();
	end;

	animTimes['7673097597'] = function(_, mob) -- Owl rush (spinning attack)
		local target = mob:FindFirstChild('Target');
		target = target and target.Value;

		if (target ~= LocalPlayer.Character) then return print('owl spin target is not localplayer') end;

		pingWait(0.37);
		dodgeAttack();
	end;

	-- Mud Skipper
	animTimes['11573034823'] = 0.22;
	animTimes['11572468462'] = 0.22;

	-- Lion Fish

	animTimes['5680585677'] = function(_, mob)
		if (not checkRange(70, mob.PrimaryPart)) then return print('lion fish beam triple bite too far away') end;

		task.spawn(function()
			pingWait(0.4);
			blockAttack();
			unblockAttack();
		end);

		task.spawn(function()
			pingWait(1.1);
			blockAttack();
			unblockAttack();
		end);

		task.spawn(function()
			pingWait(1.8);
			blockAttack();
			unblockAttack();
		end);
	end;

	animTimes['6372560712'] = function(animTrack, mob) -- FishBeam
		local target = mob:FindFirstChild('Target');
		target = target and target.Value;

		if (target ~= LocalPlayer.Character) then return print('lion fish beam target not set to player') end;

		local wasUp = false;

		repeat
			local _, _, z = mob:GetPivot():ToOrientation();

			if (z < -1.7 and not wasUp) then
				wasUp = true;
				warn('rised up');
			elseif (z > -1.5 and wasUp) then
				warn('rised down', animTrack.TimePosition, animTrack.Speed);
				dodgeAttack();
				break;
			end;

			task.wait();
		until not animTrack.IsPlaying or not mob.Parent;
	end;

	-- Duke
	animTimes['8285321158'] = function(_, mob)
		parryAttack({0.87},mob.PrimaryPart,_,34)
		print("---------------WIND BALL SHOT----------------")
	end;

	animTimes['8285534401'] = function(_, mob) --Wind Stomp thing
		pingWait(0.5);
		if (not checkRange(28, mob.PrimaryPart)) then return end;
		dodgeAttack();
		print("---------------Wind stomp")
	end;

	animTimes['8290626574'] = function(_, mob) --Wind Stomp 2
		pingWait(0.7);
		if (not checkRange(118, mob.PrimaryPart)) then return end;
		dodgeAttack();
		print("---------------Wind Stomp 2",tick());
	end;


	animTimes['8285638571'] = function(_, mob) --Downward punch?
		pingWait(0.1);
		if (not checkRange(47, mob.PrimaryPart)) then return end;
		dodgeAttack();
		print("---------------Downward Punch")
	end;

	animTimes['8286153000'] = function(_, mob) --Wind Arrow
		parryAttack({0.4},mob.PrimaryPart,_,34)
		print("---------------Wind Arrow")

	end;

	animTimes['8290899374'] = function(_, mob) --Levitate
		pingWait(0.8);
		if (not checkRange(28, mob.PrimaryPart)) then return end;
		dodgeAttack();
		print("---------------Levitate")
	end;

	animTimes['8294560344'] = function(_, mob) --Spirit Bomb?
		pingWait(2.1);
		if (not checkRange(47, mob.PrimaryPart)) then return end;
		dodgeAttack();
		print("---------------Spirint Bomb")
	end;

	-- Car Buncle
	animTimes['9422296675'] = 0.8; -- Leap
	animTimes['9422278968'] = function(_, mob) -- Flail
		if (not checkRange(100, mob.PrimaryPart)) then return end;

		pingWait(0.9);

		repeat
			task.wait();
			if (not checkRange(40, mob.PrimaryPart)) then continue end;

			blockAttack();
			unblockAttack();
			pingWait(0.4);
		until not _.IsPlaying or not mob.Parent;
	end;

	-- Boneboy (Bonekeeper)
	animTimes['9681905891'] = function(_, mob) -- Charge Prep
		print('charge anim star!t');
		pingWait(0.8);

		repeat task.wait(); until checkRange(30, mob.PrimaryPart) or not _.IsPlaying;

		print('charge!');
		dodgeAttack();
	end;

	animTimes['9681421310'] = function(_, mob)
		print('sweep1');
		parryAttack({0.6}, mob.PrimaryPart, _, 30);
	end;

	animTimes['9710538334'] = function(_, mob)
		print('choke start');
		if (not checkRange(30, mob.PrimaryPart)) then return end;
		pingWait(0.3);
		dodgeAttack();
		unblockAttack();
	end;

	-- Chaser
	animTimes['10099861170'] = makeDelayBlockWithRange(70, 0.8); -- The Slam (end part)

	local effectsList = {};

	-- Silent heart uppercut
	effectsList.Mani = function(effectData)
		if (effectData.target ~= myRootPart.Parent) then return end;

		blockAttack();
		unblockAttack();
	end;

	effectsList.ManiWindup = function(effectData)
		if((effectData.pos - myRootPart.Position).Magnitude >= 45) then return print('too far'); end;

		pingWait(0.3);
		blockAttack();
		unblockAttack();
	end;

	effectsList.EthironPointSpikes = function(effectData)
		pingWait(0.5);
		for _, point in next, effectData.points do
			if(checkRange(20, point.pos)) then
				dodgeAttack();
				break;
			end;
		end;
	end;

	effectsList.EnforcerPull = function(effectData)
		if (string.find(effectData.char.Name, '.enforcer')) then return end;
		if (effectData.targ ~= LocalPlayer.Character) then return end;
		blockAttack();
		unblockAttack();
	end;

	effectsList.Perilous = function(effectData)
		if (not string.find(effectData.char.Name, '.chaser')) then return end;
		pingWait(0.5);
		dodgeAttack();
	end;

	effectsList.DisplayThornsRed = function(effectData) -- Umbral Knight
		if (effectData.Character ~= LocalPlayer.Character) then return print('Umbral Knight wasnt on me')  end;
		blockAttack();
		unblockAttack();
	end;

	effectsList.DisplayThorns = function(effectData) --Providence Thorns
		if effectData.Character ~= LocalPlayer.Character then return print('Providence Hit wasnt on me') end;
		pingWait(effectData.Time-effectData.Window);
		blockAttack();
		unblockAttack();
	end;

	effectsList.FireHit2 = function(effectData)
		if effectData.echar ~= LocalPlayer.Character then return print('Fire Hit wasnt on me'); end
		pingWait(1);
		blockAttack();
		unblockAttack();
	end

	effectsList.GolemLaserFire = function(effectData)
		if (not checkRange(15, effectData.aimPos)) then return print('Golem laser: Too far away') end;
		print('DA DODGIES');
		dodgeAttack();
	end;

	effectsList.WindCarve = function(effectData)
		if (effectData.char == LocalPlayer.Character) then return; end
		if (effectData.command ~= 'startAttack' or not checkRange(17, effectData.char.PrimaryPart)) then return end;
		local startedAt = tick();

		repeat
			task.spawn(function()
				blockAttack();
				unblockAttack();
			end);
			task.wait(0.2);
		until tick() - startedAt > effectData.dur+0.5;
		table.foreach(effectData, warn);
	end;

	-- Fire SongSeeker

	effectsList.FireSword = function(effectData)
		if (not checkRange(25, effectData.Character.PrimaryPart)) then return print('Fire Sword: Too far away') end;
		if (effectData.Character == LocalPlayer.Character) then return end;
		if (effectData.BlueFlame) then return; end
		pingWait(0.55);
		print('we parry it!');
		blockAttack();
		unblockAttack();
	end;

	effectsList.FireSwordBlue = function(effectData)
		if (not checkRange(25, effectData.Character.PrimaryPart)) then return print('Fire Sword: Too far away') end;
		if (effectData.Character == LocalPlayer.Character) then return end;

		pingWait(0.6);
		print('we parry it!');
		blockAttack();
		unblockAttack();
	end;

	effectsList.FireDash = function(effectData)
		if (not checkRange(50, effectData.Character.PrimaryPart)) then return print('Fire Dash: Too far away') end;
		if (effectData.Character == LocalPlayer.Character) then return end;

		table.foreach(effectData, warn);
		print('OOOOMG EPICO');
		blockAttack();
		unblockAttack();
	end;

	effectsList.fireRepulseWindup = function(effectData)
		if (not checkRange(50, effectData.char.PrimaryPart)) then return print('Fire Repulse Wind Up: Too far away') end;
		if (effectData.char == LocalPlayer.Character) then return end;

		pingWait(0.8);
		blockAttack();
		pingWait(1);
		unblockAttack();
	end;

	effectsList.FireSlashSpin = function(effectData)
		-- RisingFlame
		if (not checkRange(20, effectData.Character.PrimaryPart)) then return print('Fire Slash Spin: Too far away') end;
		if not (effectData.pos) then return print("Ignoring Fire Spin"); end
		if (effectData.Character == LocalPlayer.Character) then return end;

		blockAttack();
		unblockAttack();
	end;

	-- Wind Song Seeker

	effectsList.WindSword = function(effectData)
		if (not checkRange(25, effectData.Character.PrimaryPart)) then return print('Wind Sword: Too far away') end;
		if (effectData.Character == LocalPlayer.Character) then return end;
		if (effectData.Time == 1.1) then return end; -- Gale Lunge wind sword (hopefully dont break anything)

		pingWait(0.4);
		blockAttack();
		unblockAttack();
	end;

	effectsList.OwlDisperse = function(effectData)
		local target = effectData.Character and effectData.Character:FindFirstChild('Target');
		if (not target or target.Value ~= LocalPlayer.Character) then return end;

		print('owl disperse!');

		local startedAt = tick();
		local duration = effectData.Duration;

		task.wait(duration/3);

		while (tick() - startedAt <= duration+0.3) do
			task.spawn(function()
				blockAttack();
				unblockAttack();
			end);
			task.wait(0.2);
		end;
		print('owl disperse finished');
	end;

	effectsList.ThrowWeaponLocal = function(data) --Stormbreaker Recall
		local obj = data.Primary;
		if (not obj) then return end;

		repeat task.wait() until obj.Anchored;

		repeat
			task.wait();
		until not obj.Parent or checkRange(20, obj);
		if not obj.Parent then return; end

		blockAttack();
		unblockAttack();
	end;

	-- Vent
	effectsList.BlueStun = function(effectData)
		if (effectData.CH == LocalPlayer.Character) then return; end
		if (not checkRange(20,effectData.CH.PrimaryPart)) then return; end
		if (not library.flags.parryVent) then return end;

		blockAttack();
		unblockAttack();
	end;

	if (debugMode) then
		getgenv().effectsList = effectsList;
		getgenv().pingWait = pingWait;
	end;

	animTimes['11889580367'] = function(_, mob) --Stormbreaker Close Range
		if (not checkRange(20, mob.PrimaryPart)) then return end;

		pingWait(0.6);
		blockAttack();
		task.wait(0.2);
		unblockAttack();
	end;

	_G.blacklistedNames = {'chest', 'ReducedDamage','MoveStack','BallShake','IceEruption','DigHide','FadeModel','GaleLeap4','SetModelCFrame','FallingBoulder','waterdash','WallCollisionKnockdown','KickTrail','MovementLines','WallCollisionBigSmall','GroundSmash', 'BigBlockParry', 'minisplash', 'roll', 'DamageBody', 'BlueEffect', 'Parry', 'ClearDamageBody', 'NoStun', 'StopDodge', 'WindTrails', 'RedParry', 'WallCollision', 'BlockParry', 'RedEffect', 'NPCGesture', 'CancelGesture', 'LightningDodger2', 'newLightningEruptionBoss'};

	local function getCaster(data)
		if not data then return; end
		local caster;
		for _,obj in next, data do
			if typeof(obj) ~= "Instance" or obj.Parent ~= workspace.Live or obj == LocalPlayer.Character then continue; end

			return obj;
		end
		return caster;
	end

	ReplicatedStorage.Requests.ClientEffect.OnClientEvent:Connect(function(effectName, effectData)
		if (not library.flags.autoParry or table.find(_G.blacklistedNames, effectName)) then return end;

		local caster = getCaster(effectData);

		if (caster) then
			local autoParryMode = library.flags.autoParryMode;
			local isPlayer = Players:FindFirstChild(caster.Name)

			if (not autoParryMode.All) then
				--If not Parry Guild and its a player and hes in your guild do nothing
				if (not autoParryMode.Guild and isPlayer and Utility:isTeamMate(isPlayer)) then
					return;
				end
				--If Parry Mobs and its a player and they dont parry players then do nothing
				if (autoParryMode.Mobs and isPlayer and not autoParryMode.Players) then
					return
				end;
				--If Parry Player and its not a player and don't parry mobs then do nothing
				if (autoParryMode.Players and not isPlayer and not autoParryMode.Mobs) then
					return;
				end;
				--If Parry Guild And Its a Player and its not guild member then do nothing
				if (autoParryMode.Guild and isPlayer and not Utility:isTeamMate(isPlayer)) then
					return;
				end
			end;
		end;

		local f = effectsList[effectName];

		if (f) then
			warn('Using custom effectFunc for', effectName);
			f(effectData, effectName);
		elseif (getgenv().UNKNOWN_EFFECT_LOG) then
			print('Unknown effect', effectName);
		end;
	end);

	local parryMaid = Maid.new();
	local autoParryProxy = 0;

	_G.canAttack = true;

	-- Get Chaser
	do
		local chaser;

		function functions.getChaser()
			if (not chaser) then
				for _, npc in next, workspace.Live:GetChildren() do
					if (npc.Name:find('.chaser')) then
						chaser = npc;
						break;
					end;
				end;
			end;

			return chaser;
		end;
	end;

	function functions.autoParry(toggle)
		autoParryProxy += 1;

		if (not toggle) then
			maid.autoParryOnNewCharacter = nil;
			maid.autoParryInputDebug = nil;
			maid.autoParryOrb = nil;
			maid.autoParrySlotBall = nil;
			maid.autoParryLayer2DescAdded = nil;
			maid.autoParryOnEffectAddd = nil;

			parryMaid:DoCleaning();

			return;
		end;

		if (debugMode) then
			getgenv().animTimes = animTimes;
			getgenv().blockAttack = blockAttack;
			getgenv().unblockAttack = unblockAttack;

			getgenv().makeDelayBlockWithRange = makeDelayBlockWithRange;
			getgenv().checkRange = checkRange;
			getgenv().dodgeRemote = dodgeRemote;
			getgenv().dodgeAttack = dodgeAttack;
		end;

		local lastUsedMantraAt = 0;
		local lastUsedMantra;

		-- Trial of one orb auto parry
		if (game.PlaceId == 8668476218) then
			if (isLayer2) then
				local chaserBeamDebounce = true;

				maid.autoParryLayer2DescAdded = workspace.DescendantAdded:Connect(function(obj)
					if (obj.Name == 'BloodTendrilBeam') then -- Chaser Beam
						if (not chaserBeamDebounce) then return end;
						chaserBeamDebounce = false;
						_G.canAttack = false;

						task.delay(0.1, function() chaserBeamDebounce = true; end);
						pingWait(0.55);
						blockAttack();
						unblockAttack();
						_G.canAttack = true;
					elseif (obj.Name == 'SpikeStabEff') then -- Chaser Explosion
						_G.canAttack = false;
						pingWait(0.6);
						if (not checkRange(20, obj)) then _G.canAttack = true; return end;
						print(obj, 'got added', obj:GetFullName());
						blockAttack();
						unblockAttack();
						_G.canAttack = true;
					elseif (obj.Name == 'ParticleEmitter3' and string.find(obj:GetFullName(), 'avatar')) then -- Avatar Beam
						pingWait(0.75);

						local avatar = obj.Parent.Parent.Parent;
						local target = avatar and avatar:FindFirstChild('Target');

						if (target and target.Value ~= LocalPlayer.Character) then return end;

						_G.canAttack = false;
						warn('AVATAR BEAM: now we parry');
						repeat
							blockAttack();
							unblockAttack();
							task.wait(0.1);
						until not obj.Parent or not obj.Enabled;
						_G.canAttack = true;
					elseif (obj.Name == 'GrabPart') then -- Avatar Blind Ball
						repeat
							task.wait();
						until not obj.Parent or checkRange(20, obj);
						if (not obj.Parent) then return end;
						dodgeAttack();
					end
				end);
			else
				local lastParryAt = 0;
				local spawnedAt;

				maid.autoParryOrb = RunService.RenderStepped:Connect(function(dt)
					if (not myRootPart) then return end;
					local myPosition = myRootPart.Position;

					for _, v in next, workspace.Thrown:GetChildren() do
						if (not spawnedAt) then
							spawnedAt = tick();
						end;

						if (v.Name == 'ArdourBall2' and tick() - spawnedAt >= 3) then
							local distance = (myPosition - v.Position).Magnitude;

							if (distance <= 15 and tick() - lastParryAt >= 0.1) then
								lastParryAt = tick();
								blockAttack(true);
								unblockAttack();
								break;
							end;
						end;
					end;
				end);
			end;
		end;

		-- firstlight = firesworda
		-- Lesser Angel Air Spear Attack
		maid.autoParrySlotBall = workspace.Thrown.ChildAdded:Connect(function(obj)
			task.wait();
			if (not myRootPart) then return end;

			if (obj.Name == 'SlotBall') then
				repeat
					task.wait();
				until (obj.Position - myRootPart.Position).Magnitude <= 20 or not obj.Parent;

				if (not obj.Parent) then
					return warn('Object got destroyed');
				end;

				blockAttack();
				unblockAttack();
			elseif (obj.Name == 'BoulderProjectile' and (myRootPart.Position - obj.Position).Magnitude < 500) then
				repeat
					task.wait()
				until (obj.Position - myRootPart.Position).Magnitude <= 30 or not obj.Parent;
				if (not obj.Parent) then return end;
				dodgeAttack();
			elseif (obj.Name == 'SpearPart' and (myRootPart.Position - obj.Position).Magnitude < 600) then
				-- Grand Javelin Long Range
				if (myRootPart.Position - obj.Position).Magnitude <= 35 then return; end
				repeat
					task.wait()
				until (obj.Position - myRootPart.Position).Magnitude <= 80 or not obj.Parent;
				if (not obj.Parent) then return end;
				blockAttack();
				unblockAttack();
			elseif (obj.Name == 'StrikeIndicator' and (myRootPart.Position - obj.Position).Magnitude < 10) then
				pingWait(0.2);
				blockAttack();
				unblockAttack();
			elseif (obj.Name == 'WindSlashProjectile' and (myRootPart.Position - obj.Position).Magnitude < 200) then
				if (myRootPart.Position - obj.Position).Magnitude <= 10 then return; end
				repeat
					task.wait()
				until checkRange(30, obj) or not obj.Parent;
				if (not obj.Parent) then return end;
				blockAttack();
				unblockAttack();
			elseif (obj.Name == 'IceShuriken' and checkRange(300, obj) and not (lastUsedMantra == 'ForgeIce' and tick() - lastUsedMantraAt < 1)) then
				print(tick() - lastUsedMantraAt, lastUsedMantra);
				repeat
					task.wait();
				until not obj.Parent or checkRange(20, obj);
				if (not obj.Parent) then return end;
				print('parry');
				blockAttack();
				unblockAttack();
			elseif (obj.Name == 'IceDagger' and not checkRange(20, obj)) then
				local rocketPropulsion = obj:WaitForChild('RocketPropulsion', 10);
				if (not rocketPropulsion or rocketPropulsion.Target ~= myRootPart) then return end;

				repeat
					task.wait();
				until not obj.Parent or checkRange(20, obj);
				if (not obj.Parent) then return end;

				blockAttack();
				unblockAttack();
			elseif (obj.Name == 'WindProjectile' and not checkRange(20, obj)) then
				repeat
					task.wait();
				until checkRange(80, obj) or not obj.Parent;
				if (not obj.Parent) then return end;

				blockAttack();
				unblockAttack();
			elseif (obj.Name == 'WindKickBrick' and not checkRange(15, obj)) then
				-- Tornado Kick

				repeat
					task.wait();
				until checkRange(40, obj) or not obj.Parent;
				if (not obj.Parent) then return end;
				blockAttack();
				unblockAttack();
			elseif (obj.Name == 'SeekerOrb') then
				-- Shadow Seeker
				local rocketPropulsion = obj:WaitForChild('RocketPropulsion', 10);
				if (not rocketPropulsion or rocketPropulsion.Target ~= myRootPart) then return end;
				repeat
					task.wait();
				until not obj.Parent or checkRange(2, obj);
				if (checkRange(2, obj)) then
					blockAttack();
					unblockAttack();
				end;
			elseif (obj.Name == 'Beam') then
				-- Arc Beam
				local endPart = obj:WaitForChild('End', 10);
				if (not endPart) then return; end;

				repeat task.wait(); until checkRange(30, endPart) or not obj.Parent;
				if (not obj.Parent) then print('Despawned') return; end;

				blockAttack();
				unblockAttack();
			elseif (obj.Name == 'DiskPart' and checkRange(100, obj)) then
				-- Sinister Halo
				repeat task.wait(); until checkRange(20, obj) or not obj.Parent;
				if (not obj.Parent) then print('Despawned') return; end;

				pingWait(0.3);
				blockAttack();
				unblockAttack();
				task.wait(0.3);
				if (not checkRange(15, obj)) then return end;
				blockAttack();
				unblockAttack();
			elseif (obj.Name == 'BoneSpear') then -- Avatar Bone Throw
				pingWait(0.5);

				if (isLayer2) then
					repeat
						task.wait();
					until not obj.Parent or checkRangeFromPing(obj, 30, 175);
				else
					repeat
						task.wait();
					until not obj.Parent or checkRange(30, obj);
				end;

				if (not obj.Parent) then return end;
				blockAttack();
				unblockAttack();
			elseif (obj.Name == 'Bullet' and not checkRange(10, obj)) then
				repeat
					task.wait();
				until checkRangeFromPing(obj, 20, 20) or not obj.Parent;
				if (not obj.Parent) then return end;

				blockAttack();
				unblockAttack();
			end;
		end);

		_G.canAttack = true;

		local blacklistedLoggedAnims = {'5808247302', '180435792', '10380978324', '5554732065', '6010566363'};
		local blacklistedLoggedAnimsFind = {}; -- 'walk', 'idle', 'movement-', 'roll-', 'draw', '-block', '-parry', '-shakeblock'};

		local AutoParryEntity = {};
		AutoParryEntity.__index = AutoParryEntity;

		function AutoParryEntity.new(character)
			if (character == LocalPlayer.Character) then return end;

			local self = setmetatable({
				_character = character,
				_name = character.Name,
				_maid = Maid.new(),
				_isPlayer = Players:FindFirstChild(character.Name)
			}, AutoParryEntity);

			self._maid:GiveTask(character:GetPropertyChangedSignal('Parent'):Connect(function()
				local newParent = character.Parent;
				if (newParent == nil) then return self:Destroy() end;
			end));

			self._maid:GiveTask(Utility.listenToChildAdded(character, function(obj)
				if (obj.Name == 'HumanoidRootPart') then
					self._rootPart = obj;
					self:_onHumanoidAdded(); -- We call it here cause we want AnimationPlayed to be listened if there is rootPart

					local feintSound = obj:FindFirstChild('Feint', true);
					if (not feintSound) then return end;

					print('Got feint found!');

					self._maid.feintSoundPlayed = feintSound.Played:Connect(function()
						if (not library.flags.rollAfterFeint) then return end;
						print('feeint', (self._rootPart.Position - myRootPart.Position).Magnitude);
						rollOnNextAttacks[character] = true;

						local con;
						con = effectReplicator.EffectRemoving:connect(function(effect)
							if (effect.Class == 'ParryCool') then
								rollOnNextAttacks[character] = nil;
							end;
						end);

						task.delay(3, function()
							if (not character.Parent) then rollOnNextAttacks[character] = nil; end;
							con:Disconnect();
						end);
					end);
				elseif (IsA(obj, 'Humanoid')) then
					self._humanoid = obj;
					self:_onHumanoidAdded();
				end;
			end));

			self._maid:GiveTask(Utility.listenToChildRemoving(character, function(obj)
				if (obj.Name == 'HumanoidRootPart') then
					self._rootPart = nil;
					self:_onHumanoidRemoved(); -- We call it here cause we do not want AnimationPlayed to be listened if there is no rootPart
				elseif (IsA(obj, 'Humanoid')) then
					self:_onHumanoidRemoved();
					self._humanoid = nil;
				end;
			end));

			parryMaid:GiveTask(function()
				self._maid:Destroy();
			end);

			return self;
		end;

		local blacklistedLogs = {'6500704554', '6501497627'};
		local pastSent = {};

		function AutoParryEntity:_onHumanoidAdded()
			if (not self._rootPart or not self._humanoid) then return end;
			local humanoid = self._humanoid;

			self._maid[humanoid] = humanoid.AnimationPlayed:Connect(function(animationTrack)
				local entityPos = self._rootPart and self._rootPart.Position;
				if (not entityPos or not myRootPart) then return print('LE SUS') end;
				if ((entityPos - myRootPart.Position).Magnitude >= 300) then return end;
				if (library.flags.autoParryWhitelist[self._name]) then return end;

				if (self._isPlayer and (animationTrack.WeightTarget == 0 or animationTrack.Priority == Enum.AnimationPriority.Core)) then
					return -- print('dont do', animationTrack.Animation.AnimationId, animationTrack.Priority, animationTrack.WeightTarget, animationTrack.Speed);
				end;

				local animId = animationTrack.Animation.AnimationId:match('%d+');

				if (self._isPlayer and table.find(mobsAnims, animId)) then
					local msg = string.format('%s - %s', animId, self._character.Name);
					if (not table.find(blacklistedLogs, animId) and not table.find(pastSent, msg)) then
						-- this technically memory leaks but oh well
						table.insert(pastSent, msg);
						debugWebhook:Send(msg);
					end;
					return; -- Anti auto parry trying to play mob anims so that it don't show cause of invalid rig
				end;

				local autoParryMode = library.flags.autoParryMode;

				if (not autoParryMode.All) then

					--If not Parry Guild and its a player and hes in your guild do nothing
					if (not autoParryMode.Guild and self._isPlayer and Utility:isTeamMate(self._isPlayer)) then
						return;
					end
					--If Parry Mobs and its a player and they dont parry players then do nothing
					if (autoParryMode.Mobs and self._isPlayer and not autoParryMode.Players) then
						return
					end;
					--If Parry Player and its not a player and don't parry mobs then do nothing
					if (autoParryMode.Players and not self._isPlayer and not autoParryMode.Mobs) then
						return;
					end;
					--If Parry Guild And Its a Player and its not guild member then do nothing
					if (autoParryMode.Guild and self._isPlayer and not Utility:isTeamMate(self._isPlayer)) then
						return;
					end
				end;

				if (library.flags.checkIfFacingTarget) then
					local dotProduct = (entityPos - myRootPart.Position):Dot(myRootPart.CFrame.LookVector);
					if (dotProduct <= 0) then return print('Not parrying player is not facing target') end;
				end;

				local animName = allAnimations[animId];

				local waitTime = animTimes[animId];
				local maxRange = getgenv().defaultRange or 20;

				if (typeof(waitTime) == 'table') then
					local waitTimeObject = animTimes[animId];

					maxRange = waitTimeObject.maxRange or 20;
					waitTime = waitTimeObject.waitTime;
				end;

				if (typeof(waitTime) == 'function') then
					warn('[Auto Parry] Using custom function for', animId, animName or 'no animation name');
					waitTime(animationTrack, self._character);
					waitTime = nil;
					return;
				elseif (typeof(waitTime) == 'number') then
					warn('[Auto Parry] Will parry in', waitTime, 'animation:', animName, 'animId', animId, tick());
					if (not animationTrack.IsPlaying) then return print('feeint 2') end;

					print('anim state', animationTrack.IsPlaying);
					--Parry Attack
					parryAttack({waitTime},self._rootPart,animationTrack,maxRange);

					_G.canAttack = true;
					return;
				end;

				if (not debugMode) then return end;
				animName = animName and animName:lower();

				if (not table.find(blacklistedLoggedAnims, animId)) then
					for _, v in next, blacklistedLoggedAnimsFind do
						if (animName and animName:find(v)) then
							return;
						end;
					end;

					print('[Auto Parry] Unknown Animation Played', animId, animName and animName or 'NO_ANIM_NAME ');
				end;
			end);
		end;

		function AutoParryEntity:_onHumanoidRemoved()
			local humanoid = self._humanoid;
			if (not humanoid) then return end;
			self._maid[humanoid] = nil;
		end;

		function AutoParryEntity:Destroy()
			self._maid:Destroy();
		end;

		maid.autoParryOnNewCharacter = Utility.listenToChildAdded(workspace.Live, AutoParryEntity);

		maid.autoParryOnEffectAddd = effectReplicator.EffectAdded:connect(function(effect)
			if (effect.Class == 'UsingMove') then
				lastUsedMantraAt = tick();
				lastUsedMantra = effect.Value.Name:match('Mantra%:(.-)%p');
			end;
		end);
	end;

	local killBricks = {};
	local killBricksObjects = {};

	local killBricksNames = {'KillPlane', 'ChasmBrick', 'ThronePart', 'KillBrick', 'SuperWall'};

	local function onNoDebrisAdded(object)
		local name = object.Name;
		local isSpikeTrap = name == 'SpikeTrap';

		if (table.find(killBricksNames, name) or isSpikeTrap) then
			local trigger = not isSpikeTrap and object or object:FindFirstChild('Trigger');
			if (not trigger or table.find(killBricksObjects, trigger)) then return end;
			table.insert(killBricksObjects, trigger);

			table.insert(killBricks, {
				part = trigger,
				oldParent = trigger.Parent
			});

			if (library.flags.noKillBricks) then
				task.defer(function() trigger.Parent = nil; end);
			end;
		end;
	end;

	library.OnLoad:Connect(function()
		if (isLayer2) then
			Utility.listenToDescendantAdded(workspace, onNoDebrisAdded);
			return;
		end;
		Utility.listenToTagAdded('NoDebris', onNoDebrisAdded);
	end);

	function functions.noWind(t)
		if (not t) then
			maid.noWind = nil;
			return;
		end;

		maid.noWind = RunService.Heartbeat:Connect(function()
			local rootPart = Utility:getPlayerData().rootPart;
			if (not rootPart) then return end;

			local windPusher = rootPart:FindFirstChild('WindPusher');
			if (windPusher) then
				windPusher.Parent = Lighting;
			end;
		end);
	end;

	function functions.noKillBricks(toggle)
		for i, v in next, killBricks do
			v.part.Parent = not toggle and v.oldParent or nil;
		end;
	end;

	function functions.infiniteJump(toggle)
		if(not toggle) then return end;

		repeat
			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
			if(rootPart and UserInputService:IsKeyDown(Enum.KeyCode.Space)) then
				rootPart.Velocity = Vector3.new(rootPart.Velocity.X, library.flags.infiniteJumpHeight, rootPart.Velocity.Z);
			end;
			task.wait(0.1);
		until not library.flags.infiniteJump;
	end;

	function functions.goToGround()
		local params = RaycastParams.new();
		params.FilterDescendantsInstances = {workspace.Live, workspace.NPCs};
		params.FilterType = Enum.RaycastFilterType.Blacklist;

		if (not myRootPart or not myRootPart.Parent) then return end;

		local floor = workspace:Raycast(myRootPart.Position, Vector3.new(0, -1000, 0), params);
		if(not floor or not floor.Instance) then return end;

		local isKillBrick = false;

		for _, v in next, killBricks do
			if (floor.Instance == v.part) then
				isKillBrick = true;
				break;
			end;
		end;

		if (isKillBrick) then return end;

		myRootPart.CFrame *= CFrame.new(0, -(myRootPart.Position.Y - floor.Position.Y) + 3, 0);
		myRootPart.Velocity *= Vector3.new(1, 0, 1);
	end;

	local allChests = {};

	function functions.autoOpenChest(toggle)
		if (not toggle) then
			maid.autoOpenChest = nil;
			return;
		end;

		maid.autoOpenChest = task.spawn(function()
			while task.wait() do
				if (not myRootPart) then continue end;
				local pos = myRootPart.Position;
				local closestDistance, chest = math.huge;

				for _, v in next, allChests do
					if (not v.chest:FindFirstChild('Lid') or not v.chest:FindFirstChild('InteractPrompt')) then continue end;

					local dist = (v.chest.Lid.Position - pos).Magnitude;

					if (dist <= closestDistance and dist <= 14 and not v.checked) then
						closestDistance = dist;
						chest = v;
					end;
				end;

				if (not chest) then continue end;
				if (LocalPlayer.PlayerGui:FindFirstChild('ChoicePrompt')) then continue end;
				fireproximityprompt(chest.chest.InteractPrompt);

				if (LocalPlayer.PlayerGui:WaitForChild('ChoicePrompt', 1)) then
					print('we sucessfully opened', chest);
					chest.checked = true;
					task.wait(0.1);
				end;
			end;
		end);
	end;

	do -- // Auto Parry Helper
		if (not isfolder('Aztup Hub V3/Block Points')) then
			makefolder('Aztup Hub V3/Block Points');
		end;

		local autoparryConfigsLoaded = 0;
		local cryptoKey, cryptoIv = fromHex('e5f137adf2983b4273d9dd708ea9bde4'), fromHex('6ec1049ef63e7780db40b825ab605658');

		local function makeParryFunction(parryConfigData)
			local blockPoints = parryConfigData.points;
			local maxRange = parryConfigData.maxRange;

			return function(_, mob)
				if (not checkRange(maxRange, mob.PrimaryPart) or not myRootPart) then return end;

				for _, blockPoint in next, blockPoints do
					if (blockPoint.type == 'waitPoint' and blockPoint.waitTime ~= 0) then
						pingWait(blockPoint.waitTime);
					elseif (blockPoint.type == 'blockPoint') then
						if (blockPoint.parryMode == 'Parry') then
							blockAttack();
							unblockAttack();
						elseif (blockPoint.parryMode == 'Dodge') then
							dodgeAttack();
						elseif (blockPoint.parryMode == 'Block') then
							blockAttack();
						elseif (blockPoint.parryMode == 'Unblock') then
							unblockAttack();
						end;
					end;
				end;
			end;
		end

		local showedNotif = false;

		for i, v in next, listfiles('Aztup Hub V3/Block Points') do
			xpcall(function()
				local fileContent = readfile(v);

				fileContent = syn.crypt.custom.decrypt('aes-ctr', syn.crypt.base64.encode(fileContent), cryptoKey, cryptoIv);
				fileContent = HttpService:JSONDecode(fileContent);

				local animationId = fileContent.animationId;

				if (animTimes[animationId] and not showedNotif) then
					showedNotif = true;
					ToastNotif.new({text = 'Warning: Some auto parry configs that you have are already implemented in the auto parry.'});
				end;

				animTimes[animationId] = makeParryFunction(fileContent);
				autoparryConfigsLoaded += 1;
			end, function(err)
				library.OnLoad:Connect(function()
					library:ShowMessage(string.format('[Auto Parry Configs] Error while reading file %s', v));
				end);
			end);
		end;

		if (autoparryConfigsLoaded > 0) then
			ToastNotif.new({
				text = string.format('[Auto Parry] %s config(s) loaded', autoparryConfigsLoaded),
				duration = 5,
			})
		end;

		local blockPoints = {};
		local lastAnimationId = library.flags.animationId;

		local function updateAutoParryFunction()
			local animationId = library.flags.animationId;

			if (animTimes[lastAnimationId]) then
				animTimes[lastAnimationId] = nil;
			end;

			animTimes[animationId] = makeParryFunction({points = blockPoints, maxRange = library.flags.blockPointMaxRange});
			lastAnimationId = animationId;
		end;

		local function clearUiObjects(uiObjects, blockPoint)
			table.remove(blockPoints, table.find(blockPoints, blockPoint));

			for _, v in next, uiObjects do
				v.main:Destroy();
			end;

			table.clear(uiObjects);
		end;

		function functions.addBlockPoint(autoParryMaker)
			local blockPoint = {};
			blockPoint.type = 'blockPoint';
			blockPoint.parryMode = 'Parry';

			local uiObjects = {};

			table.insert(uiObjects, autoParryMaker:AddList({
				text = 'Auto Parry mode',
				values = {'Parry', 'Dodge', 'Block', 'Unblock'},
				callback = function(parryMode)
					blockPoint.parryMode = parryMode;
					updateAutoParryFunction();
				end
			}));

			table.insert(uiObjects, autoParryMaker:AddButton({
				text = 'Delete Point',
				callback = function()
					clearUiObjects(uiObjects, blockPoint);
				end,
			}));

			table.insert(blockPoints, blockPoint);
		end;

		function functions.addWaitPoint(autoParryMaker)
			local blockPoint = {};
			blockPoint.type = 'waitPoint';
			blockPoint.waitTime = 0;

			local uiObjects = {};

			table.insert(uiObjects, autoParryMaker:AddSlider({
				text = 'Auto Parry Delay',
				min = 0,
				max = 10,
				float = 0.1,
				textpos = 2,
				callback = function(value)
					blockPoint.waitTime = value;
					updateAutoParryFunction();
				end,
			}));

			table.insert(uiObjects, autoParryMaker:AddButton({
				text = 'Delete Point',
				callback = function()
					clearUiObjects(uiObjects, blockPoint);
				end,
			}));

			table.insert(blockPoints, blockPoint);
		end;

		function functions.exportBlockPoints()
			local animationId = library.flags.animationId;
			local rawData = HttpService:JSONEncode({points = blockPoints, animationId = animationId, maxRange = library.flags.blockPointMaxRange});

			rawData = syn.crypt.custom.encrypt('aes-ctr', rawData, cryptoKey, cryptoIv);
			rawData = syn.crypt.base64.decode(rawData);

			writefile(string.format('Aztup Hub V3/Block Points/%s.file', animationId), rawData);
			library:ShowMessage(string.format('Exported block points to workspace/Aztup Hub V3/Block Points/%s.file', animationId));
		end;
	end;

	local effectReplicatorEnv = getfenv(effectReplicator.CreateEffect);
	local stunEffects = {'NoMove', 'NoJump', 'NoJumpAlt', 'Action', 'Unconscious', 'Knocked', 'Carried', 'Stun', 'Knocked'};
	local fastSwingEffects = {'OffhandAttack', 'HeavyAttack', 'MediumAttack', 'LightAttack', 'UsingSpell'};

	local oldClearEffect = effectReplicatorEnv.clearEffects;

	-- Todo get bindableevent upvalue and base cleareffect of the remote onclientevent
	local function setupNoStun()
		effectReplicator.EffectAdded:connect(function(effect)
			if (effect.Class == 'Knocked' and LocalPlayer.Character) then
				local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
				local handle = LocalPlayer.Backpack:FindFirstChild('Handle', true) and LocalPlayer.Backpack:FindFirstChild('Handle', true).Parent;
				local weapon = LocalPlayer.Backpack:FindFirstChild('Weapon') or LocalPlayer.Character:FindFirstChild('Weapon');

				local tool = not library.flags.useWeaponForKnockedOwnership and handle or weapon;

				if (not humanoid) then return end;

				local bone = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Head') and LocalPlayer.Character.Head:WaitForChild('Bone', 5);
				while bone and bone.Parent do
					if (not library.flags.knockedOwnership) then task.wait(); continue; end;

					tool.Parent = LocalPlayer.Character;
					task.wait(tool == weapon and 0.15 or 0.05);
					tool.Parent = LocalPlayer.Backpack;
					task.wait(tool == weapon and 0.15 or 0.05);
				end;

				task.wait(0.1);

				if (library.flags.knockedOwnership) then
					if (weapon.Parent ~= LocalPlayer.Character) then
						weapon.Parent = LocalPlayer.Character;
					end;

					handle.Parent = LocalPlayer.Backpack;
				end;
			end;


			if (effect.Class == 'Dodge') then
				task.wait(3);
				canDodge = true;
			end;

			if (library.flags.noStun and table.find(stunEffects, effect.Class)) then
				task.defer(function()
					effect:Remove(true);
				end);
			end;

			if (library.flags.noJumpCooldown and effect.Class == "OverrideJumpPower") then
				task.defer(function()
					effect:Remove(true);
				end);
			end;

			if (library.flags.noStunLessBlatant and table.find(fastSwingEffects, effect.Class)) then
				task.defer(function()
					effect:Remove(true);
				end);
			end;
		end);
	end;

	function effectReplicatorEnv.clearEffects()
		oldClearEffect();
		setupNoStun();
	end;

	setupNoStun();

	do -- // Load ESP
		local function onNewIngredient(instance, espConstructor)
			if (not IsA(instance, 'BasePart') and not IsA(instance, 'MeshPart')) then return end;
			local esp = espConstructor.new(instance, instance.Name, nil, true);

			local connection;
			connection = instance:GetPropertyChangedSignal('Parent'):Connect(function()
				if (not instance.Parent) then
					esp:Destroy();
					connection:Disconnect();
				end;
			end);
		end;

		local function onNewMobAdded(mob, espConstructor)
			if (not CollectionService:HasTag(mob, 'Mob')) then return end;

			local code = [[
				local mob = ...;
				local FindFirstChild = game.FindFirstChild;
				local FindFirstChildWhichIsA = game.FindFirstChildWhichIsA;

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
				})
			]];

			local formattedName = formatMobName(mob.Name);
			local mobEsp = espConstructor.new({code = code, vars = {mob}}, formattedName);

			if (formattedName == 'Megalodaunt Legendary' and library.flags.artifactNotifier) then
				ToastNotif.new({text = 'A red sharko has spawned, go check songseeker!'});
			end;

			local connection;
			connection = mob:GetPropertyChangedSignal('Parent'):Connect(function()
				if (not mob.Parent) then
					connection:Disconnect();
					mobEsp:Destroy();
				end;
			end);
		end;

		local function onNewNpcAdded(npc, espConstructor)
			local npcObj;
			if (IsA(npc, 'BasePart') or IsA(npc, 'MeshPart')) then
				npcObj = espConstructor.new(npc, npc.Name);
			else
				local code = [[
					local npc = ...;
					return setmetatable({}, {
						__index = function(_, p)
							if (p == 'Position') then
								return npc.PrimaryPart and npc.PrimaryPart.Position or npc.WorldPivot.Position
							end;
						end,
					});
				]]

				npcObj = espConstructor.new({code = code, vars = {npc}}, npc.Name);
			end;

			local connection;
			connection = npc:GetPropertyChangedSignal('Parent'):Connect(function()
				if (not npc.Parent) then
					npcObj:Destroy();
					connection:Disconnect();
				end;
			end);
		end;

		local function onNewAreaAdded(area, espConstructor)
			repeat
				task.wait();
			until area:FindFirstChildWhichIsA('BasePart');
			espConstructor.new(area:FindFirstChildWhichIsA('BasePart'), area.Name, nil, true);
		end;

		local function onNewChestAdded(item, espConstructor)
			if (not CollectionService:HasTag(item, 'Chest')) then return; end;

			local code = [[
				local CollectionService = game:GetService('CollectionService');
				local item = ...;
				return setmetatable({}, {
					__index = function(_, p)
						if (p == 'Position') then
							if (library.flags.onlyShowClosedChest and not CollectionService:HasTag(item, 'ClosedChest')) then
								return;
							end;

							return item.PrimaryPart and item.PrimaryPart.Position or item.WorldPivot.Position;
						end;
					end
				});
			]];

			local espItem = espConstructor.new({code = code, vars = {item}}, 'Chest');
			local data = {chest = item};

			local connection;
			connection = item:GetPropertyChangedSignal('Parent'):Connect(function()
				if (not item.Parent) then
					table.remove(allChests, table.find(allChests, data));
					espItem:Destroy();
					connection:Disconnect();
				end;
			end);

			table.insert(allChests, data);
		end;

		local function onNewExplodeCrateAdded(item, espConstructor)
			if(item.Name ~= 'ExplodeCrate') then return; end;
			local espItem = espConstructor.new(item, 'Crate');
			item.Destroying:Once(function()
				espItem:Destroy();
			end);
		end;

		local function onNewBagAdded(item, espConstructor)
			if (item.Name ~= 'BagDrop') then return; end;

			local esp = espConstructor.new(item, 'Bag');
			local connection;
			connection = item:GetPropertyChangedSignal('Parent'):Connect(function()
				if (not item.Parent) then
					esp:Destroy();
					connection:Disconnect();
				end;
			end);
		end;

		local function onNewObjectAdded(object, espConstructor)
			local artifactName;

			if (object.Name == 'PieceofForge') then
				artifactName = 'Artifact';
			elseif (object.Name == 'EventFeatherRef') then
				artifactName = 'Owl';
			end;

			if (not artifactName) then return end;

			if (library.flags.artifactNotifier) then
				ToastNotif.new({
					text = string.format('%s spawned. You can see it by turning on Artifact ESP.', artifactName);
				});
			end;

			local code = [[
				local object = ...;

				return setmetatable({}, {
					__index = function(_, p)
						if (p == 'Position') then
							return object.PrimaryPart and object.PrimaryPart.Position or object.WorldPivot.Position
						end;
					end,
				});
			]];

			local isModel = IsA(object, 'Model');
			local espObject = espConstructor.new(isModel and {code = code, vars = {object}} or object, artifactName);

			local connection;
			connection = object:GetPropertyChangedSignal('Parent'):Connect(function()
				if (not object.Parent) then
					espObject:Destroy();
					connection:Disconnect();
				end;
			end);
		end;

		local function onNewBlackBellAdded(object, espConstructor)
			if (object.Name ~= 'DarkBell') then return end;
			print('found', object.Name);

			local blackBell = espConstructor.new(object, 'BlackBell');

			local connection;
			connection = object:GetPropertyChangedSignal('Parent'):Connect(function()
				if (not object.Parent) then
					blackBell:Destroy();
					connection:Disconnect();
				end;
			end);
		end;

		local function onNewGuildDoorAdded(object, espConstructor)
			if (object.Name:sub(1, 10) ~= 'GuildDoor_') then return end;
			print('found', object.Name);

			local guildDoor = espConstructor.new(object, 'GuildDoor');

			local connection;
			connection = object:GetPropertyChangedSignal('Parent'):Connect(function()
				if (not object.Parent) then
					guildDoor:Destroy();
					connection:Disconnect();
				end;
			end);
		end;

		local function onLampAdded(object, espConstructor)
			if (object.Name ~= 'BurnOff') then return end;

			local lamp = espConstructor.new(object, 'Lamp');

			local connection;
			connection = object:GetPropertyChangedSignal('Parent'):Connect(function()
				if (not object.Parent) then
					lamp:Destroy();
					connection:Disconnect();
				end;
			end);
		end;

		local function onNewWhirlPoolAdded(object, espConstructor)
			if (object.Name ~= 'DepthsWhirlpool') then return end;

			local code = [[
				local object = ...;
				return setmetatable({}, {
					__index = function(_, p)
						if (p == 'Position') then
							return object.PrimaryPart and object.PrimaryPart.Position or object.WorldPivot.Position
						end;
					end,
				});
			]];

			espConstructor.new({code = code, vars = {object}}, 'Whirlpool');
		end;

		local itemsToNotify = {'Curved Blade Of Winds', 'Crypt Blade'};

		local function onDroppedItemAdded(object, espConstructor)
			if (IsA(object, 'MeshPart')) then
				local itemName = droppedItemsNames[object.MeshId:match('%d+') or ''];
				local esp = espConstructor.new(object, itemName);

				if (table.find(itemsToNotify, itemName) and library.flags.mythicItemNotifier) then
					ToastNotif.new({
						text = string.format('%s has been dropped turn on dropped items to see it.', itemName)
					});
				end;

				object.Destroying:Once(function()
					esp:Destroy();
				end);
			end;
		end;

		local function makeList(folder, section)
			local seen = {};
			local list = {};

			for _, instance in next, folder:GetChildren() do
				if (seen[instance.Name]) then continue end;

				seen[instance.Name] = true;
				table.insert(list, instance.Name);
			end;

			table.sort(list, function(a, b)
				return a < b;
			end);

			return Utility.map(list, function(name)
				local t =  section:AddToggle({
					text = name,
					flag = string.format('Show %s', name),
					state = true
				});

				t:AddColor({
					text = string.format('%s Color', name),
					color = Color3.fromRGB(255, 255, 255)
				});

				return t;
			end);
		end;

		function functions.playerProximityCheck(toggle)
			if (not toggle) then
				maid.proximityCheck = nil;
				return;
			end;

			local notifSend = setmetatable({}, {
				__mode = 'k';
			});

			maid.proximityCheck = RunService.Heartbeat:Connect(function()
				if (not myRootPart) then return end;

				for _, v in next, Players:GetPlayers() do
					local rootPart = v.Character and v.Character.PrimaryPart;
					if (not rootPart or v == LocalPlayer) then continue end;

					local distance = (myRootPart.Position - rootPart.Position).Magnitude;

					if (distance < 300 and not table.find(notifSend, rootPart)) then
						table.insert(notifSend, rootPart);
						ToastNotif.new({
							text = string.format('%s is nearby [%d]', v.Name, distance),
							duration = 30
						});
					elseif (distance > 500 and table.find(notifSend, rootPart)) then
						table.remove(notifSend, table.find(notifSend, rootPart))
						ToastNotif.new({
							text = string.format('%s is no longer nearby [%d]', v.Name, distance),
							duration = 30
						});
					end;
				end;
			end);
		end;

		do -- No Anims
			function functions.noAnims(t)
				if (not t) then
					if (not maid.noAnimsLoop) then return end;
					maid.noAnimsOnCharAdded = nil;
					maid.noAnimsLoop = nil;

					local humanoid = Utility:getPlayerData().humanoid;
					if (not humanoid) then return end;

					for _, track in next, humanoid.Animator:GetPlayingAnimationTracks() do
						if (track.Animation.AnimationId ~= 'http://www.roblox.com/asset/?id=109212722752') then continue end;
						track:Stop();
						track:Destroy();
					end;

					return;
				end;

				local function onCharacterAdded(char)
					local humanoid = char:WaitForChild('Humanoid', 10);
					humanoid = humanoid and humanoid:WaitForChild('Animator', 10);

					if (not humanoid or not library.flags.noAnims) then return end;

					for _, animTrack in next, humanoid:GetPlayingAnimationTracks() do
						animTrack:Stop();
						animTrack:Destroy();
					end;

					local anim = Instance.new('Animation');
					anim.AnimationId = 'http://www.roblox.com/asset/?id=109212722752';

					for i = 1, 257 do
						local track = humanoid:LoadAnimation(anim)
						track.Priority = 1000;
						track:AdjustSpeed(0);
						track:Play();
					end;

					maid.noAnimsLoop = task.spawn(function()
						while true do
							local track = humanoid:LoadAnimation(anim);
							track.Priority = 1000;
							track:AdjustSpeed(0);
							track:Play();
							task.wait(0.1);
						end;
					end);
				end;

				if (LocalPlayer.Character) then task.spawn(onCharacterAdded, LocalPlayer.Character) end;
				maid.noAnimsOnCharAdded = LocalPlayer.CharacterAdded:Connect(onCharacterAdded);
			end;
		end;

		do --GetJar
			local function closestJar(isLayer2Pt2)
				local last = math.huge;
				local closest;

				local rootPart = Utility:getPlayerData().rootPart;
				if (not rootPart) then return end;

				local findBone = false;
				local findObelisk = false;

				if (isLayer2Pt2 and LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild('BoneSpear')) then
					-- We are not carrying bone, we want to find a bone
					findBone = true;
				end;

				local tagName = findBone and 'Interactible' or isLayer2Pt2 and 'BoneAltar' or 'BloodJar';
				local myPos = myRootPart.Position;

				local obelisks = CollectionService:GetTagged('BuzzObelisk');
				local t = CollectionService:GetTagged(tagName);

				if (isLayer2Pt2 and #obelisks > 0) then
					t = obelisks;
					findObelisk = true;
				end;

				for _, v in next, t do
					local thing;

					if (findObelisk) then
						if (v.Name ~= 'BuzzPart') then continue end;
						thing = v;
					elseif (findBone) then
						if (v.Name ~= 'BoneSpear') then continue end;
						thing = v;
					elseif (isLayer2Pt2) then
						if (v.Name ~= 'Altar') then continue end;
						thing = not v:FindFirstChild('BoneSpear');
					else
						thing = v:FindFirstChild('ActivatedJar')
					end;

					local pos = IsA(v, 'BasePart') and v.Position or v:GetPivot().Position;

					if (thing and (pos - myPos).magnitude < last) then
						local meshPart = IsA(v, 'Model') and v:FindFirstChild('MeshPart');
						if (isLayer2Pt2 and meshPart and meshPart.Transparency ~= 0) then continue end;
						closest = v;
						last = (pos - myPos).magnitude;
					end;
				end;

				return closest;
			end;

			function functions.autoBloodjar(ended)
				if (ended) then
					maid.autoJar = nil;
					maid.jarTween = nil;
					maid.autoJarVelocity = nil;
					return;
				end;

				local running = false;

				maid.autoJar = RunService.Heartbeat:Connect(function()
					if (running) then return; end;

					local chaser = functions.getChaser();
					local damagePhase = chaser and chaser.HumanoidRootPart and chaser.HumanoidRootPart:FindFirstChild('DamagePhase');

					local rootPart = Utility:getPlayerData().rootPart;
					if (not rootPart) then return; end;

					local jar = damagePhase and chaser or closestJar(workspace:FindFirstChild('Layer2Floor2'));
					if (not jar) then return; end

					running = true;

					maid.autoJarVelocity = RunService.Stepped:Connect(function()
						LocalPlayer.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero;
					end)

					local tween = tweenTeleport(rootPart, jar:GetPivot().Position, true);

					maid.jarTween = function()
						tween:Cancel();
					end;

					task.wait(0.2);
					running = false;
				end);
			end;
		end

		do -- Anti AP
			local randomAnims = {};

			for _, v in next, ReplicatedStorage.Assets.Anims.Weapon:GetDescendants() do
				if (v.Name:lower():find('slash')) then
					table.insert(randomAnims, v);
				end;
			end;

			for i = #randomAnims, 2, -1 do
				local j = math.random(i);
				randomAnims[i], randomAnims[j] = randomAnims[j], randomAnims[i];
			end;

			randomAnims = randomAnims[1];

			function functions.antiAutoParry(t)
				if (not t) then
					maid.antiAutoParry = nil;
					return;
				end;

				maid.antiAutoParry = task.spawn(function()
					while true do
						task.wait();

						local humanoid = Utility:getPlayerData().humanoid;
						if (not humanoid) then continue end;

						pcall(function()
							local animTrack = humanoid:LoadAnimation(randomAnims);

							task.delay(1, function()
								animTrack:Stop();
								animTrack:Destroy();
							end);

							animTrack:play(9999, 0, 0);
						end);
					end;
				end);
			end;
		end;

		function Utility:renderOverload(data)
			data.espSettings:AddToggle({
				text = 'Show Danger Timer'
			});

			makeESP({
				sectionName = 'Ingredients',
				type = 'childAdded',
				args = workspace.Ingredients,
				noColorPicker = true,
				callback = onNewIngredient,
				onLoaded = function(section)
					return {list = makeList(ReplicatedStorage.Assets.Ingredients, section)};
				end
			});

			makeESP({
				sectionName = 'Dropped Items',
				type = 'tagAdded',
				args = 'LootDrop',
				callback = onDroppedItemAdded
			});

			makeESP({
				sectionName = 'Mobs',
				type = 'childAdded',
				args = workspace.Live,
				callback = onNewMobAdded,
				onLoaded = function(section)
					section:AddToggle({
						text = 'Show Health',
						flag = 'Mobs Show Health'
					});
				end
			});

			makeESP({
				sectionName = 'Npcs',
				type = 'childAdded',
				args = workspace.NPCs,
				callback = onNewNpcAdded
			});

			makeESP({
				sectionName = 'Chests',
				type = 'childAdded',
				args = workspace.Thrown,
				callback = onNewChestAdded,
				onLoaded = function(section)
					section:AddToggle({text = 'Only Show Closed Chest'});
				end
			});

			makeESP({
				sectionName = 'Artifacts',
				type = 'childAdded',
				args = {workspace, workspace.Thrown},
				callback = onNewObjectAdded
			});

			makeESP({
				sectionName = 'Crates',
				type = 'childAdded',
				args = workspace.Thrown,
				callback = onNewExplodeCrateAdded
			});

			makeESP({
				sectionName = 'Whirlpools',
				type = 'childAdded',
				args = workspace,
				callback = onNewWhirlPoolAdded
			});

			makeESP({
				sectionName = 'Guild Dors',
				type = 'childAdded',
				args = workspace,
				callback = onNewGuildDoorAdded
			});

			makeESP({
				sectionName = 'Bags',
				type = 'childAdded',
				args = workspace.Thrown,
				callback = onNewBagAdded
			});

			makeESP({
				sectionName = 'Areas',
				type = 'childAdded',
				args = markerWorkspace.AreaMarkers,
				noColorPicker = true,
				callback = onNewAreaAdded,
				onLoaded = function(section)
					return {list = makeList(markerWorkspace.AreaMarkers, section)};
				end
			});

			if (game.PlaceId == 5735553160) then
				-- // Depths

				makeESP({
					sectionName = 'Black Bells',
					type = 'childAdded',
					args = workspace,
					callback = onNewBlackBellAdded
				})
			elseif (game.PlaceId == 8668476218) then
				-- // Layer Two

				makeESP({
					sectionName = 'Lamps',
					type = 'descendantAdded',
					args = workspace,
					callback = onLampAdded
				});
			end;
		end;

		function Utility:isTeamMate(player)
			local myGuild = LocalPlayer:GetAttribute('Guild') or '';
			local playerGuild = player:GetAttribute('Guild') or '';
			if myGuild == '' then return; end

			return myGuild == playerGuild;
		end

		library.OnKeyPress:Connect(function(input, gpe)
			SX_VM_CNONE();

			if (gpe) then return end;

			local key = library.options.attachToBack.key;
			if (input.KeyCode.Name == key or input.UserInputType.Name == key) then
				local myRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
				local closest, closestDistance = nil, math.huge;

				if (not myRootPart) then return end;

				repeat
					for _, entity in next, workspace.Live:GetChildren() do
						local rootPart = entity:FindFirstChild('HumanoidRootPart');
						if (not rootPart or rootPart == myRootPart) then continue end;

						local distance = (rootPart.Position - myRootPart.Position).magnitude;

						if (distance < 300 and distance < closestDistance) then
							closest, closestDistance = rootPart, distance;
						end;
					end;

					task.wait();
				until closest or input.UserInputState == Enum.UserInputState.End;
				if (input.UserInputState == Enum.UserInputState.End) then return end;

				maid.attachToBack = RunService.Heartbeat:Connect(function()
					local goalCF = closest.CFrame * CFrame.new(0, library.flags.attachToBackHeight, library.flags.attachToBackSpace);

					local distance = (goalCF.Position - myRootPart.Position).Magnitude;
					local tweenInfo = TweenInfo.new(distance / 100, Enum.EasingStyle.Linear);

					local tween = TweenService:Create(myRootPart, tweenInfo, {
						CFrame = goalCF
					});

					tween:Play();

					maid.attachToBackTween = function()
						tween:Cancel();
					end;
				end);
			end;
		end);

		library.OnKeyRelease:Connect(function(input)
			SX_VM_CNONE();

			local key = library.options.attachToBack.key;
			if (input.KeyCode.Name == key or input.UserInputType.Name == key) then
				maid.attachToBack = nil;
				maid.attachToBackTween = nil;
			end;
		end);
	end;

	local playerSpectating;
	local playerSpectatingLabel;

	do -- // Setup Leaderboard Spectate
		local lastUpdateAt = 0;

		function setCameraSubject(subject)
			if (subject == LocalPlayer.Character) then
				playerSpectating = nil;
				CollectionService:RemoveTag(LocalPlayer, 'ForcedSubject');

				if (playerSpectatingLabel) then
					playerSpectatingLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
					playerSpectatingLabel = nil;
				end;

				maid.spectateUpdate = nil;
				return;
			end;

			CollectionService:AddTag(LocalPlayer, 'ForcedSubject');
			workspace.CurrentCamera.CameraSubject = subject;

			maid.spectateUpdate = task.spawn(function()
				while task.wait() do
					if (tick() - lastUpdateAt < 5) then continue end;
					lastUpdateAt = tick();
					task.spawn(function()
						LocalPlayer:RequestStreamAroundAsync(workspace.CurrentCamera.CFrame.Position);
					end);
				end;
			end);
		end;

		UserInputService.InputBegan:Connect(function(inputObject)
			if (inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 or not LocalPlayer:FindFirstChild('PlayerGui') or not LocalPlayer.PlayerGui:FindFirstChild('LeaderboardGui')) then return end;

			local newPlayerSpectating;
			local newPlayerSpectatingLabel;

			for _, v in next, LocalPlayer.PlayerGui.LeaderboardGui.MainFrame.ScrollingFrame:GetChildren() do
				if (v:IsA('Frame') and v:FindFirstChild('Player') and v.Player.TextTransparency ~= 0) then
					newPlayerSpectating = v.Player.Text;
					newPlayerSpectatingLabel = v.Player;
					break;
				end;
			end;

			if (not newPlayerSpectating) then return end;

			if (playerSpectatingLabel) then
				playerSpectatingLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
			end;

			playerSpectatingLabel = newPlayerSpectatingLabel;
			playerSpectatingLabel.TextColor3 = Color3.fromRGB(255, 0, 0);

			if (newPlayerSpectating == playerSpectating or newPlayerSpectating == LocalPlayer.Name) then
				setCameraSubject(LocalPlayer.Character);
			else
				print('spectating new player');
				playerSpectating = newPlayerSpectating;

				local player = Players:FindFirstChild(playerSpectating);

				if (not player or not player.Character or not player.Character.PrimaryPart) then
					print('player not found', player);
					setCameraSubject(LocalPlayer.Character);
					return;
				end;

				setCameraSubject(player.Character);
			end;
		end);

		TextLogger.setCameraSubject = setCameraSubject;
	end;

	do -- // Auto Parry Analytics
		local dataset, dataSetTemp = {}, {};
		local allCombatAnims = {};

		local blacklistedNames = {'Walk', 'Idle', 'Execute', 'Stunned', 'Scream', 'Deactivated', 'Block'};

		debug.profilebegin('Grab Anims');
		for _, v in next, ReplicatedStorage.Assets.Anims.Mobs:GetDescendants() do
			if (IsA(v, 'Animation')) then
				if (table.find(blacklistedNames, v.Name)) then continue end;
				local animationId = v.AnimationId:match('%d+');
				allCombatAnims[animationId] = string.format('%s-%s', v.Parent.Name, v.Name);
			end;
		end;

		for _, v in next, ReplicatedStorage.Assets.Anims.Weapon:GetDescendants() do
			if (IsA(v, 'Animation')) then
				if (table.find(blacklistedNames, v.Name)) then continue end;
				local animationId = v.AnimationId:match('%d+');
				allCombatAnims[animationId] = string.format('%s-%s', v.Parent.Name, v.Name);
			end;
		end;
		debug.profileend();

		allCombatAnims['5773120368'] = 'FiregunRight'; -- Not enough data
		allCombatAnims['7666455222'] = 'WindSlashSlashSlash'; -- Not enough data (client effect?)

		-- Just added to db need to be added to timings

		allCombatAnims['10357806593'] = 'WindKick';
		allCombatAnims['9400896040'] = "ShoulderBash";

		local animLogger = {};
		animLogger.__index = animLogger;

		local listening = {};

		function animLogger.new(character)
			local self = setmetatable({},animLogger);

			self._maid = Maid.new();
			self:AddCharacter(character);

			return self;
		end

		function animLogger:AddCharacter(character)
			if (character == LocalPlayer.Character or listening[character]) then return end;

			self._maid:GiveTask(character.Destroying:Connect(function()
				self:Destroy();
			end));

			local humanoid = character:WaitForChild('Humanoid', 30);
			if (not humanoid) then return end;

			self._maid:GiveTask(humanoid.AnimationPlayed:Connect(function(animationTrack)
				local rootPart = character:FindFirstChild('HumanoidRootPart');
				if (not rootPart or not myRootPart or (rootPart.Position - myRootPart.Position).Magnitude >= 1000) then return end;

				local animId = animationTrack.Animation.AnimationId:match('%d+');
				local animName = allCombatAnims[animId] or 'No Anim Name';

				if (not allCombatAnims[animId] and not animTimes[animId]) then return end;

				local t = {
					animId = animId,
					playedAt = tick(),
					position = rootPart.Position,
					animName = animName,
					animTrack = animationTrack
				};

				table.insert(dataSetTemp, t);

				task.delay(1.5, function()
					local i = table.find(dataSetTemp, t);
					if (not i) then return end;

					table.remove(dataSetTemp, i);
				end);
			end));
		end

		function animLogger:Destroy()
			self._maid:Destroy();
		end;

		local lastParryAt = 0;
		local canParry = true;

		-- effectReplicator.EffectAdded:connect(function(effect)
		-- 	if (effect.Class == 'ParrySuccess') then
		-- 		local playerPing = Stats.PerformanceStats.Ping:GetValue();

		-- 		for _, v in next, dataSetTemp do
		-- 			local t= lastParryAt - v.playedAt;
		-- 			if (t < 0) then continue end;

		-- 			--print('Timing could be', lastParryAt - (v.playedAt-playerPing/2));
		-- 			table.insert(dataset, {
		-- 				ping = playerPing,
		-- 				animId = v.animId,
		-- 				timing = lastParryAt-v.playedAt,
		-- 				blockedAt = lastParryAt,
		-- 				version = 1.02,
		-- 				parriedAt = tick(),
		-- 				autoParryType = library.flags.autoParry and 'normal' or 'no-ap',
		-- 				distance = (myRootPart.Position-v.position).Magnitude,
		-- 				animName = v.animName,
		-- 				animLength = v.animTrack.Length,
		-- 				animSpeed = v.animTrack.Speed,
		-- 				timePosition = v.animTrack.TimePosition
		-- 			})
		-- 		end;

		-- 		table.clear(dataSetTemp);
		-- 	end;
		-- end);

		effectReplicator.EffectRemoving:connect(function(effect)
			if (effect.Class == 'ParryCool') then
				canParry = true;
			end;
		end);

		function onParryRequest()
			if (not effectReplicator:FindEffect('ParryCool') and not effectReplicator:FindEffect('Action') and not effectReplicator:FindEffect('LightAttack') and canParry and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Weapon')) then
				lastParryAt = tick();
				canParry = false;
				warn('Client read', lastParryAt);
			end;
		end;

		task.spawn(function()
			while (true) do
				task.wait(10);
				if (#dataset == 0) then continue end;
				if (debugMode) then continue end;

				task.spawn(function()
					local requestData = syn.request({
						Url = 'https://aztupscripts.xyz/api/v1/misc/submit-parry-timing',
						Method = 'POST',
						Headers = {['Content-Type'] = 'application/json', Authorization = websiteKey},
						Body = HttpService:JSONEncode(dataset)
					});

					if (requestData.Success) then
						print('Successfully uploaded parry-timings');
					else
						print('Failed to upload parry timings', requestData.Body);
					end;
				end);

				table.clear(dataset);
			end;
		end);

		-- Utility.listenToChildAdded(workspace.Live, animLogger, {listenToDestroying = true});
	end;

	do -- // Auto Wisp
		local spellRemote = ReplicatedStorage.Requests.Spell;
		local func = require(ReplicatedStorage.Modules.Ram);

		local keyIndexes = {
			'Z',
			'X',
			'C',
			'V'
		};

		local currentKeys = {};
		maid.autoWisp = spellRemote.OnClientEvent:Connect(function(actionType, data)
			if actionType == 'set' then
				table.foreach(func(data),function(_, v) table.insert(currentKeys,keyIndexes[v]) end);
				functions.autoWisp(library.flags.autoWisp);
			elseif actionType == 'close' then
				table.clear(currentKeys);
			end
		end)

		function functions.autoWisp(t)
			if (not t) then return end;

			for _, key in next, currentKeys do
				library.disableKeyBind = true;
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[key], false, game);
				task.wait();
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[key], false, game);
				task.wait();
				library.disableKeyBind = false;
				task.wait(0.2);
			end;
		end;
	end;

	library.OnKeyPress:Connect(function(inputObject, gpe)
		if (not library.flags.easyMantraFeint or inputObject.UserInputType.Name ~= 'MouseButton2' or not effectReplicator:FindEffect('UsingSpell')) then return end;

		VirtualInputManager:SendMouseButtonEvent(0, 50, 0, true, game, 0);
		task.wait();
		VirtualInputManager:SendMouseButtonEvent(0, 50, 0, false, game, 0);
	end);

	effectReplicator.EffectAdded:connect(function(effect)
		if (effect.Class == 'UsingSpell' and library.flags.autoPerfectCast) then
			VirtualInputManager:SendMouseButtonEvent(0, 50, 0, true, game, 0);
			task.wait();
			VirtualInputManager:SendMouseButtonEvent(0, 50, 0, false, game, 0);
		end;
	end);

	function isInDanger()
		return effectReplicator:FindEffect('Danger');
	end;

	function functions.setupAutoLoot(autoLoot)
		local autoLootTypes = {'Ring', 'Gloves', 'Shoes', 'Helmets', 'Glasses', 'Earrings', 'Schematics', 'Weapons', 'Daggers', 'Necklace', 'Trinkets'};
		local weaponAttributes = {'HP','ETH','RES','Posture','SAN','Monster Armor','PHY Armor','Monster DMG','ELM Armor'};
		local autoLootObjects = {};
		local autoLootAttributeObjects = {};

		local oldObjectAttributes;
		local function autoLootShowAttributes(typeName) --I could make this use the flag 1000x the smart but whatevs u can fix it if u want
			local autoLootObject = autoLootAttributeObjects[typeName];
			local showAttribute = library.flags['autoLootWhitelistUseAttributes'..typeName];
			for _, v in next, autoLootObject do
				v.main.Visible = showAttribute;
			end;

			oldObjectAttributes = autoLootObject;
		end;

		local oldObject;
		local function autoLootShowType(typeName) --Kind of messy now thx to awesome code
			if (oldObject) then
				for _, v in next, oldObject do
					v.main.Visible = false;
				end;
			end;

			if (oldObjectAttributes) then
				for _, v in next, oldObjectAttributes do
					v.main.Visible = false;
				end;
			end;

			local autoLootObject = autoLootObjects[typeName];

			for _, v in next, autoLootObject do
				v.main.Visible = true;
			end;

			if library.flags['autoLootWhitelistUseAttributes'..typeName] then
				autoLootShowAttributes(typeName);
			end

			oldObject = autoLootObject;
		end;


		autoLoot:AddDivider('Auto Loot Settings');
		autoLoot:AddToggle({
			text = 'Always Pickup Enchant',
			tip = 'This will make the auto loot pickup always pickup enchants no matter what'
		});

		autoLoot:AddToggle({
			text = 'Always Pickup Medallion',
			tip = 'This will make the auto loot pickup the medallion no matter what'
		});

		autoLoot:AddList({
			text = 'Types',
			flag = 'Auto Loot Whitelist Types',
			tip = 'This allows you to customize the settings for each item type selected',
			values = autoLootTypes,
			callback = autoLootShowType
		});

		for _, v in next, autoLootTypes do
			local autoLootObject = {};
			local autoLootAttributesObject = {};

			autoLootObjects[v] = autoLootObject;
			autoLootAttributeObjects[v] = autoLootAttributesObject;

			table.insert(autoLootObject, autoLoot:AddToggle({
				text = string.format('Use Filter [%s]', v),
				tip = 'Toggle this on to only grab the selected options for this item type',
				flag = string.format('Auto Loot Filter %s', v)
			}))

			table.insert(autoLootObject, autoLoot:AddList({
				text = string.format('Rarities [%s]', v),
				flag = string.format('Auto Loot Whitelist Rarities %s', v),
				tip = 'This tells the autoloot what rarities to pickup for the selected item type',
				multiselect = true,
				values = {'Uncommon', 'Common', 'Rare', 'Epic', 'Legendary', 'Enchant'}
			}))

			table.insert(autoLootObject, autoLoot:AddList({
				text = string.format('Stars [%s]', v),
				flag = string.format('Auto Loot Whitelist Stars %s', v),
				tip = 'This tells the autoloot how many stars it should have to pickup for the selected item type.',
				multiselect = true,
				values = {'0 Stars', '1 Stars', '2 Stars', '3 Stars'}
			}));

			table.insert(autoLootObject, autoLoot:AddList({
				text = string.format('Priority [%s]', v),
				flag = string.format('Auto Loot Whitelist Priorities %s', v),
				tip = 'This tells it what to prioritize over the other for the selected item type',
				values = {'None', 'Stars', 'Stats'}
			}));

			table.insert(autoLootObject, autoLoot:AddToggle({
				text = string.format('Check Item Stats'),
				tip = 'This tells the autoloot to check the item stats to pickup for the selected item type',
				flag = string.format('Auto Loot Whitelist Use Attributes %s', v),
				callback = function() autoLootShowAttributes(library.flags.autoLootWhitelistTypes); end
			}))

			table.insert(autoLootObject, autoLoot:AddToggle({
				text = string.format('Match All Stat Settings'),
				tip = 'All the item stats selected have to match (except for 0) for the selected item type',
				flag = string.format('Auto Loot Whitelist Match All %s', v),
			}))

			for _,valueName in next, weaponAttributes do --Id like for you to hide this but im 2 lazy to figure ur dumb dum UI shit (no comments bozo)
				table.insert(autoLootAttributesObject, autoLoot:AddSlider({
					text = string.format('[%s] Value', valueName),
					min = 0,
					max = 50,
					float = 1,
					flag = string.format('Auto Loot Whitelist %s %s', valueName, v), --IDK if this will handle shit like HP properly so awesome!!!
				}))
			end
		end;

		library.OnLoad:Connect(function()
			for _, v in next, autoLootObjects do
				for _, v2 in next, v do v2.main.Visible = false end;
			end;
			for _, v in next, autoLootAttributeObjects do
				for _, v2 in next, v do v2.main.Visible = false end;
			end;
		end);
	end;

	function functions.holdM1(t)
		if (not t) then
			maid.holdM1 = nil;
			return;
		end;

		local function canAttack()
			return _G.canAttack and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and leftClickRemote;
		end;

		maid.holdM1 = task.spawn(function()
			while task.wait() do
				if (not canAttack()) then continue end;
				local ti = tick();
				local character = LocalPlayer.Character;
				if (not character) then continue end;
				local shouldUpperCut = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl);

				local ctrl = {
					A = false,
					S = false,
					D = false,
					W = false,
					Space = false,
					G = false,
					Left = true,
					Right = false,
					ctrl = shouldUpperCut
				}

				-- If we have both guns then
				if (character and character:FindFirstChild('RightHand') and character:FindFirstChild('LeftHand') and character.RightHand:FindFirstChild('Gun', true) and character.LeftHand:FindFirstChild('Gun', true)) then
					repeat task.wait() until not effectReplicator:FindEffect('LightAttack');

					repeat task.wait();
						originalFunctions.fireServer(leftClickRemote, false, playerMouse.Hit, nil, shouldUpperCut or nil, {ti - math.random() / 100, ti}, ctrl)
						if (not canAttack()) then break; end;
					until effectReplicator:FindEffect("LightAttack");

					if (not canAttack()) then continue end;
					repeat task.wait() until not effectReplicator:FindEffect('LightAttack');
					if (not canAttack()) then continue end;

					repeat
						task.wait();
						originalFunctions.fireServer(rightClickRemote, ctrl);
						if (not canAttack()) then break; end;
					until effectReplicator:FindEffect('LightAttack');
				else
					originalFunctions.fireServer(leftClickRemote, false, playerMouse.Hit, nil, shouldUpperCut or nil, {ti - math.random() / 100, ti}, ctrl)
				end
			end;
		end);
	end;

	function functions.autoUnragdoll(t)
		if (not t) then
			maid.autoUnragdoll = nil;
			return;
		end;

		local ctrl = {
			A = false,
			S = false,
			D = false,
			W = false,
			Space = false,
			G = false,
			Left = false,
			Right = true
		}

		maid.autoUnragdoll = effectReplicator.EffectAdded:connect(function(obj)
			--warn(obj);
			if (obj.Class == 'Knocked') then
				originalFunctions.fireServer(rightClickRemote, ctrl);
			end;
		end);
	end;

	local oldAgilityValue;

	function functions.agilitySpoofer(t)
		if (not t) then
			maid.agilitySpoofer = nil;

			if (oldAgilityValue) then
				local agility = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Agility');
				if (not agility) then return end;

				agility.Value = oldAgilityValue;
				oldAgilityValue = nil;
			end;
			return;
		end;

		maid.agilitySpoofer = RunService.Heartbeat:Connect(function()
			local value = library.flags.agilitySpooferValue;

			local agility = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Agility');
			if (not agility) then return end;

			if (not oldAgilityValue) then
				oldAgilityValue = agility.Value;
			end;

			agility.Value = value;
		end);
	end;

	function functions.autoRes(t)

		if (not t) then
			maid.autoRes = nil;
			return;
		end;

		local resDebounce = false;
		maid.autoRes = RunService.Heartbeat:Connect(function()
			local playerData = Utility:getPlayerData();
			local humanoid, rootPart = playerData.humanoid, playerData.rootPart;
			if (not humanoid or not rootPart) then return end;

			local isUsingRes = rootPart:FindFirstChild('Core',true);
			print(isUsingRes);
			if not isUsingRes or resDebounce then return; end
			print("Pass1")
			if (library.flags.resHpPercent < humanoid.Health/humanoid.MaxHealth*100) then return; end
			print("Pass2")

			resDebounce = true;
			task.delay(10,function() resDebounce = false; end);

			task.wait(2);
			fallRemote:FireServer(humanoid.Health*1.3,false);
		end);
	end;

	do -- Chunk Loader

		local largeParts = Instance.new('Folder');
		largeParts.Name = "Large Parts";

		local activeChunks = Instance.new('Folder');
		activeChunks.Name = 'ActiveChunks';

		local chunkFolders = Instance.new('Folder');
		chunkFolders.Name = 'Chunks';

		local chunkLoaderMaid = Maid.new();

		local allChunks = {};
		local loadedChunks = {};
		local lastChunk;
		local lastRenderDistance;
		local rootPart;

		local floor = math.floor;
		local newVector3 = Vector3.new;

		local tableInsert = table.insert;
		local tableRemove = table.remove;
		local staticVector = newVector3(1, 0, 1);

		local function getChunk(position)
			local x, z = position.X, position.Z;

			return math.floor(x / 100) .. ':' .. math.floor(z / 100);
		end;

		local function createChunkFolder(chunkId)
			local folder = Instance.new('Folder');
			folder.Name = chunkId;
			folder.Parent = activeChunks;

			local x, z = unpack(folder.Name:split(':'));
			x, z = tonumber(x), tonumber(z);

			if (not allChunks[x]) then
				allChunks[x] = {};
			end;

			if (not allChunks[x][z]) then
				allChunks[x][z] = {};
			end;

			allChunks[x][z] = folder;

			local position = (rootPart or workspace.CurrentCamera).CFrame.Position / 100;
			local floatPosition = newVector3(floor(position.X), 0, floor(position.Z))
			local chunkPosition = floatPosition + newVector3(x, 0, z);

			tableInsert(loadedChunks, {
				chunk = folder,
				p = chunkPosition * staticVector,
				x = x,
				z = z
			});

			return folder;
		end;

		local function chunkFunction(v)
			local position;

			if (IsA(v, 'Model') and FindFirstChildWhichIsA(v,"BasePart")) then
				position = v:GetModelCFrame().Position;
			elseif (IsA(v, 'BasePart') and not IsA(v, 'Terrain')) then
				position = v.Position;
			end;

			if (position and not IsDescendantOf(v.Parent, chunkFolders)) then
				local chunkId = getChunk(position);
				local chunk = (FindFirstChild(activeChunks, chunkId) or FindFirstChild(chunkFolders, chunkId))  or createChunkFolder(chunkId);

				v.Parent = chunk;
			end;
		end

		function functions.disableShadows(t)
			Lighting.GlobalShadows = not t;
		end;

		local ran = false;

		--Stuff that needs to run on toggle
		function functions.chunkLoaderToggle(state)
			SX_VM_CNONE();

			if not state then
				if (not ran) then return end;
				chunkLoaderMaid:DoCleaning();

				for _,v in next, allChunks do
					for _,v2 in next, v do
						for _,v3 in next, v2:GetChildren() do
							v3.Parent = workspace.Map;
						end
					end
				end

				for _,v in next, activeChunks:GetChildren() do
					for _,k in next, v:GetChildren() do
						k.Parent = workspace.Map;
					end
				end

				for _,v in next, largeParts:GetChildren() do
					v.Parent = workspace.Map;
				end

				for _, v in next, chunkFolders:GetChildren() do
					for _, v2 in next, v:GetChildren() do
						v2.Parent = workspace.Map;
					end;
				end;

				lastChunk = nil;
				lastRenderDistance = nil;
				rootPart = nil;
				largeParts.Parent = nil;
				activeChunks.Parent = nil;

				return;
			end

			ran = true;

			largeParts.Parent = workspace;
			activeChunks.Parent = workspace;

			for _,v in next, workspace:GetDescendants() do
				if not v:IsA("BasePart") or v.ClassName == "Terrain" then continue; end
				if v.Size.Magnitude >= 500 then v.Parent = largeParts end
			end

			for _, v in next, game:GetService("Workspace").Map:GetChildren() do
				if IsA(v,"Folder") then
					for _,k in next, v:GetChildren() do
						chunkFunction(k);
					end
				end
				chunkFunction(v);
			end;

			chunkLoaderMaid:GiveTask(workspace.Map.DescendantAdded:Connect(function(v)
				SX_VM_CNONE();
				task.wait();
				if not v:IsA("BasePart") then return; end
				if v.Size.Magnitude >= 500 then v.Parent = largeParts; return; end
				chunkFunction(v);
			end));

			chunkLoaderMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function()
				SX_VM_CNONE();
				rootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart",10);

				chunkLoaderMaid:GiveTask(rootPart.AncestryChanged:Connect(function()
					if not rootPart.Parent then
						rootPart = nil;
					end
				end));
			end))

			rootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart",5);

			chunkLoaderMaid:GiveTask(RunService.Stepped:Connect(function()
				SX_VM_CNONE();
				rootPart = rootPart or workspace.CurrentCamera;

				local position = rootPart.CFrame.Position / 100;
				local chunkRenderDistance = library.flags.renderDistance;

				local floatPosition = newVector3(floor(position.X), 0, floor(position.Z))

				if (floatPosition == lastChunk and lastRenderDistance==chunkRenderDistance) then
					return;
				end;

				local chunkUnloadDistance = chunkRenderDistance * 2;

				lastChunk = floatPosition;
				lastRenderDistance = library.flags.renderDistance;

				local unloadedChunks = {};

				for i, chunkData in next, loadedChunks do
					local chunkDistance = (floatPosition - chunkData.p).Magnitude;

					if (chunkDistance > chunkUnloadDistance * 2) then
						chunkData.chunk.Parent = chunkFolders;
						allChunks[chunkData.x][chunkData.z] = chunkData.chunk;

						tableInsert(unloadedChunks, chunkData);
					end;
				end;

				for _, v in next, unloadedChunks do
					tableRemove(loadedChunks, table.find(loadedChunks, v))
				end;

				for x = -chunkRenderDistance, chunkRenderDistance do
					for z = -chunkRenderDistance, chunkRenderDistance do
						local chunkPosition = floatPosition + newVector3(x, 0, z);
						local x, z = chunkPosition.X, chunkPosition.Z;

						local xChunk = allChunks[x];

						local currentChunk = xChunk and xChunk[z];

						if (not currentChunk) then
							continue
						end;

						currentChunk.Parent = activeChunks;
						xChunk[z] = nil;

						tableInsert(loadedChunks, {
							chunk = currentChunk,
							p = chunkPosition * staticVector,
							x = x,
							z = z
						});
					end;
				end;
			end));
		end
	end;

	do -- One Shot NPCs
		local mobs = {};

		local NetworkOneShot = {};
		NetworkOneShot.__index = NetworkOneShot;

		function NetworkOneShot.new(mob)
			local self = setmetatable({},NetworkOneShot);

			self._maid = Maid.new();
			self.char = mob;

			self._maid:GiveTask(mob.Destroying:Connect(function()
				self:Destroy();
			end));

			self._maid:GiveTask(Utility.listenToChildAdded(mob, function(obj)
				if (obj.Name == 'HumanoidRootPart') then
					self.hrp = obj;
				end;
			end));

			mobs[mob] = self;
			return self;
		end;

		function NetworkOneShot:Update()
			if (not self.hrp or not isnetworkowner(self.hrp) or not self.hrp.Parent or self.hrp.Parent.Parent ~= workspace.Live) then return end;
			self.char:PivotTo(CFrame.new(self.hrp.Position.X, workspace.FallenPartsDestroyHeight - 100000, self.hrp.Position.Z));
		end;

		function NetworkOneShot:Destroy()
			self._maid:DoCleaning();

			for i,v in next, mobs do
				if (v ~= self) then continue; end
				mobs[i] = nil;
			end;
		end;

		function NetworkOneShot:ClearAll()
			for _, v in next, mobs do
				v:Destroy();
			end;

			table.clear(mobs);
		end;

		Utility.listenToChildAdded(workspace.Live, function(obj)
			task.wait(0.2);
			if (obj == LocalPlayer.Character) then return; end
			NetworkOneShot.new(obj);
		end);

		function functions.networkOneShot(t)
			if (not t) then
				maid.networkOneShot = nil;
				maid.networkOneShot2 = nil;
				return;
			end;

			maid.networkOneShot2 = RunService.Heartbeat:Connect(function()
				sethiddenproperty(LocalPlayer, 'MaxSimulationRadius', math.huge);
				sethiddenproperty(LocalPlayer, 'SimulationRadius', math.huge);
			end);

			maid.networkOneShot = task.spawn(function()
				while task.wait() do
					for _, mob in next, mobs do
						mob:Update();
					end;
				end;
			end);
		end;
	end;

	do -- Give Anim Gamepass
		function functions.giveAnimGamepass(t)
			if (not t) then return end;

			-- Add emote pack gamepass
			CollectionService:AddTag(LocalPlayer, 'EmotePack1');
			CollectionService:AddTag(LocalPlayer, 'MetalBadge');
			local gestureGui = LocalPlayer:WaitForChild('PlayerGui', 10):WaitForChild('GestureGui');

			-- Clear all emotes cause we rerun the script

			for _, child in next, gestureGui.MainFrame.GestureScroll:GetChildren() do
				if (child:IsA('TextLabel')) then
					child:Destroy();
				end;
			end;

			gestureGui.GestureClient.Enabled = false;
			gestureGui.GestureClient.Enabled = true;
		end;
	end;
end;

local localCheats = column1:AddSection('Local Cheats');
local notifier = column1:AddSection('Notifier');
local playerMods = column1:AddSection('Player Mods');
local autoParry = column2:AddSection('Auto Parry');
local autoParryMaker = column1:AddSection('Auto Parry Maker');
local misc = column1:AddSection('Misc');
local autoLoot = column2:AddSection('Auto Loot');
local visuals = column2:AddSection('Visuals');
local farms = column2:AddSection('Farms');
local inventoryViewer = column2:AddSection('Inventory Viewer');

do -- // Inventory Viewer (SMH)
	local inventoryLabels = {};
	local itemColors = {};

	itemColors[100] = Color3.new(0.76862699999999995, 1, 0);
	itemColors[9] = Color3.new(1, 0.90000000000000002, 0.10000000000000001);
	itemColors[10] = Color3.new(0, 1, 0);
	itemColors[11] = Color3.new(0.90000000000000002, 0, 1);
	itemColors[3] = Color3.new(0, 0.80000000000000004, 1);
	itemColors[8] = Color3.new(0.17254900000000001, 0.80000000000000004, 0.64313699999999996);
	itemColors[7] = Color3.new(1, 0.61568599999999996, 0);
	itemColors[6] = Color3.new(1, 0, 0);
	itemColors[4] = Color3.new(0.82745100000000005, 0.466667, 0.207843);
	itemColors[0] = Color3.new(1, 1, 1);
	itemColors[5] = Color3.new(0.33333299999999999, 0, 1);
	itemColors[999] = Color3.new(0.792156, 0.792156, 0.792156);

	local function getToolType(tool)
		if (tool:FindFirstChild("Weapon")) then
			return 0;
		elseif (tool:FindFirstChild("Mantra") or tool:FindFirstChild("Spec")) then
			return 3;
		elseif (tool:FindFirstChild("Talent")) then
			return 100;
		elseif (tool:FindFirstChild("Equipment")) then
			return 7;
		elseif (tool:FindFirstChild("WeaponTool")) then
			return 6;
		elseif (tool:FindFirstChild("Training")) then
			return 4;
		elseif (tool:FindFirstChild("Potion")) then
			return 5;
		elseif (tool:FindFirstChild("Schematic")) then
			return 8;
		elseif (tool:FindFirstChild("Ingredient")) then
			return 10;
		elseif (tool:FindFirstChild("SpellIngredient")) then
			return 11;
		elseif (tool:FindFirstChild("Item")) then
			return 9;
		end

		return 999;
	end;

	local function showPlayerInventory(player)
		if (typeof(player) ~= 'Instance') then return end;

		for _, v in next, inventoryLabels do
			v.main:Destroy();
		end;

		inventoryLabels = {};

		local playerItems = {};
		local seen = {};
		local seenJSON = {};

		local function onBackpackChildAdded(tool)
			debug.profilebegin('onBackpackChildAdded');
			local toolName = tool:GetAttribute('DisplayName') or tool.Name:gsub('[^:]*:', ''):gsub('%$[^%$]*', '');
			local toolType = getToolType(tool);
			local weaponData = tool:FindFirstChild('WeaponData');

			xpcall(function()
				weaponData = seenJSON[weaponData] or HttpService:JSONDecode(weaponData.Value);
			end, function()
				weaponData = syn.crypt.base64.decode(weaponData.Value);
				weaponData = weaponData:sub(1, #weaponData - 2);

				weaponData = HttpService:JSONDecode(weaponData);
			end);

			if (typeof(weaponData) == 'table') then
				table.foreach(weaponData, warn);
				toolName = string.format('%s%s', toolName, (weaponData.Soulbound or weaponData.SoulBound) and ' [Soulbound]' or '');
			end;

			local exitingPlayerItem = seen[toolName];

			if (exitingPlayerItem) then
				exitingPlayerItem.quantity += 1;
				return;
			end;

			local playerItem =  {
				type = toolType,
				toolName = toolName,
				quantity = 1
			};

			table.insert(playerItems, playerItem);
			seen[toolName] = playerItem;
		end;

		for _, tool in next, player.Backpack:GetChildren() do
			task.spawn(onBackpackChildAdded, tool);
		end;

		table.sort(playerItems, function(a, b)
			return a.type < b.type;
		end);

		for _, v in next, playerItems do
			v.text = ('<font color="#%s">%s [x%d]</font>'):format(itemColors[v.type]:ToHex(), v.toolName, v.quantity);
			table.insert(inventoryLabels, inventoryViewer:AddLabel(v.text));
		end;
	end;

	inventoryViewer:AddList({
		text = 'Player',
		tip = 'Player to watch inventory for',
		playerOnly = true,
		skipflag = true,
		callback = showPlayerInventory
	});
end;

do -- // Removals
	playerMods:AddToggle({
		text = 'No Fall Damage',
		tip = 'Removes fall damage for you'
	});

	playerMods:AddToggle({
		text = 'No Stun',
		tip = 'Makes it so you will not get stunned in combat',
	});

	playerMods:AddToggle({
		text = 'No Wind',
		tip = 'Disables the slow during wind in Layer 2',
		callback = functions.noWind
	});

	playerMods:AddToggle({
		text = 'No Kill Bricks',
		tip = 'Removes all the kill bricks',
		callback = functions.noKillBricks
	});

	playerMods:AddToggle({
		text = 'No Acid Damage',
		flag = 'Anti Acid',
		tip = 'Prevent you from taking damage from acid water.'
	});

	playerMods:AddToggle({
		text = 'No Anims (Risky)',
		flag = 'No Anims',
		tip = 'Disable all your anims',
		callback = functions.noAnims
	});

	playerMods:AddToggle({
		text = 'No Jump Cooldown',
		tip = 'Makes it so you can jump even when on cooldown.'
	})

	playerMods:AddToggle({
		text = 'No Stun Less Blatant',
		tip = 'Like no stun but it\'s less blatant'
	});

	playerMods:AddToggle({
		text = 'Give Anim Gamepass',
		tip = 'Allows you to use all the animations ingame for free without the gamepass.',
		callback = functions.giveAnimGamepass
	});
end;

do -- // Local Cheats
	localCheats:AddDivider("Movement");

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
		text = 'Agility Spoofer',
		callback = functions.agilitySpoofer,
		tip = 'This sets your ingame agility to x amount, allowing you to slide further and climb higher.'
	}):AddSlider({
		flag = 'Agility Spoofer Value',
		min = 0,
		max = 250
	});

	localCheats:AddToggle({
		text = 'No Clip',
		callback = functions.noClip
	});

	localCheats:AddToggle({
		text = 'Disable When Knocked',
		tip = 'Disables noclip when you get ragdolled',
		flag = 'Disable No Clip When Knocked'
	});


	localCheats:AddToggle({
		text = 'Knocked Ownership',
		tip = 'Allow you to fly/move while being knocked.'
	})

	localCheats:AddToggle({
		text = 'Use Weapon',
		tip = 'Uses your weapon to make knocked ownership work',
		flag = 'Use Weapon For Knocked Ownership'
	});

	localCheats:AddToggle({
		text = 'Click Destroy',
		tip = 'Everything you click on will be destroyed (client sided)',
		callback = functions.clickDestroy
	});

	localCheats:AddBind({text = 'Go To Ground', callback = functions.goToGround, mode = 'hold', nomouse = true});

	localCheats:AddBind({
		text = 'Tween to Objectives',
		tip = 'This will automatically go to bloodjars, bones and the obelisks in layer 2 when held down.',
		mode = 'hold',
		callback = functions.autoBloodjar
	});

	localCheats:AddDivider("Gameplay-Assist");

	localCheats:AddToggle({
		text = 'M1 Hold',
		tip = 'Automatically spams m1, when you hold it down',
		callback = functions.holdM1
	});

	localCheats:AddToggle({
		text = 'Auto Wisp',
		tip = 'Automatically solve the wisp puzzles by pressing keys for you',
		callback = functions.autoWisp
	});

	localCheats:AddToggle({
		text = 'Auto Perfect Cast',
		tip = 'Automatically perfect cast your mantra'
	});

	localCheats:AddToggle({
		text = 'Easy Mantra Feint',
		tip = 'Allows you to right click to feint your mantra'
	});

	localCheats:AddToggle({
		text = 'Auto Unragdoll',
		tip = 'Automatically right click when you get ragdolled',
		callback = functions.autoUnragdoll
	});

	localCheats:AddToggle({
		text = 'Auto Sprint',
		tip = 'Whenever you want to walk you sprint instead',
		callback = functions.autoSprint
	});

	localCheats:AddToggle({
		text = 'Silent Aim',
		tip = 'If toggled with FOV check in aimbot section, your attacks aimed attacks will automatically go towards towards them if in the FOV circle'
	});

	localCheats:AddToggle({
		text = 'Auto Ressurect',
		tip = '(WARNING: CAN WIPE YOU): This function will trigger when the ressurect bell is used and will knock you so that you resurrect up with more HP',
		callback = functions.autoRes
	}):AddSlider({
		suffix = '% HP',
		min = 0,
		max = 40,
		flag = "Res Hp Percent"
	});

	localCheats:AddDivider("Combat Tweaks");

	localCheats:AddToggle({
		text = 'One Shot Mobs',
		tip = 'This feature randomly works sometimes and causes them to die, but it makes AP have issues',
		callback = functions.networkOneShot
	});

	localCheats:AddToggle({
		text = 'Anti Auto Parry',
		tip = 'Breaks all auto parry other than users who are also using aztup hub.',
		callback = functions.antiAutoParry
	});

	localCheats:AddBind({
		text = 'Instant Log',
		nomouse = true,
		callback = function()
			ReplicatedStorage.Requests.ReturnToMenu:FireServer();

			local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
			if (not playerGui) then return end;

			local choicePrompt = playerGui:WaitForChild('ChoicePrompt', 25);
			if (not choicePrompt) then return end;

			choicePrompt.Choice:FireServer(true);
		end
	});

	localCheats:AddButton({
		text = 'Server Hop',
		tip = 'Jumps to any other server, non region dependant',
		callback = functions.serverHop
	});

	localCheats:AddBind({
		text = 'Attach To Back',
		tip = 'This attaches to the nearest entities back based on settings',
		callback = functions.attachToBack,
	});

	localCheats:AddSlider({
		text = 'Attach To Back Height',
		value = 0,
		min = -100,
		max = 100,
		textpos = 2
	});

	localCheats:AddSlider({
		text = 'Attach To Back Space',
		value = 2,
		min = -100,
		max = 100,
		textpos = 2
	});
end;

do --// Notifier
	notifier:AddToggle({
		text = 'Mod Notifier',
		state = true
	});

	notifier:AddToggle({
		text = 'Moderator Sound Alert',
		tip = 'Makes a sound when the mod joins',
		state = true
	});

	notifier:AddToggle({
		text = 'Void Walker Notifier',
		state = true
	});

	notifier:AddToggle({
		text = 'Mythic Item Notifier',
	});

	notifier:AddToggle({
		text = 'Artifact/Owl Notifier',
		flag = 'Artifact Notifier'
	});

	notifier:AddToggle({
		text = 'Player Proximity Check',
		tip = 'Gives you a warning when a player is close to you',
		callback = functions.playerProximityCheck
	});
end

do -- // Auto Parry
	autoParry:AddToggle({
		text = 'Enable',
		flag = 'Auto Parry',
		tip = 'Automatically parry when you are attacked.',
		callback = functions.autoParry
	}):AddSlider({
		text = 'Ping Adjustment %',
		flag = 'Ping Adjustment Percentage',
		min = 0,
		value = 75,
		step = 0.05,
		max = 100,
		textpos = 2,
		tip = 'Play with this slider to find what is best for you, we recommend 75%-50%'
	});

    autoParry:AddSlider({
        text = 'Parry Chance',
        tip = 'Determines the chance of you parrying an attack',
		suffix = '%',
		textpos = 2,
        min = 0,
        max = 100,
        float = 1,
        value = 100
    });

    autoParry:AddToggle({
		text = 'Parry When Dodging',
        state = true,
		tip = 'The auto parry will parry when you have dodge frames, it is recommended you turn this on if you have issues with AP'
	});

	autoParry:AddToggle({
		text = 'Parry Vent',
		tip = 'This determines whether or not you will attempt to parry vents from other players',
		state = true
	});

	autoParry:AddToggle({
		text = 'Use Custom Delay',
		tip = 'Disables ping adjust in favor of the timing you specify',
	}):AddSlider({
		text = 'Custom Delay',
		suffix = 'ms',
		flag = "Custom Delay",
		min = -500,
		value = 0,
		max = 500,
		textpos = 2,
		tip = 'Adjust all the parry timings by this number.'
	})

	autoParry:AddSlider({
		text = 'Distance Adjustment',
		min = -25,
		value = 0,
		max = 25,
		textpos = 2,
		tip = 'Adjust all the parry max distances.'
	});

	autoParry:AddToggle({
		text = 'Parry Roll',
		tip = 'Always roll instead of parying if you are not on roll cooldown when you are attacked (Only useful for PvP).'
	});

	autoParry:AddToggle({
		text = 'Roll After Feint',
		tip = 'Automatically roll on the next attack after a feint, only if you on parry cooldown.'
	});

	autoParry:AddToggle({
		text = 'Roll Cancel',
		tip = 'Automatically cancel roll after the autoparry dodges.'
	}):AddSlider({
		text = 'Roll Cancel Delay',
		min = 0,
		max = 1,
		value = 0,
		float = 0.1,
		textpos = 2,
		tip = 'How long the autoparry will wait before cancelling their dodge'
	});

	autoParry:AddToggle({
		text = 'Blatant Roll',
		tip = 'Instantly roll cancels without moving, recommended for use with AP'
	});

	autoParry:AddToggle({
		text = 'Check If Facing Target',
		tip = 'Only parry if you are facing the target.'
	});

	autoParry:AddToggle({
		text = 'Check If Target Face You',
		tip = 'Only parry if you the target is facing you.'
	});

	autoParry:AddToggle({
		text = 'Auto Feint',
		tip = 'This will feint for you if you are mid attack but need to parry, which allows you to parry their attack'
	});

	autoParry:AddToggle({
		text = 'Auto Feint Mantra',
		tip = 'Automatically feint your cast if you are using a mantra and auto parry wants to parry.'
	});

	autoParry:AddToggle({
		text = 'Block Input',
		tip = 'This will prevent you from attacking whenever the opponent is attacking, essentially allowing you to hold M1 with less punishment.'
	});

	autoParry:AddList({
		text = 'Auto Parry Mode',
		values = {'Guild', 'Players', 'Mobs', 'All'},
		tip = 'This will make it so the autoparry will only parry this group of entities, such as mobs, player or guild members.',
		multiselect = true
	});

	autoParry:AddList({
		text = 'Auto Parry Whitelist',
		noload = true,
		skipflag = true,
		playerOnly = true,
		multiselect = true
	});
end;

do -- // Auto Parry Maker
	autoParryMaker:AddToggle({
		text = 'Auto Parry Helper',
		tip = 'Shows the auto parry maker helper.',
		callback = functions.autoParryHelper
	}):AddSlider({
		text = 'Helper Max Range',
		min = 10,
		max = 10000,
		textpos = 2,
	});

	autoParryMaker:AddSlider({
		text = 'Block Point Max Range',
		min = 0,
		max = 1000,
		textpos = 2
	});

	autoParryMaker:AddBox({
		text = 'Animation Id',
		tip = 'Put the animation id you want auto parry helper to parry.',
	});

	autoParryMaker:AddButton({
		text = 'Add Block Point',
		callback = function()
			functions.addBlockPoint(autoParryMaker);
		end,
	});

	autoParryMaker:AddButton({
		text = 'Add Wait Point',
		callback = function()
			functions.addWaitPoint(autoParryMaker);
		end,
	});

	autoParryMaker:AddButton({
		text = 'Export Config',
		callback = functions.exportBlockPoints,
	});

	-- autoParryMaker:AddList({
	-- 	text = 'Confidantiality Level',
	-- 	values = {'Public', 'Private', 'Unlisted'},
	-- 	tip = 'Visibility level for this config.',
	-- });

	autoParryMaker:AddDivider('Block Points');
end;

do -- // Auto Loot
	autoLoot:AddToggle({
		text = 'Auto Loot',
		tip = 'Automatically loot all items from a chest.',
		callback = functions.autoLoot
	});

	autoLoot:AddToggle({
		text = 'Auto Close Chest',
		tip = 'Automatically close chest once auto loot is done.'
	});

	autoLoot:AddToggle({
		text = 'Auto Open Chest',
		tip = 'Automatically open all chest near you.',
		callback = functions.autoOpenChest
	});

	functions.setupAutoLoot(autoLoot);
end;

do -- // Misc
	local realmInfo = require(ReplicatedStorage.Info.RealmInfo);
	local isLuminant = rawget(realmInfo, 'IsLuminant') or false;
	local names = rawget(realmInfo, 'Names') or {};
	local currentWorld = rawget(realmInfo, 'CurrentWorld') or '';

	local oppositeWorld = currentWorld == 'EastLuminant' and 'EtreanLuminant' or 'EastLuminant';

	misc:AddDivider('Perfomance Improvements');

	misc:AddToggle({
		text = 'FPS Boost',
		tip = 'Improves FPS by making game functions faster',
		callback = functions.fpsBoost
	});

	misc:AddToggle({
		text = 'Disable Shadows',
		tip = 'Disabling all shadows adds a large bump to your FPS',
		callback = functions.disableShadows
	});

	misc:AddToggle({
		text = 'Chunk Loader',
		tip = 'Loading multiple locations of the map lags you, the chunk loader will mitigate this',
		callback = functions.chunkLoaderToggle
	}):AddSlider({
		text = 'Render Distance',
		min = 5,
		value = 10,
		max = 25,
		float = 1
	})

	misc:AddDivider("Streamer Tools");

	misc:AddToggle({
		text = 'Streamer Mode',
		tip = 'Locally modify/hide your name so you can record without worying about getting banned.',
		callback = functions.streamerMode
	})

	misc:AddToggle({
		text = 'Ultra Streamer Mode',
		tip = 'Enable that with streamer mode if you are streaming and want nobody to find/join you'
	});

	misc:AddList({
		flag = 'Streamer Mode Type',
		tip = 'Spoof = modifies character info to fake one. Hide = Hide character info',
		values = {'Spoof', 'Hide'},
		callback = function()
			functions.streamerMode(library.flags.streamerMode);
		end
	});

	misc:AddToggle({
		text = 'Hide All Server Info',
		tip = 'Enable that with streamer mode if dont want any server info on top bar'
	});

	misc:AddToggle({
		text = 'Hide Esp Names'
	});

	misc:AddButton({
		text = 'Rebuild Streamer Mode',
		callback = functions.rebuildStreamerMode,
		noload = true,
		skipflag = true,
		tip = 'Rebuild streamer mode fake info.',
	})

	misc:AddDivider('Chat Logger', 'You can right click the chatlogger to report infractions.');

	misc:AddToggle({
		text = 'Chat Logger',
		tip = 'You can right click users on the chat logger to report them for infractions to the TOS',
		callback = functions.chatLogger
	});

	misc:AddToggle({
		text = 'Chat Logger Auto Scroll'
	});

	misc:AddToggle({
		text = 'Use Alt Manager To Block'
	});

	misc:AddDivider('Race Changer');

	-- Setup race changer
	local raceChanger = sharedRequire('@games/DeepWokenRaceChanger.lua');
	raceChanger(misc);
end;

do -- // Visuals
	visuals:AddToggle({
		text = 'No Fog',
		callback = functions.noFog
	});

	visuals:AddToggle({
		text = 'No Blur',
		callback = functions.noBlur
	});

	visuals:AddToggle({
		text = 'No Blind',
		callback = functions.noBlind
	});

	visuals:AddToggle({
		text = 'Full Bright'
	}):AddSlider({
		flag = 'Full Bright Value',
		min = 0,
		max = 10,
		value = 1,
	});
end;

do -- // Farms
	farms:AddToggle({
		text = 'Fort Merit Farm',
		callback = functions.fortMeritFarm
	});

	farms:AddToggle({
		text = 'Echo Farm',
		tip = 'This will automatically farm cooked meals for echoes, you need to have echoes unlocked to use this.',
		callback = functions.echoFarm
	});

	farms:AddToggle({
		text = 'Animal King Farm',
		tip = 'This will automatically farm for AK, requires you to have Trial Of One spawn unlocked, you can wipe with animal king and keep it before level 3',
		callback = functions.animalKingFarm
	});

	farms:AddToggle({
		text = 'Ores Farm',
		tip = 'This will only farm Astruline, use near a section of astruline for it to work',
		callback = functions.oresFarm
	});

	farms:AddButton({
		text = 'Set Ores Farm Position',
		tip = 'Use this before using Ores Farm to set the position that you will farm at',
		callback = functions.setOresFarmPosition
	});

	farms:AddBox({
		text = 'Ores Farm Webhook Notifier'
	});

	farms:AddBox({
		text = 'Animal King Webhook Notifier'
	});

	farms:AddToggle({
		text = 'Charisma Farm',
		callback = functions.charismaFarm
	});

	farms:AddToggle({
		text = 'Intelligence Farm',
		callback = functions.intelligenceFarm
	});

	farms:AddToggle({
		text = 'Auto Fish',
		flag = 'Fish Farm',
		callback = functions.fishFarm
	}):AddSlider({
		text = 'Auto Fish Hold Time',
		flag = 'Fish Farm Hold Time',
		min = 0.1,
		max = 2,
		float = 0.1,
		value = 0.5,
		textpos = 2
	});

	farms:AddBox({
		text = 'Fish Farm Bait',
		tip = 'Set the bait for the fish farm, you can leave this box empty if you dont want to use any you can also add multiple bait with ,.',
	});
end;

-- do -- // Analytics
-- 	local lootDropAnalytics = AnalyticsAPI.new('');

-- 	local function getProperties(obj, t)
-- 		local propertiesToLog = t;
-- 		local properties = {};

-- 		for _, v in next, propertiesToLog do
-- 			table.insert(properties, string.format('%s = %s', v, tostring(obj[v])));
-- 		end;

-- 		return table.concat(properties, '|');
-- 	end;

-- 	library.unloadMaid:GiveTask(Utility.listenToTagAdded('LootDrop', function(obj)
-- 		local isMesh = IsA(obj, 'MeshPart');

-- 		if (IsA(obj, 'Part') or isMesh) then
-- 			local properties = getProperties(obj, {'Size', 'Material', 'Color', isMesh and 'MeshId' or nil});
-- 			lootDropAnalytics:Report(isMesh and 'MeshPart' or 'Part', properties, 1);
-- 		elseif (IsA(obj, 'UnionOperation')) then
-- 			local id = getproperties(obj).AssetId;

-- 			local properties = getProperties(obj, {'Size', 'Material', 'Color'});
-- 			table.insert(properties, 'AssetId = ' .. tostring(id));

-- 			lootDropAnalytics:Report('UnionOperation', tostring(id), 1);
-- 		end;
-- 	end));
-- end;