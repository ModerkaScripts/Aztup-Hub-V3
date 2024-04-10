--// Defining Variables / Grabbing Data

local library = sharedRequire('../UILibrary.lua');
local Services = sharedRequire('../utils/Services.lua');
local ToastNotif = sharedRequire('../classes/ToastNotif.lua');
local Webhook = sharedRequire('@utils/Webhook.lua');

local ReplicatedStorage, Players, RunService, UserInputService, MemStorageService, TeleportService, NetworkClient, GuiService = Services:Get('ReplicatedStorage', 'Players', 'RunService', 'UserInputService', 'MemStorageService', 'TeleportService', 'NetworkClient', 'GuiService');
local column1, column2 = unpack(library.columns);

local fsysModule = ReplicatedStorage.Fsys;

print('we wait for sys');
repeat
	task.wait();
until table.find(getloadedmodules(), fsysModule);

local fsys = require(fsysModule);
local LocalPlayer = Players.LocalPlayer;

local function rejoinServer()
	library:UpdateConfig();

	while (true) do
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId);
		GuiService:ClearError();
		task.wait(5);
	end;
end;

task.spawn(function()
	while task.wait(1) do
		if (not NetworkClient:FindFirstChild('ClientReplicator')) then
			rejoinServer();
			break;
		end;
	end;
end);

local  function loader(name)
	local cache = getupvalue(fsys.load, 1);
	print('waiting for', name);

	repeat
		task.wait();
	until typeof(cache[name]) == 'table';

	return cache[name];
end;

local routerClient = loader('RouterClient');
local interiorsM = loader('InteriorsM');
local clientData = loader('ClientData')
local obbyList = loader('ObbyDB')
local petsDB = loader('InventoryPetsSubDB').entries;
local door = loader('Door');

local uiManager = loader('UIManager');
local inventory = clientData.get('inventory')

print('waiting for loadedIn');
repeat
	task.wait();
until clientData.get('loaded_in');

local remotes = getupvalue(getfenv(routerClient.get).get_remote_from_cache, 1);

local doorMT = getupvalue(door.new, 1);
local oldEnter = doorMT.enter;

oldEnter = hookfunction(oldEnter, function(...)
	if (library.flags.petFarm) then return end;
	return oldEnter(...);
end);

library.OnLoad:Connect(function()
	if (not LocalPlayer.Character) then
		remotes['TeamAPI/ChooseTeam']:InvokeServer(library.flags.switchTeam);
		uiManager.set_app_visibility('MainMenuApp', false);
		uiManager.set_app_visibility('NewsApp', false);
	end;
end);

--// Functions

local funcs = {};

function funcs.setDataloss()
	originalFunctions.invokeServer(remotes['RadioAPI/Add'], '\128', 123);
	ToastNotif.new({text = 'Dataloss set, anything after this point won\'t save'});
end;

function funcs.unsetDataloss()
	originalFunctions.invokeServer(remotes['RadioAPI/Remove'], 123);
	ToastNotif.new({text = 'Dataloss unset!'});
end;

local function teleportTo(location, door, data)
	syn.set_thread_identity(2);
	interiorsM.enter(location, door, data);
	syn.set_thread_identity(7);
end;

local function getFood(id)
	for _, v in next, inventory.food do
		if not id or v.id == id then
			return v.unique;
		end;
	end;
end;

local function getFurniture(Name)
	for _, v in next, workspace.HouseInteriors.furniture:GetChildren() do
		local Model = v:FindFirstChildOfClass('Model');
		local useId = Model and Model:FindFirstChild('UseBlocks') and Model:FindFirstChildWhichIsA('StringValue', true)

		if useId and useId.Name == 'use_id' and useId.Value == Name then
			return v:FindFirstChildWhichIsA('Model'):GetAttribute('furniture_unique');
		end;
	end;
end;

local function isInMainMap()
	return interiorsM:get_current_location().destination_id == 'MainMap';
end;

local function isInNursery()
	return interiorsM:get_current_location().destination_id == 'Nursery';
end;

local Autofarm = column1:AddSection('Autofarm');
local Misc = column1:AddSection('Misc');
local Local = column2:AddSection('Local');

local petsToFarm = {};

coroutine.wrap(function()
	while true do
		table.clear(petsToFarm);
		inventory = clientData.get('inventory');
		if (not inventory or not inventory.pets) then task.wait(); continue end;

		for _, v in next, inventory.pets do
			table.insert(petsToFarm, v.id .. ' | age: ' .. tostring(v.properties.age));
		end;

		task.wait(1);
	end;
end)();

