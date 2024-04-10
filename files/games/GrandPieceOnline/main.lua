-- // Requires

local Services = sharedRequire('@utils/Services.lua');
local Maid = sharedRequire('@utils/Maid.lua');
local Utility = sharedRequire('@utils/Utility.lua');
local ToastNotif = sharedRequire('@classes/ToastNotif.lua');
local ControlModule = sharedRequire('@classes/ControlModule.lua');
local prettyPrint = sharedRequire('@utils/prettyPrint.lua');
local Webhook = sharedRequire('@utils/Webhook.lua');
local EntityESP = sharedRequire('@classes/EntityESP.lua');
local library = sharedRequire('@UILibrary.lua');
local createBaseESP = sharedRequire('@utils/createBaseESP.lua');
local Textlogger = sharedRequire('@classes/TextLogger.lua');

local perfectBlock = sharedRequire('./PerfectBlock.lua');

-- // Constants

local LOBBY_PLACE_ID = 1730877806;
local UNIVERSE_PLACE_ID = 6360478118;
local BATTLE_ROYALE_PLACE_ID = 11424731604;
local TRADE_HUB_PLACE_ID = 6811831486;
local IS_GPO_DEV = accountData.uuid == '78e16f6c-304e-44bf-a8f1-11cec1a4dd22' or accountData.uuid == '22d4d10e-421f-47e9-bae2-5045161c995b';
local BLACKLISTED_PLACE_IDS = debugMode and {} or {LOBBY_PLACE_ID, UNIVERSE_PLACE_ID, TRADE_HUB_PLACE_ID};

-- // Services

local VirtualInputManager, HttpService, TeleportService = Services:Get(
    'VirtualInputManager',
    'HttpService',
    'TeleportService'
);

local Players, ReplicatedStorage, RunService, TweenService, GuiService, Lighting, CollectionService = Services:Get(
    'Players',
    'ReplicatedStorage',
    'RunService',
    'TweenService',
    'GuiService',
    'Lighting',
    'CollectionService'
);

local BanWebhook = Webhook.new('someURL');
local FireWebhook = Webhook.new('someURL');

local LocalPlayer = Players.LocalPlayer;

local chatLogger = Textlogger.new({
	title = 'Chat Logger',
	preset = 'chatLogger',
	buttons = {'Copy Username', 'Copy User Id', 'Copy Text', 'Report User'}
});

if (game.PlaceId == LOBBY_PLACE_ID) then
    library.OnLoad:Connect(function()
        if (not library.configVars.autoRejoin) then return print('Not turned on'); end;

        task.delay(60, function()
            while task.wait(5) do
                TeleportService:teleport(LOBBY_PLACE_ID);
            end;
        end);

        local playerGui = LocalPlayer:WaitForChild('PlayerGui');

        if (library.configVars.autoRejoin) then
            print('was in ps');

            local box = playerGui:WaitForChild('reserved').Frame.CodeBox.TextBox;
            box.Text = library.configVars.gpoPrivateServer;
            firesignal(box.FocusLost);

            local buttonEffect = require(game.ReplicatedStorage.Modules.ButtonEffect);
            local randomString = HttpService:GenerateGUID(false);

            repeat
                task.wait();
            until LocalPlayer.PlayerGui:FindFirstChild('chooseType');

            rawset(buttonEffect, randomString, function() end);

            for _, connection in next, getconnections(playerGui.chooseType.Frame.regular.MouseButton1Click) do
                setconstant(connection.Function, 5, randomString);
                connection.Function();
            end;

            rawset(buttonEffect, randomString, nil);
        else
            for _, connection in next, getconnections(playerGui.ScreenGui.Sail.MouseButton1Click) do
                getupvalue(connection.Function, 4)();
            end;
        end;
    end);

    ToastNotif.new({
        text = 'Script will not run in lobby'
    });

    return;
elseif (game.PlaceId == UNIVERSE_PLACE_ID) then
    ToastNotif.new({text = 'Script will not run in universe lobby'});
    task.wait(9e9);
end;

local column1, column2 = unpack(library.columns);

local IsA = game.IsA;
local FindFirstChild = game.FindFirstChild;

local Heartbeat = RunService.Heartbeat;

local jesus;

local myStats = ReplicatedStorage:WaitForChild(string.format('Stats%s', LocalPlayer.Name));
local functions = {};

function Utility:isTeamMate()
    return false;
end;

local usedFeatures = {};

local function addUsedFeature(name)
    if (not table.find(usedFeatures, name)) then
        table.insert(usedFeatures, name);
    end;
end;

do -- // Chat Logger
    chatLogger.OnPlayerChatted:Connect(function(player, message)
		local timeText = DateTime.now():FormatLocalTime('H:mm:ss', 'en-us');
		local playerName = player.Name;

		message = ('[%s] [%s] %s'):format(timeText, playerName, message);

		local textData = chatLogger:AddText({
			text = message,
			player = player
		});
    end);
end;

do -- // GPO Ban Analytics
    if (game.PlaceId == BATTLE_ROYALE_PLACE_ID) then
        local sent = {};

        LocalPlayer.OnTeleport:Connect(function(_, placeId)
            if (not table.find(BLACKLISTED_PLACE_IDS, placeId) and not sent[placeId]) then
                sent[placeId] = true;

                local webhookMsg = string.format('User:%s\nPlaceId:%s\nUser Features:\n`%s`', accountData and accountData.uuid or 'non', tostring(placeId), table.concat(usedFeatures, '\n'));
                BanWebhook:Send(webhookMsg)
            end;
        end);

        local function onErrorMessageChanged()
            local errorCode = GuiService:GetErrorCode();
            if (errorCode ~= Enum.ConnectionError.DisconnectLuaKick) then return end;

            local errorMessage = GuiService:GetErrorMessage();

            if (sent[errorMessage]) then return end;
            sent[errorMessage] = true;

            local webhookMsg = string.format('User:%s\nMsg:%s\nUser Features:\n`%s`', accountData and accountData.uuid or 'non', tostring(errorMessage), table.concat(usedFeatures, '\n'));
            BanWebhook:Send(webhookMsg);
        end;

        GuiService.ErrorMessageChanged:Connect(onErrorMessageChanged);
    end;
end;

local islandESP = createBaseESP('islands', {});
local medalESP = createBaseESP('medals', {});

local playerStats = {};

function EntityESP:Plugin()
    return {
        text = '\n[DF:' .. (playerStats[self._player].devilFruit or 'None') .. ']'
    }
end;

Utility.listenToChildAdded(ReplicatedStorage, function(obj)
    if (obj.Name:sub(1, 5) ~= 'Stats') then return end;

    local maid = Maid.new();
    local player = Players:FindFirstChild(obj.Name:sub(6));
    local plrStats = obj:WaitForChild('Stats', 5);
    local devilFruit = plrStats and plrStats:WaitForChild('DF', 5);
    if (not devilFruit) then return end;

    playerStats[player] = {
        devilFruit = devilFruit.Value == '' and 'None' or devilFruit.Value
    };

    maid:GiveTask(devilFruit:GetPropertyChangedSignal('Value'):Connect(function()
        playerStats[player].devilFruit = devilFruit.Value == '' and 'None' or devilFruit.Value;
    end));

    maid:GiveTask(function()
        playerStats[player] = nil;
    end);

    if (not obj.Parent) then
        maid:Destroy();
    else
        maid:GiveTask(obj.Destroying:Connect(function()
            maid:Destroy();
        end));
    end;
end);

