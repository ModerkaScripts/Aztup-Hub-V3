local Maid = sharedRequire('../utils/Maid.lua');
local library = sharedRequire('../UILibrary.lua');
local ToastNotif = sharedRequire('../classes/ToastNotif.lua');
local Utility = sharedRequire('../utils/Utility.lua');
local EntityESP = sharedRequire('../classes/EntityESP.lua');
local createBaseESP = sharedRequire('../utils/createBaseESP.lua');
local Services = sharedRequire('../utils/Services.lua');
local Textlogger = sharedRequire('@classes/TextLogger.lua');
local audioPlayer = sharedRequire('@utils/AudioPlayer.lua');
local makeESP = sharedRequire('@utils/makeESP.lua');

local column1, column2 = unpack(library.columns);


local ReplicatedStorage, Players, RunService, Lighting, UserInputService, VirtualInputManager, TeleportService, PathfindingService, MarketPlaceService, guiService = Services:Get(
	'ReplicatedStorage',
	'Players',
	'RunService',
	'Lighting',
	'UserInputService',
	'VirtualInputManager',
	'TeleportService',
    'PathfindingService',
    'MarketplaceService',
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

local plr = Players.LocalPlayer;
local plrGUI = plr.PlayerGui;
local char = plr.Character;
local mouse = plr:GetMouse()
local camera = workspace.CurrentCamera;
local LivingThings;
local tryingToSleep = false;
local doingAction = false;
local modNotifier = audioPlayer.new({
    soundId = 'rbxassetid://5608799630',
    volume = 10,
    forcedAudio = 10,
    looped = true
});


--function inits
local isA = game.IsA;
local ffc = game.FindFirstChild;
local ffcwia = game.FindFirstChildWhichIsA;
local kick = game.Players.LocalPlayer.Kick;

plr.CharacterAdded:Connect(function()
    char = plr.Character;
end);

plr.ChildAdded:Connect(function(v)
    if v.Name ~= "PlayerGui" then return; end

    plrGUI = v;
end)

local modroles = {
    ["MainChar"] = true;
    ["Mod"] = true;
    ["Trial Mod"] = true;
    ["Associates."] = true;
    ["Owner"] = true;
};

local plrTbl = {};
local function checkIfMod(v)
    local role;
    pcall(function()
        role = v:GetRoleInGroup(4800422);
    end);

    plrTbl[string.lower(v.Name)] = v;

    if not library.flags.modNotifier or not role or not modroles[role] then return; end
    if library.flags.autoPanic then library:Unload(); end

    if library.flags.autoLeave then
        if char then char:Destroy(); end
        task.delay(10,kick,plr,'Mod joined your server');
    end

    modNotifier:Play();

    local notif = ToastNotif.new({
        text = "There is a mod in your server: "..v.Name;
    });

    notif.Destroying:Connect(function()
        modNotifier:Stop();
    end)
end

Players.PlayerAdded:Connect(checkIfMod);

Players.PlayerRemoving:Connect(function(v)
    plrTbl[string.lower(v.Name)] = nil;
end);

--Non exploit functions

local function parseKey(str)
    return Utility.find({str:byte(1,9999)}, function(v) return v > 128 end);
end

local function getKey(script)
    if not script:IsA("LocalScript") then error("Expected a localscript got "..script.ClassName) end
    local key;

    local ran,env = pcall(getsenv,script);
    if not ran then return; end

    for _,v in next, env do
        if typeof(v) ~= 'function' then continue; end

        for _,k in next, getupvalues(v) do
            if typeof(k) ~= 'string' or not parseKey(k) then continue; end

            key = k;
            break;
        end
    end

    if key then return key; end

    for _,v in next, script.Parent:GetDescendants() do
        local con = string.match(v.ClassName,"Button") and getconnections(v.MouseButton1Click)[1] or getconnections(v.Changed)[1];
        if not con or not con.Function then continue; end

        for _,k in next, getupvalues(con.Function) do
            if typeof(k) ~= 'string' or not parseKey(k) then continue; end

            key = k;
            break;
        end

        if key then break; end
    end
    return key;
end

getgenv().getKey = getKey;

local function round(n, decimals)
	decimals = decimals or 0
	return math.floor(n * 10^decimals) / 10^decimals
end
local function loaded()
    if not char then
        return false;
	elseif not ffc(char,"HumanoidRootPart") then
        return false;
    elseif not ffc(char,"Humanoid") then
        return false;
	elseif not ffc(char,"DB") then
        return false;
    end
    return true;
end

local function safeClick(part) --Part should have a vector3 and contain ClickDetector

    if not library.flags.useMouseClick then fireclickdetector(part.Parent:FindFirstChildWhichIsA("ClickDetector")); return; end
    if (char.HumanoidRootPart.Position-part.Position).Magnitude <= 10 then
        local posOnC = workspace.Camera:WorldToScreenPoint(part.Position);
        local inset = guiService:GetGuiInset();
        local center = {
            x = (posOnC.X+inset.X)+(part.Size.X/2);
            y = (posOnC.Y+inset.Y)+(part.Size.Y/2);
        }
        VirtualInputManager:SendMouseMoveEvent(center.x,center.y,game);
        task.wait(0.1);
        VirtualInputManager:SendMouseButtonEvent(center.x,center.y,0,true,game,0);
        task.wait(0.1);
        VirtualInputManager:SendMouseButtonEvent(center.x,center.y,0,false,game,0);
    end
end

local function safeButton(button)
    local size = button.AbsoluteSize;
    local pos = button.AbsolutePosition;
    local inset = guiService:GetGuiInset();
    local center = {
        x = (pos.X+inset.X)+(size.X/2);
        y = (pos.Y+inset.Y)+(size.Y/2);
    }
    VirtualInputManager:SendMouseButtonEvent(center.x,center.y,0,true,game,0);
    task.wait(0.1);
    VirtualInputManager:SendMouseButtonEvent(center.x,center.y,0,false,game,0);
end
--[[For synv3 update

local execmenu = false;
if ffc(plr,"PlayerGui") and ffc(plrGUI,"LoadMenu") then
    local result = filtergc('function',{IgnoreSyn=true,Constants={0.2,"LoadStats"}},true);
    setconstant(v,43,100);
    execmenu = true;
end
--]]

--Execute in menu
local execmenu = false;
if ffc(plr,"PlayerGui") and ffc(plrGUI,"LoadMenu") then
    local env = plr.PlayerGui.LoadMenu.LocalScript;
    for i,v in next, getgc() do
        if typeof(v) == 'function' and rawget(getfenv(v),"script") == env then
            for t,k in next, getconstants(v) do
                if k == 0.2 then
                    setconstant(v,t,100);
                end
            end
        end
    end

    execmenu = true;
end
repeat task.wait() until char;
repeat task.wait() until ffc(plr,"Backpack");
repeat task.wait() until ffc(plr.Backpack,"LocalS");
--Inits
local foodTool,lastFood;
local hungerBar;
local calorieBar;
local staminaBar;
local fatigueNum;
local utility;
local visualFrame;
local beds = {};

--Toggle inits
local eating = false;
local sprinting = false;

--[[Use this to update hash
    local plr = game.Players.LocalPlayer;
    local closure = (plr.Backpack.LocalS);
    setclipboard(getscripthash(closure));
]]

repeat task.wait() until ffcwia(plr.Backpack,"Tool");
if execmenu then
    task.wait(2);
end

--[[ For synv3 update
local result = filtergc('function',{IgnoreSyn=true,Constants={"F1ySuspicion"}},true);

local banR_Name = getconstant(result,table.find(getconstants(result),"F1ySuspicion")-1);
local key = getupvalue(result,21);
local parent = getupvalue(result,20);
local banRemote = ffc(parent,banR_Name);

if not typeof(key) == 'string' then plr:Kick("Key was incorrect"); end
if not banRemote then plr:Kick("Failed to grab the ban remote"); end


]]

local banRemote;
local remoteKey;

local function initGC()
    for _, v in next, getgc() do
        if (typeof(v) == 'function' and islclosure(v) and not is_synapse_function(v) and table.find(getconstants(v), 'F1ySuspicion')) then
            banRemote = getconstant(v, table.find(getconstants(v), 'F1ySuspicion') - 1);

            for _, uv in next, getupvalues(v) do
                if (typeof(uv) == 'string') then
                    remoteKey = uv;
                end;
            end;

            if getupvalue(v,20) and ffc(getupvalue(v,20),banRemote) then
                banRemote = ffc(getupvalue(v,20),banRemote);
                return true;
            else
                return plr:Kick('Failed to grab ban remote');
            end;
        end;
    end;
end;

print('waiting for gc scan.');
repeat task.wait(); until initGC();

if not banRemote or not remoteKey then
    plr:Kick('Kicked you to protect your account something, in the game has changed.');
    return;
end

if (banRemote.Name ~= 'Detector') then
    plr:Kick('Kicked you to protect your account something, in the game has changed.');
    return;
end

local oldNamecall;
oldNamecall = hookmetamethod(game, "__namecall",function(self, ...)
    SX_VM_CNONE();

    local ncMethod = getnamecallmethod();
    if self == banRemote and ncMethod == "FireServer" or self == banRemote and ncMethod == "fireServer" then
        return;
    end;

    if library.flags.infRhythm then

        if ncMethod == 'Stop' or ncMethod == 'Play' then
            local remote = ffc(plr,"Action",true);
            if (not remote) then return oldNamecall(self, ...); end;

            local connection = getconnections(remote.OnClientEvent)[1];
            if (not connection) then return oldNamecall(self, ...); end;

            local actionCon = getupvalues(connection.Function);

            local toolInfo = actionCon[13];
            if toolInfo and toolInfo.Stance and self == toolInfo.Stance then
                toolInfo.Priority = (ncMethod == 'Stop') and 1000 or 1;
                return;
            end
        end

        local args = {...};
        if args[2] == "RhythmStance" and args[3] == false then return; end
    end

    return oldNamecall(self,...);
end);

local oldFireServer;
oldFireServer = hookfunction(Instance.new("RemoteEvent").FireServer,function(self, ...)
    SX_VM_CNONE();

    if self == banRemote then
        return;
    end;

    return oldFireServer(self,...);
end);

--Setting values probably will use a promise for this later!!

local function grabUIObjects()
    pcall(function()
        if (plrGUI:FindFirstChild('MainGui') and plrGUI.MainGui:FindFirstChild('Utility')) then
            utility = plrGUI.MainGui.Utility;
            hungerBar = utility.StomachBar.BarF.Bar;
            calorieBar = utility.StomachBar.Calories.Bar;
            staminaBar = utility.StamBar.BarF.Bar;
            fatigueNum = utility.BodyFatigue;
            visualFrame = utility.VisualFrame;
        end
    end);
end;

grabUIObjects();

local Stats = setmetatable({},{ --Creates a metatable that returns values in %
    __index = function(t,k)
        if not hungerBar or hungerBar.Parent == nil then
            grabUIObjects();
        end;

        if k == "Hunger" then
            if hungerBar then
                return hungerBar.Size.X.Scale*100;
            end
        elseif k == "Calories" then
            if calorieBar then
                return calorieBar.Size.X.Scale*100;
            end
        elseif k == "Stamina" then
            if staminaBar then
                return staminaBar.Size.X.Scale*100;
            end
        elseif k == "Fatigue" then
            if fatigueNum then
                return tonumber(string.match(fatigueNum.Text,"[%d%.]+"));
            end
        elseif k == "isEating" then
            if ffc(char,"DB") then
                return char.DB.Value;
            end
        elseif k == "Rhythm" then
            if ffc(char,"Rhythm") then
                return char.Rhythm.Value;
            end
        elseif k == "isKnocked" then
            if ffc(char,"Ragdolled") then
                return char.Ragdolled.Value;
            end
        elseif k == "Sleeping" then
            if not loaded() then return false; end

            for i,v in next, char.HumanoidRootPart:GetConnectedParts() do
                if v.Name == "Matress" then
                    return true;
                end
            end
            return false;
        elseif k == "isRunning" then
            if not loaded() then return false; end

            local foundAnim = false;
            for i,v in next, char.Humanoid.Animator:GetPlayingAnimationTracks() do
                local curId = v.Animation.AnimationId;
                if curId == "rbxassetid://5087736730" or curId == "rbxassetid://4889489948" then
                    foundAnim = true;
                end
            end
            return foundAnim;
        elseif k == "isSquatting" then
            if not loaded() then return false; end

            local foundAnim = false;
            for i,v in next, char.Humanoid.Animator:GetPlayingAnimationTracks() do
                local curId = v.Animation.AnimationId;
                if curId == "rbxassetid://4934239228" then
                    foundAnim = true;
                end
            end
            return foundAnim;
        elseif k == "isPushuping" then
            if not loaded() then return false; end

            local foundAnim = false;
            for i,v in next, char.Humanoid.Animator:GetPlayingAnimationTracks() do
                local curId = v.Animation.AnimationId;
                if curId == "rbxassetid://4931281501" then
                    foundAnim = true;
                end
            end
            return foundAnim;
        elseif k == "ProteinShake" then
            if visualFrame then
                return ffc(visualFrame,"Protein Shake");
            end
        elseif k == "BCAA" then
            if visualFrame then
                return ffc(visualFrame,"BCAA");
            end
        elseif k == "FatBurner" then
            if visualFrame then
                return ffc(visualFrame,"Fat Burner");
            end
        elseif k == "Scalar" then
            if visualFrame then
                return ffc(visualFrame,"Scalar");
            end
        end
    end
});
getfenv().Stats = Stats; --Sets to script env

local env = getsenv(plr.Backpack.LocalS)

--Gets all the beds on the map
for i,v in next, workspace:GetDescendants() do
    if isA(v,"ClickDetector") and v.Parent.Name == "Bed" and ffc(v.Parent,"Blanket") then
        table.insert(beds,v.Parent);
    end
end
--Get closest bed returns bed model that is closest to you.
local function closestBed()
    if not loaded() then return; end
    local last = 15; --Must be within 15 studs to click a bed aka ontop of it
    local closest;
    for i = 1,#beds do
        if ffc(beds[i],"Matress") and (beds[i].Matress.Position - char.HumanoidRootPart.Position).magnitude < last then
            closest = beds[i];
            last = (closest.Matress.Position - char.HumanoidRootPart.Position).magnitude;
        end
    end
    return closest;
end

--Get food tool
local function getFood(foodName)
    if not foodName then foodName = ""; end
    if not loaded() then return; end

    local food;
    if foodName ~= "" then
        food = ffc(plr.Backpack,foodName) or ffc(char,foodName);
    else
        food = ffc(plr.Backpack,"FoodScript",true) or ffc(char,"FoodScript",true);
    end

    if not food then return; end
    if isA(food,"Tool") then
        return {food, food.Name};
    else
        return {food.Parent, food.Parent.Name};
    end
end

local function isBusy()
    if library.flags.autoEat and Stats.Hunger <= library.flags["autoEatAt%"] then
        repeat task.wait(); until Stats.Hunger >= library.flags["eatTo%"] or (not library.flags.legitAutoMachine and not library.flags.riskyAutoMachine and not library.flags.autoDura)
    end
    if library.flags.autoProtein and getFood('Protein Shake') then
        repeat task.wait(); until Stats.ProteinShake or (not library.flags.legitAutoMachine and not library.flags.riskyAutoMachine and not library.flags.autoDura)
    end

    if library.flags.autoBcaa and getFood('BCAA') then
        repeat task.wait(); until Stats.BCAA or (not library.flags.legitAutoMachine and not library.flags.riskyAutoMachine and not library.flags.autoDura)
    end

    if library.flags.autoFatBurner and getFood('Fat Burner') then
        repeat task.wait(); until Stats.FatBurner or (not library.flags.legitAutoMachine and not library.flags.riskyAutoMachine and not library.flags.autoDura)
    end

    if library.flags.autoScalar and getFood('Scalar') then
        repeat task.wait(); until Stats.Scalar or (not library.flags.legitAutoMachine and not library.flags.riskyAutoMachine and not library.flags.autoDura)
    end
    return;
end

--Get tool by Name
local function getToolByName(toolName)
    if not loaded() then return; end

    return ffc(plr.Backpack,toolName) or ffc(char,toolName);
end

--Get fight tool
local function getStyle()
    if not loaded() then return; end
    if not ffc(plr,"Backpack") then return; end
    if ffc(plr.Backpack,"Style",true) then
        return ffc(plr.Backpack,"Style",true).Parent;
    elseif ffc(char,"Style",true) then
        return ffc(char,"Style",true).Parent;
    end
    return nil
end

--toggleSleep function that sleeps on bed and unsleep if in bed.
local function toggleSleep()
    if not loaded() then return; end

    local bed = closestBed();
    if not bed then return; end

    if not Stats.Sleeping then
        tryingToSleep = true;
        repeat
            task.wait(0.2);
            char.Humanoid:UnequipTools();
            safeClick(bed.Matress);
        until Stats.Sleeping or not library.flags.autoSleep;
        tryingToSleep = false;

    elseif Stats.Sleeping and bed then
        char.Humanoid:UnequipTools();
        safeClick(bed.Matress);
        task.wait(0.5);
        for i,v in next, char:GetChildren() do
            if v.Name == "Safe" then
                v:Destroy();
            end
        end

    end
end
local trainButtons = {
    ["Strike"] = {};
    ["Dura"] = {};
    ["Road"] = {};
};
local BadModels = {};
--Puts all the buttons in appropriate tables
for i,v in next, workspace:GetDescendants() do
    if v.Name == "Weight2" and v.Parent.Name == "Model" and not BadModels[v.Parent] then
        BadModels[v.Parent] = true;
    end
    if v.Name == "Roadwork: $40" then
        table.insert(trainButtons["Road"],v);
    elseif v.Name == "Strike Speed Training: $45" then
        table.insert(trainButtons["Strike"],v);
    elseif v.Name == "Durability Training: $40" then
        table.insert(trainButtons["Dura"],v);
    end
end

--Simple table search function
local function search(tbl,str)
    for t,k in next, tbl do
        if string.match(t,str) then
            return k;
        end
    end
    return nil;
end

--Gives closest button in specified range
local function getButton(Type,Range)
    if not loaded() then return; end
    local closest;
    for i,v in next, trainButtons[Type] do
        if (v.Head.Position-char.HumanoidRootPart.Position).magnitude < Range then
            Range = (v.Head.Position-char.HumanoidRootPart.Position).magnitude;
            closest = v;
        end
    end
    return closest;
end

local punchingBags = {};
for i,v in next, workspace:GetDescendants() do
    if v.Name == "PunchingBag" then
        table.insert(punchingBags,v.bag);
    end
end

local function getBag()
    if not loaded() then return; end
    local closest;
    for i,v in next, punchingBags do
        if ((v.Position * Vector3.new(1, 0, 1))-(char.HumanoidRootPart.Position*Vector3.new(1,0,1))).magnitude < 6.5 then
            closest = v;
            break;
        end
    end
    return closest;
end

local function getPlayerInRange(ignoredCharacter,targetPos,range)
    local inRange;
    for i,v in next, LivingThings:GetChildren() do
        if v == ignoredCharacter then continue; end
        if not (ffc(v,"HumanoidRootPart")) then continue; end
        if (v.HumanoidRootPart.Position-targetPos).magnitude >= range then continue; end
        inRange = v;
        break;
    end

    return inRange;
end

local function getMobInRange(range)
    local inRange;
    local closest = range;
    for i,v in next, LivingThings:GetChildren() do
        if v == char then continue; end
        if ffc(Players,v.Name) then continue; end
        if not (ffc(v,"HumanoidRootPart")) or not ffc(char,"HumanoidRootPart") then continue; end
        if (v.HumanoidRootPart.Position-char.HumanoidRootPart.Position).magnitude >= closest then continue; end
        inRange = v;
        closest = (v.HumanoidRootPart.Position-char.HumanoidRootPart.Position).magnitude;
        break;
    end

    return inRange;
end

--Legit move to function uses pathfind
local function legitMove(Position)
    if not loaded() then return; end
    local path = PathfindingService:CreatePath();
    path:ComputeAsync(char.HumanoidRootPart.Position, Position);
    local waypoints = path:GetWaypoints();
    for _, waypoint in pairs(waypoints) do
    	char.Humanoid:MoveTo(waypoint.Position);
    	char.Humanoid.MoveToFinished:Wait();
    end
end

local Foods = {
    ["BCAA: $75"] = 75;
    ["Fat Burner: $70"] = 70;
    ["Protein Shake: $60"] = 60;
    ["Ramen: $55"] = 55;
    ["Hamburger: $55"] = 55;
    ["Tofu Beef Soup: $45"] = 45;
    ["Pancakes: $35"] = 35;
    ["Pie: $35"] = 35;
    ["Donut: $35"] = 35;
    ["EZ Taco: $25"] = 25;
    ["Hotdog: $25"] = 25;
    ["Chicken Fries: $20"] = 20;
    ["Omelette: $20"] = 20;
}
local foodButtons = {};
for i,v in next, workspace:GetDescendants() do
    if Foods[v.Name] then
        table.insert(foodButtons,v);
    end
end

local Teleports = {
    ["Protein CEO Bed"] = Vector3.new(-287.970764, 65.4588547, -256.528046);
    ["Gym CEO Bed"] = Vector3.new(-605.105347, 72.4071121, -158.616302);
    ["HOMRA CEO Bed"] = Vector3.new(-426, 84, -141);
    ["Bank CEO Bed1"] = Vector3.new(-429.838226, 139.137741, -521.047363);
    ["Bank CEO Bed2"] = Vector3.new(-400.048737, 138.245346, -519.46936);
    ["Space BunkBed"] = Vector3.new(-293.323395, 50.5205154, -522.796326);
    ["Mart CEO Bed"] = Vector3.new(-326.314911, 51.4444199, -514.276367);
    ["Boxing CEO Bed"] = Vector3.new(845.754395, 50.2253838, -102.881683);
    ["Ramen CEO Bed"] = Vector3.new(-1172.79968, 49.8107491, -309.082245);
    ["PRIME CEO Bed"] = Vector3.new(-1127.57178, 13.5423203, -829.319519);
    ["Police CEO Bed"] = Vector3.new(-791.490967, 49.4704971, 36.7121468);
    ["AOKI Gym"] = Vector3.new(-423.82809448242, -8.1605911254883, -492.89834594727);
}

--Auto Dura OOP


local autoDura = {};
autoDura.__index = autoDura;

local autoDuraTab = {};
function autoDura.new(firstTurn,secondTurn)

	local self = setmetatable({},autoDura);
    table.insert(autoDuraTab, self);

	self._maid = Maid.new();

	self._firstChar = firstTurn;
	self._secondChar = secondTurn;

	self._combatStyle = getStyle();
	self._duraTool = getToolByName("Durability Training");
	self._duraButton = getButton("Dura",999);
	self._lastRefresh = tick();


	self._stopPunching = true;
    self._firstDebounce = false;
    self._secondDebounce = false;

	self._maid:GiveTask(self._firstChar.ChildAdded:Connect(function(v) --Tells us if first turn is using dura
		if v.Name ~= "DuraTrain" then return; end

        self._duraVal = v;
		self._lastTurn = self._firstChar;
	end))

	self._maid:GiveTask(self._secondChar.ChildAdded:Connect(function(v) --Tells us if second turn is using dura
		if v.Name ~= "DuraTrain" then return; end

        self._duraVal = v;
		self._lastTurn = self._secondChar;
	end))

	self._maid:GiveTask(self._firstChar.Humanoid.HealthChanged:Connect(function(health) --When the first turn gets too low
		if (health/self._firstChar.Humanoid.MaxHealth*100) >= library.flags["minimumHp%"] then return; end
        if self._firstDebounce then return; end

		self._stopPunching = true; --Stop punching if the first turn is too low
        self._firstDebounce = true;

		self:Unpop();
		self:Pop();

        repeat task.wait() until self._firstChar.Humanoid.Health >= self._firstChar.Humanoid.MaxHealth or not self._firstChar.Parent;

        if self._lastTurn ~= char then self._stopPunching = false; doingAction = true; end
        warn(debug.traceback(),'true')


        self._firstDebounce = false;
	end))

	self._maid:GiveTask(self._secondChar.Humanoid.HealthChanged:Connect(function(health) --When the second turn gets too low
		if (health/self._secondChar.Humanoid.MaxHealth*100) >= library.flags["minimumHp%"] then return; end
        if self._secondDebounce then return; end

		self._stopPunching = true; --Stop punching if the second turn is too low
        self._secondDebounce = true;

		self:Unpop();
		self:Pop();

        repeat task.wait() until self._secondChar.Humanoid.Health >= self._secondChar.Humanoid.MaxHealth or not self._secondChar.Parent;

        if self._lastTurn ~= char then self._stopPunching = false; doingAction = true; end
        warn(debug.traceback(),'true')


        self._secondDebounce = false;
	end))

	self._maid:GiveTask(RunService.RenderStepped:Connect(function()
		if tick()-self._lastRefresh <= 0.1 then return; end
		self._lastRefresh = tick();

		if self._stopPunching then return; end
        if not self._duraVal or not self._duraVal.Parent then return; end
		if not self._lastTurn or self._lastTurn == char then return; end --Only start punching when they have actually popped dura
		if self._combatStyle.Parent ~= char then char.Humanoid:UnequipTools(); self._combatStyle.Parent = char; return; end

		self._combatStyle:Activate();
	end))

    return self;
end

function autoDura:Unpop()
	if self._lastTurn ~= char then return; end

	if self._duraTool.Parent then --If the tool was removed then was unpopped
        self._duraTool.Parent = char;
        task.wait(0.7); --Make sure they stopped punching before unpopping

        self._duraTool:Activate();
        task.wait();
    end

    repeat task.wait() until not getToolByName("Durability Training")

    self:BuyDura();
    if not library.flags.takeTurns then return; end --If take turns is not enabled then don't start punching
	self._stopPunching = false; --Start trying to punch when lastTurn changes
    doingAction = true;
    warn(debug.traceback(),'true')

end


function autoDura:BuyDura()
	if not self._duraButton then self:CreateError("Stand closer to a durability training button"); return; end
	if getToolByName("Durability Training") then return; end

	char.Humanoid:UnequipTools();
	task.wait(0.1);

    while task.wait(0.2) do
        if getToolByName("Durability Training") then break; end
        print("BUYING IT PLEASE")
        safeClick(self._duraButton.Head);
    end

	self._duraTool = getToolByName("Durability Training");
    warn(self._duraTool)
	task.wait();

    doingAction = false;
    warn("SET DOING ACTION TO FALSE???",doingAction,self._stopPunching)
    isBusy(); --Wait until not waiting to eat
    doingAction = true;
    warn(debug.traceback(),'true')
end

function autoDura:Pop()
	if self._lastTurn and self._lastTurn == char and library.flags.takeTurns then return; end --If it was our turn last and take turns is on then don't pop
    if self._lastTurn and self._lastTurn ~= char and not library.flags.takeTurns then return; end --If it wasn't our turn last and take turns isn't on then don't pop
	if not self._duraTool or not self._duraTool.Parent then self:BuyDura(); end --Try to buy the tool

    if not self._duraTool or not self._duraTool.Parent then return; end --If still no tool then return


    char.Humanoid:UnequipTools();

    task.wait(0.1);

	self._duraTool.Parent = char;

	repeat task.wait(0.1); until char.Humanoid.Health >= char.Humanoid.MaxHealth --Wait till full health to pop
    repeat task.wait(0.1); until not Stats.isEating;

    self._duraTool.Parent = char;

    doingAction = true;
    task.wait(0.1);

	self._duraTool:Activate();
end

function autoDura:Start()
	if self._firstChar == char then
		self:BuyDura();
		self:Pop();
        return;
    end
    self._stopPunching = false;
    warn(debug.traceback(),'true')
    doingAction = true;
end

function autoDura:Destroy()
	self._maid:DoCleaning();
	for i,v in next, autoDuraTab do
		if v == self then
			autoDuraTab[i] = nil;
		end
	end
end

function autoDura:ClearAll()
    doingAction = false;
	for _,v in next, autoDuraTab do
        v:Destroy();
    end
end

function autoDura:CreateError(msg)
    ToastNotif.new({
        text = msg;
        duration = 20
    });
end

local streetESP = createBaseESP('streetFighters');
local behelitESP = createBaseESP('behelit');

local gMaid = Maid.new();

do --Entity esp overwrite
    local playerInfoTab = {};
    local playerInfo = {};
    playerInfo.__index = playerInfo;

    function playerInfo.new(player,combatStyle)
        local self = setmetatable({},playerInfo);
        playerInfoTab[player] = self;

        self._player = player;
        self._char = player.Character;
        self._humanoid = self._char.Humanoid;
        self._combatStyle = tostring(combatStyle);
        self._currentStam = self._char.CurrentStamina.Value/self._char.MaxStamina.Value*100;
        self._maid = Maid.new();

        self._maid:GiveTask(self._char.CurrentStamina:GetPropertyChangedSignal("Value"):Connect(function()
            self._currentStam = self._char.CurrentStamina.Value/self._char.MaxStamina.Value*100;
        end))

        self._maid:GiveTask(self._humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            self._health = self._humanoid.Health;
        end))

        self._maid:GiveTask(self._humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(function()
            self._maxHealth = self._humanoid.MaxHealth;
        end))

        self._maid:GiveTask(self._char.Destroying:Connect(function()
            self:Destroy();
        end))

        self._maid:GiveTask(self._char.AncestryChanged:Connect(function(part,newParent)
            if newParent ~= nil then return; end
            self:Destroy();
        end))
        return self;
    end

    function playerInfo:Destroy()
        self._maid:DoCleaning();
        for i,v in next, playerInfoTab do
            if v == self then
                playerInfoTab[i] = nil;
            end
        end
    end

    local function onCharacterAdded(player) --Normally this should be a character but we pass a player..
        if not player.Character:WaitForChild("CurrentStamina",10) then return; end
        local Style = (ffc(player.Backpack,"Style",true) or ffc(player.Character,"Style",true));

        if not Style then
            for i = 1,10 do
                task.wait(1);
                Style = (ffc(player.Backpack,"Style",true) or ffc(player.Character,"Style",true));
                if Style then break; end
            end
            if not Style then return; end
        end
        playerInfo.new(player,Style.Parent);
    end

    local function onPlayerAdded(player) --Kinda skidded from u nya
        if (player == plr) then return end;

        player.CharacterAdded:Connect(function()
            onCharacterAdded(player);
        end);

        if not (player.Character) then return; end

        task.spawn(onCharacterAdded, player);
    end;

    library.OnLoad:Connect(function()
		Utility.listenToChildAdded(Players, onPlayerAdded);
	end);

	local function onNewMobAdded(mob, espConstructor)
        if ffc(Players,mob.Name) then return; end;
        if not mob:WaitForChild("HumanoidRootPart",5) then return; end
		local pseudoMob = mob.HumanoidRootPart;

		local mobEsp = espConstructor.new(pseudoMob, mob.Name);

		local connection;
		connection = mob.AncestryChanged:Connect(function()
			if mob:IsDescendantOf(game) then return; end

			connection:Disconnect();
			mobEsp:Destroy();
		end);
	end;

    function EntityESP:Plugin()
        local plrInfo = playerInfoTab[self._player];
        if not plrInfo then return {}; end

        local text = '\n';
		local style, stamina = plrInfo._combatStyle, plrInfo._currentStam;
        if library.flags.showStyle then
            text = text..string.format('[Style: %s] ', style)
        end
        if library.flags.showStamina then
            text = text..string.format('[Stamina: %d]', stamina)
        end
		return {
			text = text
		}
	end;

    function Utility:renderOverload(data)
        local espSettings = data.espSettings;

        espSettings:AddToggle({text='Show Stamina'});
        espSettings:AddToggle({text='Show Style'});

        local sfESP = data.column2:AddSection("Street Fighter ESP");

        local function updateEsp(t)
            if (not t) then
                gMaid.streetFightersESP = nil;
                streetESP:UnloadAll();
                return;
            end;

            gMaid.streetFightersESP = RunService.Stepped:Connect(function()
                streetESP:UpdateAll();
            end);
        end;

        sfESP:AddToggle({
            text = "Street Fighters",
            callback = updateEsp
        });

        local bhESP = data.column2:AddSection("Behelit ESP");

        local function updateEspBehelit(t)
            if (not t) then
                gMaid.behelitESP = nil;
                behelitESP:UnloadAll();
                return;
            end;

            gMaid.behelitESP = RunService.Stepped:Connect(function()
                behelitESP:UpdateAll();
            end);
        end;

        bhESP:AddToggle({
            text = "Behelit",
            callback = updateEspBehelit
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
    end
end

local riskyTab = library:AddTab("MO (Risky)");
local riskyColumn1 = riskyTab:AddColumn();
local riskyColumn2 = riskyTab:AddColumn();
local risky = riskyColumn1:AddSection("Risky");

local Safe = column1:AddSection("Safe");
local StatV = column1:AddSection("Stat Viewer");
local Misc = column1:AddSection("Misc");

local a= (function()
local updateStat;
local autoTrain;
local stupidWait = false;
local staminaP = 0;
local flySpeed = 50;
local trainMove = "Push up";
local Events = ReplicatedStorage.Events;
local StatT = {};
local flingMaid = Maid.new();
local teleMaid = Maid.new();
local flyMaid = Maid.new();
local strikeMaid = Maid.new();
local legitMachineMaid = Maid.new();
LivingThings = ffc(workspace,"Live") or Instance.new("Model");



--Check if they accidentally pressed w or something stupid
local stopOld = env.stopSprint;
local runOld = env.runPrompt;

env.runPrompt = function()
    if (library.flags.autoPunch and library.flags.autoRhythm and Stats.Rhythm < 100) then --Won't run until fully charged rhythm
        return;
    end
    local remote = plr:FindFirstChild("Action",true);
    if remote then
        print("Found remote")
        local actionCon = getupvalues(getconnections(remote.OnClientEvent)[1].Function);

        local toolInfo = actionCon[13];
        print(toolInfo)
        if toolInfo and toolInfo.Stance.IsPlaying then
            print("Told it to stop playing..")
            toolInfo.Stance:Stop();
        end
    end
    sprinting = true;
    return runOld();
end

env.stopSprint = function()
    sprinting = false;
    return stopOld();
end

--Spectate Function
local curSpectate;
local oldObject;
local function spectatefunc(Object)
    if curSpectate == Object.Name then --Unspectate player
        curSpectate = "";
        Object.User.Txt.TextColor3 = Color3.new(255,255,255);
        camera.CameraSubject = char.Humanoid;
        return;
    end

    if not ffc(LivingThings,Object.Name) then return; end --If they dont have a player model

    if oldObject and oldObject.Parent then
        oldObject.User.Txt.TextColor3 = Color3.new(255,255,255); --Reset the color when they spectate someone new
    end

    oldObject = Object;
    curSpectate = Object.Name;

    Object.User.Txt.TextColor3 = Color3.new(255,0,0);
    camera.CameraSubject = LivingThings[Object.Name].Humanoid;
end

for i,v in next, plrGUI.PlayerList.Frame.ScrollF:GetChildren() do
    if not Players:FindFirstChild(v.Name) then continue; end

    v.User.MouseButton1Click:Connect(function()
        spectatefunc(v);
    end);
end

plrGUI.PlayerList.Frame.ScrollF.ChildAdded:Connect(function(v)
    v.User.MouseButton1Click:Connect(function()
        spectatefunc(v);
    end);
end);

plrGUI.ChildAdded:Connect(function(c)
    if c.Name ~= "PlayerList" then return; end
    if not c:WaitForChild("Frame",2) then return; end
    if not c.Frame:WaitForChild("ScrollF",2) then return; end
    repeat task.wait(); until ffc(c.Frame.ScrollF,plr.Name);
    task.wait(0.1)
    for i,v in next, c.Frame.ScrollF:GetChildren() do
        if not Players:FindFirstChild(v.Name) then continue; end

        v.User.MouseButton1Click:Connect(function()
            spectatefunc(v);
        end);
    end
end);

--Settings Functions


Misc:AddToggle({text = "FPS Improver", callback = function(toggle)
    if not toggle then
        Lighting.GlobalShadows = true;
    else
        Lighting.GlobalShadows = false;
    end
end});

Misc:AddToggle({text = "Mod Notifier", state = true});
Misc:AddToggle({text = 'Chat Logger', callback = function(t) chatLogger:SetVisible(t) end});
Misc:AddDivider("Mod Notifier Settings");

Misc:AddToggle({text = "Auto Leave",tip = "Sometimes risky as they chase people who insta log", callback = function() return; end});
Misc:AddToggle({text = "Auto Panic", callback =  function() return; end});

Misc:AddToggle({text = "Panic in Range",callback = function(toggle)
    if not toggle then return; end

    repeat
        task.wait(0.2)
        local closestPlayer = getPlayerInRange(char,char.HumanoidRootPart.Position,library.flags.panicRange);

        if closestPlayer then library:Unload(); end

    until not library.flags.panicInRange
end})


Misc:AddToggle({text = "Kick in Range",function(toggle)
    if not toggle then return; end

    repeat
        task.wait(0.2)
        local closestPlayer = getPlayerInRange(char,char.HumanoidRootPart.Position,library.flags.kickRange);

        if closestPlayer then plr:Kick("Player got too close to you, auto kicked."); end

    until not library.flags.kickInRange
end})

Misc:AddSlider({text = "Panic Range", min = 1, float = 5, max = 200,function() return; end});

Misc:AddSlider({text = "Kick Range", min = 1, float = 5, max = 200, callback = function() return; end});

Misc:AddButton({text = "Panic Button", callback = panic});
Misc:AddButton({text = "Insta Log", callback = function() plr:Kick("Instantly logged") end});
Misc:AddButton({text = "Server Hop", callback = function()
    local req = syn.request({
        Method = "GET";
        Url = "https://games.roblox.com/v1/games/4878988249/servers/Public?sortOrder=Asc&limit=50"
    })
    local decoded = game.HttpService:JSONDecode(req.Body);
    local lowestping = 1000;
    local id = "";
    for i,v in next, decoded.data do
        if v.playing ~= 30 and v.id ~= game.JobId and v.ping < lowestping then
            lowestping = v.ping;
            id = v.id;
        end
    end
    TeleportService:TeleportToPlaceInstance(4878988249,id,plr);
end});
Misc:AddButton({text = "Rejoin Server", callback = function() TeleportService:TeleportToPlaceInstance(4878988249,game.JobId,plr) end});
--Safe Functions

Safe:AddToggle({text = "Use Mouse Click"});
Safe:AddToggle({text = "Auto Train", callback = function(toggle)
    if not toggle then gMaid.autoTrainMaid = nil; return; end

    local env = getsenv(plr.Backpack.LocalS);
    local autoTrainDeb = false;
    local tool = ffc(plr.Backpack,trainMove) or ffc(char,trainMove);

    gMaid.autoTrainMaid = RunService.Stepped:Connect(function()
        if autoTrainDeb then return; end
        if not loaded() then sprinting = false; return; end
        if eating or Stats.Sleeping or Stats.isKnocked or Stats.isEating or tryingToSleep then sprinting = false; return; end

        autoTrainDeb = true;

        if trainMove == "Stamina" then

            if Stats.Stamina < staminaP and not Stats.isEating then sprinting = false; env.stopSprint(); repeat task.wait() until (Stats.Stamina+1 >= library.flags["maxStamina%"]) or (not library.flags.autoTrain) end --Waiting for stamina
            if not Stats.isEating and not sprinting and not Stats.Sleeping and not Stats.isKnocked then sprinting = true; env.runPrompt(); end --If they can run then make them run

            autoTrainDeb = false;
            return; --If training stamina then return
        end

        if not tool or tool.Name ~= trainMove then tool = ffc(plr.Backpack,trainMove) or ffc(char,trainMove); end --If they changed what training they are using then switch the tool
        if not tool or not tool.Parent then library.options.autoTrain:SetState(false); autoTrainDeb = false; return; end --If no tool or tool is in nil then turn off and return
        if tool.Parent ~= char and not Stats.isEating and not Stats.isKnocked and not Stats.Sleeping and not eating then char.Humanoid:EquipTool(tool); task.wait(0.2); end --If they arent doing something and dont have the tool equipped, equip the tool
        if eating or Stats.Sleeping or Stats.isKnocked then autoTrainDeb = false; return; end --If they are busy then return
        if Stats.Stamina < staminaP then repeat task.wait() until (Stats.Stamina+1 >= library.flags["maxStamina%"]) or (not library.flags.autoTrain) end --If has less than staminaP task.wait till max stamina

        if library.flags.trainingType == "Slow" then
            repeat task.wait() until not Stats.isSquatting or not library.flags.autoTrain;
            repeat task.wait() until not Stats.isPushuping or not library.flags.autoTrain;
        end

        if tool.Parent ~= char then autoTrainDeb = false; return print("Couldn't equip tool"); end
        tool:Activate();

        local task1;
        local task2;
        if library.flags.trainingType == "Slow" then

            task2 = task.delay(5,function()
                task.wait(5);
                task.cancel(task1);
                autoTrainDeb = false;
            end)

            task1 = task.spawn(function()
                if library.flags.training == "Push up" then
                    repeat task.wait() until Stats.isPushuping or not library.flags.autoTrain;
                elseif library.flags.training == "Squat" then
                    repeat task.wait() until Stats.isSquatting or not library.flags.autoTrain;
                end
                task.cancel(task2);
                autoTrainDeb = false;
            end)
        else
            autoTrainDeb = false;
        end
    end)
    env.stopSprint();
    sprinting = false;
end});

Safe:AddList({text = "Training",values = {"Push up","Squat","Stamina"},callback = function(val) trainMove = val end});
Safe:AddList({text = "Training Type", values = {"Slow","Fast"}, callback = function() return; end});
Safe:AddSlider({text = "Stamina %", tip = "When the training action will pause until max stamina %", float = 0.1, min = 0, max = 100,callback = function(val) staminaP = val end});
Safe:AddSlider({text = "Max Stamina %", tip = "When the training action will resume", value = 99, min = 0, max = 100, float = 0.1, callback = function() return; end});

Safe:AddToggle({text = "Auto Strikespeed", callback = function(toggle)
    --Bullshit code
    if not toggle then strikeMaid:DoCleaning(); return; end

    local fightTool = getStyle();
    if not fightTool then
        library.options.autoStrikespeed:SetState(false);
        return;
    end

    if not getBag() then
        library.options.autoStrikespeed:SetState(false);

        ToastNotif.new({
            text = "Stand closer to a bag to begin";
            duration = 5
        });
        return;
    end

    for i,v in next, BadModels do
        for t,k in next, i:GetChildren() do
            k.CanCollide = false;
        end
    end

    --Stuff that actually matters
    local shouldM2 = false;
    strikeMaid:GiveTask(char.ChildAdded:Connect(function(v)
        if v.Name == "Attacking" and v.Value == 4 then
            task.spawn(function() shouldM2 = true; task.wait(2); shouldM2 = false; end)
            v:Destroy();
        end
    end))

    local function tryHit(canHit)
        while (canHit.Value and library.flags.autoStrikespeed) do
            fightTool:Activate();
            if shouldM2 then
                local key = getKey(plr.Backpack.LocalS);
                if not key then return; end

                plr.Backpack.Action:FireServer(key,"GuardBreak",true);
            elseif not char:WaitForChild("Attacking",0.2) and canHit.Value then
                fightTool:Activate();
            end
            task.wait(1)
        end
    end

    local curBag = char.HumanoidRootPart.Position;
    strikeMaid:GiveTask(plrGUI.ChildAdded:Connect(function(v)
        if v.Name ~= "SpeedTraining" then return; end

        local canHit = v:WaitForChild("CanHit",5);
        if not canHit then return; end

        char.Humanoid:UnequipTools();
        fightTool.Parent = char;
        task.wait(0.1);

        strikeMaid:GiveTask(v.CanHit:GetPropertyChangedSignal("Value"):Connect(function()
            if not canHit.Value then return; end

            fightTool.Parent = char;
            tryHit(canHit);
        end))

        if not canHit.Value then return; end
        tryHit(canHit);
    end))


    strikeMaid:GiveTask(plrGUI.ChildRemoved:Connect(function(v)
        if v.Name ~= "SpeedTraining" then return; end
        if ffc(plr.Backpack,"Strike Speed Training") or ffc(char,"Strike Speed Training") then return; end

        local button = getButton("Strike",999);
        if not button then return; end

        char.Humanoid:UnequipTools();

        if ((button.Head.Position * Vector3.new(1, 0, 1)) - (char.HumanoidRootPart.Position * Vector3.new(1, 0, 1))).magnitude > 10 and library.flags.autoWalk then
            legitMove(button.Head.Position);
            safeClick(button.Head);
            legitMove(curBag);
        else
            safeClick(button.Head);
        end

        char.Humanoid:UnequipTools();
        local strikeTool = plr.Backpack:WaitForChild("Strike Speed Training",5) or ffc(char,"Strike Speed Training");

        if not strikeTool then return; end

        strikeTool.Parent = char;
        task.wait(0.3);
        strikeTool:Activate();
    end))

    if ffc(plrGUI,"SpeedTraining") then
        if fightTool.Parent ~= char then char.Humanoid:UnequipTools(); end

        local canHit = plrGUI.SpeedTraining:WaitForChild("CanHit",5);
        if not canHit then return; end

        fightTool.Parent = char;
        task.wait(0.1);

        strikeMaid:GiveTask(plrGUI.SpeedTraining.CanHit:GetPropertyChangedSignal("Value"):Connect(function()
            if not canHit.Value then return; end

            fightTool.Parent = char;
            tryHit(canHit);
        end))
        if not canHit.Value then return; end

        tryHit(canHit);
    else
        if ffc(plr.Backpack,"Strike Speed Training") or ffc(char,"Strike Speed Training") then return; end

        local button = getButton("Strike",999);
        if not button then return; end

        char.Humanoid:UnequipTools();
        if library.flags.autoWalk and ((button.Head.Position * Vector3.new(1, 0, 1)) - (char.HumanoidRootPart.Position * Vector3.new(1, 0, 1))).magnitude > 10 then
            legitMove(button.Head.Position);
            safeClick(button.Head);
            legitMove(curBag);
        else
            safeClick(button.Head);
        end

        char.Humanoid:UnequipTools();

        local strikeTool = plr.Backpack:WaitForChild("Strike Speed Training",5) or ffc(char,"Strike Speed Training");
        if not strikeTool then return; end

        strikeTool.Parent = char;
        task.wait(0.2);
        strikeTool:Activate();
    end
end});

Safe:AddToggle({text = "Auto Walk", tip = "This function is very obvious and clippable", callback = function() return; end})


local autoPunch = column1:AddSection('Auto Punch');
autoPunch:AddToggle({text = "Auto Punch",tip = "This is a Striking Power Macro" , callback = function(toggle)
    if not toggle then gMaid.autoPunchMaid = nil; gMaid.tryM2 = nil; return; end

    local autoPunchDeb = false;
    local shouldM2 = false;
    local fightTool = getStyle();
    if not fightTool then return; end

    local givenTask;
    gMaid.tryM2 = char.ChildAdded:Connect(function(v)
        if v.Name ~= "Attacking" then return; end

        if v.Value == 4 then
            givenTask = task.spawn(function() shouldM2 = true; task.wait(2); shouldM2 = false; end)
        elseif v.Value == 5 then
            shouldM2 = false;
            if givenTask then
                task.cancel(givenTask);
            end
        end
    end)

    gMaid.autoPunchMaid = RunService.Stepped:Connect(function()
        if autoPunchDeb then return; end
        if eating or Stats.isKnocked or not fightTool then return; end

        autoPunchDeb = true;

        if fightTool.Parent ~= char then char.Humanoid:UnequipTools(); fightTool.Parent = char; end --If the fightTool parent isnt char then give it to char
        if eating then repeat task.wait(); until (not eating) or (not library.flags.autoPunch); end --If eating then task.wait till not

        if (Stats.Stamina+1 >= 80) or Stats.Stamina <= library.flags["minStamina%"] then
            env.runPrompt();
            repeat
                if not Stats.isRunning then --To prevent loop from getting stuck
                    env.runPrompt();
                end
                task.wait(0.2);
            until Stats.Stamina <= library.flags["minStamina%"] or not library.flags.autoPunch;

            env.stopSprint();
            repeat task.wait() until Stats.Stamina >= library.flags["staminaWait%"] or not library.flags.autoPunch;
        end

        if shouldM2 and library.flags.useM2 then
            local key = getKey(plr.Backpack.LocalS);
            if not key then autoPunchDeb = false; return; end

            plr.Backpack.Action:FireServer(key,"GuardBreak",true);
        else
            fightTool:Activate();
        end

        autoPunchDeb = false;
    end)
end});

autoPunch:AddSlider({text = "Min Stamina %", tip = "Will run until this % to sweat", min = 0, max = 100, float = 0.1, callback = function() return; end});
autoPunch:AddSlider({text = "Stamina Wait %", tip = "Will wait till this % to punch", value = 99, min = 0, max = 100, callback = function() return; end, float = 0.1});
autoPunch:AddToggle({text = "Use M2"})

local autoClickSettings = column2:AddSection("Autoclick");

autoClickSettings:AddToggle({text = "Hold M1", callback = function(t)
    if (not t) then
        gMaid.holdM1 = nil;
        return;
    end;

    local function canAttack()
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and plr.Character and plr.Character:FindFirstChildWhichIsA("Tool");
    end;

    gMaid.holdM1 = task.spawn(function()
        while task.wait() do
            local tool = canAttack();
            if (not tool) then continue end;

            tool:Activate();
        end;
    end);
end})


autoClickSettings:AddToggle({text = "Auto Click", callback = function(toggle)
    if not toggle then return; end
    task.wait(1);
    repeat task.wait();
        local pos = UserInputService:GetMouseLocation();
        VirtualInputManager:SendMouseButtonEvent(pos.X,pos.Y,0,true,game,1);
        task.wait(library.flags.clickDelay);
        VirtualInputManager:SendMouseButtonEvent(pos.X,pos.Y,0,false,game,1);
    until not library.flags.autoClick;
end});

autoClickSettings:AddSlider({text = "Click Delay", value = 0.5, min = 0, max = 5, float = 0.1});

local legitAutoMachine = column2:AddSection("Legit Auto Machine");

legitAutoMachine:AddToggle({text = "LEGIT Auto Machine", callback = function(toggle)
    if not toggle then legitMachineMaid:DoCleaning(); doingAction = false; return; end
    doingAction = false;

    local lastMachine = nil;
    legitMachineMaid:GiveTask(plrGUI.ChildAdded:Connect(function(v)
        task.wait()
        if ffc(v,"Machine") then lastMachine = v.Machine.Value; end

        if v.Name == "BarbellMachineGUI" or v.Name == "SquatMachineGUI" then
            if not v:WaitForChild("Frame2") then return; end
            if not v.Frame2:WaitForChild("LiftingF") then return; end
            doingAction = true;

            legitMachineMaid:GiveTask(v.Frame2.LiftingF.ChildAdded:Connect(function(z)
                if stupidWait then return; end
                if z.Name ~= "LiftIcon" then return; end
                if Stats.Stamina <= library.flags["minimumStamina%"] then stupidWait = true; repeat task.wait() until Stats.Stamina >= library.flags["maximumStamina%"] or (not library.flags.legitAutoMachine); stupidWait = false; end --Wait for stamina to reach 100%

                task.wait(library.flags.keypressDelay);
                repeat
                    safeButton(z);
                    task.wait(0.1);
                until (not z or not z.Parent)
            end))

            if not library.flags.autoReuse then return; end
            if not v:WaitForChild("Frame") then return; end
            if not v.Frame:WaitForChild("ListF") then return; end

            local powerButton = v.Frame.ListF:WaitForChild(string.format("Barbell %s Weight",library.flags["lift/squatPower"]));
            if not powerButton then return; end

            repeat
                safeButton(powerButton);
                task.wait();
            until (v.Frame2.Visible) or (not library.flags.legitAutoMachine or not library.flags.autoReuse)

            if (not library.flags.legitAutoMachine) then return; end

            repeat task.wait() until (Stats.Stamina >= 100) or (not library.flags.legitAutoMachine);

            repeat
                safeButton(v.Frame2.Start);
                task.wait();
            until not v.Frame2.Start.Visible or (not library.flags.legitAutoMachine or not library.flags.autoReuse)
            return;
        end

        --Treadmill Part
        if v.Name ~= "TreadmillMachineGUI" then return; end
        if not v:WaitForChild("Frame3") then return; end
        if not v.Frame3:WaitForChild("TrainingF") then return; end

        doingAction = true;
        task.wait();
        legitMachineMaid:GiveTask(v.Frame3.TrainingF.ButtonTemplate:GetPropertyChangedSignal("Position"):Connect(function()
            if stupidWait then return; end
            if Stats.Stamina <= library.flags["minimumStamina%"] then stupidWait = true; repeat task.wait() until Stats.Stamina >= library.flags["maximumStamina%"] or (not library.flags.legitAutoMachine); stupidWait = false; end --Wait for stamina to reach 100%

            task.wait(library.flags.keypressDelay);

            local key = v.Frame3.TrainingF.ButtonTemplate.Input.Text;
            VirtualInputManager:SendKeyEvent(true,key,false,game);
            task.wait(0.1);
            VirtualInputManager:SendKeyEvent(false,key,false,game);
        end))

        --Treadmill auto use part
        if not library.flags.autoReuse then return; end

        if not v:WaitForChild("Frame") then return; end
        if not ffc(v.Frame,library.flags.treadmillType,true) then return; end

        repeat
            safeButton(ffc(v.Frame,library.flags.treadmillType,true));
            task.wait();
        until (not v.Parent) or (not v.Frame.Visible) or (not library.flags.legitAutoMachine or not library.flags.autoReuse)

        repeat task.wait(); until (v.Frame2.ListF:FindFirstChild(library.flags.treadmillPower) or not library.flags.autoReuse)

        repeat
            safeButton(ffc(v.Frame2.ListF,library.flags.treadmillPower,true));
            task.wait();
        until (not v.Parent) or (not v.Frame2.Visible) or (not library.flags.legitAutoMachine or not library.flags.autoReuse)

        repeat task.wait(); until (v.Frame3.Visible) or (not library.flags.legitAutoMachine);

        if (not library.flags.legitAutoMachine) then return; end
        repeat task.wait() until (Stats.Stamina >= 100) or (not library.flags.legitAutoMachine);

        repeat
            safeButton(v.Frame3.Start);
            task.wait();
        until not v.Frame3.Start.Visible or (not library.flags.legitAutoMachine or not library.flags.autoReuse)
    end))

    legitMachineMaid:GiveTask(plrGUI.ChildRemoved:Connect(function(v)
        if v.Name ~= "BarbellMachineGUI" and v.Name ~= "SquatMachineGUI" and v.Name ~= "TreadmillMachineGUI" then return; end
        doingAction = false; --Should be set before waiting to get on the machine

        if not library.flags.autoReuse then return; end
        if not library.flags.legitAutoMachine then return; end
        if not lastMachine then return; end

        task.wait(library.flags.reuseWait);

        isBusy(); --Checks if they need to eat and waits until they do

        doingAction = true;

        char.Humanoid:UnequipTools();
        repeat
            safeClick(lastMachine.Base);
            task.wait();
        until ffc(plrGUI,"BarbellMachineGUI") or ffc(plrGUI,"SquatMachineGUI") or ffc(plrGUI,"TreadmillMachineGUI") or not library.flags.autoReuse or not library.flags.legitAutoMachine
    end))
end});

legitAutoMachine:AddSlider({text = "Minimum Stamina %", value = 30, min = 0, max = 100, float = 0.1, callback = function() return; end});
legitAutoMachine:AddSlider({text = "Maximum Stamina %", value = 100, min = 0, max = 100, float = 0.1, callback = function() return; end});

legitAutoMachine:AddToggle({text = "Auto Reuse"});
legitAutoMachine:AddSlider({text = "Reuse Wait",tip = "How long to wait before getting on the machine", value = 2, min = 0, max = 2,float = 0.1, function() end});
legitAutoMachine:AddList({text ="Treadmill Type", values = {"Stamina","RunningSpeed"}});
legitAutoMachine:AddSlider({text = "Treadmill Power",value = 1, min = 1, max = 5, float = 1, function() return; end});
legitAutoMachine:AddSlider({text = "Lift/Squat Power",value = 1, min = 1, max = 6, float = 1, function() return; end});
legitAutoMachine:AddSlider({text = "Keypress Delay",value = 0,min = 0, max = 1, float = 0.1, function() return; end});

local autoDuraSettings = column2:AddSection("Auto Dura Settings");

autoDuraSettings:AddToggle({text = "Auto Dura",callback = function(state)
    if not state then autoDura:ClearAll(); return; end

    local player1 = search(plrTbl,string.lower(library.flags.firstTurn));
    local player2 = search(plrTbl,string.lower(library.flags.secondTurn));

    if not player1 or not player2 then autoDura:CreateError("Cannot find one or both of the players."); return; end
    if not player1.Character or not player2.Character then autoDura:CreateError("One of the player's isn't spawned in"); return; end

    local autoDuraObj = autoDura.new(player1.Character,player2.Character);
    autoDuraObj:Start();
end})

autoDuraSettings:AddBox({text = "First Turn", tip = "This value should be the same for both users", value = "First Player"});
autoDuraSettings:AddBox({text = "Second Turn", tip = "This value should be the same for both users", value ="Second Player"});
autoDuraSettings:AddSlider({text = "Minimum HP %",value = 15,min = 0,max = 100});
autoDuraSettings:AddToggle({text = "Take Turns",tip = "This value should be the same for both users"});

local function eat(item,ignore,keepEating)
    if getgenv().debug_auto_eat then
        print(item, Stats.Hunger, ignore, Stats.isEating, Stats.isRunning, doingAction, Stats.isKnocked, Stats.Sleeping, tryingToSleep, library.flags.autoEat);
    end
    if typeof(item) == 'table' then item = unpack(item); end --If we pass a table to it handle it properly
    if Stats.Hunger >= library.flags["autoEatAt%"] and not ignore then return; end
    if eating then return; end
    if Stats.isEating then return; end
    if Stats.isRunning then return false; end
    if doingAction then return false; end
    if Stats.isKnocked then return false; end
    if Stats.Sleeping then return false; end
    if tryingToSleep then return false; end
    if not item then return false; end
    if not library.flags.autoEat then return false; end
    warn("PASSED ALL")

    if item.Parent == nil then

        if library.flags.autoSleep and getFood() == nil then --If no more food and they using auto sleep, make them go to sleep.
            env.stopSprint();
            char.Humanoid:UnequipTools();
            toggleSleep();
            return false;
        end

        return false;
    end

    eating = true;
    sprinting = false;

    warn(item.Parent);
    if item.Parent ~= char then
        char.Humanoid:UnequipTools();
    end

    if doingAction then char.Humanoid:UnequipTools(); return false; end --We want to make sure we NEVER have food on treadmill

    item.Parent = char;
    item:Activate();

    repeat task.wait(0.5); item:Activate(); if item.Parent == nil then break; end if item.Parent ~= char then if doingAction then break; end item.Parent = char; end until Stats.isEating or not library.flags.autoEat; --If item is in nil or they are on the treadmill then break, otherwise equip
    repeat task.wait(0.5); until not Stats.isEating or not library.flags.autoEat;

    if item.Parent ~= char then
        char.Humanoid:UnequipTools();
    end
    eating = false;

    if Stats.Hunger <= library.flags["eatTo%"] and keepEating then
        local foodTab = getFood(lastFood) or getFood() or {};
        foodTool,lastFood = unpack(foodTab);
        eat(foodTool,true,true);
    end
    char.Humanoid:UnequipTools();
end


local autoEatSettings = column2:AddSection("Auto Eat Settings");

autoEatSettings:AddToggle({text = "Auto Eat", callback = function(toggle)
    if not toggle then return; end
    if not loaded() then return; end

    foodTool,lastFood = unpack(getFood() or {});
    repeat
        task.wait(0.2);
        local foodTab = getFood(lastFood) or getFood() or {};
        foodTool,lastFood = unpack(foodTab);
        local eatRet = eat(foodTool,false,true);
        if eatRet == false then
            eating = eatRet;
        end
    until not library.flags.autoEat;
end});


autoEatSettings:AddSlider({text = "Auto Eat at %",value = 0, min = 0, max = 100, float = 0.1});
autoEatSettings:AddSlider({text = "Eat to %",value = 100, min = 0,max = 100, float = 0.1});


autoEatSettings:AddToggle({text= "Auto Protein", callback = function(toggle)
    if not toggle then return; end

    repeat
        local eatRet;
        task.wait(0.2);
        if not Stats.ProteinShake then
            eatRet = eat(getFood("Protein Shake"),true); --Should only eat Protein Shake
        end

        if eatRet == false then
            eating = eatRet;
        end
    until not library.flags.autoProtein;
end});

autoEatSettings:AddToggle({text= "Auto BCAA", callback = function(toggle)
    if not toggle then return; end

    repeat
        local eatRet;
        task.wait(0.2);
        if not Stats.BCAA then
            eatRet = eat(getFood("BCAA"),true); --Should only eat BCAA
        end

        if eatRet == false then
            eating = eatRet;
        end
    until not library.flags.autoBcaa;
end});

autoEatSettings:AddToggle({text = "Auto Fat Burner",callback = function(toggle)
    if not toggle then return; end

    repeat
        local eatRet;
        task.wait(0.2);
        if not Stats.FatBurner then
            eatRet = eat(getFood("Fat Burner"),true); --Should only eat Fat Burner
        end

        if eatRet == false then
            eating = eatRet;
        end
    until not library.flags.autoFatBurner;
end});

autoEatSettings:AddToggle({text = "Auto Scalar",callback = function(toggle)
    if not toggle then return; end

    repeat
        local eatRet;
        task.wait(0.2);
        if not Stats.Scalar then
            eatRet = eat(getFood("Scalar"),true); --Should only eat Scalar
        end

        if eatRet == false then
            eating = eatRet;
        end
    until not library.flags.autoScalar;
end});

local sleepSettings = column2:AddSection("Auto Sleep Settings");

sleepSettings:AddToggle({text = "Auto Sleep", callback = function(toggle)
    if not toggle then gMaid.AutoSleep = nil; return; end
    local lastStep = tick();
    gMaid.AutoSleep = RunService.Stepped:Connect(function()
        if tick()-lastStep <= 0.2 then return; end
        lastStep = tick();
        if Stats.Fatigue >= library.flags["sleepAt%"] and not Stats.Sleeping then --Sleep
            toggleSleep();
        elseif Stats.Fatigue <= library.flags["wakeAt%"] and Stats.Sleeping then --Wake up
            if library.flags.autoEat and getFood() == nil then return; end
            toggleSleep();
        end
    end);
end});
sleepSettings:AddSlider({text = "Sleep at %",value = 65,min = 0,max = 100, float = 0.1});
sleepSettings:AddSlider({text = "Wake at %",value = 0,min = 0,max = 100,float = 0.1});

local autoRhythm;
autoRhythm = Safe:AddToggle({text = "Auto Rhythm", callback = function(toggle)
    if not toggle then gMaid.autoRhythm = nil; return; end

    local lastRhythmLoop = tick();
    local fightTool = getStyle();
    gMaid.autoRhythm = RunService.Stepped:Connect(function()
        if not (tick() - lastRhythmLoop >= 0.2) then return; end

        lastRhythmLoop = tick();

        if char.HumanoidRootPart.RhythmUI.Enabled then return; end
        if fightTool and fightTool.Parent ~= char then return; end
        if Stats.Rhythm >= 100 then return; end
        if Stats.isEating then return; end
        if Stats.isRunning then return; end

        VirtualInputManager:SendKeyEvent(true,"R",false,game);
        task.wait(0.1);
        VirtualInputManager:SendKeyEvent(false,"R",false,game);
    end)
end})

Safe:AddToggle({text = "Auto Use Flow", callback = function(toggle)
    if not toggle then gMaid.autoFlowToggle = nil; return; end
    if not ffc(plrGUI,"FlowUI") then library.options.autoUseFlow:SetState(false); return; end

    gMaid.autoFlowToggle = plrGUI.FlowUI:GetPropertyChangedSignal("Enabled"):Connect(function()
        if not plrGUI.FlowUI.Enabled then return; end

        VirtualInputManager:SendKeyEvent(true,"T",false,game);
        task.wait(0.1);
        VirtualInputManager:SendKeyEvent(false,"T",false,game);
    end)
end})

local function autoSprint(toggle)
    if (not toggle) then
        gMaid.autoSprint = nil;
        return;
    end;

    local moveKeys = {Enum.KeyCode.W};
    local lastRan = 0;

    gMaid.autoSprint = UserInputService.InputBegan:Connect(function(input, gpe)
        if (gpe or tick() - lastRan < 0.1) then return end;

        if (table.find(moveKeys, input.KeyCode)) then
            lastRan = tick();
            VirtualInputManager:SendKeyEvent(true, input.KeyCode, false, game);
        end;
    end);
end;

Safe:AddToggle({text = "Auto Sprint",callback=autoSprint});

local mobs = {};
local networkOneShot = {};
networkOneShot.__index = networkOneShot;

function networkOneShot.new(mob)
    local self = setmetatable({},networkOneShot);
    mobs[mob] = self;

    self._maid = Maid.new();

    self.char = mob;
    self.humanoid = mob.Humanoid;
    self.hrp = mob.HumanoidRootPart;

    self._maid:GiveTask(mob.Destroying:Connect(function()
        self:Destroy();
    end))
    print("Made Connection!", mob);
    self._maid:GiveTask(RunService.RenderStepped:Connect(function()

        if library.flags.oneShotPercent < self.humanoid.Health/self.humanoid.MaxHealth*100 then return; end
        self.char:PivotTo(CFrame.new(self.hrp.Position.X,workspace.FallenPartsDestroyHeight-500,self.hrp.Position.Z))
    end))
end

function networkOneShot:Destroy()
    self._maid:DoCleaning();
    for i,v in next, mobs do
        if v ~= self then continue; end

        mobs[i] = nil;
    end
end

function networkOneShot:ClearAll()
    for _,v in next, mobs do
        v:Destroy();
    end
end

risky:AddButton({text = "Money Farm",callback = function()
    setclipboard("https://shoppy.gg/product/mBzd1gV");
    ToastNotif.new({text= "Buy money service 1m for 15$ at https://shoppy.gg/product/mBzd1gV , it has also been copied to your clipboard"});
end})

risky:AddToggle({text = 'One Shot NPC',tip = "Do not kill enemies too quickly as you will get logged", callback = function(toggle)
    if not toggle then gMaid.OwnerShipBeat = nil; gMaid.OneShotNPC = nil; networkOneShot:ClearAll(); return; end

    gMaid.OwnerShipBeat = RunService.Heartbeat:Connect(function()
        sethiddenproperty(plr,"MaxSimulationRadius",math.huge);
        sethiddenproperty(plr,"SimulationRadius",math.huge);
    end)

    gMaid.OneShotNPC = Utility.listenToChildAdded(LivingThings,function(instance)
        if ffc(Players,instance.Name) then return; end
        if not instance:WaitForChild("HumanoidRootPart",5) or not instance:WaitForChild("Humanoid",5) then return; end

        networkOneShot.new(instance); --Starts the handler for oneshot
    end)
end}):AddSlider({
  flag = "One Shot Percent",
  min = 0,
  max = 100,
  value = 100,
  float = 1,
  tip = "The HP % should they get one shot at"
});

local angleOffSet = CFrame.Angles(math.rad(-90),0,0);
risky:AddToggle({text = 'Attach to Back (Mobs)', flag = "Attach To Back", callback = function(toggle)
    if not toggle then gMaid.attachToback = nil; return; end

    local lastcheck = tick();
    local target = getMobInRange(library.flags.attachToBackRange);
    gMaid.attachToback = RunService.Heartbeat:Connect(function()
        if tick()-lastcheck >= 0.1 and target then
            lastcheck = tick();

            if ffc(target,"KO") then return; end
        end

        if not target or not target.Parent then
            target = getMobInRange(library.flags.attachToBackRange);
        end
        if not target or not ffc(target,"HumanoidRootPart") then return; end

        char.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame * (CFrame.new(0,library.flags.attachToBackDistance,1)*angleOffSet);
        char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero;
        char.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero;
    end)
end});

risky:AddSlider({text = "Attach to Back Distance",tip = "How far to move you from the mob", value = 5,min=1,max=10,float=0.1});
risky:AddSlider({text = "Attach to Back Range",tip = "Get closest mob in this range",value = 100,min=0,max=100,float=1});

local riskyAutoMachine = riskyColumn2:AddSection("Risky Auto Machine");




--Risky automachine
--Hooks the OnClientInvoke to return a time in the past such as -1
--Due to it returning a number below 0 it will give the best possible stats,
--They should be able to change the return timing between -1 and 1
--It should use a wait loop whenever regenerating stamina
--Thus it wont give a return until the next button
--This should entail the BEST possible auto farm
--The sliders and toggles should be the same as legit auto machine



do --Risky AutoMachine

    local riskyMachine = {};
    riskyMachine.__index = riskyMachine;

    local riskyMachineTab = {};

    function riskyMachine.new()
        local self = setmetatable({},riskyMachine);
        table.insert(riskyMachineTab, self);

        self._maid = Maid.new();

        self:Setup();
        return self;
    end

    function riskyMachine:Setup()
        self._maid:GiveTask(Utility.listenToChildAdded(plrGUI,function(machineUI)
            if machineUI.Name ~= "TreadmillMachineGUI" and machineUI.Name ~= "BarbellMachineGUI" and machineUI.Name ~= "SquatMachineGUI" then return; end
            self._machineUI = machineUI;
            self._machine = machineUI:WaitForChild("Machine").Value;
            self._remote = machineUI:WaitForChild("RemoteF");
            self._lastMachineName = machineUI.Name;

            if self._lastMachineName == "TreadmillMachineGUI" then
                self:Treadmill();
            elseif self._lastMachineName == "BarbellMachineGUI" or self._lastMachineName == "SquatMachineGUI" then
                self:Weights();
            end
        end))

        self._maid:GiveTask(plrGUI.ChildRemoved:Connect(function(machineUI)
            if self._lastMachineName ~= machineUI.Name then return; end

            doingAction = false; --Should be set before waiting to get on the machine

            if not library.flags.autoReuse then return; end
            if not library.flags.riskyAutoMachine then return; end

            task.wait(library.flags.reuseWait);

            isBusy(); --Checks if they need to eat and waits until they do
            doingAction = true;

            char.Humanoid:UnequipTools();
            repeat
                safeClick(self._machine.Base);
                task.wait();
            until ffc(plrGUI,self._lastMachineName) or not library.flags.autoReuse or not library.flags.riskyAutoMachine
        end))
    end

    function riskyMachine:Treadmill()
        doingAction = true;
        local machineUI = self._machineUI;

        task.wait(2);

        local isPaused = false;
        self._remote.OnClientInvoke = function(action,promptInfo)
            if action == "Exit" then
                plrGUI.BackpackGUI.Enabled = true;
                if ffc(self._machine,"InviWall") then
                    self._machine.InviWall.CanCollide = true;
                end
                return;
            end

            if action ~= "Prompt" then return; end

            if Stats.Stamina <= library.flags["minimumStamina%"] then
                if not isPaused then
                    print('pausing???')
                    isPaused = true;
                    task.spawn(function()
                        repeat task.wait() until Stats.Stamina >= library.flags["maximumStamina%"] or (not library.flags.riskyAutoMachine);
                        isPaused = false;
                        print('unpausing what???')
                    end)
                    return 0,false;
                end
            end

            repeat task.wait() until not isPaused;
            return 0,true,true
        end

        if not library.flags.autoReuse then return; end

        local v = machineUI;

        if not v:WaitForChild("Frame") then return; end
        if not ffc(v.Frame,library.flags.treadmillType,true) then return; end

        repeat
            safeButton(ffc(v.Frame,library.flags.treadmillType,true));
            task.wait();
        until (not v.Parent) or (not v.Frame.Visible) or (not library.flags.riskyAutoMachine or not library.flags.autoReuse)

        repeat task.wait(); until (v.Frame2.ListF:FindFirstChild(library.flags.treadmillPower) or not library.flags.autoReuse)

        repeat
            safeButton(ffc(v.Frame2.ListF,library.flags.treadmillPower,true));
            task.wait();
        until (not v.Parent) or (not v.Frame2.Visible) or (not library.flags.riskyAutoMachine or not library.flags.autoReuse)

        repeat task.wait(); until (v.Frame3.Visible) or (not library.flags.riskyAutoMachine);

        if (not library.flags.riskyAutoMachine) then return; end
        repeat task.wait() until (Stats.Stamina >= 100) or (not library.flags.riskyAutoMachine);

        repeat
            safeButton(v.Frame3.Start);
            task.wait();
        until not v.Frame3.Start.Visible or (not library.flags.riskyAutoMachine or not library.flags.autoReuse)
    end

    function riskyMachine:Weights()
        doingAction = true;
        local machineUI = self._machineUI;

        task.wait(2);

        local isPaused = false;
        self._remote.OnClientInvoke = function(action,promptInfo)
            if action == "Exit" then
                plrGUI.BackpackGUI.Enabled = true;
                return;
            end

            if action ~= "LiftPrompt" then return; end

            if Stats.Stamina <= library.flags["minimumStamina%"] then
                if not isPaused then
                    print('pausing???')
                    isPaused = true;
                    task.spawn(function()
                        repeat task.wait() until Stats.Stamina >= library.flags["maximumStamina%"] or (not library.flags.riskyAutoMachine);
                        isPaused = false;
                        print('unpausing what???')
                    end)
                    return 0,false;
                end
            end

            repeat task.wait() until not isPaused;
            warn'going thru'
            return 0,true
        end

        local v = machineUI;

        if not library.flags.autoReuse then return; end
        if not v:WaitForChild("Frame") then return; end
        if not v.Frame:WaitForChild("ListF") then return; end

        local powerButton = v.Frame.ListF:WaitForChild(string.format("Barbell %s Weight",library.flags["lift/squatPower"]));
        if not powerButton then return; end

        repeat
            safeButton(powerButton);
            task.wait();
        until (v.Frame2.Visible) or (not library.flags.riskyAutoMachine or not library.flags.autoReuse)

        if (not library.flags.riskyAutoMachine) then return; end

        repeat task.wait() until (Stats.Stamina >= 100) or (not library.flags.riskyAutoMachine);

        repeat
            safeButton(v.Frame2.Start);
            task.wait();
        until not v.Frame2.Start.Visible or (not library.flags.riskyAutoMachine or not library.flags.autoReuse)
    end

    function riskyMachine:Destroy()
        self._maid:DoCleaning();
        for i,v in next, riskyMachineTab do
            if v == self then
                riskyMachineTab[i] = nil;
            end
        end
    end

    function riskyMachine:ClearAll()
        for _,v in next, riskyMachineTab do
            v:Destroy();
        end
    end


    riskyAutoMachine:AddToggle({text = "Risky Auto Machine",tip = "Makes gaining all stats faster through machines, uses settings from legit auto machine",callback = function(t)
        if not t then return riskyMachine:ClearAll(); end

        riskyMachine.new();
    end});
end


local playerMods = riskyColumn2:AddSection("Risky Player Mods");

playerMods:AddToggle({text = 'Fly',callback = function(toggle)
    if not toggle then flyMaid:DoCleaning(); return; end
    if not loaded() then return; end
    local T = char.HumanoidRootPart
    local CONTROL = {F = 0, B = 0, L = 0, R = 0}
    local lCONTROL = {F = 0, B = 0, L = 0, R = 0}
    local SPEED = 5
    local BG = Instance.new('BodyGyro')
    BG.Parent = T;
    local BV = Instance.new('BodyVelocity')
    BV.Parent = T;
    BG.P = 9e4
    BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.cframe = T.CFrame
    BV.velocity = Vector3.new(0, 0.1, 0)
    BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
    print(library.flags.fly)
    spawn(function()
        repeat task.wait()
            if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 then
                SPEED = flySpeed
            elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0) and SPEED ~= 0 then
                SPEED = 0
            end
            if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 then
                BV.velocity = ((camera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((camera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B) * 0.2, 0).p) - camera.CoordinateFrame.p)) * SPEED
                lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
            elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and SPEED ~= 0 then
                BV.velocity = ((camera.CoordinateFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((camera.CoordinateFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B) * 0.2, 0).p) - camera.CoordinateFrame.p)) * SPEED
            else
                BV.velocity = Vector3.new(0, 0.1, 0)
            end
            BG.cframe = camera.CoordinateFrame
        until not library.flags.fly;
        CONTROL = {F = 0, B = 0, L = 0, R = 0}
        lCONTROL = {F = 0, B = 0, L = 0, R = 0}
        SPEED = 0
        BG:Destroy()
        BV:Destroy()
    end);

    flyMaid:GiveTask(UserInputService.InputBegan:connect(function(Input, gameProcessed)
        local code = Input.KeyCode;
        if code == Enum.KeyCode.W then
            CONTROL.F = 1;
        elseif code == Enum.KeyCode.S then
            CONTROL.B = -1;
        elseif code == Enum.KeyCode.A then
            CONTROL.L = -1;
        elseif code == Enum.KeyCode.D then
            CONTROL.R = 1;
        end
    end))
    flyMaid:GiveTask(UserInputService.InputEnded:connect(function(Input, gameProcessed)
        local code = Input.KeyCode;
        if code == Enum.KeyCode.W then
            CONTROL.F = 0;
        elseif code == Enum.KeyCode.S then
            CONTROL.B = 0;
        elseif code == Enum.KeyCode.A then
            CONTROL.L = 0;
        elseif code == Enum.KeyCode.D then
            CONTROL.R = 0;
        end
    end))
end}):AddSlider({text = 'Fly Speed',value=50,min=1,max=100,callback=function(val) flySpeed = val; end});