local currentPet;
local stores = {'CoffeeShop', 'Supermarket', 'PizzaPlace', 'ToyShop', 'Obbies', 'Neighborhood', 'CampingShop', 'AutoShop', 'Nursery', 'Cave', 'IceCream', 'PotionShop', 'SkyCastle', 'Hospital', 'HatShop', 'PetShop', 'School', 'BabyShop', 'HotSpringHouse', 'SafetyHub', 'DebugInterior'};

local function onAilmentAdded(ailment)
	if ailment:IsA('Frame') then
		remotes['MonitorAPI/AddRate']:InvokeServer(ailment.Name, 100);
	end;
end;

Autofarm:AddToggle({text = 'Pet Farm'});

Autofarm:AddList({
	text = 'Pet to Farm',
	values = petsToFarm,
	callback = function(value)
		for i, v in next, inventory.pets do
			if v.id .. ' | age: ' .. tostring(v.properties.age) == value then
				currentPet = v;
			end;
		end;
	end;
});

local wantedPets = {};

for _, v in next, petsDB do
    if (v.rarity == 'legendary' and not v.is_egg and not v.origin_entry.robux) then
		table.insert(wantedPets, v.name);
    end;
end;

table.sort(wantedPets, function(a, b) return a < b end);
Autofarm:AddList({text = 'Wanted Pets', values = wantedPets, multiselect = true});

Autofarm:AddToggle({text = 'Farm All Pets'})
Autofarm:AddToggle({text = 'Farm Until Full Grown'});

Autofarm:AddToggle({
	text = 'No Rendering',
	callback = function(t) RunService:Set3dRenderingEnabled(not t) end
})

Autofarm:AddToggle({
	text = 'Baby Farm',
	callback = function(value)
		if value then
			for _, ailment in next, LocalPlayer.PlayerGui.AilmentsMonitorApp.Ailments:GetChildren() do
				onAilmentAdded(ailment);
			end;
		end;
	end;
});

Autofarm:AddBox({text = 'Webhook Url'});
Autofarm:AddToggle({text = 'Auto Paycheck'});

Misc:AddButton({
	text = 'Complete All Obbies',
	callback = function()
		for i in next, obbyList do
			remotes['MinigameAPI/FinishObby']:FireServer(i);
		end;
	end
});

Local:AddSlider({
	text = 'Walk Speed',
	textpos = 2,
	min = 16,
	max = 200,
	default = 16
});

Local:AddSlider({
	text = 'Jump Height',
	textpos = 2,
	min = 50,
	max = 200,
	default = 50
});

Local:AddToggle({
	text = 'Noclip'
});

Local:AddButton({
	text = 'Teleport to Main Map',
	callback = function()
		teleportTo('MainMap', 'Neighborhood/MainDoor', {});
	end
});

Local:AddButton({
	text = 'Teleport to Home',
	callback = function()
		teleportTo('housing', 'MainDoor', {
			['house_owner'] = LocalPlayer
		});
	end
});

Local:AddList({
	text = 'Teleport to Store',
	values = stores,
	noload = true,
	skipflag = true,
	callback = function(value)
		if not isInMainMap() then
			teleportTo('MainMap', 'Neighborhood/MainDoor', {});
			repeat task.wait() until isInMainMap();
		end;

		teleportTo(value, 'MainDoor', {});
	end
});

Misc:AddButton({
	text = 'Set Dataloss',
	callback = funcs.setDataloss
});

Misc:AddButton({
	text = 'Remove Dataloss',
	callback = funcs.unsetDataloss
});

Misc:AddButton({
	text = 'Make Pets Flyable',
	callback = function()
		for _, v in next, inventory.pets do
			v.properties.flyable = true;
		end;
	end
});

Misc:AddButton({
	text = 'Make Pets Rideable',
	callback = function()
		for _, v in next, inventory.pets do
			v.properties.rideable = true;
		end;
	end
});

Misc:AddList({
	text = 'Switch Team',
	values = {'Babies','Parents'},
	noload = true,
	skipflag = true,
	callback = function(team)
		remotes['TeamAPI/ChooseTeam']:InvokeServer(team, true);
	end
});