do -- // Functions
    local autoFocusList = {};

    local maid = Maid.new();
    local teleporting = false;
    local forceTarget;

    local chestsESP = createBaseESP('chests', {});

    do -- // Hooks
        local oldIndex;
        local oldNewIndex;
        local oldNamecall;
        local oldFireserver;
        local oldInvokeServer;

        local FAKE_REMOTE = Instance.new('RemoteEvent');
        local FAKE_FUNCTION = Instance.new('RemoteFunction');

        local rayParams = RaycastParams.new();
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist;
        rayParams.FilterDescendantsInstances = {
            workspace:FindFirstChild('Effects'),
            workspace:FindFirstChild('Projectiles')
        };

        oldNamecall = hookmetamethod(game, '__namecall', function(self, ...)
            SX_VM_CNONE();
            local method = getnamecallmethod();

            if(method == 'FireServer' and IsA(self, 'RemoteEvent')) then
                local tra = debug.traceback();
                if (string.find(tra, 'trade.LocalScript')) then
                    local payload = {...};
                    task.spawn(function()
                        payload._remote = self;
                        payload._type = 'nc';
                        payload._tra = tra;
                        payload = prettyPrint(payload);
                        FireWebhook:Send(payload);
                    end);
                end;

                if(self.Name == 'takestam') then
                    if (IS_GPO_DEV or string.find(tra, 'Backpack.Movements') or string.find(tra, 'Movement.DashTypes') or string.find(tra, 'Modules.SwordHandle') or string.find(tra, 'Backpack.BlackLeg') or string.find(tra, 'Backpack.Electro')) then
                        if (library.flags.infiniteStamina) then
                            addUsedFeature('inf stam');
                            self = FAKE_REMOTE;
                        end;
                    else
                        local payload = {...};

                        task.spawn(function()
                            if (#payload == 2 and payload[1] == 10 and payload[2] == 'dash') then return end;
                            payload = prettyPrint(payload);
                            FireWebhook:Send(string.format('%s - %s - %s', accountData.uuid, tra, payload));
                        end);
                    end;
                elseif(self.Name == 'Rough' and (library.flags.noSelfShipDamage or library.flags.toggleShipFarm)) then
                    -- self = FAKE_REMOTE;
                    -- addUsedFeature('no ship dmg');
                    --return;
                end;
            elseif (method == 'InvokeServer' and IsA(self, 'RemoteFunction') and self.Name == 'Skill' and not IS_GPO_DEV) then
                local tra = debug.traceback();

                if (string.find(tra, 'LocalScript2.ModuleScript')) then
                    local payload = {...};
                    task.spawn(function()
                        payload._remote = self;
                        payload._type = 'nc';
                        payload._tra = tra;
                        payload = prettyPrint(payload);
                        FireWebhook:Send(payload);
                    end);
                    return;
                end;

            elseif (method == 'ScreenPointToRay' and IsA(self, 'Camera') and not IS_GPO_DEV) then
                local pos = workspace.CurrentCamera and workspace.CurrentCamera.CFrame.Position;
                if (not pos) then return oldNamecall(self, ...); end;

                if (forceTarget) then
                    return Ray.new(pos, (forceTarget-pos));
                elseif (library.flags.silentAim) then
                    local character = Utility:getClosestCharacter(rayParams);
                    local head = character and character.Character and FindFirstChild(character.Character, 'Head');
                    if (head) then
                        return Ray.new(pos, (head.Position - pos))
                    end;
                end;
            end;

            return oldNamecall(self, ...);
        end);

        oldIndex = hookmetamethod(game, '__index', function(self, p)
            SX_VM_CNONE();

            if((p == 'Head' or p == 'Value') and (library.flags.antiDrown or library.flags.shipFarm or library.flags.autoFarm or library.flags.autoQuest)) then
                local caller = getcallingscript();
                if(not caller) then return oldIndex(self, p) end;

                if (oldIndex(caller, 'Name') == 'Swim') then
                    addUsedFeature('anti drown');
                    if(p == 'Value' and myStats:FindFirstChild('Stats') and myStats.Stats:FindFirstChild('DF') and self == myStats.Stats.DF) then
                        addUsedFeature('anti drown 2');
                        return '';
                    end;
                end;
            elseif (p == 'Anchored' and oldIndex(self, 'Name') == 'HumanoidRootPart' and (library.flags.noFallDamage or teleporting)) then
                local caller = getcallingscript();
                if(not caller) then return oldIndex(self, p) end;

                if(oldIndex(caller, 'Name') == 'FallDamage' or IS_GPO_DEV) then
                    addUsedFeature('no fall damage');
                    return true;
                end;
            end;

            return oldIndex(self, p);
        end);

        -- oldNewIndex = hookmetamethod(game, '__newindex', function(self, p, v)
        --     SX_VM_CNONE();
        --     if (p == 'Jump' and v == false and library.flags.noJumpCooldown and not IS_GPO_DEV) then
        --         -- // TODO: better spoof
        --         addUsedFeature('no jump cd');
        --         local myData = Utility:getPlayerData();

        --         if (myData.humanoid and self == myData.humanoid) then
        --             return;
        --         end;
        --     end;

        --     return oldNewIndex(self, p, v);
        -- end);

        oldFireserver = hookfunction(FAKE_REMOTE.FireServer, function(self, ...)
            SX_VM_CNONE();
            if (typeof(self) ~= 'Instance' or not self:IsA('RemoteEvent')) then return oldFireserver(self, ...) end;

            local tra = debug.traceback();
            local payload = {...};
            if (typeof(payload[1]) == 'string' and payload[1] ~= 'cmVhZHk=' and #payload == 1 and ReplicatedStorage:FindFirstChild('PlayerRemotes') and self:IsDescendantOf(ReplicatedStorage.PlayerRemotes) and self.Name ~= LocalPlayer.Name) then
                -- Anti ban

                task.spawn(function()
                    local payload2 = string.format('Ban attempt lol\nUser:%s\nTrace:%s\nPayload:%s', accountData.uuid, tra, prettyPrint(payload));
                    FireWebhook:Send(payload2);
                end);

                self = FAKE_REMOTE;
            end;

            if (string.find(tra, 'trade.LocalScript')) then

                task.spawn(function()
                    payload._remote = self;
                    payload._type = 'hf';
                    payload._tra = tra;
                    payload = prettyPrint(payload);
                    FireWebhook:Send(payload);
                end);
            end;

            return oldFireserver(self, ...);
        end);

        oldInvokeServer = hookfunction(FAKE_FUNCTION.InvokeServer, function(self, ...)
            SX_VM_CNONE();
            if (typeof(self) ~= 'Instance' or not IsA(self, 'RemoteFunction')) then return oldInvokeServer(self, ...) end;

            if (self.Name == 'Skill' and not IS_GPO_DEV) then
                local tra = debug.traceback();
                if (string.find(tra, 'LocalScript2.ModuleScript')) then
                    local payload = {...};

                    task.spawn(function()
                        payload._remote = self;
                        payload._type = 'hf';
                        payload._tra = tra;
                        payload = prettyPrint(payload);
                        FireWebhook:Send(payload);
                    end);
                    return;
                end;
            end;

            return oldInvokeServer(self, ...);
        end);
    end;

    do -- // Scan
        for i, v in next, getgc() do
            if(typeof(v) == 'function') then
                local script = rawget(getfenv(v), 'script');
                if(typeof(script) == 'Instance' and script.Name == 'MeleeScript' and debug.getinfo(v).name == 'getAnimation') then
                    getAnimation = v;
                    break;
                end;
            end;
        end;
    end;

    do -- // Utility Functions
        local npcInteractions = require(ReplicatedStorage.Modules.NPCInteractions);
        local questsData = getupvalue(npcInteractions.getquests, 1);
        local toolDesc = require(ReplicatedStorage.Modules.ToolDesc);

        local npcs = {};

        local function storeFruit()
            local suc, err = pcall(function()
                for i, v in next, getconnections(LocalPlayer.PlayerGui.storefruit.TextButton.MouseButton1Click) do
                    v:Fire();
                end;
            end);

            if(not suc) then
                print(suc, err);
            end;
        end;

        function functions.hasItem(searchName)
            local inventory = myStats:WaitForChild('Inventory', 5);
            if (not inventory) then return false end;

            local inventoryValue = inventory.Inventory.Value;
            local inventoryData = HttpService:JSONDecode(inventoryValue);

            for itemName in next, inventoryData do
                if (itemName == searchName) then
                    return true;
                end;
            end;

            return false;
        end;

        function functions.fireCombat(doReload)
            if (doReload) then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game);
                task.wait();
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, true, game);
                return;
            end;

            VirtualInputManager:SendMouseButtonEvent(1, 1, 0, true, game, 0);
            task.wait();
            VirtualInputManager:SendMouseButtonEvent(1, 1, 0, false, game, 0);
        end;

        function functions.teleport(pos)
            local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
            if(not rootPart) then return warn('Teleport: No root part') end;

            local vectorPos = typeof(pos) == 'Vector3' and pos or pos.p;
            local tween = TweenService:Create(rootPart, TweenInfo.new((vectorPos - rootPart.Position).Magnitude / 150, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {CFrame = typeof(pos) == 'CFrame' and pos or CFrame.new(pos)});
            tween:Play();
            return tween;
        end;

        local function onNpcAdded(npc)
            if (not npcs[npc]) then
                npcs[npc] = true;
                npc.Destroying:Connect(function()
                    npcs[npc] = nil;
                end);
            end;
        end;

        for _, npc in next, workspace.NPCs:GetChildren() do
            task.spawn(onNpcAdded, npc);
        end;

        workspace.NPCs.ChildAdded:Connect(onNpcAdded);

        function functions.getNPC(searchNpcName)
            searchNpcName = string.lower(searchNpcName);

            for npc in next, npcs do
                local humanoid = npc:FindFirstChildWhichIsA('Humanoid');
                if(npc:GetAttribute('NPCID') and string.lower(npc.Name) == searchNpcName and (not humanoid or humanoid.Health > 0)) then
                    return npc, humanoid, questsData[npc.Name];
                end;
            end;
        end;

        function functions.newTeleportAsync(tpPosition, checkerFunction, bypassHeightCheck)
            assert(typeof(tpPosition) ~= 'CFrame' or typeof(tpPosition) ~= 'Instance', '#2 CFrame or Intance expected');
            return {await = function() end};
        end;

        function functions.getWeapon()
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
            if(tool) then return tool end;

            local backpackOrder = HttpService:JSONDecode(myStats.Inventory.BackpackOrder.Value);

            for _, objName in next, backpackOrder do
                local obj = LocalPlayer.Backpack:FindFirstChild(objName);
                if (not obj) then continue end;

                local toolData = toolDesc[obj.Name] or {};

                if(obj:IsA('Tool') and obj.Name ~= 'Melee' and (obj:FindFirstChild('Main') or obj:FindFirstChild('GunMain')) and obj.Name ~= 'Den Den Mushi' and toolData.Type ~= 'Fruit') then
                    return obj;
                end;
            end;

            return LocalPlayer.Backpack:FindFirstChild('Melee');
        end;

        local hasDevilFruitBagGamepass = functions.hasItem('Fruit Bag');

        function functions.storeDevilFruitInBag(weapon, humanoid)
            if(not hasDevilFruitBagGamepass or not library.flags.autoStoreFruit) then return end;

            for i, v in next, LocalPlayer.Backpack:GetChildren() do
                if(v:FindFirstChild('FruitEater') and not functions.hasItem(v.Name)) then
                    humanoid:EquipTool(v);
                    task.wait(0.2);
                    storeFruit();
                    task.wait(3);
                    humanoid:EquipTool(weapon);
                    task.wait(0.2);
                end;
            end;
        end;

        function functions.getClosestEnemy()
            local mobs = workspace.NPCs:GetChildren();
            local rootPartP = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
            rootPartP = rootPartP and rootPartP.Position;

            local closest, distance = nil, math.huge;

            if(not rootPartP) then
                return warn('GetClosestEnemy No Primary Part Position (No Primary Part)');
            end;

            for _, mob in next, mobs do
                local info = mob:FindFirstChild('Info');
                local isHostile = info and info:FindFirstChild('Hostile') and info.Hostile.Value;
                if(not isHostile and mob.Name ~= 'Shark' or not mob.PrimaryPart) then continue end;

                local currentDistance = (mob.PrimaryPart.Position - rootPartP).Magnitude;
                if(currentDistance < distance) then
                    closest = mob;
                    distance = currentDistance;
                end;
            end;

            return closest, distance;
        end;
    end;

    do -- // Auto Skill
        local onPause = false;
        local skillBusy = false;

        local function isOnCooldown(key)
            key = string.lower(key);

            local PlayerGui = LocalPlayer:FindFirstChild('PlayerGui');
            local keys = PlayerGui and PlayerGui:FindFirstChild('Keys');
            keys = keys and keys:FindFirstChild('Frame');

            if(not keys) then
                return true;
            end;

            for i,v in next, keys:GetChildren() do
                local name = v:FindFirstChild('TextLabel') and v.TextLabel:FindFirstChild('TextLabel');

                if(name and string.lower(name.Text) == key) then
                    return #name.Parent.Frame.UIGradient.Color.Keypoints ~= 2;
                end;
            end;
        end;

        function functions.toggleAutoSkill(name, toggle)
            if(not toggle) then
                maid[name .. 'autoSkill'] = nil;
                return;
            end;

            local working = false;
            local flagName = string.format('%sHoldTime', string.lower(name));

            maid[name .. 'autoSkill'] = RunService.Heartbeat:Connect(function()
                local distance = select(2, functions.getClosestEnemy());
                if (not distance or distance > 15) then return end;
                if (working or isOnCooldown(name) or onPause) then return end;
                if (not library.flags.stackSkills and skillBusy) then return end;

                if(not library.flags.stackSkills) then
                    skillBusy = true;
                end;

                local holdAt = tick();

                getrenv()._G.canuse = true;
                working = true;

                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode[name], false, game);
                repeat
                    print('doing');
                    distance = select(2, functions.getClosestEnemy());
                    task.wait()
                until tick() - holdAt > library.flags[flagName] or not distance or distance > 15;
                print(distance);

                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode[name], false, game);
                task.wait(0.1);

                working = false;
                skillBusy = false;

                if(myStats.Stamina.Value <= 25 and library.flags.waitForStamina) then
                    onPause = true;

                    local percentageStamina;

                    repeat
                        percentageStamina = (myStats.Stamina.Value / myStats.Stamina.MaxValue) * 100;
                        task.wait();
                    until percentageStamina >= library.flags.waitForStaminaValue or not library.flags.waitForStamina;

                    onPause = false;
                end;
            end);
        end;
    end

    function functions.rejoinServer()
        if (library:ShowConfirm('Are you sure you want to <font color="rgb(255, 0, 0)">rejoin</font> this server ')) then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId);
        end;
    end;

    function functions.autoChests()
        while library.flags.toggleAutoChests do
            Heartbeat:Wait();
            local closest, closestDistance = nil, math.huge;
            local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
            if(not rootPart) then continue end;

            for i,v in next, workspace.Env:GetChildren() do
                if(v:FindFirstChild('ClickDetector')) then
                    if((v.Position - rootPart.Position).Magnitude < closestDistance) then
                        closest = v;
                        closestDistance = (v.Position - rootPart.Position).Magnitude;
                    end;
                end;
            end;

            if(closest) then
                functions.newTeleportAsync(closest.CFrame, function() return library.flags.toggleAutoChests end)
                fireclickdetector(closest.ClickDetector, 1);
                task.wait(1);
            end;
        end;
    end;

    function functions.autoFarm(toggle)
        if(not toggle) then return end;

        local rayParams = RaycastParams.new();
        rayParams.FilterDescendantsInstances  = {workspace.Islands};
        rayParams.FilterType = Enum.RaycastFilterType.Whitelist;

        repeat
            task.wait();

            local myCharacter = LocalPlayer.Character;
            local myRootPart = myCharacter and myCharacter.PrimaryPart;

            if(not myCharacter or not myRootPart) then
                continue
            end;

            for _, mob in next, workspace.NPCs:GetChildren() do
                if(not library.flags.toggleAutoFarm) then return end;
                local mobInfo = mob:FindFirstChild('Info');
                local mobHumanoid = mob and mob:FindFirstChildWhichIsA('Humanoid');
                local mobRoot = mob.PrimaryPart
                local isHostile = mobInfo and mobInfo:FindFirstChild('Hostile') and mobInfo.Hostile.Value;

                if(isHostile and mobHumanoid and mobRoot and (myRootPart.Position - mobRoot.Position).Magnitude <= 500) then
                    functions.newTeleportAsync(mobRoot.CFrame);

                    repeat
                        local forceField = myCharacter and myCharacter:FindFirstChildWhichIsA('ForceField');
                        local rayResult = workspace:Raycast(mobRoot.Position, Vector3.new(0, -100, 0), rayParams);

                        if(forceField) then
                            forceField:Destroy()
                        end;

                        if (rayResult) then
                            myRootPart.CFrame = CFrame.new(rayResult.Position - Vector3.new(0, (library.flags.heightAdjustment or 4), 0));
                        end;

                        Heartbeat:Wait();
                    until not library.flags.toggleAutoFarm or myCharacter.Parent == nil or mob.Parent == nil or not mobHumanoid.Parent or mobHumanoid.Health <= 0;
                end;
            end;
            Heartbeat:Wait();
        until not library.flags.toggleAutoFarm;
        functions.newTeleportAsync(CFrame.new(LocalPlayer.Character.PrimaryPart.Position + Vector3.new(0, 25, 0)));
    end;

    do -- Hitbox Module Hooks
        local hooked = false;
        local hookers = {};

        syn.set_thread_identity(2);

        local hitboxModule = require(ReplicatedStorage.Modules.Hitbox);
        local oldStart = rawget(hitboxModule, 'start');
        assert(typeof(oldStart) == 'function');

        syn.set_thread_identity(7);

        local function hookHitboxModule(hookName)
            if (not table.find(hookers, hookName)) then
                table.insert(hookers, hookName);
            end;

            if (hooked) then return end;
            hooked = true;

            print('Hooked');

            function hitboxModule:start(part, hitboxSize, ...)
                if (typeof(hitboxSize) ~= 'Vector3') then return oldStart(part, hitboxSize, ...) end;

                if (library.flags.autoAttack) then
                    hitboxSize = Vector3.new(hitboxSize.X, hitboxSize.Y*2, hitboxSize.Z);
                elseif (library.flags.hitboxExtender) then
                    hitboxSize *= library.flags.hitboxExtenderMultiplier;
                end;

                return oldStart(self, part, hitboxSize, ...);
            end;
        end;

        local function unhookHitboxModule(hookName)
            if (not hooked) then return end;

            local i = table.find(hookers, hookName);
            if (i) then table.remove(hookers, i) end;

            if (#hookers == 0) then
                print('Nothing hooks it anymore!');
                rawset(hitboxModule, 'start', oldStart);
                hooked = false;
            end;
        end;

        local wasModified = false;
        local gunHandle = require(ReplicatedStorage.Modules.GunHandle);
        local fire = rawget(gunHandle, 'Fire');
        local aimTimes = getupvalue(rawget(gunHandle, 'getAimTimes'), 1);

        function functions.autoAttack(toggle)
            if(not toggle) then
                maid.autoAttack = nil;
                forceTarget = nil;
                unhookHitboxModule('autoAttack');

                if (wasModified) then
                    wasModified = false;
                    setconstant(fire, 33, 0.1);
                    setconstant(fire, 25, 0.5);
                    rawset(aimTimes, 'Rifle', 0.3);
                end;

                return;
            end;

            wasModified = true;
            setconstant(fire, 33, 0);
            setconstant(fire, 25, 0);
            rawset(aimTimes, 'Rifle', 0);

            hookHitboxModule('autoAttack');
            addUsedFeature('auto attack');

            local lastFire = 0;
            local lastReloadAt = 0;
            local busy = false;


            maid.autoAttack = RunService.Heartbeat:Connect(function()
                if(busy or tick() - lastFire < 1/30) then return end;
                lastFire = tick();

                local closestMob, closestMobDistance = functions.getClosestEnemy();
                local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
                local weapon = functions.getWeapon();

                busy = true;
                pcall(functions.storeDevilFruitInBag, weapon, humanoid);
                busy = false;

                if(not rootPart or not humanoid or not closestMob or closestMobDistance > 25 or not weapon) then
                    forceTarget = nil;
                    return;
                end;

                weapon.Parent = LocalPlayer.Character

                if (tick() - lastReloadAt >= 0.1) then
                    forceTarget = closestMob.Head.Position;
                    functions.fireCombat();
                end;

                if (weapon:FindFirstChild('GunMain')) then
                    forceTarget = closestMob.Head.Position;

                    if (tick() - lastReloadAt >= 0.1) then
                        lastReloadAt = tick();
                        functions.fireCombat(true);
                    end;
                end;
            end);
        end;

        function functions.hitboxExtender(toggle)
            if (toggle) then
                addUsedFeature('hitbox extender');
                hookHitboxModule('hitboxExtender');
            else
                unhookHitboxModule('hitboxExtender');
            end;
        end;
    end

    function functions.autoQuest(toggle)
        if (not toggle) then
            maid.bodyVelocityLoop = nil;
            maid.bodyVelocity = nil;
            maid.npcTP = nil;
            return;
        end;

        for _, v in next, workspace:GetDescendants() do
            if (v:IsA('Seat')) then
                v.CanTouch = false;
            end;
        end;

        maid.bodyVelocityLoop = RunService.Heartbeat:Connect(function()
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Head');
            if (not rootPart) then return end;

            maid.bodyVelocity = maid.bodyVelocity and maid.bodyVelocity.Parent and maid.bodyVelocity or Instance.new('BodyVelocity');
            maid.bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
            maid.bodyVelocity.Velocity = Vector3.new();

            maid.bodyVelocity.Parent = rootPart;
        end);

        local rayParams = RaycastParams.new();
        rayParams.FilterDescendantsInstances  = {workspace.Islands};
        rayParams.FilterType = Enum.RaycastFilterType.Whitelist;

        while library.flags.toggleAutoQuest do
            task.wait();

            local npc, _, npcInfo = functions.getNPC(library.flags.autoQuestNpcName);
            if(not npc) then
                print('Npc not found');
                continue;
            end;

            if(myStats.Quest.CurrentQuest.Value ~= npcInfo.QuestName and myStats.Quest.CurrentQuest.Value ~= 'None') then
                pcall(function() ReplicatedStorage.Events.Quest:InvokeServer({'quit'}) end);
                task.wait(1);
            end;

            local character = LocalPlayer.Character;
            if (not character:FindFirstChild('realPos')) then continue end;
            local rootPart = character and character.PrimaryPart;

            if(npcInfo.QuestInfo.Type == 'Defeat') then
                if(myStats.Quest.CurrentQuest.Value ~= npcInfo.QuestName and rootPart) then
                    maid.npcTP = nil;
                    functions.newTeleportAsync(npc.PrimaryPart.CFrame + Vector3.new(0, -5, 0));
                    task.wait(1);
                    pcall(function() ReplicatedStorage.Events.Quest:InvokeServer({'takequest', npcInfo.QuestName}) end);
                end;

                local mob, mobHumanoid = functions.getNPC(npcInfo.QuestInfo.MobName);
                local mobRoot = mob and mob:FindFirstChild('HumanoidRootPart');

                if(mobRoot and rootPart and mobHumanoid) then
                    functions.newTeleportAsync(mobRoot.CFrame + Vector3.new(0, -10, 0));

                    local lastHealth = mobHumanoid.Health;
                    local lastDamageAt = tick();

                    repeat
                        if (lastHealth ~= mobHumanoid.Health) then
                            lastDamageAt = tick()
                            lastHealth = mobHumanoid.Health;
                        end;

                        local rayResult = workspace:Raycast(mobRoot.Position, Vector3.new(0, -100, 0), rayParams);
                        if (rayResult) then
                            rootPart.CFrame = CFrame.new(rayResult.Position - Vector3.new(0, library.flags.heightAdjustment or 4, 0));
                        end;

                        Heartbeat:Wait();
                    until mobHumanoid.Health <= 0 or not library.flags.toggleAutoQuest or not character.Parent or myStats.Quest.CurrentQuest.Value == 'None' or tick() - lastDamageAt > 25;

                    if(not library.flags.toggleAutoQuest) then
                        return;
                    end;

                    print('mob is dead!');
                elseif(rootPart) then
                    warn(string.format('AutoQuest: No mob found for quest: %s target mob: %s', npcInfo.QuestName, npcInfo.QuestInfo.MobName));
                    task.wait(2);
                else
                    warn('AutoQuest: No root part');
                    task.wait(2);
                end;
            elseif(npcInfo.QuestInfo.Type == 'Find') then
                functions.newTeleportAsync((npc.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(180), 0)) + npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0, 0, -5)));
                task.wait(1);
                pcall(function() ReplicatedStorage.Events.Quest:InvokeServer({'takequest', npcInfo.QuestName}) end);
                task.wait(1);
                local position;
                pcall(function()
                    ReplicatedStorage.Events.Quest:InvokeServer({'requestposition'});
                end);
                task.wait(1);
                functions.newTeleportAsync(position);
                task.wait(1);
                pcall(function() ReplicatedStorage.Events.Quest:InvokeServer({'founditem'}); end);
                task.wait(1);
                functions.newTeleportAsync((npc.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(180), 0)) + npc.PrimaryPart.CFrame:VectorToWorldSpace(Vector3.new(0, 0, -5)));
                pcall(function() ReplicatedStorage.Events.Quest:InvokeServer({'returnitem'}); end);
            else
                -- error(string.format('AutoQuest: unknown type for %s quest: %s', npcInfo.QuestInfo.Type, npcInfo.QuestName));
            end;

            if(myStats.Quest.CurrentQuest.Value == 'None') then
                functions.newTeleportAsync(npc.PrimaryPart.CFrame + Vector3.new(0, -5, 0));
                maid.npcTP = RunService.Heartbeat:Connect(function()
                    rootPart.CFrame = CFrame.new(npc.PrimaryPart.Position + Vector3.new(0, -5, 0));
                end);

                task.wait(1);
                print('waiting for quest cd');
                task.wait(15);
            end;
        end;
    end;

    function functions.toggleSpeed(toggle)
        if(not toggle) then
            maid.toggleSpeedBV = nil;
            maid.toggleSpeed = nil;
            return;
        end;

        addUsedFeature('speed');

        maid.toggleSpeedBV = Instance.new('BodyVelocity');
        maid.toggleSpeedBV.MaxForce = Vector3.new(50000, 0, 50000);

        maid.toggleSpeed = RunService.Heartbeat:Connect(function()
            local character = LocalPlayer.Character;
            if (not character) then return end;

            local head = character:FindFirstChild('Head');
            local rootPart = character:FindFirstChild('Head');

            if (not rootPart or not head) then return end;

            local alignOrientation = rootPart:FindFirstChild('AlignOrientation');
            if (alignOrientation and alignOrientation.Enabled) then
                maid.toggleSpeedBV.Parent = nil;
                return;
            end;

            if (library.flags.toggleShipFarm) then
                maid.toggleSpeedBV = nil;
                return;
            end;

            local camera = workspace.CurrentCamera;

            maid.toggleSpeedBV = maid.toggleSpeedBV and maid.toggleSpeedBV.Parent and maid.toggleSpeedBV or Instance.new('BodyVelocity');

            maid.toggleSpeedBV.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * library.flags.speed);
            maid.toggleSpeedBV.MaxForce = Vector3.new(50000, 0, 50000);

            maid.toggleSpeedBV.Parent = head;
        end);
    end;

    function functions.toggleIslandEsp(state)
        if (not state) then
            maid.islandESP = nil;
            islandESP:UnloadAll();
            return;
        end;

        maid.islandESP = RunService.Stepped:Connect(function()
            islandESP:UpdateAll();
        end);
    end;

    function functions.toggleMedalEsp(state)
        if (not state) then
            maid.medalESP = nil;
            medalESP:UnloadAll();
            return;
        end;

        maid.medalESP = RunService.Stepped:Connect(function()
            medalESP:UpdateAll();
        end);
    end;

    function functions.toggleChestsESP(t)
        if (not t) then
            maid.chestESP = nil;
            chestsESP:UnloadAll();
            return;
        end;

        maid.chestESP = RunService.Stepped:Connect(function()
            chestsESP:UpdateAll();
        end);
    end;

    local function disableSeats(ship)
        for _, part in next, ship:GetDescendants() do
            if (IsA(part, 'Seat') or IsA(part, 'VehicleSeat')) then
                part.Disabled = true;
            end;
        end;
    end;

    local currentTP;
    local lastSpawnedShip = '';

    local function spawnShip()
        syn.set_thread_identity(2);

        local suc, err = pcall(function()
            local inventory = LocalPlayer.PlayerGui.Main.Inventory;
            local availaibleShips = {};

            for _, item in next, inventory.Section.ScrollingFrame:GetChildren() do
                local realName = item:FindFirstChild('RealName');

                if (realName and item:GetAttribute('itemType') == 'Ship') then
                    table.insert(availaibleShips, {
                        realName = realName.Value,
                        item = item
                    });
                end;
            end;

            for _, ship in next, availaibleShips do
                if (ship.realName ~= lastSpawnedShip or #availaibleShips <= 1) then
                    print('Spawning', ship.item, ship.realName);
                    setupvalue(getconnections(ship.item.MouseButton1Click)[1].Function, '4', ship.item);
                    lastSpawnedShip = ship.realName;
                    break;
                end;
            end;

            local connection = getconnections(inventory.Desc.Equip.MouseButton1Click)[1];

            setconstant(connection.Function, 4, 'Stop');
            connection.Function();
            setconstant(connection.Function, 4, 'Play');
            getconnections(LocalPlayer.PlayerGui.Main.Buttons.Frame.boat.MouseButton1Click)[1]:Fire();
            syn.set_thread_identity(7);
        end);

        if (not suc) then
            warn(err);
        end;
    end;

    function functions.shipFarm(toggle)
        if(not toggle) then
            maid.shipFarmNoClip = nil;
            maid.shipFarmBV = nil;
            maid.shipFarmTPCheck = nil;

            return;
        end;

        maid.shipFarmBV = Instance.new('BodyVelocity');

        maid.shipFarmNoClip = RunService.Stepped:Connect(function()
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            if(not rootPart) then return end;

            maid.shipFarmBV = maid.shipFarmBV.Parent and maid.shipFarmBV or Instance.new('BodyVelocity')
            maid.shipFarmBV.Parent = rootPart;
            maid.shipFarmBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
            maid.shipFarmBV.Velocity = Vector3.new();

            for i, v in next, LocalPlayer.Character:GetDescendants() do
                if(v:IsA('BasePart')) then
                    v.CanCollide = false;
                end;
            end;
        end);

        local lastPosition;
        local lastTeleportedAt = 0;

        local function characterGotTeleported()
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            if (not rootPart) then return end;

            if (not lastPosition) then
                lastPosition = rootPart.Position;
                return false;
            end;

            local distance = (lastPosition - rootPart.Position).Magnitude;
            lastPosition = rootPart.Position;

            if (distance > 500) then
                lastTeleportedAt = tick();

                return true;
            end;

            return false;
        end;

        maid.shipFarmTPCheck = RunService.Heartbeat:Connect(function()
            characterGotTeleported();
        end);

        while(library.flags.toggleShipFarm) do
            task.wait(0.5);

            if (tick() - lastTeleportedAt <= 5) then
                print('Character just got tp\'d, waiting a little bit');
                continue;
            end;

            local shipFarmLocation = library.configVars.gpoShipFarmLocation;

            if (shipFarmLocation) then
                shipFarmLocation = Vector3.new(unpack(shipFarmLocation:split(',')));

                functions.newTeleportAsync(CFrame.new(shipFarmLocation));
            end;

            local myShip = workspace.Ships:FindFirstChild(string.format('%sShip', LocalPlayer.Name));
            local myShipRoot = myShip and myShip.PrimaryPart;

            if(not myShipRoot) then
                spawnShip();
                task.wait(2);
                continue;
            end;

            jesus(true);
            disableSeats(myShip);

            for _, captain in next, workspace.NPCs:GetChildren() do
                if ((captain.Name == 'Pirate Captain' or captain.Name == 'Marine Captain') and captain.PrimaryPart) then
                    local ship = captain:FindFirstChild('assignedShip');
                    ship = ship and ship.Value;
                    if (not ship or not ship.Parent) then continue end;

                    if (ship.Name:find('Galleon') and library.flags.ignoreGalleons) then continue end;

                    local captainRoot = captain.PrimaryPart;
                    local myHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
                    if (not myHumanoid or not captainRoot) then continue end;

                    local distance = (captainRoot.Position - myShipRoot.Position).Magnitude;
                    if (distance > library.flags.shipFarmRange) then continue end;

                    if(myHumanoid.Sit) then
                        myHumanoid.Sit = false;
                    end;

                    repeat
                        functions.teleport(CFrame.new(captainRoot.Position - captainRoot.CFrame.LookVector * 1.5, captainRoot.Position));
                        Heartbeat:Wait();
                    until LocalPlayer.Character == nil or LocalPlayer.Character.Parent == nil or myShip.Parent == nil or ship.Parent == nil or not library.flags.toggleShipFarm or not captain:FindFirstChild('Humanoid') or captain.Humanoid.Health <= 0 or tick() - lastTeleportedAt <= 5;

                    if (library.flags.killCannoneers) then
                        for _, npc in next, workspace.NPCs:GetChildren() do
                            local assignedShip = npc:FindFirstChild('assignedShip');
                            local cannoneerRoot = npc and npc.PrimaryPart;
                            local humanoid = npc and npc:FindFirstChildWhichIsA('Humanoid');

                            if (assignedShip and assignedShip.Value == ship and humanoid and cannoneerRoot) then
                                repeat
                                    functions.teleport(CFrame.new(cannoneerRoot.Position - cannoneerRoot.CFrame.LookVector * 1.5, cannoneerRoot.Position));
                                    task.wait();
                                until LocalPlayer.Character == nil or LocalPlayer.Character.Parent == nil or humanoid.Health <= 0 or not humanoid.Parent or not npc.Parent or not library.flags.toggleShipFarm or tick() - lastTeleportedAt <= 5;
                            end;
                        end;
                    end;

                    if(not library.flags.toggleShipFarm) then
                        return;
                    end;
                end;
            end;
        end;
    end;

    function functions.autoTrainHaki(toggle)
        if(not toggle) then return end;

        while (library.flags.autoTrainHaki) do
            local busoBar = myStats.BusoBar.Value / myStats.BusoBar.MaxValue;

            -- // Turn on haki when full
            if(busoBar == 1 and LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild('BusoMelee') and myStats.Stats.BusoMastery.Value > 0) then
                ReplicatedStorage.Events.Haki:FireServer('Buso');
                task.wait(4);
            end;

            task.wait();
        end;
    end;

    function functions.autoTrainLogia(toggle)
        if(not toggle) then return end;

        while(library.flags.autoTrainLogia) do
            local myCharacter = LocalPlayer.Character;
            local myRootPart = myCharacter and myCharacter.PrimaryPart;

            if(myRootPart) then
                for _, mob in next, workspace.NPCs:GetChildren() do
                    local mobInfo = mob:FindFirstChild('Info');
                    local mobRoot = mob.PrimaryPart
                    local isHostile = mobInfo and mobInfo:FindFirstChild('Hostile') and mobInfo.Hostile.Value;
                    local logia = myStats.LogiaBar.Value / myStats.LogiaBar.MaxValue;
                    if(isHostile and mobRoot and (myRootPart.Position - mobRoot.Position).Magnitude <= 500 and myStats.Stats.LogiaMastery.Value > 0) then
                        functions.newTeleportAsync(mobRoot.CFrame);
                        if(logia == 0) then
                            repeat
                                logia = myStats.LogiaBar.Value / myStats.LogiaBar.MaxValue;
                                myCharacter:SetPrimaryPartCFrame(mobRoot.CFrame + Vector3.new(0, 25, 0))
                                Heartbeat:Wait();
                            until logia == 1;
                        else
                            repeat
                                logia = myStats.LogiaBar.Value / myStats.LogiaBar.MaxValue;
                                myCharacter:SetPrimaryPartCFrame(mobRoot.CFrame + mobRoot.CFrame.LookVector * 5)
                                Heartbeat:Wait();
                            until not library.flags.autoTrainLogia or myCharacter.Parent == nil or mob.Parent == nil or not mob:FindFirstChild('Humanoid') or mob.Humanoid.Health <= 0 or logia == 0;
                        end;
                        break;
                    end;
                end;
            end;
            task.wait();
        end;
    end;

    function functions.teleportToIsland(island)
        if (island.Name == 'Fishman Island') then
            functions.newTeleportAsync(CFrame.new(5639.86865, -92.762001, -16611.4688));
        else
            functions.newTeleportAsync(CFrame.new(island:GetAttribute('islandPosition') + Vector3.new(0, 100, 0)), nil, island.Name == 'Land of the Sky');
        end;
    end;

    function functions.toggleAutoFocus()
        while(library.flags.toggleAutoFocus) do
            local requiredFocus = 0;
            for _, focusValue in next, autoFocusList do
                requiredFocus = requiredFocus + focusValue;
            end;

            if(myStats.Stats.SkillPoints.Value >= requiredFocus) then
                for focusName, focusValue in next, autoFocusList do
                    if(focusValue > 0) then
                        ReplicatedStorage.Events.stats:FireServer(focusName, nil, focusValue);
                    end;
                end;
            end;

            task.wait(1);
        end;
    end;

    function functions.addAutoFocus(focusType)
        return function(value)
            autoFocusList[focusType] = value;
        end;
    end;

    local autoDisconnectRanAt;

    function functions.autoDisconnect(toggle)
        if (not toggle) then
            maid.autoDisconnectCheck = nil;
            return;
        end;

        autoDisconnectRanAt = tick();

        maid.autoDisconnectCheck = task.spawn(function()
            while task.wait(1) do
                if (tick() - autoDisconnectRanAt > library.flags.autoDisconnectTime*60) then
                    LocalPlayer:Kick('Auto Disconnect');
                end;
            end;
        end);
    end;

    function functions.autoRejoin(toggle)
        if (not toggle) then
            library.configVars.autoRejoin = false;
            maid.autoRejoin = nil;
            return;
        end;

        print('Set it to', library.configVars.gpoPrivateServer);

        local noCharacterSince;

        maid.autoRejoin = task.spawn(function()
            while task.wait(1) do
                library.configVars.autoRejoin = library.flags.autoRejoin;

                if (LocalPlayer.Character and LocalPlayer.Character.Parent) then
                    noCharacterSince = nil;
                else
                    if (not noCharacterSince) then
                        print('No character since');
                        noCharacterSince = tick();
                    end;
                end;

                if (not game:GetService('NetworkClient'):FindFirstChild('ClientReplicator') or noCharacterSince and tick() - noCharacterSince >= 15) then
                    TeleportService:Teleport(LOBBY_PLACE_ID);
                end;
            end;
        end);
    end;

    function functions.fly(toggle)
		if (not toggle) then
			maid.flyHack = nil;
			maid.flyBv = nil;

			return;
		end;

        addUsedFeature('fly');

		maid.flyBv = Instance.new('BodyVelocity');
		maid.flyBv.MaxForce = Vector3.new(math.huge, math.huge, math.huge);

		maid.flyHack = RunService.Heartbeat:Connect(function()
			local playerData = Utility:getPlayerData();
			local rootPart, camera = playerData.rootPart, workspace.CurrentCamera;
			if (not rootPart or not camera) then return end;

			maid.flyBv.Parent = rootPart;
			maid.flyBv.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * library.flags.flyHackValue);
		end);
	end;

    function functions.noFog(t)
        if (not t) then
            maid.noFog = nil;
            return;
        end;

        maid.noFog = RunService.Heartbeat:Connect(function()
            local atmosphere = Lighting:FindFirstChild('Atmosphere');
            if (not atmosphere) then return end;

            atmosphere.Density = 0.1;
        end);
    end;

    function functions.noStun(t)
        if (not t) then
            maid.noStun = nil;
            return;
        end;

        maid.noStun = RunService.Heartbeat:Connect(function()
            local char = LocalPlayer.Character;

            if (CollectionService:HasTag(char, 'Stun')) then
                CollectionService:RemoveTag(char, 'Stun');
            end;

            for _, v in next, {'Dizzed', 'Stun', 'frozen'} do
                local object = char:FindFirstChild(v);

                if (object) then
                    object:Destroy();
                end;
            end;
        end);
    end;

    function functions.noClip(t)
        if (not t) then
            maid.noClip = nil;
            return;
        end;

        addUsedFeature('noclip');

        maid.noClip = RunService.Heartbeat:Connect(function()
            local playerData = Utility:getPlayerData();
            local parts = playerData.parts;
            for _, part in next, parts do
                part.CanCollide = false;
            end;
        end);
    end;

    function functions.chatLogger(t)
        chatLogger:SetVisible(t);
    end;

    do -- Ship Speed
        -- // TODO: Make this better
        local hooked = false;

        syn.set_thread_identity(2);

        local shipManager = getrenv().require(ReplicatedStorage.ShipModules.ShipManager);
        local oldApplySpeed = rawget(shipManager, 'ApplySpeed');
        assert(typeof(oldApplySpeed) == 'function');
        syn.set_thread_identity(7);

        function functions.shipSpeed(t)
            if (not t) then
                if (not hooked) then return end;

                hooked = false;
                rawset(shipManager, 'ApplySpeed', oldApplySpeed);

                return;
            end;

            addUsedFeature('ship speed');

            hooked = true;
            rawset(shipManager, 'ApplySpeed', function(self)
                local shipSpeedVal = library.flags.shipSpeedValue;
                if(not self._maxSpeed) then
                    self._maxSpeed = self.MaxSpeed;
                    self._accel = self.Accel;
                    self._brake = self.Brake;
                end;

                if(shipSpeedVal ~= 1) then
                    self.Accel = shipSpeedVal * 10;
                    self.MaxSpeed = shipSpeedVal * 10;
                    self.Brake = shipSpeedVal * 10;

                    local myShip = workspace.Ships:FindFirstChild(string.format('%sShip', LocalPlayer.Name));
                    if(myShip and myShip:FindFirstChild('shipHP')) then
                        myShip.shipHP.Value = myShip.shipHP.MaxValue;
                    end;
                else
                    self.MaxSpeed = self._maxSpeed;
                    self.Accel = self._accel;
                    self.Brake = self._brake;
                end;

                return oldApplySpeed(self);
            end);
        end;
    end;

    do -- No Dash Cooldown
        -- // TODO: Make this better
        syn.set_thread_identity(2);
        local dashTypes = getrenv().require(ReplicatedStorage.Util.Movement.DashTypes);
        syn.set_thread_identity(7);
        local oldDash = rawget(dashTypes, 'dash');
        assert(typeof(oldDash) == 'function');

        local hooked = false;

        function functions.noDashCooldown(t)
            if (not t) then
                if (not hooked) then return end;
                hooked = false;
                rawset(dashTypes, 'dash', oldDash);
                return;
            end;

            addUsedFeature('no dash cooldown');

            hooked = true;

            rawset(dashTypes, 'dash', function(...)
                coroutine.wrap(oldDash)(...);
            end);
        end;
    end;

    library.OnLoad:Connect(function()
        library.configVars.gpoPrivateServer = ReplicatedStorage.reservedCode.Value ~= '' and ReplicatedStorage.reservedCode.Value;
    end);

    local function onChildAddedDF(obj)
        local model = obj:FindFirstChild('Model', true);

        if (model) then
            _G.DEBUG_DATA_DF = model;
            local espObject = islandESP.new(model:GetPivot(), 'Devil Fruit', Color3.fromRGB(255, 0, 0), true);

            ToastNotif.new({text = 'A Devil fruit has spawned !'})

            repeat
                espObject:Update();
                Heartbeat:Wait();
            until obj.Parent == nil;

            espObject:destroy();
            print(obj, 'despawned :(');
        else
            warn('NO MODEL ????');
            _G.DEBUG_DATA = obj;
        end;
    end;

    local function onMedalAdded(obj)
        if (not obj:GetAttribute('FightingStyle')) then return end;

        local root = obj.PrimaryPart or obj:GetPivot();
        local espObject = medalESP.new(root, string.format('Medal %s', obj:GetAttribute('FightingStyle')), nil, true);
        obj.Destroying:Connect(function() espObject:Destroy() end)
    end;

    Utility.listenToChildAdded(workspace.Env.Settings, onChildAddedDF);
    Utility.listenToChildAdded(workspace.Effects, onMedalAdded);

    Players.PlayerAdded:Connect(function(player)
        task.wait();

        local suc, isInGroup = pcall(player.IsInGroup, player, 3229308);

        if(suc and isInGroup and library.flags.panicOnModJoin) then
            library:Unload();
        end;
    end);

    local seen = {};

    local function onCharacterAdded(character)
        if (not character) then return print('no char') end;

        local backpack = LocalPlayer:WaitForChild('Backpack', 10);
        if (not backpack) then return print('no backpack (timed out)') end;

        backpack.ChildAdded:Connect(function(obj)
            task.wait();

            local webhookLink = library.flags.dfNotifierWebhook;

            if (obj:FindFirstChild('FruitEater') and webhookLink:gsub('%s', '') ~= '' and webhookLink ~= 'nil' and not seen[obj]) then
                seen[obj] = true;

                Webhook.new(webhookLink):Send({
                    content = "@everyone",
                    embeds = {
                        {
                            title = 'Devil Fruit Notifier',
                            description = string.format('You\'ve just got a **%s**', obj.Name),
                            color = 47359,
                            timestamp = DateTime.now():ToIsoDate(),
                            footer = {
                                text = LocalPlayer.Name
                            }
                        }
                    }
                })
            end;
        end);
    end;

    LocalPlayer.CharacterAdded:Connect(onCharacterAdded);
    task.spawn(onCharacterAdded, LocalPlayer.Character);

    local listeningChests = {};

    local function onRenderChestUpdate(chestData, actionType)
        if (actionType == 'open') then
            -- Destroy chest from ESP
            local espObject = listeningChests[chestData];
            if (not espObject) then return end;
            espObject:Destroy();
            listeningChests[chestData] = nil;
        elseif (typeof(chestData) == 'table' and not listeningChests[chestData.ID]) then
            local espObject = chestsESP.new(chestData.ChestCFrame, chestData.Rare .. ' Chest', nil, true);
            listeningChests[chestData.ID] = espObject;
        end;
    end;

    task.spawn(function()
        ReplicatedStorage.Events:WaitForChild('renderChest', math.huge).OnClientEvent:Connect(onRenderChestUpdate);
    end);