local oldSpeed; --This function can get detected technically
playerMods:AddToggle({text="Run Speed", callback = function(toggle)
    local func;
    for i,v in next, getconnections(Events.UpdateStats.OnClientEvent) do
        if v.Function and not is_synapse_function(v.Function) then
            func = v.Function;
        end
    end

    local tab = getupvalue(func,1);
    oldSpeed = rawget(tab,"RunningSpeed") or oldSpeed;
    if not toggle then
        setmetatable(tab,nil);
        rawset(tab,"RunningSpeed",oldSpeed);
        return;
    end

    setmetatable(tab,{
        __newindex = function(t,k,v)
            if k == 'RunningSpeed' then
                return;
            end
            return rawset(t,k,v);
        end;
        __index = function(t,k)
            if k == 'RunningSpeed' then
                return library.flags.runningSpeed;
            end
        end
    })
    rawset(tab,"RunningSpeed",nil);
end}):AddSlider({
    value=500,
    min=0,
    max=2300,
    flag = "Running Speed",
})


local function teleportFunc(cframe)
    repeat task.wait() until plr.Character ~= nil;
    repeat task.wait() until char:FindFirstChild("HumanoidRootPart");

    char.HumanoidRootPart:GetPropertyChangedSignal("CFrame"):Wait();
    teleMaid:GiveTask(RunService.RenderStepped:Connect(function()
        char.HumanoidRootPart.CFrame = cframe;
        char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero;
        char.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero;
    end))
    task.spawn(function()
        task.wait(0.5);
        repeat task.wait() until ffcwia(plr.Backpack,"Tool");
        teleMaid:DoCleaning();
    end);
