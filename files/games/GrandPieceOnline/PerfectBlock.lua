local library = sharedRequire('@UILibrary.lua');

local Maid = sharedRequire('@utils/Maid.lua');
local Utility = sharedRequire('@utils/Utility.lua');
local Services = sharedRequire('@utils/Services.lua');
local TextLogger = sharedRequire('@classes/TextLogger.lua');
local prettyPrint = sharedRequire('@utils/prettyPrint.lua');

local animLogger = TextLogger.new({
    title = 'Auto Parry Helper Logger',
	buttons = {'Copy Animation Id', 'Add To Ignore List', 'Test'}
});


local Players, MarketplaceService = Services:Get('Players', 'MarketplaceService');
local LocalPlayer = Players.LocalPlayer;

local maid = Maid.new();

local PerfectBlock = {};
PerfectBlock.__index = PerfectBlock;

local IsA = game.IsA;

local parryMaid = Maid.new();
local animTimes = {};
local animationNames = {};
local ignoredAnimations = {'5517298834', '10001707271';  '11093531300', '6043954920', '7075728341', '10001705684', '507765644', '4563261864', '2095054253', '9984793787', '5796457289', '4126956669', '5796460384'};

local myRootPart;

task.spawn(function()
    while true do
        myRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
        task.wait();
    end;
end);

if (debugMode) then
    animLogger:SetVisible(true);

    animLogger.OnClick:Connect(function(btnName, ctx)
        if (btnName == 'Copy Animation Id') then
            setclipboard(ctx.animationId);
        elseif (btnName == 'Add To Ignore List') then
            if (table.find(ignoredAnimations, ctx.animationId)) then return end;
            table.insert(ignoredAnimations, ctx.animationId);
        elseif (btnName == 'Test') then
            animTimes[ctx.animationId] = _G.perfectBlockTime or 0;
        end;
    end);

    getgenv().animTimes = animTimes;
    getgenv().ignoredAnimations = ignoredAnimations;
    getgenv().copyIgnoreAnimations = function()
        setclipboard(prettyPrint(ignoredAnimations));
    end;

    library.flags.chatLoggerAutoScroll = true;
end;

animTimes['5746701412'] = 0; -- Fishman Karate Punch
animTimes['4760307723'] = 0.3; -- Pistol Aim

animTimes['11382679819'] = 0; -- Some Katana Slash
animTimes['4087684389'] = 0; -- Default Punch

local function parry(t, root, anim, maxRange)
    if (t ~= 0) then
        task.wait(t);
    end;
    keypress(0x46);
    task.wait(0.5);
    keyrelease(0x46);
end;


local function calculatePingWait(n)
    -- local playerPing = Stats.PerformanceStats.Ping:GetValue()/1000;
    -- n -= (playerPing*(library.flags.pingAdjustmentPercentage/100));

    return n;
end;

local function parryAttack(timings,rootPart,animationTrack,maxRange,useAnimSpeed)
    warn(" CALLED PARRY ATTACK!!!!!")

    _G.canAttack = false;

    local solved = false;

    local function getAllTimings(t, index)
        local total = 0;

        for i = index, 1, -1 do
            total += t[i];
        end;

        return total;
    end;

    local endIndex = #timings;

    for i in next, timings do
        task.spawn(function()
            local convertedWait = calculatePingWait(getAllTimings(timings, i)/(useAnimSpeed and animationTrack.Speed or 1));

            local waited = parry(convertedWait,rootPart,animationTrack,maxRange);
            -- warn("WE WAITED "..waited,"CURRENT TIME|"..convertedWait);

            if (i == endIndex) then
                solved = true;
            end;
        end);
    end;

    repeat
        task.wait();
    until solved;

    _G.canAttack = true;
end

function PerfectBlock.new(character)
    if (character == LocalPlayer.Character) then return end;

    local self = setmetatable({
        _character = character,
        _name = character.Name,
        _maid = Maid.new(),
        _isPlayer = Players:FindFirstChild(character.Name)
    }, PerfectBlock);

    self._maid:GiveTask(character:GetPropertyChangedSignal('Parent'):Connect(function()
        local newParent = character.Parent;
        if (newParent == nil) then return self:Destroy() end;
    end));

    self._maid:GiveTask(Utility.listenToChildAdded(character, function(obj)
        if (obj.Name == 'HumanoidRootPart') then
            self._rootPart = obj;
            self:_onHumanoidAdded(); -- We call it here cause we want AnimationPlayed to be listened if there is rootPart
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

function PerfectBlock:_onHumanoidAdded()
    if (not self._rootPart or not self._humanoid) then return end;
    local humanoid = self._humanoid;

    self._maid[humanoid] = humanoid.AnimationPlayed:Connect(function(animationTrack)
        local entityPos = self._rootPart and self._rootPart.Position;
        if (not entityPos or not myRootPart) then return end;
        if ((entityPos - myRootPart.Position).Magnitude >= 150) then return end;
        -- if (library.flags.autoParryWhitelist[self._name]) then return end;

        -- local autoParryMode = library.flags.autoParryMode;

        -- if (not autoParryMode.All) then
        --     if (autoParryMode.Mobs and self._isPlayer and not autoParryMode.Players) then
        --         return
        --     end;
        --     if (autoParryMode.Players and not self._isPlayer and not autoParryMode.Mobs) then
        --         return;
        --     end;
        -- end;

        if (library.flags.checkIfFacingTarget) then
            local dotProduct = (entityPos - myRootPart.Position):Dot(myRootPart.CFrame.LookVector);
            if (dotProduct <= 0) then return print('Not parrying player is not facing target') end;
        end;

        if (library.flags.checkIfTargetFaceYou) then
            local dotProduct = (myRootPart.Position - entityPos):Dot(self._rootPart.CFrame.LookVector);
            if (dotProduct <= 0) then return print('Not parrying target is not facing player') end;
        end;

        local animId = animationTrack.Animation.AnimationId:match('%d+');
        local waitTime = animTimes[animId];
        local maxRange = getgenv().defaultRange or 20;

        local animName = animationNames[animId];

        if (debugMode and not table.find(ignoredAnimations, animId)) then
            if (not animName) then
                animationNames[animId] = '?';
                task.spawn(function()
                    animationNames[animId] = MarketplaceService:GetProductInfo(tonumber(animId), Enum.InfoType.Asset).Name;
                end);
            end;

            animLogger:AddText({
                animationId = animId,
                text = string.format('Animation played %s | %s from %s %s', animId, animationNames[animId], self._name, waitTime and 'has' or 'dont have')
            });
        end;

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
    end);
end;

function PerfectBlock:_onHumanoidRemoved()
    local humanoid = self._humanoid;
    if (not humanoid) then return end;
    self._maid[humanoid] = nil;
end;

function PerfectBlock:Destroy()
    self._maid:Destroy();
end;

local function init(t)
    if (not t) then
        parryMaid:DoCleaning();
        maid.autoParryOnNewCharacter = nil;
        maid.autoParryOnNewCharacter2 = nil;
        return;
    end;

    maid.autoParryOnNewCharacter = Utility.listenToChildAdded(workspace.NPCs, PerfectBlock);
    maid.autoParryOnNewCharacter2 = Utility.listenToChildAdded(workspace.PlayerCharacters, PerfectBlock);
end;

return init;