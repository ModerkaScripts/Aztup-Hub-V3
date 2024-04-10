SX_VM_CNONE();

-- // Services

local libraryLoadAt = tick();

local Signal = sharedRequire('utils/Signal.lua');
local Services = sharedRequire('utils/Services.lua');
local KeyBindVisualizer = sharedRequire('classes/KeyBindVisualizer.lua');

local CoreGui, Players, RunService, TextService, UserInputService, ContentProvider, HttpService, TweenService, GuiService, TeleportService = Services:Get('CoreGui', 'Players', 'RunService', 'TextService', 'UserInputService', 'ContentProvider', 'HttpService', 'TweenService', 'GuiService', 'TeleportService');

local toCamelCase = sharedRequire('utils/toCamelCase.lua');
local Maid = sharedRequire('utils/Maid.lua');
local ToastNotif = sharedRequire('@classes/ToastNotif.lua');

local LocalPlayer = Players.LocalPlayer;
local visualizer;

if getgenv().library then
	getgenv().library:Unload();
end;

if (not isfile('Aztup Hub V3/configs')) then
    makefolder('Aztup Hub V3/configs');
end;

if (not isfile('Aztup Hub V3/configs/globalConf.bin')) then
    -- By default global config is turned on
    writefile('Aztup Hub V3/configs/globalConf.bin', 'true');
end;

local globalConfFilePath = 'Aztup Hub V3/configs/globalConf.bin';
local isGlobalConfigOn = readfile(globalConfFilePath) == 'true';

local library = {
    unloadMaid = Maid.new(),
	tabs = {},
	draggable = true,
	flags = {},
	title = string.format('Aztup Hub | v%s', scriptVersion or 'DEBUG'),
	open = false,
	popup = nil,
	instances = {},
	connections = {},
	options = {},
	notifications = {},
    configVars = {},
	tabSize = 0,
	theme = {},
	foldername =  isGlobalConfigOn and 'Aztup Hub V3/configs/global' or string.format('Aztup Hub V3/configs/%s', tostring(LocalPlayer.UserId)),
	fileext = getServerConstant('.json'),
    chromaColor = Color3.new()
}

library.originalTitle = library.title;

