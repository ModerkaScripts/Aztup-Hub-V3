local Services = sharedRequire('@utils/Services.lua');
local library = sharedRequire('@UILibrary.lua');
local Maid = sharedRequire('@utils/Maid.lua');
local ControlModule = sharedRequire('@classes/ControlModule.lua');
local Utility = sharedRequire('@utils/Utility.lua');

local Players, UserInputService, Lighting, RunService = Services:Get('Players', 'UserInputService', 'Lighting', 'RunService');
local LocalPlayer = Players.LocalPlayer;

local basicsHelpers = {};

local chatFocused = false;
local maid = Maid.new();

UserInputService.TextBoxFocused:Connect(function()
    chatFocused = true;
end);

UserInputService.TextBoxFocusReleased:Connect(function()
    chatFocused = false;
end);

function basicsHelpers.infiniteJump(toggle)
    if(not toggle) then return end;

    repeat
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
        if(rootPart and UserInputService:IsKeyDown(Enum.KeyCode.Space) and not chatFocused) then
            rootPart.Velocity = Vector3.new(rootPart.Velocity.X, library.flags.infiniteJumpHeight, rootPart.Velocity.Z);
        end;
        task.wait(0.1);
    until not library.flags.infiniteJump;
end;

local lastFogDensity = 0;

function basicsHelpers.noFog(t)
    if not t then Lighting.Atmosphere.Density = lastFogDensity; maid.noFog = nil; return; end

    maid.noFog = Lighting.Atmosphere:GetPropertyChangedSignal('Density'):Connect(function()
        Lighting.Atmosphere.Density = 0;
    end);

    lastFogDensity = Lighting.Atmosphere.Density;
    Lighting.Atmosphere.Density = 0;
end

function basicsHelpers.noBlur(t)
    local dof = Lighting.DepthOfField;
    if not t then maid.noBlur = nil; dof.Enabled = true; return; end

    maid.noBlur = Lighting.DepthOfField:GetPropertyChangedSignal('Enabled'):Connect(function()
        if not dof.Enabled then return; end
        dof.Enabled = false;
    end);

    dof.Enabled = false;
end

local oldAmbient, oldBritghtness = Lighting.Ambient, Lighting.Brightness;

function basicsHelpers.fullBright(toggle)
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

function basicsHelpers.speedHack(toggle)
    if (not toggle) then
        maid.speedHack = nil;

        local humanoid = Utility:getPlayerData().humanoid;
        if (not humanoid) then return; end;
        humanoid.WalkSpeed = 16;

        return;
    end;

    maid.speedHack = RunService.Heartbeat:Connect(function()
        local humanoid = Utility:getPlayerData().humanoid;
        if (not humanoid) then return; end;

        humanoid.WalkSpeed = library.flags.speedHackValue
    end);
end;

function basicsHelpers.flyHack(toggle)
    if (not toggle) then
        maid.flyHack = nil;
        maid.flyBv = nil;
        return;
    end;

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

function basicsHelpers.noclip(toggle)
    if (not toggle) then
        maid.noclip = nil;

        local humanoid = Utility:getPlayerData().humanoid;
        if (not humanoid) then return end;

        humanoid:ChangeState('Physics');
        task.wait();
        humanoid:ChangeState('RunningNoPhysics');
        return;
    end;

    maid.noclip = RunService.Heartbeat:Connect(function()
        local parts = Utility:getPlayerData().parts;
        if (not parts) then return; end;

        for _, part in next, parts do
            part.CanCollide = false;
        end;
    end);
end;

return basicsHelpers;