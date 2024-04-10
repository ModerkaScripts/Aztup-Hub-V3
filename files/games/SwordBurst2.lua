local Services = sharedRequire('../utils/Services.lua');
local library = sharedRequire('../UILibrary.lua');

local column1, column2 = unpack(library.columns);

local Players, ReplicatedStorage, RunService, TweenService = Services:Get(
    'Players',
    'ReplicatedStorage',
    'RunService',
    'TweenService'
);

local Heartbeat = RunService.Heartbeat;
local LocalPlayer = Players.LocalPlayer;

local toggleAutoAttack;
local toggleAutoFarm;

do -- // Functions
    local framework;
    do -- grab framework
        for i, v in next, getgc(true) do
            if(typeof(v) == 'table' and rawget(v, 'Services')) then
                framework = v.Services;
            end;
        end;

        if(not framework) then
            return LocalPlayer:Kick('Error Occured -> A. Dm Aztup. Do not dm if you are in the lobby just do not execute the script in the lobby');
        end;
    end;

    local function getClosestTarget(respectFlags)
        local myRootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
        if(not myRootPart) then return end;

        debug.profilebegin('Get Closest Target');

        local closestDistance = math.huge;
        local closestTarget = nil;

        if(respectFlags) then
            if(library.flags.targetMobs) then
                for _, mob in next, workspace.Mobs:GetChildren() do
                    if(mob.PrimaryPart and (mob.PrimaryPart.Position - myRootPart.Position).Magnitude <= closestDistance and mob:FindFirstChild('Entity') and mob.Entity.Health.Value > 0) then
                        closestDistance = (mob.PrimaryPart.Position - myRootPart.Position).Magnitude;
                        closestTarget = mob;
                    end;
                end;
            end;

            if(library.flags.targetPlayers) then
                for _, player in next, game.Players:GetChildren() do
                    if(player ~= LocalPlayer and player.Character and player.Character.PrimaryPart and (player.Character.PrimaryPart.Position - myRootPart.Position).Magnitude <= closestDistance) then
                        closestDistance = (player.Character.PrimaryPart.Position - myRootPart.Position).Magnitude;
                        closestTarget = player.Character;
                    end;
                end;
            end;
        else
            for _, mob in next, workspace.Mobs:GetChildren() do
                if(mob.PrimaryPart and (mob.PrimaryPart.Position - myRootPart.Position).Magnitude <= closestDistance and mob.Entity.Health.Value > 0) then
                    closestDistance = (mob.PrimaryPart.Position - myRootPart.Position).Magnitude;
                    closestTarget = mob;
                end;
            end;
        end;

        debug.profileend();

        return closestTarget, closestDistance, myRootPart;
    end;

    local staticCombatKeys = getupvalue(framework.Combat.Init, 2);

    local bodyVelocity = Instance.new('BodyVelocity');
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);

    function toggleAutoAttack(toggle)
        if(not toggle) then return end;

        while(library.flags.toggleAutoAttack) do
            local target, targetDistance = getClosestTarget(true);

            if(target and targetDistance <= 25) then
                ReplicatedStorage.Event:FireServer('Combat', staticCombatKeys, {'Attack', nil, "1", target});
                task.wait((11 - library.flags.autoAttackSpeed) * 0.15);
            end;

            task.wait();
        end;
    end;

    function toggleAutoFarm(toggle)
        while(library.flags.toggleAutoFarm) do
            debug.profilebegin('Auto Farm');
            local target, targetDistance, myRootPart = getClosestTarget();

            if(target and myRootPart) then
                bodyVelocity.Parent = myRootPart;
                TweenService:Create(myRootPart, TweenInfo.new(targetDistance / 50), {CFrame = target.PrimaryPart.CFrame + Vector3.new(0, 5, 0)}):Play();
            end;

            debug.profileend();
            Heartbeat:Wait();
        end;

        bodyVelocity.Parent = nil;
    end;
end;

local AutoFarm = column1:AddSection('Auto Farm')
local AutoAttack = column2:AddSection('Auto Attack')

AutoAttack:AddToggle({text = 'Toggle Auto Attack', callback = toggleAutoAttack});
AutoAttack:AddToggle({text = 'Target Players'});
AutoAttack:AddToggle({text = 'Target Mobs', state = true});
AutoAttack:AddSlider({text = 'Auto Attack Speed', min = 1, max = 10})

AutoFarm:AddToggle({text = 'Toggle Auto Farm', callback = toggleAutoFarm});