local Maid = sharedRequire('../../utils/Maid.lua');
local Services = sharedRequire('../../utils/Services.lua');
local library = sharedRequire('../../UILibrary.lua');
local Utility = sharedRequire('../../utils/Utility.lua');

local RunService, UserInputService = Services:Get('RunService', 'UserInputService');
local UserService = game:GetService('UserService');

local maid = Maid.new();

local Circle = Drawing.new('Circle');
local targetLine = Drawing.new('Line');

Circle.Transparency = 1;
Circle.Visible = false;
Circle.Color = Color3.fromRGB(255, 255, 255);
Circle.Radius = 100;
Circle.Thickness = 1;

targetLine = Drawing.new('Line');
targetLine.Visible = true;
targetLine.Transparency = 1;
targetLine.Thickness = 1;
targetLine.Color = Color3.fromRGB(255, 255, 255);

local function Aimbot(ended)
    if (ended) then
        maid.aimbot = nil;
        return;
    end;

    maid.aimbot = RunService.RenderStepped:Connect(function()
        if(not library) then
            maid.aimbot = nil;
            return;
        end;

        local Character = Utility:getClosestCharacter()
        Character = Character and Character.Character;
        if(not Character) then return end;

        local head = Character:FindFirstChild('Head');
        local hitPos = head and head.CFrame.Position;

        local Camera = workspace.CurrentCamera;
        if(not Camera) then return end;

        local aimPart = library.flags.aimPart;
        if(aimPart == 'Torso') then
            hitPos = hitPos - Vector3.new(0, 1.5, 0);
        elseif(aimPart == 'Leg') then
            hitPos = hitPos - Vector3.new(0, 3, 0);
        end;

        local hitPosition2D, visible = Camera:WorldToViewportPoint(hitPos);
        if (not visible) then return end;

        hitPosition2D = Vector2.new(hitPosition2D.X, hitPosition2D.Y);

        local mousePosition = UserInputService:GetMouseLocation();
        local final = (hitPosition2D - mousePosition) / (_G.test or 10);
        mousemoverel(final.X, final.Y);
    end);
end;

local function updateCircleProp(property)
    return function(value)
        if (property == "NumSides" and value == 50) then
            value = 500;
        elseif (property == "Filled" and library.flags.circleTransparency == 1) then
            library.flags.circleTransparency = 0.9;
            Circle.Transparency = 0.9;
        end
        Circle[property] = value;
    end;
end;

local function toggleRainbowCircle(toggle)
    if(not toggle) then
        maid.toggleRainbowCircle = nil;
        return;
    end;

    local circleColor = library.options.circleColor;

    maid.toggleRainbowCircle = RunService.RenderStepped:Connect(function()
        circleColor:SetColor(library.chromaColor);
    end);
end;

local function showCircle(toggle)
    Circle.Visible = toggle;

    if(not toggle) then
        maid.updateCirclePosition = nil;
        return;
    end;

    maid.updateCirclePosition = RunService.Heartbeat:Connect(function()
        -- if(library.flags.unlockCircle) then
            if(Circle) then
                Circle.Position = UserInputService:GetMouseLocation()
            end;
        -- else
        --     local camera = workspace.CurrentCamera;
        --     if(not camera) then return end;

        --     local cameraViewPortSize = camera.ViewportSize;
        --     local x = cameraViewPortSize.X / 2;
        --     local y = cameraViewPortSize.Y / 2;

        --     Circle.Position = Vector2.new(x, y);
        -- end;
    end);
end;

local Window = library:AddTab('Aimbot');
local section1 = Window:AddColumn();
local section2 = Window:AddColumn();
local aimbotSettings = section1:AddSection('Aimbot Settings');
local circleSettings = section2:AddSection('Circle Settings');
local aimbotWhitelist = section1:AddSection('Aimbot Whitelist');

