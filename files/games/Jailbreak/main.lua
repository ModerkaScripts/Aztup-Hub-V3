local library = sharedRequire('../../UILibrary.lua');

local Maid = sharedRequire('../../utils/Maid.lua');
local Services = sharedRequire('../../utils/Services.lua');
local Utility = sharedRequire('../../utils/Utility.lua');

local ControlModule = sharedRequire('../../classes/ControlModule.lua');

local column1, column2 = unpack(library.columns);

local Players, ReplicatedStorage, RunService, CollectionService, UserInputService = Services:Get(
    'Players',
    'ReplicatedStorage',
    'RunService',
    'CollectionService',
    'UserInputService'
);

local LocalPlayer = Players.LocalPlayer;
local playerMouse = LocalPlayer:GetMouse();

function Utility:isTeamMate(player)
    local playerTeam = (player.Team.Name == 'Criminal' or player.Team.Name == 'Prisoner') and 'Criminal' or 'Police';
    local myTeam = (LocalPlayer.Team.Name == 'Criminal' or LocalPlayer.Team.Name == 'Prisoner') and 'Criminal' or 'Police';

    return myTeam == playerTeam;
end;

local maid = Maid.new();
local functions = {};

local setupRobberyStates;

do -- // Functions
    local circleActionModule = require(ReplicatedStorage.Module.UI).CircleAction;
    local alexChassis = require(ReplicatedStorage.Module.AlexChassis);
    local vehicle = require(ReplicatedStorage.Game.Vehicle);
    local vehicleSystem = require(ReplicatedStorage.Game.VehicleSystem)
    local playerUtils = require(ReplicatedStorage.Game.PlayerUtils);
    local boat = require(ReplicatedStorage.Game.Boat.Boat);
    local militaryTurretUtils = require(ReplicatedStorage.Game.MilitaryTurret.MilitaryTurretUtils);
    local cargoShipTurret = require(ReplicatedStorage.Game.Robbery.CargoShip.Turret);
    local gun = require(ReplicatedStorage.Game.Item.Gun);
    local dartDispenser = require(ReplicatedStorage.Game.DartDispenser.DartDispenser);
    local robberyConsts = require(ReplicatedStorage.Robbery.RobberyConsts);
    local militaryIsland = require(ReplicatedStorage.Game.MilitaryIsland);

    local robberyStates = ReplicatedStorage.RobberyState;

    local jetPack = getupvalue(require(ReplicatedStorage.Game.JetPack.JetPack).Init, 9);

    local oldIsPointInTag = playerUtils.isPointInTag;
    local oldGetLocalVehiclePacket = vehicle.GetLocalVehiclePacket;
    local oldHeartbeatLocal = jetPack.HeartbeatLocal;
    local oldUpdateStepped = alexChassis.UpdatePrePhysics;
    local oldUpdatePhysics = boat.UpdatePhysics;
    local oldGetNearestNonPolice = militaryTurretUtils.getNearestNonPolice;
    local oldShoot = cargoShipTurret.Shoot;
    local oldInputBegan = gun.InputBegan;
    local oldDartFire = dartDispenser._fire;

    local killBricks;
    local allKillBrics;
    local nitroData;
    local allDoors, canOpenDoor, openDoor;

    do -- // Get Network & Other Stuff
        local network;

        for i, v in next, getgc(true) do
            if (typeof(v) == 'table') then
                if (rawget(v, 'FireServer')) then
                    network = v;
                elseif (rawget(v, 'NitroLastMax')) then
                    nitroData = v;
                end;
            elseif (typeof(v) == 'function' and not is_synapse_function(v) and islclosure(v)) then
                local constants = getconstants(v);

                if(table.find(constants, 'hasKey')) then
                    canOpenDoor = v;
                elseif(table.find(constants, 'AwaitingDoorClose') and table.find(constants, 'GetTagged')) then
                    allDoors = getupvalue(v, 4);
                elseif(table.find(constants, 'SequenceRequireState')) then
                    openDoor = v;
                end;
            end;
        end;

        assert(network);

        local realFireServer = getupvalue(network.FireServer, 1);
        local antiCheatBypassed = false;

        setupvalue(network.FireServer, 1, function(fireId, ...)
            local fireArgs = {...};
            local traceback = debug.traceback();

            print(traceback);
            if(#fireArgs == 2 and fireArgs[2] == false and not antiCheatBypassed) then
                antiCheatBypassed = true;
                return;
            elseif(#fireArgs == 0 and string.find(traceback, 'Museum') and library.flags.noMuseumDetection) then
                return;
            end;

            return realFireServer(fireId, ...);
        end);

        function playerUtils.isPointInTag(pointPosition, tag)
            if(tag == 'NoFallDamage' and library.flags.antiFallDamage) then return true end;
            if(tag == 'NoRagdoll' and library.flags.antiRagdoll) then return true end;

            return oldIsPointInTag(pointPosition, tag);
        end;

        oldCanOpenDoor = hookfunction(canOpenDoor, function(...)
            if (library.flags.unlockDoors) then
                return true;
            end;

            return oldCanOpenDoor(...);
        end);

        function vehicle.GetLocalVehiclePacket(...)
            if(string.find(debug.traceback(), 'toggleEquip') and library.flags.carWeapons) then
                return false;
            end;

            return oldGetLocalVehiclePacket(...);
        end;

        function jetPack:HeartbeatLocal(...)
            oldHeartbeatLocal(self, ...);

            if (library.flags.infJetpackFuel) then
                self.Fuel = self.MaxFuel;
            end;
        end;

        function alexChassis:UpdateStepped(delta)
            if (not self._backup) then
                self._backup = {
                    speed = self.GarageEngineSpeed,
                    height = self.Height,
                    turnSpeed = self.TurnSpeed
                };
            end;

            if (library.flags.enginePower ~= 0) then
                self.GarageEngineSpeed = library.flags.enginePower;
            else
                self.GarageEngineSpeed = self._backup.speed;
            end;

            if (library.flags.heightPower ~= 0) then
                self.Height = library.flags.heightPower;
            else
                self.Height = self._backup.height;
            end;

            if (library.flags.turnSpeed ~= 0) then
                self.TurnSpeed = library.flags.turnSpeed / 10;
            else
                self.TurnSpeed = self._backup.turnSpeed;
            end;

            return oldUpdateStepped(self, delta);
        end;

        function boat:UpdatePhysics()
            if (not self.oldConfig) then
                self.oldSpeed = self.Config.SpeedForward;
            end;

            if (library.flags.boatSpeed) then
                self.Config.SpeedForward = library.flags.boatSpeed;
            else
                self.Config.SpeedForward = self.oldSpeed;
            end;

            return oldUpdatePhysics(self);
        end;

        function militaryTurretUtils.getNearestNonPolice(...)
            local player = oldGetNearestNonPolice(...);
            if (player == LocalPlayer and library.flags.disableTurrets) then return end;

            return player;
        end;

        function cargoShipTurret:Shoot()
            if (library.flags.disableTurrets) then return end;

            return oldShoot(self);
        end;

        function gun:InputBegan(inputObject, gpe)
            if (inputObject.UserInputType == Enum.UserInputType.MouseButton1) then

                repeat
                    if (library.flags.silentAim) then
                        local character = Utility:getClosestCharacter();
                        character = character and character.Character;

                        local head = character and character:FindFirstChild('Head');

                        if (head) then
                            self.TipDirection = (head.Position - self.Tip.Position).Unit;
                        end;
                    end;

                    if(self.SpringCamera and not self.SpringCamera.hooked) then
                        self.SpringCamera.hooked = true;
                        local oldAccelerate = self.SpringCamera.Accelerate;

                        function self.SpringCamera.Accelerate(...)
                            if (library.flags.gunMods) then
                                return;
                            end;

                            return oldAccelerate(...);
                        end;
                    end;

                    if (library.flags.gunMods) then
                        self.Config.BulletSpread = false;

                        -- self.inventoryItemValue:SetAttribute('AmmoCurrent', 10);
                        -- self.inventoryItemValue:SetAttribute('AmmoCurrentLocal', 10);
                        self.inventoryItemValue:SetAttribute('LastShoot', 0);
                    end;

                    oldInputBegan(self, inputObject, gpe);
                    task.wait();
                until inputObject.UserInputState == Enum.UserInputState.End or not library.flags.gunMods;
            else
                return oldInputBegan(self, inputObject, gpe);
            end;
        end;
    end;

    do -- // Setup Robbery State Listener
        function setupRobberyStates()
            local robberyStatesUI = column2:AddSection('Robbery States');
            local labels = {};

            local function onRobberyChange(v)
                local name = robberyConsts.PRETTY_NAME[tonumber(v.Name)];
                if (not labels[name]) then return warn(v.Name, 'no') end;

                local closed = v.Value == robberyConsts.ENUM_STATUS.CLOSED;
                labels[name].main.TextColor3 = closed and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0);
            end;

            local function onRobberyAdded(v)
                v:GetPropertyChangedSignal('Value'):Connect(function()
                    onRobberyChange(v);
                end);

                onRobberyChange(v);
            end;

            for i, v in next, robberyConsts.LIST_ROBBERY do
                if (v ~= 'HOME_VAULT') then
                    local name = robberyConsts.PRETTY_NAME[i];
                    local label = robberyStatesUI:AddLabel(name);
                    labels[name] = label;
                end;
            end;

            library.OnLoad:Connect(function()
                for i, v in next, labels do
                    v.main.TextColor3 = Color3.fromRGB(255, 0, 0);
                end;
                for i, v in next, robberyStates:GetChildren() do
                    onRobberyAdded(v);
                end;

                robberyStates.ChildAdded:Connect(onRobberyAdded);
            end);
        end;
    end;

    function functions.speedHack(toggle)
        if (not toggle) then
            maid.speedHack = nil;
            maid.speedBodyVelocity = nil;
            maid.flyBodyVelocity = nil;
            return;
        end;

        maid.speedHack = RunService.Stepped:Connect(function()
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            if (not rootPart) then return end;

            local camera = workspace.CurrentCamera;
            if(not camera) then return end;

            local bodyVelocity = maid.speedBodyVelocity or Instance.new('BodyVelocity');
            bodyVelocity.Parent = rootPart;
            bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000);
            bodyVelocity.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * library.flags.speedValue);

            maid.speedBodyVelocity = bodyVelocity;
        end);
    end;

    function functions.fly(toggle)
        if (not toggle) then
            maid.fly = nil;
            maid.flyBodyVelocity = nil;
            maid.speedBodyVelocity = nil;
            return;
        end;

        maid.fly = RunService.Stepped:Connect(function()
            local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
            if (not rootPart) then return end;

            local camera = workspace.CurrentCamera;
            if(not camera) then return end;

            local bodyVelocity = maid.flyBodyVelocity or Instance.new('BodyVelocity');
            bodyVelocity.Parent = rootPart;
            bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000);
            bodyVelocity.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * library.flags.flyValue);

            maid.flyBodyVelocity = bodyVelocity;
        end);
    end;

    function functions.jumpPower(toggle)
        if (not toggle) then
            maid.jumpPower = nil;

            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
            if (not humanoid) then return end;
            humanoid.JumpPower = 50;

            return;
        end;

        maid.jumpPower = RunService.Heartbeat:Connect(function()
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
            if (not humanoid) then return end;

            humanoid.JumpPower = library.flags.jumpPowerValue;
        end);
    end;

    function functions.noWait(toggle)
        if (not toggle) then
            maid.noWait = nil;
            return;
        end;

        maid.noWait = RunService.Heartbeat:Connect(function()
            if (not circleActionModule.Spec) then return end;
            circleActionModule.Spec.PressedAt = 0;
        end);
    end;

    function functions.clickDestroy(toggle)
        if (not toggle) then
            maid.clickDestroy = nil;
            return;
        end;

        maid.clickDestroy = UserInputService.InputBegan:Connect(function(input, gpe)
            if (input.UserInputType.Name ~= 'MouseButton1' or gpe) then return end;
            if (not playerMouse.Target or not playerMouse.Target:IsA('BasePart') or playerMouse.Target:IsA('Terrain')) then return end;

            playerMouse.Target:Destroy();
        end);
    end;

    local function addToKillBrick(obj)
        table.insert(killBricks, {object = obj, oldParent = obj.Parent});
        table.insert(allKillBrics, obj);
    end;

    function functions.removeKillBricks(toggle)
        if (not killBricks) then
            print('ran wooo');

            killBricks = {};
            allKillBrics = {};

            local killBricksNameList = {'BarbedWire', 'Lasers', 'LavaKill'};

            for i, v in next, workspace:GetDescendants() do
                if (table.find(killBricksNameList, v.Name)) then
                    addToKillBrick(v);
                end;
            end;

            for i, v in next, CollectionService:GetTagged('TombSpike') do
                addToKillBrick(v);
            end;

            workspace.DescendantAdded:Connect(function(v)
                if (not table.find(allKillBrics, v) and table.find(killBricksNameList, v.Name)) then
                    addToKillBrick(v);

                    if (library.flags.removeKillBricks) then
                        v.Parent = nil;
                    end;
                end;
            end);

            dartDispenser._fire = toggle and function() end or oldDartFire;
        end;

        for i, v in next, killBricks do
            v.object.Parent = not toggle and v.oldParent or nil;
        end;

        if (toggle) then
            militaryIsland.StopSpin();
        end;
    end;

    function functions.openAllDoors(toggle)
        if (not toggle) then
            maid.openAllDoors = nil;
            return;
        end;

        local lastOpenDoorAt = 0;

        maid.openAllDoors = RunService.Heartbeat:Connect(function()
            if (tick() - lastOpenDoorAt < 1) then return end;
            lastOpenDoorAt = tick();

            for i, v in next, allDoors do
                openDoor(v);
            end;
        end);
    end;

    function functions.infiniteNitro(toggle)
        if (not toggle) then
            maid.infiniteNitro = nil;
            return;
        end;

        maid.infiniteNitro = RunService.Heartbeat:Connect(function()
            nitroData.Nitro = 250;
            nitroData.NitroLastMax = 250;
            nitroData.NitroForceUIUpdate = true;
        end);
    end;

    function functions.jetSkiOnRoad(toggle)
        if (not toggle) then
            maid.jetSkiOnRoad = nil;

            local vehiclePacket = vehicleSystem.GetVehiclePacket(LocalPlayer);
            if not (vehiclePacket) then return end;
            vehiclePacket.WaterHeight = 0;

            return;
        end;

        maid.jetSkiOnRoad = RunService.Heartbeat:Connect(function()
            local vehiclePacket = vehicleSystem.GetVehiclePacket(LocalPlayer);
            if not (vehiclePacket) then return end;

            vehiclePacket.WaterHeight = 99999;
        end);
    end;
