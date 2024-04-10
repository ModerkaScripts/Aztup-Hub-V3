local library = sharedRequire('../UILibrary.lua');
local Services = sharedRequire('../utils/Services.lua');

local column1, column2 = unpack(library.columns);

local ReplicatedStorage, Players, RunService = Services:Get('ReplicatedStorage', 'Players', 'RunService');
local IsA = game.IsA;

local LocalPlayer = Players.LocalPlayer;
local Heartbeat = RunService.Heartbeat;

local pointsAutoFarm;
local toggleBagEsp;
local disconnectOnModJoin;
local alwaysPerfectLandings;
local infWallJump;
local rgbChat;
local annoy;
local enableRenderDistance;
local infWallRun;
local blackBubbleChat;

local bagEsp = {};

do -- // Bag Esp
    bagEsp.__index = bagEsp;
    bagEsp.objects = {};

    function bagEsp.new(bag)
        local self = setmetatable({}, bagEsp);
        self.rarity = bag.Rarity.Value;
        self.root = bag.PrimaryPart;

        self.line = Drawing.new('Line');
        self.line.Transparency = 1;
        self.line.Color = Color3.fromRGB(255, 255, 255);

        self.text = Drawing.new('Text');
        self.text.Center = true;
        self.text.Color = Color3.fromRGB(255, 255, 255);
        self.text.Transparency = 1;

        table.insert(bagEsp.objects, self);

        return self;
    end;

    function bagEsp:hide()
        self.text.Visible = false;
        self.line.Visible = false;
    end;

    function bagEsp:update(myRootPart)
        if(not library.flags.toggleBagEsp) then
            return self:hide();
        end;

        local distance = (self.root.Position - myRootPart.Position).Magnitude;
        if(distance > library.flags.maxBagEspDistance) then
            return self:hide();
        end;

        local screenPosition, visible = workspace.CurrentCamera:WorldToViewportPoint(self.root.Position);
        if(not visible) then
            return self:hide();
        end;

        local vectorScreenPosition = Vector2.new(screenPosition.X, screenPosition.Y);
        local viewportSize = workspace.CurrentCamera.ViewportSize;

        self.text.Position = vectorScreenPosition;
        self.text.Text = string.format("[%s] [%.02f]", self.rarity, distance);
        self.text.Visible = true;

        self.line.From = Vector2.new(viewportSize.X / 2, viewportSize.Y);
        self.line.To = vectorScreenPosition;
        self.line.Visible = true;
    end;

    function bagEsp:destroy()
        table.remove(self.objects, table.find(self.objects, self));

        self.line:Remove();
        self.text:Remove();

        self.line = nil;
        self.text = nil;
    end;

    local function onBagAdded(instance)
        if(instance:FindFirstChild('BagTouchScript')) then
            local esp = bagEsp.new(instance);
            instance:GetPropertyChangedSignal('Parent'):Wait();
            esp:destroy();
        end;
    end;

    for i, v in next, workspace:GetChildren() do
        coroutine.wrap(onBagAdded)(v);
    end;

    workspace.ChildAdded:Connect(onBagAdded);
end;

do -- // Hooks
    local blacklistedEvents = {'LandWithForceField', 'UpdateCombo', 'HighCombo'};
    local oldNamecall;
    local oldNewIndex;

    local function returnOne()
        return 1;
    end;

    local getCurrentCombo = ReplicatedStorage.GetCurrentCombo
    getCurrentCombo.OnClientInvoke = returnOne;

    oldNamecall = hookmetamethod(game, '__namecall', function(self, ...)
        SX_VM_CNONE();
        local method = getnamecallmethod();

        if(method == 'FireServer' and table.find(blacklistedEvents, tostring(self))) then
            return;
        end;

        return oldNamecall(self, ...);
    end);

    oldNewIndex = hookmetamethod(game, '__newindex', function(self, p, v)
        SX_VM_CNONE();
        if(p == 'WalkSpeed' and IsA(self, 'Humanoid') and library.flags.toggleSpeedHack) then
            v = library.flags.speedHack;
            return oldNewIndex(self, p, v);
        elseif(p == 'OnClientInvoke' and self == getCurrentCombo) then
            print('attempt to change onclientinvoke');
            return;
        end;

        return oldNewIndex(self, p, v);
    end);

    local oldMathClamp;
    oldMathClamp = hookfunction(getrenv().math.clamp, function(n, min, max)
        if(min == 0 and max == 0.4 and string.find(debug.traceback(), 'upMovement') and library.flags.perfectMs) then
            print('called', n, min, max, debug.traceback());
            -- table.foreach(getconstants(2), warn);

            return Random.new():NextInteger(library.flags.perfectMsRange, library.flags.perfectMsRange + 10) / 1000;
        end;

        return oldMathClamp(n, min, max);
    end);