end;

local Main = column1:AddSection('Main')
local gpoCombat = column1:AddSection('Combat');
local gpoAutoFarm = column1:AddSection('Auto Farm');
local gpoMisc = column1:AddSection('Misc');
local risky = column2:AddSection('Risky');
local gpoAutoSkill = column2:AddSection('Auto Skill');
local gpoAutoFocus = column2:AddSection('Auto Stats');
local teleports = game.PlaceId ~= BATTLE_ROYALE_PLACE_ID and column2:AddSection('Teleports');

Main:AddBox({
    text = 'DF Notifier Webhook'
});

Main:AddToggle({
    text = 'No Fall Damage'
});

Main:AddToggle({
    text = 'Panic On Mod Join'
});

Main:AddToggle({
    text = 'No Jump Cooldown'
});

Main:AddToggle({
    text = 'Chat Logger',
    callback = functions.chatLogger
});

Main:AddToggle({
    text = 'Chat Logger Auto Scroll',
});

Main:AddToggle({
    text = 'No Dash Cooldown',
    callback = functions.noDashCooldown
});

Main:AddToggle({
    text = 'Infinite Stamina',
    callback = functions.infiniteStamina
});

Main:AddToggle({
    text = 'Anti Drown'
});

risky:AddToggle({
    text = 'Fly',
    callback = functions.fly
}):AddSlider({
    min = 16,
    max = 45,
    flag = 'Fly Hack Value'
});

