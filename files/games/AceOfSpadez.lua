local library = sharedRequire('../UILibrary.lua');
local Services = sharedRequire('../utils/Services.lua');
local Utility = sharedRequire('../utils/Utility.lua');

local Players = Services:Get('Players');
local column1 = unpack(library.columns);

local LocalPlayer = Players.LocalPlayer;

local FindFirstChild = game.FindFirstChild;
local GetPlayers = Players.GetPlayers;

local Combat = column1:AddSection('Combat')
local GunMods = column1:AddSection('Gun Mods')

local camera = require(LocalPlayer.PlayerScripts.Main.Camera);

local oldRecoil;
oldRecoil = hookfunction(camera.Recoil, function(...)
    if (library.flags.noRecoil) then return end;
    return oldRecoil(...);
end);

function Utility:getCharacter(player)
    local character = player.Character;
    if (not character) then return end;

    local rootPart = FindFirstChild(character, 'HumanoidRootPart');
    if (not rootPart) then return end;

    local health = FindFirstChild(character, 'Health');
    if (not health) then return end;

    local maxHealth = health.Max.Value;
    local healthValue = health.Value;

    return character, maxHealth, (healthValue / maxHealth) * 100, math.floor(healthValue), rootPart;
end;

Combat:AddToggle({
    text = "Silent Aim",
})

Combat:AddToggle({
    text = "Melee Silent Aim"
})

GunMods:AddToggle({
    text = "No Recoil",
})

--// Silent Aim

local function getEnemies()
    local enemies = {};

    for i, v in next, GetPlayers(Players) do
        if(v.Character and v.Team and v.Team ~= LocalPlayer.Team and v.Team.Name ~= 'Spectators') then
            table.insert(enemies, v.Character);
        end;
    end;

    return enemies;
end;

local oldIndex;
local isA = game.IsA;

-- The game do customSpawn(func) inside of the bullet func so we can identify if it's the bullet function by checking if it's customSpawn
local function isBulletFunc()
    local s = debug.info(5, 's');

    if (s and s:find('Spawn')) then
        return true;
    end;
end;

local function getSilentAimPos()
    local rayParams = RaycastParams.new();
    rayParams.FilterType = Enum.RaycastFilterType.Whitelist;
    rayParams.FilterDescendantsInstances = {FindFirstChild(workspace.Game, 'Map'), getEnemies()};

    local target = Utility:getClosestCharacter(rayParams);
    target = target and target.Character;
    local hitPart = target and FindFirstChild(target, 'Head');

    if (hitPart) then
        return hitPart.Position;
    end;
end;

oldIndex = hookmetamethod(game, '__index', function(self, p)
    if (p == 'CFrame' and isA(self, 'Camera') and library.flags.silentAim and string.find(debug.traceback(), 'WeaponSystem')) then
        if (isBulletFunc()) then
            local pos = getSilentAimPos()
            return CFrame.new(oldIndex(self, p).Position, pos or oldIndex(self, p).LookVector);
        end;
    elseif (p == 'Position' and isA(self, 'Part') and library.flags.silentAim and string.find(debug.traceback(), 'WeaponSystem')) then
        if (isBulletFunc()) then
            return getSilentAimPos() or oldIndex(self, p);
        end;
    end;

    return oldIndex(self, p);
end);

local oldMathRandom;
oldMathRandom = hookfunction(math.random, function(n1, n2)
    local traceback = debug.traceback();
    if(string.find(traceback, 'TouchBullet') and library.flags.noSpread) then
        return 0;
    end;

    return oldMathRandom(n1, n2)
end);