end

local function teleport(target)
    if not loaded() then return; end
    local cframe = target;
    if typeof(cframe) == "Vector3" or typeof(cframe) == "CFrame" then
        if typeof(target) == "Vector3" then
            cframe = CFrame.new(cframe);
        end
        teleMaid:GiveTask(plr.CharacterAdded:Connect(function() teleportFunc(cframe) end));
        char.Humanoid.Health = 0;
    elseif typeof(target) == "Instance" and target:IsA("Part") then
            teleMaid:GiveTask(plr.CharacterAdded:Connect(function() teleportFunc(cframe.CFrame) end));
            char.Humanoid.Health = 0;
        else
    end
end

playerMods:AddBox({text="Teleport (Respawns you)",noload = true, skipflag = true, callback=function(val)
    if val == 'nil' or val == '' or not val then return; end
    if search(plrTbl,string.lower(val)) and search(plrTbl,string.lower(val)) ~= plr then
        local target = search(plrTbl,string.lower(val));
        if target and target.Character and ffc(target.Character,"HumanoidRootPart") then
            teleport(target.Character.HumanoidRootPart);
        end
    else
        ToastNotif.new({
            text = "Looks like the player isn't here or there was a error in their name double check the capitalization";
            duration = 20
        });
    end
end});

playerMods:AddList({text="Teleports", noload = true, skipflag = true, values = Teleports,callback=function(v)
    v = Teleports[v];
    local inRoom = false;
    local pName;
    for t,k in next, LivingThings:GetChildren() do
        if ffc(k,"HumanoidRootPart") and k ~= char then
            local raycastRes = workspace:Raycast(k.HumanoidRootPart.Position,k.HumanoidRootPart.Position-v);
            if not raycastRes then
                inRoom = true;
                pName = k.Name;
                break;
            end
        end
    end
    if inRoom then
        ToastNotif.new({
            text = pName.." is in the room, so you won't be teleported",
            duration = 20
        });
        return;
    end
    teleport(v)
end});



