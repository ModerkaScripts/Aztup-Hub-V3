SX_VM_CNONE();
local Maid = sharedRequire('Maid.lua');
local Services = sharedRequire('Services.lua');

local toCamelCase = sharedRequire('toCamelCase.lua');
local library = sharedRequire('../UILibrary.lua');

local Players, CorePackages, HttpService = Services:Get('Players', 'CorePackages', 'HttpService');
local LocalPlayer = Players.LocalPlayer;

local NUM_ACTORS = 8;

--[[
	We'll add an example cuz I have no brain

	local chestsESP = createBaseESP('chests'); -- This is the base ESP it returns a class with .new, .Destroy, :UpdateAll, :UnloadAll, and some other stuff

	-- Listen to chests childAdded through Utility.listenToChildAdded and then create an espObject for that chest
	-- chestsESP.new only accepts BasePart or CFrame
	-- It has a lazy parameter allowing it to not update the get the position everyframe only get the screen position
	-- Also a color parameter

	Utility.listenToChildAdded(workspace.Chests, function(obj)
		local espObject = chestsESP.new(obj, 'Normal Chest', color, isLazy);

		obj.Destroying:Connect(function()
			espObject:Destroy();
		end);
	end);

	local function updateChestESP(toggle)
		if (not toggle) then
			maid.chestESP = nil;
			chestsESP:UnloadAll();
			return;
		end;

		maid.chestESP = RunService.Stepped:Connect(function()
			chestsESP:UpdateAll();
		end);
	end;

	-- UI Lib functions
	:AddToggle({text = 'Enable', flag = 'chests', callback = updateChestESP});
	:AddToggle({text = 'Show Distance', textpos = 2, flag = 'Chests Show Distance'});
	:AddToggle({text = 'Show Normal Chest'}):AddColor({text = 'Normal Chest Color'}); -- Filer for if you want to see that chest and select the color of it
]]

local playerScripts = LocalPlayer:WaitForChild('PlayerScripts')

local playerScriptsLoader = playerScripts:FindFirstChild('PlayerScriptsLoader');
local actors = {};

local readyCount = 0;
local broadcastEvent = Instance.new('BindableEvent');

local supportedGamesList = HttpService:JSONDecode(sharedRequire('../../gameList.json'));
local gameName = supportedGamesList[tostring(game.GameId)];

if (not playerScriptsLoader and gameName == 'Apocalypse Rising 2') then
	playerScriptsLoader = playerScripts:FindFirstChild('FreecamDelete');
end;

if (playerScriptsLoader) then
	for _ = 1, NUM_ACTORS do
		local commId, commEvent;

		if (isSynapseV3) then
			commEvent = {
				_event = Instance.new('BindableEvent'),

				Connect = function(self, f)
					return self._event.Event:Connect(f)
				end,

				Fire = function(self, ...)
					self._event:Fire(...);
				end
			};
		else
			commId, commEvent = getgenv().syn.create_comm_channel();
		end;

		local clone = playerScriptsLoader:Clone();
		local actor = Instance.new('Actor');
		clone.Parent = actor;

		local playerModule = CorePackages.InGameServices.MouseIconOverrideService:Clone();
		playerModule.Name = 'PlayerModule';
		playerModule.Parent = actor;

		if (not isSynapseV3) then
			syn.protect_gui(actor);
		end;

		actor.Parent = LocalPlayer.PlayerScripts;

		local connection;

		connection = commEvent:Connect(function(data)
			if (data.updateType == 'ready') then
				commEvent:Fire({updateType = 'giveEvent', event = broadcastEvent, gameName = gameName});
				actor:Destroy();

				readyCount += 1;

				connection:Disconnect();
				connection = nil;
			end;
		end);

		originalFunctions.runOnActor(actor, sharedRequire('@utils/createBaseESPParallel.lua'), commId or commEvent);
		table.insert(actors, {
			actor = actor,
			commEvent = commEvent
		});
	end;

	print('Waiting for actors');
	repeat task.wait(); until readyCount >= NUM_ACTORS;
	print('All actors have been loaded');
else
	local commId, commEvent = getgenv().syn.create_comm_channel();

	local connection;
	connection = commEvent:Connect(function(data)
		if (data.updateType == 'ready') then
			connection:Disconnect();
			connection = nil;

			commEvent:Fire({updateType = 'giveEvent', event = broadcastEvent});
		end;
	end);

	loadstring(sharedRequire('@utils/createBaseESPParallel.lua'))(commId);

	table.insert(actors, {commEvent = commEvent});
	readyCount = 1;
end;

local count = 1;

local function createBaseEsp(flag, container)
	container = container or {};
	local BaseEsp = {};

	BaseEsp.ClassName = 'BaseEsp';
	BaseEsp.Flag = flag;
	BaseEsp.Container = container;
	BaseEsp.__index = BaseEsp;

	local whiteColor = Color3.new(1, 1, 1);

	local maxDistanceFlag = BaseEsp.Flag .. 'MaxDistance';
	local showHealthFlag = BaseEsp.Flag .. 'ShowHealth';
	local showESPFlag = BaseEsp.Flag;

	function BaseEsp.new(instance, tag, color, isLazy)
		assert(instance, '#1 instance expected');
		assert(tag, '#2 tag expected');

		local isCustomInstance = false;

		if (typeof(instance) == 'table' and rawget(instance, 'code')) then
			isCustomInstance = true;
		end;

		color = color or whiteColor;

		local self = setmetatable({}, BaseEsp);
		self._tag = tag;

		local displayName = tag;

		if (typeof(tag) == 'table') then
			displayName = tag.displayName;
			self._tag = tag.tag;
		end;

		self._instance = instance;
		self._text = displayName;
		self._color = color;
		self._showFlag = toCamelCase('Show ' .. self._tag);
		self._colorFlag = toCamelCase(self._tag .. ' Color');
		self._colorFlag2 = BaseEsp.Flag .. 'Color';
		self._showDistanceFlag = BaseEsp.Flag .. 'ShowDistance';
		self._isLazy = isLazy;
		self._actor = actors[(count % readyCount) + 1];
		self._id = count;
		self._maid = Maid.new();

		count += 1;

		if (isLazy and not isCustomInstance) then
			self._instancePosition = instance.Position;
		end;

		self._maxDistanceFlag = maxDistanceFlag;
		self._showHealthFlag = showHealthFlag;

		if (isCustomInstance) then
			self._isCustomInstance = true;
			self._code = instance.code;
			self._vars = instance.vars;
		end;

		local smallData = table.clone(self);
		smallData._actor = nil;
		self._actor.commEvent:Fire({
			updateType = 'new',
			data = smallData,
			isCustomInstance = isCustomInstance,
			showFlag = showESPFlag
		});


		return self;
	end;

	function BaseEsp:Unload() end;
	function BaseEsp:BaseUpdate() end;
	function BaseEsp:UpdateAll() end;
	function BaseEsp:Update() end;
	function BaseEsp:UnloadAll() end;
	function BaseEsp:Disable() end;

	function BaseEsp:Destroy()
		self._maid:Destroy();
		self._actor.commEvent:Fire({
			updateType = 'destroy',
			id = self._id
		});
	end;

	return BaseEsp;
end;

library.OnFlagChanged:Connect(function(data)
	broadcastEvent:Fire({
		type = data.type,
		flag = data.flag,
		color = data.color,
		state = data.state,
		value = data.value
	});
end);

return createBaseEsp;