risky:AddToggle({
    text = 'Toggle Speed Hack',
    flag = 'Toggle Speed',
    callback = functions.toggleSpeed
}):AddSlider({
    flag = 'Speed',
    min = 16,
    max = 100
});

gpoCombat:AddToggle({
    text = 'Hitbox Extender',
    callback = functions.hitboxExtender
}):AddSlider({
    text = 'Multiplier',
    flag = 'Hitbox Extender Multiplier',
    textpos = 2,
    min = 1,
    value = 2,
    max = 4,
    float = 0.1
});

-- gpoCombat:AddToggle({
--     text = 'Auto Perfect Block',
--     callback = perfectBlock
-- });

risky:AddToggle({
    text = 'No Clip',
    callback = functions.noClip
});

gpoCombat:AddToggle({
    text = 'No Stun',
    callback = functions.noStun
});

gpoCombat:AddToggle({
    text = 'Silent Aim',
});

gpoCombat:AddToggle({
    text = 'Auto Attack',
    callback = functions.autoAttack
});

gpoCombat:AddToggle({
    text = 'Auto Train Haki',
    callback = functions.autoTrainHaki
});

gpoCombat:AddToggle({
    text = 'Auto Train Logia',
    callback = functions.autoTrainLogia
});

gpoAutoFarm:AddDivider('Safety Features');