risky:AddToggle({text="Inf Treadmill Stamina",callback=function(toggle)
    if not toggle then return; end
    if not loaded() then return; end
    local key = getKey(plr.Backpack.LocalS);
    if key then
        local action = plr.Backpack.Action;
        repeat
            action:FireServer(key,"RunToggle",{[1] = true,[2] = false});
            task.wait();
            action:FireServer(key,"RunToggle",{false});
            task.wait(0.3)
        until not library.flags.infTreadmillStamina;
    end
end});

risky:AddToggle({text="Inf Rhythm", tip = "Makes your rhythm inf, makes a cloud under your feet" ,callback=function(toggle)
    if not toggle then return; end
    if not loaded() then return; end

    local key = getKey(plr.Backpack.LocalS);
    if not key then library.options.infRhythm:SetState(false); return; end

    local action = plr.Backpack.Action;
    action:FireServer(key, "RhythmStance", true);
    repeat
        task.wait(0.1);
    until not library.flags.infRhythm;
    action:FireServer(key, "RhythmStance", false);
end});

risky:AddToggle({text="Inf Dashes",callback=function(toggle)
    if not toggle then return; end
    if not loaded() then return; end
    local env = getsenv(plr.Backpack.LocalS);
    repeat
        task.wait(0.1)
        setupvalue(env.Dash,2,3);
        setupvalue(env.Dash,3,"");
    until not library.flags.infDashes;
end});

