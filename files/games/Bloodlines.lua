local HttpService = game:GetService("HttpService")
local library = sharedRequire('../UILibrary.lua');
local Services = sharedRequire('../utils/Services.lua');
local Maid = sharedRequire('../utils/Maid.lua');
local Utility = sharedRequire('../utils/Utility.lua');
local createBaseESP = sharedRequire('../utils/createBaseESP.lua');

local TextLogger = sharedRequire('../classes/TextLogger.lua');
local ToastNotif = sharedRequire('../classes/ToastNotif.lua');
local ControlModule = sharedRequire('../classes/ControlModule.lua');

-- Services
local Players, ReplicatedStorage, RunService, Lighting, MemStorageService, TeleportService = Services:Get('Players', 'ReplicatedStorage', 'RunService', 'Lighting', 'MemStorageService', 'TeleportService');
local MAIN_PLACE_ID = 10266164381;

if (game.PlaceId ~= MAIN_PLACE_ID) then
    return ToastNotif.new({text = 'Script will not run in lobby.'});
end

-- UI Init
local column1, column2 = unpack(library.columns);

local localCheats = column1:AddSection('Local Cheats');
local visualCheats = column1:AddSection('Visual Cheats');
local riskyCheats = column2:AddSection('Risky Cheats');
local teleportCheats = column2:AddSection('Teleport Cheats');
local miscCheats = column2:AddSection('Misc Cheats');

-- Utility Functions
local IsA = game.IsA;

-- Variables
local chatLogger = TextLogger.new({
	title = 'Chat Logger',
	-- buttons = {'Spectate', 'Copy Username', 'Copy User Id', 'Copy Text'}
});

local localPlayer = Players.LocalPlayer;

local funcs = {};

local maid = Maid.new();
local remotes = ReplicatedStorage.Events;
local dataEvent, dataFunction = remotes.DataEvent, remotes.DataFunction;

local gameManager = require(ReplicatedStorage.GameManager);
local localPlayerData = Utility:getPlayerData();

local chakraPoints = {};
local npcs = {};
local purchasableItems = {};

local loadSound;
local inDanger = false;