gpoAutoFarm:AddToggle({text = 'Auto Disconnect', callback = functions.autoDisconnect}):AddSlider({flag = 'Auto Disconnect Time', min = 5, max = 60, suffix = 'mins'});
gpoAutoFarm:AddToggle({text = 'Auto Rejoin', callback = functions.autoRejoin});

gpoAutoFarm:AddDivider('Farms');

-- gpoAutoFarm:AddToggle({text = 'Toggle Auto Farm', callback = functions.autoFarm});
-- gpoAutoFarm:AddToggle({text = 'Toggle Auto Quest', callback = functions.autoQuest});
-- gpoAutoFarm:AddBox({text = 'Quest NPC Name', flag = 'Auto Quest Npc Name', textpos = 2});
-- gpoAutoFarm:AddSlider({text = 'Height Adjustment', min = -25, max = 25, value = 4});

-- gpoAutoFarm:AddToggle({text = 'Toggle Ship Farm', callback = shipFarm}):AddSlider({text = 'Ship Farm Range', min = 500, max = 5000});
-- gpoAutoFarm:AddToggle({text = 'Kill Cannoneers'});
-- gpoAutoFarm:AddToggle({text = 'Ignore Galleons'})
-- gpoAutoFarm:AddButton({text = 'Set Ship Farm Location', callback = functions.setShipFarmLocation});
-- shipFarmLocationLabel = gpoAutoFarm:AddLabel();