local constantNum = table.find(getconstants(env.Dash),"FireServer");

risky:AddToggle({text="No Stam Dashes",callback=function(toggle)
    if not toggle then setconstant(getsenv(plr.Backpack.LocalS).Dash,constantNum,"FireServer") return; end

    setconstant(getsenv(plr.Backpack.LocalS).Dash,constantNum,"GetChildren");
end});

risky:AddButton({text='Respawn',callback=function()
    if not loaded() then return; end
    char:BreakJoints();
end});

risky:AddButton({text='Respawn Back',callback=function()
    if not loaded() then return; end
    teleport(char.HumanoidRootPart.CFrame);
end});

risky:AddButton({text="Teleport Tourney of 100",callback=function()
    TeleportService:Teleport(6320657368);
end});

risky:AddButton({text="Teleport Private Server",callback=function()
    TeleportService:Teleport(6745592527);
end});

local whiteStats = {
    ["BodyFatigue"] = true;
    ["PrimaryStyle"] = true;
    ["Calories"] = true;
    ["Reputation"] = true;
    ["Trait"] = true;
    ["LowerBodyMuscle"] = true;
    ["UpperBodyMuscle"] = true;
    ["Karma"] = true;
    ["MightyCoins"] = true;
    ["BankMoney"] = true;
    ["Money"] = true;
    ["Stamina"] = true;
    ["BodyHeat"] = true;
    ["Rhythm"] = true;
    ["Stomach"] = true;
    ["Height"] = true;
    ["RunningSpeed"] = true;
    ["Fat"] = true;
    ["SkillPoints"] = true;
    ["Logged"] = true;
    ["Banned"] = true;
    ["Durability"] = true;
    ["StrikingPower"] = true;
    ["StrikingSpeed"] = true;
};
local function statfunction(p5,p6)
    if not whiteStats[p5] then return; end
    if p5 == "UpperBodyMuscle" then
        p5 = "UpperMuscle";
    elseif p5 == "LowerBodyMuscle" then
        p5 = "LowerMuscle";
    elseif p5 == "RunningSpeed" then
        p5 = "RunSpeed";
    end
    local val;
    if tonumber(p6) ~= nil then
        val = tostring(round(p6,3));
    elseif typeof(p6) == "table" then
        val = tostring(round(p6[1],3));
    else
        if typeof(p6) == 'function' then return; end

        val = tostring(p6);
    end

    if not StatT[p5] then
        StatT[p5] = StatV:AddLabel(string.format("%s: %s",p5,val));
    else
        StatT[p5].Text = string.format("%s: %s",p5,val);
    end
