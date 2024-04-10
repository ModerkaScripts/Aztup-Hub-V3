local Utility = sharedRequire('@utils/Utility.lua');
local createBaseESP = sharedRequire('@utils/createBaseESP.lua');
local library = sharedRequire('@UILibrary.lua');

local partsESP = createBaseESP('npcs');

local c = 0;
local function onPartAdded(obj)
    local esp;

    local code = [[
        local obj = ...;
        local FindFirstChildWhichIsA = game.FindFirstChildWhichIsA;

        return setmetatable({}, {
            __index = function(_, p)
                if (p == 'Position') then
                    return obj.Position
                end;
            end,
        });
    ]]

    esp = partsESP.new({code = code, vars = {obj}}, obj.Name .. tostring(math.random()) .. ' DA OP', nil, true);

    local con;
    con = obj:GetPropertyChangedSignal('Parent'):Connect(function()
        if (obj.Parent) then return end;
        print('destroyed');

        con:Disconnect();
        esp:Destroy();
    end);
end

function Utility:renderOverload(data)
    data.column1:AddSection('Parts ESP'):AddToggle({
        text = 'Enable',
        flag = 'Npcs'
    })
end;

Utility.listenToChildAdded(workspace.Parts, onPartAdded);