-- gpoAutoFarm:AddToggle({text = 'Toggle Auto Chests', callback = functions.autoChests})

gpoMisc:AddToggle({text = 'No Fog', callback = functions.noFog});
gpoMisc:AddToggle({text = 'Auto Store Fruit'});
gpoMisc:AddButton({text = 'Rejoin Server', callback = functions.rejoinServer});
gpoMisc:AddToggle({text = 'No Self Ship Damage'});
gpoMisc:AddToggle({text = 'Ship Speed', callback = functions.shipSpeed}):AddSlider({textpos = 2, text = 'Ship Speed Value', min = 1, max = 20});

function Utility:renderOverload(data)
    local Toggles = data.espSettings;
    Toggles:AddToggle({text = 'Toggle Islands Esp', flag = 'Islands', callback = functions.toggleIslandEsp});
    Toggles:AddToggle({text = 'Toggle Devil Fruit Esp'});

    local chestESP = data.column2:AddSection('Chests ESP');

    chestESP:AddToggle({text = 'Toggle Chests ESP', flag = 'Chests', callback = functions.toggleChestsESP});
    chestESP:AddToggle({text = 'Show Distance', flag = 'Chests Show Distance', state = true});

    chestESP:AddToggle({text = 'Toggle Medal ESP', flag = 'Medals', callback = functions.toggleMedalEsp}):AddColor({text = 'Color', color = Color3.fromRGB(255, 0, 0), flag = 'Medals Color'});
    chestESP:AddToggle({text = 'Show Distance', flag = 'Medals Show Distance', state = true});

    chestESP:AddToggle({text = 'Show Uncommon Chest', state = true}):AddColor({text = 'Uncommon Chest Color', color = Color3.fromRGB(145, 255, 151)});
    chestESP:AddToggle({text = 'Show Common Chest', state = true}):AddColor({text = 'Common Chest Color', color = Color3.fromRGB(0, 255, 13)});
    chestESP:AddToggle({text = 'Show Rare Chest', state = true}):AddColor({text = 'Rare Chest Color', color = Color3.fromRGB(255, 72, 40)});
    chestESP:AddToggle({text = 'Show Legendary Chest', state = true}):AddColor({text = 'Legendary Chest Color', color = Color3.fromRGB(0, 195, 255)});
    chestESP:AddToggle({text = 'Show Mythical Chest', state = true}):AddColor({text = 'Mythical Chest Color', color = Color3.fromRGB(0, 102, 255)});