local function getPetId()
	if not library.flags.farmAllPets then
		return currentPet and currentPet.unique;
	end;

	local allPets = {};

	for _, pet in next, inventory.pets do
		if (pet.properties.age == 6) then continue end;
		local isEgg = petsDB[pet.id].is_egg;

		if (isEgg) then
			table.insert(allPets, {
				properties = {age = 0},
				id = pet.id,
				unique = pet.unique
			});

			continue;
		end;

		table.insert(allPets, pet);
	end;

	if (library.flags.farmUntilFullGrown) then
		table.sort(allPets, function(a, b)
			return a.unique < b.unique;
		end);

		print('we return', allPets[1] and allPets[1].unique);
		return allPets[1] and allPets[1].unique;
	end;

	table.sort(allPets, function(a, b)
		return a.properties.age < b.properties.age;
	end);

	local lowestAge = allPets[1] and allPets[1].properties.age;
	if (not lowestAge) then return end;

	local smallestAgePets = {};

	for _,  pet in next, allPets do
		if (pet.properties.age == lowestAge) then
			table.insert(smallestAgePets, pet);
		end;
	end;

	table.sort(smallestAgePets, function(a, b)
		return a.unique < b.unique;
	end);

	return smallestAgePets[1].unique;
end;

--// Pet Farm Action Functions

local Actions = {
	hungry = function(data)
		local food = getFood();

		if not food then
			print('no food buying food');

			repeat
				remotes['ShopAPI/BuyItem']:InvokeServer('food', 'apple', {});
				task.wait(1);
			until getFood();

			print('bought food');
		else
			print('food found');
		end

		food = getFood()
		if not food then
			print('no food :(');
			return
		end

		print('equip food');
		remotes['ToolAPI/Equip']:InvokeServer(food);
		print('consume food');
		remotes['PetAPI/ConsumeFoodItem']:FireServer(food);

		local ranAt = tick();

		repeat
			task.wait();
		until data.progress == 1 or tick() - ranAt > 60;
	end,

	pizza_party = function(data)
		teleportTo('PizzaShop', 'MainDoor', {});

		local ranAt = tick();

		repeat
			task.wait();
		until data.progress == 1 or tick() - ranAt > 60;
	end,

	pool_party = function(data)
		teleportTo('MainMap', 'Neighborhood/MainDoor', {});

		local poolSiteCF = workspace:WaitForChild('StaticMap'):WaitForChild('Pool'):WaitForChild('PoolOrigin');
		local ranAt = tick();

		pcall(function()
			LocalPlayer.Character:SetPrimaryPartCFrame(poolSiteCF.CFrame * CFrame.new(0, 5, 0));
		end);

		repeat
			task.wait();
		until data.progress == 1 or tick() - ranAt > 60;
	end,

	salon = function(data)
		teleportTo('Salon', 'MainDoor', {});

		local ranAt = tick();

		repeat
			task.wait();
		until data.progress == 1 or tick() - ranAt > 60;
	end,

	dirty = function(data, pet)
		teleportTo('housing', 'MainDoor', {
			['house_owner'] = LocalPlayer
		})

		repeat task.wait() until getFurniture('generic_shower')

		task.spawn(function()
			remotes['HousingAPI/ActivateFurniture']:InvokeServer(LocalPlayer, getFurniture('generic_shower'), 'UseBlock', {
				['cframe'] = LocalPlayer.Character.PrimaryPart.CFrame
			}, pet)
		end)

		local ranAt = tick();

		repeat
			task.wait()
		until data.progress == 1 or tick() - ranAt > 60;

		local PetID = getPetId()

		remotes['ToolAPI/Unequip']:InvokeServer(PetID)
		remotes['ToolAPI/Equip']:InvokeServer(PetID)
	end,

	sleepy = function(data, pet)
		print('doing sleepy tp');
		repeat
			teleportTo('housing', 'MainDoor', {
				['house_owner'] = LocalPlayer
			})
			task.wait(1)
		until getFurniture('generic_crib');
		print('teleported!, using furniture and waiting for task to finish');

		task.spawn(function()
			remotes['HousingAPI/ActivateFurniture']:InvokeServer(LocalPlayer, getFurniture('generic_crib'), 'UseBlock', {
				['cframe'] = LocalPlayer.Character.PrimaryPart.CFrame
			}, pet)
		end)

		local ranAt = tick();

		repeat
			task.wait()
		until data.progress == 1 or tick() - ranAt > 60;
		print('task finished or timedout');

		local petId = getPetId();
		remotes['ToolAPI/Unequip']:InvokeServer(petId);
		remotes['ToolAPI/Equip']:InvokeServer(petId);
	end,

	bored = function(data)
		teleportTo('MainMap', 'Neighborhood/MainDoor', {})

		local BoredAilmentTarget = workspace:WaitForChild('StaticMap'):WaitForChild('Park'):WaitForChild('BoredAilmentTarget')
		local ranAt = tick();

		repeat
			pcall(function()
				LocalPlayer.Character:SetPrimaryPartCFrame(BoredAilmentTarget.CFrame * CFrame.new(0, 5, 0));
			end);

			RunService.Heartbeat:Wait();
		until data.progress == 1 or tick() - ranAt > 60;
	end,

	thirsty = function(data, Pet)
		repeat
			teleportTo('Nursery', 'MainDoor', {});
			task.wait(1);
		until isInNursery();

		local rootPart = LocalPlayer.Character and LocalPlayer.Character:WaitForChild('HumanoidRootPart', 10);
		if (not rootPart) then return end;

		task.wait(2);

		local ranAt = tick();

		repeat
			print('we fire it');
			task.spawn(function()
				remotes['HousingAPI/ActivateInteriorFurniture']:InvokeServer('f-8', 'UseBlock', {
					cframe = rootPart.CFrame
				}, Pet);
			end);

			task.wait(10);
		until data.progress == 1 or tick() - ranAt > 60;

		local petId = getPetId();

		remotes['ToolAPI/Unequip']:InvokeServer(petId);
		remotes['ToolAPI/Equip']:InvokeServer(petId);

		task.wait(2);
	end,

	sick = function(data)
		teleportTo('Hospital', 'MainDoor', {});
		local ranAt = tick();

		repeat
			remotes['MonitorAPI/HealWithDoctor']:FireServer();
			task.wait(1);
		until data.progress == 1 or tick() - ranAt > 60;
	end,

	adoption_party = function(data)
		teleportTo('Nursury', 'MainDoor', {});
		local ranAt = tick();

		repeat
			task.wait();
		until data.progress == 1 or tick() - ranAt > 60;
	end,

	school = function(data)
		teleportTo('School', 'MainDoor', {});
		local ranAt = tick();

		repeat
			task.wait();
		until data.progress == 1 or tick() - ranAt > 60;
	end,

	hot_spring = function(data)
		teleportTo('MainMap', 'Neighborhood/MainDoor', {});

		local hotSpringCF = workspace:WaitForChild('StaticMap'):WaitForChild('HotSpring'):WaitForChild('HotSpringOrigin')
		local ranAt = tick();

		pcall(function()
			LocalPlayer.Character:SetPrimaryPartCFrame(hotSpringCF.CFrame * CFrame.new(0, 5, 0));
		end);

		repeat
			task.wait();
		until data.progress == 1 or tick() - ranAt > 60;
	end,

	camping = function(data)
		teleportTo('MainMap', 'Neighborhood/MainDoor', {});

		local campSiteCF = workspace:WaitForChild('StaticMap'):WaitForChild('Campsite'):WaitForChild('CampsiteOrigin');
		local ranAt = tick();

		pcall(function()
			LocalPlayer.Character:SetPrimaryPartCFrame(campSiteCF.CFrame * CFrame.new(0, 5, 0));
		end);

		repeat
			task.wait();
		until data.progress == 1 or tick() - ranAt > 60;
	end
};