end

for i,v in next, getconnections(Events.UpdateStats.OnClientEvent) do
    if not v.Function then
        return;
    end
    if string.match(debug.getinfo(v.Function,'s').short_src,"LocalS") then
        updateStat = v.Function;
    end
end

for i,v in next, getupvalues(updateStat) do
    if typeof(v) == 'table' then
        for t,k in next, v do
            statfunction(t,k);
        end
        break;
    end
end


Events.UpdateStats.OnClientEvent:Connect(statfunction)
task.spawn(function()
    while task.wait(1) do
        if not loaded() then return; end
        if not ffc(char,"MaxStamina") then return; end
        statfunction("Stamina",char.MaxStamina.Value-100);
        statfunction("BodyHeat",char.BodyHeat.Value);
        statfunction("Rhythm",char.Rhythm.Value);
    end
end);

--Auto Parry Tab
local parryAnims = {
    ["rbxassetid://7009320896"]={["Guardbreak"]=false},
    ["rbxassetid://5087462384"]={["Guardbreak"]=false},
    ["rbxassetid://6501739912"]={["Guardbreak"]=false},
    ["rbxassetid://6704457409"]={["Guardbreak"]=false},
    ["rbxassetid://6718814119"]={["Guardbreak"]=false},
    ["rbxassetid://5029356929"]={["Guardbreak"]=false},
    ["rbxassetid://6930761828"]={["Guardbreak"]=false},
    ["rbxassetid://5087464114"]={["Guardbreak"]=false},
    ["rbxassetid://5029359784"]={["Guardbreak"]=false},
    ["rbxassetid://7876039532"]={["Guardbreak"]=false},
    ["rbxassetid://5810497127"]={["Guardbreak"]=false},
    ["rbxassetid://7891093418"]={["Guardbreak"]=false},
    ["rbxassetid://6930758587"]={["Guardbreak"]=false},
    ["rbxassetid://5110868660"]={["Guardbreak"]=false},
    ["rbxassetid://7877241063"]={["Guardbreak"]=false},
    ["rbxassetid://6550835152"]={["Guardbreak"]=false},
    ["rbxassetid://6604546413"]={["Guardbreak"]=false},
    ["rbxassetid://6875783564"]={["Guardbreak"]=false},
    ["rbxassetid://5052660577"]={["Guardbreak"]=false},
    ["rbxassetid://7877246443"]={["Guardbreak"]=false},
    ["rbxassetid://8594975706"]={["Guardbreak"]=false},
    ["rbxassetid://5865529031"]={["Guardbreak"]=false},
    ["rbxassetid://5116608619"]={["Guardbreak"]=false},
    ["rbxassetid://5110454001"]={["Guardbreak"]=false},
    ["rbxassetid://5092035643"]={["Guardbreak"]=false},
    ["rbxassetid://5869781872"]={["Guardbreak"]=false},
    ["rbxassetid://5110500012"]={["Guardbreak"]=false},
    ["rbxassetid://5645707634"]={["Guardbreak"]=false},
    ["rbxassetid://6718812539"]={["Guardbreak"]=false},
    ["rbxassetid://6194195462"]={["Guardbreak"]=false},
    ["rbxassetid://5110724393"]={["Guardbreak"]=false},
    ["rbxassetid://6930759930"]={["Guardbreak"]=false},
    ["rbxassetid://5883810295"]={["Guardbreak"]=false},
    ["rbxassetid://4918348016"]={["Guardbreak"]=false},
    ["rbxassetid://5092037778"]={["Guardbreak"]=false},
    ["rbxassetid://5052449595"]={["Guardbreak"]=false},
    ["rbxassetid://5087459369"]={["Guardbreak"]=false},
    ["rbxassetid://5873100725"]={["Guardbreak"]=false},
    ["rbxassetid://6573164932"]={["Guardbreak"]=false},
    ["rbxassetid://6566644368"]={["Guardbreak"]=false},
    ["rbxassetid://7791575394"]={["Guardbreak"]=false},
    ["rbxassetid://6360102363"]={["Guardbreak"]=false},
    ["rbxassetid://6719137742"]={["Guardbreak"]=false},
    ["rbxassetid://5052435233"]={["Guardbreak"]=false},
    ["rbxassetid://7876328758"]={["Guardbreak"]=false},
    ["rbxassetid://6875731587"]={["Guardbreak"]=false},
    ["rbxassetid://5126044328"]={["Guardbreak"]=false},
    ["rbxassetid://7887536058"]={["Guardbreak"]=false},
    ["rbxassetid://6674659296"]={["Guardbreak"]=false},
    ["rbxassetid://7130763680"]={["Guardbreak"]=false},
    ["rbxassetid://5092042225"]={["Guardbreak"]=false},
    ["rbxassetid://5110453274"]={["Guardbreak"]=false},
    ["rbxassetid://6360098898"]={["Guardbreak"]=false},
    ["rbxassetid://6704318501"]={["Guardbreak"]=false},
    ["rbxassetid://5870608112"]={["Guardbreak"]=false},
    ["rbxassetid://5126071335"]={["Guardbreak"]=false},
    ["rbxassetid://6257267175"]={["Guardbreak"]=false},
    ["rbxassetid://10234589242"]={["Guardbreak"]=false},--Tiger Hunt
    ["rbxassetid://10234603041"]={["Guardbreak"]=true},--Snake Bite
    ["rbxassetid://10261951458"]={["Guardbreak"]=false},--Dragon Claw
    ["rbxassetid://5594891491"]={["Guardbreak"]=false}, --Bear Hug
    ["rbxassetid://7819569583"]={["Guardbreak"]=false}, --BlastCore
    ["rbxassetid://4901795168"]={["Guardbreak"]=true}, --brawl GB
    ["rbxassetid://4973374984"]={["Guardbreak"]=true}, --Thai GB
    ["rbxassetid://5016575571"]={["Guardbreak"]=true}, --Karate gb
    ["rbxassetid://6169229434"]={["Guardbreak"]=true}, --Wrestling GB
    ["rbxassetid://5016611308"]={["Guardbreak"]=true}, --Sumo GB
    ["rbxassetid://6538829055"]={["Guardbreak"]=true}, --Taek GB
    ["rbxassetid://6585959296"]={["Guardbreak"]=true}, --Raishin GB
    ["rbxassetid://6194191510"]={["Guardbreak"]=true}, --Kure GB
    ["rbxassetid://4918356164"]={["Guardbreak"]=true}, --Boxing GB
    ["rbxassetid://6169361647"]={["Guardbreak"]=true} --Karate GB
}

