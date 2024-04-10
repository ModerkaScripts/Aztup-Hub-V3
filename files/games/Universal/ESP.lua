local Maid = sharedRequire('../../utils/Maid.lua');
local Services = sharedRequire('../../utils/Services.lua');
local EntityESP = sharedRequire('../../classes/EntityESP.lua');
local library = sharedRequire('../../UILibrary.lua');
local Utility = sharedRequire('../../utils/Utility.lua');

local Players, RunService = Services:Get(getServerConstant('Players'), getServerConstant('RunService'));
local LocalPlayer = Players.LocalPlayer;

local maid = Maid.new();
local entityEspList = {};

local function onPlayerAdded(player)
    if (player == LocalPlayer) then return end;
    local espEntity = EntityESP.new(player);

    library.unloadMaid[player] = function()
        table.remove(entityEspList, table.find(entityEspList, espEntity));
        espEntity:Destroy();
    end;

    table.insert(entityEspList, espEntity);
end;

local function onPlayerRemoving(player)
    library.unloadMaid[player] = nil;
end;

library.OnLoad:Connect(function()
    Players.PlayerAdded:Connect(onPlayerAdded);
    Players.PlayerRemoving:Connect(onPlayerRemoving);

    for i, v in next, Players:GetPlayers() do
        task.spawn(onPlayerAdded, v);
    end;
end);

local function updateEspState(toggle)
    if (not toggle) then
        maid.updateEsp = nil;
        for _, entity in next, entityEspList do
            entity:Hide();
        end;

        return;
    end;

    local lastUpdateAt = 0;
    local ESP_UPDATE_RATE = 10/1000;

    maid.updateEsp = RunService.RenderStepped:Connect(function()
        if (tick() - lastUpdateAt < ESP_UPDATE_RATE) then return end;
        lastUpdateAt = tick();

        debug.profilebegin('Full Entity Update');

        for _, entity in next, entityEspList do
            debug.profilebegin('Single Entity Update ' .. entity._playerName);
            entity:Update();
            debug.profileend();
        end;

        debug.profileend();
    end);
end;

local function toggleRainbowEsp(flag)
    return function(toggle)
        if(not toggle) then
            maid['rainbow' .. flag] = nil;
            return;
        end;

        maid['rainbow' .. flag] = RunService.RenderStepped:Connect(function()
            library.options[flag]:SetColor(library.chromaColor, false, true);
        end);
    end;
end;

local esp = library:AddTab('ESP');
local column1 = esp:AddColumn();
local column2 = esp:AddColumn();
local espSettings = column1:AddSection(getServerConstant('Esp Settings'));
local espCustomisation = column2:AddSection(getServerConstant('Esp Customisation'));
local proximityArrows = column1:AddSection(getServerConstant('Proximity Arrows'));

espSettings:AddToggle({
    text = 'Toggle Esp',
    callback = updateEspState
}):AddSlider({
    text = 'Max Esp Distance',
    value = 10000,
    min = 50,
    max = 10000,
    callback = function(value)
        if (value == 10000) then
            value = math.huge;
        end;

        library.flags.maxEspDistance = value;
    end,
});

espSettings:AddList({
    text = 'Esp Font',
    flag = 'Esp Font',
    values = {'UI', 'System', 'Plex', 'Monospace'},
    callback = function(font)
        font = Drawing.Fonts[font];
        for i, v in next, entityEspList do
            v:SetFont(font);
        end;
    end,
});

espSettings:AddSlider({
    text = 'Text Size',
    textpos = 2,
    max = 100,
    min = 16,
    callback = function(textSize)
        for i, v in next, entityEspList do
            v:SetTextSize(textSize);
        end;
    end;
});

espSettings:AddToggle({
    text = 'Toggle Tracers',
});

proximityArrows:AddToggle({
    text = 'Proximity Arrows',
}):AddSlider({text = 'Arrows Size', flag = 'Proximity Arrows Size', min = 10, max = 25, value = 20, textpos = 2});

proximityArrows:AddSlider({
    text = 'Max Distance',
    flag = 'Max Proximity Arrow Distance',
    min = 0,
    max = 2000,
    value = 1000
});

espSettings:AddToggle({
    text = 'Toggle Boxes',
});

-- espSettings:AddToggle({
--     text = '2D Esp',
--     flag = 'Two Dimensions E S P'
-- });

espSettings:AddToggle({
    text = 'Show Health Bar'
});

espSettings:AddToggle({
    text = 'Show Team',
});

espCustomisation:AddToggle({
    text = 'Rainbow Enemy Color',
    callback = toggleRainbowEsp('enemyColor')
});

espCustomisation:AddToggle({
    text = 'Rainbow Ally Color',
    callback = toggleRainbowEsp('allyColor')
});

espCustomisation:AddToggle({
    text = 'Unlock Tracers',
});

espCustomisation:AddColor({
    text = 'Ally Color',
})

espCustomisation:AddColor({
    text = 'Enemy Color',
});

function Utility:getESPSection()
    return {
        espCustomisation = espCustomisation,
        espSettings = espSettings,
        column1 = column1,
        column2 = column2
    };
end;

Utility.setupRenderOverload = function()
    Utility:renderOverload({
        espCustomisation = espCustomisation,
        espSettings = espSettings,
        column1 = column1,
        column2 = column2
    });
end;