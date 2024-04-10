local Services = sharedRequire('../../utils/Services.lua');
local library = sharedRequire('../../UILibrary.lua');
local ToastNotif = sharedRequire('@classes/ToastNotif.lua');

local column1, column2 = unpack(library.columns);

local Players, ReplicatedStorage, TweenService, RunService, TeleportService = Services:Get('Players', 'ReplicatedStorage', 'TweenService', 'RunService', 'TeleportService');

local LocalPlayer = Players.LocalPlayer;

print("RO GHOUL FOUND!");

local ClientControl
repeat
    print("Waiting for game to start ...");
    ClientControl = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("ClientControl");
    task.wait(0.5);
until ClientControl and not ClientControl.Disabled

local PlayerTeam = LocalPlayer.PlayerFolder.Customization.Team.Value
local toggleAutoFarm
local toggleCashOutReputation
local toggleAutoFocus
local toggleAutoTrainer

do --//Utility
    local RemoteKey
    for i, v in next, getgc() do
        if (typeof(v) == "function") then
            local Constants = not is_synapse_function(v) and islclosure(v) and getconstants(v)
            if (Constants and table.find(Constants, "KeyEvent")) then
                RemoteKey = Constants[table.find(Constants, "KeyEvent") + 1]
                break;
            end;
        end;
    end;

    if (not RemoteKey or typeof(RemoteKey) ~= "string") then
        print(RemoteKey);
        return LocalPlayer:Kick("\nError 404-A(RoGhoul). Make a support ticket if that happens again!");
    end;

    print("GotKey", RemoteKey);
    local tweenSpeed = 100;

    local function isMobInSafeZone(rootPart)
        local rayCastParams = RaycastParams.new();
        rayCastParams.FilterType = Enum.RaycastFilterType.Whitelist;
        rayCastParams.FilterDescendantsInstances = {workspace.SafeZones};

        local Result = workspace:Raycast(rootPart.Position, Vector3.new(0, -25, 0), rayCastParams) and true or false;
        if (Result) then
            warn("MOB IN SAFEZONE!");
        end;

        return Result;
    end;

    local function canAttack(Mob)
        if (string.find(Mob.Name, "Investigator") and library.flags.focusInvestigator) then
            return true;
        elseif (string.find(Mob.Name, "Aogiri") and library.flags.focusAogiri) then
            return true;
        elseif (Mob.Parent.Name == "HumanSpawns" and library.flags.focusHuman) then
            return true;
        elseif (Mob.Parent.Name == "BossSpawns" and library.flags.focusBoss) then
            return true;
        end;

        return false;
    end;

    local function canAttackQuest(Mob, questTarget)
        if (string.find(Mob.Name, "Investigator") and string.find(questTarget, "Investigator")) then
            return true;
        elseif (string.find(Mob.Name, "Aogiri") and string.find(questTarget, "Aogiri")) then
            return true;
        elseif (Mob.Parent.Name == "HumanSpawns" and string.find(questTarget, "Human")) then
            return true;
        end;

        return false;
    end

    local function getClosestMob()
        local currentMob, currentDistance, mobIsBoss = nil, math.huge, false;
        local MyRootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;

        local prioritys = {
            Eto = library.flags.etoPriority,
            Koutarou = library.flags.koutarouPriority,
            Nishiki = library.flags.nishikiPriority
        }

        local AllMobs = {};

        for i, v in next, workspace.NPCSpawns:GetChildren() do
            local isMob = v:FindFirstChildOfClass("Model")
            if (isMob and MyRootPart) then
                local root = isMob and isMob.PrimaryPart
                local mobDistance = root and (root.Position - MyRootPart.Position).Magnitude

                if (mobDistance and not isMobInSafeZone(root)) then
                    table.insert(
                        AllMobs,
                        {
                            mob = isMob,
                            mobDistance = mobDistance,
                            root = root,
                            isBoss = v.Name == "BossSpawns"
                        }
                    )
                end
            end
        end

        local highest = 0
        local targetBoss = nil

        for _, Mob in next, AllMobs do
            if (Mob.isBoss) then
                for priorityBoss, priorityValue in next, prioritys do
                    if (Mob.mob.Name:find(priorityBoss) and highest < priorityValue and priorityValue > 0) then
                        highest = priorityValue
                        targetBoss = Mob
                    end
                end
            end
        end

        if (targetBoss and library.flags.focusBoss) then
            return targetBoss.mob, targetBoss.mobDistance, MyRootPart
        end

        if (library.flags.toggleAutoQuest) then
            local questTarget, questTargetObject = nil, nil
            local maxTarget, currentTarget = 1, 0

            local CurrentQuest = LocalPlayer.PlayerFolder.CurrentQuest

            for i, v in next, CurrentQuest.Complete:GetChildren() do
                if (v.Name ~= "Reward") then
                    questTarget = v.Name
                    questTargetObject = v
                end
            end

            if (questTargetObject) then
                currentTarget, maxTarget = questTargetObject.Value, questTargetObject.Max.Value
            end

            if (questTarget == nil or maxTarget == currentTarget) then
                local myTeam = PlayerTeam == "CCG" and "Yoshitoki" or "Yoshimura"
                local reputationPostion = workspace:FindFirstChild(myTeam, true):GetPrimaryPartCFrame().p

                local myRoot = MyRootPart
                local distanceFrom = (myRoot.Position - reputationPostion).Magnitude
                repeat
                    myRoot = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
                    if (myRoot) then
                        distanceFrom = (myRoot.Position - reputationPostion).Magnitude
                        TweenService:Create(
                            myRoot,
                            TweenInfo.new(distanceFrom / tweenSpeed),
                            {CFrame = CFrame.new(reputationPostion)}
                        ):Play()
                    end
                    wait(0.5)
                until myRoot and (myRoot.Position - reputationPostion).Magnitude <= 25
                wait(2.5)
                for i = 1, 2 do
                    print(ReplicatedStorage.Remotes[myTeam].Task:InvokeServer())
                    wait(2.5)
                end
            end

            for i, v in next, LocalPlayer.PlayerFolder.CurrentQuest.Complete:GetChildren() do
                if (v.Name ~= "Reward") then
                    questTarget = v.Name
                end
            end

            local currentMob, currentDistance = nil, math.huge

            for _, Mob in next, AllMobs do
                local MobHumanoid = Mob.mob:FindFirstChildOfClass("Humanoid")

                if (Mob and MobHumanoid and MobHumanoid.Health > 25 and canAttackQuest(Mob.mob, questTarget)) then
                    if (Mob.mobDistance < currentDistance) then
                        currentMob, currentDistance, mobIsBoss = Mob.mob, Mob.mobDistance, Mob.isBoss
                    end
                end
            end

            if (currentMob) then
                return currentMob, currentDistance, MyRootPart
            end
        end

        for _, Mob in next, AllMobs do
            local MobHumanoid = Mob.mob:FindFirstChildOfClass("Humanoid")

            if (Mob and MobHumanoid and MobHumanoid.Health > 25 and canAttack(Mob.mob)) then
                if (Mob.mobDistance < currentDistance) then
                    currentMob, currentDistance, mobIsBoss = Mob.mob, Mob.mobDistance, Mob.isBoss
                end
            end
        end

        return currentMob, currentDistance, MyRootPart, mobIsBoss
    end

    local lastMobAttack = 0
    local function mobIsDead(Mob)
        if (tick() - lastMobAttack >= 60) then
            return true
        else
            local MobRoot = Mob and Mob.PrimaryPart
            if (Mob.Parent == nil) then
                print("Mob Not In Workspace")
                return true
            elseif (MobRoot and MobRoot.Position.Y <= 25) then
                return true
            elseif (Mob:FindFirstChild(Mob.Name .. " Corpse")) then
                return true, true
            end
        end
    end

    local function eatCorpse(clickPart)
        print('Found corpse');

        for _ = 1, 5 do
            pcall(fireclickdetector, clickPart);
            task.wait(0.1);
        end;
    end;

    local function FireServer(...)
        local Character = LocalPlayer.Character
        local Remotes = Character and Character:FindFirstChild("Remotes")
        local KeyEvent = Remotes and Remotes:FindFirstChild("KeyEvent")

        if (KeyEvent) then
            KeyEvent:FireServer(RemoteKey, ...)
        end
    end

    local BodyVelocity
    local function createBodyVelocity(MyRootPart)
        if (BodyVelocity and BodyVelocity.Parent ~= MyRootPart) then
            BodyVelocity:Destroy()
            BodyVelocity = nil
        end

        BodyVelocity = BodyVelocity or Instance.new("BodyVelocity")
        BodyVelocity.Velocity = Vector3.new()
        BodyVelocity.Parent = MyRootPart
    end

    local KaguneStages = {
        [0] = "Zero",
        [1] = "One",
        [2] = "Two",
        [3] = "Three",
        [4] = "Four",
        [5] = "Five",
        [6] = "Six",
        [7] = "Seven",
        [8] = "Eight",
        [9] = "Nine"
    }

    local autoFarmWorkings = {}
    autoFarmWorkings.autoFarm = false
    autoFarmWorkings.cashoutReputation = false
    autoFarmWorkings.autoTrainer = false

    local currentTween;

    local lastCashout = 0

    function autoFarmWorkings:all(exclude)
        for i, v in next, autoFarmWorkings do
            if (typeof(v) == "boolean" and v and i ~= exclude) then
                return true
            end
        end
    end

    function autoFarmWorkings:queue(autoFarmType)
        print("QUEUE STARTED!");

        autoFarmWorkings[autoFarmType] = true;
        repeat wait(); until not autoFarmWorkings:all(autoFarmType);

        print("QUEUE FINISHED!");
    end

    local function tweenTeleport(rootPart, position)
        local tweenInfo = TweenInfo.new((rootPart.Position - position).Magnitude / 100, Enum.EasingStyle.Linear);
        local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(position)});

        tween:Play();
        tween.Completed:Wait();
    end;

    function toggleAutoFarm(toggle)
        if (not toggle) then
            if(BodyVelocity) then
                BodyVelocity:Destroy();
                BodyVelocity = nil;
            end;

            if (currentTween) then
                currentTween:Cancel()
                currentTween = nil
            end
            return
        end

        repeat
            local Mob, MobDistance, MyRootPart, mobIsBoss = getClosestMob()

            if (Mob and MyRootPart and not autoFarmWorkings:all("autoFarm")) then
                autoFarmWorkings.autoFarm = true
                createBodyVelocity(MyRootPart)
                local tweenInfo = TweenInfo.new(MobDistance / tweenSpeed)
                lastMobAttack = tick()

                local Tween =
                    TweenService:Create(
                    MyRootPart,
                    tweenInfo,
                    {
                        CFrame = CFrame.new(Mob.PrimaryPart.CFrame.p)
                    }
                )
                Tween:Play()
                currentTween = Tween

                repeat
                    RunService.Heartbeat:Wait();
                until mobIsDead(Mob) or Tween.PlaybackState ~= Enum.PlaybackState.Playing or not library.flags.toggleAutoFarm;

                if (not library.flags.toggleAutoFarm) then
                    if (currentTween) then
                        currentTween:Cancel();
                        currentTween = nil;
                    end;

                    autoFarmWorkings.autoFarm = false;
                    return;
                end;

                if (Tween.PlaybackState == Enum.PlaybackState.Completed) then
                    local lastFire = 0;

                    repeat
                        local Character = LocalPlayer.Character;
                        local MyRootPart = Character and Character.PrimaryPart;
                        local mobRoot = Mob.PrimaryPart;

                        if (MyRootPart and mobRoot) then
                            createBodyVelocity(MyRootPart);
                            MyRootPart.CFrame = CFrame.new(mobRoot.CFrame * (mobRoot.CFrame.LookVector * 2.5)) * CFrame.new(0, 5, 0) * CFrame.Angles(math.rad(-90), 0, 0);

                            if (not (Character:FindFirstChild("Kagune") or Character:FindFirstChild("Katana") or Character:FindFirstChild("Quinque"))) then
                                FireServer(KaguneStages[library.flags.kaguneStage or 1], 'Down', nil, 'ShiftLock', workspace.CurrentCamera.CFrame);
                                wait(2)
                            elseif (tick() - lastFire >= 0.1) then
                                FireServer('Mouse1', 'Down', nil, 'ShiftLock', workspace.CurrentCamera.CFrame);

                                if (mobIsBoss) then
                                    FireServer('E', 'Down', nil, 'ShiftLock', workspace.CurrentCamera.CFrame);
                                    FireServer('R', 'Down', nil, 'ShiftLock', workspace.CurrentCamera.CFrame);
                                    FireServer('F', 'Down', nil, 'ShiftLock', workspace.CurrentCamera.CFrame);
                                end;

                                lastFire = tick();
                            end;
                        end;

                        if (not library.flags.toggleAutoFarm) then
                            return;
                        end;
                        RunService.Heartbeat:Wait();
                    until mobIsDead(Mob) or not library.flags.toggleAutoFarm;
                end;

                if (not library.flags.toggleAutoFarm) then
                    autoFarmWorkings.autoFarm = false;
                    return;
                end;

                local isDead, canEat = mobIsDead(Mob);

                if (isDead and canEat and library.flags.eatCorpse) then
                    wait(0.5);
                    local MobCorpse = Mob:FindFirstChild(Mob.Name .. " Corpse");
                    local clickPart = MobCorpse and MobCorpse:FindFirstChildWhichIsA("ClickDetector", true);

                    if(clickPart) then
                        tweenTeleport(MyRootPart, clickPart.Parent.Position);
                        eatCorpse(clickPart);
                    else
                        print('no click part!');
                    end;

                    print(clickPart);
                    wait(0.2);
                end

                autoFarmWorkings.autoFarm = false;
            end
            wait(0.5);
        until not library.flags.toggleAutoFarm;
    end;

    function toggleCashOutReputation(toggle)
        if (not toggle) then
            return;
        end;

        repeat
            if (tick() - lastCashout >= 3600 and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart) then
                autoFarmWorkings:queue("cashoutReputation")
                print("HEY IM CASHOUT IM DOING MY STUFF END IN 10SEC")

                local myTeam = PlayerTeam == "CCG" and "Yoshitoki" or "Yoshimura"
                local reputationPostion = workspace:FindFirstChild(myTeam, true):GetPrimaryPartCFrame().p

                local myRoot = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
                local distanceFrom = (myRoot.Position - reputationPostion).Magnitude
                repeat
                    myRoot = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart
                    if (myRoot) then
                        distanceFrom = (myRoot.Position - reputationPostion).Magnitude
                        TweenService:Create(
                            myRoot,
                            TweenInfo.new(distanceFrom / tweenSpeed),
                            {CFrame = CFrame.new(reputationPostion)}
                        ):Play()
                    end
                    wait(0.5)
                until myRoot and (myRoot.Position - reputationPostion).Magnitude <= 25
                wait(2.5)
                ReplicatedStorage.Remotes.ReputationCashOut:InvokeServer()
                lastCashout = tick()
                wait(2.5)
                autoFarmWorkings.cashoutReputation = false
                print("HEY IM CASHOUT I'VE DONE THE STUFF")
                wait(1)
            else
                print(string.format("CASHOUT CAN ONLY CASH OUT IN %s SECONDS", 3600 - (tick() - lastCashout)))
            end
            wait(1)
        until not library.flags.cashoutReputation
    end

    local allFocusTypes = {
        "Physical",
        "Kagune",
        "Durability",
        "Speed"
    }

    local function convert(value)
        if (value == "Kagune") then
            return "Weapon"
        end

        return value
    end

    function toggleAutoFocus(t)
        if (not t) then
            return
        end
        repeat
            local totalFocusPoint = 0

            for i, v in next, allFocusTypes do
                totalFocusPoint = totalFocusPoint + library.flags[string.lower(v)]
            end

            local playerFocus = tonumber(LocalPlayer.PlayerFolder.Stats.Focus.Value) or 0

            if (playerFocus >= totalFocusPoint) then
                for i, v in next, allFocusTypes do
                    LocalPlayer.PlayerFolder.StatsFunction:InvokeServer(
                        "Focus",
                        convert(v) .. "AddButton",
                        library.flags[string.lower(v)]
                    )
                end
            end
            wait(0.25)
        until not library.flags.toggleAutoFocus
    end

    RunService.Stepped:Connect(function()
        local Character = LocalPlayer.Character
        if (Character and (library.flags.toggleAutoFarm or library.flags.cashoutReputation)) then
            for i, v in next, Character:GetChildren() do
                if (v:IsA("BasePart")) then
                    v.CanCollide = false
                end
            end
        end
    end)

    local oldNamecall;
    oldNamecall = hookmetamethod(game, '__namecall', function(...)
        SX_VM_CNONE();
        local method = getnamecallmethod();
        local self = ...;

        if(typeof(self) ~= 'Instance') then
            return oldNamecall(...);
        end;

        if(method == 'Destroy' and tostring(self) == 'TSCodeVal' and library.flags.toggleAutoTrainer) then
            local Caller = getfenv(2).script;
            local Trainer = Caller.TrainingSession.Value;

            delay(1, function()
                Trainer.Comm.FireServer(Trainer.Comm, 'Finished', self.Value, false);
                autoFarmWorkings.autoTrainer = false;
            end);
        end;

        return oldNamecall(...);
    end);

    function toggleAutoTrainer(t)
        if (not t) then
            return
        end

        repeat
            autoFarmWorkings:queue('autoTrainer');
            local data = ReplicatedStorage.Remotes.Trainers.RequestTraining:InvokeServer(LocalPlayer.PlayerFolder.Trainers[PlayerTeam .. "Trainer"].Value);
            print(data, data == nil, data == '');
            if(data ~= nil) then
                autoFarmWorkings.autoTrainer = false;
            end;
            wait(10)
        until not library.flags.toggleAutoTrainer
    end

    function setDataloss(t)
        pcall(function()
            local spawnLocationValue = LocalPlayer.PlayerFolder.Settings.SpawnLocation;
            local currentSpawn = spawnLocationValue.Value:gsub('\128', '');

            originalFunctions.fireServer(ReplicatedStorage.Remotes.Settings.SpawnSelection, t and string.format('%s\128', currentSpawn) or currentSpawn);

            spawnLocationValue:GetPropertyChangedSignal('Value'):Once(function()
                print('oui')
                spawnLocationValue.Value = currentSpawn;
            end);

            ToastNotif.new({
                text = t and 'Dataloss set' or 'Dataloss unset'
            });
        end);
    end;