do -- // Load
    library.unloadMaid:GiveTask(task.spawn(function()
        while true do
            for i = 1, 360 do
                library.chromaColor = Color3.fromHSV(i / 360, 1, 1);
                task.wait(0.1);
            end;
        end;
    end));

    -- if(debugMode) then
        getgenv().library = library
    -- end;

    library.OnLoad = Signal.new();
    library.OnKeyPress = Signal.new();
    library.OnKeyRelease = Signal.new();

    library.OnFlagChanged = Signal.new();

    KeyBindVisualizer.init(library);

    library.unloadMaid:GiveTask(library.OnLoad);
    library.unloadMaid:GiveTask(library.OnKeyPress);
    library.unloadMaid:GiveTask(library.OnKeyRelease);
    library.unloadMaid:GiveTask(library.OnFlagChanged);

    visualizer = KeyBindVisualizer.new();
    local mouseMovement = Enum.UserInputType.MouseMovement;

    --Locals
    local dragging, dragInput, dragStart, startPos, dragObject

    local blacklistedKeys = { --add or remove keys if you find the need to
        Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Escape
    }
    local whitelistedMouseinputs = { --add or remove mouse inputs if you find the need to
        Enum.UserInputType.MouseButton1,Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3
    }

    local function onInputBegan(input, gpe)
        local inputType = input.UserInputType;
        if (inputType == mouseMovement) then return end;

        if (UserInputService:GetFocusedTextBox()) then return end;
        local inputKeyCode = input.KeyCode;

        local fastInputObject = {
            KeyCode = {
                Name = inputKeyCode.Name,
                Value = inputKeyCode.Value
            },

            UserInputType = {
                Name = inputType.Name,
                Value = inputType.Value
            },

            UserInputState = input.UserInputState,
            realKeyCode = inputKeyCode,
            realInputType = inputType
        };

        library.OnKeyPress:Fire(fastInputObject, gpe);
    end;

    local function onInputEnded(input)
        local inputType = input.UserInputType;
        if (inputType == mouseMovement) then return end;

        local inputKeyCode = input.KeyCode;

        local fastInputObject = {
            KeyCode = {
                Name = inputKeyCode.Name,
                Value = inputKeyCode.Value
            },

            UserInputType = {
                Name = inputType.Name,
                Value = inputType.Value
            },

            UserInputState = input.UserInputState,
            realKeyCode = inputKeyCode,
            realInputType = inputType
        };

        library.OnKeyRelease:Fire(fastInputObject);
    end;

    library.unloadMaid:GiveTask(UserInputService.InputBegan:Connect(onInputBegan));
    library.unloadMaid:GiveTask(UserInputService.InputEnded:Connect(onInputEnded));

    local function makeTooltip(interest, option)
        library.unloadMaid:GiveTask(interest.InputChanged:connect(function(input)
            if input.UserInputType.Name == 'MouseMovement' then
                if option.tip then
                    library.tooltip.Text = option.tip;
                    library.tooltip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36);
                end;
            end;
        end));

        library.unloadMaid:GiveTask(interest.InputEnded:connect(function(input)
            if input.UserInputType.Name == 'MouseMovement' then
                if option.tip then
                    library.tooltip.Position = UDim2.fromScale(10, 10);
                end;
            end;
        end));
    end;

    --Functions
    library.round = function(num, bracket)
        bracket = bracket or 1
        if typeof(num) == getServerConstant('Vector2') then
            return Vector2.new(library.round(num.X), library.round(num.Y))
        elseif typeof(num) == getServerConstant('Color3') then
            return library.round(num.r * 255), library.round(num.g * 255), library.round(num.b * 255)
        else
            return num - num % bracket;
        end
    end

    function library:Create(class, properties)
        properties = properties or {}
        if not class then return end
        local a = class == 'Square' or class == 'Line' or class == 'Text' or class == 'Quad' or class == 'Circle' or class == 'Triangle'
        local t = a and Drawing or Instance
        local inst = t.new(class)
        for property, value in next, properties do
            inst[property] = value
        end
        table.insert(self.instances, {object = inst, method = a})
        return inst
    end

    function library:AddConnection(connection, name, callback)
        callback = type(name) == 'function' and name or callback
        connection = connection:Connect(callback)
        self.unloadMaid:GiveTask(connection);
        if name ~= callback then
            self.connections[name] = connection
        else
            table.insert(self.connections, connection)
        end
        return connection
    end

    function library:Unload()
        task.wait();
        visualizer:Remove();

        for _, o in next, self.options do
            if o.type == 'toggle' and not string.find(string.lower(o.flag), 'panic') and o.flag ~= 'saveconfigauto' then
                pcall(o.SetState, o, false);
            end;
        end;

        library.unloadMaid:Destroy();
    end

    local function readFileAndDecodeIt(filePath)
        if (not isfile(filePath)) then return; end;

        local suc, fileContent = pcall(readfile, filePath);
        if (not suc) then return; end;

        local suc2, configData = pcall(HttpService.JSONDecode, HttpService, fileContent);
        if (not suc2) then return; end;

        return configData;
    end;

    local function getConfigForGame(configData)
        local configValueName = library.gameName or 'Universal';

        if (not configData[configValueName]) then
            configData[configValueName] = {};
        end;

        return configData[configValueName];
    end;

    function library:LoadConfig(configName)
        if (not table.find(self:GetConfigs(), configName)) then
            return;
        end;

        local filePath = string.format('%s/%s.%s%s', self.foldername, configName, 'config', self.fileext);
        local configData = readFileAndDecodeIt(filePath);
        if (not configData) then print('no config', configName); return; end;
        configData = getConfigForGame(configData);

        -- Set the loaded config to the new config so we save it only when its actually loaded
        library.loadedConfig = configName;
        library.options.configList:SetValue(configName);

        for _, option in next, self.options do
            if (not option.hasInit or option.type == 'button' or not option.flag or option.skipflag) then
                continue;
            end;

            local configDataVal = configData[option.flag];

            if (typeof(configDataVal) == 'nil') then
                continue;
            end;

            if (option.type == 'toggle') then
                task.spawn(option.SetState, option, configDataVal == 1);
            elseif (option.type == 'color') then
                task.spawn(option.SetColor, option, Color3.fromHex(configDataVal));

                if option.trans then
                    task.spawn(option.SetTrans, option, configData[option.flag .. 'Transparency']);
                end;
            elseif (option.type == 'bind') then
                task.spawn(option.SetKeys, option, configDataVal);
            else
                task.spawn(option.SetValue, option, configDataVal);
            end;
        end;

        return true;
    end;

    function library:SaveConfig(configName)
        local filePath = string.format('%s/%s.%s%s', self.foldername, configName, 'config', self.fileext);
        local allConfigData = readFileAndDecodeIt(filePath) or {};

        if (allConfigData.configVersion ~= '1') then
            allConfigData = {};
            allConfigData.configVersion = '1';
        end;

        local configData = getConfigForGame(allConfigData);

        debug.profilebegin('Set config value');
        for _, option in next, self.options do
            if (option.type == 'button' or not option.flag) then continue end;
            if (option.skipflag or option.noSave) then continue end;

            local flag = option.flag;

            if (option.type == 'toggle') then
                configData[flag] = option.state and 1 or 0;
            elseif (option.type == 'color') then
                configData[flag] = option.color:ToHex();
                if (not option.trans) then continue end;
                configData[flag .. 'Transparency'] = option.trans;
            elseif (option.type == 'bind' and option.key ~= 'none') then
                local toSave = {};
                for _, v in next, option.keys do
                    table.insert(toSave, v.Name);
                end;

                configData[flag] = toSave;
            elseif (option.type == 'list') then
                configData[flag] = option.value;
            elseif (option.type == 'box' and option.value ~= 'nil' and option.value ~= '') then
                configData[flag] = option.value;
            else
                configData[flag] = option.value;
            end;
        end;
        debug.profileend();

        local configVars = library.configVars;
        configVars.config = configName;

        debug.profilebegin('writefile');
        writefile(self.foldername .. '/' .. self.fileext, HttpService:JSONEncode(configVars));
        debug.profileend();

        debug.profilebegin('writefile');
        writefile(filePath, HttpService:JSONEncode(allConfigData));
        debug.profileend();
    end

    function library:GetConfigs()
        if not isfolder(self.foldername) then
            makefolder(self.foldername)
        end

        local configFiles = {};

        for i, v in next, listfiles(self.foldername) do
            local fileName = v:match('\\(.+)');
            local fileSubExtension = v:match('%.(.+)%.json');

            if (fileSubExtension == 'config') then
                table.insert(configFiles, fileName:match('(.-)%.config'));
            end;
        end;

        if (not table.find(configFiles, 'default')) then
            table.insert(configFiles, 'default');
        end;

        return configFiles;
    end

    function library:UpdateConfig()
        if (not library.hasInit) then return end;
        debug.profilebegin('Config Save');

        library:SaveConfig(library.loadedConfig or 'default');

        debug.profileend();
    end;

    local function createLabel(option, parent)
        option.main = library:Create('TextLabel', {
            LayoutOrder = option.position,
            Position = UDim2.new(0, 6, 0, 0),
            Size = UDim2.new(1, -12, 0, 24),
            BackgroundTransparency = 1,
            TextSize = 15,
            Font = Enum.Font.Code,
            TextColor3 = Color3.new(1, 1, 1),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            RichText = true,
            Parent = parent
        })

        setmetatable(option, {__newindex = function(t, i, v)
            if i == 'Text' then
                option.main.Text = tostring(v)

                local textSize = TextService:GetTextSize(option.main.ContentText, 15, Enum.Font.Code, Vector2.new(option.main.AbsoluteSize.X, 9e9));
                option.main.Size = UDim2.new(1, -12, 0, textSize.Y);
            end
        end})

        option.Text = option.text
    end

    local function createDivider(option, parent)
        option.main = library:Create('Frame', {
            LayoutOrder = option.position,
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Parent = parent
        })

        library:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, -24, 0, 1),
            BackgroundColor3 = Color3.fromRGB(60, 60, 60),
            BorderColor3 = Color3.new(),
            Parent = option.main
        })

        option.title = library:Create('TextLabel', {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BorderSizePixel = 0,
            TextColor3 =  Color3.new(1, 1, 1),
            TextSize = 15,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = option.main
        })

        local interest = option.main;
        makeTooltip(interest, option);

        setmetatable(option, {__newindex = function(t, i, v)
            if i == 'Text' then
                if v then
                    option.title.Text = tostring(v)
                    option.title.Size = UDim2.new(0, TextService:GetTextSize(option.title.Text, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X + 12, 0, 20)
                    option.main.Size = UDim2.new(1, 0, 0, 18)
                else
                    option.title.Text = ''
                    option.title.Size = UDim2.new()
                    option.main.Size = UDim2.new(1, 0, 0, 6)
                end
            end
        end})
        option.Text = option.text
    end

    local function createToggle(option, parent)
        option.hasInit = true
        option.onStateChanged = Signal.new();

        option.main = library:Create('Frame', {
            LayoutOrder = option.position,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = parent
        })

        local tickbox
        local tickboxOverlay
        if option.style then
            tickbox = library:Create('ImageLabel', {
                Position = UDim2.new(0, 6, 0, 4),
                Size = UDim2.new(0, 12, 0, 12),
                BackgroundTransparency = 1,
                Image = 'rbxassetid://3570695787',
                ImageColor3 = Color3.new(),
                Parent = option.main
            })

            library:Create('ImageLabel', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundTransparency = 1,
                Image = 'rbxassetid://3570695787',
                ImageColor3 = Color3.fromRGB(60, 60, 60),
                Parent = tickbox
            })

            library:Create('ImageLabel', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -6, 1, -6),
                BackgroundTransparency = 1,
                Image = 'rbxassetid://3570695787',
                ImageColor3 = Color3.fromRGB(40, 40, 40),
                Parent = tickbox
            })

            tickboxOverlay = library:Create('ImageLabel', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, -6, 1, -6),
                BackgroundTransparency = 1,
                Image = 'rbxassetid://3570695787',
                ImageColor3 = library.flags.menuAccentColor,
                Visible = option.state,
                Parent = tickbox
            })

            library:Create('ImageLabel', {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = 'rbxassetid://5941353943',
                ImageTransparency = 0.6,
                Parent = tickbox
            })

            table.insert(library.theme, tickboxOverlay)
        else
            tickbox = library:Create('Frame', {
                Position = UDim2.new(0, 6, 0, 4),
                Size = UDim2.new(0, 12, 0, 12),
                BackgroundColor3 = library.flags.menuAccentColor,
                BorderColor3 = Color3.new(),
                Parent = option.main
            })

            tickboxOverlay = library:Create('ImageLabel', {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = option.state and 1 or 0,
                BackgroundColor3 = Color3.fromRGB(50, 50, 50),
                BorderColor3 = Color3.new(),
                Image = 'rbxassetid://4155801252',
                ImageTransparency = 0.6,
                ImageColor3 = Color3.new(),
                Parent = tickbox
            })

            library:Create('ImageLabel', {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = 'rbxassetid://2592362371',
                ImageColor3 = Color3.fromRGB(60, 60, 60),
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(2, 2, 62, 62),
                Parent = tickbox
            })

            library:Create('ImageLabel', {
                Size = UDim2.new(1, -2, 1, -2),
                Position = UDim2.new(0, 1, 0, 1),
                BackgroundTransparency = 1,
                Image = 'rbxassetid://2592362371',
                ImageColor3 = Color3.new(),
                ScaleType = Enum.ScaleType.Slice,
                SliceCenter = Rect.new(2, 2, 62, 62),
                Parent = tickbox
            })

            table.insert(library.theme, tickbox)
        end

        option.interest = library:Create('Frame', {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Parent = option.main
        })

        option.title = library:Create('TextLabel', {
            Position = UDim2.new(0, 24, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = option.text,
            TextColor3 =  option.state and Color3.fromRGB(210, 210, 210) or Color3.fromRGB(180, 180, 180),
            TextSize = 15,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = option.interest
        })

        library.unloadMaid:GiveTask(option.interest.InputBegan:connect(function(input)
            if input.UserInputType.Name == 'MouseButton1' then
                option:SetState(not option.state)
            end
            if input.UserInputType.Name == 'MouseMovement' then
                if not library.warning and not library.slider then
                    if option.style then
                        tickbox.ImageColor3 = library.flags.menuAccentColor
                    else
                        tickbox.BorderColor3 = library.flags.menuAccentColor
                        tickboxOverlay.BorderColor3 = library.flags.menuAccentColor
                    end
                end
                if option.tip then
                    library.tooltip.Text = option.tip;
                end
            end
        end))

        makeTooltip(option.interest, option);

        library.unloadMaid:GiveTask(option.interest.InputEnded:connect(function(input)
            if input.UserInputType.Name == 'MouseMovement' then
                if option.style then
                    tickbox.ImageColor3 = Color3.new()
                else
                    tickbox.BorderColor3 = Color3.new()
                    tickboxOverlay.BorderColor3 = Color3.new()
                end
            end
        end));

        function option:SetState(state, nocallback)
            state = typeof(state) == 'boolean' and state
            state = state or false
            library.flags[self.flag] = state
            self.state = state
            option.title.TextColor3 = state and Color3.fromRGB(210, 210, 210) or Color3.fromRGB(160, 160, 160)
            if option.style then
                tickboxOverlay.Visible = state
            else
                tickboxOverlay.BackgroundTransparency = state and 1 or 0
            end

            if not nocallback then
                task.spawn(self.callback, state);
            end

            option.onStateChanged:Fire(state);
            library.OnFlagChanged:Fire(self);
        end

        task.defer(function()
            option:SetState(option.state);
        end);

        setmetatable(option, {__newindex = function(t, i, v)
            if i == 'Text' then
                option.title.Text = tostring(v)
            else
                rawset(t, i, v);
            end
        end})
    end

    local function createButton(option, parent)
        option.hasInit = true

        option.main = option.sub and option:getMain() or library:Create('Frame', {
            LayoutOrder = option.position,
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Parent = parent
        })

        option.title = library:Create('TextLabel', {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -5),
            Size = UDim2.new(1, -12, 0, 18),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderColor3 = Color3.new(),
            Text = option.text,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 15,
            Font = Enum.Font.Code,
            Parent = option.main
        })

        if (option.sub) then
            if (not option.parent.subInit) then
                option.parent.subInit = true;

                -- If we are a sub option then set some properties of parent

                option.parent.title.Size = UDim2.fromOffset(0, 18);

                option.parent.listLayout = library:Create('UIGridLayout', {
                    Parent = option.parent.main,
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    CellSize = UDim2.new(1 / (#option.main:GetChildren()-1), -8, 0, 18)
                });
            end;

            option.parent.listLayout.CellSize = UDim2.new(1 / (#option.parent.main:GetChildren()-1), -8, 0, 18);
        end;

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.fromRGB(60, 60, 60),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.title
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.new(),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.title
        })

        library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 180, 180)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(253, 253, 253)),
            }),
            Rotation = -90,
            Parent = option.title
        })

        library.unloadMaid:GiveTask(option.title.InputBegan:connect(function(input)
            if input.UserInputType.Name == 'MouseButton1' then
                option.callback()
                if library then
                    library.flags[option.flag] = true
                end
                if option.tip then
                    library.tooltip.Text = option.tip;
                end
            end
            if input.UserInputType.Name == 'MouseMovement' then
                if not library.warning and not library.slider then
                    option.title.BorderColor3 = library.flags.menuAccentColor;
                end
                if option.tip then
                    library.tooltip.Text = option.tip;
                end
            end
        end));

        makeTooltip(option.title, option);

        library.unloadMaid:GiveTask(option.title.InputEnded:connect(function(input)
            if input.UserInputType.Name == 'MouseMovement' then
                option.title.BorderColor3 = Color3.new();
            end
        end));
    end

    local function createBind(option, parent)
        option.hasInit = true

        local Loop
        local maid = Maid.new()

        library.unloadMaid:GiveTask(function()
            maid:Destroy();
        end);

        if option.sub then
            option.main = option:getMain()
        else
            option.main = option.main or library:Create('Frame', {
                LayoutOrder = option.position,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Parent = parent
            })

            option.title = library:Create('TextLabel', {
                Position = UDim2.new(0, 6, 0, 0),
                Size = UDim2.new(1, -12, 1, 0),
                BackgroundTransparency = 1,
                Text = option.text,
                TextSize = 15,
                Font = Enum.Font.Code,
                TextColor3 = Color3.fromRGB(210, 210, 210),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = option.main
            })
        end

        local bindinput = library:Create(option.sub and 'TextButton' or 'TextLabel', {
            Position = UDim2.new(1, -6 - (option.subpos or 0), 0, option.sub and 2 or 3),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BorderSizePixel = 0,
            TextSize = 15,
            Font = Enum.Font.Code,
            TextColor3 = Color3.fromRGB(160, 160, 160),
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = option.main
        })

        if option.sub then
            bindinput.AutoButtonColor = false
        end

        local interest = option.sub and bindinput or option.main;
        local maid = Maid.new();

        local function formatKey(key)
            if (key:match('Mouse')) then
                key = key:gsub('Button', ''):gsub('Mouse', 'M');
            elseif (key:match('Shift') or key:match('Alt') or key:match('Control')) then
                key = key:gsub('Left', 'L'):gsub('Right', 'R');
            end;

            return key:gsub('Control', 'CTRL'):upper();
        end;

        local function formatKeys(keys)
            if (not keys) then return {}; end;
            local ret = {};

            for _, key in next, keys do
                table.insert(ret, formatKey(typeof(key) == 'string' and key or key.Name));
            end;

            return ret;
        end;

        local busy = false;

        makeTooltip(interest, option);

        library.unloadMaid:GiveTask(interest.InputEnded:connect(function(input)
            if input.UserInputType.Name == 'MouseButton1' and not busy then
                busy = true;
                library.disableKeyBind = true;

                bindinput.Text = '[...]'
                bindinput.Size = UDim2.new(0, -TextService:GetTextSize(bindinput.Text, 16, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 16)
                bindinput.TextColor3 = library.flags.menuAccentColor

                local displayKeys = {};
                local keys = {};

                maid.keybindLoop = RunService.Heartbeat:Connect(function()
                    for _, key in next, UserInputService:GetKeysPressed() do
                        local value = formatKey(key.KeyCode.Name);

                        if (value == 'BACKSPACE') then
                            maid.keybindLoop = nil;
                            option:SetKeys('none');
                            return;
                        end;

                        if (table.find(displayKeys, value)) then continue; end;
                        table.insert(displayKeys, value);
                        table.insert(keys, key.KeyCode);
                    end;

                    for _, mouseBtn in next, UserInputService:GetMouseButtonsPressed() do
                        local value = formatKey(mouseBtn.UserInputType.Name);

                        if (option.nomouse) then continue end;
                        if (not table.find(whitelistedMouseinputs, mouseBtn.UserInputType)) then continue end;

                        if (table.find(displayKeys, value)) then continue; end;

                        table.insert(displayKeys, value);
                        table.insert(keys, mouseBtn.UserInputType);
                    end;

                    bindinput.Text = '[' .. table.concat(displayKeys, '+') .. ']';

                    if (#displayKeys == 3) then
                        maid.keybindLoop = nil;
                    end;
                end);

                task.wait(0.05);
                maid.onInputEnded = UserInputService.InputEnded:Connect(function(input)
                    if(input.UserInputType ~= Enum.UserInputType.Keyboard and not input.UserInputType.Name:find('MouseButton')) then return; end;

                    maid.keybindLoop = nil;
                    maid.onInputEnded = nil;

                    option:SetKeys(keys);
                    library.disableKeyBind = false;
                    task.wait(0.2);
                    busy = false;
                end);
            end
        end));

        local function isKeybindPressed()
            local foundCount = 0;

            for _, key in next, UserInputService:GetKeysPressed() do
                if (table.find(option.keys, key.KeyCode)) then
                    foundCount += 1;
                end;
            end;

            for _, key in next, UserInputService:GetMouseButtonsPressed() do
                if (table.find(option.keys, key.UserInputType)) then
                    foundCount += 1;
                end;
            end;

            return foundCount == #option.keys;
        end;

        local debounce = false;

        function option:SetKeys(keys)
            if (typeof(keys) == 'string') then
                keys = {keys};
            end;

            keys = keys or {option.key ~= 'none' and option.key or nil};

            for i, key in next, keys do
                if (typeof(key) == 'string' and key ~= 'none') then
                    local isMouse = key:find('MouseButton');

                    if (isMouse) then
                        keys[i] = Enum.UserInputType[key];
                    else
                        keys[i] = Enum.KeyCode[key];
                    end;
                end;
            end;

            bindinput.TextColor3 = Color3.fromRGB(160, 160, 160)

            if Loop then
                Loop:Disconnect()
                Loop = nil;
                library.flags[option.flag] = false
                option.callback(true, 0)
            end

            self.keys = keys;

            if self.keys[1] == 'Backspace' or #self.keys == 0 then
                self.key = 'none'
                bindinput.Text = '[NONE]'

                if (#self.keys ~= 0) then
                    visualizer:RemoveText(self.text);
                end;
            else
                if (self.parentFlag and self.key ~= 'none') then
                    if (library.flags[self.parentFlag]) then
                        visualizer:AddText(self.text);
                    end;
                end;

                local formattedKey = formatKeys(self.keys);
                bindinput.Text = '[' .. table.concat(formattedKey, '+') .. ']';
                self.key = table.concat(formattedKey, '+');
            end

            bindinput.Size = UDim2.new(0, -TextService:GetTextSize(bindinput.Text, 16, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 16)

            if (self.key == 'none') then
                maid.onKeyPress = nil;
                maid.onKeyRelease = nil;
            else
                maid.onKeyPress = library.OnKeyPress:Connect(function()
                    if (library.disableKeyBind or #option.keys == 0 or debounce) then return end;
                    if (not isKeybindPressed()) then return; end;

                    debounce = true;

                    if option.mode == 'toggle' then
                        library.flags[option.flag] = not library.flags[option.flag]
                        option.callback(library.flags[option.flag], 0)
                    else
                        library.flags[option.flag] = true

                        if Loop then
                            Loop:Disconnect();
                            Loop = nil;
                            option.callback(true, 0);
                        end;

                        Loop = library:AddConnection(RunService.Heartbeat, function(step)
                            if not UserInputService:GetFocusedTextBox() then
                                option.callback(nil, step)
                            end
                        end)
                    end
                end);

                maid.onKeyRelease = library.OnKeyRelease:Connect(function()
                    if (debounce and not isKeybindPressed()) then debounce = false; end;
                    if (option.mode ~= 'hold') then return; end;

                    local bindKey = option.key;
                    if (bindKey == 'none') then return end;

                    if not isKeybindPressed() then
                        if Loop then
                            Loop:Disconnect()
                            Loop = nil;

                            library.flags[option.flag] = false
                            option.callback(true, 0)
                        end
                    end
                end);
            end;
        end;

        option:SetKeys();
    end

    local function createSlider(option, parent)
        option.hasInit = true

        if option.sub then
            option.main = option:getMain()
        else
            option.main = library:Create('Frame', {
                LayoutOrder = option.position,
                Size = UDim2.new(1, 0, 0, option.textpos and 24 or 40),
                BackgroundTransparency = 1,
                Parent = parent
            })
        end

        option.slider = library:Create('Frame', {
            Position = UDim2.new(0, 6, 0, (option.sub and 22 or option.textpos and 4 or 20)),
            Size = UDim2.new(1, -12, 0, 16),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderColor3 = Color3.new(),
            Parent = option.main
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2454009026',
            ImageColor3 = Color3.new(),
            ImageTransparency = 0.8,
            Parent = option.slider
        })

        option.fill = library:Create('Frame', {
            BackgroundColor3 = library.flags.menuAccentColor,
            BorderSizePixel = 0,
            Parent = option.slider
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.fromRGB(60, 60, 60),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.slider
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.new(),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.slider
        })

        option.title = library:Create('TextBox', {
            Position = UDim2.new((option.sub or option.textpos) and 0.5 or 0, (option.sub or option.textpos) and 0 or 6, 0, 0),
            Size = UDim2.new(0, 0, 0, (option.sub or option.textpos) and 14 or 18),
            BackgroundTransparency = 1,
            Text = (option.text == 'nil' and '' or option.text .. ': ') .. option.value .. option.suffix,
            TextSize = (option.sub or option.textpos) and 14 or 15,
            Font = Enum.Font.Code,
            TextColor3 = Color3.fromRGB(210, 210, 210),
            TextXAlignment = Enum.TextXAlignment[(option.sub or option.textpos) and 'Center' or 'Left'],
            Parent = (option.sub or option.textpos) and option.slider or option.main
        })
        table.insert(library.theme, option.fill)

        library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(115, 115, 115)),
                ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
            }),
            Rotation = -90,
            Parent = option.fill
        })

        if option.min >= 0 then
            option.fill.Size = UDim2.new((option.value - option.min) / (option.max - option.min), 0, 1, 0)
        else
            option.fill.Position = UDim2.new((0 - option.min) / (option.max - option.min), 0, 0, 0)
            option.fill.Size = UDim2.new(option.value / (option.max - option.min), 0, 1, 0)
        end

        local manualInput
        library.unloadMaid:GiveTask(option.title.Focused:connect(function()
            if not manualInput then
                option.title:ReleaseFocus()
                option.title.Text = (option.text == 'nil' and '' or option.text .. ': ') .. option.value .. option.suffix
            end
        end));

        library.unloadMaid:GiveTask(option.title.FocusLost:connect(function()
            option.slider.BorderColor3 = Color3.new()
            if manualInput then
                if tonumber(option.title.Text) then
                    option:SetValue(tonumber(option.title.Text))
                else
                    option.title.Text = (option.text == 'nil' and '' or option.text .. ': ') .. option.value .. option.suffix
                end
            end
            manualInput = false
        end));

        local interest = (option.sub or option.textpos) and option.slider or option.main
        library.unloadMaid:GiveTask(interest.InputBegan:connect(function(input)
            if input.UserInputType.Name == 'MouseButton1' then
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                    manualInput = true
                    option.title:CaptureFocus()
                else
                    library.slider = option
                    option.slider.BorderColor3 = library.flags.menuAccentColor
                    option:SetValue(option.min + ((input.Position.X - option.slider.AbsolutePosition.X) / option.slider.AbsoluteSize.X) * (option.max - option.min))
                end
            end
            if input.UserInputType.Name == 'MouseMovement' then
                if not library.warning and not library.slider then
                    option.slider.BorderColor3 = library.flags.menuAccentColor
                end
                if option.tip then
                    library.tooltip.Text = option.tip;
                end
            end
        end));

        makeTooltip(interest, option);

        library.unloadMaid:GiveTask(interest.InputEnded:connect(function(input)
            if input.UserInputType.Name == 'MouseMovement' then
                if option ~= library.slider then
                    option.slider.BorderColor3 = Color3.new();
                end;
            end;
        end));

        if (option.parent) then
            local oldParent = option.slider.Parent;

            option.parent.onStateChanged:Connect(function(state)
                option.slider.Parent = state and oldParent or nil;
            end);
        end;

        local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

        function option:SetValue(value, nocallback)
            value = value or self.value;

            value = library.round(value, option.float)
            value = math.clamp(value, self.min, self.max)

            if self.min >= 0 then
                TweenService:Create(option.fill, tweenInfo, {Size = UDim2.new((value - self.min) / (self.max - self.min), 0, 1, 0)}):Play();
            else
                TweenService:Create(option.fill, tweenInfo, {
                    Size = UDim2.new(value / (self.max - self.min), 0, 1, 0),
                    Position = UDim2.new((0 - self.min) / (self.max - self.min), 0, 0, 0)
                }):Play();
            end
            library.flags[self.flag] = value
            self.value = value
            option.title.Text = (option.text == 'nil' and '' or option.text .. ': ') .. string.format(option.float == 1 and '%d' or '%.02f', option.value) .. option.suffix
            if not nocallback then
                task.spawn(self.callback, value)
            end

            library.OnFlagChanged:Fire(self)
        end

        task.defer(function()
            if library then
                option:SetValue(option.value)
            end
        end)
    end

    local function createList(option, parent)
        option.hasInit = true

        if option.sub then
            option.main = option:getMain()
            option.main.Size = UDim2.new(1, 0, 0, 48)
        else
            option.main = library:Create('Frame', {
                LayoutOrder = option.position,
                Size = UDim2.new(1, 0, 0, option.text == 'nil' and 30 or 48),
                BackgroundTransparency = 1,
                Parent = parent
            })

            if option.text ~= 'nil' then
                library:Create('TextLabel', {
                    Position = UDim2.new(0, 6, 0, 0),
                    Size = UDim2.new(1, -12, 0, 18),
                    BackgroundTransparency = 1,
                    Text = option.text,
                    TextSize = 15,
                    Font = Enum.Font.Code,
                    TextColor3 = Color3.fromRGB(210, 210, 210),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = option.main
                })
            end
        end

        if(option.playerOnly) then
            library.OnLoad:Connect(function()
                option.values = {};

                for i,v in next, Players:GetPlayers() do
                    if (v == LocalPlayer) then continue end;
                    option:AddValue(v.Name);
                end;

                library.unloadMaid:GiveTask(Players.PlayerAdded:Connect(function(plr)
                    option:AddValue(plr.Name);
                end));

                library.unloadMaid:GiveTask(Players.PlayerRemoving:Connect(function(plr)
                    option:RemoveValue(plr.Name);
                end));
            end);
        end;

        local function getMultiText()
            local t = {};

            if (option.playerOnly and option.multiselect) then
                for i, v in next, option.values do
                    if (option.value[i]) then
                        table.insert(t, tostring(i));
                    end;
                end;
            else
                for i, v in next, option.values do
                    if (option.value[v]) then
                        table.insert(t, tostring(v));
                    end;
                end;
            end;

            return table.concat(t, ', ');
        end

        option.listvalue = library:Create('TextBox', {
            Position = UDim2.new(0, 6, 0, (option.text == 'nil' and not option.sub) and 4 or 22),
            Size = UDim2.new(1, -12, 0, 22),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderColor3 = Color3.new(),
            Active = false,
            ClearTextOnFocus = false,
            Text = ' ' .. (typeof(option.value) == 'string' and option.value or getMultiText()),
            TextSize = 15,
            Font = Enum.Font.Code,
            TextColor3 = Color3.new(1, 1, 1),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = option.main
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2454009026',
            ImageColor3 = Color3.new(),
            ImageTransparency = 0.8,
            Parent = option.listvalue
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.fromRGB(60, 60, 60),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.listvalue
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.new(),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.listvalue
        })

        option.arrow = library:Create('ImageLabel', {
            Position = UDim2.new(1, -16, 0, 7),
            Size = UDim2.new(0, 8, 0, 8),
            Rotation = 90,
            BackgroundTransparency = 1,
            Image = 'rbxassetid://4918373417',
            ImageColor3 = Color3.new(1, 1, 1),
            ScaleType = Enum.ScaleType.Fit,
            ImageTransparency = 0.4,
            Parent = option.listvalue
        })

        option.holder = library:Create('TextButton', {
            ZIndex = 4,
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderColor3 = Color3.new(),
            Text = '',
            TextColor3 = Color3.fromRGB(255,255, 255),
            AutoButtonColor = false,
            Visible = false,
            Parent = library.base
        })

        option.content = library:Create('ScrollingFrame', {
            ZIndex = 4,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
            ScrollBarThickness = 6,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            VerticalScrollBarInset = Enum.ScrollBarInset.Always,
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            Parent = option.holder
        })

        library:Create('ImageLabel', {
            ZIndex = 4,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.fromRGB(60, 60, 60),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.holder
        })

        library:Create('ImageLabel', {
            ZIndex = 4,
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.new(),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.holder
        })

        local layout = library:Create('UIListLayout', {
            Padding = UDim.new(0, 2),
            Parent = option.content
        })

        library:Create('UIPadding', {
            PaddingTop = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            Parent = option.content
        })

        local valueCount = 0;

        local function updateHolder(newValueCount)
            option.holder.Size = UDim2.new(0, option.listvalue.AbsoluteSize.X, 0, 8 + ((newValueCount or valueCount) > option.max and (-2 + (option.max * 22)) or layout.AbsoluteContentSize.Y))
            option.content.CanvasSize = UDim2.new(0, 0, 0, 8 + layout.AbsoluteContentSize.Y)
        end;

        library.unloadMaid:GiveTask(layout.Changed:Connect(function() updateHolder(); end));
        local interest = option.sub and option.listvalue or option.main
        local focused = false;

        library.unloadMaid:GiveTask(option.listvalue.Focused:Connect(function() focused = true; end));
        library.unloadMaid:GiveTask(option.listvalue.FocusLost:Connect(function() focused = false; end));

        library.unloadMaid:GiveTask(option.listvalue:GetPropertyChangedSignal('Text'):Connect(function()
            if (not focused) then return end;
            local newText = option.listvalue.Text;

            if (newText:sub(1, 1) ~= ' ') then
                newText = ' ' .. newText;
                option.listvalue.Text = newText;
                option.listvalue.CursorPosition = 2;
            end;

            local search = string.lower(newText:sub(2));
            local matchedResults = 0;

            for name, label in next, option.labels do
                if (string.find(string.lower(name), search)) then
                    matchedResults += 1;
                    label.Visible = true;
                else
                    label.Visible = false;
                end;
            end;

            updateHolder(matchedResults);
        end));

        library.unloadMaid:GiveTask(option.listvalue.InputBegan:connect(function(input)
            if input.UserInputType.Name == 'MouseButton1' then
                if library.popup == option then library.popup:Close() return end
                if library.popup then
                    library.popup:Close()
                end
                option.arrow.Rotation = -90
                option.open = true
                option.holder.Visible = true
                local pos = option.main.AbsolutePosition
                option.holder.Position = UDim2.new(0, pos.X + 6, 0, pos.Y + ((option.text == 'nil' and not option.sub) and 66 or 84))
                library.popup = option
                option.listvalue.BorderColor3 = library.flags.menuAccentColor
                option.listvalue:CaptureFocus();
                option.listvalue.CursorPosition = string.len(typeof(option.value) == 'string' and option.value or getMultiText() or option.value) + 2;

                if (option.multiselect) then
                    option.listvalue.Text = ' ';
                end;
            end
            if input.UserInputType.Name == 'MouseMovement' then
                if not library.warning and not library.slider then
                    option.listvalue.BorderColor3 = library.flags.menuAccentColor
                end
            end
        end));

        library.unloadMaid:GiveTask(option.listvalue.InputEnded:connect(function(input)
            if input.UserInputType.Name == 'MouseMovement' then
                if not option.open then
                    option.listvalue.BorderColor3 = Color3.new()
                end
            end
        end));

        library.unloadMaid:GiveTask(interest.InputBegan:connect(function(input)
            if input.UserInputType.Name == 'MouseMovement' then
                if option.tip then
                    library.tooltip.Text = option.tip;
                end
            end
        end));

        makeTooltip(interest, option);

        function option:AddValue(value, state)
            if self.labels[value] then return end
            state = state or (option.playerOnly and false)

            valueCount = valueCount + 1

            if self.multiselect then
                self.values[value] = state
            else
                if not table.find(self.values, value) then
                    table.insert(self.values, value)
                end
            end

            local label = library:Create('TextLabel', {
                ZIndex = 4,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = value,
                TextSize = 15,
                Font = Enum.Font.Code,
                TextTransparency = self.multiselect and (self.value[value] and 1 or 0) or self.value == value and 1 or 0,
                TextColor3 = Color3.fromRGB(210, 210, 210),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = option.content
            })

            self.labels[value] = label

            local labelOverlay = library:Create('TextLabel', {
                ZIndex = 4,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 0.8,
                Text = ' ' ..value,
                TextSize = 15,
                Font = Enum.Font.Code,
                TextColor3 = library.flags.menuAccentColor,
                TextXAlignment = Enum.TextXAlignment.Left,
                Visible = self.multiselect and self.value[value] or self.value == value,
                Parent = label
            });

            table.insert(library.theme, labelOverlay)

            library.unloadMaid:GiveTask(label.InputBegan:connect(function(input)
                if input.UserInputType.Name == 'MouseButton1' then
                    if self.multiselect then
                        self.value[value] = not self.value[value]
                        self:SetValue(self.value);
                        self.listvalue.Text = ' ';
                        self.listvalue.CursorPosition = 2;
                        self.listvalue:CaptureFocus();
                    else
                        self:SetValue(value)
                        self:Close()
                    end
                end
            end));
        end

        for i, value in next, option.values do
            option:AddValue(tostring(typeof(i) == 'number' and value or i))
        end

        function option:RemoveValue(value)
            local label = self.labels[value]
            if label then
                label:Destroy()
                self.labels[value] = nil
                valueCount = valueCount - 1
                if self.multiselect then
                    self.values[value] = nil
                    self:SetValue(self.value)
                else
                    table.remove(self.values, table.find(self.values, value))
                    if self.value == value then
                        self:SetValue(self.values[1] or '')

                        if (not self.values[1]) then
                            option.listvalue.Text = '';
                        end;
                    end
                end
            end
        end

        function option:SetValue(value, nocallback)
            if self.multiselect and typeof(value) ~= 'table' then
                value = {}
                for i,v in next, self.values do
                    value[v] = false
                end
            end

            if (not value) then return end;

            self.value = self.multiselect and value or self.values[table.find(self.values, value) or 1];
            if (self.playerOnly and not self.multiselect) then
                self.value = Players:FindFirstChild(value);
            end;

            if (not self.value) then return end;

            library.flags[self.flag] = self.value;
            option.listvalue.Text = ' ' .. (self.multiselect and getMultiText() or tostring(self.value));

            for name, label in next, self.labels do
                local visible = self.multiselect and self.value[name] or self.value == name;
                label.TextTransparency = visible and 1 or 0;
                if label:FindFirstChild'TextLabel' then
                    label.TextLabel.Visible = visible;
                end;
            end;

            if not nocallback then
                self.callback(self.value)
            end
        end

        task.defer(function()
            if library and not option.noload then
                option:SetValue(option.value)
            end
        end)

        function option:Close()
            library.popup = nil
            option.arrow.Rotation = 90
            self.open = false
            option.holder.Visible = false
            option.listvalue.BorderColor3 = Color3.new()
            option.listvalue:ReleaseFocus();
            option.listvalue.Text = ' ' .. (self.multiselect and getMultiText() or tostring(self.value));

            for _, label in next, option.labels do
                label.Visible = true;
            end;
        end

        return option
    end

    local function createBox(option, parent)
        option.hasInit = true

        option.main = library:Create('Frame', {
            LayoutOrder = option.position,
            Size = UDim2.new(1, 0, 0, option.text == 'nil' and 28 or 44),
            BackgroundTransparency = 1,
            Parent = parent
        })

        if option.text ~= 'nil' then
            option.title = library:Create('TextLabel', {
                Position = UDim2.new(0, 6, 0, 0),
                Size = UDim2.new(1, -12, 0, 18),
                BackgroundTransparency = 1,
                Text = option.text,
                TextSize = 15,
                Font = Enum.Font.Code,
                TextColor3 = Color3.fromRGB(210, 210, 210),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = option.main
            })
        end

        option.holder = library:Create('Frame', {
            Position = UDim2.new(0, 6, 0, option.text == 'nil' and 4 or 20),
            Size = UDim2.new(1, -12, 0, 20),
            BackgroundColor3 = Color3.fromRGB(50, 50, 50),
            BorderColor3 = Color3.new(),
            Parent = option.main
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2454009026',
            ImageColor3 = Color3.new(),
            ImageTransparency = 0.8,
            Parent = option.holder
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.fromRGB(60, 60, 60),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.holder
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.new(),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.holder
        })

        local inputvalue = library:Create('TextBox', {
            Position = UDim2.new(0, 4, 0, 0),
            Size = UDim2.new(1, -4, 1, 0),
            BackgroundTransparency = 1,
            Text = '  ' .. option.value,
            TextSize = 15,
            Font = Enum.Font.Code,
            TextColor3 = Color3.new(1, 1, 1),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            ClearTextOnFocus = false,
            Parent = option.holder
        })

        library.unloadMaid:GiveTask(inputvalue.FocusLost:connect(function(enter)
            option.holder.BorderColor3 = Color3.new()
            option:SetValue(inputvalue.Text, enter)
        end));

        library.unloadMaid:GiveTask(inputvalue.Focused:connect(function()
            option.holder.BorderColor3 = library.flags.menuAccentColor
        end));

        library.unloadMaid:GiveTask(inputvalue.InputBegan:connect(function(input)
            if input.UserInputType.Name == 'MouseMovement' then
                if not library.warning and not library.slider then
                    option.holder.BorderColor3 = library.flags.menuAccentColor
                end
                if option.tip then
                    library.tooltip.Text = option.tip;
                end
            end
        end));

        makeTooltip(inputvalue, option);

        library.unloadMaid:GiveTask(inputvalue.InputEnded:connect(function(input)
            if input.UserInputType.Name == 'MouseMovement' then
                if not inputvalue:IsFocused() then
                    option.holder.BorderColor3 = Color3.new();
                end;
            end;
        end));

        function option:SetValue(value, enter)
            if (value:gsub('%s+', '') == '') then
                value = '';
            end;

            library.flags[self.flag] = tostring(value);
            self.value = tostring(value);
            inputvalue.Text = self.value;
            self.callback(value, enter);

            library.OnFlagChanged:Fire(self);
        end
        task.defer(function()
            if library then
                option:SetValue(option.value)
            end
        end)
    end

    local function createColorPickerWindow(option)
        option.mainHolder = library:Create('TextButton', {
            ZIndex = 4,
            --Position = UDim2.new(1, -184, 1, 6),
            Size = UDim2.new(0, option.trans and 200 or 184, 0, 264),
            BackgroundColor3 = Color3.fromRGB(40, 40, 40),
            BorderColor3 = Color3.new(),
            AutoButtonColor = false,
            Visible = false,
            Parent = library.base
        })

        option.rgbBox = library:Create('Frame', {
            Position = UDim2.new(0, 6, 0, 214),
            Size = UDim2.new(0, (option.mainHolder.AbsoluteSize.X - 12), 0, 20),
            BackgroundColor3 = Color3.fromRGB(57, 57, 57),
            BorderColor3 = Color3.new(),
            ZIndex = 5;
            Parent = option.mainHolder
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2454009026',
            ImageColor3 = Color3.new(),
            ImageTransparency = 0.8,
            ZIndex = 6;
            Parent = option.rgbBox
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.fromRGB(60, 60, 60),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            ZIndex = 6;
            Parent = option.rgbBox
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.new(),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            ZIndex = 6;
            Parent = option.rgbBox
        })

        local r, g, b = library.round(option.color);
        local colorText = table.concat({r, g, b}, ',');

        option.rgbInput = library:Create('TextBox', {
            Position = UDim2.new(0, 4, 0, 0),
            Size = UDim2.new(1, -4, 1, 0),
            BackgroundTransparency = 1,
            Text = colorText,
            TextSize = 14,
            Font = Enum.Font.Code,
            TextColor3 = Color3.new(1, 1, 1),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextWrapped = true,
            ClearTextOnFocus = false,
            ZIndex = 6;
            Parent = option.rgbBox
        })

        option.hexBox = option.rgbBox:Clone()
        option.hexBox.Position = UDim2.new(0, 6, 0, 238)
        -- option.hexBox.Size = UDim2.new(0, (option.mainHolder.AbsoluteSize.X/2 - 10), 0, 20)
        option.hexBox.Parent = option.mainHolder
        option.hexInput = option.hexBox.TextBox;

        library:Create('ImageLabel', {
            ZIndex = 4,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.fromRGB(60, 60, 60),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.mainHolder
        })

        library:Create('ImageLabel', {
            ZIndex = 4,
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.new(),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.mainHolder
        })

        local hue, sat, val = Color3.toHSV(option.color)
        hue, sat, val = hue == 0 and 1 or hue, sat + 0.005, val - 0.005
        local editinghue
        local editingsatval
        local editingtrans

        local transMain
        if option.trans then
            transMain = library:Create('ImageLabel', {
                ZIndex = 5,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Image = 'rbxassetid://2454009026',
                ImageColor3 = Color3.fromHSV(hue, 1, 1),
                Rotation = 180,
                Parent = library:Create('ImageLabel', {
                    ZIndex = 4,
                    AnchorPoint = Vector2.new(1, 0),
                    Position = UDim2.new(1, -6, 0, 6),
                    Size = UDim2.new(0, 10, 1, -60),
                    BorderColor3 = Color3.new(),
                    Image = 'rbxassetid://4632082392',
                    ScaleType = Enum.ScaleType.Tile,
                    TileSize = UDim2.new(0, 5, 0, 5),
                    Parent = option.mainHolder
                })
            })

            option.transSlider = library:Create('Frame', {
                ZIndex = 5,
                Position = UDim2.new(0, 0, option.trans, 0),
                Size = UDim2.new(1, 0, 0, 2),
                BackgroundColor3 = Color3.fromRGB(38, 41, 65),
                BorderColor3 = Color3.fromRGB(255, 255, 255),
                Parent = transMain
            })

            library.unloadMaid:GiveTask(transMain.InputBegan:connect(function(Input)
                if Input.UserInputType.Name == 'MouseButton1' then
                    editingtrans = true
                    option:SetTrans(1 - ((Input.Position.Y - transMain.AbsolutePosition.Y) / transMain.AbsoluteSize.Y))
                end
            end));

            library.unloadMaid:GiveTask(transMain.InputEnded:connect(function(Input)
                if Input.UserInputType.Name == 'MouseButton1' then
                    editingtrans = false
                end
            end));
        end

        local hueMain = library:Create('Frame', {
            ZIndex = 4,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 6, 1, -54),
            Size = UDim2.new(1, option.trans and -28 or -12, 0, 10),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(),
            Parent = option.mainHolder
        })

        library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            }),
            Parent = hueMain
        })

        local hueSlider = library:Create('Frame', {
            ZIndex = 4,
            Position = UDim2.new(1 - hue, 0, 0, 0),
            Size = UDim2.new(0, 2, 1, 0),
            BackgroundColor3 = Color3.fromRGB(38, 41, 65),
            BorderColor3 = Color3.fromRGB(255, 255, 255),
            Parent = hueMain
        })

        library.unloadMaid:GiveTask(hueMain.InputBegan:connect(function(Input)
            if Input.UserInputType.Name == 'MouseButton1' then
                editinghue = true
                local X = (hueMain.AbsolutePosition.X + hueMain.AbsoluteSize.X) - hueMain.AbsolutePosition.X
                X = math.clamp((Input.Position.X - hueMain.AbsolutePosition.X) / X, 0, 0.995)
                option:SetColor(Color3.fromHSV(1 - X, sat, val))
            end
        end));

        library.unloadMaid:GiveTask(hueMain.InputEnded:connect(function(Input)
            if Input.UserInputType.Name == 'MouseButton1' then
                editinghue = false
            end
        end));

        local satval = library:Create('ImageLabel', {
            ZIndex = 4,
            Position = UDim2.new(0, 6, 0, 6),
            Size = UDim2.new(1, option.trans and -28 or -12, 1, -74),
            BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
            BorderColor3 = Color3.new(),
            Image = 'rbxassetid://4155801252',
            ClipsDescendants = true,
            Parent = option.mainHolder
        })

        local satvalSlider = library:Create('Frame', {
            ZIndex = 4,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(sat, 0, 1 - val, 0),
            Size = UDim2.new(0, 4, 0, 4),
            Rotation = 45,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Parent = satval
        })

        library.unloadMaid:GiveTask(satval.InputBegan:connect(function(Input)
            if Input.UserInputType.Name == 'MouseButton1' then
                editingsatval = true
                local X = (satval.AbsolutePosition.X + satval.AbsoluteSize.X) - satval.AbsolutePosition.X
                local Y = (satval.AbsolutePosition.Y + satval.AbsoluteSize.Y) - satval.AbsolutePosition.Y
                X = math.clamp((Input.Position.X - satval.AbsolutePosition.X) / X, 0.005, 1)
                Y = math.clamp((Input.Position.Y - satval.AbsolutePosition.Y) / Y, 0, 0.995)
                option:SetColor(Color3.fromHSV(hue, X, 1 - Y))
            end
        end));

        library:AddConnection(UserInputService.InputChanged, function(Input)
            if (not editingsatval and not editinghue and not editingtrans) then return end;

            if Input.UserInputType.Name == 'MouseMovement' then
                if editingsatval then
                    local X = (satval.AbsolutePosition.X + satval.AbsoluteSize.X) - satval.AbsolutePosition.X
                    local Y = (satval.AbsolutePosition.Y + satval.AbsoluteSize.Y) - satval.AbsolutePosition.Y
                    X = math.clamp((Input.Position.X - satval.AbsolutePosition.X) / X, 0.005, 1)
                    Y = math.clamp((Input.Position.Y - satval.AbsolutePosition.Y) / Y, 0, 0.995)
                    option:SetColor(Color3.fromHSV(hue, X, 1 - Y))
                elseif editinghue then
                    local X = (hueMain.AbsolutePosition.X + hueMain.AbsoluteSize.X) - hueMain.AbsolutePosition.X
                    X = math.clamp((Input.Position.X - hueMain.AbsolutePosition.X) / X, 0, 0.995)
                    option:SetColor(Color3.fromHSV(1 - X, sat, val))
                elseif editingtrans then
                    option:SetTrans(1 - ((Input.Position.Y - transMain.AbsolutePosition.Y) / transMain.AbsoluteSize.Y))
                end
            end
        end)

        library.unloadMaid:GiveTask(satval.InputEnded:connect(function(Input)
            if Input.UserInputType.Name == 'MouseButton1' then
                editingsatval = false
            end
        end));

        option.hexInput.Text = option.color:ToHex();

        library.unloadMaid:GiveTask(option.rgbInput.FocusLost:connect(function()
            local color = Color3.fromRGB(unpack(option.rgbInput.Text:split(',')));
            return option:SetColor(color)
        end));

        library.unloadMaid:GiveTask(option.hexInput.FocusLost:connect(function()
            local color = Color3.fromHex(option.hexInput.Text);
            return option:SetColor(color);
        end));

        function option:updateVisuals(Color)
            hue, sat, val = Color:ToHSV();
            hue, sat, val = math.clamp(hue, 0, 1), math.clamp(sat, 0, 1), math.clamp(val, 0, 1);

            hue = hue == 0 and 1 or hue
            satval.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
            if option.trans then
                transMain.ImageColor3 = Color3.fromHSV(hue, 1, 1)
            end
            hueSlider.Position = UDim2.new(1 - hue, 0, 0, 0)
            satvalSlider.Position = UDim2.new(sat, 0, 1 - val, 0)

            local color = Color3.fromHSV(hue, sat, val);
            local r, g, b = library.round(color);

            option.hexInput.Text = color:ToHex();
            option.rgbInput.Text = table.concat({r, g, b}, ',');
        end

        return option
    end

    local function createColor(option, parent)
        option.hasInit = true

        if option.sub then
            option.main = option:getMain()
        else
            option.main = library:Create('Frame', {
                LayoutOrder = option.position,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Parent = parent
            })

            option.title = library:Create('TextLabel', {
                Position = UDim2.new(0, 6, 0, 0),
                Size = UDim2.new(1, -12, 1, 0),
                BackgroundTransparency = 1,
                Text = option.text,
                TextSize = 15,
                Font = Enum.Font.Code,
                TextColor3 = Color3.fromRGB(210, 210, 210),
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = option.main
            })
        end

        option.visualize = library:Create(option.sub and 'TextButton' or 'Frame', {
            Position = UDim2.new(1, -(option.subpos or 0) - 24, 0, 4),
            Size = UDim2.new(0, 18, 0, 12),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            BackgroundColor3 = option.color,
            BorderColor3 = Color3.new(),
            Parent = option.main
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2454009026',
            ImageColor3 = Color3.new(),
            ImageTransparency = 0.6,
            Parent = option.visualize
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.fromRGB(60, 60, 60),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.visualize
        })

        library:Create('ImageLabel', {
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.new(),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = option.visualize
        })

        local interest = option.sub and option.visualize or option.main

        if option.sub then
            option.visualize.Text = ''
            option.visualize.AutoButtonColor = false
        end

        library.unloadMaid:GiveTask(interest.InputBegan:connect(function(input)
            if input.UserInputType.Name == 'MouseButton1' then
                if not option.mainHolder then
                    createColorPickerWindow(option)
                end
                if library.popup == option then library.popup:Close() return end
                if library.popup then library.popup:Close() end
                option.open = true
                local pos = option.main.AbsolutePosition
                option.mainHolder.Position = UDim2.new(0, pos.X + 36 + (option.trans and -16 or 0), 0, pos.Y + 56)
                option.mainHolder.Visible = true
                library.popup = option
                option.visualize.BorderColor3 = library.flags.menuAccentColor
            end
            if input.UserInputType.Name == 'MouseMovement' then
                if not library.warning and not library.slider then
                    option.visualize.BorderColor3 = library.flags.menuAccentColor
                end
                if option.tip then
                    library.tooltip.Text = option.tip;
                end
            end
        end));

        makeTooltip(interest, option);

        library.unloadMaid:GiveTask(interest.InputEnded:connect(function(input)
            if input.UserInputType.Name == 'MouseMovement' then
                if not option.open then
                    option.visualize.BorderColor3 = Color3.new();
                end;
            end;
        end));

        function option:SetColor(newColor, nocallback, noFire)
            newColor = newColor or Color3.new(1, 1, 1)
            if self.mainHolder then
                self:updateVisuals(newColor)
            end
            option.visualize.BackgroundColor3 = newColor
            library.flags[self.flag] = newColor
            self.color = newColor

            if not nocallback then
                task.spawn(self.callback, newColor)
            end

            if (not noFire) then
                library.OnFlagChanged:Fire(self);
            end;
        end

        if option.trans then
            function option:SetTrans(value, manual)
                value = math.clamp(tonumber(value) or 0, 0, 1)
                if self.transSlider then
                    self.transSlider.Position = UDim2.new(0, 0, value, 0)
                end
                self.trans = value
                library.flags[self.flag .. 'Transparency'] = 1 - value
                task.spawn(self.calltrans, value)
            end
            option:SetTrans(option.trans)
        end

        task.defer(function()
            if library then
                option:SetColor(option.color)
            end
        end)

        function option:Close()
            library.popup = nil
            self.open = false
            self.mainHolder.Visible = false
            option.visualize.BorderColor3 = Color3.new()
        end
    end

    function library:AddTab(title, pos)
        local tab = {canInit = true, columns = {}, title = tostring(title)}
        table.insert(self.tabs, pos or #self.tabs + 1, tab)

        function tab:AddColumn()
            local column = {sections = {}, position = #self.columns, canInit = true, tab = self}
            table.insert(self.columns, column)

            function column:AddSection(title)
                local section = {title = tostring(title), options = {}, canInit = true, column = self}
                table.insert(self.sections, section)

                function section:AddLabel(text)
                    local option = {text = text}
                    option.section = self
                    option.type = 'label'
                    option.position = #self.options
                    table.insert(self.options, option)

                    if library.hasInit and self.hasInit then
                        createLabel(option, self.content)
                    else
                        option.Init = createLabel
                    end

                    return option
                end

                function section:AddDivider(text, tip)
                    local option = {text = text, tip = tip}
                    option.section = self
                    option.type = 'divider'
                    option.position = #self.options
                    table.insert(self.options, option)

                    if library.hasInit and self.hasInit then
                        createDivider(option, self.content)
                    else
                        option.Init = createDivider
                    end

                    return option
                end

                function section:AddToggle(option)
                    option = typeof(option) == 'table' and option or {}
                    option.section = self
                    option.text = tostring(option.text)
                    option.state = typeof(option.state) == 'boolean' and option.state or false
                    option.default = option.state;
                    option.callback = typeof(option.callback) == 'function' and option.callback or function() end
                    option.type = 'toggle'
                    option.position = #self.options
                    option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
                    option.subcount = 0
                    option.tip = option.tip and tostring(option.tip)
                    option.style = option.style == 2
                    library.flags[option.flag] = option.state
                    table.insert(self.options, option)
                    library.options[option.flag] = option

                    function option:AddColor(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        subOption.subpos = self.subcount * 24
                        function subOption:getMain() return option.main end
                        self.subcount = self.subcount + 1
                        return section:AddColor(subOption)
                    end

                    function option:AddBind(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        subOption.subpos = self.subcount * 24
                        function subOption:getMain() return option.main end
                        self.subcount = self.subcount + 1
                        return section:AddBind(subOption)
                    end

                    function option:AddList(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        function subOption:getMain() return option.main end
                        self.subcount = self.subcount + 1
                        return section:AddList(subOption)
                    end

                    function option:AddSlider(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        function subOption:getMain() return option.main end
                        self.subcount = self.subcount + 1

                        subOption.parent = option;
                        return section:AddSlider(subOption)
                    end

                    if library.hasInit and self.hasInit then
                        createToggle(option, self.content)
                    else
                        option.Init = createToggle
                    end

                    return option
                end

                function section:AddButton(option)
                    option = typeof(option) == 'table' and option or {}
                    option.section = self
                    option.text = tostring(option.text)
                    option.callback = typeof(option.callback) == 'function' and option.callback or function() end
                    option.type = 'button'
                    option.position = #self.options
                    option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
                    option.subcount = 0
                    option.tip = option.tip and tostring(option.tip)
                    table.insert(self.options, option)
                    library.options[option.flag] = option

                    function option:AddBind(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        subOption.subpos = self.subcount * 24
                        function subOption:getMain() option.main.Size = UDim2.new(1, 0, 0, 40) return option.main end
                        self.subcount = self.subcount + 1
                        return section:AddBind(subOption)
                    end

                    function option:AddColor(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        subOption.subpos = self.subcount * 24
                        function subOption:getMain() option.main.Size = UDim2.new(1, 0, 0, 40) return option.main end
                        self.subcount = self.subcount + 1
                        return section:AddColor(subOption)
                    end

                    function option:AddButton(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        subOption.subpos = self.subcount * 24
                        function subOption:getMain() return option.main end
                        self.subcount = self.subcount + 1
                        subOption.parent = option;
                        section:AddButton(subOption)

                        return option;
                    end;

                    function option:SetText(text)
                        option.title.Text = text;
                    end;

                    if library.hasInit and self.hasInit then
                        createButton(option, self.content)
                    else
                        option.Init = createButton
                    end

                    return option
                end

                function section:AddBind(option)
                    option = typeof(option) == 'table' and option or {}
                    option.section = self
                    option.text = tostring(option.text)
                    option.key = (option.key and option.key.Name) or option.key or 'none'
                    option.nomouse = typeof(option.nomouse) == 'boolean' and option.nomouse or false
                    option.mode = typeof(option.mode) == 'string' and ((option.mode == 'toggle' or option.mode == 'hold') and option.mode) or 'toggle'
                    option.callback = typeof(option.callback) == 'function' and option.callback or function() end
                    option.type = 'bind'
                    option.position = #self.options
                    option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
                    option.tip = option.tip and tostring(option.tip)
                    table.insert(self.options, option)
                    library.options[option.flag] = option

                    if library.hasInit and self.hasInit then
                        createBind(option, self.content)
                    else
                        option.Init = createBind
                    end

                    return option
                end

                function section:AddSlider(option)
                    option = typeof(option) == 'table' and option or {}
                    option.section = self
                    option.text = tostring(option.text)
                    option.min = typeof(option.min) == 'number' and option.min or 0
                    option.max = typeof(option.max) == 'number' and option.max or 0
                    option.value = option.min < 0 and 0 or math.clamp(typeof(option.value) == 'number' and option.value or option.min, option.min, option.max)
                    option.default = option.value;
                    option.callback = typeof(option.callback) == 'function' and option.callback or function() end
                    option.float = typeof(option.value) == 'number' and option.float or 1
                    option.suffix = option.suffix and tostring(option.suffix) or ''
                    option.textpos = option.textpos == 2
                    option.type = 'slider'
                    option.position = #self.options
                    option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
                    option.subcount = 0
                    option.tip = option.tip and tostring(option.tip)
                    library.flags[option.flag] = option.value
                    table.insert(self.options, option)
                    library.options[option.flag] = option

                    function option:AddColor(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        subOption.subpos = self.subcount * 24
                        function subOption:getMain() return option.main end
                        self.subcount = self.subcount + 1
                        return section:AddColor(subOption)
                    end

                    function option:AddBind(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        subOption.subpos = self.subcount * 24
                        function subOption:getMain() return option.main end
                        self.subcount = self.subcount + 1
                        return section:AddBind(subOption)
                    end

                    if library.hasInit and self.hasInit then
                        createSlider(option, self.content)
                    else
                        option.Init = createSlider
                    end

                    return option
                end

                function section:AddList(option)
                    option = typeof(option) == 'table' and option or {}
                    option.section = self
                    option.text = tostring(option.text)
                    option.values = typeof(option.values) == 'table' and option.values or {}
                    option.callback = typeof(option.callback) == 'function' and option.callback or function() end
                    option.multiselect = typeof(option.multiselect) == 'boolean' and option.multiselect or false
                    --option.groupbox = (not option.multiselect) and (typeof(option.groupbox) == 'boolean' and option.groupbox or false)
                    option.value = option.multiselect and (typeof(option.value) == 'table' and option.value or {}) or tostring(option.value or option.values[1] or '')
                    if option.multiselect then
                        for i,v in next, option.values do
                            option.value[v] = false
                        end
                    end
                    option.max = option.max or 8
                    option.open = false
                    option.type = 'list'
                    option.position = #self.options
                    option.labels = {}
                    option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
                    option.subcount = 0
                    option.tip = option.tip and tostring(option.tip)
                    library.flags[option.flag] = option.value
                    table.insert(self.options, option)
                    library.options[option.flag] = option

                    function option:AddValue(value, state)
                        if self.multiselect then
                            self.values[value] = state
                        else
                            table.insert(self.values, value)
                        end
                    end

                    function option:AddColor(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        subOption.subpos = self.subcount * 24
                        function subOption:getMain() return option.main end
                        self.subcount = self.subcount + 1
                        return section:AddColor(subOption)
                    end

                    function option:AddBind(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        subOption.subpos = self.subcount * 24
                        function subOption:getMain() return option.main end
                        self.subcount = self.subcount + 1
                        return section:AddBind(subOption)
                    end

                    if library.hasInit and self.hasInit then
                        createList(option, self.content)
                    else
                        option.Init = createList
                    end

                    return option
                end

                function section:AddBox(option)
                    option = typeof(option) == 'table' and option or {}
                    option.section = self
                    option.text = tostring(option.text)
                    option.value = tostring(option.value or '')
                    option.callback = typeof(option.callback) == 'function' and option.callback or function() end
                    option.type = 'box'
                    option.position = #self.options
                    option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
                    option.tip = option.tip and tostring(option.tip)
                    library.flags[option.flag] = option.value
                    table.insert(self.options, option)
                    library.options[option.flag] = option

                    if library.hasInit and self.hasInit then
                        createBox(option, self.content)
                    else
                        option.Init = createBox
                    end

                    return option
                end

                function section:AddColor(option)
                    option = typeof(option) == 'table' and option or {}
                    option.section = self
                    option.text = tostring(option.text)
                    option.color = typeof(option.color) == 'table' and Color3.new(option.color[1], option.color[2], option.color[3]) or option.color or Color3.new(1, 1, 1)
                    option.callback = typeof(option.callback) == 'function' and option.callback or function() end
                    option.calltrans = typeof(option.calltrans) == 'function' and option.calltrans or (option.calltrans == 1 and option.callback) or function() end
                    option.open = false
                    option.default = option.color;
                    option.trans = tonumber(option.trans)
                    option.subcount = 1
                    option.type = 'color'
                    option.position = #self.options
                    option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
                    option.tip = option.tip and tostring(option.tip)
                    library.flags[option.flag] = option.color
                    table.insert(self.options, option)
                    library.options[option.flag] = option

                    function option:AddColor(subOption)
                        subOption = typeof(subOption) == 'table' and subOption or {}
                        subOption.sub = true
                        subOption.subpos = self.subcount * 24
                        function subOption:getMain() return option.main end
                        self.subcount = self.subcount + 1
                        return section:AddColor(subOption)
                    end

                    if option.trans then
                        library.flags[option.flag .. 'Transparency'] = option.trans
                    end

                    if library.hasInit and self.hasInit then
                        createColor(option, self.content)
                    else
                        option.Init = createColor
                    end

                    return option
                end

                function section:SetTitle(newTitle)
                    self.title = tostring(newTitle)
                    if self.titleText then
                        self.titleText.Text = tostring(newTitle)
                    end
                end

                function section:Init()
                    if self.hasInit then return end
                    self.hasInit = true

                    self.main = library:Create('Frame', {
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        BorderColor3 = Color3.new(),
                        Parent = column.main
                    })

                    self.content = library:Create('Frame', {
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        BorderColor3 = Color3.fromRGB(60, 60, 60),
                        BorderMode = Enum.BorderMode.Inset,
                        Parent = self.main
                    })

                    library:Create('ImageLabel', {
                        Size = UDim2.new(1, -2, 1, -2),
                        Position = UDim2.new(0, 1, 0, 1),
                        BackgroundTransparency = 1,
                        Image = 'rbxassetid://2592362371',
                        ImageColor3 = Color3.new(),
                        ScaleType = Enum.ScaleType.Slice,
                        SliceCenter = Rect.new(2, 2, 62, 62),
                        Parent = self.main
                    })

                    table.insert(library.theme, library:Create('Frame', {
                        Size = UDim2.new(1, 0, 0, 1),
                        BackgroundColor3 = library.flags.menuAccentColor,
                        BorderSizePixel = 0,
                        BorderMode = Enum.BorderMode.Inset,
                        Parent = self.main
                    }))

                    local layout = library:Create('UIListLayout', {
                        HorizontalAlignment = Enum.HorizontalAlignment.Center,
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        Padding = UDim.new(0, 2),
                        Parent = self.content
                    })

                    library:Create('UIPadding', {
                        PaddingTop = UDim.new(0, 12),
                        Parent = self.content
                    })

                    self.titleText = library:Create('TextLabel', {
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, 12, 0, 0),
                        Size = UDim2.new(0, TextService:GetTextSize(self.title, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X + 10, 0, 3),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        BorderSizePixel = 0,
                        Text = self.title,
                        TextSize = 15,
                        Font = Enum.Font.Code,
                        TextColor3 = Color3.new(1, 1, 1),
                        Parent = self.main
                    })

                    library.unloadMaid:GiveTask(layout.Changed:connect(function()
                        self.main.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 16)
                    end));

                    for _, option in next, self.options do
                        option.Init(option, self.content)
                    end
                end

                if library.hasInit and self.hasInit then
                    section:Init()
                end

                return section
            end

            function column:Init()
                if self.hasInit then return end
                self.hasInit = true

                self.main = library:Create('ScrollingFrame', {
                    ZIndex = 2,
                    Position = UDim2.new(0, 6 + (self.position * 239), 0, 2),
                    Size = UDim2.new(0, 233, 1, -4),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarImageColor3 = Color3.fromRGB(),
                    ScrollBarThickness = 4,
                    VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    Visible = true
                })

                local layout = library:Create('UIListLayout', {
                    HorizontalAlignment = Enum.HorizontalAlignment.Center,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 12),
                    Parent = self.main
                })

                library:Create('UIPadding', {
                    PaddingTop = UDim.new(0, 8),
                    PaddingLeft = UDim.new(0, 2),
                    PaddingRight = UDim.new(0, 2),
                    Parent = self.main
                })

                library.unloadMaid:GiveTask(layout.Changed:connect(function()
                    self.main.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 14)
                end));

                for _, section in next, self.sections do
                    if section.canInit and #section.options > 0 then
                        section:Init()
                    end
                end
            end

            if library.hasInit and self.hasInit then
                column:Init()
            end

            return column
        end

        function tab:Init()
            if self.hasInit then return end
            self.hasInit = true

            local size = TextService:GetTextSize(self.title, 18, Enum.Font.Code, Vector2.new(9e9, 9e9)).X + 10

            self.button = library:Create('TextLabel', {
                Position = UDim2.new(0, library.tabSize, 0, 22),
                Size = UDim2.new(0, size, 0, 30),
                BackgroundTransparency = 1,
                Text = self.title,
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 15,
                Font = Enum.Font.Code,
                TextWrapped = true,
                ClipsDescendants = true,
                Parent = library.main
            });

            library.tabSize = library.tabSize + size

            library.unloadMaid:GiveTask(self.button.InputBegan:connect(function(input)
                if input.UserInputType.Name == 'MouseButton1' then
                    library:selectTab(self);
                end;
            end));

            for _, column in next, self.columns do
                if column.canInit then
                    column:Init();
                end;
            end;
        end;

        if self.hasInit then
            tab:Init()
        end

        return tab
    end

    function library:AddWarning(warning)
        warning = typeof(warning) == 'table' and warning or {}
        warning.text = tostring(warning.text)
        warning.type = warning.type == 'confirm' and 'confirm' or ''

        local answer
        function warning:Show()
            library.warning = warning
            if warning.main and warning.type == '' then
                warning.main:Destroy();
                warning.main = nil;
            end
            if library.popup then library.popup:Close() end
            if not warning.main then
                warning.main = library:Create('TextButton', {
                    ZIndex = 2,
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 0.3,
                    BackgroundColor3 = Color3.new(),
                    BorderSizePixel = 0,
                    Text = '',
                    AutoButtonColor = false,
                    Parent = library.main
                })

                warning.message = library:Create('TextLabel', {
                    ZIndex = 2,
                    Position = UDim2.new(0, 20, 0.5, -60),
                    Size = UDim2.new(1, -40, 0, 40),
                    BackgroundTransparency = 1,
                    TextSize = 16,
                    Font = Enum.Font.Code,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextWrapped = true,
                    RichText = true,
                    Parent = warning.main
                })

                if warning.type == 'confirm' then
                    local button = library:Create('TextLabel', {
                        ZIndex = 2,
                        Position = UDim2.new(0.5, -105, 0.5, -10),
                        Size = UDim2.new(0, 100, 0, 20),
                        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                        BorderColor3 = Color3.new(),
                        Text = 'Yes',
                        TextSize = 16,
                        Font = Enum.Font.Code,
                        TextColor3 = Color3.new(1, 1, 1),
                        Parent = warning.main
                    })

                    library:Create('ImageLabel', {
                        ZIndex = 2,
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Image = 'rbxassetid://2454009026',
                        ImageColor3 = Color3.new(),
                        ImageTransparency = 0.8,
                        Parent = button
                    })

                    library:Create('ImageLabel', {
                        ZIndex = 2,
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Image = 'rbxassetid://2592362371',
                        ImageColor3 = Color3.fromRGB(60, 60, 60),
                        ScaleType = Enum.ScaleType.Slice,
                        SliceCenter = Rect.new(2, 2, 62, 62),
                        Parent = button
                    })

                    local button1 = library:Create('TextLabel', {
                        ZIndex = 2,
                        Position = UDim2.new(0.5, 5, 0.5, -10),
                        Size = UDim2.new(0, 100, 0, 20),
                        BackgroundColor3 = Color3.fromRGB(40, 40, 40),
                        BorderColor3 = Color3.new(),
                        Text = 'No',
                        TextSize = 16,
                        Font = Enum.Font.Code,
                        TextColor3 = Color3.new(1, 1, 1),
                        Parent = warning.main
                    })

                    library:Create('ImageLabel', {
                        ZIndex = 2,
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Image = 'rbxassetid://2454009026',
                        ImageColor3 = Color3.new(),
                        ImageTransparency = 0.8,
                        Parent = button1
                    })

                    library:Create('ImageLabel', {
                        ZIndex = 2,
                        Size = UDim2.new(1, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Image = 'rbxassetid://2592362371',
                        ImageColor3 = Color3.fromRGB(60, 60, 60),
                        ScaleType = Enum.ScaleType.Slice,
                        SliceCenter = Rect.new(2, 2, 62, 62),
                        Parent = button1
                    })

                    library.unloadMaid:GiveTask(button.InputBegan:connect(function(input)
                        if input.UserInputType.Name == 'MouseButton1' then
                            answer = true
                        end
                    end));

                    library.unloadMaid:GiveTask(button1.InputBegan:connect(function(input)
                        if input.UserInputType.Name == 'MouseButton1' then
                            answer = false
                        end
                    end));
                else
                    local button = library:Create('TextLabel', {
                        ZIndex = 2,
                        Position = UDim2.new(0.5, -50, 0.5, -10),
                        Size = UDim2.new(0, 100, 0, 20),
                        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
                        BorderColor3 = Color3.new(),
                        Text = 'OK',
                        TextSize = 16,
                        Font = Enum.Font.Code,
                        TextColor3 = Color3.new(1, 1, 1),
                        Parent = warning.main
                    })

                    library.unloadMaid:GiveTask(button.InputEnded:connect(function(input)
                        if input.UserInputType.Name == 'MouseButton1' then
                            answer = true
                        end
                    end));
                end
            end
            warning.main.Visible = true
            warning.message.Text = warning.text

            repeat task.wait() until answer ~= nil;
            library.warning = nil;

            local answerCopy = answer;
            warning:Close();

            return answerCopy;
        end

        function warning:Close()
            answer = nil
            if not warning.main then return end
            warning.main.Visible = false
        end

        return warning
    end

    function library:Close()
        self.open = not self.open

        if self.main then
            if self.popup then
                self.popup:Close()
            end

            self.base.Enabled = self.open
        end

        library.tooltip.Position = UDim2.fromScale(10, 10);
    end

    function library:Init(silent)
        if self.hasInit then return end

        self.hasInit = true
        self.base = library:Create('ScreenGui', {IgnoreGuiInset = true, AutoLocalize = false, Enabled = not silent})
        self.dummyBox = library:Create('TextBox', {Visible = false, Parent = self.base});
        self.dummyModal = library:Create('TextButton', {Visible = false, Modal = true, Parent = self.base});

        self.unloadMaid:GiveTask(self.base);

        if RunService:IsStudio() then
            self.base.Parent = script.Parent.Parent
        elseif syn then
            if(gethui) then
                self.base.Parent = gethui();
            else
                pcall(syn.protect_gui, self.base);
                self.base.Parent = CoreGui;
            end;
        end

        self.main = self:Create('ImageButton', {
            AutoButtonColor = false,
            Position = UDim2.new(0, 100, 0, 46),
            Size = UDim2.new(0, 500, 0, 600),
            BackgroundColor3 = Color3.fromRGB(20, 20, 20),
            BorderColor3 = Color3.new(),
            ScaleType = Enum.ScaleType.Tile,
            Visible = true,
            Parent = self.base
        })

        local top = self:Create('Frame', {
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundColor3 = Color3.fromRGB(30, 30, 30),
            BorderColor3 = Color3.new(),
            Parent = self.main
        })

        self.titleLabel = self:Create('TextLabel', {
            Position = UDim2.new(0, 6, 0, -1),
            Size = UDim2.new(0, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = tostring(self.title),
            Font = Enum.Font.Code,
            TextSize = 18,
            TextColor3 = Color3.new(1, 1, 1),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.main
        })

        table.insert(library.theme, self:Create('Frame', {
            Size = UDim2.new(1, 0, 0, 1),
            Position = UDim2.new(0, 0, 0, 24),
            BackgroundColor3 = library.flags.menuAccentColor,
            BorderSizePixel = 0,
            Parent = self.main
        }))

        library:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2454009026',
            ImageColor3 = Color3.new(),
            ImageTransparency = 0.4,
            Parent = top
        })

        self.tabHighlight = self:Create('Frame', {
            BackgroundColor3 = library.flags.menuAccentColor,
            BorderSizePixel = 0,
            Parent = self.main
        })
        table.insert(library.theme, self.tabHighlight)

        self.columnHolder = self:Create('Frame', {
            Position = UDim2.new(0, 5, 0, 55),
            Size = UDim2.new(1, -10, 1, -60),
            BackgroundTransparency = 1,
            Parent = self.main
        })

        self.tooltip = self:Create('TextLabel', {
            ZIndex = 2,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            TextSize = 15,
            Size = UDim2.fromOffset(0, 0),
            Position = UDim2.fromScale(10, 10),
            Font = Enum.Font.Code,
            TextColor3 = Color3.new(1, 1, 1),
            Visible = true,
            Active = false,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.base,
            AutomaticSize = Enum.AutomaticSize.XY
        })

        self:Create('UISizeConstraint', {
            Parent = self.tooltip,
            MaxSize = Vector2.new(400, 1000),
            MinSize = Vector2.new(0, 0),
        });

        self:Create('Frame', {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 0),
            Size = UDim2.new(1, 10, 1, 0),
            Active = false,
            Style = Enum.FrameStyle.RobloxRound,
            Parent = self.tooltip
        })

        self:Create('ImageLabel', {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.fromRGB(60, 60, 60),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = self.main
        })

        self:Create('ImageLabel', {
            Size = UDim2.new(1, -2, 1, -2),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundTransparency = 1,
            Image = 'rbxassetid://2592362371',
            ImageColor3 = Color3.new(),
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(2, 2, 62, 62),
            Parent = self.main
        })

        library.unloadMaid:GiveTask(top.InputBegan:connect(function(input)
            if input.UserInputType.Name == 'MouseButton1' then
                dragObject = self.main
                dragging = true
                dragStart = input.Position
                startPos = dragObject.Position
                if library.popup then library.popup:Close() end
            end
        end));

        library.unloadMaid:GiveTask(top.InputChanged:connect(function(input)
            if dragging and input.UserInputType.Name == 'MouseMovement' then
                dragInput = input
            end
        end));

        library.unloadMaid:GiveTask(top.InputEnded:connect(function(input)
            if input.UserInputType.Name == 'MouseButton1' then
                dragging = false
            end
        end));

        local titleTextSize = TextService:GetTextSize(self.titleLabel.Text, 18, Enum.Font.Code, Vector2.new(1000, 0));

        local searchLabel = library:Create('ImageLabel', {
            Position = UDim2.new(0, titleTextSize.X + 10, 0.5, -8),
            Size = UDim2.new(0, 16, 0, 16),
            BackgroundTransparency = 1,
            Image = 'rbxasset://textures/ui/Settings/ShareGame/icons.png',
            ImageRectSize = Vector2.new(16, 16),
            ImageRectOffset = Vector2.new(6, 106),
            ClipsDescendants = true,
            Parent = self.titleLabel
        });

        local searchBox = library:Create('TextBox', {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(searchLabel.AbsolutePosition.X-80, 5),
            Size = UDim2.fromOffset(50, 15),
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = self.titleLabel,
            Text = '',
            PlaceholderText = 'Type something to search...',
            Visible = false
        });

        local searchContainer = library:Create('ScrollingFrame', {
            BackgroundTransparency = 1,
            Visible = false,
            Size = UDim2.fromScale(1, 1),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = library.columnHolder,
            BorderSizePixel = 0,
            ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
            ScrollBarThickness = 6,
            CanvasSize = UDim2.new(),
            ScrollingDirection = Enum.ScrollingDirection.Y,
            VerticalScrollBarInset = Enum.ScrollBarInset.Always,
            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
        });

        library:Create('UIListLayout', {
            Parent = searchContainer
        })

        local allFoundResults = {};
        local modifiedNames = {};

        local function clearFoundResult()
            for _, option in next, allFoundResults do
                option.main.Parent = option.originalParent;
            end;

            for _, option in next, modifiedNames do
                option.title.Text = option.text;
                option.main.Parent = option.originalParent;
            end;

            table.clear(allFoundResults);
            table.clear(modifiedNames);
        end;

        local sFind, sLower = string.find, string.lower;

        library.unloadMaid:GiveTask(searchBox:GetPropertyChangedSignal('Text'):Connect(function()
            local text = string.lower(searchBox.Text):gsub('%s', '');

            for _, v in next, library.options do
                if (not v.originalParent) then
                    v.originalParent = v.main.Parent;
                end;
            end;

            clearFoundResult();

            for _, v in next, library.currentTab.columns do
                v.main.Visible = text == '' and true or false;
            end;

            if (text == '') then return; end;
            local matchedResults = false;

            for _, v in next, library.options do
                local main = v.main;

                if (v.text == 'Enable' or v.parentFlag) then
                    if (v.type == 'toggle' or v.type == 'bind') then
                        local parentName = v.parentFlag and 'Bind' or v.section.title;
                        v.title.Text = string.format('%s [%s]', v.text, parentName);

                        table.insert(modifiedNames, v);
                    end;
                end;

                if (sFind(sLower(v.text), text) or sFind(sLower(v.flag), text)) then
                    matchedResults = true;
                    main.Parent = searchContainer;
                    table.insert(allFoundResults, v);
                else
                    main.Parent = v.originalParent;
                end;
            end;

            searchContainer.Visible = matchedResults;
        end));

        library.unloadMaid:GiveTask(searchLabel.InputBegan:Connect(function(inputObject)
            if(inputObject.UserInputType ~= Enum.UserInputType.MouseButton1) then return end;
            searchBox.Visible = true;
            searchBox:CaptureFocus();
        end));

        library.unloadMaid:GiveTask(searchBox.FocusLost:Connect(function()
            if (searchBox.Text:gsub('%s', '') ~= '') then return end;
            searchBox.Visible = false;
        end));


        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

        function self:selectTab(tab)
            if self.currentTab == tab then return end
            if library.popup then library.popup:Close() end
            clearFoundResult();
            searchBox.Visible = false;
            searchBox.Text = '';

            if self.currentTab then
                self.currentTab.button.TextColor3 = Color3.fromRGB(255, 255, 255)
                for _, column in next, self.currentTab.columns do
                    column.main.Parent = nil;
                    column.main.Visible = true;
                end
            end
            self.main.Size = UDim2.new(0, 16 + ((#tab.columns < 2 and 2 or #tab.columns) * 239), 0, 600)
            self.currentTab = tab
            tab.button.TextColor3 = library.flags.menuAccentColor;

            TweenService:Create(self.tabHighlight, tweenInfo, {
                Position = UDim2.new(0, tab.button.Position.X.Offset, 0, 50),
                Size = UDim2.new(0, tab.button.AbsoluteSize.X, 0, -1)
            }):Play();

            for _, column in next, tab.columns do
                column.main.Parent = self.columnHolder
            end
        end

        task.spawn(function()
            while library do
                local Configs = self:GetConfigs()
                for _, config in next, Configs do
                    if config ~= 'nil' and not table.find(self.options.configList.values, config) then
                        self.options.configList:AddValue(config)
                    end
                end
                for _, config in next, self.options.configList.values do
                    if config ~= 'nil' and not table.find(Configs, config) then
                        self.options.configList:RemoveValue(config)
                    end
                end
                task.wait(1);
            end
        end)

        for _, tab in next, self.tabs do
            if tab.canInit then
                tab:Init();
            end;
        end;

        self:AddConnection(UserInputService.InputEnded, function(input)
            if (input.UserInputType.Name == 'MouseButton1') and self.slider then
                self.slider.slider.BorderColor3 = Color3.new();
                self.slider = nil;
            end;
        end);

        self:AddConnection(UserInputService.InputChanged, function(input)
            if self.open then
                if input == dragInput and dragging and library.draggable then
                    local delta = input.Position - dragStart;
                    local yPos = (startPos.Y.Offset + delta.Y) < -36 and -36 or startPos.Y.Offset + delta.Y;

                    dragObject:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, yPos), 'Out', 'Quint', 0.1, true);
                end;

                if self.slider and input.UserInputType.Name == 'MouseMovement' then
                    self.slider:SetValue(self.slider.min + ((input.Position.X - self.slider.slider.AbsolutePosition.X) / self.slider.slider.AbsoluteSize.X) * (self.slider.max - self.slider.min));
                end;
            end;
        end);

        local configData = readFileAndDecodeIt(library.foldername .. '/' .. library.fileext);

        if (configData) then
            library.configVars = configData;
            library:LoadConfig(configData.config);

            library.OnLoad:Connect(function()
                library.options.configList:SetValue(library.loadedConfig or 'default');
            end);
        else
            print('[Script] [Config Loader] An error has occured', configData);
        end;

        self:selectTab(self.tabs[1]);

        if (not silent) then
            self:Close();
        else
            self.open = false;
        end;

        library.OnLoad:Fire();
        library.OnLoad:Destroy();
        library.OnLoad = nil;
    end;

    function library:SetTitle(text)
        if (not self.titleLabel) then
            return;
        end;

        self.titleLabel.Text = text;
    end;

    do -- // Load Basics
        local configWarning = library:AddWarning({type = 'confirm'})
        local messageWarning = library:AddWarning();

        function library:ShowConfirm(text)
            configWarning.text = text;
            return configWarning:Show();
        end;

        function library:ShowMessage(text)
            messageWarning.text = text;
            return messageWarning:Show();
        end

        local function showBasePrompt(text)
            local r, g, b = library.round(library.flags.menuAccentColor);

            local configName = text == 'create' and library.flags.configName or library.flags.configList;
            local trimedValue = configName:gsub('%s', '');

            if(trimedValue == '') then
                library:ShowMessage(string.format('Can not %s a config with no name !', text));
                return false;
            end;

            return library:ShowConfirm(string.format(
                'Are you sure you want to %s config <font color=\'rgb(%s, %s, %s)\'>%s</font>',
                text,
                r,
                g,
                b,
                configName
            ));
        end;

        local joinDiscord;

        do -- // Utils
            function joinDiscord(code)
                for i = 6463, 6472 do -- // Just cause there is a 10 range port
                    if(pcall(function()
                        syn.request({
                            Url = ('http://127.0.0.1:%s/rpc?v=1'):format(i),
                            Method = 'POST',
                            Headers = {
                                ['Content-Type'] = 'application/json',
                                Origin = 'https://discord.com' -- // memery moment
                            },
                            Body = ('{"cmd":"INVITE_BROWSER","args":{"code":"%s"},"nonce":"%s"}'):format(code, string.lower(HttpService:GenerateGUID(false)))
                        });
                    end)) then
                        print('found port', i);
                        break;
                    end;
                end;
            end;
        end;

        local maid = Maid.new();
        library.unloadMaid:GiveTask(function()
            maid:Destroy();
        end);

        local settingsTab       = library:AddTab('Settings', 100);
        local settingsColumn    = settingsTab:AddColumn();
        local settingsColumn1   = settingsTab:AddColumn();
        local settingsMain      = settingsColumn:AddSection('Main');
        local settingsMenu      = settingsColumn:AddSection('Menu');
        local configSection     = settingsColumn1:AddSection('Configs');
        local discordSection    = settingsColumn:AddSection('Discord');
        local BackgroundArray   = {};

        local Backgrounds = {
            Floral  = 5553946656,
            Flowers = 6071575925,
            Circles = 6071579801,
            Hearts  = 6073763717,
        };

        task.spawn(function()
            for i, v in next, Backgrounds do
                table.insert(BackgroundArray, 'rbxassetid://' .. v);
            end;

            ContentProvider:PreloadAsync(BackgroundArray);
        end);

        local lastShownNotifAt = 0;

        local function setCustomBackground()
            local imageURL = library.flags.customBackground;
            imageURL = imageURL:gsub('%s', '');

            if (imageURL == '') then return end;

            if (not isfolder('Aztup Hub V3/CustomBackgrounds')) then
                makefolder('Aztup Hub V3/CustomBackgrounds');
            end;

            local path = string.format('Aztup Hub V3/CustomBackgrounds/%s.bin', syn.crypt.hash(imageURL));

            if (not isfile(path)) then
                local suc, httpRequest = pcall(syn.request, {
                    Url = imageURL,
                });

                if (not suc) then return library:ShowMessage('The url you have specified for the custom background is invalid.'); end;

                if (not httpRequest.Success) then return library:ShowMessage(string.format('Request failed %d', httpRequest.StatusCode)); end;
                local imgType = httpRequest.Headers['Content-Type']:lower();
                if (imgType ~= 'image/png' and imgType ~= 'image/jpeg') then return library:ShowMessage('Only PNG and JPEG are supported'); end;

                writefile(path, httpRequest.Body);
            end;

            library.main.Image = getsynasset(path);

            local acColor = library.flags.menuBackgroundColor;
            local r, g, b = acColor.R * 255, acColor.G * 255, acColor.B * 255;

            if (r <= 100 and g <= 100 and b <= 100 and tick() - lastShownNotifAt > 1) then
                lastShownNotifAt = tick();
                ToastNotif.new({text = 'Your menu accent color is dark custom background may not show.', duration = 20});
            end;
        end;

        settingsMain:AddBox({
            text = 'Custom Background',
            tip = 'Put a valid image link here',
            callback = setCustomBackground
        });

        library.OnLoad:Connect(function()
            local customBackground = library.flags.customBackground;
            if (customBackground:gsub('%s', '') == '') then return end;

            task.defer(setCustomBackground);
        end);

        do
            local scaleTypes = {};

            for _, scaleType in next, Enum.ScaleType:GetEnumItems() do
                table.insert(scaleTypes, scaleType.Name);
            end;

            settingsMain:AddList({
                text = 'Background Scale Type',
                values = scaleTypes,
                callback = function()
                    library.main.ScaleType = Enum.ScaleType[library.flags.backgroundScaleType];
                end
            });
        end;

        settingsMain:AddButton({
            text = 'Unload Menu',
            nomouse = true,
            callback = function()
                library:Unload()
            end
        });

        settingsMain:AddBind({
            text = 'Unload Key',
            nomouse = true,
            callback = library.options.unloadMenu.callback
        });

        -- settingsMain:AddToggle({
        --     text = 'Remote Control'
        -- });

        settingsMenu:AddBind({
            text = 'Open / Close',
            flag = 'UI Toggle',
            nomouse = true,
            key = 'LeftAlt',
            callback = function() library:Close() end
        })

        settingsMenu:AddColor({
            text = 'Accent Color',
            flag = 'Menu Accent Color',
            color = Color3.fromRGB(18, 127, 253),
            callback = function(Color)
                if library.currentTab then
                    library.currentTab.button.TextColor3 = Color
                end

                for _, obj in next, library.theme do
                    obj[(obj.ClassName == 'TextLabel' and 'TextColor3') or (obj.ClassName == 'ImageLabel' and 'ImageColor3') or 'BackgroundColor3'] = Color
                end
            end
        })

        settingsMenu:AddToggle({
            text = 'Keybind Visualizer',
            state = true,
            callback = function(state)
                return visualizer:SetEnabled(state);
            end
        }):AddColor({
            text = 'Keybind Visualizer Color',
            callback = function(color)
                return visualizer:UpdateColor(color);
            end
        });

        settingsMenu:AddToggle({
            text = 'Rainbow Keybind Visualizer',
            callback = function(t)
                if (not t) then
                    return maid.rainbowKeybindVisualizer;
                end;

                maid.rainbowKeybindVisualizer = task.spawn(function()
                    while task.wait() do
                        visualizer:UpdateColor(library.chromaColor);
                    end;
                end);
            end
        })

        settingsMenu:AddList({
            text = 'Background',
            flag = 'UI Background',
            values = {'Floral', 'Flowers', 'Circles', 'Hearts'},
            callback = function(Value)
                if Backgrounds[Value] then
                    library.main.Image = 'rbxassetid://' .. Backgrounds[Value]
                end
            end
        }):AddColor({
            flag = 'Menu Background Color',
            color = Color3.new(),
            trans = 1,
            callback = function(Color)
                library.main.ImageColor3 = Color
            end,
            calltrans = function(Value)
                library.main.ImageTransparency = 1 - Value
            end
        });

        settingsMenu:AddSlider({
            text = 'Tile Size',
            value = 90,
            min = 50,
            max = 500,
            callback = function(Value)
                library.main.TileSize = UDim2.new(0, Value, 0, Value)
            end
        })

        configSection:AddBox({
            text = 'Config Name',
            skipflag = true,
        })

        local function getAllConfigs()
            local files = {};

            for _, v in next, listfiles('Aztup Hub V3/configs') do
                if (not isfolder(v)) then continue; end;

                for _, v2 in next, listfiles(v) do
                    local configName = v2:match('(%w+).config.json');
                    if (not configName) then continue; end;

                    local folderName = v:match('configs\\(%w+)');
                    local fullConfigName = string.format('%s - %s', folderName, configName);

                    table.insert(files, fullConfigName);
                end;
            end;

            return files;
        end;

        local function updateAllConfigs()
            for _, v in next, library.options.loadFromList.values do
                library.options.loadFromList:RemoveValue(v);
            end;

            for _, configName in next, getAllConfigs() do
                library.options.loadFromList:AddValue(configName);
            end;
        end

        configSection:AddList({
            text = 'Configs',
            skipflag = true,
            value = '',
            flag = 'Config List',
            values = library:GetConfigs(),
        })

        configSection:AddButton({
            text = 'Create',
            callback = function()
                if (showBasePrompt('create')) then
                    library.options.configList:AddValue(library.flags.configName);
                    library.options.configList:SetValue(library.flags.configName);
                    library:SaveConfig(library.flags.configName);
                    library:LoadConfig(library.flags.configName);

                    updateAllConfigs();
                end;
            end
        })

        local btn;
        btn = configSection:AddButton({
            text = isGlobalConfigOn and 'Switch To Local Config' or 'Switch to Global Config';

            callback = function()
                isGlobalConfigOn = not isGlobalConfigOn;
                writefile(globalConfFilePath, tostring(isGlobalConfigOn));

                btn:SetText(isGlobalConfigOn and 'Switch To Local Config' or 'Switch to Global Config');
                library:ShowMessage('Note: Switching from Local to Global requires script relaunch.');
            end
        });

        configSection:AddButton({
            text = 'Save',
            callback = function()
                if (showBasePrompt('save')) then
                    library:SaveConfig(library.flags.configList);
                end;
            end
        }):AddButton({
            text = 'Load',
            callback = function()
                if (showBasePrompt('load')) then
                    library:UpdateConfig(); -- Save config before switching to new one
                    library:LoadConfig(library.flags.configList);
                end
            end
        }):AddButton({
            text = 'Delete',
            callback = function()
                if (showBasePrompt('delete')) then
                    local Config = library.flags.configList
                    local configFilePath = library.foldername .. '/' .. Config .. '.config' .. library.fileext;

                    if table.find(library:GetConfigs(), Config) and isfile(configFilePath) then
                        library.options.configList:RemoveValue(Config)
                        delfile(configFilePath);
                    end
                end;
            end
        })

        configSection:AddList({
            text = 'Load From',
            flag = 'Load From List',
            values = getAllConfigs()
        });

        configSection:AddButton({
            text = 'Load From',
            callback = function()
                if (not showBasePrompt('load from')) then return; end;
                if (isGlobalConfigOn) then return library:ShowMessage('You can not load a config from another user if you are in global config mode.'); end;

                local folderName, configName = library.flags.loadFromList:match('(%w+) %p (.+)');
                local fullConfigName = string.format('%s.config.json', configName);

                if (isfile(library.foldername .. '/' .. fullConfigName)) then
                    -- If there is already an existing config with this name then

                    if (not library:ShowConfirm('There is already a config with this name in your config folder. Would you like to delete it? Pressing no will cancel the operation')) then
                        return;
                    end;
                end;

                local configData = readfile(string.format('Aztup Hub V3/configs/%s/%s', folderName, fullConfigName));
                writefile(string.format('%s/%s', library.foldername, fullConfigName), configData);

                library:LoadConfig(configName);
            end
        })

        configSection:AddToggle({
            text = 'Automatically Save Config',
            state = true,
            flag = 'saveConfigAuto',
            callback = function(toggle)
                -- This is required incase the game crash but we can move the interval to 60 seconds

                if(not toggle) then
                    maid.saveConfigAuto = nil;
                    library:UpdateConfig(); -- Make sure that we update config to save that user turned off automatically save config
                    return;
                end;

                maid.saveConfigAuto = task.spawn(function()
                    while true do
                        task.wait(60);
                        library:UpdateConfig();
                    end;
                end);
            end,
        })

        local function saveConfigBeforeGameLeave()
            if (not library.flags.saveconfigauto) then return; end;
            library:UpdateConfig();
        end;

        library.unloadMaid:GiveTask(GuiService.NativeClose:Connect(saveConfigBeforeGameLeave));

        -- NativeClose does not fire on the Lua App
        library.unloadMaid:GiveTask(GuiService.MenuOpened:Connect(saveConfigBeforeGameLeave));

        library.unloadMaid:GiveTask(LocalPlayer.OnTeleport:Connect(function(state)
            if (state ~= Enum.TeleportState.Started and state ~= Enum.TeleportState.RequestedFromServer) then return end;
            saveConfigBeforeGameLeave();
        end));

        discordSection:AddButton({
            text = 'Join Discord',
            callback = function() return joinDiscord('gWCk7pTXNs') end
        });

        discordSection:AddButton({
            text = 'Copy Discord Invite',
            callback = function() return setclipboard('discord.gg/gWCk7pTXNs') end
        });
    end;
end;

warn(string.format('[Script] [Library] Loaded in %.02f seconds', tick() - libraryLoadAt));

library.OnFlagChanged:Connect(function(data)
    local keybindExists = library.options[string.lower(data.flag) .. 'Bind'];
    if (not keybindExists or not keybindExists.key or keybindExists.key == 'none') then return end;

    local toggled = library.flags[data.flag];

    if (toggled) then
        visualizer:AddText(data.text);
    else
        visualizer:RemoveText(data.text);
    end
end);

return library;