-- Functions
do
    -- Anti Cheat Bypass / No Fall Damage
    do
        local oldNamecall;

        local function fireServerHook(remote, action, ...)
            if (remote == dataEvent and string.lower(action) == 'banme') then
                return warn('No No No');
            end;

            return oldNamecall(remote, action, ...);
        end;

        oldNamecall = hookmetamethod(game, '__namecall', function(self, ...)
            SX_VM_CNONE();
            local method = getnamecallmethod();

            if ((method == 'fireServer' or method == 'FireServer') and IsA(self, 'RemoteEvent') and self == dataEvent) then
                return fireServerHook(self, ...);
            elseif (method == 'FindFirstChild') then
                local args = {...};
                if (args[1] == 'NegateFall' and library.flags.noFallDamage) then
                    print('no fall damage haha');
                    return true;
                end;
            end;

            return oldNamecall(self, ...);
        end);
    end;

    -- Remove Kill Bricks
    do
        local KILL_BRICKS_NAMES = {'LavarossaVoid', 'Void'};
        local killBricks = {};

        local function onChildAdded(object)
            if (not table.find(KILL_BRICKS_NAMES, object.Name)) then return end;

            table.insert(killBricks, {
                part = object,
                oldParent = object.Parent
            });

            if (library.flags.noKillBricks) then
                object.Parent = nil;
            end;
        end;

        function funcs.noKillBricks(state)
            for _, killBrick in next, killBricks do
                killBrick.part.Parent = not state and killBrick.oldParent or nil;
            end;
        end;

        library.OnLoad:Connect(function()
            for _, v in next, workspace:GetDescendants() do
                if (table.find(KILL_BRICKS_NAMES, v.Name)) then
                    task.spawn(onChildAdded, v);
                end;
            end;

            workspace.DescendantAdded:Connect(onChildAdded);
        end);
    end;

    -- Chat Logger
    do
        local function onPlayerChatted(player, message)
            local timeText = DateTime.now():FormatLocalTime('H:mm:ss', 'en-us');
            local playerName = player.Name;
            local playerIngName = player:GetAttribute('CharacterName') or 'N/A';

            message = ('[%s] [%s] [%s] %s'):format(timeText, playerName, playerIngName, message);

            local textData = chatLogger:AddText({
                text = message,
                player = player
            });
        end;

        ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(messageData)
            local player, message = Players:FindFirstChild(messageData.FromSpeaker), messageData.Message;
            if (not player or not message) then return end;

            onPlayerChatted(player, message);
        end);

        function funcs.chatLogger(state)
            chatLogger:SetVisible(state);
        end;

        chatLogger.OnUpdate:Connect(function(updateType, vector)
            library.configVars['chatLogger' .. updateType] = tostring(vector);
        end);

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
    end;

    -- Danger Check
    do
        dataEvent.OnClientEvent:Connect(function(eventType, ...)
            if (eventType == 'InDanger') then
                inDanger = true;
            elseif (eventType == 'OutOfDanger') then
                inDanger = false;
            end;
        end);
    end

    -- Danger Checks Features (Reset Character, Instant Log)
    do
        function funcs.resetCharacter()
            local character = localPlayerData.character;
            if (not character) then return end;

            if (library:ShowConfirm('Are you sure you want to reset character?')) then
                character:BreakJoints();
            end;
        end;

        function funcs.instantLog()
            if (inDanger) then return ToastNotif.new({text = 'You can not do this right now. You are in danger.'}) end;

            localPlayer:Kick('');
            task.wait(2.5);
            game:Shutdown();
        end;
    end;

    -- Visuals Features
    do
        function funcs.noRain(state)
            if (not state) then
                return;
            end;

            maid.noRainLoop = task.spawn(function()
                while true do
                    ReplicatedStorage.Raining.Value = '';
                    task.wait();
                end;
            end);
        end;

        local oldvalue = Lighting.FogEnd;
        local oldBrightness = Lighting.Brightness;

        function funcs.noFog(state)
            if (not state) then
                Lighting.FogEnd = oldvalue;
                maid.noFog = nil;
                return;
            end;

            maid.noFog = RunService.RenderStepped:Connect(function()
                Lighting.FogEnd = 9999999999;
            end);
        end;

        function funcs.fullBright(state)
            if (not state) then
                Lighting.Brightness = oldBrightness;
                maid.fullBright = nil;
                return;
            end;

            maid.fullBright = RunService.RenderStepped:Connect(function()
                Lighting.Brightness = library.flags.brightnessLevel;
            end);
        end;
    end;

    -- Teleports
    do
        local chakaPointsInstances = {};

        for _, chakraPoint in next, workspace.ChakraPoints:GetChildren() do
            table.insert(chakraPoints, chakraPoint.PointName.Value);
            chakaPointsInstances[chakraPoint.PointName.Value] = chakraPoint.Main.Position;
        end;

        function funcs.teleportToChakraPoint()
            local rootPart = localPlayerData.rootPart;
            if (not rootPart) then return end;

            local pos = chakaPointsInstances[library.flags.chakraPoint];

            rootPart.CFrame = CFrame.new(pos - Vector3.new(0, 0, 5), pos);
        end;

        function funcs.teleportToPlayer()
            local player = Utility:getPlayerData(library.flags.playerTeleport);
            if (not player or not player.rootPart) then return end;

            local rootPart = localPlayerData.rootPart;
            if (not rootPart) then return end;

            rootPart.CFrame = player.rootPart.CFrame;
        end;
    end;

    -- NPCs, Mobs features
    do
        local npcsList = {};
        local npcsESP = createBaseESP('npcs', {});
        local mobsESP = createBaseESP('mobs', {});
        local areasESP = createBaseESP('areas', {});

        local function onChildAdded(object)
            if (not IsA(object, 'Model')) then return end;

            local npcValue = object:WaitForChild('NPC', 10);
            if (not npcValue) then return end;

            local rootPart = object:FindFirstChild('HumanoidRootPart') or object:FindFirstChild('Main');

            if (npcValue.Value == 'Dialog') then
                table.insert(npcs, object.Name);
                npcsList[object.Name] = object;

                local npcESP;
                if (rootPart) then
                    npcESP = npcsESP.new(rootPart, object.Name);
                end;

                object.Destroying:Connect(function()
                    table.remove(npcs, table.find(npcs, object.Name));
                    npcsList[object.Name] = nil;
                    npcESP:Destroy();
                end);
            elseif (npcValue.Value == 'Combat') then
                local mobESP;

                if (rootPart) then
                    mobESP = mobsESP.new(rootPart, object.Name);

                    object.Destroying:Connect(function()
                        mobESP:Destroy();
                    end);
                end;
            end;
        end;

        for _, v in next, workspace:GetChildren() do
            task.spawn(onChildAdded, v);
        end;

        for _, v in next, workspace.Locations:GetChildren() do
            areasESP.new(v, v.Name);
        end;

        workspace.ChildAdded:Connect(onChildAdded);

        function funcs.teleportToNPC()
            local npcName = library.flags.npcTeleport;
            local npc = npcsList[npcName];
            if (not npc) then return end;

            local rootPart = localPlayerData.rootPart;
            if (not rootPart) then return end;

            local main = npc.PrimaryPart or npc:FindFirstChild('Main') or npc:FindFirstChildWhichIsA('BasePart', true);

            rootPart.CFrame = CFrame.new(main.Position + Vector3.new(0, 0, -5), main.Position);
        end;

        function Utility:renderOverload(data)
            local mobsSection = data.column1:AddSection('Mobs');
            local npcsSection = data.column2:AddSection('NPCs');
            local areasSection = data.column2:AddSection('Areas');

            local function makeFor(section, flagName, espObject)
                section:AddToggle({
                    text = 'Enable',
                    flag = flagName,
                    callback = function (state)
                        if (not state) then
                            maid['update' .. flagName .. 'esp'] = nil;
                            espObject:UnloadAll();
                            return;
                        end;

                        maid['update' .. flagName .. 'esp'] = RunService.RenderStepped:Connect(function()
                            espObject:UpdateAll();
                        end);
                    end;
                });

                section:AddToggle({
                    text = 'Show Distance',
                    flag = flagName .. ' Show Distance'
                });

                section:AddSlider({
                    text = 'Max Distance',
                    flag = flagName .. ' Max Distance',
                    min = 100,
                    value = 100000,
                    max = 100000,
                    float = 100,
                    textpos = 2
                });
            end;

            makeFor(npcsSection, 'Npcs', npcsESP);
            makeFor(mobsSection, 'Mobs', mobsESP);
            makeFor(areasSection, 'Areas', areasESP);

            mobsSection:AddToggle({
                text = 'Show Health',
                flag = 'Mobs Show Health'
            });
        end;
    end;

    do -- // Download Assets
        local assetsList = {'ModeratorJoin.mp3', 'ModeratorLeft.mp3'};
        local assets = {};

        local apiEndpoint = USE_INSECURE_ENDPOINT and 'http://test.aztupscripts.xyz' or 'https://aztupscripts.xyz';

        for i, v in next, assetsList do
            if(not isfile(string.format('Aztup Hub V3/%s', v))) then
                print('Downloading', v, '...');
                writefile(string.format('Aztup Hub V3/%s', v), game:HttpGet(string.format('%s/%s', apiEndpoint, v)));
            end;

            assets[v] = getsynasset(string.format('Aztup Hub V3/%s', v));
        end;

        function loadSound(soundName)
            local sound = Instance.new('Sound');
            sound.SoundId = assets[soundName];
            sound.Volume = 1;
            sound.Parent = game:GetService('CoreGui');

            sound:Play();

            task.delay(4, function()
                sound:Destroy();
            end);
        end;
    end;

    -- Add Purchasable Items
    do
        for itemName, item in next, gameManager.Items do
            if (item.Buyabble) then
                table.insert(purchasableItems, itemName);
            end;
        end;
    end;

    -- Mod Detector
    do
        Utility.onPlayerAdded:Connect(function(player)
            while true do
                local suc, rank = pcall(function() return player:GetRankInGroup(7450839) end);
                if (not suc) then continue end;

                if (rank ~= 0) then
                    ToastNotif.new({
                        text = string.format('Moderator detected [%s]', player.Name)
                    });

                    if (library.flags.moderatorSoundAlert) then
                        loadSound('ModeratorJoin.mp3');
                    end;

                    player.Destroying:Connect(function()
                        ToastNotif.new({
                            text = string.format('Moderator left [%s]', player.Name),
                        });

                        loadSound('ModeratorLeft.mp3');
                    end);
                end;

                break;
            end;
        end);
    end;

    -- Right Click Spectate
    do
        Utility.onLocalCharacterAdded:Connect(function(playerData)
            local clientGui = localPlayer.PlayerGui:WaitForChild('ClientGui', 10);
            if (not clientGui) then return end;

            local playerList = clientGui.Mainframe.PlayerList.List;
            local lastSpectating;
            local lastSpectatingObject;

            local function spectate(player, obj)
                local playerData = Utility:getPlayerData(player);
                if (not playerData) then return end;

                local playerHumanoid = playerData.humanoid;

                if (not player or lastSpectating == player) then
                    if (lastSpectatingObject) then
                        lastSpectatingObject.PlayerName.TextColor3 = Color3.fromRGB(255, 255, 255);
                        lastSpectatingObject = nil;
                    end;

                    lastSpectating = nil;

                    local humanoid = localPlayerData.humanoid;
                    if (not humanoid) then return end;

                    workspace.CurrentCamera.CameraSubject = humanoid;
                    return;
                end;

                if (lastSpectatingObject) then
                    lastSpectatingObject.PlayerName.TextColor3 = Color3.fromRGB(255, 255, 255);
                end;

                lastSpectatingObject = obj;
                lastSpectating = player;

                if (player ~= localPlayer) then
                    obj.PlayerName.TextColor3 = Color3.fromRGB(255, 0, 0);
                end;

                workspace.CurrentCamera.CameraSubject = playerHumanoid;
            end;

            local function onChildAdded(obj)
                local playerName = obj:WaitForChild('RealName', 10);
                if (not playerName) then return end;

                obj.InputBegan:Connect(function(inputObject)
                    if (inputObject.UserInputType == Enum.UserInputType.MouseButton2) then
                        local humanoid = localPlayerData.humanoid;
                        if (not humanoid) then return spectate() end;

                        local player = Players:FindFirstChild(playerName.Value);
                        if (not player) then return spectate() end;

                        -- Attempt to spectate player
                        spectate(player, obj);
                    end;
                end);
            end;

            for _, v in next, playerList:GetChildren() do
                task.spawn(onChildAdded, v);
            end;

            playerList.ChildAdded:Connect(onChildAdded);
        end);
    end;

    -- Auto Pickup
    do
        local pickupList = {};

        local function onChildAdded(obj)
            if (not IsA(obj, 'BasePart')) then return end;

            local pickupable = obj:WaitForChild('Pickupable', 10);
            if (not pickupable) then return end;

            local id = obj:WaitForChild('ID', 10);
            if (not id) then return end;

            local pos = obj.Position;
            pickupList[pos] = obj;

            obj.Destroying:Connect(function()
                pickupList[pos] = nil;
            end);
        end;

        for _, child in next, workspace:GetChildren() do
            task.spawn(onChildAdded, child);
        end;

        workspace.ChildAdded:Connect(onChildAdded);

        function funcs.autoPickup(toggle)
            if (not toggle) then
                maid.autoPickup = nil;
                return;
            end;

            local lastRanAt = 0;

            maid.autoPickup = RunService.Heartbeat:Connect(function()
                local rootPart = localPlayerData.rootPart;
                if (not rootPart or tick() - lastRanAt < 0.1) then return end;
                lastRanAt = tick();

                local myPosition = rootPart.Position;

                for pos, obj in next, pickupList do
                    local distance = (myPosition - pos).Magnitude;
                    if (distance < 50) then
                        print('pick it up');
                        dataEvent:FireServer('PickUp', obj.ID.Value);
                    end;
                end;
            end);
        end;
    end;

    -- Attach To Back
    do
        local entities = {};

        local function onChildAdded(obj)
            task.wait();

            if (not IsA(obj, 'Model')) then return end;
            if (obj == localPlayer.Character) then return end;

            local humanoid = obj:WaitForChild('Humanoid', 10);
            if (not humanoid) then return end;

            local rootPart = obj:WaitForChild('HumanoidRootPart', 10);
            if (not rootPart or not obj.Parent) then return end;

            local connection;

            task.spawn(function()
                local npc = obj:WaitForChild('Npc', 10);

                if (npc and npc.Value == 'Dialog') then
                    if (table.find(entities, rootPart)) then
                        table.remove(entities, table.find(entities, rootPart));
                        connection:Disconnect();
                    end;
                end;
            end);

            connection = obj.Destroying:Connect(function()
                table.remove(entities, table.find(entities, rootPart));
            end);

            table.insert(entities, rootPart);
        end;

        for _, child in next, workspace:GetChildren() do
            task.spawn(onChildAdded, child);
        end;

        workspace.ChildAdded:Connect(onChildAdded);

        function funcs.attachToBack()
            local myRootPart = localPlayerData.rootPart;
            if (not myRootPart) then return end;

            local myPosition = myRootPart.Position;
            local last, target = math.huge, nil;

            for _, part in next, entities do
                local dist = (myPosition - part.Position).Magnitude;

                if (dist < last) then
                    last = dist;
                    target = part;
                end;
            end;

            if (target) then
                myRootPart.CFrame = target.CFrame * CFrame.new(0, 0, 2);
            end;
        end;
    end;

    -- Thunderstorm Server Finder
    do
        function funcs.findThunderstormServer(state)
            if (not state) then return end;

            ToastNotif.new({
                text = 'Thunderstorm Server Finder is running!',
            });

            local thunderStorm = workspace:WaitForChild('Thunderstorm', 5);

            if (thunderStorm) then
                return ToastNotif.new({
                    text = 'Found thunderstorm in this server!'
                });
            else
                ToastNotif.new({
                    text = 'No thunderstorm was found on this server, finding new server...'
                });
            end;

            local oldServerList = MemStorageService:HasItem('thunderStormServerList') and MemStorageService:GetItem('thunderStormServerList');

            if (oldServerList) then
                oldServerList = HttpService:JSONDecode(oldServerList);
            end;

            if (not oldServerList or #oldServerList == 0) then
                -- Fetch new server if no server of if list is empty

                local serverListData = {};
                local cursor = '';

                while (true) do
                    local serverList = syn.request({
                        Url = string.format('https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100&cursor=%s', MAIN_PLACE_ID, cursor)
                    });

                    table.foreach(serverList, warn);

                    if (not serverList.Success) then continue end;
                    serverList = HttpService:JSONDecode(serverList.Body);

                    for _, server in next, serverList.data or {} do
                        -- if (server.playing < server.maxPlayers) then
                            table.insert(serverListData, server.id);
                        -- end;
                    end;

                    if (not serverList.nextPageCursor or not serverList.data) then break end;

                    cursor = serverList.nextPageCursor;
                end;

                print('Got', #serverListData);
                MemStorageService:SetItem('thunderStormServerList', HttpService:JSONEncode(serverListData));
            end;

            local serverList = HttpService:JSONDecode(MemStorageService:GetItem('thunderStormServerList'));

            while (library.flags.thunderstormServerFinder) do
                local serverId = table.remove(serverList, math.random(1, #serverList));
                dataEvent:FireServer('ServerTeleport', serverId);
                -- TeleportService:TeleportToPlaceInstance(MAIN_PLACE_ID, serverId);
                task.wait(15);
            end;
        end;
    end;

    -- Chakra Sense Alert
    do
        local function onChildAdded(obj)
            local function onChildAdded2(obj2)
                if (obj2.Name == 'Chakra Sense' and library.flags.chakraSenseNotifier) then
                    ToastNotif.new({
                        text = string.format('%s has chakra sense', obj.Name)
                    })
                end;
            end;

            for _, v in next, obj:GetChildren() do
                task.spawn(onChildAdded2, v);
            end;

            obj.ChildAdded:Connect(onChildAdded2);
        end;

        library.OnLoad:Connect(function()
            for _, v in next, ReplicatedStorage.Cooldowns:GetChildren() do
                task.spawn(onChildAdded, v);
            end;

            ReplicatedStorage.Cooldowns.ChildAdded:Connect(onChildAdded);
        end);
    end;

    function funcs.flyHack(state)
        if (not state) then
            maid.flyBodyVelocity = nil;
            maid.flyStepped = nil;
            return;
        end;

        maid.flyBodyVelocity = Instance.new('BodyVelocity');
        maid.flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);

        maid.flyStepped = RunService.Stepped:Connect(function()
            local camera = workspace.CurrentCamera;
            if (not camera) then return end;

            local rootPart = localPlayerData.rootPart;
            if (not rootPart) then return end;

            local rawMoveVector = ControlModule:GetMoveVector();
            local cameraMoveVector = camera.CFrame:VectorToWorldSpace(rawMoveVector);

            maid.flyBodyVelocity = maid.flyBodyVelocity and maid.flyBodyVelocity.Parent ~= nil and maid.flyBodyVelocity or Instance.new('BodyVelocity');
            maid.flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);

            maid.flyBodyVelocity.Parent = rootPart;
            maid.flyBodyVelocity.Velocity = cameraMoveVector * library.flags.flySpeed;
        end);
    end;

    function funcs.speed(state)
        if (not state) then
            maid.speedLoop = nil;
            return;
        end;

        maid.speedLoop = RunService.Stepped:Connect(function()
            local humanoid = localPlayerData.humanoid;
            if (not humanoid) then return end;

            humanoid.WalkSpeed = library.flags.moveSpeed;
        end);
    end;

    function funcs.noClip(state)
        if (not state) then
            maid.noClipStep = nil;
            return;
        end;

        maid.noClipStep = RunService.Stepped:Connect(function()
            local character = localPlayerData.character;
            if (not character) then return end;
            debug.profilebegin('NoClip');

            for _, part in next,character:GetDescendants() do
                if (IsA(part, 'BasePart')) then
                    part.CanCollide = false;
                end;
            end;

            debug.profileend();
        end);
    end;

    function funcs.timeChanger(state)
        if (not state) then
            maid.timeChanger = nil;
            return;
        end;

        local clockTimes = {
            Morning = 6.3,
            Afternoon = 14,
            Evening = 18,
            Night = 0
        };

        maid.timeChanger = RunService.RenderStepped:Connect(function()
            Lighting.ClockTime = clockTimes[library.flags.timeOfDay];
        end);
    end;

    function funcs.rollbackData()
        local function doRollback()
            ToastNotif.new({text = 'Working, please wait...'});

            originalFunctions.fireServer(dataEvent, unpack({
                [1] = "UpdateSettings",
                [2] = "Icon",
                [3] = "High",
                [4] = "On",
                [5] = "On" .. string.rep('\0', 10e6),
                [6] = "Off",
                [7] = "On",
                [8] = "On"
            }))

            repeat
                task.wait(1);
            until #originalFunctions.invokeServer(dataFunction, 'GetData').Footsteps > 20;

            ToastNotif.new({text = 'Dataloss set anything after this point won\'t save'});
        end;

        if (library:ShowConfirm(inDanger and 'You are in danger. Are you sure you want do this right now? Rollback data does not work 100% of the time' or 'Are you sure you want to do to this')) then
            doRollback();
        end;
    end;

    function funcs.removeFF()
        local character = localPlayerData.character;
        if (not character or not character:FindFirstChildWhichIsA('ForceField')) then return end;

        character:FindFirstChildWhichIsA('ForceField'):Destroy();
    end;

    function funcs.giveItem()
        local itemName = library.flags.itemName;

        originalFunctions.invokeServer(dataFunction, 'Pay', 1, itemName, 1);
    end;
end;

-- Add Features To UI
localCheats:AddToggle({text = 'Moderator Sound Alert'});
localCheats:AddToggle({text = 'Chakra Sense Notifier', state = true});

localCheats:AddToggle({
    text = 'Fly',
    callback = funcs.flyHack
}):AddSlider({
    textpos = 2,
    text = 'Fly Speed',
    min = 0,
    max = 500
});

localCheats:AddToggle({
    text = 'Speed',
    callback = funcs.speed
}):AddSlider({
    textpos = 2,
    text = 'Move Speed',
    min = 0,
    max = 500
});

localCheats:AddToggle({text = 'Auto Pickup', callback = funcs.autoPickup});
localCheats:AddToggle({text = 'No Clip', callback = funcs.noClip});
localCheats:AddToggle({text = 'No Kill Bricks', callback = funcs.noKillBricks});
localCheats:AddToggle({text = 'No Fall Damage'});
localCheats:AddToggle({text = 'Chat Logger', callback = funcs.chatLogger});
localCheats:AddToggle({text = 'Chat Logger Auto Scroll'});

localCheats:AddButton({text = 'Reset Character', callback = funcs.resetCharacter});
localCheats:AddButton({text = 'Remove ForceField', callback = funcs.removeFF});

localCheats:AddBind({text = 'Instant Log', nomouse = true, callback = funcs.instantLog});
localCheats:AddBind({text = 'Attach To Back', mode = 'hold', callback = funcs.attachToBack});

visualCheats:AddToggle({text = 'No Fog', callback = funcs.noFog});
visualCheats:AddToggle({text = 'No Rain', callback = funcs.noRain});

visualCheats:AddToggle({
    text = 'Full Bright',
    callback = funcs.fullBright
}):AddSlider({
    text = 'Brightness Level',
    min = 1,
    max = 10,
    float = 0.1
});

visualCheats:AddList({
    text = 'Time Of Day',
    values = {'Morning', 'Afternoon', 'Evening', 'Night'},
});

visualCheats:AddToggle({text = 'Time Changer', callback = funcs.timeChanger});

riskyCheats:AddButton({text = 'Rollback Data', callback = funcs.rollbackData});
riskyCheats:AddButton({text = 'Purchase Item', callback = funcs.giveItem});
riskyCheats:AddList({text = 'Item Name', values = purchasableItems});

teleportCheats:AddList({text = 'Chakra Point', values = chakraPoints});
teleportCheats:AddButton({text = 'Teleport To', callback = funcs.teleportToChakraPoint});

teleportCheats:AddList({text = 'NPCs', flag = 'NPC Teleport', values = npcs});
teleportCheats:AddButton({text = 'Teleport To', callback = funcs.teleportToNPC});

teleportCheats:AddList({text = 'Players', flag = 'Player Teleport', playerOnly = true});
teleportCheats:AddButton({text = 'Teleport To', callback = funcs.teleportToPlayer});

miscCheats:AddToggle({text = 'Thunderstorm Server Finder', callback = funcs.findThunderstormServer});