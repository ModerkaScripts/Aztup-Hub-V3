local library = sharedRequire('@UILibrary.lua');

local ToastNotif = sharedRequire('@classes/ToastNotif.lua');
local TextLogger = sharedRequire('@classes/TextLogger.lua');
local EntityESP = sharedRequire('@classes/EntityESP.lua');
local ControlModule = sharedRequire('@classes/ControlModule.lua');

local createBaseESP = sharedRequire('@utils/createBaseESP.lua');
local toCamelCase = sharedRequire('@utils/toCamelCase.lua');
local prettyPrint = sharedRequire('@utils/prettyPrint.lua');
local findPlayer = sharedRequire('@utils/findPlayer.lua');
local getImageSize = sharedRequire('@utils/getImageSize.lua');

local Services = sharedRequire('@utils/Services.lua');
local Utility = sharedRequire('@utils/Utility.lua');
local Maid = sharedRequire('@utils/Maid.lua');
local BlockUtils = sharedRequire('@utils/BlockUtils.lua');

local column1, column2 = unpack(library.columns);

local disableenvprotection = disableenvprotection or function() end;
local enableenvprotection = enableenvprotection or function() end;

local Players, Lighting, RunService, UserInputService, ReplicatedStorage, CoreGui, NetworkClient = Services:Get(
    'Players',
    'Lighting',
    'RunService',
    'UserInputService',
    'ReplicatedStorage',
    'CoreGui',
    'NetworkClient'
);

local TeleportService, GuiService, CollectionService, HttpService, VirtualInputManager, MemStorageService, TweenService, StarterGui = Services:Get(
    'TeleportService',
    'GuiService',
    'CollectionService',
    'HttpService',
    'VirtualInputManager',
    'MemStorageService',
    'TweenService',
    'StarterGui'
);

local Heartbeat = RunService.Heartbeat;

local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local FindFirstChild = game.FindFirstChild;
local IsA = game.IsA;
local IsDescendantOf = game.IsDescendantOf;

local startMenu;
local ranSince = tick();

repeat
    startMenu = LocalPlayer and LocalPlayer:FindFirstChild('PlayerGui') and LocalPlayer.PlayerGui:FindFirstChild('StartMenu');
    task.wait();
until startMenu or tick() - ranSince >= 10 or LocalPlayer.Character;

if(tick() - ranSince >= 10) then
    print('[Rogue Lineage Anti Bug] Timeout excedeed!');
    while true do
        TeleportService:Teleport(3016661674);
        task.wait(5);
    end;
else
    print('[Rogue Lineage Anti Bug] Timeout not excedeed!')
end;

local isGaia = game.PlaceId == 5208655184;
local spawnLocations = {};

local fly;
local wipe;
local noFog;
local noClip;
local maxZoom;
local respawn;
local infMana;
local antiFire;
local autoSell;
local spamClick;
local autoSmelt;
local speedHack;
local noInjuries;
local noClipXray;
local fullBright;
local instantLog;
local manaAdjust;
local autoPickup;
local setLocation;
local toggleMobEsp;
local toggleNpcEsp;
local toggleBagEsp;
local streamerMode;
local infiniteJump;
local clickDestroy;
local autoPickupBag;
local spellStacking;
local spectatePlayer;
local setOverlayUrl;
local showCollectorPickupUI;
local antiHystericus;
local removeKillBricks;
local toggleTrinketEsp;
local collectorAutoFarm;
local toggleIngredientsEsp;
local toggleSpellAdjust;
local toggleSpellAutoCast;
local buildAutoPotion;
local buildAutoCraft;
local manaViewer;
local manaHelper;
local disableAmbientColors;
local autoPickupIngredients;
local aaGunCounter;
local showManaOverlay;
local goToGround;
local pullToGround;
local attachToBack;
local noStun;
local showCastZone;
local temperatureLock;
local daysFarm;
local allowFood;
local serverHop;
local gachaBot;
local scroomBot;
local loadSound;
local satan;
local spellStack;
local spellCounter;

local Trinkets = {};
local spellValues = {};
local Ingredients = {"Acorn Light","Glow Scroom","Lava Flower","Canewood","Moss Plant","Freeleaf","Trote","Scroom","Zombie Scroom","Potato","Tellbloom","Polar Plant","Strange Tentacle","Vile Seed","Ice Jar","Dire Flower","Crown Flower","Bloodthorn","Periascroom","Orcher Leaf","Uncanny Tentacle","Creely","Desert Mist","Snow Scroom"};

local trinkets = {};
local ingredients = {};
local mobs = {};
local npcs = {};
local bags = {};
local queue = {};

local Bots;

do -- // Download Assets
    local assetsList = {'IllusionistJoin.mp3', 'IllusionistLeft.mp3', 'IllusionistSpectateEnd.mp3', 'IllusionistSpectateStart.mp3', 'ModeratorJoin.mp3', 'ModeratorLeft.mp3'};
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

do -- // Mod Ban Analytics
    local disconnectedPlayers = {};
    local sentUserIds = false;

    local function onPlayerRemoving(plr)
        disconnectedPlayers[plr.UserId] = tick();
    end;

    GuiService.ErrorMessageChanged:Connect(function(msg)
        print(msg);

        if(string.find(msg, 'banned from the game') and not string.find(msg, 'Incident ID') and not sentUserIds) then
            print('[Moderator Detection] Sending report ...');

            sentUserIds = true;
            local userIds = {};

            for i, v in next, Players:GetPlayers() do
                if(not v:IsFriendsWith(LocalPlayer.UserId) and v.UserId ~= LocalPlayer.UserId) then
                    table.insert(userIds, v.UserId);
                end;
            end;

            for userId, userLeftAt in next, disconnectedPlayers do
                if(tick() - userLeftAt <= 120) then
                    table.insert(userIds, userId);
                else
                    print(string.format('[Moderator Detection] Removed %s from the list', userId));
                    userIds[userId] = nil;
                end;
            end;

            print(syn.request({
                Url = 'https://aztupscripts.xyz/api/v1/moderatorDetection',
                Method = 'POST',
                Headers = {
                    ['Content-Type'] = 'application/json',
                    Authorization = websiteScriptKey
                },
                Body = HttpService:JSONEncode({
                    userIds = userIds
                })
            }).Body)
        end;
    end);

    Players.PlayerRemoving:Connect(onPlayerRemoving);
end;

local function fromHex(str)
    return (str:gsub('..', function (cc)
        return string.char(tonumber(cc, 16));
    end));
end;

-- Y am I hardcoding this?

local cipherIV = fromHex('f25cbb355f61317ce02de60cb81168ea');
local cipherKey = fromHex('90cf0e772789b4a244076a352cce2fa3eb1a18898dc4612c14fbd033f3320b2c');

local chatLogger = TextLogger.new({
	title = 'Chat Logger',
	preset = 'chatLogger',
	buttons = {'Spectate', 'Copy Username', 'Copy User Id', 'Copy Text', 'Report User'}
});