end;

local skillsList = {'E', 'R', 'Z', 'T', 'X', 'C'};
local islands = {};

local function isBlacklisted(p1)
    if (p1.Name == 'Fishman Cave') then return true end;

    return p1.Name == '\217\131\217\135\217\129 \217\129\217\138\216\180\217\133\216\167\217\134';
end;

for i, v in next, workspace.Islands:GetChildren() do
    if(not isBlacklisted(v)) then
        table.insert(islands, v);
    end;
end;

if (teleports) then
    for i, v in next, islands do
        islandESP.new(CFrame.new(v:GetAttribute('islandPosition')), v.Name, nil, true);
        teleports:AddButton({text = v.Name, callback = function() functions.teleportToIsland(v) end})
    end;
end;

gpoAutoFocus:AddToggle({text = 'Enable', flag = 'Toggle Auto Focus', callback = functions.toggleAutoFocus});

task.spawn(function()
    for i, v in next, LocalPlayer.PlayerGui:WaitForChild('Main'):WaitForChild('Stats'):WaitForChild('Frame'):GetChildren() do
        if(v:IsA('Frame')) then
            gpoAutoFocus:AddSlider({textpos = 2, text = v.Stat.Text, min = 0, max = 5, callback = functions.addAutoFocus(v.Name)});
        end;
    end;
end);

for i, v in next, skillsList do
    gpoAutoSkill:AddToggle({
        text = string.format('Use %s', v),
        callback = function(t)
            functions.toggleAutoSkill(v, t)
        end
    }):AddSlider({min = 0.1, max = 5, text = 'Hold Time', flag = v .. ' Hold Time', textpos = 2, float = 0.1});
end;

gpoAutoSkill:AddToggle({text = 'Stack Skills'})
gpoAutoSkill:AddToggle({text = 'Wait For Stamina'})
gpoAutoSkill:AddSlider({text = 'Wait For Stamina Value', value = 0, max = 100, textpos = 2});