do -- Render gui
    do -- // Circle Settings
        circleSettings:AddToggle({
            text = 'Show Circle',
            callback = showCircle
        }):AddColor({
            color = Color3.fromRGB(255, 0, 0),
            trans = 1,
            flag = 'Circle Color',
            calltrans = updateCircleProp('Transparency'),
            callback = updateCircleProp('Color')
        })

        circleSettings:AddToggle({
            text = 'Rainbow Circle',
            callback = toggleRainbowCircle
        })

        circleSettings:AddToggle({
            text = 'Fill Circle',
            callback = updateCircleProp('Filled')
        })

        circleSettings:AddSlider({
            text = 'Circle Shape',
            value = 50,
            min = 4,
            max = 50,
            float = 2,
            callback = updateCircleProp('NumSides')
        })

        circleSettings:AddSlider({
            text = 'Circle Thickness',
            value = 1,
            max = 50,
            callback = updateCircleProp('Thickness')
        });
    end;

    do -- // Aimbot Settings
        aimbotSettings:AddBind({
            text = 'Enable',
            flag = 'Toggle Aimbot',
            mode = 'hold',
            callback = Aimbot
        })

        aimbotSettings:AddSlider({
            text = 'Field Of View',
            flag = 'Aimbot F O V',
            min = 0,
            value = 100,
            max = 800,
            callback = updateCircleProp('Radius')
        })

        aimbotSettings:AddList({
            text = 'Aim Part',
            values = {'Head', 'Torso', 'Leg'}
        })

        aimbotSettings:AddToggle({
            text = 'Use Field Of View',
            flag = 'use F O V'
        })

        aimbotSettings:AddToggle({
            text = 'Visibility Check',
        })

        aimbotSettings:AddToggle({
            text = 'Check Team',
            state = true
        })
    end;

    do -- // Aimbot Whitelist
        local usersInfosByName = {};

        local function addPlayer(userId, isTextBox)
            if (not isTextBox) then
                userId = library.flags.aimbotWhitelistPlayers;
                userId = userId and userId.UserId;
            end;

            if (not userId) then return print('no user id', userId, isTextBox); end;

            local suc, userInfos = pcall(function()
                return UserService:GetUserInfosByUserIdsAsync({userId});
            end);

            if (not suc) then
                return warn(userInfos);
            end;

            local userInfo = userInfos[1];
            if (not userInfo) then return end;
            library.options.aimbotWhitelistedPlayers:AddValue(userInfo.Username);

            local aimbotWhitelistedPlayers = library.configVars.aimbotWhitelistedPlayers;

            if (not aimbotWhitelistedPlayers) then
                aimbotWhitelistedPlayers = {};
                library.configVars.aimbotWhitelistedPlayers = aimbotWhitelistedPlayers;
            end;

            if (not table.find(aimbotWhitelistedPlayers, userInfo.Id)) then
                table.insert(aimbotWhitelistedPlayers, userInfo.Id);
                usersInfosByName[userInfo.Username] = userInfo;
            end;
        end;

        local function removePlayer()
            local userInfo = usersInfosByName[library.flags.aimbotWhitelistedPlayers];
            if (not userInfo) then return end;

            library.options.aimbotWhitelistedPlayers:RemoveValue(userInfo.Username);
            local whitelistedPlayers = library.configVars.aimbotWhitelistedPlayers;

            table.remove(whitelistedPlayers, table.find(whitelistedPlayers, userInfo.Id));
        end;

        library.OnLoad:Connect(function()
            local whitelistedPlayers = library.configVars.aimbotWhitelistedPlayers or {};
            local userInfos = UserService:GetUserInfosByUserIdsAsync(whitelistedPlayers);

            for _, userInfo in next, userInfos do
                library.options.aimbotWhitelistedPlayers:AddValue(userInfo.Username);
                usersInfosByName[userInfo.Username] = userInfo;
            end;
        end);

        aimbotWhitelist:AddDivider('Add Player');
        aimbotWhitelist:AddList({text = 'Players', flag = 'Aimbot Whitelist Players', playerOnly = true, noSave = true});
        aimbotWhitelist:AddButton({text = 'Add Player', callback = addPlayer});

        aimbotWhitelist:AddDivider('Remove Player');
        aimbotWhitelist:AddList({text = 'Whitelisted Players', flag = 'Aimbot Whitelisted Players'});
        aimbotWhitelist:AddButton({text = 'Remove Player', callback = removePlayer});

        aimbotWhitelist:AddDivider('Advanced Whitelist');
        aimbotWhitelist:AddBox({text = 'Player UserId', flag = 'Aimbot Whitelist Player Box'});
        aimbotWhitelist:AddButton({text = 'Add Player By User Id', callback = function() addPlayer(tonumber(library.flags.aimbotWhitelistPlayerBox), true) end});
    end;
end;