--// Pet Farm Loop

local function calculateNeeded(ailments,percentage)
	return math.ceil(ailments/percentage);
end;

coroutine.wrap(function()
	while task.wait(1) do
		if (not library.flags.petFarm) then continue end;
		inventory = clientData.get('inventory');

		local petCharWrapper = clientData.get('pet_char_wrapper');
		local equipManager = clientData.get('equip_manager');

		local autoDataLoss = library.flags.autoDataloss;

		if (not equipManager) then
			print('no equip manager!');
			continue;
		end

		local petId = getPetId();
		local currentEquipedPet = equipManager.pets;

		if not currentEquipedPet or currentEquipedPet.unique ~= petId or not petCharWrapper then
			remotes['ToolAPI/Unequip']:InvokeServer(petId);
			remotes['ToolAPI/Equip']:InvokeServer(petId);
		end;

		currentEquipedPet = equipManager.pets;

		if (not currentEquipedPet or not currentEquipedPet.properties) then
			print('no currentEquipedPet');
			continue;
		end;

		local ailmentsCompleted = currentEquipedPet.properties.ailments_completed;
		if (not ailmentsCompleted) then print('no ailment completed'); continue end;

		if (not petCharWrapper or not petCharWrapper.ailments_monitor or not petCharWrapper.ailments_monitor.ailments) then print('no pet char wrapper'); continue end;

		local percentage = petCharWrapper.pet_progression.percentage;
		if (not percentage) then continue end;

		local willHatch = calculateNeeded(ailmentsCompleted, percentage)-1 == ailmentsCompleted;
		local isEgg = petsDB[currentEquipedPet.id].is_egg;
		print(isEgg, ailmentsCompleted, willHatch, percentage, calculateNeeded(ailmentsCompleted, percentage));
		if (isEgg and ailmentsCompleted > 0 and willHatch and not MemStorageService:HasItem(petId) and autoDataLoss) then
			print('we rejoin server');
			MemStorageService:SetItem(petId, 'true');
			rejoinServer();
			continue;
		end;

		local function getAllAilments(noMT)
			-- This function is really bad but we have to do this cause the game keeps replacing the table
			local ailments = {};

			for _, ailmentData in next, uiManager.apps.AilmentsMonitorApp.ailments_data do
				for _, prop in next, ailmentData.props.babies do
					if (not prop.is_pet) then continue end;
					if (noMT) then
						table.insert(ailments, prop);
						continue;
					end;

					prop = table.clone(prop);
					prop.progress = nil;

					setmetatable(prop, {
						__index = function(self, p)
							if (p == 'progress') then
								for _, ailment in next, getAllAilments(true) do
									if (ailment.unique == prop.unique) then
										print('we returned', ailment.progress);
										return ailment.progress;
									end;
								end;

								print('we dont find it!, prob got removed');
								return 1;
							end;

							return rawget(self, p);
						end
					});

					table.insert(ailments, prop);
				end;
			end;

			return ailments;
		end;

		local ailments = getAllAilments();

		local function getAilment()
			for _, v in next, ailments do
				if (v.id == 'sleepy') then
					return v;
				end;
			end;

			return ailments[1];
		end;

		local ailment = getAilment();
		if (not ailment) then print('no ailment') continue end;
		if (not Actions[ailment.id]) then print('UH ???') continue end;

		if (willHatch and autoDataLoss) then
			print('ON Y VA?');
			funcs.setDataloss();

			task.spawn(function()
				print('pet will hatch, waiting for it to hatch');
				local _, pet = remotes['PetAPI/OwnedEggHatched'].OnClientEvent:Wait();

				print('webhook send', library.flags.webhookUrl);

				if (library.flags.wantedPets[pet.name]) then
					Webhook.new(library.flags.webhookUrl):Send(string.format('@everyone You got a %s %s', pet.rarity, pet.name), true);

					-- disdplay webhook notif;
					funcs.unsetDataloss();
				else
					Webhook.new(library.flags.webhookUrl):Send(string.format('You got a unwanted %s %s', pet.rarity, pet.name), true);
				end;

				print('pet hatched!', pet.name, pet.id, pet.rarity);
				task.wait(1);
				rejoinServer();
			end);
		end;

		print('going for' .. ailment.id .. '\n', equipManager.pets, equipManager.pets.id);
		Actions[ailment.id](ailment, petCharWrapper.char);
		task.wait(2.5);

		if (willHatch and autoDataLoss) then
			print('stopped');
			return;
		end;
	end;
end)();

--// Baby Farm

LocalPlayer.PlayerGui.AilmentsMonitorApp.Ailments.ChildAdded:Connect(function(ailment)
	if library.flags.babyFarm then
		onAilmentAdded(ailment);
	end;
end);

--// Auto Paycheck

coroutine.wrap(function()
	while task.wait(1) do
		if library.flags.autoPayCheck then
			remotes['PayAPI/CashOut']:InvokeServer();
		end;
	end;
end)();

--// Local Stuff Loop

UserInputService.JumpRequest:Connect(function()
	if library.flags.infiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid') then
		LocalPlayer.Character.Humanoid:ChangeState('Jumping');
	end;
end);

RunService.Stepped:Connect(function()
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid') and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
		LocalPlayer.Character.Humanoid.WalkSpeed = library.flags.walkSpeed;
		LocalPlayer.Character.Humanoid.JumpPower = library.flags.jumpHeight;

		if (not library.flags.noclip or library.flags.petFarm) then return end;

		for _, v in next, LocalPlayer.Character:GetChildren() do
			if v:IsA('BasePart') then
				v.CanCollide = false;
			end;
		end;
	end;
end);