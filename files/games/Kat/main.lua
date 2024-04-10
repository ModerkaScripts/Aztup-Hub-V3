local library = sharedRequire('../../UILibrary.lua');
local Utility = sharedRequire('../../utils/Utility.lua');

local Services = sharedRequire('../../utils/Services.lua');
local LocalPlayer = Services:Get('Players').LocalPlayer;

local column1 = unpack(library.columns);

do -- // Functions
    local whitelistedScripts = {'KnifeClient', 'RevolverClient'};
    local oldNamecall;

    oldNamecall = hookmetamethod(game, '__namecall', function(self, ...)
        SX_VM_CNONE();
        if(checkcaller()) then return oldNamecall(self, ...) end;

        if(getnamecallmethod() == 'FindPartOnRayWithIgnoreList' and library.flags.silentAim) then
            local caller = getcallingscript();
            local scriptName = typeof(caller) == 'Instance' and caller.Name;
            local method = getnamecallmethod();

            if(table.find(whitelistedScripts, scriptName)) then
                local args = {...};

                local target = Utility:getClosestCharacter();
                local myRoot = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
                local targetRoot = target and target.Character and target.Character.PrimaryPart;

                if(targetRoot and myRoot) then
                    args[1] = Ray.new(myRoot.Position, (targetRoot.Position - myRoot.Position).Unit * 2000);
                    return oldNamecall(self, unpack(args));
                end;

                setnamecallmethod(method);
            end;
        end;

        return oldNamecall(self, ...);
    end);
end;

local Combat = column1:AddSection('Combat')
Combat:AddToggle({text = 'Silent Aim'});