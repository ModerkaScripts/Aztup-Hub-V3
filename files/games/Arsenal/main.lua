local library = sharedRequire('../../UILibrary.lua');

local Utility = sharedRequire('../../utils/Utility.lua');
local Maid = sharedRequire('../../utils/Maid.lua');
local Services = sharedRequire('../../utils/Services.lua');
local ControlModule = sharedRequire('../../classes/ControlModule.lua');

local FindFirstChild, FindFirstChildWhichIsA = game.FindFirstChild, game.FindFirstChildWhichIsA;
local IsA = game.IsA;

local column1, column2 = unpack(library.columns);

local RunService = Services:Get('RunService');
local LocalPlayer = Services:Get('Players').LocalPlayer;
local Heartbeat = RunService.Heartbeat;

local toggleFly;
local toggleNoClip;
local jumpPower;

do --//GC Scan
    function Utility:getCharacter(player)
        local character = player.Character;
        if (not character or not FindFirstChild(character, 'Spawned')) then return end;

        local humanoid = FindFirstChildWhichIsA(character, 'Humanoid');

        local maxHealth = humanoid and humanoid.MaxHealth or 100;
        local health = humanoid and humanoid.Health or 100;
        local floatHealth = (health / maxHealth) * 100;

        return player.Character, maxHealth, floatHealth, math.floor(health);
    end;

    do --//Bypass anti cheat
        local oldSpawn;

        oldSpawn = hookfunction(spawn, newcclosure(function(f)
            local Constants = getconstants(f)
            if(table.find(Constants, 'BeanBoozled')) then
                return wait(9e9)
            end

            return oldSpawn(f)
        end))

        local clientEnv;
        local clientEnvTwo;

        for i,v in next, getgc(true) do
            if(clientEnv and clientEnvTwo) then
                break;
            end;

            if(typeof(v) == 'function' and islclosure(v) and not is_synapse_function(v)) then
                local Env = getfenv(v);

                if(rawget(Env, 'ammocount')) then
                    clientEnv = Env;
                end;
            elseif(typeof(v) == 'table' and rawget(v, 'firebullet')) then
                clientEnvTwo = v;
            end;
        end;

        local oldFireBullet = clientEnvTwo.firebullet;
        clientEnvTwo.firebullet = function(...)
            if(library.flags.infiniteAmmo) then
                clientEnv.ammocount.Value = 100;
            end;

            return oldFireBullet(...);
        end;
    end

    local maid = Maid.new();
    local BodyVelocity;

    function toggleFly(toggle)
        if(not toggle) then
            if(BodyVelocity) then
                BodyVelocity:Destroy();
                BodyVelocity = nil;
            end;
            return;
        end;

        local BodyVelocity = Instance.new('BodyVelocity');

        repeat
            local RootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Head');
            local Camera = workspace.CurrentCamera;
            local moveVector = ControlModule:GetMoveVector();

            if(RootPart and Camera) then
                BodyVelocity.Parent = RootPart;
                BodyVelocity.Velocity = Camera.CFrame:VectorToWorldSpace(moveVector * library.flags.flySpeed);
                BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
            end;

            Heartbeat:Wait();
        until not library.flags.fly;

        BodyVelocity.Parent = nil;
    end;

    function toggleNoClip(toggle)
        if(not toggle) then return end;

        repeat
            local Character = LocalPlayer.Character;
            if(Character) then
                for i, v in next, Character:GetDescendants() do
                    if(v:IsA("BasePart")) then
                        v.CanCollide = false;
                    end;
                end;
            end;
            RunService.Stepped:Wait();
        until not library.flags.noClip;
    end;

    function jumpPower(toggle)
        if (not toggle) then
            maid.jumpPower = nil;
            return;
        end;

        maid.jumpPower = RunService.Heartbeat:Connect(function()
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
            if (not humanoid) then return end;

            warn('woo', library.flags.jumpPowerValue);

            humanoid.JumpPower = library.flags.jumpPowerValue;
        end);
    end;

    local oldNamecall;
    local oldIndex;
    local oldNewIndex;

    local rayCastSpoofs = 0;

    oldNamecall = hookmetamethod(game, '__namecall', function(self, ...)
        SX_VM_CNONE();
        if(checkcaller()) then return oldNamecall(self, ...) end;

        local method = getnamecallmethod();
        local caller = getcallingscript();

        if(method == 'FindPartOnRayWithIgnoreList' and library.flags.silentAim and caller and caller.Name == 'Client' and rayCastSpoofs < 250) then
            rayCastSpoofs = rayCastSpoofs + 1;
            local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
            local character = Utility:getClosestCharacter();

            character = character and character.Character;
            local head = character and character.FindFirstChild(character, 'Head');

            if(character and head) then
                return head, (head.Position - rootPart.Position).Unit;
            end;
        end;

        return oldNamecall(self, ...);
    end);

    oldIndex = hookmetamethod(game, '__index', function(self, p)
        SX_VM_CNONE();
        if(checkcaller()) then return oldIndex(self, p) end;

        if(p == 'Touched' and IsA(self, 'BasePart') and library.flags.silentAim) then
            local function ConnectTouched(self, f)
                local Character = Utility:getClosestCharacter();
                Character = Character and Character.Character;
                local Head = Character and Character.FindFirstChild(Character, 'Head');

                if(Character and Head) then
                    return f(Head);
                end;
            end;

            return {
                Connect = ConnectTouched;
                connect = ConnectTouched;
            };
        end;

        return oldIndex(self, p);
    end);

    oldNewIndex = hookmetamethod(game, '__newindex', function(self, p, v)
        SX_VM_CNONE();
        if(checkcaller() or not IsA(self, 'Humanoid')) then return oldNewIndex(self, p, v) end;

        if(p == 'WalkSpeed' and library.flags.walkspeed) then
            v = library.flags.walkspeedValue;
        elseif (p == 'JumpPower' and library.flags.jumpPower) then
            v = library.flags.jumpPowerValue;
        end;

        return oldNewIndex(self, p, v);
    end);

    task.spawn(function()
        while task.wait(2) do
            rayCastSpoofs = 0;
        end;
    end);
end;

local Character = column1:AddSection('Character')
local Gun = column2:AddSection('Gun');

Character:AddToggle({
    text = 'Walkspeed'
}):AddSlider({flag = 'Walkspeed Value', min = 16, max = 500});

Character:AddToggle({
    text = 'Jump Power',
    callback = jumpPower
}):AddSlider({flag = 'Jump Power Value', min = 50, max = 500});

Character:AddToggle({
    text = 'Fly',
    callback = toggleFly
}):AddSlider({flag = 'Fly Speed', min = 16, max = 500});

Character:AddToggle({
    text = 'No Clip',
    callback = toggleNoClip
});

Gun:AddToggle({
    text = 'Infinite Ammo'
});

Gun:AddToggle({
    text = 'Silent Aim'
});