end

do --//Render Gui
    local AutoFarm = column1:AddSection('Auto Farm');
    local AutoFocus = column2:AddSection("Auto Focus");
    local AutoTrainer = column2:AddSection("Auto Trainer");
    local Dataloss = column2:AddSection('Dataloss');

    AutoFarm:AddToggle({text = "Toggle Auto Farm", callback = toggleAutoFarm})
    AutoFarm:AddToggle({text = "Focus Investigator"})
    AutoFarm:AddToggle({text = "Focus Aogiri"})
    AutoFarm:AddToggle({text = "Focus Human"})
    AutoFarm:AddToggle({text = "Focus Boss"})
    AutoFarm:AddToggle({text = "Toggle Auto Quest"})
    AutoFarm:AddToggle({text = "CashOut Reputation", callback = toggleCashOutReputation})
    AutoFarm:AddToggle({text = "Eat Corpse"})

    AutoFarm:AddSlider({text = "Kagune Stage", min = 1, max = 6})
    AutoFarm:AddSlider({text = "Eto Priority", value = 3, min = 0, max = 3})
    AutoFarm:AddSlider({text = "Koutarou Priority", value = 2, min = 0, max = 3})
    AutoFarm:AddSlider({text = "Nishiki Priority", min = 0, max = 3})

    AutoFocus:AddToggle({text = "Toggle Auto Focus", callback = toggleAutoFocus})
    AutoFocus:AddSlider({text = "Physical",  min = 1, max = 10})
    AutoFocus:AddSlider({text = "Kagune", min = 1, max = 10})
    AutoFocus:AddSlider({text = "Durability", min = 1, max = 10})
    AutoFocus:AddSlider({text = "Speed", min = 1, max = 10})

    AutoTrainer:AddToggle({text = "Enable", flag = "Toggle Auto Trainer", callback = toggleAutoTrainer})

    Dataloss:AddButton({
        text = 'Set dataloss',
        callback = function() setDataloss(true) end
    });


    Dataloss:AddButton({
        text = 'Unset dataloss',
        callback = function() setDataloss(false) end
    });

    Dataloss:AddButton({
        text = 'Rejoin',
        callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId); end
    })
end