local guardBreak ={
    ["Corkscrew"] = true,
    ["Blast Core"] = true,
    ["Flying Knee"] = true,
    ["Axe Kick"] = true,
    ["Tiger Bite"] = true,
    ["Reverse Heel"] = true,
    ["Solid Strike"] = true,
    ["Jolt Hook"] = true,
    ["Flying Side Kick"] = true,
    ["Sumo Throw"] = true,
    ["Bear Hug"] = true,
    ["Shoulder Bash"] = true,
    ["Forearm Smash"] = true,
    ["Suplex"] = true,
    ["Elbow Drop"]  = 0.1,
    ["Body Slam"] = true,
    ["Eye Slice"] = true,
}

local function blockAttack()
	local key = getKey(plr.Backpack.LocalS);
	if not key then return; end

	plr.Backpack.Action:FireServer(key, "Block", {true});
end

local function unblockAttack()
	local key = getKey(plr.Backpack.LocalS);
	if not key then return; end

	plr.Backpack.Action:FireServer(key, "Block", {false});
end

local function guardBreak()
	local key = getKey(plr.Backpack.LocalS);
	if not key then return; end

	plr.Backpack.Action:FireServer(key, "GuardBreak", {true});
end

local autoBlockMaid = Maid.new();

local function autoParry(v)
	if v == char then return; end

	local hrp = v:WaitForChild("HumanoidRootPart",10);
	local animator = v:WaitForChild("Humanoid",10) and v.Humanoid:WaitForChild("Animator",10);
	if not hrp or not animator then return; end

	autoBlockMaid:GiveTask(animator.AnimationPlayed:Connect(function(animationTrack)
		local combat = getStyle();
		local animation = animationTrack.Animation;
		local id = animation.AnimationId;
		local tool = ffcwia(v,"Tool");
		local willGuardbreak = tool and guardBreak[tool.Name];

		local distance = hrp.Parent and char and (hrp.Position-char.HumanoidRootPart.Position).magnitude;
		if not distance or distance > library.flags.autoParryRange or not parryAnims[id] or not (math.random(1,100) <= library.flags.autoParryChance) then return; end

		if willGuardbreak or parryAnims[id]["Guardbreak"] then
			if ffc(char,"Blocking") then return combat:Activate(); end --If we already blocking then just parry?

			if parryAnims[id]["Guardbreak"] then --Calculate speed
				task.wait(animationTrack.Speed/10);
			end

			blockAttack();

			if library.flags.autoCounter then guardBreak(); end --This allows us to counter while blocking

			combat:Activate();
			task.wait(0.4);
			unblockAttack();
			return; --We dont want to do anything else if they guardbreak
		end

		blockAttack();

		if library.flags.autoCounter then guardBreak(); end --This allows us to counter while blocking

		task.wait(0.4);
		unblockAttack();
	end))