end;

do -- // Character
    local character = column1:AddSection('Character');

    character:AddToggle({
        text = 'Speed',
        callback = functions.speedHack
    }):AddSlider({
        text = 'Speed Value',
        textpos = 2,
        value = 16,
        min = 0,
        max = 100
    });

    character:AddToggle({
        text = 'Jump Power',
        callback = functions.jumpPower
    }):AddSlider({
        text = 'Jump Power Value',
        textpos = 2,
        value = 50,
        min = 0,
        max = 500
    });

    character:AddToggle({
        text = 'Fly',
        callback = functions.fly
    }):AddSlider({
        text = 'Fly Value',
        textpos = 2,
        value = 16,
        min = 0,
        max = 100
    });

    character:AddToggle({
        text = 'Anti Fall Damage'
    });

    character:AddToggle({
        text = 'Anti Ragdoll'
    });
end;

do -- // Utils
    local utils = column1:AddSection('Utils');

    utils:AddToggle({
        text = 'No Wait',
        callback = functions.noWait
    });

    utils:AddToggle({
        text = 'Click Destroy',
        callback = functions.clickDestroy
    });

    utils:AddToggle({
        text = 'No Museum Detection'
    });

    utils:AddToggle({
        text = 'Remove Kill Bricks',
        callback = functions.removeKillBricks
    });

    utils:AddToggle({
        text = 'Unlock Doors'
    });