end;

do -- // Utility
    local mainEnv = getsenv(LocalPlayer:WaitForChild('Backpack'):WaitForChild('Main'));

    local forceField = Instance.new('ForceField');
    forceField.Visible = false;

    local client = {};

    local function onCharacterAdded()
        wait(1);
        mainEnv = getsenv(LocalPlayer:WaitForChild('Backpack'):WaitForChild('Main'));
        repeat wait(); until mainEnv.updateGrapplerPos;
        client = getupvalue(mainEnv.updateGrapplerPos, 2);

        local oldGearIs = mainEnv.gearIs;

        function mainEnv.gearIs(bodyType, gearType)
            if(library and gearType == 'PowerGauntlet' and library.flags.powergripMode) then
                return true
            end;

            return oldGearIs(bodyType, gearType);
        end;

        local oldComboAdd = mainEnv.comboAdd;
        function mainEnv.comboAdd(...)
            if(checkcaller()) then
                return;
            end;

            return oldComboAdd(...);
        end;

        local oldupdatePlayerVisibility = mainEnv.updatePlayerVisibility;
        local lastUpdatedAt = 0;

        function mainEnv.updatePlayerVisibility(...)
            if (tick() - lastUpdatedAt < 2) then return end;
            lastUpdatedAt = tick();

            return oldupdatePlayerVisibility();
        end
    end;

    function pointsAutoFarm()
        while(library.flags.togglePointsAutoFarm) do
            local wallrunDist = math.random(85, 99);

            local mt = setmetatable({wallrunDist = wallrunDist}, {
                __newindex = function(self, p, v)
                    if(p == 'combo') then
                        v = 5;
                    end;

                    rawset(self, p, v);
                end;
            });

            mainEnv.getfenv = newcclosure(function()
                return mainEnv;
            end);

            pcall(mainEnv.pointsAdd, wallrunDist * 0.8, 'wallrun', mt);
            task.wait(0.4 + math.random() * 1.5);
        end;
    end;

    function toggleBagEsp()
        repeat
            local myRootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;

            if(myRootPart) then
                for i, v in next, bagEsp.objects do
                    v:update(myRootPart);
                end;
            end;

            Heartbeat:Wait();
        until not library.flags.toggleBagEsp;
    end;

    function disconnectOnModJoin()
        while(library.flags.disconnectOnModJoin) do
            for i, v in next, Players:GetPlayers() do
                pcall(function()
                    local role = v:GetRoleInGroup(3468086);
                    if(role ~= 'Member' and role ~= 'Guest') then
                        LocalPlayer:Kick('\nModerator Joined');
                    end;
                end);
            end;

            wait();
        end;
    end;

    function alwaysPerfectLandings(t)
        while(library.flags.alwaysPerfectLandings) do
            client.lastPrep = tick();
            client.preparePlaying = true;
            Heartbeat:Wait();
        end;
    end;

    function infWallJump()
        while(library.flags.infWallClimb) do
            client.numWallclimb = math.huge;
            Heartbeat:Wait();
        end;

        client.numWallclimb = 1;
    end;

    function infWallRun(toggle)
        if(not toggle) then return end;

        while(library.flags.infWallRun) do
            client.numWallrun = math.huge;
            Heartbeat:Wait();
        end;

        client.numWallrun = 1;
    end;

    function rgbChat(t)
        ReplicatedStorage.BubbleColours[LocalPlayer.Name].RGB.Value = t and true;
    end;

    function blackBubbleChat(t)
        ReplicatedStorage.BubbleColours[LocalPlayer.Name].Value = t and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(255, 255, 25);
    end;

    function annoy(toggle)
        if(not toggle) then return end;
        repeat
            mainEnv.playCharacterSound("GrapplePull");
            mainEnv.playCharacterSound("Grapple");
            Heartbeat:Wait();
        until not library.flags.annoy;
    end;

    do -- // Render Distance Setup
        local chunkObjectsList = {workspace.Props, workspace.TimeTrials, workspace.Billboards, workspace.BustableDoors, workspace.MapDecoration};
        local chunkObjects;

        local function getPartPosition(object)
            return object:IsA('BasePart') and object.Position or object:IsA('Model') and object.WorldPivot.Position;
        end

        local function updateChunk(disable)
            local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
            if(not rootPart or not chunkObjects) then return end;

            local rootPosition = rootPart.Position;
            local maxRenderDistance = (library.flags.renderDistanceValue or 500);

            for i = 1, #chunkObjects do
                local v = chunkObjects[i];
                if(not disable and (v.position - rootPosition).Magnitude >= maxRenderDistance) then
                    v.object.Parent = nil;
                else
                    v.object.Parent = chunkObjectsList[v.oldParent];
                end;
            end;
        end;

        function enableRenderDistance(toggle)
            if (not toggle) then
                updateChunk(true);
                return
            end;

            if (not chunkObjects) then
                chunkObjects = {};

                for i, v in next, chunkObjectsList do
                    for i2, v2 in next, v:GetChildren() do
                        table.insert(chunkObjects, {position = getPartPosition(v2), object = v2, oldParent = i});
                    end;
                end;

                print('[Map Chunk] made', #chunkObjects, 'chunk objects');
            end;

            repeat
                updateChunk();
                task.wait(1);
            until not library.flags.enableRenderDistance;

            updateChunk(true);
        end;
    end;

    LocalPlayer.CharacterAdded:Connect(onCharacterAdded);
    onCharacterAdded();
end;

local parkourAutoFarm = column1:AddSection('Auto Farm');
local parkourCharacter = column1:AddSection('Main');
local parkourBagEsp = column2:AddSection('Bag Esp');
local parkourMisc = column2:AddSection('Misc');

parkourAutoFarm:AddToggle({text = 'Toggle Points Auto Farm', callback = pointsAutoFarm})

parkourCharacter:AddToggle({text = 'Always Perfect Landings', callback = alwaysPerfectLandings});
parkourCharacter:AddToggle({text = 'Powergrip Mode'});
parkourCharacter:AddToggle({text = 'Toggle Speed Hack'});
parkourCharacter:AddToggle({text = 'Perfect Ms'}):AddSlider({flag = 'Perfect Ms Range', min = 10, max = 100});
parkourCharacter:AddToggle({text = 'Inf Wall Climb', callback = infWallJump});
parkourCharacter:AddToggle({text = 'Inf Wall Run', callback = infWallRun});
parkourCharacter:AddSlider({text = 'Speed Hack', value = 100, min = 0, max = 500});

parkourMisc:AddToggle({text = 'Enable Render Distance', callback = enableRenderDistance}):AddSlider({flag = 'Render Distance Value', min = 250, max = 5000});

parkourMisc:AddToggle({text = 'Annoy', callback = annoy});
parkourMisc:AddToggle({text = 'Disconnect On Mod Join', callback = disconnectOnModJoin});
parkourMisc:AddToggle({text = 'Rgb Chat', callback = rgbChat});
parkourMisc:AddToggle({text = 'Black Bubble Chat', callback = blackBubbleChat})

parkourBagEsp:AddToggle({text = 'Toggle Bag Esp', callback = toggleBagEsp});
parkourBagEsp:AddSlider({text = 'Max Bag Esp Distance', value = 10000, min = 100, max = 10000});