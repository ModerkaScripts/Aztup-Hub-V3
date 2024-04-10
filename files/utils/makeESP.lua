local Utility = sharedRequire('@utils/Utility.lua');
local createBaseESP = sharedRequire('@utils/createBaseESP.lua');
local library = sharedRequire('@UILibrary.lua');
local toCamelCase = sharedRequire('@utils/toCamelCase.lua');

local sectionIndex = 1;
local addedESPSearch = false;
local function makeEsp(options)
    options = options or {};

    local tag = toCamelCase(options.sectionName);

    assert(options.sectionName, 'options.sectionName is required');
    assert(options.callback, 'options.callback is required');
    assert(options.args, 'options.args is required');
    assert(options.type, 'options.type is required');

    sectionIndex = (sectionIndex % 2) + 1;

    local espSections = Utility:getESPSection();
    local espSection = espSections['column' .. sectionIndex]:AddSection(options.sectionName);

    if (not addedESPSearch) then
        addedESPSearch = true;
        espSections.espSettings:AddBox({
            text = 'ESP Search',
            skipflag = true,
            noload = true
        });
    end;

    local enableToggle = espSection:AddToggle({
        text = 'Enable',
        flag = options.sectionName
    });

    if (not options.noColorPicker) then
        enableToggle:AddColor({
            flag = string.format('%s Color', options.sectionName)
        });
    end;

    local showDistance = espSection:AddToggle({
        text = 'Show Distance',
        flag = options.sectionName .. ' Show Distance'
    })

    showDistance:AddSlider({
        text = 'Max Distance',
        flag = options.sectionName .. ' Max Distance',
        min = 100,
        value = 100000,
        max = 100000,
        float = 100,
        textpos = 2
    });

    local espConstructor = createBaseESP(tag);

    -- If arg is not a table turn arg into a table
    options.args = typeof(options.args) == 'table' and options.args or {options.args};

    local descOrChild = options.type == 'childAdded' or options.type == 'descendantAdded';
    local watcherFunc;

    if (descOrChild) then
        watcherFunc = Utility[options.type == 'childAdded' and 'listenToChildAdded' or 'listenToDescendantAdded'];
    elseif (options.type == 'tagAdded') then
        watcherFunc = Utility.listenToTagAdded;
    end;

    if (not watcherFunc) then
        return error(options.tag .. ' is not being watched!');
    end;

    for _, parent in next, options.args do
        library.unloadMaid:GiveTask(watcherFunc(parent, function(obj)
            options.callback(obj, espConstructor);
        end));
    end;

    local loadedData = options.onLoaded and options.onLoaded(espSection);

    library.OnLoad:Connect(function()
        local onStateChanged = enableToggle.onStateChanged;

        onStateChanged:Connect(function(state)
            showDistance.main.Visible = state;
        end);

        if (not loadedData) then return; end;

        onStateChanged:Connect(function(state)
            for _, listItem in next, loadedData.list do
                listItem.main.Visible = state;
            end;
        end);
    end);
end;

--[[
    Example usage:

    local section = makeEsp({
        sectionName = 'Mobs',

        type = 'childAdded',
        args = {workspace},

        callback = function(obj, esp)
            esp.new(obj, obj:GetAttribute('MobName') or mob.Name, nil, true); -- Simple args from createBaseESP
        end,

        onLoaded = function(section)
            section:AddToggle({
                text = 'Show Health'
            });

            -- You can also return a list for esp that require toggle for each obj
            return {
                list = arrayOfToggles
            };
        end
    });
]]

-- This is required cause we want the script to finish loading before we setup esp
return function (options)
    task.spawn(makeEsp, options);
end;
