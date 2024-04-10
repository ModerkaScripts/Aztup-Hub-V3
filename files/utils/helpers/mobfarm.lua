local Utility = sharedRequire('@utils/Utility.lua');
local Services = sharedRequire('@Utils/Services.lua');
local Maid = sharedRequire('@utils/Maid.lua');
local library = sharedRequire('@UILibrary.lua');

local TweenService, RunService = Services:Get('TweenService', 'RunService');
local mobfarmHelper = {};
local allTweens = {};

function mobfarmHelper:getClosest(folder, options)
    assert(typeof(options) == 'table');
    options.maxDistance = options.maxDistance or math.huge;

    local rootPart = options.rootOverride or Utility:getPlayerData().rootPart;
    if (not rootPart) then return nil; end;

    local closestDistance, closestMob = math.huge, nil;

    for _, child in next, typeof(folder) == 'table' and folder or folder:GetChildren() do
        local mobRoot = options.getRoot and options.getRoot(child) or child:FindFirstChild('HumanoidRootPart');
        if (not mobRoot) then continue end;
        if (options.isAlive and not options.isAlive(child)) then continue end;
        if (options.filter and not options.filter(child)) then continue end;

        local distance = (rootPart.Position - mobRoot.Position).Magnitude;
        if (options.prioritize and options.prioritize(child)) then return child, distance; end;

        if (distance < closestDistance and distance <= options.maxDistance) then
            closestDistance = distance;
            closestMob = child;
        end;
    end;

    return closestMob, closestDistance;
end;

function mobfarmHelper:tweenTeleport(goalCFrame, options)
    local rootPart = Utility:getPlayerData().rootPart;
    if (not rootPart) then return false; end;

    if (typeof(goalCFrame) == 'Vector3') then
        goalCFrame = CFrame.new(goalCFrame);
    end;

    options = options or {};
    options.tweenSpeed = options.tweenSpeed or library.flags.tweenSpeed or 100;
    options.offset = options.offset or CFrame.identity*goalCFrame.Rotation;

    if (options.instant) then
        options.tweenSpeed = 5000;
    end;

    mobfarmHelper.noPhysics(options);
    local maid = Maid.new();

    local distance = (rootPart.Position - goalCFrame.Position).Magnitude;

    if (options.tweenSpeedIgnoreY) then
        distance = Utility:roundVector(rootPart.Position - goalCFrame.Position).Magnitude;
    end;

    local tweenInfo = TweenInfo.new(distance / options.tweenSpeed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);
    local tween = TweenService:Create(rootPart, tweenInfo, {
        CFrame = goalCFrame * options.offset
    });

    allTweens[tween] = tween;
    maid:GiveTask(RunService.Heartbeat:Connect(function()
        mobfarmHelper.noPhysics(options);
    end));

    maid:GiveTask(function()
        allTweens[tween] = nil;
    end);

    maid:GiveTask(tween.Completed:Connect(function()
        maid:Destroy();
    end));

    tween:Play();
    return tween;
end;

function mobfarmHelper.noPhysics(options)
    local playerData = Utility:getPlayerData();
    local rootPart = playerData.rootPart;
    for _, part in next, playerData.parts do
        part.CanCollide = false;
    end;

    rootPart.CFrame = CFrame.new(rootPart.CFrame.Position) * options.offset.Rotation;
    if (not rootPart or rootPart:FindFirstChild('NoPhysics')) then return end;

    local bodyVelocity = Instance.new('BodyVelocity');
    bodyVelocity.Name = 'NoPhysics';
    bodyVelocity.MaxForce = Vector3.one * math.huge;
    bodyVelocity.Velocity = Vector3.zero;
    bodyVelocity.Parent = rootPart;
end;

function mobfarmHelper.destroyTweens()
    for i, v in next, allTweens do
        v:Cancel();
        allTweens[i] = nil;
    end;
end;

function mobfarmHelper.turnOffAutoFarm()
    mobfarmHelper.destroyTweens();
    mobfarmHelper.destroyNoPhysics();
end;

function mobfarmHelper.destroyNoPhysics()
    local playerData = Utility:getPlayerData();
    local rootPart = playerData.rootPart;
    if (not rootPart or not rootPart:FindFirstChild('NoPhysics')) then return end;

    rootPart.NoPhysics:Destroy();
end;

return mobfarmHelper;