end;

do -- // Combat
    local combat = column2:AddSection('Combat');

    combat:AddToggle({
        text = 'Silent Aim'
    });

    -- combat:AddToggle({
    --     text = 'Unlock All Gun Skins'
    -- });

    -- combat:AddToggle({
    --     text = 'Kill Aura'
    -- });

    -- combat:AddToggle({
    --     text = 'Taze Aura'
    -- });

    combat:AddToggle({
        text = 'Disable Turrets'
    });

    combat:AddToggle({
        text = 'Gun Mods'
    });
end;

do -- // Fun
    local fun = column1:AddSection('Fun');

    fun:AddToggle({
        text = 'Open All Doors',
        callback = functions.openAllDoors
    });
end;

do -- // Vehicle
    local vehicle = column2:AddSection('Vehicle');

    vehicle:AddToggle({
        text = 'Car Weapons'
    });

    vehicle:AddToggle({
        text = 'Inf Nitro',
        callback = functions.infiniteNitro
    });

    vehicle:AddToggle({
        text = 'Inf Jetpack Fuel'
    });

    vehicle:AddToggle({
        text = 'Jet Ski On Road',
        callback = functions.jetSkiOnRoad
    });

    vehicle:AddSlider({
        text = 'Engine Power',
        min = 0,
        max = 100,
        textpos = 2
    });

    vehicle:AddSlider({
        text = 'Height Power',
        min = 0,
        max = 100,
        textpos = 2
    });

    vehicle:AddSlider({
        text = 'Turn Speed',
        min = 0,
        max = 100,
        textpos = 2
    });

    vehicle:AddSlider({
        text = 'Boat Speed',
        min = 0,
        max = 100,
        textpos = 2
    });
end;

setupRobberyStates();