end

local autoParrySettings = column2:AddSection("Auto Parry Settings");

autoParrySettings:AddToggle({text="Auto Parry",callback=function(toggle)
    if not toggle then autoBlockMaid:DoCleaning(); return; end

    for _,v in next, LivingThings:GetChildren() do
		task.spawn(autoParry,v);
    end

    autoBlockMaid:GiveTask(LivingThings.ChildAdded:Connect(autoParry));
end})

autoParrySettings:AddSlider({text="Auto Parry Range",value=18,min=1,max=30,float=0.1});
autoParrySettings:AddSlider({text="Auto Parry Chance",value=100,min=1,max=100,float=1});
autoParrySettings:AddToggle({text="Auto Counter"});

local function notifyWebhook(message)
    if library.flags.webhookUrl == '' then return error("Webhook URL must not be empty"); end
    syn.request({
        Url = library.flags.webhookUrl,
        Method = "POST";
        Headers = {
            ["Content-Type"] = "application/json";
        };
        Body = game.HttpService:JSONEncode({content = tostring(message)});
    })
end


local Notify = column2:AddSection("Notify/Kick Features");

local hungerDeb = false;
local fatigueDeb = false;

Notify:AddToggle({text="Auto Kick", noload = true, skipflag = true, callback=function(toggle)
    if not toggle then gMaid.autoKick = nil; return; end

    gMaid.autoKick = RunService.Stepped:Connect(function()

        if (library.flags.hunger and library.flags["hungerReaches%"] >= Stats.Hunger) or (library.flags.fatigue and library.flags["fatigueReaches%"] <= Stats.Fatigue) then
            plr:Kick("Kicked due to auto kick");
            gMaid.autoKick = nil;
        end
    end)
end})

Notify:AddToggle({text="Webhook Notify",callback=function(toggle)
    if not toggle then gMaid.autoNotify = nil; return; end

    local notifyDeb = tick();
    gMaid.autoNotify = RunService.Stepped:Connect(function()

        if tick() - notifyDeb < 0.5 then return; end
        notifyDeb = tick();

        if (library.flags.hunger and library.flags["hungerReaches%"] >= Stats.Hunger and not hungerDeb) then
            hungerDeb = true;

            notifyWebhook(string.format("Your hunger has reached %s @everyone",Stats.Hunger))
        elseif library.flags["hungerReaches%"] < Stats.Hunger and hungerDeb then
            hungerDeb = false;
        end

        if (library.flags.fatigue and library.flags["fatigueReaches%"] <= Stats.Fatigue and not fatigueDeb) then
            fatigueDeb = true;

            notifyWebhook(string.format("Your fatigue has reached %s @everyone",Stats.Fatigue))
        elseif library.flags["fatigueReaches%"] > Stats.Fatigue and fatigueDeb then
            fatigueDeb = false;
        end
    end)
end})


Notify:AddToggle({text="Hunger"});
Notify:AddSlider({text="Hunger Reaches %",value=0,min=0,max=100,float=0.1});

Notify:AddToggle({text="Fatigue"});
Notify:AddSlider({text="Fatigue Reaches %",value=0,min=0,max=100,float=0.1});

Notify:AddToggle({text="Killed",callback=function(toggle)
    if not toggle then gMaid.deadKick = nil; return; end

    gMaid.deadKick = char.Humanoid.Died:Connect(function()
        if not library.flags.autoKick then return; end
        plr.CharacterAdded:Wait();
        plr:Kick("Kicked due to auto kick");
        if library.flags.webhookNotify then
            notifyWebhook("You have been killed and auto kicked @everyone");
        end
    end)
end});

do --Street Fighter ESP/Notifier

    local function onStreetFighterAdded(streetFighter)
        if not streetFighter:WaitForChild("HumanoidRootPart",10) then return; end
        local streetFighterName = streetFighter:WaitForChild("Attached",1) and streetFighter.Attached:WaitForChild("FakeH",1) and streetFighter.Attached.FakeH:FindFirstChildWhichIsA("Model") and streetFighter.Attached.FakeH:FindFirstChildWhichIsA("Model").Name or "Street Fighter";

        local sfESP = streetESP.new(streetFighter.HumanoidRootPart, streetFighterName, nil, true);

        local connection;
        connection = streetFighter.AncestryChanged:Connect(function()
            if streetFighter:IsDescendantOf(game) then return; end

            sfESP:Destroy();
            connection:Disconnect();
        end);
    end

    local function sfDescendantAdded(instance)
        if not instance or instance.Name ~= "NPCModel" then return; end

        local streetFighter;

        while true do
            streetFighter = instance.Value;
            if streetFighter then break; end
            task.wait();
        end

        local streetFighterName = streetFighter:WaitForChild("Attached",1) and streetFighter.Attached:WaitForChild("FakeH",1) and streetFighter.Attached.FakeH:FindFirstChildWhichIsA("Model") and streetFighter.Attached.FakeH:FindFirstChildWhichIsA("Model").Name or "Street Fighter";
        onStreetFighterAdded(streetFighter);

        if not library.flags.streetFighterNotifier then return; end

        ToastNotif.new({text = "A Street Fighter has spawned: "..streetFighterName});
        if library.flags.webhookNotify then notifyWebhook("@everyone A Street Fighter has spawned: "..streetFighterName); end
    end

    Notify:AddToggle({text = "Street Fighter Notifier",callback=function(toggle)
        if not toggle then return; end

        sfDescendantAdded(ffc(workspace,"NPCModel",true))
    end})

    workspace.DescendantAdded:Connect(sfDescendantAdded);
end

do --Behelit ESP/Notifier
    local function onBehelitAdded(model)
        local espObject = behelitESP.new(model:GetPivot(), "Behelit Necklace", nil, true);

        local connection;
        connection = model.AncestryChanged:Connect(function()
            if (not model.Parent) then
                espObject:Destroy();
                connection:Disconnect();
            end
        end);
    end

    local function bhDescendantAdded(instance)
        if not instance or instance.Name ~= "BehelitMODEL" then return; end

        onBehelitAdded(instance);

        if not library.flags.behelitNotifier then return; end

        ToastNotif.new({text = "A Behelit has spawned!!!"});
        if library.flags.webhookNotify then notifyWebhook("@everyone A Behelit Necklace has spawned"); end
    end

    Notify:AddToggle({text = "Behelit Notifier",callback=function(toggle)
        if not toggle then return; end

        bhDescendantAdded(ffc(workspace,"BehelitMODEL",true))
    end})

    workspace.DescendantAdded:Connect(bhDescendantAdded);
end
--Notify webhook code is so bad...

Notify:AddBox({text="Webhook URL"});

Notify:AddButton({text="Test Webhook",callback = function()
    notifyWebhook("This is a test!");
end});

end)

a();

task.spawn(function()
    --Mod Check
    for _,v in next, Players:GetPlayers() do
        checkIfMod(v)
    end
end)


getgenv().autoParryDebug = false;
_G.legitMove = legitMove;
_G.GuiRan = true;