do -- // Functions
    local tango;
    local fallDamage;
    local dodge;
    local manaCharge;
    local dialog;
    local dolorosa;
    local changeArea;

    local getTrinketType;
    local ingredientsFolder;

    local solveCaptcha;

    local isPrivateServer = ReplicatedStorage:FindFirstChild('ServerType') and ReplicatedStorage.ServerType.Value ~= 'Normal';

    -- LocalPlayer:Kick();
    -- game:GetService('GuiService'):ClearError();

    local collectorUI;
    local apiEndpoint = USE_INSECURE_ENDPOINT and 'http://test.aztupscripts.xyz/api/v1/' or 'https://aztupscripts.xyz/api/v1/';

    local moderatorIds = syn.request({
        Url = string.format('%smoderatorDetection', apiEndpoint),
        Headers = {['X-API-Key'] = websiteScriptKey}
    }).Body;

    moderatorIds = syn.crypto.custom.decrypt(
        'aes-cbc',
        syn.crypt.base64.encode(moderatorIds),
        cipherKey,
        cipherIV
    );

    local injuryObjects = {'Careless', 'PsychoInjury', 'MindWarp', 'NoControl', 'Maniacal', 'BrokenLeg', 'BrokenArm', 'VisionBlur'};

    local noclipBlocks = {};
    local killBricks = {};
    local trinketsData = {};
    local playerClassesList = {};
    local playerClasses = {};
    local remotes = {};
    local allMods = {};
    local illusionists = {};

    local autoCraftUtils = {};

    local trinketEspBase = createBaseESP('trinketEsp', trinkets);
    local ingredientEspBase = createBaseESP('ingredientEsp', ingredients);
    local mobEspBase = createBaseESP('mobEsp', mobs);
    local npcEspBase = createBaseESP('npcEsp', npcs);
    local bagEspBase = createBaseESP('bagEsp', bags);

    local moderatorInGame = false;
    local sprinting = false;
    local playerGotManualKick = false;

    local artefactOrderList;

    local findServer;
    local oldFireServer;

    local maid = Maid.new();

    local rayParams = RaycastParams.new();
    rayParams.FilterDescendantsInstances = {workspace.Live};
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist;

    do -- // Get Ingredient Folder
        for i, v in next, workspace:GetChildren() do
            if(v:IsA("Folder")) then
                local union = v:FindFirstChild('UnionOperation');
                if(union) then
                    ingredientsFolder = v;
                    break;
                end;
            end;
        end;
    end;

    local function getPlayerStats(player)
        if(isGaia) then
            return player:GetAttribute('FirstName') or 'Unknown', player:GetAttribute('LastName') or 'Unknown';
        else
            local leaderstats = player:FindFirstChild('leaderstats');
            local firstName = leaderstats and leaderstats:FindFirstChild('FirstName');
            local lastName = leaderstats and leaderstats:FindFirstChild('LastName');

            if(not leaderstats or not firstName or not lastName) then
                return 'Unknown', 'Unknown';
            end;

            return firstName.Value, lastName.Value;
        end;
    end;

    local function chargeMana()
        if(not manaCharge) then return end;

        if(isGaia) then
            manaCharge.FireServer(manaCharge, {math.random(1, 10), math.random()});
        else
            manaCharge.FireServer(manaCharge, true);
        end;
    end;

    local function dechargeMana()
        if(not manaCharge) then return end;

        if(isGaia) then
            manaCharge.FireServer(manaCharge);
        else
            manaCharge.FireServer(manaCharge, false);
        end;
    end

    local function canUseMana()
        local character = LocalPlayer.Character;
        if(not character) then return end;

        if (character:FindFirstChild('Grabbed')) then return end;
        if (character:FindFirstChild('Climbing')) then return end;
        if (character:FindFirstChild('ClimbCoolDown')) then return end;

        if (character:FindFirstChild('ManaStop')) then return end;
        if (character:FindFirstChild('SpellBlocking')) then return end;
        if (character:FindFirstChild('ActiveCast')) then return end;
        if (character:FindFirstChild('Stun')) then return end;

        if CollectionService:HasTag(character, 'Knocked') then return end;
        if CollectionService:HasTag(character, 'Unconscious') then return end;

        return true;
    end;

    local function makeNotification(title, text)
        return ToastNotif.new({text = title .. ' - ' .. text})
    end;

    local function spawnLocalCharacter()
        if(not LocalPlayer.Character) then
            library.base.Enabled = false;

            local startMenu = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('StartMenu');
            local finish = startMenu.Choices.Play

            repeat
                local btnPosition = finish.AbsolutePosition + Vector2.new(40, 40);
                local overlay = finish.Parent and finish.Parent.Parent and finish.Parent.Parent:FindFirstChild('Overlay');
                if (not overlay) then task.wait(); continue end;

                VirtualInputManager:SendMouseButtonEvent(btnPosition.X, btnPosition.Y, 0, true, game, 1);
                task.wait();
                VirtualInputManager:SendMouseButtonEvent(btnPosition.X, btnPosition.Y, 0, false, game, 1);
                task.wait();
            until LocalPlayer.Character;

            library.base.Enabled = true;
        end;

        return LocalPlayer.Character;
    end;

    local function kickPlayer(reason)
        if (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Danger')) then
            repeat
                task.wait()
            until not LocalPlayer.Character:FindFirstChild('Danger');
        end;

        playerGotManualKick = true;
        LocalPlayer:Kick(reason);
        task.wait(1);
    end;

    do -- // Anti Cheat Bypass
        local Humanoid = Instance.new('Humanoid', game);

        local Animation = Instance.new('Animation');
        Animation.AnimationId = 'rbxassetid://4595066903';

        local Play = Humanoid:LoadAnimation(Animation).Play;
        Humanoid:Destroy();

        local getKey;

        local function grabKeyHandler()
            if(isGaia) then
                for i, v in next, getgc() do
                    if(typeof(v) == 'function' and islclosure(v) and not is_synapse_function(v) and table.find(getconstants(v), 'plum')) then
                        local keyHandler = getupvalue(v, 1);
                        if(typeof(keyHandler) == 'table' and typeof(rawget(keyHandler, 1)) == 'function') then
                            getKey = rawget(keyHandler, 1);
                            break
                        end;
                    end;
                end;
            else
                for i, v in next, getgc(true) do
                    if(typeof(v) == 'table' and rawget(v, 'getKey')) then
                        getKey = rawget(v, 'getKey');
                        break;
                    end;
                end;
            end;
        end;

        getgenv().remotes = {};
        local function setRemote(name, remote, isPcall)
            -- print('[Remote Grabbed] Got', name, 'as', remote);

            if (isPcall) then remote = isPcall; end;
            getgenv().remotes[name] = remote;

            if(name == 'tango') then
                tango = remote;
            elseif(name == 'fallDamage') then
                fallDamage = remote;
            elseif(name == 'dodge') then
                dodge = remote;
            elseif(name == 'manaCharge') then
                manaCharge = remote;
            elseif(name == 'dialog') then
                dialog = remote;
            elseif(name == 'dolorosa') then
                dolorosa = remote;
            elseif(name == 'changeArea') then
                changeArea = remote;
            end;
        end;

        grabKeyHandler();
        if(not getKey) then
            warn('Didn\'t got keyhandler retrying with loop...');
            repeat
                grabKeyHandler();
                task.wait(2);
            until getKey;
        end;

        hookfunction(Instance.new('Part').BreakJoints,newcclosure(function() end));

        local oldPlay;
        oldPlay = hookfunction(Play, newcclosure(function(self)
            if (isUserTrolled) then return oldPlay(self) end;
            if(typeof(self) == 'Instance' and self.ClassName == 'AnimationTrack' and (string.find(self.Animation.AnimationId, '4595066903'))) then
                return warn('Ban Attempt -> Play');
            end;

            return oldPlay(self);
        end));

        oldFireServer = hookfunction(Instance.new('RemoteEvent').FireServer, function(self, ...)
            if(typeof(self) ~= 'Instance' or not self:IsA('RemoteEvent') or isUserTrolled) then return oldFireServer(self, ...); end;
            if(debugMode) then
                -- print(prettyPrint({
                --     ...,
                --     __self = self,
                --     __traceback = debug.traceback()
                -- }));
            end;

            if(not tango) then return print('Remote return cause no tango got!'); end;
            if(not isGaia and self == tango) then return warn('Ban Attempt -> Drop'); end;

            local args = {...};
            if(self == tango) then
                local sprintData = rawget(args, 1);
                local sprintValue = sprintData and rawget(sprintData, 1);
                local randomValue = sprintData and rawget(sprintData, 2);

                if(typeof(randomValue) == 'number' and not (randomValue <= 4 and randomValue >= 2)) then
                    print('[Tango Args]', randomValue <= 4, randomValue >= 2, randomValue, sprintValue);
                    return warn('Ban Attempt -> Tango');
                elseif((sprintValue == 1 or sprintValue == 2) and randomValue < 3) then
                    print(randomValue);
                    print(sprintValue);
                    sprinting = sprintValue == 1;
                    dechargeMana();
                end;

                -- print(sprintValue);
                -- sprinting = sprintValue == 1;
                -- -- if(sprintValue == 1) then
                -- -- end;
            elseif(self == dolorosa) then
                return warn('Ban Attempt -> Dolorosa');
            elseif(self == fallDamage and (library.flags.noFallDamage or library.flags.collectorAutoFarm) and not checkcaller()) then
                return warn('Fall Damage -> Attempt');
            elseif(self.Name == 'LeftClick') then
                if(library.flags.antiBackfire) then
                    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
                    if(not tool) then return oldFireServer(self, ...) end;

                    -- local useSnap = library.flags[toCamelCase(tool.Name .. ' Use Snap')];
                    local amount = spellValues[tool.Name]
                    amount = amount and amount[1];

                    if(not amount) then return oldFireServer(self, ...) end;

                    local mana = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Mana');
                    if(mana.Value < amount.min or mana.Value > amount.max) then
                        return;
                    end;
                end;
            elseif(self.Name == 'RightClick') then
                if(library.flags.antiBackfire) then
                    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
                    if(not tool) then return oldFireServer(self, ...) end;

                    -- local useSnap = library.flags[toCamelCase(tool.Name .. ' Use Snap')];
                    local amount = spellValues[tool.Name]
                    amount = amount and amount[2];

                    if(not amount) then return oldFireServer(self, ...) end;

                    local mana = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Mana');
                    if(mana.Value < amount.min or mana.Value > amount.max) then
                        return;
                    end;
                end;
            elseif(self == changeArea and library.flags.temperatureLock) then
                args[1] = 'Oresfall'
                return oldFireServer(self, unpack(args));
            end;

            return oldFireServer(self, ...);
        end);

        remotes.loadKeys = true;

        -- // Thanks Unluac
        local TANGO_PASSWORD = 30195.341357415226
        local POST_DIALOGUE_PASSWORD = 404.5041892976703
        local DODGE_PASSWORD = 398.00010021400533
        local APPLY_FALL_DAMAGE_PASSWORD = 90.32503962905011
        local SET_MANA_CHARGE_STATE_PASSWORD = 27.81839265298673

        if(isGaia) then
            do -- // FindFirstChild Hook cuz recursive FindFirstChild is so laggy
                local soundService = game:GetService('SoundService');

                local turrets = workspace.Turrets;
                local turretsBody = turrets:FindFirstChild('Body', true);
                local map = workspace.Map;

                local killBrick = map:FindFirstChild('KillBrick', true);
                local lavaBrick = map:FindFirstChild('Lava', true);

                local robloxGui = CoreGui:FindFirstChild('RobloxGui');
                local oldFindFirstChild;
                oldFindFirstChild = hookfunction(game.FindFirstChild, newcclosure(function(self, itemName, recursive)
                    if(checkcaller() or typeof(self) ~= 'Instance' or typeof(itemName) ~= 'string') then return oldFindFirstChild(self, itemName, recursive) end;

                    if(itemName == 'Body' and self == turrets and recursive) then
                        return turretsBody;
                    elseif(itemName == 'KB' and self == soundService) then
                        return nil;
                    elseif(itemName == 'Lava' and self == map) then
                        return lavaBrick;
                    elseif(itemName == 'KillBrick' and self == map) then
                        return killBrick;
                    elseif(itemName == 'RobloxGui' and self == game and recursive) then
                        return robloxGui;
                    elseif(itemName == 'Players' and self == game and recursive) then
                        return Players;
                    elseif(itemName == 'Server Pinger' and self == game and recursive) then
                        return nil;
                    end;

                    return oldFindFirstChild(self, itemName, recursive);
                end));
            end;
        end;

        local cameraMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance;

        local oldNewIndex;
        local oldNameCall;
        local oldIndex;

        local requests = ReplicatedStorage:WaitForChild('Requests');
        local myRemotes;

        local function onCharacterAdded(character)
            if(not character) then return end;
            local myNewRemotes = character:WaitForChild('CharacterHandler') and character.CharacterHandler:WaitForChild('Remotes');
            if(not myNewRemotes) then return end;

            myRemotes = myNewRemotes;

            task.delay(1,function()
                ReplicatedStorage.Requests.GetMouse.OnClientInvoke = function()
                    local mouseT = {};

                    mouseT.Hit = Mouse.Hit;
                    mouseT.Target = Mouse.Target;
                    mouseT.UnitRay = Mouse.UnitRay;
                    mouseT.X = Mouse.X;
                    mouseT.Y = Mouse.Y;

                    if (library.flags.silentAim) then
                        local target = Utility:getClosestCharacter(rayParams);
                        target = target and target.Character;

                        local cam = workspace.CurrentCamera;
                        local worldToViewportPoint = cam.WorldToViewportPoint;
                        local viewportPointToRay = cam.ViewportPointToRay;

                        if (target and target.PrimaryPart) then
                            local pos = worldToViewportPoint(cam, target.PrimaryPart.Position);

                            mouseT.Hit = target.PrimaryPart.CFrame;
                            mouseT.Target = target.PrimaryPart;
                            mouseT.X = pos.X;
                            mouseT.Y = pos.Y;
                            mouseT.UnitRay = viewportPointToRay(cam, pos.X, pos.Y, 1)
                            mouseT.Hit = target.PrimaryPart.CFrame;
                        end;
                    end;

                    if library.flags.spellStack then
                        --Wait until keypress?
                        --Make it a table queue sort of thing that removes oldest first?
                        print("HOLDING FIRE")
                        local info = {currentTime = tick(), fired = false};
                        table.insert(queue,info);

                        spellCounter.Text = string.format('Spell Counter: %d', Utility:countTable(queue));
                        repeat
                            task.wait();
                        until info.fired or tick()-info.currentTime >= 2;

                        for i,v in next, queue do 
                            if v.currentTime == info.currentTime then
                            
                                queue[i] = nil;
                                break;
                            end
                        end
                        
                        table.foreach(queue,warn)

                        spellCounter.Text = string.format('Spell Counter: %d', Utility:countTable(queue));
                        warn("FIRING")
                    end

                    return mouseT;
                end;
            end)

        end;

        onCharacterAdded(LocalPlayer.Character);
        LocalPlayer.CharacterAdded:Connect(onCharacterAdded);

        local cachedRemotes = {};

        oldIndex = hookmetamethod(game, '__index', function(self, p)
            SX_VM_CNONE();
            if(not tango) then
                return oldIndex(self, p);
            end;

            -- if(string.find(debug.traceback(), 'KeyHandler')) then
            --     warn('kay handler call __index', self, p);
            -- end;

            if(p == 'MouseButton1Click' and IsA(self, 'GuiButton') and library.flags.autoBard) then
                local caller = getcallingscript();
                caller = typeof(caller) == 'Instance' and oldIndex(caller, 'Parent');

                if(caller and oldIndex(caller, 'Name') == 'BardGui') then
                    local fakeSignal = {};
                    function fakeSignal.Connect(_, f)
                        coroutine.wrap(function()
                            local outerRing = FindFirstChild(self, 'OuterRing');
                            if(outerRing) then
                                repeat
                                    task.wait();
                                until oldIndex(outerRing, 'Parent') == nil or outerRing.Size.X.Offset <= 135;
                                if(oldIndex(outerRing, 'Parent')) then
                                    f();
                                end;
                            end;
                        end)();
                    end;
                    fakeSignal.connect = fakeSignal.Connect;
                    return fakeSignal;
                end;
            elseif(self == LocalPlayer and p == 'CameraMaxZoomDistance' and not checkcaller()) then
                local stackTrace = debug.traceback();

                if(not string.find(stackTrace, 'CameraModule')) then
                    return cameraMaxZoomDistance;
                end;
            end;

            return oldIndex(self, p);
        end);

		local getMouse = ReplicatedStorage.Requests.GetMouse;

        oldNewIndex = hookmetamethod(game, '__newindex', function(self, p, v)
            SX_VM_CNONE();
            -- local Character = oldIndex(LocalPlayer, 'Character');
            -- local CharacterHandler = Character and FindFirstChild(Character, 'CharacterHandler') or self;

            -- if(string.find(debug.traceback(), 'KeyHandler')) then
                -- warn('kay handler call __newindex', self, p, v);
            -- end;

            if(p == 'Parent' and IsA(self, 'Script') and oldIndex(self, 'Name') == 'CharacterHandler' and IsDescendantOf(self, LocalPlayer.Character)) then
                return warn('Ban Attempt -> Character Nil');
            elseif(tango and not checkcaller()) then -- // stuff that only triggers once ac is bypassed
                if(p == 'WalkSpeed' and IsA(self, 'Humanoid') and library.flags.speedHack) then
                    return;
                elseif((p == 'Ambient' or p == 'Brightness') and self == Lighting and library.flags.fullbright) then
                    return;
                elseif((p == 'FogEnd' or p == 'FogStart') and self == Lighting and library.flags.noFog) then
                    return;
                end;
			elseif (p == 'OnClientInvoke' and self == getMouse and not checkcaller()) then
				return;
            elseif(self == LocalPlayer and p == 'CameraMaxZoomDistance' and not checkcaller()) then
                cameraMaxZoomDistance = v;
            end;

            return oldNewIndex(self, p, v);
        end);

        oldNameCall = hookmetamethod(game, '__namecall', function(self, ...)
            SX_VM_CNONE();
            if(not remotes.loadKeys or checkcaller() or not string.find(debug.traceback(), 'ControlModule')) then
                return oldNameCall(self, ...);
            end;

            -- local args = {...};

            -- if(string.find(debug.traceback(), 'KeyHandler')) then
                -- warn('kay handler call __namecall', method);
            -- end;

            if(isGaia) then
                local oldGetKey = getKey;

                local function getKey(name, pwd)
                    local cachedRemote = cachedRemotes[name];

                    if(cachedRemote and cachedRemote.Parent and (cachedRemote.Parent == requests or cachedRemote.Parent == myRemotes)) then
                        return cachedRemote;
                    end;

                    cachedRemotes[name] = coroutine.wrap(oldGetKey)(name, pwd);
                    return cachedRemotes[name];
                end;

                --print(debug.traceback());
                if(debugMode) then
                    local getRemotes = (function()
                        tango = getKey(TANGO_PASSWORD, 'plum');

                        setRemote('tango', tango);
                        setRemote('fallDamage',getKey(APPLY_FALL_DAMAGE_PASSWORD, 'plum'));
                        setRemote('dodge', getKey(DODGE_PASSWORD, 'plum'));
                        setRemote('manaCharge', getKey(SET_MANA_CHARGE_STATE_PASSWORD, 'plum'));
                        setRemote('dialog', getKey(POST_DIALOGUE_PASSWORD, 'plum'));
                        setRemote('changeArea', getKey('SetCurrentArea', 'plum'));
                    end);

                    coroutine.wrap(getRemotes)();
                else
                    tango = getKey(TANGO_PASSWORD, 'plum');

                    setRemote('tango', tango);
                    setRemote('fallDamage',getKey(APPLY_FALL_DAMAGE_PASSWORD, 'plum'));
                    setRemote('dodge', getKey(DODGE_PASSWORD, 'plum'));
                    setRemote('manaCharge', getKey(SET_MANA_CHARGE_STATE_PASSWORD, 'plum'));
                    setRemote('dialog', getKey(POST_DIALOGUE_PASSWORD, 'plum'));
                    setRemote('changeArea', getKey('SetCurrentArea', 'plum'));
                end;
            else
                local character = oldIndex(LocalPlayer, 'Character');
                local characterHandler = character and FindFirstChild(character, 'CharacterHandler');
                local remotes = characterHandler and FindFirstChild(characterHandler, 'Remotes');

                disableenvprotection();

                setrawmetatable(false, {__index = function(_, p)
                    if (p == 'Parent') then
                        return true;
                    elseif (p == 'IsDescendantOf') then
                        return true;
                    end;
                end});

                setRemote('tango', pcall(getKey, 'Drop', 'apricot'));
                setRemote('fallDamage', pcall(getKey, 'FallDamage', 'apricot'));
                setRemote('dodge', remotes and FindFirstChild(remotes, 'Dash'));
                setRemote('manaCharge', pcall(getKey, 'Charge', 'apricot'));
                setRemote('dialog', pcall(getKey, 'SendDialogue', 'apricot'));
                setRemote('dolorosa', pcall(getKey, 'Dolorosa', 'apricot'));

                setrawmetatable(false, nil);

                enableenvprotection();
            end;

            remotes.loadKeys = false;

            task.delay(2, function()
                remotes.loadKeys = true;
            end);

            return oldNameCall(self, ...);
        end);

        local function onCharAdded(character)
            maid.charChildRemovedMana = character.ChildRemoved:Connect(function(obj)
                if(obj.Name == 'Sprinting') then
                    sprinting = false;
                end;
            end);

            repeat
                task.wait();
            until character:FindFirstChild('CharacterHandler') and character.CharacterHandler:FindFirstChild('Input');

            remotes.loadKeys = true;
        end;

        LocalPlayer.CharacterAdded:Connect(onCharAdded)

        if (LocalPlayer.Character) then
            onCharAdded(LocalPlayer.Character);
        end;
    end;

    do -- // Chat Logger
        local function containBlacklistedWord(text)
            text = string.lower(text);
            local blacklistedWords = {'cheater', 'hacker', 'exploiter', 'hack', 'cheat', 'exploit', 'report', string.lower(LocalPlayer.Name)}
            for i, v in next, blacklistedWords do
                if(string.find(text, v)) then
                    return true;
                end;
            end;

            return false;
        end;

        local function addText(player, ignName, message)
            local time = os.date('%H:%M:%S')
            local prefixBase = string.format('[%s] [%s] - %s', time, ignName or 'Unknwon', message);
            local prefixHover = string.format('[%s] [%s] - %s', time, player == LocalPlayer and 'You' or player.Name, message);
            local color = Color3.fromRGB(255, 255, 255);

            local originalText = string.format('[%s] [%s] [%s] %s', time, player.Name, ignName, message); -- Better version for report system

            if(illusionists[player]) then
                color = Color3.fromRGB(230, 126, 34);
            end;

            if(allMods[player] or not player.Character or containBlacklistedWord(message)) then
                color = Color3.fromRGB(231, 76, 60);

                if(not player.Character) then
                    prefixBase = '[Not Spawned In] ' .. prefixBase;
                    prefixHover = '[Not Spawned In] ' .. prefixHover;
                end;
            end;

            local textObject = chatLogger:AddText({
                color = color,
                player = player,
                text = prefixBase,
                originalText = originalText, -- Used for report system cause Rogue is special with mouseenter and mouseleave
            });

            textObject.OnMouseEnter:Connect(function()
                textObject:SetText(prefixHover);
            end);

            textObject.OnMouseLeave:Connect(function()
                textObject:SetText(prefixBase);
            end);
        end;

        chatLogger.OnPlayerChatted:Connect(function(player, message)
            if (not player or not message) then return end;

            local firstName, lastName = getPlayerStats(player);
            local playerFullName = firstName .. (lastName ~= "" and " " .. lastName or "");

            addText(player, playerFullName, message);
        end);
    end;

    do -- // Captcha Bypass
        local function readCSG(union)
            local unionData = select(2, getpcdprop(union));
            local unionDataStream = unionData;

            local function readByte(n)
                local returnData = unionDataStream:sub(1, n);
                unionDataStream = unionDataStream:sub(n+1, #unionDataStream);

                return returnData;
            end;

            readByte(51); -- useless data

            local points = {};

            while #unionDataStream > 0 do
                readByte(20) -- trash
                readByte(20) -- trash 2

                local vertSize =  string.unpack('ii', readByte(8));

                for i = 1, (vertSize/3) do
                    local x, y, z = string.unpack('fff', readByte(12))
                    table.insert(points, union.CFrame:ToWorldSpace(CFrame.new(x, y, z)).Position);
                end;

                local faceSize = string.unpack('I', readByte(4));
                readByte(faceSize * 4);
            end;

            return points;
        end;

        function solveCaptcha(union)
            local worldModel = Instance.new('WorldModel');
            worldModel.Parent = CoreGui;

            local newUnion = union:Clone()
            newUnion.Parent = worldModel;

            local cameraCFrame = gethiddenproperty(union.Parent, 'CameraCFrame');
            local points = readCSG(union);

            local rangePart = Instance.new('Part');
            rangePart.Parent = worldModel;
            rangePart.CFrame = cameraCFrame:ToWorldSpace(CFrame.new(-8, 0, 0))
            rangePart.Size = Vector3.new(1, 100, 100);

            local model = Instance.new('Model', worldModel);
            local baseModel = Instance.new('Model', worldModel);

            baseModel.Name = 'Base';
            model.Name = 'Final';

            for i, v in next, points do
                local part = Instance.new('Part', baseModel);
                part.CFrame = CFrame.new(v);
                part.Size = Vector3.new(0.1, 0.1, 0.1);
            end;

            local seen = false;

            for i = 0, 100 do
                rangePart.CFrame = rangePart.CFrame * CFrame.new(1, 0, 0)

                local overlapParams = OverlapParams.new();
                overlapParams.FilterType = Enum.RaycastFilterType.Whitelist;
                overlapParams.FilterDescendantsInstances = {baseModel};

                local bob = worldModel:GetPartsInPart(rangePart, overlapParams);
                if(seen and #bob <= 0) then break end;

                for i, v in next, bob do
                    seen = true;

                    local new = v:Clone();

                    new.Parent = model;
                    new.CFrame = CFrame.new(new.Position);
                end;
            end;

            for i, v in next, model:GetChildren() do
                v.CFrame = v.CFrame * CFrame.Angles(0, math.rad(union.Orientation.Y), 0);
            end;

            local shorter, found = math.huge, '';
            local result = model:GetExtentsSize();

            local values = {
                ['Arocknid'] = Vector3.new(11.963972091675, 6.2284870147705, 12.341609954834),
                ['Howler'] = Vector3.new(2.904595375061, 7.5143890380859, 6.4855442047119),
                ['Evil Eye'] = Vector3.new(6.7253036499023, 6.2872190475464, 11.757738113403),
                ['Zombie Scroom'] = Vector3.new(4.71413230896, 4.400146484375, 4.7931442260742),
                ['Golem'] = Vector3.new(17.123439788818, 21.224365234375, 6.9429664611816),
            };

            for i, v in next, values do
                if((result - v).Magnitude < shorter) then
                    found = i;
                    shorter = (result - v).Magnitude;
                end;
            end;

            worldModel:Destroy();
            worldModel = nil;

            return found;
        end;
    end;

    do -- // Collector Auto Farm
        local collectorData;

        local function getCollectorDoors()
            local doors = {};

            for i, v in next, workspace:GetChildren() do
                if(v.Name == 'Part' and v:FindFirstChild('Exit')) then
                    table.insert(doors, v);
                end;
            end;

            return doors;
        end;

        local function getCollectorDoor(collector)
            local lastDoor, lastDistance = nil, math.huge;

            for i, v in next, getCollectorDoors() do
                if((v.Position - collector.PrimaryPart.Position).Magnitude < lastDistance) then
                    lastDistance = (v.Position - collector.PrimaryPart.Position).Magnitude;
                    lastDoor = v;
                end;
            end;

            return lastDoor;
        end;

        local buttons = {};

        local dragging = false;
        local draggingBtn;
        local frame;

        local success, savedOrderData = pcall(readfile, 'Aztup Hub V3/RogueLineageCollectorBotList.json');

        if(success) then
            success, savedOrderData = pcall(function()
                return HttpService:JSONDecode(savedOrderData);
            end);
        end;

        artefactOrderList = success and savedOrderData or {
            'Azael Horn',
            'Staff of Pain',
            'Mask of Baima',
            'Phoenix Bloom',
            'Pocket Watch',
            'Heirloom',
            'Dienis Locket',
            'Unwavering Focus'
        };

        local function createComponent(c, p)
            local obj = Instance.new(c)
            obj.Name = tostring({}):gsub("table: ", ""):gsub("0x", "")
            for i, v in next, p do
                if i ~= "Parent" then
                    if typeof(v) == "Instance" then
                        v.Parent = obj
                    else
                        obj[i] = v
                    end
                end
            end
            obj.Parent = p.Parent
            return obj
        end;

        do -- // render button
            collectorUI = createComponent('ScreenGui', {
                Parent = CoreGui,
                Enabled = false,
            });

            frame = createComponent('Frame', { -- // main frame
                Parent = collectorUI,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.9, 0, 0.5, 0),
                Size = UDim2.new(0, 300, 0, 350),
                BackgroundColor3 = Color3.fromRGB(42, 42, 42),

                createComponent('UICorner', {
                    CornerRadius = UDim.new(0, 8)
                }),

                createComponent('Frame', { -- // border
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    Size = UDim2.new(1, 5, 1, 5),
                    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                    ZIndex = 0,

                    createComponent('UICorner', {
                        CornerRadius = UDim.new(0, 8)
                    })
                }),

                createComponent('TextLabel', { -- // title
                    Font = Enum.Font.Garamond,
                    Text = 'Aztup Hub V3 Collector Auto Farm Order List',
                    TextSize = 25,
                    TextWrapped = true,
                    BackgroundTransparency = 1,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextStrokeTransparency = 0.85,
                    Size = UDim2.new(1, 0, 0, 55),
                    TextStrokeColor3 = Color3.fromRGB(0, 0, 0),

                    createComponent('Frame', {
                        BackgroundColor3 = Color3.fromRGB(2, 255, 137),
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 2),
                        Position = UDim2.new(0, 0, 1, 0)
                    })
                })
            })
        end;

        local function positionButtons()
            for i,v in next, buttons do
                v.Size = UDim2.new(1, 0, 0, 25);
                v.LayoutOrder = i;
                v.Position = UDim2.new(0.5, 0, 0, 80 + (i - 1) * 25);
            end;
        end;

        local function dragger(container)
            local dragging;
            local dragInput;
            local dragStart;
            local startPos;

            local function update(input)
                local delta = input.Position - dragStart
                container.Position = UDim2.new(
                    0.5,
                    0,
                    startPos.Y.Scale,
                    math.clamp(startPos.Y.Offset + delta.Y, 80, frame.AbsoluteSize.Y - 20)
                );
            end

            container.InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    dragging = true
                    dragStart = input.Position
                    startPos = container.Position

                    input.Changed:Connect(function()
                        if (input.UserInputState == Enum.UserInputState.End) then
                            dragging = false
                            positionButtons();
                        end
                    end)
                end
            end)

            container.InputChanged:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    dragInput = input
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and dragging then
                    update(input)
                end
            end)
        end;

        local function update(btn)
            if(not dragging) then
                draggingBtn, dragging = btn, true;
                btn.ZIndex = 999;

                repeat
                    task.wait();
                until not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1);

                positionButtons();
                dragging, draggingBtn = false, nil;
                btn.ZIndex = 1;
            end;
        end;

        local function renderBtn()
            for i, v in next, artefactOrderList do
                local button = createComponent('TextButton', {
                    Parent = frame,
                    Active = true,
                    Text = v,
                    BackgroundTransparency = 1,
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Font = Enum.Font.Garamond,
                    AutoButtonColor = false,
                    TextScaled = true
                });

                table.insert(buttons, button);
                dragger(button);
            end;

            positionButtons();
        end;

        renderBtn();

        local tweenInfo = TweenInfo.new(0.2);

        do -- // Buttons Render
            for i, v in next, buttons do
                local tweenIn = TweenService:Create(v, tweenInfo, {TextColor3 = Color3.fromRGB(176, 176, 176)});
                local tweenOut = TweenService:Create(v, tweenInfo, {TextColor3 = Color3.fromRGB(255, 255, 255)});

                v.MouseButton1Down:Connect(function()
                    update(v);
                end);

                v.MouseEnter:Connect(function()
                    tweenIn:Play();
                    if(dragging and v ~= draggingBtn) then
                        local oldLayout = v.LayoutOrder;

                        v.LayoutOrder = draggingBtn.LayoutOrder;
                        draggingBtn.LayoutOrder = oldLayout;

                        table.sort(buttons, function(a, b)
                            return a.LayoutOrder < b.LayoutOrder;
                        end);

                        positionButtons();
                    end;
                end);

                v.MouseLeave:Connect(function()
                    tweenOut:Play();
                end);
            end;
        end;

        task.spawn(function()
            while true do
                local newOrderList = {};

                for i, v in next, buttons do
                    newOrderList[i] = v.Text;
                end;

                artefactOrderList = newOrderList;

                writefile('Aztup Hub V3/RogueLineageCollectorBotList.json', HttpService:JSONEncode(newOrderList));
                task.wait(1);
            end;
        end);

        local function getBestChoice(choices)
            local order = artefactOrderList;
            local foundChoice, foundChoicePosition = nil, 9999;

            for i, v in next, choices do
                for i2, v2 in next, order do
                    if(v2 == v and i2 <= foundChoicePosition) then
                        foundChoicePosition = i2;
                        foundChoice = v2;
                    end;
                end;
            end;

            return foundChoice;
        end;

        local function isDangerousPlayer(v)
            return v:FindFirstChild('Pebble') or v:FindFirstChild('Dagger Throw') or v:FindFirstChild('Autumn Rain') or v:FindFirstChild('Shadow Fan') or v:FindFirstChild('Triple Dagger Throw') or v:FindFirstChild('Justice Spears') or v:FindFirstChild('Augimas') or v:FindFirstChild('Perflora');
        end;

        function showCollectorPickupUI(toggle)
            collectorUI.Enabled = toggle;
        end;

        function collectorAutoFarm(toggle)
            if(not toggle or isPrivateServer or isGaia) then
                return;
            end;

            local function onConnectionLost()
                if (playerGotManualKick) then return end;

                while true do
                    if (library.flags.automaticallyRejoin) then
                        print('[Automatic Rejoin] Player got disconneted');
                        findServer();
                    end;

                    task.wait(10);
                end;
            end;

            if (not NetworkClient:FindFirstChild('ClientReplicator')) then
                return onConnectionLost();
            else
                NetworkClient.ChildRemoved:Connect(onConnectionLost);
            end;

            task.wait(2.5);

            local live = workspace:WaitForChild('Live');
            if (moderatorInGame) then return findServer() end;

            local function runPanicCheck(playerPosition)
                if (moderatorInGame) then
                    findServer();
                    return task.wait(9e9);
                end;

                local entities = live:GetChildren();

                for i, v in next, Players:GetPlayers() do
                    local character = v.Character;
                    if (character and not table.find(entities, character)) then
                        table.insert(entities, character);
                    end;
                end;

                for i, v in next, entities do
                    local playerRootPart = v:FindFirstChild('HumanoidRootPart');
                    if(not playerRootPart or v.Name == LocalPlayer.Name) then continue end;

                    local dangerousPlayer = isDangerousPlayer(v);
                    local playerDistance = (Utility:roundVector(playerRootPart.Position) - Utility:roundVector(playerPosition)).Magnitude;
                    local maxPlayerDistance = dangerousPlayer and math.huge or 300;

                    if(playerDistance <= maxPlayerDistance) then
                        print('Entity too close panicking', (playerRootPart.Position - playerPosition).Magnitude, v.Name, dangerousPlayer);
                        findServer();
                        return task.wait(9e9);
                    end;
                end;
            end;

            if(MemStorageService:HasItem('lastPlayerPosition')) then
                local playerPosition = Vector3.new(unpack(MemStorageService:GetItem('lastPlayerPosition'):split(',')));
                print('Last player position', playerPosition);

                runPanicCheck(playerPosition);
            else
                print('No last player position saving current one');
            end;

            local character = spawnLocalCharacter();

            LocalPlayer.CharacterAdded:Connect(function(newCharacter)
                kickPlayer('You were killed, please DM Aztup and sent him a clip if you have any, dont do that if you just pressed the menu button');
                task.wait(1);

                while true do end;
            end);

            local dangerConnection;
            dangerConnection = character.ChildAdded:Connect(function(obj)
                if (obj.Name == 'Danger') then
                    if (library.base.Enabled) then
                        library:Close();
                    end;

                    ToastNotif:DestroyAll();
                    library.options.chatLogger:SetState(false);
                end;
            end);

            task.wait(0.1);

            if(not MemStorageService:HasItem('collectorLocationTP')) then
                MemStorageService:SetItem('collectorLocationTP', math.random(1, 2) == 1 and '20' or '-20');
            end;

            local rootPart = character and character:WaitForChild('HumanoidRootPart', 10);
            local humanoid = character and character:WaitForChild('Humanoid', 10);

            if (not rootPart or not humanoid) then
                findServer();
                return;
            end;

            local lastNotificationSentAt = 0;

            repeat
                --print('[Collector Auto Farm] Waiting for collector to be grabbed ...');
                local lastDistance = math.huge;

                for i, v in next, workspace.NPCs:GetChildren() do
                    if(v.Name == 'Collector' and (v.PrimaryPart.Position - rootPart.Position).Magnitude <= 500) then
                        lastDistance = (v.PrimaryPart.Position - rootPart.Position).Magnitude;
                        collectorData = {door = getCollectorDoor(v), collector = v, distance = lastDistance};
                        break;
                    end;
                end;

                if(not collectorData and tick() - lastNotificationSentAt > 1) then
                    lastNotificationSentAt = tick();
                    ToastNotif.new({
                        text = 'You must be at the collector',
                        duration = 1
                    });
                end;

                if(not library.flags.collectorAutoFarm) then return end;
                task.wait();
            until collectorData;

            local collectorRoot = collectorData.collector:WaitForChild('HumanoidRootPart', 10);
            if (not collectorRoot) then
                return findServer();
            end;

            local params = RaycastParams.new();
            params.FilterType = Enum.RaycastFilterType.Whitelist;
            params.FilterDescendantsInstances = getCollectorDoors();

            runPanicCheck(rootPart.Position);
            MemStorageService:SetItem('lastPlayerPosition', tostring(rootPart.Position));

            local ranSince = tick();

            local function isDoorHere()
                local rayResult = workspace:Raycast(collectorRoot.Position + Vector3.new(0, 5, 0), collectorRoot.CFrame.LookVector * 250, params);
                local instance = rayResult and rayResult.Instance;

                if (not instance) then
                    return false;
                elseif(not instance.CanCollide) then
                    return false;
                end;

                return true;
            end;

            if (library.flags.rollOutOfFf) then
                local lastCFrame = rootPart.CFrame;
                local lastPosition = lastCFrame.Position;
                local lastDodgeAt = tick();

                repeat
                    if (tick() - lastDodgeAt > 1) then
                        lastDodgeAt = tick();
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game);
                    end;
                    task.wait();
                until rootPart:FindFirstChild('DodgeVel');

                task.wait(0.2);
                repeat task.wait() until not rootPart:FindFirstChild('DodgeVel');

                warn('dash finished ?!');
                task.wait(0.2 + math.random() * 1);

                local moveToFinished = false;

                task.spawn(function()
                    while (not moveToFinished) do
                        humanoid:MoveTo(lastPosition);
                        task.wait(1);
                    end;
                end);

                humanoid.MoveToFinished:Wait();
                moveToFinished = true;
            end;

            repeat -- // Wait for collector door to show ?
                local inDanger = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Danger');

                if(not rootPart.Parent and not inDanger) then
                    kickPlayer('You died, disconecting to prevent losing lives');
                    return;
                end;

                runPanicCheck(rootPart.Position);

                if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('ForceField') and not library.flags.rollOutOfFf) then
                    LocalPlayer.Character:FindFirstChildWhichIsA('ForceField'):Destroy();
                end;

                task.wait();
            until not isDoorHere() or tick() - ranSince >= library.flags.collectorBotWaitTime;

            if(isDoorHere()) then
                while true do
                    if(LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild('Danger')) then
                        ReplicatedStorage.Requests.ReturnToMenu:InvokeServer();
                        findServer();

                        task.wait(5);
                    end;

                    task.wait();
                end;
            end;

            dangerConnection:Disconnect();
            dangerConnection = nil;

            local artifactPickedUp;
            local choices;

            local function handleDialog(data)
                task.wait(1);

                if(data.choices) then
                    print('[Collector Auto Farm] Picking Up Artifact');

                    local artefactChoice = getBestChoice(data.choices);

                    artifactPickedUp = artefactChoice;
                    choices = data.choices;

                    dialog:FireServer({choice = artefactChoice});
                else
                    print('[Collector Bot] Exited!');
                    dialog:FireServer({exit = true});
                    task.wait(2);

                    repeat
                        task.wait();
                    until LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild('Danger');

                    if(artifactPickedUp) then
                        kickPlayer('You got a ' .. artifactPickedUp);

                        task.spawn(function()
                            pcall(function()
                                syn.request({
                                    Url = '',
                                    Method = 'POST',
                                    Headers = {
                                        ['Content-Type'] = 'application/json'
                                    },

                                    Body = HttpService:JSONEncode({
                                        content = 'Collector Bot',
                                        embeds = {{
                                            timestamp = DateTime.now():ToIsoDate(),
                                            title = 'Collector has been collected :tada:',
                                            color = 1345023,
                                            fields = {
                                                {
                                                    name = 'Artifact Chosen',
                                                    value = artifactPickedUp,
                                                },
                                                {
                                                    name = 'Options',
                                                    value = '['.. table.concat(choices or {'DM', 'Aztup'}, ', ') .. ']',
                                                },
                                            }
                                        }}
                                    })
                                });
                            end);
                        end);

                        task.spawn(function()
                            syn.request({
                                Url = library.flags.webhookUrl,
                                Method = 'POST',
                                Headers = {
                                    ['Content-Type'] = 'application/json'
                                },

                                Body = HttpService:JSONEncode({
                                    content = '@everyone',
                                    embeds = {{
                                        timestamp = DateTime.now():ToIsoDate(),
                                        title = 'Collector has been collected :tada:',
                                        color = 1345023,
                                        fields = {
                                            {
                                                name = 'Artifact Chosen',
                                                value = artifactPickedUp,
                                            },
                                            {
                                                name = 'Username',
                                                value = LocalPlayer.Name,
                                            },
                                            {
                                                name = 'Options',
                                                value = '['.. table.concat(choices or {'DM', 'Aztup'}, ', ') .. ']',
                                            }
                                        }
                                    }}
                                })
                            });
                        end);

                        artifactPickedUp = nil;
                    else
                        ReplicatedStorage.Requests.ReturnToMenu:InvokeServer();
                        task.wait(2);
                        return findServer();
                    end;
                end;
            end;

            dialog.OnClientEvent:Connect(handleDialog);
            task.wait(2.5);

            rootPart.CFrame = collectorRoot.CFrame:ToWorldSpace(CFrame.new(0, 0, -5));
            workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, workspace.CurrentCamera.CFrame.Position + collectorRoot.Position);

            print('[Collector Auto Farm] Collector is ready!');

            if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Immortal')) then
                LocalPlayer.Character.Immortal:Destroy();
            end;

            local function toggleGUI(state)
                local playerGui = LocalPlayer and LocalPlayer:FindFirstChild('PlayerGui');
                if(playerGui) then
                    for i, v in next, playerGui:GetChildren() do
                        if(v:IsA('ScreenGui') and v.Name ~= 'DialogueGui' and v.Name ~= 'Captcha' and v.Name ~= 'CaptchaLoading') then
                            v.Enabled = false;
                        end;
                    end;
                end;

                for i, v in next, game:GetService('CoreGui'):GetChildren() do
                    if(v:IsA('ScreenGui')) then
                        v.Enabled = state;
                    end;
                end;

                library.base.Enabled = state;
            end;

            toggleGUI(false);

            local elapsedTime = tick();

            repeat
                print('Clicking Click Detector Distance', (rootPart.Position - collectorRoot.Position).Magnitude);

                workspace.CurrentCamera.CameraSubject = collectorRoot;

                local pos = workspace.CurrentCamera:WorldToViewportPoint(collectorRoot.Position);

                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                task.wait();
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)

                task.wait(0.25);
            until LocalPlayer.PlayerGui:FindFirstChild('CaptchaLoad') or tick() - elapsedTime >= 8;
            -- // No need to add anything else since the auto dialog will serverhop as soon as collector gives exit

            if (tick() - elapsedTime >= 5) then
                ReplicatedStorage.Requests.ReturnToMenu:InvokeServer();
                task.wait(2);
                return findServer();
            end;

            repeat
                task.wait();
            until LocalPlayer.PlayerGui:FindFirstChild('Captcha');

            local lastWebhookSentAt = 0;
            local lastWebhookSentAt2 = 0;
            local lastWebhookSentAt3 = 0;

            repeat
                local captchaGUI = LocalPlayer.PlayerGui:FindFirstChild('Captcha');
                local choices = captchaGUI and captchaGUI:FindFirstChild('MainFrame') and captchaGUI.MainFrame:FindFirstChild('Options');
                choices = choices and choices:GetChildren();
                local union = captchaGUI and captchaGUI:FindFirstChild('MainFrame') and captchaGUI.MainFrame:FindFirstChild('Viewport') and captchaGUI.MainFrame.Viewport:FindFirstChild('Union');

                if(choices and union) then
                    local captchaAnswer = solveCaptcha(union);
                    if(tick() - lastWebhookSentAt > 0.1) then
                        lastWebhookSentAt = tick();
                    end;

                    for i, v in next, choices do
                        if(v.Name == captchaAnswer) then
                            if(tick() - lastWebhookSentAt2 > 0.1) then
                                lastWebhookSentAt2 = tick();
                            end;

                            local position = v.AbsolutePosition + Vector2.new(40, 40);
                            VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 1);
                            task.wait();
                            VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 1);

                            break;
                        end;
                    end;
                else
                    if(tick() - lastWebhookSentAt3 > 0.1) then
                        lastWebhookSentAt3 = tick();
                    end;
                end;

                task.wait();
            until not LocalPlayer.PlayerGui:FindFirstChild('Captcha');

            if(LocalPlayer.PlayerGui:FindFirstChild('CaptchaDisclaimer')) then
                task.wait(5);
            end;
        end;
    end;

    do -- // Set Trinkets
        Trinkets = {
            {
                ["MeshId"] = "5204003946";
                ["Name"] = "Goblet";
            };
            {
                ["MeshId"] = "5196776695";
                ["Name"] = "Ring";
            };
            {
                ["MeshId"] = "5196782997";
                ["Name"] = "Old Ring";
            };
            {
                ["Name"] = "Emerald";
            };
            {
                ["Name"] = "Ruby";
            };
            {
                ["Name"] = "Sapphire";
            };
            {
                ["Name"] = "Diamond";
            };
            {
                ["Name"] = "Rift Gem";
                ["Rare"] = true;
            };
            {
                ["Name"] = "Fairfrozen";
                ["Rare"] = true;
            };
            {
                ["MeshId"] = "5204453430";
                ["Name"] = "Ninja Scroll";
            };
            {
                ["Name"] = "Old Amulet";
                ["MeshId"] = "5196577540";
            };
            {
                ["Name"] = "Amulet";
                ["MeshId"] = "5196551436";
            };
            {
                ["Name"] = "Idol Of The Forgotten";
                ["ParticleEmitter"] = true;
            };
            {
                ["Name"] = "Opal";
                ["VertexColor"] = Vector3.new(1, 1, 1);
                ["MeshType"] = "Sphere";
            },
            {
                Name = "Candy";
                MeshId = '4103271893'
            },
            {
                ["Texture"] = "20443483";
                ["Name"] = "Ya'alda";
                ["Rare"] = true;
            };
            {
                ["Texture"] = "1536547385";
                ["Name"] = "Pheonix Down";
                ["Rare"] = true;
            };
            {
                ["Texture"] = "20443483";
                ["ParticleEmitter"] = true;
                ["PointLight"] = true;
                ["Name"] = "Ice Essence";
                ["Rare"] = true;
            };
            {
                ["Name"] = "White King's Amulet";
                ["Rare"] = true;
            };
            {
                ["Name"] = "Lannis Amulet";
                ["Rare"] = true;
            };
            {
                ["Name"] = "Night Stone";
                ["Rare"] = true;
            };
            {
                ["Name"] = "Philosopher's Stone";
                ["Rare"] = true;
            };
            {
                ["Name"] = "Spider Cloak";
                ["Rare"] = true;
            };
            {
                ["Name"] = "Howler Friend";
                ["Rare"] = true;
                ["MeshId"] = "2520762076";
            };
            {
                ["Name"] = "Scroom Key";
                ["Rare"] = true;
            },
            {
                Name = 'Mysterious Artifact',
                Rare = true
            }
        };

        for i, v in next, Trinkets do
            trinketsData[v.Name] = v;
        end;
    end;

    do -- // Player Classes
        playerClassesList = {
            ["Warrior"] = {
                ["Active"] = {"Pommel Strike", "Action Surge"};
                ["Classes"] = {
                    ["Sigil Knight"] = {"Thunder Charge", Level = 1};
                    ["Blacksmith"] = {"Remote Smithing", "Grindstone", "Shockwave", Level = 1};
                    ["Greatsword"] = {"Greatsword Training", "Stun Resistance", Level = 1};
                    ["Sigil Knight Commander"] = {"Charged Blow", "White Flame Charge", "Hyper Body", Level = 2};
                    ["Lapidarist"] = {"Hammer Training", "Improved Grindstone", "Gem Mastery", "Gem Abilities", Level = 2},
                    ["AbyssWalker"] = {"Wrathful Leap", "Abyssal Scream", Level = 2};
                    ["Wraith Knight"] = {"Wraith Training", Level = 2};
                    ["Pilgrim Knight"] = {"Chain of Fate", "Rod of Narsa", "Pasmarkinti", Level = 3};
                    ["Abyss Dancer"] = {"Great Cyclone", "Spinning Soul", "Void Slicer", "Deflecting Spin", Level = 3};
                    ["Reaper"] = {"Mirror", "Chase", "Hunt", "Soul Burst", Level = 3};
                }
            };
            ["Pit Fighter"] = {
                ["Active"] = {"Serpent Strike", "Triple Strike"};
                ["Classes"] = {
                    ["Dragon Knight"] = {"Spear Crusher", "Dragon Roar", "Dragon Blood", Level = 1};
                    ["Church Knight"] = {"Church Knight Helmet", "Impale", "Light Piercer", Level = 1};
                    ["Dragon Slayer"] = {"Wing Soar", "Thunder Spear Crash", "Dragon Awakening", Level = 2};
                    ["Deep Knight"] = {"Deep Sacrifice", "Leviathan Plunge", "Chain Pull", Level = 2};
                    ["Dragon Rider"] = {"Heroic Volley", "Call Drake", "Ensnaring Strike", "Justice Spears", Level = 3};
                    ["Abomination"] = {"Tethering Lance", "Void Spear", "Aura of Despair", "Soul Siphon", Level = 3};
                }
            };
            ["Scholar"] = {
                ["Active"] = {"FastSigns", "CurseBlock", "WiseCasting"};
                ["Classes"] = {
                    ["Illusionist"] = {"Custos", "Claritum", "Observe", Level = 1};
                    ["Botanist"] = {"Fons Vitae", "Verdien", "Life Sense", Level = 1};
                    ["Necromancer"] = {"Inferi", "Reditus", "Ligans", Level = 1};
                    ["Master Illusionist"] = {"Globus", "Intermissium", "Dominus", Level = 2};
                    ["Druid"] = {"Snap Verdien", "Snap Fons Vitae", "Perflora", "Snap Perflora", "Floresco", "Snap Floresco", Level = 2};
                    ["Master Necromancer"] = {"Secare", "Furantur", "Command Monsters", "Howler Summoning", Level = 2};
                    ["Uber Illusionist"] = {"Doube", "Compress", "Terra Rebus", Level = 3};
                    ["Monster Hunter"] = {"Coercere", "Liber", "Scribo", Level = 3};
                    ["Crystal Cage"] = {"Mirgeti", "Krusa", "Spindulys", Level = 3};
                    ["Worm Prophet"] = {"Worm Bombs", "Worm Blast", "Call of the Dead", Level = 3};
                }
            };
            ["Thief"] = {
                ["Active"] = {"Dagger Throw", "Pickpocket", "Trinket Steal", "Lock Manipulation"};
                ["Classes"] = {
                    ["Spy"] = {"Interrogation", Level = 1};
                    ["Assassin"] = {"Lethality", "Bane", "Triple Dagger Throw", Level = 1};
                    ["Whisperer"] = {"Elegant Slash", "The Shadow", "Needle's Eye", "The Wraith", "The Soul", Level = 2};
                    ["Cadence"] = {"Music Meter", "Faster Meter Charge", "Feel Invincible", Level = 2};
                    ["Faceless"] = {"Shadow Step", "Chain Lethality", "Improved Bane", "Faceless", Level = 2};
                    ["Shinobi"] = {"Resurrection", Level = 2};
                    ["Duelist"] = {"Mana Grenade", "Auto Reload", "Duelist Dash", "Bomb Jump", "Bullseye", Level = 3};
                    ["Uber Bard"] = {"Inferno March", "Galecaller's Melody", "Bad Time Symphony", "Theme of Reversal", Level = 3};
                    ["Friendless One"] = {"Shadow Buddy", "Falling Darkness", "Flash of Darkness", Level = 3};
                    ["Shura"] = {"Rising Cloud", "Autumn Rain", "Cruel Wind", Level = 3};
                };
            };
            ["Monk"] = {
                Level = 1,
                ["Active"] = {"Monastic Stance"};
                ["Classes"] = {
                    ["Dragon Sage"] = {"Lightning Drop", "Lightning Elbow", "Lightning Dash", "Dragon Static", Level = 2};
                    ["Vhiunese Monk"] = {"Thundering Leap", "Seismic Toss", "Electric Smite", Level = 3};
                };
            };
            ["Akuma"] = {
                ["Active"] = {"Leg Breaker", "Spin Kick", "Rising Dragon", Level = 1};
                ["Classes"] = {
                    ["Oni"] = {"Demon Flip", "Axe Kick", "Demon Step", Level = 2};
                    ["Uber Oni"] = {"Consuming Flames", "Rampage", "Augimas M1 & M2", "Axe Kick M2", Level = 3}
                };
            };
        };
    end;

    do -- // Server Hop
        local serverInfo = not isGaia and ReplicatedStorage:WaitForChild('ServerInfo'):GetChildren() or {};

        do -- // Server Hop Khei
            if(not isGaia and not isPrivateServer) then
                repeat
                    serverInfo = ReplicatedStorage:WaitForChild('ServerInfo'):GetChildren();
                    task.wait();
                until #serverInfo >= 2;
            end;
        end;

        function findServer(bypassKhei)
            if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Danger')) then
                repeat
                    task.wait();
                until not LocalPlayer.Character:FindFirstChild('Danger');
            end;

            task.delay(5, function()
                if (not NetworkClient:FindFirstChild('ClientReplicator') and library.flags.automaticallyRejoin) then
                    TeleportService:Teleport(3016661674);
                else
                    findServer(bypassKhei);
                end;
            end);

            if(not isGaia and not bypassKhei) then
                print('[Server Hop] Finding server ...');

                if(LocalPlayer.Character) then
                    ReplicatedStorage.Requests.ReturnToMenu:InvokeServer();
                    task.wait(2);
                end;

                local chosenServer = serverInfo[Random.new():NextInteger(1, #serverInfo)];
                local teleportHandler;

                teleportHandler = LocalPlayer.OnTeleport:Connect(function(state)
                    if(state == Enum.TeleportState.Failed) then
                        print('[Server Hop] Teleport failed');

                        teleportHandler:Disconnect();
                        teleportHandler = nil;

                        findServer();
                    end;
                end);

                print('Going to', chosenServer.Name);
                ReplicatedStorage.Requests.JoinPublicServer:FireServer(chosenServer.Name);
            else
                BlockUtils:BlockRandomUser();
                TeleportService:Teleport(3016661674);
            end;
        end;
    end;

    do -- // Set Spells Values
        spellValues = {
            ["Secare"] = {
                [1] = {
                ["max"] = 95,
                ["min"] = 90
                }
            },
            ["Maledicta Terra"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 20
                }
            },
            ["Better Mori"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 0
                },
                [2] = {
                ["max"] = 100,
                ["min"] = 0
                }
            },
            ["Contrarium"] = {
                [1] = {
                ["max"] = 95,
                ["min"] = 80
                },
                [2] = {
                ["max"] = 90,
                ["min"] = 70
                }
            },
            ["Mederi"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 0
                }
            },
            ["Scrupus"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 30
                }
            },
            ["Intermissum"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 70
                }
            },
            ["Gourdus"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 75
                }
            },
            ["Inferi"] = {
                [1] = {
                ["max"] = 30,
                ["min"] = 10
                }
            },
            ["Custos"] = {
                [1] = {
                ["max"] = 65,
                ["min"] = 45
                }
            },
            ["Gelidus"] = {
                [1] = {
                ["max"] = 95,
                ["min"] = 80
                },
                [2] = {
                ["max"] = 100,
                ["min"] = 80
                }
            },
            ["Telorum"] = {
                [1] = {
                ["max"] = 90,
                ["min"] = 80
                },
                [2] = {
                ["max"] = 80,
                ["min"] = 70
                }
            },
            ["Viribus"] = {
                [1] = {
                ["max"] = 35,
                ["min"] = 25
                },
                [2] = {
                ["max"] = 70,
                ["min"] = 60
                }
            },
            ["Hoppa"] = {
                [1] = {
                ["max"] = 60,
                ["min"] = 40
                },
                [2] = {
                ["max"] = 60,
                ["min"] = 50
                }
            },
            ["Velo"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 70
                },
                [2] = {
                ["max"] = 60,
                ["min"] = 40
                }
            },
            ["Pondus"] = {
                [1] = {
                ["max"] = 90,
                ["min"] = 70
                },
                [2] = {
                ["max"] = 30,
                ["min"] = 20
                }
            },
            ["Verdien"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 75
                },
                [2] = {
                ["max"] = 85,
                ["min"] = 75
                }
            },
            ["Trahere"] = {
                [1] = {
                ["max"] = 85,
                ["min"] = 75
                }
            },
            ["Dominus"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 50
                }
            },
            ["Armis"] = {
                [1] = {
                ["max"] = 60,
                ["min"] = 40
                },
                [2] = {
                ["max"] = 80,
                ["min"] = 70
                }
            },
            ["Ligans"] = {
                [1] = {
                ["max"] = 80,
                ["min"] = 63
                }
            },
            ["Shrieker"] = {
                [1] = {
                ["max"] = 50,
                ["min"] = 30
                }
            },
            ["Celeritas"] = {
                [1] = {
                ["max"] = 90,
                ["min"] = 70
                },
                [2] = {
                ["max"] = 80,
                ["min"] = 70
                }
            },
            ["Hystericus"] = {
                [1] = {
                ["max"] = 90,
                ["min"] = 75
                },
                [2] = {
                ["max"] = 35,
                ["min"] = 15
                }
            },
            ["Snarvindur"] = {
                [1] = {
                ["max"] = 75,
                ["min"] = 60
                },
                [2] = {
                ["max"] = 30,
                ["min"] = 20
                }
            },
            ["Percutiens"] = {
                [1] = {
                ["max"] = 70,
                ["min"] = 60
                },
                [2] = {
                ["max"] = 80,
                ["min"] = 70
                }
            },
            ["Furantur"] = {
                [1] = {
                ["max"] = 80,
                ["min"] = 60
                }
            },
            ["Nosferatus"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 90
                }
            },
            ["Reditus"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 50
                }
            },
            ["Floresco"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 90
                },
                [2] = {
                ["max"] = 95,
                ["min"] = 80
                }
            },
            ["Howler"] = {
                [1] = {
                ["max"] = 80,
                ["min"] = 60
                }
            },
            ["Manus Dei"] = {
                [1] = {
                ["max"] = 95,
                ["min"] = 90
                },
                [2] = {
                ["max"] = 60,
                ["min"] = 50
                }
            },
            ["Fons Vitae"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 75
                },
                [2] = {
                ["max"] = 100,
                ["min"] = 75
                }
            },
            ["Ignis"] = {
                [1] = {
                ["max"] = 95,
                ["min"] = 80
                },
                [2] = {
                ["max"] = 60,
                ["min"] = 50
                }
            },
            ["Globus"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 70
                }
            },
            ["Fimbulvetr"] = {
                [1] = {
                ["max"] = 92,
                ["min"] = 84
                },
                [2] = {
                ["max"] = 80,
                ["min"] = 70
                }
            },
            ["Perflora"] = {
                [1] = {
                ["max"] = 90,
                ["min"] = 70
                },
                [2] = {
                ["max"] = 50,
                ["min"] = 30
                }
            },
            ["Gate"] = {
                [1] = {
                ["max"] = 83,
                ["min"] = 75
                },
                [2] = {
                ["max"] = 83,
                ["min"] = 75
                }
            },
            ["Nocere"] = {
                [1] = {
                ["max"] = 85,
                ["min"] = 70
                },
                [2] = {
                ["max"] = 85,
                ["min"] = 70
                }
            },
            ["Sagitta Sol"] = {
                [1] = {
                ["max"] = 65,
                ["min"] = 50
                },
                [2] = {
                ["max"] = 60,
                ["min"] = 40
                }
            },
            ["Claritum"] = {
                [1] = {
                ["max"] = 100,
                ["min"] = 90
                }
            },
            ["Trickstus"] = {
                [1] = {
                ["max"] = 70,
                ["min"] = 30
                },
                [2] = {
                ["max"] = 50,
                ["min"] = 30
                }
            }
        }
    end;

    do -- // Mana Helper
        local manaHelperRows = {};

        local manaTextGui = library:Create('ScreenGui', {
            Enabled = true,
        });

        local manaText = library:Create('TextLabel', {
            Parent = manaTextGui,
            BackgroundTransparency = 1,
            Text = '0 %',
            Visible = false,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            Size = UDim2.new(0, 1, 0, 1),
        });

        local manaHelperGUI = library:Create('ScreenGui', {
            Enabled = false,
        });

        local castZoneGui = library:Create('ScreenGui', {
            Enabled = false
        });

        local snapCastValue = library:Create('Frame', {
            Parent = castZoneGui,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(52, 152, 219),
        });

        local normalCastValue = library:Create('Frame', {
            Parent = castZoneGui,
            BackgroundTransparency = 0.5,
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(231, 76, 60),
        });

        for i = 0, 10 do
            local container = Instance.new('Frame');
            container.Parent = manaHelperGUI;
            container.BorderSizePixel = 0;
            container.Size = UDim2.new(0, 28, 0, 2);
            container.BackgroundColor3 = Color3.fromRGB(255, 0, 4);

            local text = Instance.new('TextLabel');
            text.Size = UDim2.new(1, 0, 1, 0);
            text.TextColor3 = Color3.fromRGB(255, 255, 255);
            text.Parent = container;
            text.Position = UDim2.new(0, 50, 0, 0);
            text.BackgroundTransparency = 1;
            text.TextStrokeTransparency = 0;
            text.Text = string.format('%d %%', i * 10)

            if(i == 0 or i == 10) then
                container.Parent = nil
            end;

            table.insert(manaHelperRows, container);
        end;

        if(gethui) then
            manaTextGui.Parent = gethui();
            manaHelperGUI.Parent = gethui();
            castZoneGui.Parent = gethui();
        else
            syn.protect_gui(manaTextGui);
            manaTextGui.Parent = CoreGui;

            syn.protect_gui(manaHelperGUI);
            manaHelperGUI.Parent = CoreGui;

            syn.protect_gui(castZoneGui);
            castZoneGui.Parent = CoreGui;
        end;

        local manaOverlay = Drawing.new('Image');
        manaOverlay.Visible = false;

        function showCastZone(toggle)
            castZoneGui.Enabled = toggle;
            if(not toggle) then
                maid.showCastZone = nil;
                return;
            end;

            local function hideCastZones()
                normalCastValue.Visible = false;
                snapCastValue.Visible = false;
            end

            maid.showCastZone = RunService.RenderStepped:Connect(function()
                local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
                if(not playerGui or not playerGui:FindFirstChild('StatGui')) then return hideCastZones() end;

                local manaGui = playerGui.StatGui.LeftContainer.Mana;

                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
                if(not tool) then return hideCastZones() end;

                local values = spellValues[tool.Name];
                if(not values) then return hideCastZones() end;

                local hasSnap = values[2];

                if(hasSnap) then
                    local min, max = values[2].min, values[2].max;

                    snapCastValue.Visible = true;
                    snapCastValue.Size = UDim2.new(0, manaGui.AbsoluteSize.X, 0, manaGui.AbsoluteSize.Y * (max - min) / 100);
                    snapCastValue.Position = UDim2.new(0, manaGui.AbsolutePosition.X, 0, manaGui.AbsolutePosition.Y) + UDim2.new(0, 0, 0, manaGui.AbsoluteSize.Y - manaGui.AbsoluteSize.Y * max  / 100);
                else
                    snapCastValue.Visible = false;
                end;

                local min, max = values[1].min, values[1].max;

                normalCastValue.Visible = true;
                normalCastValue.Size = UDim2.new(0, manaGui.AbsoluteSize.X, 0, manaGui.AbsoluteSize.Y * (max - min) / 100);
                normalCastValue.Position = UDim2.new(0, manaGui.AbsolutePosition.X, 0, manaGui.AbsolutePosition.Y) + UDim2.new(0, 0, 0, manaGui.AbsoluteSize.Y - manaGui.AbsoluteSize.Y * max  / 100);
            end);

        end;

        function manaViewer(toggle)
            manaText.Visible = toggle;
            if(not toggle) then
                maid.manaViewer = nil;
                return;
            end;

            maid.manaViewer = RunService.RenderStepped:Connect(function()
                local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
                if(not playerGui or not playerGui:FindFirstChild('StatGui')) then return end;

                local manaGui = playerGui.StatGui.LeftContainer.Mana;

                local mana = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Mana');
                if(not mana) then return end;

                manaText.Position = UDim2.new(0, manaGui.AbsolutePosition.X + 14, -0.020, manaGui.AbsolutePosition.Y);
                manaText.Text = string.format('%d %%', mana.Value)
            end);
        end;

        function manaHelper(toggle)
            manaHelperGUI.Enabled = toggle;
            if(not toggle) then
                maid.manaHelper = nil;
            end;

            maid.manaHelper = RunService.RenderStepped:Connect(function()
                local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
                if(not playerGui or not playerGui:FindFirstChild('StatGui') or not playerGui.StatGui:FindFirstChild('LeftContainer')) then return end;


                local mana = playerGui.StatGui.LeftContainer.Mana;
                local size = (mana.AbsoluteSize.Y);
                local position = (mana.AbsolutePosition).Y;
                local rowSize = size / 10;

                for i, v in next, manaHelperRows do
                    v.Position = UDim2.new(0, mana.AbsolutePosition.X, 0, position + size - rowSize * (i - 1));
                end;
            end);
        end;

        function showManaOverlay(toggle)
            manaOverlay.Visible = toggle;

            if(not toggle) then
                maid.manaOverlay = nil;
                return;
            end;

            maid.manaOverlay = RunService.RenderStepped:Connect(function()
                local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
                if(not playerGui or not playerGui:FindFirstChild('StatGui')) then return end;

                local mana = playerGui.StatGui.LeftContainer.Mana;

                manaOverlay.Size = Vector2.new(library.flags.overlayScaleX, library.flags.overlayScaleY)
                manaOverlay.Position = mana.AbsolutePosition - Vector2.new(library.flags.overlayOffsetX, library.flags.overlayOffsetY);
            end);
        end;

        function spellStack(t)
            if not t then maid.spellStack = nil; table.clear(queue); return; end
            
            maid.spellStack = UserInputService.InputBegan:Connect(function(input,gameProcessed)
                if (input.KeyCode ~= Enum.KeyCode[library.options.spellStackKeybind.key] or gameProcessed) then return end;
        
                local youngest = tick();
                local found;
                for i,v in next, queue do 
                    if v.currentTime > youngest or v.fired then continue; end
                    
                    found = i;
                    youngest = v.currentTime;
                end

                queue[found].fired = true;
            end)
        end

        function setOverlayUrl(url, enter)
            local suc, requestData = pcall(syn.request, {Url = url})
            local imgData = suc and requestData.Body;
            if (not suc) then return end;

            local imgSize = getImageSize(imgData);

            manaOverlay.Data = imgData;

            if (enter) then
                manaOverlay.Size = imgSize;
                library.options.overlayScaleX:SetValue(imgSize.X);
                library.options.overlayScaleY:SetValue(imgSize.Y);
            end;
        end;
    end;

    do -- // AA Gun Counter
        local aaGunCounterGUI = library:Create('ScreenGui', {
            Enabled = false;
        });

        if(gethui) then
            aaGunCounterGUI.Parent = gethui();
        else
            syn.protect_gui(aaGunCounterGUI);
            aaGunCounterGUI.Parent = CoreGui;
        end;

        local aaGunCounterText = library:Create('TextLabel', {
            Parent = aaGunCounterGUI,
            RichText = true,
            TextSize = 25,
            Text = '',
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0, 50),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 200, 0, 50),
            Font = Enum.Font.SourceSansSemibold,
            TextColor3 = Color3.fromRGB(255, 255, 255)
        });

        local params = RaycastParams.new();
        params.FilterType = Enum.RaycastFilterType.Blacklist;
        params.FilterDescendantsInstances = {workspace.Live, workspace:FindFirstChild('NPCs') or Instance.new('Folder'), workspace:FindFirstChild('AreaMarkers') or Instance.new('Folder')};

        local flying        = false;
        local lastFly       = tick();
        local onGroundAt    = tick();
        local flyStartedAt  = lastFly;

        function aaGunCounter(toggle)
            aaGunCounterGUI.Enabled = toggle;

            if(not toggle) then
                maid.aaGunCounter = nil;
                return;
            end;

            maid.aaGunCounter = RunService.RenderStepped:Connect(function()
                local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
                if(not rootPart) then return end;

                local isOnGround = workspace:Raycast(rootPart.Position, Vector3.new(0, -10, 0), params)
                if(not isOnGround) then
                    if(not flying) then
                        flyStartedAt = tick();
                    end;
                    flying = true;
                    lastFly = tick();
                else
                    if(flying) then
                        onGroundAt = tick();
                    end;
                    flying = false;
                end;

                local timeSinceLastFly = tick() - flyStartedAt;
                local timeOnGround = tick() - onGroundAt;
                local shouldFly = (timeOnGround >= 6 and (flying and timeSinceLastFly < 5 or not flying and true));

                local red, green = 'rgb(255, 0, 0)', 'rgb(0, 255, 0)'
                local onGroundText = string.format('<font color="%s"> %s </font>', isOnGround and green or red, isOnGround and 'Yes' or 'No')
                local timeOnGroundText = string.format('<font color="%s"> %.01f </font>', flying and red or green, flying and -timeSinceLastFly or timeOnGround);
                local canFlyText = string.format('<font color="%s"> %s </font>', shouldFly and green or red, shouldFly and 'Yes' or 'No');

                aaGunCounterText.Text = string.format('On Ground: %s\nTime on ground: %s\nCan Fly (Recommended): %s', onGroundText, timeOnGroundText, canFlyText);
            end);
        end;
    end;

    do -- // Auto Potions + Auto Smithing
        local potions = {
            ['Health Potion'] = {
                ['Lava Flower'] = 1;
                ['Scroom'] = 2;
            },

            ['Bone Growth Potion'] = {
                ['Trote'] = 1,
                ['Strange Tentacle'] = 1,
                ['Uncanny Tentacle'] = 1
            },

            ['Switch Witch'] = {
                ['Dire Flower'] = 1,
                ['Glow Shroom'] = 2
            },

            ['Silver Sun'] = {
                ['Desert Mist'] = 1,
                ['Free Leaf'] = 1,
                ['Polar Plant'] = 1
            },

            ['Lordsbane'] = {
                ['Crown Flower'] = 3
            },

            ['Liquid Wisdom'] = {
                ['Desert Mist'] = 1,
                ['Periashroom'] = 1,
                ['Crown Flower'] = 1,
                ['Freeleaf'] = 1
            },

            ['Ice Protection'] = {
                ['Snow Scroom'] = 2,
                ['Trote'] = 1,
            },

            ['Kingsbane'] = {
                ['Crown Flower'] = 1,
                ['Vile Seed'] = 2,
            },

            ['Feather Feet'] = {
                ['Creely'] = 1,
                ['Dire Flower'] = 1,
                ['Polar Plant'] = 1
            },

            ['Fire Protection Potion'] = {
                ['Trote'] = 1,
                ['Scroom'] = 2
            },

            ['Tespian Elixir'] = {
                ['Lava Flower'] = 1,
                ['Scroom'] = 1,
                ['Moss Plant'] = 2
            },

            ['Slateskin'] = {
                ['Petrii Flower'] = 1,
                ['Stone Scroom'] = 1,
                ['Coconut'] = 1
            },

            ['Mind Mend'] = {
                ['Grass Stem'] = 1,
                ['Crystal Lotus'] = 1,
                ['Winter Blossom'] = 1
            },

            ['Clot Control'] = {
                ['Coconut'] = 1,
                ['Grass Stem'] = 1,
                ['Petri Flower'] = 1
            },

            ['Maidensbane'] = {
                ['Stone Scroom'] = 1,
                ['Fen Bloom'] = 1,
                ['Foul Root'] = 1,
            },

            ['Sooth Sight'] = {
                ['Grass Stem'] = 2,
                ['Crystal Lotus'] = 1
            },

            ['Crystal Extract'] = {
                ['Crystal Root'] = 1,
                ['Crystal Lotus'] = 1,
                ['Winter Blossom'] = 1
            },

            ['Soothing Frost'] = {
                ['Winter Blossom'] = 1,
                ['Snowshroom'] = 2
            },
        };

        local swords = {
            ['Bronze Sword'] = {
                ['Copper Bar'] = 1,
                ['Tin Bar'] = 2
            },

            ['Bronze Dagger'] = {
                ['Copper Bar'] = 1,
                ['Tin Bar'] = 1
            },

            ['Bronze Spear'] = {
                ['Tin Bar'] = 1,
                ['Copper Bar'] = 2
            },

            ['Steel Sword'] = {
                ['Iron Bar'] = 2,
                ['Copper Bar'] = 1
            },

            ['Steel Dagger'] = {
                ['Iron Bar'] = 1,
                ['Copper Bar'] = 1
            },

            ['Steel Spear'] = {
                ['Iron Bar'] = 1,
                ['Copper Bar'] = 2
            },

            ['Mythril Sword'] = {
                ['Copper Bar'] = 1,
                ['Iron Bar'] = 2,
                ['Mythril Bar'] = 1
            },

            ['Mythril Dagger'] = {
                ['Copper Bar'] = 1,
                ['Iron Bar'] = 1,
                ['Mythril Bar'] = 1
            },

            ['Mythril Spear'] = {
                ['Copper Bar'] = 2,
                ['Iron Bar'] = 1,
                ['Mythril Bar'] = 1
            }
        }

        local stations = workspace:FindFirstChild("Stations");

        local function GrabStation(type)
            if typeof(type) ~= "string" then
                return error(string.format("Expected type string got <%s>",typeof(type)))
            elseif(not stations) then
                return warn('[Auto Potion] No Stations');
            end

            for i,v in next, stations:GetChildren() do
                if (v.Timer.Position-LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 15 and string.find(v.Name, type) then
                    return v;
                end;
            end;
        end

        local function hasMaterials(items, item)
            local recipe = items[item];
            local count = setmetatable({}, {__index = function() return 0 end});

            assert(recipe);

            for i, v in next, LocalPlayer.Backpack:GetChildren() do
                if(recipe[v.Name]) then
                    local quantity = v:FindFirstChild('Quantity');
                    quantity = quantity and quantity.Value or 1;

                    count[v.Name] = count[v.Name] + quantity;
                end;
            end;

            for i, v in next, recipe do
                if(count[i] < v) then
                    return false;
                end;
            end;

            return recipe;
        end;

        autoCraftUtils.hasMaterials = function(craftType, item)
            return hasMaterials(craftType == 'Alchemy' and potions or swords, item);
        end;

        local function addItemsToStation(items, station, part, partToClick, partToClean)
            if(station.Contents.Value ~= '[]') then
                repeat
                    fireclickdetector(station[partToClean].ClickEmpty);
                    task.wait(0.1);
                until station.Contents.Value == '[]';

                task.wait(0.1);
            end;

            for name, count in next, items do
                for i = 1, count do
                    local k = LocalPlayer.Backpack:FindFirstChild(name);
                    if(not k) then return; end;

                    k.Parent = LocalPlayer.Character;
                    task.wait(0.1);

                    local remote = k:FindFirstChildWhichIsA('RemoteEvent');

                    if(remote) then
                        local content = station.Contents.Value;

                        repeat
                            remote:FireServer(station[part].CFrame,station[part]);
                            task.wait(0.1);
                        until station.Contents.Value ~= content;

                        k.Parent = LocalPlayer.Backpack;
                        task.wait(0.1);
                    else
                        k:Activate();

                        repeat
                            task.wait(0.5);
                        until not k.Parent;
                    end;
                end;
            end;

            repeat
                fireclickdetector(station[partToClick].ClickConcoct);
                task.wait(0.1);
            until station.Contents.Value == '[]';
        end;

        local function craft(stationType, itemToCraft)
            local station = GrabStation(stationType);
            local items = hasMaterials(stationType == 'Alchemy' and potions or swords, itemToCraft);

            if(not station) then return ToastNotif.new({text = 'You must be near a cauldron/furnace !'}) end;
            if(not items) then return ToastNotif.new({text = 'Some Ingredients are missing !'}) end;

            if(stationType == 'Smithing') then
                ReplicatedStorage.Requests.GetMouse.OnClientInvoke = function()
                    return {
                        Hit = station.Material.CFrame,
                        Target = station.Material,
                        UnitRay = Mouse.UnitRay,
                        X = Mouse.X,
                        Y = Mouse.Y
                    }
                end;
            end;

            if (stationType == 'Alchemy') then
                repeat
                    addItemsToStation(items, station, 'Water', 'Ladle', 'Bucket');
                    items = hasMaterials(stationType == 'Alchemy' and potions or swords, itemToCraft);

                    task.wait(0.5);
                until not items;
            elseif (stationType == 'Smithing') then
                repeat
                    addItemsToStation(items, station, 'Material', 'Hammer', 'Trash');
                    items = hasMaterials(stationType == 'Alchemy' and potions or swords, itemToCraft);

                    task.wait(0.5);
                until not items;
            end;

            task.wait(2);

            ReplicatedStorage.Requests.GetMouse.OnClientInvoke = function()
                return {
                    Hit = Mouse.Hit,
                    Target = Mouse.Target,
                    UnitRay = Mouse.UnitRay,
                    X = Mouse.X,
                    Y = Mouse.Y
                }
            end;
        end;

        autoCraftUtils.craft = craft;

        function buildAutoPotion(window)
            local list = {};

            for i, v in next, potions do
                table.insert(list, i);
            end;

            window:AddList({text = 'Auto Potion', skipflag = true, noload = true, values = list, callback = function(name) craft('Alchemy', name) end});
        end;

        function buildAutoCraft(window)
            local list = {};

            for i, v in next, swords do
                table.insert(list, i);
            end;

            window:AddList({text = 'Auto Craft', skipflag = true, noload = true, values = list, callback = function(name) craft('Smithing', name) end});
        end;
    end;

    local chatFocused = false;

    UserInputService.TextBoxFocused:Connect(function()
        chatFocused = true;
    end);

    UserInputService.TextBoxFocusReleased:Connect(function()
        chatFocused = false;
    end);

    local function removeGroup(instance, list)
        for _, listObject in next, list do
            local foundListObject = instance:FindFirstChild(listObject)
            if(foundListObject) then
                foundListObject:Destroy();
            end;

            CollectionService:RemoveTag(instance, listObject);
        end;
    end;

    local function isUnderWater()
        if(not library.flags.noClipDisableValues['Disable On Water']) then
            return;
        end;

        local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Head');
        if(not head) then return end;

        local min = head.Position - (0.5 * head.Size);
        local max = head.Position + (0.5 * head.Size);

        local region = Region3.new(min, max):ExpandToGrid(4);

        local material = workspace.Terrain:ReadVoxels(region,4)[1][1][1];

        return material == Enum.Material.Water;
    end;

    local function isKnocked()
        if(not library.flags.noClipDisableValues['Disable When Knocked']) then
            return;
        end;

        local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Head');
        if(head and head:FindFirstChild('Bone')) then
            return true;
        end;
    end;

    local function getCurrentNpc(whitelist)
        local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
        if(not rootPart) then return end;

        for _, npc in next, (workspace:FindFirstChild('NPCs') or Instance.new('Folder')):GetChildren() do
            local npcRoot = npc.PrimaryPart;
            if(npcRoot and table.find(whitelist, npc.Name) and (rootPart.Position - npcRoot.Position).Magnitude <= 15) then
                return npc;
            end;
        end;
    end;

    local function getPlayerClass(player)
        if(playerClasses[player] and tick() - playerClasses[player].lastUpdate <= 5) then
            return playerClasses[player].name;
        end;

        local allFounds = {};
        local playerBackpack = player:FindFirstChild('Backpack');
        if(not playerBackpack) then
            return 'Freshie';
        end;

        for i, v in next, playerClassesList do
            for i2, v2 in next, v.Active do
                local alternative = tostring(v2):gsub("%s", "");
                if(i2 ~= "Level" and (playerBackpack:FindFirstChild(v2) or playerBackpack:FindFirstChild(alternative))) then
                    table.insert(allFounds, {Level = -1, Name = i});
                    break;
                end;
            end;

            for i2, v2 in next, v.Classes do
                for i3, v3 in next, v2 do
                    local alternative = tostring(v3):gsub("%s", "");
                    if(i3 ~= "Level" and (playerBackpack:FindFirstChild(v3) or playerBackpack:FindFirstChild(alternative))) then
                        table.insert(allFounds, {Level = v2.Level, Name = i2});
                        break;
                    end;
                end;
            end
        end;

        local foundClass, foundClassLevel = nil, -1;
        for i, v in next, allFounds do
            if(v.Level >= foundClassLevel) then
                foundClass = v;
                foundClassLevel = v.Level;
            end;
        end;

        playerClasses[player] = {
            lastUpdate = tick();
            name = foundClass and foundClass.Name or 'Freshie'
        };

        if(not foundClass) then
            return 'Freshie';
        end;

        return foundClass.Name;
    end;

    local playerRaces = {};
    local raceColors = {};

    do -- // Grab Race Data
        if(ReplicatedStorage:FindFirstChild('Info') and ReplicatedStorage.Info:FindFirstChild('Races')) then
            for i, v in next, ReplicatedStorage.Info.Races:GetChildren() do
                table.insert(raceColors, {tostring(v.EyeColor.Value), tostring(v.SkinColor.Value), v.Name})
            end;
        end;
    end;

    local function getPlayerRace(player)
        if(playerRaces[player] and tick() - playerRaces[player].lastUpdateAt <= 5) then
            return playerRaces[player].name;
        end;

        local head = player.Character and player.Character:FindFirstChild('Head');
        local face = head and head:FindFirstChild('RLFace');
        local scroomHead = player.Character and player.Character:FindFirstChild('ScroomHead');

        local raceFound = 'Unknown'

        if(not face) then return raceFound end;

        if(scroomHead) then
            if(scroomHead.Material.Name == 'DiamondPlate') then
                raceFound = 'Metascroom';
            else
                raceFound = 'Scroom';
            end;
        end;

        if(raceFound == 'Unknown') then
            for i2, v2 in next, raceColors do
                local eyeColor, skinColor, raceName = v2[1], v2[2], v2[3];

                if(tostring(head.Color) == skinColor and tostring(face.Color3) == eyeColor) then
                    raceFound = raceName;
                end;
            end;
        end;


        playerRaces[player] = {
            lastUpdateAt = tick(),
            name = raceFound
        };

        return raceFound;
    end;

    local function chargeManaUntil(amount)
        local character = LocalPlayer.Character;
        if(not character or character:FindFirstChildWhichIsA('ForceField') or not canUseMana()) then return warn('Cant charge mana cuz cant use mana', canUseMana()) end;

        local playerMana = character and character:FindFirstChild('Mana');
        if(character:FindFirstChild('Charge')) then
            dechargeMana();
            task.wait(0.2);
        end;

        if(not playerMana or sprinting) then
            return;
        end;

        if(playerMana.Value < amount) then
            --print('[Mana Adjust] Charge Mana');

            repeat
                chargeMana();
                task.wait(0.1);
            until playerMana.Value > math.clamp(amount, 0, 98) or sprinting;

            --print('[Mana Adjust] Decharge Mana');

            if (character:FindFirstChild('Charge')) then
                dechargeMana();
                task.wait(0.3);
            end;
        end;
    end;

    do -- // Bots
        local function runSafetyCheck(serverHop)
            local playerRangeCheck = library.flags.playerRangeCheck;

            if(moderatorInGame) then
                if(serverHop) then
                    kickPlayer('Moderator In Game');
                    return findServer(true), true, task.wait(9e9);
                else
                    return true, 'Mod In Game';
                end;
            end;

            if(Utility:countTable(illusionists) > 0 and library.flags.skipIllusionistServer) then
                if(serverHop) then
                    kickPlayer('Illusionist In Game');
                    return findServer(true), true, task.wait(9e9);
                else
                    return true, 'Illusionist In Game';
                end;
            end;

            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            if(not rootPart) then return end;

            if(_G.forcePanic) then
                if(serverHop) then
                    kickPlayer('Forced Panic');
                    return findServer(true), true, task.wait(9e9);
                else
                    return true, 'Forced Panic';
                end;
            end;

            for i, v in next, Players:GetPlayers() do
                local plrRoot = v.Character and v.Character:FindFirstChild('HumanoidRootPart');
                if(v == LocalPlayer or not plrRoot) then continue end;

                local playerDistance = rootPart and (plrRoot.Position - rootPart.Position).Magnitude;
                if(playerDistance <= playerRangeCheck) then
                    if(serverHop) then
                        kickPlayer(string.format('Player Too Close (%s) [%d] Studs', v.Name, playerDistance));
                        return findServer(true), true, task.wait(9e9);
                    else
                        return true, string.format('Player Too Close (%s) [%d] Studs', v.Name, playerDistance);
                    end;
                end;
            end;
        end;

        local function runSmallSafetyCheck(cf, playerDistanceCheck, ignoreY)
            local illusionistObserving, playerTooClose = false, false;
            local rangeCheck = playerDistanceCheck or 500;

            for i, v in next, Players:GetPlayers() do
                local rootPart = v.Character and v.Character:FindFirstChild('HumanoidRootPart');
                if(not rootPart or v == LocalPlayer) then continue end;

                if(v.Character:FindFirstChild('Observing')) then
                    illusionistObserving = true;
                end;

                if((Utility:roundVector(rootPart.Position) - Utility:roundVector(cf.p)).Magnitude <= rangeCheck) then
                    playerTooClose = true;
                    break;
                end;
            end;

            return illusionistObserving, playerTooClose;
        end;

        local function findClosest(currentPosition, positions)
            local closest, distance = nil, math.huge;
            local index = 0;

            for i, v in next, positions do
                local newDistance = (currentPosition - v.position).Magnitude;
                if(newDistance < distance) then
                    closest, distance = v.position, newDistance;
                    index = i;
                end;
            end;

            return closest, distance, index;
        end;

        local function setFeatureState(names, state)
            for _, name in next, names do
                if(library.flags[name] ~= state) then
                    library.options[name]:SetState(state);
                end;
            end;
        end;

        local function disableBeds()
            local bed = workspace:FindFirstChild('Bed', true);
            if(not bed) then return end;

            for i, v in next, bed.Parent:GetChildren() do
                if(v.Name == 'Bed') then
                    v.CanTouch = false;
                end;
            end;
        end;

        local function tweenTeleport(rootPart, position)
            local distance = (rootPart.Position - position).Magnitude;
            local tween = TweenService:Create(rootPart, TweenInfo.new(distance / 150, Enum.EasingStyle.Linear), {
                CFrame = CFrame.new(position)
            });

            tween:Play();
            tween.Completed:Wait();
        end;

        local function getClosestTrinkets(rootPart)
            local allTrinkets = {};

            for i, v in next, workspace:GetChildren() do
                if(v:IsA('BasePart') and v:FindFirstChildWhichIsA('ClickDetector', true) and (v.Position - rootPart.Position).Magnitude <= 500) then
                    runSafetyCheck(true);

                    local distance = (v.Position - rootPart.Position).Magnitude;
                    table.insert(allTrinkets, {distance = distance, object = v});
                end;
            end;

            table.sort(allTrinkets, function(a, b)
                return a.distance < b.distance;
            end);

            return allTrinkets;
        end;

        local function createBot(tpLocations)
            runSafetyCheck(true);

            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');

            if(not LocalPlayer.Character) then
                local startMenu = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('StartMenu');
                local finish = startMenu:WaitForChild('Finish');

                finish:FireServer();

                repeat
                    rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
                    task.wait();
                until rootPart;
            end;

            runSafetyCheck(true);
            setFeatureState({'autoPickup', 'antiFire', 'removeKillBricks', 'noFallDamage'}, true);
            disableBeds();

            local _, distance = findClosest(rootPart.Position, tpLocations);
            if(distance >= 20) then
                repeat
                    _, distance = findClosest(rootPart.Position, tpLocations);
                    ToastNotif.new({
                        text = 'You are too far away from the points',
                        duration = 2.5
                    });
                    task.wait(5);
                until distance <= 20;
            end;

            local bodyVelocity = Instance.new('BodyVelocity');
            CollectionService:AddTag(bodyVelocity, 'AllowedBM');

            bodyVelocity.Velocity = Vector3.new();
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
            bodyVelocity.Parent = rootPart;

            local aaGunPart = Instance.new('Part');

            aaGunPart.Anchored = true;
            aaGunPart.Transparency = debugMode and 0 or 1;
            aaGunPart.Size = Vector3.new(10, 0.1, 10);
            aaGunPart.Parent = workspace;

            local trinketPickedUp = {};

            RunService.Stepped:Connect(function()
                aaGunPart.CFrame = rootPart.CFrame * CFrame.new(0, -3.5, 0);

                if(LocalPlayer.Character:FindFirstChild('Frostbitten')) then
                    LocalPlayer.Character.Frostbitten:Destroy();
                end;

                if(LocalPlayer.Character:FindFirstChild('DamageMPStack')) then
                    LocalPlayer.Character.DamageMPStack:Destroy();
                end;
            end);

            if((tpLocations[1].position - rootPart.Position).Magnitude > 20) then
                local _, _, index = findClosest(rootPart.Position, tpLocations);

                for i = index, 1, -1 do
                    local tpData = tpLocations[i];

                    runSafetyCheck(true);
                    tweenTeleport(rootPart, tpData.position);

                    local ranAt = tick();

                    repeat
                        runSafetyCheck(true);
                        task.wait();
                    until tick() - ranAt >= tpData.delay;
                end;

                findServer(true);
                return;
            end;

            for i, v in next, tpLocations do
                runSafetyCheck(true);
                tweenTeleport(rootPart, v.position);

                local ranAt = tick();

                repeat
                    runSafetyCheck(true);
                    task.wait();
                until tick() - ranAt >= v.delay;

                local trinkets = getClosestTrinkets(rootPart);

                for i, v in next, trinkets do
                    if(trinketPickedUp[v.object]) then
                        continue;
                    end;

                    local trinketType = getTrinketType(v.object);
                    if((trinketType.Name == 'Phoenix Down' and library.flags.dontPickupPhoenixDown) or (trinketType.Name == 'Ninja Scroll' and library.flags.dontPickupScrolls)) then
                        if(v.object:FindFirstChildWhichIsA('ClickDetector', true)) then
                            v.object:FindFirstChildWhichIsA('ClickDetector', true):Destroy();
                        end;

                        trinketPickedUp[v.object] = true;
                        continue;
                    end;

                    local pickedUpAt = tick();
                    repeat task.wait() until not v.object.Parent or tick() - pickedUpAt >= 5;

                    trinketPickedUp[v.object] = true;
                    task.wait(0.1);
                end;
            end;

            if(not rootPart.Parent) then
                return kickPlayer('You got killed, stopped bot.');
            end;

            findServer(true);
        end;

        local function findPlayerInZone(zonePosition, zoneSize)
            local castPart = Instance.new('Part');
            castPart.Anchored = true;
            castPart.Transparency = 1;
            castPart.CanCollide = false;
            castPart.Size = zoneSize; -- Vector3.new(1000, 0, 1000);
            castPart.Position = zonePosition; -- Vector3.new(-1171.661, 702.853, 201.261);
            castPart.Parent = workspace;

            local params = RaycastParams.new();
            params.FilterType = Enum.RaycastFilterType.Whitelist;
            params.FilterDescendantsInstances = {castPart};

            for i, v in next, Players:GetPlayers() do
                local rootPart = v.Character and v.Character:FindFirstChild('HumanoidRootPart');

                if (rootPart and workspace:Raycast(rootPart.Position, Vector3.new(0, 10000, 0), params) and v ~= LocalPlayer) then
                    return true;
                end;
            end;
        end;

        function scroomBot(toggle)
            if(not toggle) then return end;

            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            local target = library.flags.scroomBotTargetPlayer;

            repeat
                task.wait(1);

                if(getPlayerRace(LocalPlayer) ~= 'Scroom') then
                    ToastNotif.new({text = 'Scroom Bot - You must be a scroom !', duration = 5});
                    continue;
                end;

                local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
                if(not rootPart or not humanoid) then continue end;

                local statGui = LocalPlayer:FindFirstChild('PlayerGui') and LocalPlayer.PlayerGui:FindFirstChild('StatGui');
                if(not statGui) then continue end;

                local lives = tonumber(statGui.Container.Health.Lives.Roller.Char.Text)
                if(not lives) then continue end;

                warn('[Scroom Bot] Scroom has', lives, 'lives');

                if(lives == 0) then
                    warn('[Scroom Bot] No more lives !');

                    local function moveTo(pos)
                        local moveToFinished = false;
                        coroutine.wrap(function()
                            humanoid.MoveToFinished:Wait();
                            moveToFinished = true;
                        end)();

                        repeat
                            print('[Scroom Bot] Waiting for moveToFinished');
                            humanoid:MoveTo(pos);
                            task.wait();
                        until moveToFinished;
                    end;

                    moveTo(Vector3.new(-7172.99316, 274.759491, 2772.82275));
                    moveTo(Vector3.new(-7144.06201, 274.759338, 2771.50513));

                    print('[Scroom Bot] Ready to talk to Ferryman');

                    local npc = getCurrentNpc({'Ferryman'});
                    fireclickdetector(npc.ClickDetector);

                    task.wait(1);
                    local choices = {'New Character\n(free)', 'My son.', 'exit'};
                    for i, v in next, choices do
                        if(v == 'exit') then
                            dialog:FireServer({exit = true});
                        else
                            dialog:FireServer({choice = v});
                        end;

                        task.wait(1);
                    end;

                    LocalPlayer.CharacterAdded:Wait();
                    continue;
                end;

                if(not target.Character or (target.Character.PrimaryPart.Position - rootPart.Position).Magnitude > 100) then
                    ToastNotif.new({text = 'Scroom Bot - Player is too far away (Maximum 100 studs)', duration = 5});
                    continue;
                end;

                local tween = TweenService:Create(rootPart, TweenInfo.new((rootPart.Position - target.Character.PrimaryPart.Position).Magnitude / 200), {
                    CFrame = CFrame.new(target.Character.PrimaryPart.Position)
                });

                tween:Play();
                tween.Completed:Wait();

                if(LocalPlayer.Character:FindFirstChildWhichIsA('ForceField')) then
                    LocalPlayer.Character:FindFirstChildWhichIsA('ForceField'):Destroy();
                end;

                task.wait(0.1);
                local id = HttpService:GenerateGUID(false):sub(1, 8);

                repeat
                    if(library.flags.scroomBotGripMode and humanoid.Health >= 10) then
                        fallDamage:FireServer({math.random(), 2});
                    end;
                    print('[Scroom Bot] Waiting for player to die ...', id);

                    task.wait(1);
                until humanoid.Health <= 0 or not library.flags.scroomBot;

                warn('[Scroom Bot] Player is dead, waiting for new character to spawn ...');
                LocalPlayer.CharacterAdded:Wait();
                warn('[Scroom Bot] New character has spawned');
            until not library.flags.scroomBot;
        end;

        function daysFarm(toggle)
            local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            if(not toggle) then
                maid.daysFarm = nil;
                maid.daysFarmNoClip = nil;
                return;
            end;

            if(not LocalPlayer.Character) then
                spawnLocalCharacter();
                task.wait(1);
            end;

            repeat
                task.wait();
            until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            
            maid.daysFarm = RunService.Heartbeat:Connect(function()
                local _, playerTooClose = runSmallSafetyCheck(humanoidRootPart.CFrame,library.flags.daysFarmRange);

                if(playerTooClose or moderatorInGame) then
                    maid.daysFarm = nil;
                    task.wait(1);
                    kickPlayer(moderatorInGame and 'Mod In Game' or 'Player Too Close');
                    findServer();
                end;
            end);
        end;

        function gachaBot(toggle)
            if(not toggle or not isGaia) then return end;

            if(moderatorInGame) then
                kickPlayer('Mod In Game');
                return findServer();
            end;

            local character = spawnLocalCharacter();

            local rootPart = character and character:WaitForChild('HumanoidRootPart');
            if(not rootPart) then return ToastNotif.new({text = 'no hrp?'}) and findServer(); end;

            local npc = workspace.NPCs:FindFirstChild('Xenyari');
            local npcRootPart = npc and npc:FindFirstChild('Head');
            local clickDetector = npc and npc:FindFirstChildWhichIsA('ClickDetector');

            if (not npc or not npcRootPart or not clickDetector) then
                kickPlayer('Please dm Aztup!');
                return findServer();
            end;

            local distanceFromNPC = (npcRootPart.Position - rootPart.Position).Magnitude;

            if (distanceFromNPC > 10) then
                repeat
                    ToastNotif.new({text = 'You are too far away from Xenyari', duration = 1});
                    distanceFromNPC = (npcRootPart.Position - rootPart.Position).Magnitude;
                    task.wait(1);
                until distanceFromNPC < 10;
            end;

            local getPlayerDays = (function()
                for i, v in next, getconnections(ReplicatedStorage.Requests.DaysSurvivedChanged.OnClientEvent) do
                    return getupvalue(v.Function, 2);
                end;
            end);

            local playerDays = getPlayerDays();

            repeat
                playerDays = getPlayerDays();
                task.wait(0.1);
            until playerDays;

            ReplicatedStorage.Requests.DaysSurvivedChanged.OnClientEvent:Connect(function(days)
                playerDays = days;
            end);

            if (MemStorageService:HasItem('gachaBotLives')) then
                repeat
                    print('running safety check and waiting for lives to change!', playerDays, tonumber(MemStorageService:GetItem('gachaBotLives')));

                    local _, playerTooClose = runSmallSafetyCheck(rootPart.CFrame, 2500);

                    if (playerTooClose) then
                        if (character:FindFirstChild('Danger')) then
                            repeat
                                task.wait(0.1);
                            until not character:FindFirstChild('Danger');
                        end;

                        kickPlayer('Player too close');
                        findServer();
                    elseif (character:FindFirstChildWhichIsA('ForceField')) then
                        character:FindFirstChildWhichIsA('ForceField'):Destroy();
                    end;

                    task.wait(0.1);
                until playerDays ~= tonumber(MemStorageService:GetItem('gachaBotLives'));
            else
                MemStorageService:SetItem('gachaBotLives', tostring(playerDays));
            end;

            dialog.OnClientEvent:Connect(function(dialogData)
                task.wait(1);

                if (not dialogData.choices) then
                    dialog:FireServer({exit = true});
                    task.wait(1);
                    kickPlayer('Hopping');
                    findServer();
                elseif (dialogData.choices) then
                    MemStorageService:SetItem('gachaBotLives', tostring(playerDays));
                    dialog:FireServer({choice = dialogData.choices[1]});
                end;
            end);

            library.base.Enabled = false;

            repeat
                local rootPosition = workspace.CurrentCamera:WorldToViewportPoint(npcRootPart.Position);

                VirtualInputManager:SendMouseButtonEvent(rootPosition.X, rootPosition.Y, 0, false, game, 1);
                task.wait();
                VirtualInputManager:SendMouseButtonEvent(rootPosition.X, rootPosition.Y, 0, true, game, 1);
                task.wait(0.25);
            until LocalPlayer.PlayerGui:FindFirstChild('CaptchaLoad') or LocalPlayer.PlayerGui:FindFirstChild('Captcha');
            -- // Waiting for npc answer or waiting for captcha

            repeat task.wait() until LocalPlayer.PlayerGui:FindFirstChild('Captcha');

            repeat
                local captchaGUI = LocalPlayer.PlayerGui:FindFirstChild('Captcha');
                local choices = captchaGUI and captchaGUI.MainFrame.Options:GetChildren();
                local union = captchaGUI and captchaGUI.MainFrame.Viewport.Union;

                if(choices and union) then
                    local captchaAnswer = solveCaptcha(union);

                    for i, v in next, choices do
                        if(v.Name == captchaAnswer) then
                            local position = v.AbsolutePosition + Vector2.new(40, 40);
                            VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 1);
                            task.wait();
                            VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 1);

                            break;
                        end;
                    end;
                end;

                task.wait(1);
            until not LocalPlayer.PlayerGui:FindFirstChild('Captcha');

            library.base.Enabled = true;
        end;

        function blackSmithBot(toggle)
            if (not toggle) then return end;

            local character = spawnLocalCharacter();
            local rootPart = character and character:WaitForChild('HumanoidRootPart');

            local locations = {
                Vector3.new(-1066.6357421875, 583.36157226563, -421.35971069336)
            };

            local boxes = {};
            setFeatureState({'antiFire', 'removeKillBricks', 'noFallDamage'}, true);

            for i = 1, #locations do
                local box = Drawing.new('Square');
                box.Size = Vector2.new(50, 50);
                box.Thickness = 5;
                box.Color = Color3.fromRGB(255, 255, 255);

                local text = Drawing.new('Text');
                text.Size = 20;
                text.Center = false;
                text.Text = string.format('Blacksmith Point %d', i);
                text.Color = Color3.fromRGB(255, 255, 255);

                table.insert(boxes, {box, text});
            end;

            RunService.Heartbeat:Connect(function()
                for i, location in next, locations do
                    local box, text = unpack(boxes[i]);
                    local screenPosition, visible = workspace.CurrentCamera:WorldToViewportPoint(location);

                    box.Visible = visible;
                    text.Visible = visible;

                    box.Position = Vector2.new(screenPosition.X, screenPosition.Y) - box.Size / 2;
                    text.Position = Vector2.new(screenPosition.X, screenPosition.Y) - box.Size;
                end;
            end);

            local function getChosenLocation()
                for i, v in next, locations do
                    if ((rootPart.Position - v).Magnitude < 10) then
                        return i, v;
                    end;
                end;
            end;

            local chosenLocationIndex, chosenLocation = getChosenLocation();

            if (not chosenLocation) then
                repeat
                    ToastNotif.new({text = 'You must be on one of the blacksmith points', duration = 1});

                    chosenLocationIndex, chosenLocation = getChosenLocation();
                    task.wait(1);
                until chosenLocation;
            end;

            local bodyVelocity = Instance.new('BodyVelocity');
            CollectionService:AddTag(bodyVelocity, 'AllowedBM');

            bodyVelocity.Velocity = Vector3.new();
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
            bodyVelocity.Parent = rootPart;

            local aaGunPart = Instance.new('Part');

            aaGunPart.Anchored = true;
            aaGunPart.Transparency = debugMode and 0 or 1;
            aaGunPart.Size = Vector3.new(10, 0.1, 10);
            aaGunPart.Parent = workspace;

            local function getPickaxes()
                local pickaxes = {};

                for i, v in next, LocalPlayer.Backpack:GetChildren() do
                    if (v.Name == 'Pickaxe') then
                        table.insert(pickaxes, v);
                    end;
                end;

                return pickaxes;
            end;

            local pickaxes = getPickaxes();

            if (#pickaxes <= 1) then
                repeat
                    ToastNotif.new({text = 'You must have atleast 1 pickaxe.', duration = 1})
                    pickaxes = getPickaxes();

                    task.wait(1);
                until #pickaxes >= 1;
            end;

            RunService.Stepped:Connect(function()
                aaGunPart.CFrame = rootPart.CFrame * CFrame.new(0, -3.5, 0);

                if(character:FindFirstChild('Frostbitten')) then
                    character.Frostbitten:Destroy();
                end;

                if(character:FindFirstChild('DamageMPStack')) then
                    character.DamageMPStack:Destroy();
                end;
            end);

            local function mineOres(ores)
                for i, v in next, ores do
                    local isBlacklisted = v:FindFirstChild('Blacklist') and v.Blacklist:FindFirstChild(LocalPlayer.Name);

                    if ((v.Position - rootPart.Position).Magnitude < 10 and v.Transparency == 0 and not isBlacklisted and (not library.flags.skipIllusionistServer or Utility:countTable(illusionists) <= 0)) then
                        local startedAt = tick();

                        repeat
                            local pickaxe = table.remove(pickaxes, 1);

                            pickaxe.Parent = LocalPlayer.Character;
                            pickaxe:Activate();

                            task.wait(0.05);
                            pickaxe.Parent = LocalPlayer.Backpack;

                            table.insert(pickaxes, pickaxe);
                        until v.Transparency ~= 0 or tick() - startedAt >= 2;
                    end;
                end;
            end;

            local function getOres(getCookedOre)
                local totalOres = {};
                local closest = 0;

                for i, v in next, LocalPlayer.Backpack:GetChildren() do
                    if (v:FindFirstChild('Ore') or (getCookedOre and v:FindFirstChild('OreBar'))) then
                        totalOres[v.Name] = (totalOres[v.Name] or 0) + 1
                    end;
                end;

                for i, v in next, totalOres do
                    if (v > closest) then
                        closest = v;
                    end;
                end;

                return closest;
            end;

            local function getDaggers()
                local counter = 0;

                for i, v in next, LocalPlayer.Backpack:GetChildren() do
                    if (v:FindFirstChild('Smithed')) then
                        counter = counter + 1;
                    end;
                end;

                return counter;
            end;

            local playerTooClose = findPlayerInZone(Vector3.new(-1357.403, 702.853, 170.2), Vector3.new(1371.484, 9.368, 1504.703));
            task.wait(5);

            if (playerTooClose) then
                kickPlayer('Player too close.');
                return findServer();
            elseif (Utility:countTable(illusionists) > 0 and library.flags.skipIllusionistServer) then
                kickPlayer('Illusionist in server.');
                return findServer();
            elseif (moderatorInGame) then
                kickPlayer('Mod in game.');
                return findServer();
            end;

            LocalPlayer.CharacterAdded:Connect(function()
                kickPlayer('You got killed, stopping bot');
                function findServer() end;
                task.wait(1);
                while true do end;
            end);

            local forceField = LocalPlayer.Character:FindFirstChildWhichIsA('ForceField');
            if (forceField) then
                forceField:Destroy();
                task.wait(1);
            end;

            local amountOfOres = getOres();
            local amountOfCookedOres = getOres(true);
            local leftClick = LocalPlayer.Character.CharacterHandler.Remotes.LeftClick;
            local rightClick = LocalPlayer.Character.CharacterHandler.Remotes.RightClick;

            if (chosenLocationIndex == 1) then
                local ores = workspace.Ores:GetChildren();
                local oresLocation = Vector3.new(-1047.0006103516, 185.89465332031, -51.419830322266);

                local foundOres = {};

                for i, v in next, ores do
                    local isBlacklisted = v:FindFirstChild('Blacklist') and v.Blacklist:FindFirstChild(LocalPlayer.Name);

                    if ((v.Position - oresLocation).Magnitude < 500 and v.Transparency == 0 and not isBlacklisted) then
                        table.insert(foundOres, v);
                    end;
                end;

                if (#foundOres <= 0) then
                    kickPlayer('No ores.');
                    return findServer();
                end;

                tweenTeleport(rootPart, Vector3.new(-1067.231, 583.361, -419.418));
                tweenTeleport(rootPart, Vector3.new(-1066.703, 589.257, -399.340));
                tweenTeleport(rootPart, Vector3.new(-1047.000, 589.257, -51.419));
                tweenTeleport(rootPart, Vector3.new(-1047.197, 185.895, -59.241));
                mineOres(ores);
                tweenTeleport(rootPart, Vector3.new(-1047.738, 185.895, -154.77));
                mineOres(ores);
                tweenTeleport(rootPart, Vector3.new(-1057.99, 185.895, -151.683));
                mineOres(ores);
                tweenTeleport(rootPart, Vector3.new(-1045.891, 185.895, -153.512));
                tweenTeleport(rootPart, Vector3.new(-1047.197, 185.895, -59.241));
                tweenTeleport(rootPart, Vector3.new(-1047.000, 589.257, -51.419));
                tweenTeleport(rootPart, Vector3.new(-1066.703, 589.257, -399.340));
                tweenTeleport(rootPart, Vector3.new(-1067.231, 583.361, -419.418));
            end;

            if (amountOfOres >= 25 or MemStorageService:HasItem('wasCookingOres')) then
                local remoteSmithing = LocalPlayer.Backpack:FindFirstChild('Remote Smithing');
                if (not remoteSmithing) then return kickPlayer('Bot, stopped, due to max amount of ores and no remote smithing') end;

                rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(20, 0, 0));
                MemStorageService:SetItem('wasCookingOres', 'true');

                remoteSmithing.Parent = LocalPlayer.Character;
                task.wait(1);
                rightClick:FireServer({math.random(1, 10), math.random()});

                setFeatureState({'autoSmelt'}, true);

                repeat
                    playerTooClose = findPlayerInZone(Vector3.new(-1357.403, 702.853, 170.2), Vector3.new(1371.484, 9.368, 1504.703))
                    amountOfOres = getOres();

                    task.wait(0.1);
                until playerTooClose or amountOfOres <= 0;

                if (amountOfOres <= 0) then
                    MemStorageService:RemoveItem('wasCookingOres');
                end;

                remoteSmithing.Parent = LocalPlayer.Backpack;

                rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 10, 0));
                task.wait(0.1);
                rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(-20, 0, 0));
                task.wait(0.1);
                rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, -10, 0));

                setFeatureState({'autoSmelt'}, false);
                task.wait(0.5);

                if (playerTooClose) then
                    kickPlayer('Player was too close aborted, smelt ores');
                    return findServer();
                end;
            end;

            local craftItem;
            local itemToCrafts = {'Bronze Dagger', 'Steel Dagger', 'Mythril Dagger'};

            for i, v in next, itemToCrafts do
                if (autoCraftUtils.hasMaterials('Smithing', v)) then
                    craftItem = v;
                end;
            end;

            if (amountOfCookedOres >= 50 or MemStorageService:HasItem('wasDoingCrafting')) then
                local remoteSmithing = LocalPlayer.Backpack:FindFirstChild('Remote Smithing');
                if (not remoteSmithing) then return kickPlayer('Bot, stopped, due to max amount of ores and no remote smithing') end;

                MemStorageService:SetItem('wasDoingCrafting', 'true');

                rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 0, 20));
                remoteSmithing.Parent = LocalPlayer.Character;

                task.wait(1);
                leftClick:FireServer({math.random(1, 10), math.random()});
                task.wait(1);
                remoteSmithing.Parent = LocalPlayer.Backpack;

                local craftEnded = false;

                task.spawn(function()
                    autoCraftUtils.craft('Smithing', craftItem);
                    craftEnded = true;
                    MemStorageService:RemoveItem('wasDoingCrafting');
                end);

                repeat
                    playerTooClose = findPlayerInZone(Vector3.new(-1357.403, 702.853, 170.2), Vector3.new(1371.484, 9.368, 1504.703))
                    task.wait(0.1);
                until playerTooClose or craftEnded;

                rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 10, 0));
                task.wait(0.1);
                rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 0, -20));
                task.wait(0.1);
                rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, -10, 0));

                task.wait(0.5);

                if (playerTooClose) then
                    kickPlayer('Player was too close aborted, smelt ores');
                    return findServer();
                end;
            end;

            local amountOfDaggers = getDaggers();

            if (amountOfDaggers >= 50) then
                local playerTooClose = findPlayerInZone(Vector3.new(-1357.403, 702.853, 170.2), Vector3.new(1371.484, 9.368, 1504.703));

                if (playerTooClose) then
                    kickPlayer('Player too close, cant sell daggers');
                    return findServer();
                elseif (Utility:countTable(illusionists) > 0 and library.flags.skipIllusionistServer) then
                    kickPlayer('Illu in server, cant sell daggers');
                    return findServer();
                end;

                if (chosenLocationIndex == 1) then
                    tweenTeleport(rootPart, Vector3.new(-1067.231, 583.361, -419.418));
                    tweenTeleport(rootPart, Vector3.new(-1066.703, 589.257, -399.340));
                    tweenTeleport(rootPart, Vector3.new(-1047.000, 589.257, -51.419));
                    tweenTeleport(rootPart, Vector3.new(-1048.018, 185.895, -48.932));
                    tweenTeleport(rootPart, Vector3.new(-1047.197, 185.895, 205.667));
                    tweenTeleport(rootPart, Vector3.new(-1041.21, 168.84, 227.411));
                    tweenTeleport(rootPart, Vector3.new(-1107.443, 168.84, 253.837));
                    tweenTeleport(rootPart, Vector3.new(-1169.846, 162.282, 290.529));
                    tweenTeleport(rootPart, Vector3.new(-1169.846, 145.626, 291.5));
                    tweenTeleport(rootPart, Vector3.new(-1250.748, 146.004, 290.529));
                    tweenTeleport(rootPart, Vector3.new(-1250.748, 146.004, 253.283));
                    tweenTeleport(rootPart, Vector3.new(-1237.223, 146.004, 254.742));

                    -- talk to npc

                    repeat
                        task.wait(0.1);
                        local merchant = getCurrentNpc({'Merchant', 'Pawnbroker'});
                        if (not merchant) then warn('no npc very sad') continue end;

                        fireclickdetector(merchant.ClickDetector);
                        task.wait(1);
                        dialog:FireServer({choice = 'Can I sell in bulk?'})
                        task.wait(1);
                        dialog:FireServer({choice = 'Weapons.'});
                        task.wait(1);
                        dialog:FireServer({choice = 'It\'s a deal.'});
                        task.wait(1);
                        dialog:FireServer({exit = true});

                        amountOfDaggers = getDaggers();
                        warn('daggers:', amountOfDaggers)
                    until amountOfDaggers <= 0;

                    tweenTeleport(rootPart, Vector3.new(-1237.223, 146.004, 254.742));
                    tweenTeleport(rootPart, Vector3.new(-1250.748, 146.004, 253.283));
                    tweenTeleport(rootPart, Vector3.new(-1250.748, 146.004, 290.529));
                    tweenTeleport(rootPart, Vector3.new(-1169.846, 145.626, 291.5));
                    tweenTeleport(rootPart, Vector3.new(-1169.846, 162.282, 290.529));
                    tweenTeleport(rootPart, Vector3.new(-1107.443, 168.84, 253.837));
                    tweenTeleport(rootPart, Vector3.new(-1041.21, 168.84, 227.411));
                    tweenTeleport(rootPart, Vector3.new(-1047.197, 185.895, 205.667));
                    tweenTeleport(rootPart, Vector3.new(-1048.018, 185.895, -48.932));
                    tweenTeleport(rootPart, Vector3.new(-1047.000, 589.257, -51.419));
                    tweenTeleport(rootPart, Vector3.new(-1066.703, 589.257, -399.340));
                    tweenTeleport(rootPart, Vector3.new(-1067.231, 583.361, -419.418));

                    task.wait(0.5);

                    kickPlayer('Sold daggers wooo');
                    return findServer();
                end;

                -- setFeatureState({'blacksmithBot'}, false);
                -- return kickPlayer('Finished farming, you can now sell your daggers');
            end;

            task.wait(0.5);

            kickPlayer('Finished lotting.');
            return findServer();
        end;

        local botPoints = {};
        local botPointsUI = {};

        local botPointsParts = {};
        local botPointsLines = {};

        function addPoint(position, delay, waitForTrinkets)
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            position = position or (rootPart and rootPart.Position);
            if(not position) then return end;

            local roundPosition = Vector3.new(math.floor(position.X), math.floor(position.Y), math.floor(position.Z));
            local brickColor = BrickColor.palette(((#botPoints*5) % 100)+1);

            waitForTrinkets = waitForTrinkets or false;

            local pointData = {};
            pointData.position = position;
            pointData.delay = delay or 0;
            pointData.waitForTrinkets = waitForTrinkets;

            table.insert(botPoints, pointData);

            local point = Instance.new('Part');

            point.Size = Vector3.new(1, 1, 1);
            point.Parent = workspace;
            point.Shape = Enum.PartType.Ball;
            point.Anchored = true;
            point.CanCollide = false;
            point.Material = Enum.Material.SmoothPlastic;
            point.CFrame = CFrame.new(position);
            point.BrickColor = brickColor;

            local label = Bots:AddLabel(string.format('Point %d | %s', #botPoints, tostring(roundPosition)));
            label.main.TextColor3 = brickColor.Color;
            label.main.InputBegan:Connect(function(inputObject)
                if(inputObject.UserInputType ~= Enum.UserInputType.MouseButton1) then return end;

                repeat
                    workspace.CurrentCamera.CameraSubject = point;
                    Heartbeat:Wait();
                until inputObject.UserInputState == Enum.UserInputState.End;

                workspace.CurrentCamera.CameraSubject = LocalPlayer.Character;
            end);

            table.insert(botPointsUI, label);
            table.insert(botPointsUI, Bots:AddSlider({text = 'Delay', textpos = 2, value = pointData.delay, min = 0, max = 15, callback = function(val) pointData.delay = val end}));
            table.insert(botPointsUI, Bots:AddToggle({text = 'Wait For Trinkets', state = waitForTrinkets, callback = function(val) pointData.waitForTrinkets = val end}));
            table.insert(botPointsParts, point);

            refreshPoints();
        end;

        function clearPointsPrompt()
            if (library:ShowConfirm('Are you sure ?')) then clearPoints() end;
        end;

        function refreshPoints()
            if(#botPointsParts >= 2) then
                for i, v in next, botPointsLines do
                    v:Destroy();
                end;

                table.clear(botPointsLines);

                local params = RaycastParams.new();
                params.FilterType = Enum.RaycastFilterType.Whitelist;
                params.FilterDescendantsInstances = isGaia and {workspace.Map} or {};

                for i = 1, #botPointsParts do
                    local pointA, pointB = botPointsParts[i], botPointsParts[i + 1];

                    if(pointA and pointB) then
                        local line = Instance.new('Part');

                        line.Size = Vector3.new(0.5, 0.5, (pointA.Position-pointB.Position).Magnitude);
                        line.Parent = workspace;
                        line.Material = Enum.Material.SmoothPlastic;
                        line.Color = workspace:Raycast(pointA.Position, (pointB.Position - pointA.Position).Unit*line.Size.Z, params) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 0);
                        line.Anchored = true;
                        line.CanCollide = false;
                        line.CFrame = CFrame.new(pointA.Position, pointB.Position) * CFrame.new(0, 0, -(pointA.Position-pointB.Position).Magnitude/2);

                        table.insert(botPointsLines, line);
                    end;
                end;
            end;
        end;

        function clearPoints()
            for i, v in next, botPointsUI do
                for i2, v2 in next, v do
                    if(typeof(v2) == 'Instance') then
                        v2:Destroy();
                    end;
                end;
            end;

            for i, v in next, botPointsLines do
                v:Destroy();
            end;

            for i, v in next, botPointsParts do
                v:Destroy();
            end;

            table.clear(botPointsLines);
            table.clear(botPointsParts);
            table.clear(botPoints);
            table.clear(botPointsUI);
        end;

        local canceled = false;

        function previewBot()
            if(#botPoints <= 0) then return end;
            canceled = false;

            local part = Instance.new('Part');
            part.Size = Vector3.new(5, 5, 5);
            part.Anchored = true;
            part.Shape =  Enum.PartType.Ball;
            part.Parent = workspace;
            part.Color = Color3.fromRGB(255, 0, 0);
            part.CanCollide = false;
            part.Material = Enum.Material.SmoothPlastic;
            part.CFrame = CFrame.new(botPoints[1].position);

            workspace.CurrentCamera.CameraSubject = part;

            local function startPointLoop(n1, n2, n3)
                for i = n1, n2, n3 or 1 do
                    local v = botPoints[i];
                    if(canceled) then break end;

                    local tween = TweenService:Create(part, TweenInfo.new((part.Position - v.position).Magnitude / 150, Enum.EasingStyle.Linear), {
                        CFrame = CFrame.new(v.position)
                    });

                    local completed = false;

                    tween.Completed:Connect(function() completed = true end);
                    tween:Play();

                    repeat task.wait() until completed or canceled;
                    local startedAt = tick();
                    repeat task.wait() until tick() - startedAt > v.delay or canceled;

                    if(canceled) then
                        tween:Cancel();
                    end;
                end;
            end;

            startPointLoop(1, #botPoints);
            startPointLoop(#botPoints, 1, -1);

            task.wait(1);
            part:Destroy();
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character;
        end;

        function cancelPreview()
            canceled = true;
        end;

        function saveBot()
            if(isfile(library.flags.fileName .. '.json')) then
                library:ShowMessage('A file with this name already exists!');
                return;
            end;

            local saveData = {};

            for i, v in next, botPoints do
                table.insert(saveData, {
                    position = tostring(v.position),
                    delay = v.delay,
                    waitForTrinkets = v.waitForTrinkets
                });
            end;

            writefile(library.flags.fileName .. '.json', HttpService:JSONEncode(saveData));
            library:ShowMessage('Path has been saved under synapsex/workspace/' .. library.flags.fileName .. '.json');
        end;

        function loadBot()
            if (library:ShowConfirm('Are you sure ? (This will clear your current path)')) then
                xpcall(function()
                    local suc, file = pcall(readfile, library.flags.fileName .. '.json');
                    if(not suc) then
                        return library:ShowMessage('File not found');
                    end;

                    local pointsData = HttpService:JSONDecode(file);

                    clearPoints();

                    for i, v in next, pointsData do
                        v.position = Vector3.new(unpack(v.position:split(',')));
                        addPoint(v.position, v.delay, v.waitForTrinkets);
                    end;

                    library:ShowMessage('Path loaded');
                end, function()
                    library:ShowMessage('An error has occured!');
                end);
            end;
        end;

        function removeLastPoint()
            if(#botPoints <= 0) then return end;
            table.remove(botPoints, #botPoints);
            table.remove(botPointsParts, #botPointsParts):Destroy();

            if(#botPointsLines > 0) then
                table.remove(botPointsLines, #botPointsLines):Destroy();
            end;

            for i = 1, 3 do
                for i, v in next, table.remove(botPointsUI, #botPointsUI) or {} do
                    if(typeof(v) == 'Instance') then
                        v:Destroy();
                    end;
                end;
            end;
        end;

        function startBot()
            local suc, file = pcall(readfile, library.flags.fileName .. '.json');

            if(not suc) then
                return library:ShowMessage('Failed to start bot, file not found');
            end;

            local pointsData = HttpService:JSONDecode(file);
            clearPoints();

            for i, v in next, pointsData do
                v.position = Vector3.new(unpack(v.position:split(',')));
                addPoint(v.position, v.delay, v.waitForTrinkets);
            end;

            MemStorageService:SetItem('botStarted', 'true');
            createBot(pointsData);
        end;

        function startBotPrompt()
            if (library:ShowConfirm('Are you sure you want to start the bot ?')) then
                startBot();
            end;
        end;

        library.OnLoad:Connect(function()
            if(MemStorageService:HasItem('botStarted')) then
                startBot();
            end;
        end);
    end;

    function noClip(toggle)
        if(not toggle) then return end;

        library.options.fly:SetState(true);
        repeat
            local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid");

            if(Humanoid and not isUnderWater() and not isKnocked()) then
                for _, part in next, LocalPlayer.Character:GetDescendants() do
                    if(part:IsA('BasePart')) then
                        part.CanCollide = false;
                    end;
                end;
            end;
            Humanoid:ChangeState("Jumping");
            Humanoid.JumpPower = 0;
            RunService.Stepped:Wait();
        until not library.flags.noClip;
        local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid");

        library.options.fly:SetState(false);
        if (not Humanoid) then return; end
        LocalPlayer.Character.Humanoid.JumpPower = 45;
    end;

    function noInjuries(toggle)
        if(not toggle) then return end;

        repeat
            local character = LocalPlayer.Character;
            local boosts = character and character:FindFirstChild('Boosts');
            if(character) then
                removeGroup(character, injuryObjects);

                if(boosts) then
                    removeGroup(boosts, injuryObjects);
                end;
            end;
            task.wait();
        until not library.flags.noInjuries;
    end;

    function noFog(toggle)
        if(not toggle) then return end;
        local oldFogStart, oldFogEnd = Lighting.FogStart, Lighting.FogEnd;

        repeat
            Lighting.FogStart = 99999;
            Lighting.FogEnd = 99999;
            task.wait();
        until not library.flags.noFog;

        Lighting.FogStart, Lighting.FogEnd = oldFogStart, oldFogEnd;
    end;

    function noClipXray(toggle)
        if(not toggle) then return end;

        repeat
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');

            if(rootPart) then
                local region = Region3.new(rootPart.Position - Vector3.new(1, 0, 1), rootPart.Position + Vector3.new(1, 0, 1));
                local parts = workspace:FindPartsInRegion3WithIgnoreList(region, {workspace.Live, workspace.MonsterSpawns})

                for i, v in next, noclipBlocks do
                    noclipBlocks[i].Transparency = 0;
                    table.remove(noclipBlocks, i);
                end;

                for _, part in next, parts do
                    if(part.Transparency == 0) then
                        table.insert(noclipBlocks, part);
                        part.Transparency = 0.5;
                    end;
                end;
            end;
            task.wait();
        until not library.flags.noClipXray;

        for i, v in next, noclipBlocks do
            noclipBlocks[i].Transparency = 0;
            table.remove(noclipBlocks, i);
        end;
    end;

    function speedHack(toggle)
        if(not toggle) then
            maid.speedHack = nil;
            maid.speedHackBV = nil;
            return;
        end;

        maid.speedHack = RunService.Heartbeat:Connect(function()
            local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
            if (not rootPart) then return end;

            local camera = workspace.CurrentCamera;
            if (not camera) then return end;
            if(library.flags.fly) then
                maid.speedHackBV = nil;
                return;
            end;

            maid.speedHackBV = (maid.speedHackBV and maid.speedHackBV.Parent and maid.speedHackBV) or Instance.new('BodyVelocity');

            maid.speedHackBV.Parent = rootPart;
            maid.speedHackBV.MaxForce = Vector3.new(100000, 0, 100000);
            maid.speedHackBV.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * library.flags.speedhackSpeed);
        end);
    end;

    function fly(toggle)
        if(not toggle) then
            maid.fly = nil;
            maid.flyBV = nil;
            return;
        end;

        maid.fly = RunService.Heartbeat:Connect(function()
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            if (not rootPart) then return end;

            local camera = workspace.CurrentCamera;
            if (not camera) then return end;

            maid.flyBV = (maid.flyBV and maid.flyBV.Parent and maid.flyBV) or Instance.new('BodyVelocity');

            maid.flyBV.Parent = rootPart;
            maid.flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
            maid.flyBV.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * library.flags.flySpeed);
        end);
    end;

    function antiFire(toggle)
        if(not toggle) then return end;

        repeat
            local Character = LocalPlayer.Character;
            if(Character and Character:FindFirstChild('Burning') and dodge) then
                if(isGaia) then
                    dodge:FireServer({4, math.random()});
                else
                    dodge:FireServer('back', workspace.CurrentCamera);
                end;
            end;

            Heartbeat:Wait();
        until not library.flags.antiFire;
    end;

    function allowFood()
        if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('NoEat')) then
            LocalPlayer.Character.NoEat:Destroy();
        end;
    end;

    local oldAmbient, oldBritghtness = Lighting.Ambient, Lighting.Brightness;

    function fullBright(toggle)
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

    function infiniteJump(toggle)
        if(not toggle) then return end;

        repeat
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            if(rootPart and UserInputService:IsKeyDown(Enum.KeyCode.Space) and not chatFocused) then
                rootPart.Velocity = Vector3.new(rootPart.Velocity.X, library.flags.infiniteJumpHeight, rootPart.Velocity.Z);
            end;
            task.wait(0.1);
        until not library.flags.infiniteJump;
    end;

    function maxZoom(toggle)
        for _, v in next, getconnections(LocalPlayer.Changed) do
            v:Disable();
        end;

        LocalPlayer.CameraMaxZoomDistance = toggle and 9e9 or 50;

        for _, v in next, getconnections(LocalPlayer.Changed) do
            v:Enable();
        end;
    end;

    function spamClick(toggle)
        if(not toggle) then
            maid.spamClick = nil;
            return
        end;

        local lastClick = tick();

        maid.spamClick = RunService.RenderStepped:Connect(function()
            if(tick() - lastClick < 0.13) then return end;
            if(not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('CharacterHandler')) then return end;
            lastClick = tick();

            LocalPlayer.Character.CharacterHandler.Remotes.LeftClick:FireServer({math.random(1, 10), math.random()});
        end);
    end;

    function clickDestroy()
        if(Mouse.Target and not Mouse.Target:IsA('Terrain')) then
            Mouse.Target:Destroy();
        end;
    end;

    function instantLog()
        repeat
            task.wait();
        until LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild('Danger');

        LocalPlayer:Kick('Logged Out Closing Roblox...');
        delay(5, function()
            game:Shutdown();
        end);
    end;

    function respawn()
        if (library:ShowConfirm('Are you sure you want to respawn ?')) then
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
            if(not humanoid) then return end;

            humanoid.Health = 0;
        end;
    end;

    function chatLoggerSetEnabled(state)
        chatLogger:SetVisible(state);
    end;

    function removeKillBricks(toggle)
        if(not toggle) then
            maid.removeKillBricks = nil;
        else
            maid.removeKillBricks = RunService.Heartbeat:Connect(function()
                local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
                if(not rootPart) then return end;

                local inDanger = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Danger');

                if(rootPart.Position.Y <= -550 and not library.flags.fly and inDanger) then
                    library.options.fly:SetState(true);
                    ToastNotif.new({
                        text = 'You were about to die, so script automatically enabled fly to prevent you from dying :sungl:'
                    });
                end;
            end);
        end;

        for i,v in next, killBricks do
            v.Parent = not toggle and workspace or nil;
        end;
    end;

    do -- // Auto Pickup
        local trinkets = {};
        local ingredients = {};

        local function onChildAdded(obj)
            local isIngredient = obj.Parent == ingredientsFolder;
            local isTrinket = not isIngredient;
            local t = isIngredient and ingredients or trinkets;

            if(isIngredient or (obj:FindFirstChild('Part') and obj.Part.Size == Vector3.new(1.5, 1.5, 1.5))) then
                table.insert(t, obj);

                local propertyWatched = isIngredient and 'Transparency' or 'Parent';
                local connection;
                connection = obj:GetPropertyChangedSignal(propertyWatched):Connect(function()
                    task.wait();
                    if(obj.Parent and isIngredient or not connection) then return end;

                    if(obj:IsDescendantOf(game)) then return; end

                    connection:Disconnect();
                    connection = nil;

                    table.remove(t, table.find(t, obj));
                end);
            end;
        end;

        library.OnLoad:Connect(function()
            if (library.flags.collectorAutoFarm) then
                warn('[Auto Pickup] Not enabling cuz collector bot is on');
                return;
            end;

            if(ingredientsFolder) then
                for _, obj in next, ingredientsFolder:GetChildren() do
                    task.spawn(onChildAdded, obj);
                end;

                ingredientsFolder.ChildAdded:Connect(onChildAdded);
            end;

            for _, obj in next, workspace:GetChildren() do
                task.spawn(onChildAdded, obj);
            end;

            workspace.ChildAdded:Connect(onChildAdded);
        end);

        local function makeAutoPickup(maidName, t)
            return function(toggle)
                if(not toggle) then
                    maid[maidName] = nil;
                    return;
                end;

                local lastUpdate = 0;

                maid[maidName] = RunService.RenderStepped:Connect(function()
                    local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
                    if(not rootPart or tick() - lastUpdate < 0.2) then return end;

                    lastUpdate = tick();

                    for i,v in next, t do
                        if((rootPart.Position - v.Position).Magnitude <= 25) then
                            local clickDetector = v:FindFirstChildWhichIsA('ClickDetector', true);
                            if(clickDetector and clickDetector.MaxActivationDistance <= 100) then
                                fireclickdetector(clickDetector, 1);
                            end;
                        end;
                    end;
                end);
            end;
        end;

        autoPickup = makeAutoPickup('autoPickup', trinkets);
        autoPickupIngredients = makeAutoPickup('autoPickupIngredients', ingredients);
    end;

    function attachToBack()
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
        if(not rootPart) then return end;

        for i, v in next, Players:GetPlayers() do
            local plrRoot = v.Character and v.Character:FindFirstChild('HumanoidRootPart');
            if(not plrRoot or v == LocalPlayer) then continue end;

            if((plrRoot.Position - rootPart.Position).Magnitude <= 50) then
                rootPart.CFrame = CFrame.new(plrRoot.Position - plrRoot.CFrame.LookVector * 2, plrRoot.Position);
                break;
            end;
        end
    end;

    function disableAmbientColors(t)
        if(not t) then
            maid.disableAmbientColors = nil;
            task.wait();
            Lighting.areacolor.Enabled = true;
            return;
        end;

        maid.disableAmbientColors = RunService.Heartbeat:Connect(function()
            if(not Lighting:FindFirstChild('areacolor')) then return end;
            Lighting.areacolor.Enabled = false;
        end);
    end;

    function streamerMode(toggle)
        local defaultCharName;

        local function updateStreamerMode(value)
            local statGui = LocalPlayer:FindFirstChild('PlayerGui') and LocalPlayer.PlayerGui:FindFirstChild('StatGui');
            local container = statGui and statGui:FindFirstChild('Container');
            local characterName = container and container:FindFirstChild('CharacterName');
            local characterNameShadow = characterName and characterName:FindFirstChild('Shadow');

            if(not defaultCharName and characterName) then
                defaultCharName = characterName.Text;
            end;

            local leaderstats = LocalPlayer and LocalPlayer:FindFirstChild('leaderstats');
            local hidden =  leaderstats and leaderstats:FindFirstChild('Hidden');

            local deadContainer = statGui and statGui:FindFirstChildOfClass('TextLabel');

            if (hidden) then
                hidden.Value = value;
            end;

            if(characterName and characterNameShadow) then
                characterName.Text = value and "" or defaultCharName;
                characterNameShadow.Text = value and "" or defaultCharName;
            end;

            if(deadContainer) then
                deadContainer.Visible = not value;
            end;
        end;

        repeat
            updateStreamerMode(true)
            task.wait();
        until not library.flags.streamerMode;

        updateStreamerMode(false);
    end;

    function spellStacking(toggle)
        if(not toggle) then
            maid.spellStacking = nil;
            return;
        end;

        maid.spellStacking = RunService.RenderStepped:Connect(function()
            local Character = LocalPlayer.Character;
            if (not Character) then return end;

            local activeCast = Character:FindFirstChild('ActiveCast') or Character:FindFirstChild('VampiriusCast');
            local boosts = Character and Character:FindFirstChild('Boosts');

            if(activeCast) then
                activeCast:Destroy();
            end;

            if(boosts) then
                for i, v in next, boosts:GetChildren() do
                    if(v.Name == "SpeedBoost" and v.Value <= 0) then
                        v:Destroy();
                    end;
                end;
            end;
        end);
    end;

    function antiHystericus(toggle)
        local antiHystericusList = {'NoControl', 'Confused'};
        if(not toggle) then return end;

        repeat
            task.wait();
            if(not LocalPlayer.Character) then continue end;

            removeGroup(LocalPlayer.Character, antiHystericusList);
        until not library.flags.antiHystericus;
    end;

    function spectatePlayer(playerName)
        playerName = tostring(playerName);
        local player = findPlayer(playerName);
        local playerHumanoid = player and player.Character and player.Character:FindFirstChildOfClass('Humanoid');

        if(playerHumanoid) then
            workspace.CurrentCamera.CameraType = Enum.CameraType.Custom;
            workspace.CurrentCamera.CameraSubject = playerHumanoid;
        end;
    end;

    local furnaceFolder;
    local allFurnaces = {};

    do
        Utility.listenToChildAdded(workspace, function(obj)
            if(obj.Name == 'PortableFurnace' and obj:IsA('Model')) then
                table.insert(allFurnaces, obj);
                obj.Destroying:Connect(function()
                    table.remove(allFurnaces, table.find(allFurnaces, obj));
                end);
            end;
        end);
    end;

    function autoSmelt(toggle)
        if(not toggle) then return end;

        if (not furnaceFolder) then
            furnaceFolder = workspace:FindFirstChild('Bed', true);
            furnaceFolder = furnaceFolder and furnaceFolder.Parent;
        end;

        local lastSmeltAttempt;
        repeat
            task.wait();
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid');
            if(not humanoid or not furnaceFolder or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart')) then continue end;

            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            local isNearFurnace = false;
            local currentFurnace;

            for i, v in next, furnaceFolder:GetChildren() do
                if(v.Name == 'Furnace' and v:IsA('BasePart') and (v.Position - rootPart.Position).Magnitude <= 25) then
                    isNearFurnace = true;
                    currentFurnace = v;
                    break;
                end;
            end;

            if (not currentFurnace) then
                for _, v in next, allFurnaces do
                    if ((v.PrimaryPart.Position - rootPart.Position).Magnitude <= 25) then
                        local furnace = v:FindFirstChild('Furnace');
                        if (not furnace) then continue end;
        
                        warn('wee', furnace);
                        isNearFurnace = true;
                        currentFurnace = furnace;
                        break;
                    end;
                end;
            end;

            if(not isNearFurnace) then continue; end;

            for _, v in next, LocalPlayer.Backpack:GetChildren() do
                if (not library.flags.autoSmelt) then break end;
                if (not v:FindFirstChild('Ore')) then continue end;
                local handle = v:FindFirstChild('Handle');
                if (not handle) then continue end;

                firetouchinterest(handle, currentFurnace, 0);
                lastSmeltAttempt = tick();
                humanoid:EquipTool(v);
                repeat task.wait() until v.Parent == nil or tick() - lastSmeltAttempt >= 2;
                firetouchinterest(handle, currentFurnace, 1);
            end;
        until not library.flags.autoSmelt;
    end;

    function autoSell(toggle)
        if(not toggle) then
            return;
        end;

        local lastUpdate = 0;
        local artifactsList = {'Phoenix Down', 'Lannis\'s Amulet', 'Spider Cloak', 'Philosopher\'s Stone', 'Ice Essence', 'Howler Friend', 'Amulet of the White King', 'Fairfrozen', 'Scroom Key', 'Nightstone', 'Rift Gem', 'Scroll of Manus Dei', 'Scroll of Fimbulvetr', 'Mysterious Artifact'};

        repeat
            task.wait()
            if(tick() - lastUpdate < 1) then continue end;

            local merchant = getCurrentNpc({'Merchant', 'Pawnbroker'});
            if(not merchant) then continue end;

            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
            if(not humanoid) then continue end;

            if(library.flags.autoSellValues.Scrolls or library.flags.autoSellValues.Gems or library.flags.autoSellValues.Swords) then
                local scroll;

                for i, v in next, LocalPlayer.Backpack:GetChildren() do
                    if(table.find(artifactsList, v.Name)) then continue end;
                    if(v:FindFirstChild('SpellType') and library.flags.autoSellValues.Scrolls or v:FindFirstChild('Gem') and library.flags.autoSellValues.Gems or v:FindFirstChild('Smithed') and library.flags.autoSellValues.Swords) then
                        scroll = v;
                    end;
                end;

                if(not scroll) then continue end;
                lastUpdate = tick();

                humanoid:EquipTool(scroll);
                fireclickdetector(merchant.ClickDetector, 1);
                task.wait(0.2);
                dialog:FireServer({choice = 'Could you appraise this for me?'});
                task.wait(0.2);
                dialog:FireServer({choice = 'It\'s a deal.'});
                task.wait(0.2);
                dialog:FireServer({exit = true});

                continue;
            end;
        until not library.flags.autoSell;
    end;

    function manaAdjust(toggle)
        if(not toggle) then
            if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Charge')) then
                dechargeMana();
            end;

            return;
        end;

        repeat
            task.wait();
            local currentTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
            if(currentTool and spellValues[currentTool.Name] and library.flags.spellAdjust) then continue; end;

            chargeManaUntil(library.flags.manaAdjustAmount);
        until not library.flags.manaAdjust;
    end;

    function wipe()
        if (library:ShowConfirm('Are you sure you want to wipe your account ?')) then
            fallDamage:FireServer({math.random(), 3})
            task.wait(1);
            if(LocalPlayer.Character:FindFirstChild('Head')) then
                LocalPlayer.Character.Head:Destroy();
            end;
        end;
    end;

    function toggleTrinketEsp(toggle)
        if(not toggle) then
            maid.trinketEsp = nil;
            trinketEspBase:Disable();
            return;
        end;

        maid.trinketEsp = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
            debug.profilebegin('Trinket Esp Update');
            trinketEspBase:UpdateAll();
            debug.profileend();
        end);
    end;

    function toggleIngredientsEsp(toggle)
        if(not toggle) then
            maid.ingredientEsp = nil;
            ingredientEspBase:Disable();
            return;
        end;

        maid.ingredientEsp = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
            debug.profilebegin('Ingredient Esp Update');
            ingredientEspBase:UpdateAll();
            debug.profileend();
        end);
    end;

    function toggleMobEsp(toggle)
        if(not toggle) then
            maid.mobEsp = nil;
            mobEspBase:Disable();
            return;
        end;

        maid.mobEsp = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
            debug.profilebegin('Mob Esp Update');
            mobEspBase:UpdateAll();
            debug.profileend();
        end);
    end;

    function toggleNpcEsp(toggle)
        if(not toggle) then
            maid.npcEsp = nil;
            npcEspBase:Disable();
            return;
        end;

        maid.npcEsp = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
            debug.profilebegin('Npc Esp Update');
            npcEspBase:UpdateAll();
            debug.profileend();
        end);
    end;

    function toggleBagEsp(toggle)
        if(not toggle) then
            maid.bagEsp = nil;
            bagEspBase:Disable();
            return;
        end;

        maid.bagEsp = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
            debug.profilebegin('Bag Esp Update');
            bagEspBase:UpdateAll();
            debug.profileend();
        end);
    end;

    function toggleSpellAutoCast(toggle)
        if(not toggle) then
            maid.spellCast = nil;
            return;
        end;

        local lastCast = 0;

        maid.spellCast = RunService.RenderStepped:Connect(function()
            if(tick() - lastCast <= 2.5 and not library.flags.spellStacking) then return end;

            local currentTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
            if(not currentTool) then return end;

            local amounts = spellValues[currentTool.Name];
            if(not amounts) then return end;

            local useSnap = library.flags[toCamelCase(currentTool.Name .. ' Use Snap')];
            amounts = amounts[useSnap and 2 or 1];

            local mana = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Mana');
            if(not mana) then return end;

            if(mana.Value > amounts.min and mana.value < amounts.max) then
                lastCast = tick();
                if(useSnap) then
                    LocalPlayer.Character.CharacterHandler.Remotes.RightClick:FireServer({math.random(1, 10), math.random()});
                else
                    LocalPlayer.Character.CharacterHandler.Remotes.LeftClick:FireServer({math.random(1, 10), math.random()});
                end;
            end;
        end);
    end;

    function toggleSpellAdjust(toggle)
        if(not toggle) then return; end;

        repeat
            RunService.RenderStepped:Wait();

            local currentTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
            if(not currentTool) then continue; end;

            local amounts = spellValues[currentTool.Name];
            if(not amounts) then continue end;

            local useSnap = library.flags[toCamelCase(currentTool.Name .. ' Use Snap')];
            amounts = amounts[useSnap and 2 or 1];

            local amount = amounts.max - (amounts.max  - amounts.min) / 2;

            chargeManaUntil(amount);
        until not library.flags.spellAdjust;
    end;

    function goToGround()
        local params = RaycastParams.new();
        params.FilterDescendantsInstances = {workspace.Live, workspace.NPCs, workspace.AreaMarkers};
        params.FilterType = Enum.RaycastFilterType.Blacklist;

        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
        if (not rootPart) then return end;

        -- setclipboard(tostring(Character.HumanoidRootPart.Position));
        local floor = workspace:Raycast(rootPart.Position, Vector3.new(0, -1000, 0), params);
        if(not floor) then return end;

        rootPart.CFrame = rootPart.CFrame * CFrame.new(0, -(rootPart.Position.Y - floor.Position.Y) + 3, 0);
        -- rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z);
    end;

    function pullToGround(t)
        if (not t) then
            maid.pullToGround = nil;
            return;
        end;

        local params = RaycastParams.new();
        params.FilterDescendantsInstances = {workspace.Live, workspace.NPCs, workspace.AreaMarkers};
        params.FilterType = Enum.RaycastFilterType.Blacklist;
        params.IgnoreWater = true;
        params.RespectCanCollide = true;

        maid.pullToGround = task.spawn(function()
            while true do
                task.wait(0.1);
                local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
                if (not rootPart) then continue end;

                local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid');
                if (not humanoid) then continue end;

                if(humanoid.FloorMaterial ~= Enum.Material.Air) then continue; end;
                if (library.flags.fly or UserInputService:IsKeyDown(Enum.KeyCode.Space)) then continue; end;

                local floor = workspace:Raycast(rootPart.Position, Vector3.new(0, -1000, 0), params);
                if (not floor) then continue end;

                rootPart.CFrame = rootPart.CFrame * CFrame.new(0, -(rootPart.Position.Y - floor.Position.Y) + 3, 0);
                rootPart.Velocity = Vector3.zero;
            end;
        end);
    end;

    function setLocation()
		if (not library:ShowConfirm(string.format('Are you sure you want to tp to %s', library.flags.location))) then return end;

        local npc = spawnLocations[library.flags.location];
        local char = game.Players.LocalPlayer.Character;

		local con;
		con = RunService.Heartbeat:Connect(function()
			sethiddenproperty(LocalPlayer, 'MaxSimulationRadius', math.huge);
			sethiddenproperty(LocalPlayer, 'SimulationRadius', math.huge);
		end)

		dialog:FireServer({choice = 'Sure.'})
		for i = 1,10 do
			char:BreakJoints();
			task.wait();
			char:PivotTo(npc:GetPivot());
			char.HumanoidRootPart.CFrame = npc:GetPivot();

			task.wait(0.1);
			fireclickdetector(npc.ClickDetector);
			task.wait(0.2)
		end;

		con:Disconnect();
    end;

    function serverHop()
        if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Danger')) then
            repeat
                task.wait()
            until not LocalPlayer.Character:FindFirstChild('Danger');
        end;

        LocalPlayer:Kick('Server Hopping...');
        findServer();
    end;

    function satan(toggle)
        if (not toggle) then
            maid.satan = nil;

            if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')) then
                LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true);
            end;

            return;
        end;

        maid.satan = RunService.Heartbeat:Connect(function()
            if(not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')) then return end;

            LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false);
        end);
    end;

    function noStun(toggle)
        if (not toggle) then
            maid.noStun = nil;
            return;
        end;

        maid.noStun = RunService.Heartbeat:Connect(function()
            local character = LocalPlayer.Character;
            if (not character) then return end;

            if (character:FindFirstChild('Action')) then character.Action:Destroy() end;
            if (character:FindFirstChild('NoJump')) then character.NoJump:Destroy() end;
        end);
    end;

	function infMana(toggle)
		if (not toggle) then
			maid.infMana = nil;
			return;
		end;

		maid.infMana = RunService.Heartbeat:Connect(function()
			local mana = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Mana');
			if (not mana) then return end;

			mana.Value = 100;
		end);
	end;

    function flyOwnership(toggle)
        if (not toggle) then
            maid.flyOwnership = nil;
            return;
        end;

        maid.flyOwnership = RunService.Heartbeat:Connect(function()
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            if (not rootPart) then return end;

            local bone = rootPart and rootPart:findFirstChild('Bone');

            if (bone and bone:FindFirstChild('Weld')) then
                bone.Weld:Destroy();
            end;
        end);
    end;

    function knockYourself()
        if (library:ShowConfirm('Are you sure you want to knock yourself ?')) then
            fallDamage:FireServer({math.random(), 1});
        end;
    end;

    local stringFormat = string.format;
	local bags = {};

	function autoPickupBag(toggle)
		if (not toggle) then
			maid.autoBagPickup = nil;
			return
		end;

		maid.autoBagPickup = RunService.Heartbeat:Connect(function()
			local rootPart = Utility:getRootPart();
			if (not rootPart) then return end;

			for _, bag in next, bags do
				local dist = (rootPart.Position - bag.Position).Magnitude;
				local range = bag.Name == 'ToolBag' and library.flags.bagPickupRange or library.flags.bagPickupRange * 2;
				if (dist > range) then continue end;

				task.spawn(function()
					firetouchinterest(bag, rootPart, 0);
					task.wait();
					firetouchinterest(bag, rootPart, 1);
				end);
			end;
		end);
	end;

    function EntityESP:Plugin()
        local holdingItem = self._player.Character and self._player.Character:FindFirstChildWhichIsA('Tool');
        local firstName = getPlayerStats(self._player);
        local manaAbilities = self._player.Character and self._player.Character:FindFirstChild('ManaAbilities');

        return {
            text = stringFormat(
                '\n[%s] [%s] [%s] [%s] %s',
                firstName,
                getPlayerClass(self._player),
                getPlayerRace(self._player),
                holdingItem and holdingItem.Name or 'None',
                manaAbilities and not manaAbilities:FindFirstChild('ManaSprint') and '[Day 0]' or ''
            );
        }
    end;

    local function initEspStuff()
        local damageIndicator = {};

        do -- // Player Stuff
            local blacklistedHouses = {'Mudock', 'Mudockfat', 'Archfat', 'Female'};
            local mudockList = {};

            local function isInGroup(player, groupId)
                local suc, err = pcall(player.IsInGroup, player, groupId);

                if(not suc) then return false end;
                return err;
            end;

            local function addIllusionist(player)
                if(illusionists[player]) then return end;
                illusionists[player] = true;

                loadSound('IllusionistJoin.mp3');
                makeNotification('Illusionist Alert', string.format('[%s] Has joined your game', player.Name), true);
            end;

            local artifactsList = {'Phoenix Down', 'Lannis\'s Amulet', 'Spider Cloak', 'Philosopher\'s Stone', 'Ice Essence', 'Howler Friend', 'Amulet of the White King', 'Fairfrozen', 'Scroom Key', 'Nightstone', 'Rift Gem', 'Scroll of Manus Dei', 'Scroll of Fimbulvetr', 'Mysterious Artifact'};

            local function onPlayerAdded(player)
                if(player == LocalPlayer) then return end;

                local seen = {};

                local function onCharacterAdded(character)
                    local backpack = player:WaitForChild('Backpack');
                    local spectating = false;

                    local function onChildAddedPlayer(obj)
                        if (library.flags.artifactNotifier and (table.find(artifactsList, obj.Name) or obj:FindFirstChild('Artifact')) and not table.find(seen, obj.Name) and obj.Parent == backpack) then
                            table.insert(seen, obj.Name);
                            ToastNotif.new({
                                text = string.format('%s has %s', player.Name, obj.Name)
                            });
                        end;

                        if(obj.Name ~= 'Observe') then return end;
                        addIllusionist(player);

                        if(not library.flags.illusionistNotifier) then return end;
                        print(player.Name, obj.Parent == character and 'in character' or 'in backpack');

                        if(obj.Parent ~= backpack and not spectating) then
                            spectating = true;
                            loadSound('IllusionistSpectateStart.mp3');
                            makeNotification('Spectate Alert', string.format('[%s] Started spectating', player.Name), true);

                            if(library.flags.autoPanic and library.flags.autoPanicValues['Spectate']) then
                                panic();
                            end;
                        end;
                    end;

                    local function onChildRemovedPlayer(obj)
                        if(obj.Name ~= 'Observe' or not spectating) then return end;

                        spectating = false;
                        loadSound('IllusionistSpectateEnd.mp3');
                        makeNotification('Spectate Alert', string.format('[%s] Stopped spectating', player.Name), true);
                    end;

                    Utility.listenToChildAdded(backpack, onChildAddedPlayer);
                    Utility.listenToChildAdded(character, onChildAddedPlayer);
                    character.ChildRemoved:Connect(onChildRemovedPlayer);

                    local humanoid = character:WaitForChild('Humanoid');
                    local head = character:WaitForChild('Head');

                    local currentHealth = humanoid.Health;

                    humanoid.HealthChanged:Connect(function(newHealth)
                        if(newHealth < currentHealth and library.flags.damageIndicator and damageIndicator.new) then
                            damageIndicator.new(head, currentHealth - newHealth);
                        end;

                        currentHealth = humanoid.Health;
                    end);
                end;

                if(player.Character) then
                    task.spawn(onCharacterAdded, player.Character);
                end;

                player.CharacterAdded:Connect(onCharacterAdded);

                if(string.find(moderatorIds, tostring(player.UserId)) or isInGroup(player, 4556484)) then
                    moderatorInGame = true;
                    allMods[player] = true;

                    makeNotification('Mod Alert', string.format('[%s] Has joined your game.', player.Name), true);

                    if(library.flags.autoPanic and library.flags.autoPanicValues['Mod Join']) then
                        task.spawn(panic);
                    end;

                    loadSound('ModeratorJoin.mp3');
                end;

                if(table.find(blacklistedHouses, player:GetAttribute('LastName') or 'Unknown')) then
                    makeNotification('Mudock Alert', string.format('[%s] Has joined your game', player.Name), true);
                    mudockList[player] = true;

                    if(library.flags.autoPanic and library.flags.autoPanicValues['Mudock Join']) then
                        panic();
                    end;
                end;
            end;

            local function onPlayerRemoving(player)
                if(allMods[player]) then
                    moderatorInGame = false;
                    allMods[player] = nil;
                    loadSound('ModeratorLeft.mp3');
                    makeNotification('Mod Alert', string.format('%s left the game', tostring(player)), true);
                end;

                if(illusionists[player]) then
                    makeNotification('Illusionist', string.format('[%s] Has left your game', player.Name), true);
                    loadSound('IllusionistLeft.mp3');
                    illusionists[player] = nil;
                end;

                if(mudockList[player]) then
                    makeNotification('Mudock Alert', string.format('%s Has left your game', tostring(player)), true);
                    mudockList[player] = nil;
                end;
            end;

            for i, v in next, Players:GetPlayers() do
                task.spawn(onPlayerAdded, v);
            end;

            Players.PlayerAdded:Connect(onPlayerAdded);
            Players.PlayerRemoving:Connect(onPlayerRemoving);
        end;

        if (library.flags.collectorAutoFarm) then
            warn('[Player ESP] Not turning off cause player has collector bot on');
            return;
        end;

        local function getId(id)
            return id:gsub('%%20', ''):gsub('%D', '');
        end;

        local function findInTable(t, index, value)
            for i, v in next, t do
                if v[index] == value then
                    return v;
                end;
            end;
        end;

        local opalColor = Vector3.new(1, 1, 1);

        function getTrinketType(v) -- // This code is from the old source too lazy to remake it as this one works properly
            if (v.Name == "Part" or v.Name == "Handle" or v.Name == "MeshPart") and (v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart")) then
                local Mesh = (v:IsA("MeshPart") and v) or v:FindFirstChildOfClass("SpecialMesh");
                local ParticleEmitter = v:FindFirstChildOfClass("ParticleEmitter");
                local Attachment = v:FindFirstChildOfClass("Attachment");
                local PointLight = v:FindFirstChildOfClass("PointLight");
                local Material = v.Material;
                local className = v.ClassName;
                local Size = v.Size;
                local SizeMagnitude = Size.Magnitude;
                local Color = v.BrickColor.Name;

                if(className == "UnionOperation" and Material == Enum.Material.Neon and SizeMagnitude < 3.1 and SizeMagnitude > 2) then
                    if(not v.UsePartColor) then
                        return trinketsData["White King's Amulet"];
                    else
                        return trinketsData["Lannis Amulet"];
                    end;
                end;

                if(className == "Part" and v.Shape == Enum.PartType.Block and Material == Enum.Material.Neon and Color == "Pastel Blue" and Mesh.MeshId == "") then
                    return trinketsData["Fairfrozen"];
                end;

                if(SizeMagnitude < 0.9 and Material == Enum.Material.Neon and className == "UnionOperation" and v.Transparency == 0) then
                    if(Color == "Persimmon") then
                        return trinketsData["Philosopher's Stone"];
                    elseif(Color == "Black") then
                        return trinketsData["Night Stone"];
                    end;
                end;

                if(Material == Enum.Material.DiamondPlate and v.Transparency == 0 and PointLight and PointLight.Brightness == 0.5) then
                    return trinketsData["Scroom Key"];
                end;

                if(className == "MeshPart" and getId(v.MeshId) == "2520762076") then
                    return trinketsData["Howler Friend"];
                end;

                if(Mesh and getId(Mesh.MeshId) == "2877143560") then
                    if(string.find(Color, "green")) then
                        return trinketsData["Emerald"];
                    elseif(Color == "Really red") then
                        return trinketsData["Ruby"];
                    elseif(Color == "Lapis") then
                        return trinketsData["Sapphire"];
                    elseif(string.find(Color, "blue")) then
                        return trinketsData["Diamond"];
                    else
                        return trinketsData["Rift Gem"];
                    end;
                end;

                if(ParticleEmitter and ParticleEmitter.Texture:find("20443483") and SizeMagnitude > 0.6 and SizeMagnitude < 0.8 and v.Transparency == 1 and Material == Enum.Material.Neon) then
                    if(className == "Part") then
                        return trinketsData["Ice Essence"];
                    end;
                    return trinketsData["Spider Cloak"];
                end;

                if(ParticleEmitter) then
                    local TextureId = ParticleEmitter.Texture:gsub("%D", "");
                    local Trinket = findInTable(Trinkets, "Texture", TextureId);

                    if(Trinket) then
                        return Trinket;
                    end;
                end;

                if(Mesh and Mesh.MeshId ~= "") then
                    local MeshId = Mesh.MeshId:gsub("%D", "");
                    local Trinket = findInTable(Trinkets, "MeshId", MeshId);

                    if(Trinket) then
                        return Trinket;
                    end;
                end;

                if(ParticleEmitter and Material == Enum.Material.Slate) then
                    return trinketsData["Idol Of The Forgotten"];
                end;

                if(Attachment) then
                    if(Attachment:FindFirstChildOfClass("ParticleEmitter")) then
                        local ParticleEmitter2 = Attachment:FindFirstChildOfClass("ParticleEmitter");

                        if (ParticleEmitter2) then
                            local TextureId = getId(ParticleEmitter2.Texture);
                            if(TextureId == '1536547385') then
                                if(ParticleEmitter2.Size.Keypoints[1].Value ~= 0) then
                                    return trinketsData['Mysterious Artifact'];
                                end;

                                return trinketsData['Pheonix Down'];
                            end
                            local Trinket = findInTable(Trinkets, "Texture", TextureId);
                            return Trinket;
                        end;
                    end;
                end;

                if(Mesh and Mesh:IsA('SpecialMesh') and Mesh.MeshType.Name == 'Sphere' and Mesh.VertexColor == opalColor) then
                    return trinketsData.Opal;
                end;
            end;
        end;

        local id = 0;

        local ingredientsIds = {
            ['2766802766'] = 'Strange Tentacle',
            ['2766925214'] = 'Crown Flower',
            ['2766802731'] = 'Dire Flower',
            ['3215371492'] = 'Potato',
            ['2766802752'] = 'Orcher Leaf',
            ['2620905234'] = 'Scroom',
            ['2766925289'] = 'Trote',
            ['2766925228'] = 'Tellbloom',
            ['2766925245'] = 'Uncanny Tentacle',
            ['2575167210'] = 'Moss Plant',
            ['2773353559'] = 'Bloodthorn',
            ['2766802713'] = 'Periascroom',
            ['2766925267'] = 'Creely',
            ['3049928758'] = 'Canewood',
            ['3049345298'] = 'Zombie Scroom',
            ['3049556532'] = 'Acorn Light',
            ['2766925320'] = 'Polar Plant',
            ['2577691737'] = 'Lava Flower',
            ['2573998175'] = 'Freeleaf',
            ['2618765559'] = 'Glow Scroom',
            ['2766925304'] = 'Vile Seed',
            ['2889328388'] = 'Ice Jar',
            ['2960178471'] = 'Snow Scroom',
            ['3293218896'] = 'Desert Mist',
        }

        local function getIngredientType(v) -- // Also old code but still works very well!
            local specialInfo = getspecialinfo and getspecialinfo(v) or getproperties(v);
            local assetId = specialInfo and specialInfo.AssetId and specialInfo.AssetId:match('%d+') or 'NIL';

            if(ingredientsIds[assetId]) then
                return ingredientsIds[assetId];
            else
                id = id + 1;
                return string.format('Unknown %s', id);
            end;
        end;

        local objectsRaycastFilter = RaycastParams.new();
        objectsRaycastFilter.FilterType = Enum.RaycastFilterType.Whitelist;
        objectsRaycastFilter.FilterDescendantsInstances = {workspace.AreaMarkers};

        local function onChildAdded(object)
            task.wait(1);
            if (not object:IsA('BasePart')) then return; end;

            local trinketType = getTrinketType(object);
            if (not trinketType or not object:FindFirstChildWhichIsA('ClickDetector', true)) then return end;

            local location = workspace:Raycast(object.Position, Vector3.new(0, 5000, 0), objectsRaycastFilter);
            location = location and location.Instance.Name or '???';

            local self = trinketEspBase.new(object, trinketType.Name);
            self._text = string.format('%s] [%s', trinketType.Name, location);

            self._maid:GiveTask(object:GetPropertyChangedSignal('Parent'):Connect(function()
                if(object.Parent) then return end;
                self:Destroy();
            end));
        end;

        local function onChildAddedIngredient(object)
            if (not IsA(object, 'BasePart')) then return; end;

            local ingredientType = getIngredientType(object);
            if (not ingredientType) then return end;

            local location = workspace:Raycast(object.Position, Vector3.new(0, 5000, 0), objectsRaycastFilter);
            location = location and location.Instance.Name or '???';

            local maid = Maid.new();

            if (object.Transparency == 0) then
                local obj = ingredientEspBase.new(object, ingredientType);
                maid.espObject = function()
                    obj:Destroy();
                end;
            end;

            object:GetPropertyChangedSignal('Transparency'):Connect(function()
                if(object.Transparency == 0) then
                    local obj = ingredientEspBase.new(object, ingredientType);
                    maid.espObject = function()
                        obj:Destroy();
                    end;
                elseif (maid.espObject) then
                    maid.espObject = nil;
                end;
            end);
        end;

        local function onMobAdded(object)
            task.wait(1);
            if (not object:FindFirstChild('MonsterInfo') or not object.MonsterInfo:FindFirstChild('MonsterType')) then
                return;
            end;

            local head = object:FindFirstChild('Head') or object.PrimaryPart;
            if (not head) then return end;

            local self = mobEspBase.new(head, object.MonsterInfo.MonsterType.Value);
            self._maid:GiveTask(object:GetPropertyChangedSignal('Parent'):Connect(function()
                if (object.Parent) then return end;
                self:Destroy();
            end));
        end;

        local function onNpcAdded(object)
            local head = object:FindFirstChild('Head') or object.PrimaryPart;
            if (not head) then return end;

            local self = npcEspBase.new(head, object.Name);
            self._maid:GiveTask(object:GetPropertyChangedSignal('Parent'):Connect(function()
                if (object.Parent) then return end;
                self:Destroy();
            end));
        end;

        local function onBagAdded(object)
            if (object.Name ~= 'ToolBag' and object.Name ~= 'MoneyBag') then return end;

			table.insert(bags, object);

            local name = object:WaitForChild('BillboardGui', 1);
            name = name and name:WaitForChild('Tool', 1);
            name = name and name.Text;

            if(not name) then return end;

            local self = bagEspBase.new(object, name);
            self._maid:GiveTask(object:GetPropertyChangedSignal('Parent'):Connect(function()
                if(object.Parent) then return end;
                self:Destroy();
				table.remove(bags, table.find(bags, object));
            end));
        end;

        do -- // Damage Indicator
            damageIndicator.ClassName = 'DamageIndicator';
            damageIndicator.__index = damageIndicator;

            local function generateOffSet()
                local n = Random.new():NextNumber() * 2;
                if (Random.new():NextInteger(1, 2) == 1) then
                    n = -n;
                end;

                return n;
            end;

            function damageIndicator.new(part, damage)
                local self = setmetatable({}, damageIndicator);
                self._maid = Maid.new();
                self._part = part;
                self._offset = Vector3.new(generateOffSet(), generateOffSet(), 0);

                self._gui = library:Create('ScreenGui', {
                    Parent = game:GetService('CoreGui')
                });

                self._text = library:Create('TextLabel', {
                    Parent = self._gui,
                    Rotation = generateOffSet() * 5,
                    Visible = true,
                    TextColor3 = Color3.fromRGB(231, 76, 60),
                  Text = '-' .. tostring(math.ceil(damage)),
                    BackgroundTransparency = 1,
                    TextStrokeTransparency = 0,
                    TextSize = 10
                });

                self._maid:GiveTask(self._gui);

                self._maid:GiveTask(RunService.Heartbeat:Connect(function()
                    self:Update();
                end));

                task.delay(2, function()
                    self:Destroy();
                end);
            end;

            function damageIndicator:Update()
                local partPosition, visible = workspace.CurrentCamera:WorldToViewportPoint(self._part.Position + self._offset);
                partPosition = Vector2.new(partPosition.X, partPosition.Y);

                self._text.Visible = visible;
                self._text.Position = UDim2.new(0, partPosition.X, 0, partPosition.Y);
            end;

            function damageIndicator:Destroy()
                assert(self._maid);

                self._maid:Destroy();
                self._maid = nil;
            end;
        end;

        if(ingredientsFolder) then
            Utility.listenToChildAdded(ingredientsFolder, onChildAddedIngredient);
        end;

        Utility.listenToChildAdded(workspace, onChildAdded);
        Utility.listenToChildAdded(workspace.Live, onMobAdded);
        Utility.listenToChildAdded(workspace:FindFirstChild('NPCs') or Instance.new('Folder'), onNpcAdded);
        Utility.listenToChildAdded(workspace.Thrown, onBagAdded);
    end;

    local climbBoost = Instance.new('NumberValue');
    climbBoost.Name = "ClimbBoost";

    task.spawn(function()
        local killPartsObjects = {'KillBrick', 'Lava', 'PoisonField', 'PitKillBrick'};

        local slate = Enum.Material.Slate;
        local map = isGaia and workspace:FindFirstChild('Map') or workspace;

        for i, v in next, map:GetChildren() do
            if(v.Name == 'Part' and IsA(v, 'Part') and v.Material == slate and v.CanCollide == false and v.Transparency == 1) then
                v.Transparency = 0.5;
                v.Color = Color3.fromRGB(255, 0, 0);

                local touchTransmitter = v:FindFirstChildWhichIsA('TouchTransmitter');

                if(touchTransmitter) then
                    touchTransmitter:Destroy();
                end;
            elseif(table.find(killPartsObjects, v.Name)) then
                table.insert(killBricks, v);
            end;
        end;
    end);

    task.spawn(function()
        while task.wait(0.2) do
            local character = LocalPlayer.Character;
            local boosts = character and character:FindFirstChild('Boosts');

            if(boosts and library.flags.climbSpeed ~= 1) then
                climbBoost.Value = library.flags.climbSpeed;
                climbBoost.Parent = boosts;
            else
                climbBoost.Parent = nil;
            end;

            local leaderboardGui = LocalPlayer:FindFirstChild('PlayerGui') and LocalPlayer.PlayerGui:FindFirstChild('LeaderboardGui');

            if (leaderboardGui and not leaderboardGui.Enabled) then
                leaderboardGui.Enabled = true;
            end;
        end;
    end);

    task.spawn(function()
        if (not LocalPlayer.Character and not LocalPlayer.PlayerGui:FindFirstChild('LeaderboardGui')) then
            local newLeaderboardGui = StarterGui:FindFirstChild('LeaderboardGui'):Clone();
            newLeaderboardGui.Parent = LocalPlayer.PlayerGui;

            LocalPlayer.CharacterAdded:Wait();
            newLeaderboardGui:Destroy();
        end;
    end);

    local spectating;
    local oldNamesColors = {};

    UserInputService.InputBegan:Connect(function(input)
        if(input.UserInputType ~= Enum.UserInputType.MouseButton2) then return end;
        if(not LocalPlayer:FindFirstChild('PlayerGui') or not LocalPlayer.PlayerGui:FindFirstChild('LeaderboardGui')) then return end;

        local leaderboardPlayers = LocalPlayer.PlayerGui.LeaderboardGui.MainFrame.ScrollingFrame:GetChildren();

        local function getHoveredPlayer()
            for i,v in next, leaderboardPlayers do
                if(v.TextTransparency ~= 0) then
                    return v;
                end;
            end;
        end;

        local label = getHoveredPlayer();
        if(not label) then return end;

        local player = Players:FindFirstChild(label.Text:gsub('\226\128\142', ''));
        if(not player or not player.Character) then return end;

        if(player == LocalPlayer) then
            spectating = player;
        end;

        for i, v in next, leaderboardPlayers do
            if(not oldNamesColors[v]) then
                oldNamesColors[v] = v.TextColor3;
            end;

            v.TextColor3 = oldNamesColors[v];
        end;

        if(spectating ~= player) then
            spectating = player;
            spectatePlayer(player.Name);
            label.TextColor3 = Color3.fromRGB(46, 204, 113);
        else
            spectating = nil;
            spectatePlayer(LocalPlayer.Name);
        end;
    end);

    library.OnLoad:Connect(initEspStuff);
end;

function Utility:renderOverload(data)
    local misc = data.column1:AddSection('Misc');
    local trinketEsp = data.column2:AddSection('Trinkets');
    local ingredientEsp = data.column2:AddSection('Ingredients');

    local trinketsToggles = {};
    local ingrdientsToggles = {};

    data.espSettings:AddBox({
        text = 'ESP Search',
        skipflag = true,
        noload = true
    });

    local function createEspList(t, func)
        return function(toggle, ...)
            for i, v in next, t do
                v.visualize.Parent.Visible = toggle;
            end;

            func(toggle, ...);
        end;
    end;

    trinketEsp:AddToggle({
        text = 'Enable',
        flag = 'Trinket Esp',
        callback = createEspList(trinketsToggles, toggleTrinketEsp)
    }):AddSlider({text = 'Max Distance', flag = 'Trinket Esp Max Distance', value = 500, min = 10, max = 5000});
    trinketEsp:AddToggle({text = 'Show Distance', flag = 'Trinket Esp Show Distance'})

    ingredientEsp:AddToggle({
        text = 'Enable',
        flag = 'Ingredient Esp',
        callback = createEspList(ingrdientsToggles, toggleIngredientsEsp);
    }):AddSlider({text = 'Max Distance', flag = 'Ingredient Esp Max Distance', value = 500, min = 10, max = 5000});
    ingredientEsp:AddToggle({text = 'Show Distance', flag = 'Ingredient Esp Show Distance'});

    misc:AddDivider('Mobs');
    misc:AddToggle({
        text = 'Enable',
        flag = 'Mob Esp',
        callback = toggleMobEsp
    }):AddSlider({text = 'Max Distance', flag = 'Mob Esp Max Distance', value = 500, min = 10, max = 10000});
    misc:AddToggle({text = 'Show Distance', flag = 'Mob Esp Show Distance'});

    misc:AddDivider('NPC')
    misc:AddToggle({
        text = 'Enable',
        flag = 'Npc Esp',
        callback = toggleNpcEsp
    }):AddSlider({text = 'Max Distance', flag = 'Npc Esp Max Distance', value = 500, min = 10, max = 10000});
    misc:AddToggle({text = 'Show Distance', flag = 'Npc Esp Show Distance'});

    misc:AddDivider('Bags');
    misc:AddToggle({
        text = 'Enable',
        flag = 'Bag Esp',
        callback = toggleBagEsp
    }):AddSlider({text = 'Max Distance', flag = 'Bag Esp Max Distance', value = 500, min = 10, max = 10000});
    misc:AddToggle({text = 'Show Distance', flag = 'Bag Esp Show Distance'});

    -- local Colors = library:CreateWindow('Esp - Colors');
    -- local Toggles = library:CreateWindow('Esp - Toggles');
    -- local Sliders = data.Sliders;

    for i,v in next, Trinkets do
        table.insert(trinketsToggles, trinketEsp:AddToggle({text = v.Name, flag = string.format('Show %s', v.Name), state = true}):AddColor({flag = string.format('%s Color', v.Name)}));
    end;

    for i, v in next, Ingredients do
        table.insert(ingrdientsToggles, ingredientEsp:AddToggle({text = v, flag = string.format('Show %s', v), state = true}):AddColor({flag = string.format('%s Color', v)}));
    end;

    library.OnLoad:Connect(function()
        for i, v in next, trinketsToggles do
            v.visualize.Parent.Visible = false;
        end;

        for i, v in next, ingrdientsToggles do
            v.visualize.Parent.Visible = false;
        end;
    end);
end;

local window = library.window;
local column3 = window:AddColumn();

local Main = column1:AddSection('Main');
local AutoPanic = column1:AddSection('Auto Panic');
local Removals = column2:AddSection('Removals');
local Automation = column2:AddSection('Automation');
local Misc = column1:AddSection('Misc');
local NoClip = column3:AddSection('NoClip');
local Visuals = column3:AddSection('Visuals');
local Spell = column2:AddSection('Spells');
Bots = column3:AddSection('Bots');
local ManaViewer = column3:AddSection('Mana Viewer');

Main:AddToggle({text = 'Artifact Notifier', state = true});
Main:AddToggle({text = 'Illusionist Notifier', state = true});
Main:AddToggle({text = 'Silent Aim'});
Main:AddToggle({text = 'Spell Stack', callback = spellStack});
spellCounter = Main:AddLabel(string.format('Spell Counter: %d', tonumber(#queue)));
Main:AddBind({text = 'Spell Stack Keybind'});

NoClip:AddToggle({text = 'Xray', flag = 'No Clip Xray', callback = noClipXray});
NoClip:AddToggle({text = 'Enable', flag = 'No Clip', callback =  noClip}):AddList({
    text = 'Disable Event Types',
    flag = 'No Clip Disable Values',
    values = {'Disable On Water', 'Disable When Knocked'},
    multiselect = true
});

ManaViewer:AddToggle({text = 'Enable', flag = 'Mana Viewer', callback = manaViewer});
ManaViewer:AddToggle({text = 'Show Mana Helper', callback = manaHelper});
ManaViewer:AddToggle({text = 'Show Cast Zone', callback = showCastZone});
ManaViewer:AddToggle({text = 'Show Overlay', callback = showManaOverlay});
ManaViewer:AddBox({text = 'Overlay Url', callback = setOverlayUrl});

ManaViewer:AddSlider({text = 'Overlay Scale X', textpos = 2, min = 1, max = 1920});
ManaViewer:AddSlider({text = 'Overlay Scale Y', textpos = 2, min = 1, max = 1080});

ManaViewer:AddSlider({text = 'Overlay Offset X', textpos = 2, min = -1920, max = 1920});
ManaViewer:AddSlider({text = 'Overlay Offset Y', textpos = 2, min = -1080, max = 1080});

Main:AddToggle({text = 'AA Gun Counter', callback = aaGunCounter});
Main:AddToggle({text = 'Days Farm', callback = daysFarm}):AddSlider({
    text = 'Days Farm Auto Log Range',
    flag = 'Days Farm Range',
    min = 0,
    max = 3000,
    value = 500
});
Main:AddToggle({text = 'Satan', callback = satan});
Main:AddBind({text = 'Attach To Back', mode = 'hold', callback = attachToBack});
Main:AddButton({text = 'Respawn', callback = respawn});
Main:AddButton({text = 'Wipe', callback = wipe});
Main:AddList({text = 'Location', values = {}})
Main:AddButton({text = 'Set Location (RISKY)', callback = setLocation})

library.OnLoad:Connect(function()
    for _, npc in next, workspace.NPCs:GetChildren() do
        if (npc.Name == 'Inn Keeper') then
            local location = npc:FindFirstChild('Location');
            library.options.location:AddValue(location.Value);
            spawnLocations[location.Value] = npc;
        end;
    end;
end);

if (isGaia) then
    Main:AddButton({text = 'Knock Yourself', callback = knockYourself});
    Main:AddToggle({text = 'Knocked Ownership', callback = flyOwnership});
end;

Main:AddToggle({text = 'Temp Lock(Hide Trinkets)', flag = 'Temperature Lock', callback = temperatureLock});
Main:AddButton({text = 'Allow Food', callback = allowFood});
Main:AddButton({text = 'Server Hop', callback = serverHop});

Main:AddToggle({text = 'Mana Adjust', callback = manaAdjust}):AddSlider({flag = 'Mana Adjust Amount', min = 10, max = 100}):AddBind({
    callback = function() library.options.manaAdjust:SetState(not library.flags.manaAdjust) end,
    flag = 'manaAdjustBind'
})

Main:AddToggle({text = 'Speed Hack', flag = 'Toggle Speed Hack', callback = speedHack}):AddSlider({flag = 'SpeedHack Speed', min = 16, max = 250}):AddBind({
    callback = function() library.options.toggleSpeedHack:SetState(not library.flags.toggleSpeedHack) end,
    flag = 'toggleSpeedHackBind'
});

Main:AddToggle({text = 'Fly', callback = fly}):AddSlider({flag = 'Fly Speed', min = 16, max = 250}):AddBind({
    callback = function() library.options.fly:SetState(not library.flags.fly) end,
    flag = 'toggleFlyBind'
});

Main:AddToggle({text = 'Infinite Jump', callback = infiniteJump}):AddSlider({flag = 'Infinite Jump Height', min = 50, max = 250}):AddBind({
    callback = function() library.options.infiniteJump:SetState(not library.flags.infiniteJump) end,
    flag = 'infiniteJumpBind'
});


Main:AddToggle({text = 'Chat Logger', callback = chatLoggerSetEnabled});
Main:AddToggle({text = 'Chat Logger Auto Scroll'})
Main:AddToggle({text = 'Spell Stacking', callback = spellStacking});

Removals:AddToggle({text = 'Remove Kill Bricks', callback = removeKillBricks});
Removals:AddToggle({text = 'Anti Hystericus', callback = antiHystericus});
Removals:AddToggle({text = 'Anti Fire', callback = antiFire});
Main:AddToggle({text = 'No Stun', callback = noStun});
Removals:AddToggle({text = 'No Mental Injuries'});
Removals:AddToggle({text = 'No Fall Damage'});
Removals:AddToggle({text = 'No Injuries', callback = noInjuries});

Automation:AddToggle({text = 'Bag Auto Pickup', callback = autoPickupBag}):AddSlider({text = 'Bag Pickup Range', min = 10, max = 90, value = 90});
Automation:AddToggle({text = 'Auto Pickup', callback = autoPickup});
Automation:AddToggle({text = 'Auto Pickup Ingredients', callback = autoPickupIngredients});
Automation:AddToggle({text = 'Auto Bard'});

buildAutoPotion(Automation);
buildAutoCraft(Automation);

Automation:AddToggle({text = 'Auto Click', callback = spamClick});
Automation:AddToggle({text = 'Auto Smelt', callback = autoSmelt});
Automation:AddToggle({text = 'Auto Sell', callback = autoSell}):AddList({
    values = {'Scrolls', 'Gems', 'Swords'},
    flag = 'Auto Sell Values',
    multiselect = true
})

AutoPanic:AddToggle({text = 'Enable', flag = 'Auto Panic'}):AddList({
    text = 'Event Types',
    values = {'Spectate', 'Mod Join', 'Mudock Join'},
    flag = 'Auto Panic Values',
    multiselect = true
});

Visuals:AddToggle({text = 'No Fog', callback = noFog});
Visuals:AddToggle({text = 'Fullbright', callback = fullBright});
Visuals:AddToggle({text = 'Disable Ambient Color', callback = disableAmbientColors});
Visuals:AddToggle({text = 'Damage Indicator'});

if (isGaia) then
	local triggers = workspace.MonsterSpawns.Triggers;
    local triggeredLocations = {
        ['Crypt'] = triggers.CryptTrigger.LastSpawned,
        ['Castle Rock'] = triggers.CastleRockSnake.LastSpawned,
        ['Snake Pit'] = triggers.MazeSnakes.LastSpawned,
		['Sunken Passage'] = triggers.evileye1.LastSpawned,
    };

    local function formatTime(seconds)
        local minutes = math.floor(seconds / 60);
        local hours = math.floor(minutes / 60);
        local days = math.floor(hours / 24);
        local formattedTime = '';

        if days > 0 then
            formattedTime = formattedTime .. days .. 'd ';
            hours = hours % 24;
        end;

        if hours > 0 then
            formattedTime = formattedTime .. hours .. 'h ';
            minutes = minutes % 60;
        end;

        if minutes > 0 then
            formattedTime = formattedTime .. minutes .. 'm';
            seconds = seconds % 60;
        end;

        return formattedTime;
    end;

    local function convertTime(dateTime)
        return os.time({year=dateTime.Year,month=dateTime.Month,day=dateTime.Day,hour=dateTime.Hour,min=dateTime.Minute,sec=dateTime.Second})
    end;

    for name, lastSpawned in next, triggeredLocations do
        local label = Misc:AddLabel('');

        local function onLastSpawnedChanged()
            if (lastSpawned.Value == 0) then
                label.Text = string.format('%s - Never taken', name);
                return;
            end;

            local lastSpawnedLocal = DateTime.fromUnixTimestamp(lastSpawned.Value):ToLocalTime()
            local currentTime = DateTime.now():ToLocalTime()

            local diff = os.difftime(convertTime(currentTime),convertTime(lastSpawnedLocal))
            label.Text = string.format('%s - %s ago', name, formatTime(diff));
        end;

        library.OnLoad:Connect(function()
            lastSpawned:GetPropertyChangedSignal('Value'):Connect(onLastSpawnedChanged);

            task.spawn(function()
                while true do
                    onLastSpawnedChanged();
                    task.wait(60);
                end;
            end);
        end);
    end;
end;

Misc:AddSlider({text = 'Climb Speed', min = 1, max = 10, textpos = 2});

Misc:AddBox({text = 'Spectate Player', callback = spectatePlayer});

Misc:AddToggle({text = 'Inf Mana (Client Side)', callback = infMana});
Misc:AddToggle({text = 'Use Alt Manager To Block'});
Misc:AddToggle({text = 'Max Zoom', callback = maxZoom});
Misc:AddToggle({text = 'Streamer Mode', callback = streamerMode});

Misc:AddBind({text = 'Click Destroy', callback = clickDestroy});
Misc:AddBind({text = 'Instant Log', nomouse = true, key = Enum.KeyCode.Plus, callback = instantLog});
Misc:AddBind({text = 'Go To Ground', callback = goToGround, mode = 'hold'})
Misc:AddToggle({text = 'Pull To Ground', callback = pullToGround, tip = 'Will pull you to the ground if you fly'})

Spell:AddToggle({text = 'Anti Backfire'});
Spell:AddToggle({text = 'Spell Adjust', callback = toggleSpellAdjust})
Spell:AddToggle({text = 'Auto Cast', callback = toggleSpellAutoCast})

for i, v in next, spellValues do
    if(v[2]) then
        Spell:AddToggle({
            text = i .. ' - Use Snap',
            flag = i .. ' Use Snap',
            state = true
        });
    end;
end;

if(isGaia) then
    Bots:AddToggle({text = 'Scroom Bot', callback = scroomBot});
    Bots:AddToggle({text = 'Scroom Bot Grip Mode'});
    Bots:AddList({flag = 'Scroom Bot Target Player', playerOnly = true});

    Bots:AddToggle({text = 'Gacha Bot', callback = gachaBot});
    Bots:AddToggle({text = 'Blacksmith Bot', callback = blackSmithBot});
    Bots:AddToggle({text = 'Auto Sell', flag = 'Blacksmith Bot Auto Sell'});
else
    Bots:AddToggle({text = 'Show Pickup Order UI', callback = showCollectorPickupUI});
    Bots:AddToggle({text = 'Roll Out Of FF'});
    Bots:AddToggle({text = 'Collector Auto Farm', callback = collectorAutoFarm});
    Bots:AddSlider({text = 'Collector Bot Wait Time', value = 12, min = 8, max = 60});

    Bots:AddBox({text = 'Webhook Url'});
end;

Bots:AddToggle({text = 'Automatically Rejoin', state = true});
Bots:AddToggle({text = 'Skip Illusionist Server'});
Bots:AddDivider('Custom Bots');

Bots:AddToggle({text = 'Dont Pickup Phoenix Down'});
Bots:AddToggle({text = 'Dont Pickup Scrolls'});

Bots:AddSlider({value = 200, min = 100, max = 1000, textpos = 2, text = 'Player Range Check'});

Bots:AddButton({text = 'Add Point', callback = addPoint});
Bots:AddButton({text = 'Clear Points', callback = clearPointsPrompt});
Bots:AddButton({text = 'Remove Last Point', callback = removeLastPoint});
Bots:AddButton({text = 'Preview Bot', callback = previewBot})
Bots:AddButton({text = 'Cancel Preview', callback = cancelPreview})
Bots:AddButton({text = 'Save Bot', callback = saveBot});
Bots:AddButton({text = 'Load Bot', callback = loadBot});
Bots:AddButton({text = 'Start Bot', callback = startBotPrompt});

Bots:AddBox({text = 'File Name'});
Bots:AddDivider('Custom Bots Settings');