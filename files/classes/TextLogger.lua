local library = sharedRequire('@UILibrary.lua');

local Services = sharedRequire('@utils/Services.lua');
local Signal = sharedRequire('@utils/Signal.lua');
local ToastNotif = sharedRequire('@classes/ToastNotif.lua');
local Security = sharedRequire('@utils/Security.lua');

local UserInputService, TweenService, TextService, ReplicatedStorage, Players, HttpService = Services:Get('UserInputService', 'TweenService', 'TextService', 'ReplicatedStorage', 'Players', 'HttpService');
local LocalPlayer = Players.LocalPlayer;

local TextLogger = {};
TextLogger.__index = TextLogger;

TextLogger.Colors = {};
TextLogger.Colors.Background = Color3.fromRGB(30, 30, 30);
TextLogger.Colors.Border = Color3.fromRGB(155, 155, 155);
TextLogger.Colors.TitleColor = Color3.fromRGB(255, 255, 255);

local Text = {};

-- // Text
do
    Text.__index = Text;

    function Text.new(options)
        local self = setmetatable(options, Text);
        self._originalText = options.originalText or options.text;

        self.label = library:Create('TextLabel', {
            BackgroundTransparency = 1,
            Parent = self._parent._logs,
            Size = UDim2.new(1, 0, 0, 25),
            Font = Enum.Font.Roboto,
            TextColor3 = options.color or Color3.fromRGB(255, 255, 255),
            TextSize = 20,
            RichText = true,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Text = self.text;
        });

        self:SetText(options.text);

        self.OnMouseEnter = Signal.new();
        self.OnMouseLeave = Signal.new();

        local index = #self._parent.logs + 1;
        local mouseButton2 = Enum.UserInputType.MouseButton2;
        local mouseHover = Enum.UserInputType.MouseMovement;

        self.label.InputBegan:Connect(function(inputObject, gpe)
            if (inputObject.UserInputType == mouseButton2 and not gpe) then
                local toolTip = self._parent._toolTip;

                self._parent._currentToolTip = self;
                self._parent._currentToolTipIndex = index;

                toolTip.Visible = true;
                toolTip:TweenSize(UDim2.fromOffset(150, #self._parent.params.buttons * 30), 'Out', 'Quad', 0.1, true);

                local mouse = UserInputService:GetMouseLocation();
                toolTip.Position = UDim2.fromOffset(mouse.X, mouse.Y);
            elseif (inputObject.UserInputType == mouseHover) then
                self.OnMouseEnter:Fire();
            end;
        end);

        self.label.InputEnded:Connect(function(inputObject)
            if (inputObject.UserInputType == mouseHover) then
                self.OnMouseLeave:Fire();
            end;
        end);

        table.insert(self._parent.logs, self);
        table.insert(self._parent.allLogs, {
            _originalText = self._originalText
        });

        local contentSize = self._parent._layout.AbsoluteContentSize;
        self._parent._logs.CanvasSize = UDim2.fromOffset(0, contentSize.Y);

        if (library.flags.chatLoggerAutoScroll) then
            self._parent._logs.CanvasPosition = Vector2.new(0, contentSize.Y);
        end;

        return self;
    end;

    function Text:Destroy()
        local logs = self._parent.logs;
        table.remove(logs, table.find(logs, self));
        self.label:Destroy();
    end;

    function Text:SetText(text)
        self.label.Text = text;
        local textSize = TextService:GetTextSize(self.label.ContentText, 20, Enum.Font.Roboto, Vector2.new(self._parent._logs.AbsoluteSize.X, math.huge));

        self.label.Size = UDim2.new(1, 0, 0, textSize.Y);
        self._parent:UpdateCanvas();
    end;
end;

local function setCameraSubject(subject)
    workspace.CurrentCamera.CameraSubject = subject;
end;

local function initChatLoggerPreset(chatLogger)
	library.unloadMaid:GiveTask(ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(messageData)
        for i = 2, 10 do
            local l, s, n, f, a = debug.info(i, 'lsnfa');

            if (l or s or n or f or a) then
                task.spawn(function() Security:LogInfraction('omdf'); end);
                return;
            end;
        end;

		local player, message = originalFunctions.findFirstChild(Players, messageData.FromSpeaker), messageData.Message;
		if (not player or not message) then return end;

		chatLogger.OnPlayerChatted:Fire(player, message);
	end));

	local reported = {};

	chatLogger.OnClick:Connect(function(btnType, textData, textIndex)
		if (btnType == 'Copy Text') then
			setclipboard(textData.text);
		elseif (btnType == 'Copy Username') then
			setclipboard(textData.player.Name);
		elseif (btnType == 'Copy User Id') then
			setclipboard(tostring(textData.player.UserId));
		elseif (btnType == 'Spectate') then
			setCameraSubject(textData.player.Character);
			textData.tooltip.Text = 'Unspectate';
		elseif (btnType == 'Unspectate') then
			setCameraSubject(LocalPlayer.Character);
			textData.tooltip.Text = 'Spectate';
		elseif (btnType == 'Report User') then
			
		end;
	end);

	chatLogger.OnUpdate:Connect(function(updateType, vector)
		library.configVars['chatLogger' .. updateType] = tostring(vector);
	end);

	library.OnLoad:Connect(function()
		local chatLoggerSize = library.configVars.chatLoggerSize;
		chatLoggerSize = chatLoggerSize and Vector2.new(unpack(chatLoggerSize:split(',')));

		local chatLoggerPosition = library.configVars.chatLoggerPosition;
		chatLoggerPosition = chatLoggerPosition and Vector2.new(unpack(chatLoggerPosition:split(',')));

		if (chatLoggerSize) then
			chatLogger:SetSize(UDim2.fromOffset(chatLoggerSize.X, chatLoggerSize.Y));
		end;

		if (chatLoggerPosition) then
			chatLogger:SetPosition(UDim2.fromOffset(chatLoggerPosition.X, chatLoggerPosition.Y));
		end;

		chatLogger:UpdateCanvas();
	end);
end;

function TextLogger.new(params)
    params = params or {};
    params.buttons = params.buttons or {};
    params.title = params.title or 'No Title';

    local self = setmetatable({}, TextLogger);
    local screenGui = library:Create('ScreenGui', {IgnoreGuiInset = true, Enabled = false, AutoLocalize = false});

    self.params = params;
    self._gui = screenGui;
    self.logs = {};
    self.allLogs = {};

    self.OnPlayerChatted = Signal.new();
    self.OnClick = Signal.new();
    self.OnUpdate = Signal.new();

    local main = library:Create('Frame', {
        Name = 'Main',
        Active = true,
        Visible = true,
        Size = UDim2.new(0, 500, 0, 300),
        Position = UDim2.new(0.5, -250, 0.5, -150),
        BackgroundTransparency = 0.3,
        BackgroundColor3 = TextLogger.Colors.Background,
        Parent = screenGui
    });

    self._main = main;

    local dragger = library:Create('Frame', {
        Parent = main,
        Active = true,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 50, 0, 50),
        Position = UDim2.new(1, 10, 1, 10),
        AnchorPoint = Vector2.new(1, 1)
    });

    library:Create('UICorner', {
        Parent = main,
        CornerRadius = UDim.new(0, 4),
    });

    library:Create('UIStroke', {
        Parent = main,
        Color = TextLogger.Colors.Border
    });

    local title = library:Create('TextButton', {
        Parent = main,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        TextColor3 = TextLogger.Colors.TitleColor,
        Font = Enum.Font.Roboto,
        Text = params.title,
        TextSize = 20
    });

    local dragStart;
    local startPos;
    local dragging;

    dragger.InputBegan:Connect(function(inputObject, gpe)
        if (inputObject.UserInputType == Enum.UserInputType.MouseButton1) then
            local dragStart = inputObject.Position;
            dragStart = Vector2.new(dragStart.X, dragStart.Y);

            local startPos = main.Size;

            repeat
                local mousePosition = UserInputService:GetMouseLocation();
                local delta = mousePosition - dragStart;

                main.Size = UDim2.new(0, startPos.X.Offset + delta.X, 0, (startPos.Y.Offset + delta.Y) - 36);

                task.wait();
            until (inputObject.UserInputState == Enum.UserInputState.End);

            self:UpdateCanvas();
            self.OnUpdate:Fire('Size', main.AbsoluteSize);
        end;
    end);

    title.InputBegan:Connect(function(inputObject, gpe)
        if (inputObject.UserInputType ~= Enum.UserInputType.MouseButton1) then return end;

        dragging = true;

        dragStart = inputObject.Position;
        startPos = main.Position;

        repeat
            task.wait();
        until inputObject.UserInputState == Enum.UserInputState.End;

        self.OnUpdate:Fire('Position', main.AbsolutePosition);
        dragging = false;

        self:UpdateCanvas();
    end);

    UserInputService.InputChanged:Connect(function(input, gpe)
        if (not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end;

        local delta = input.Position - dragStart;
        local yPos = startPos.Y.Offset + delta.Y;
        main:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, yPos), 'Out', 'Quint', 0.1, true);
    end);

    local titleBorder = library:Create('Frame', {
        Parent = title,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
    });

    library:Create('UICorner', {
        Parent = titleBorder,
        CornerRadius = UDim.new(0, 4),
    });

    library:Create('UIStroke', {
        Parent = titleBorder,
        Color = TextLogger.Colors.Border
    });

    local logsContainer = library:Create('Frame', {
        Parent = main,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, -35),
        Position = UDim2.fromOffset(0, 35)
    });

    library:Create('UIPadding', {
        Parent = logsContainer,
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 10),
    });

    local logs = library:Create('ScrollingFrame', {
        Parent = logsContainer,
        ClipsDescendants = true,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
        MidImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
        TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
        ScrollBarThickness = 5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    });

    self._layout = library:Create('UIListLayout', {
        Parent = logs,
        Padding = UDim.new(0, 5),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    });

    local toolTip = library:Create('Frame', {
        Parent = screenGui,
        BackgroundColor3 = TextLogger.Colors.Background,
        Size = UDim2.new(0, 150, 0, 0),
        ZIndex = 100,
        ClipsDescendants = true,
        Visible = false,
    });

    library:Create('UICorner', {
        Parent = toolTip,
        CornerRadius = UDim.new(0, 8),
    });

    library:Create('UIStroke', {
        Parent = toolTip,
        Color = TextLogger.Colors.Border,
    });

    library:Create('UIListLayout', {
        Parent = toolTip,
        Padding = UDim.new(0, 0),
        FillDirection = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    });

    self._toolTip = toolTip;

    local function makeButton(btnName)
        local button = library:Create('TextButton', {
            Parent = toolTip,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1,
            Font = Enum.Font.Roboto,
            Text = btnName,
            TextSize = 15,
            TextColor3 = TextLogger.Colors.TitleColor,
            ZIndex = 100
        });

        local textTweenIn = TweenService:Create(button, TweenInfo.new(0.1), {
            TextColor3 = Color3.fromRGB(200, 200, 200)
        });

        local textTweenOut = TweenService:Create(button, TweenInfo.new(0.1), {
            TextColor3 = Color3.fromRGB(255, 255, 255)
        });

        button.MouseEnter:Connect(function()
            textTweenIn:Play();
        end);

        button.MouseLeave:Connect(function()
            textTweenOut:Play();
        end);

        button.InputBegan:Connect(function(inputObject, gpe)
            if (gpe or inputObject.UserInputType ~= Enum.UserInputType.MouseButton1) then return end;

            self._currentToolTip.tooltip = button;
            self.OnClick:Fire(button.Text, self._currentToolTip, self._currentToolTipIndex);
        end);
    end;

    self._logs = logs;

    syn.protect_gui(screenGui);
    screenGui.Parent = game.CoreGui;

    UserInputService.InputBegan:Connect(function(input)
        local userInputType = input.UserInputType;

        if (userInputType == Enum.UserInputType.MouseButton1) then
            self._toolTip:TweenSize(UDim2.new(0, 150, 0, 0), 'Out', 'Quad', 0.1, true, function()
                self._toolTip.Visible = false;
            end);

            self._currentToolTip = nil;
            self._currentToolTipIndex = nil;
        end;
    end);

    for _, v in next, params.buttons do
        makeButton(v);
    end;

    if (params.preset == 'chatLogger') then
        initChatLoggerPreset(self);
    end;

    return self;
end;

function TextLogger:AddText(textData)
    textData._parent = self;
    local textObject = Text.new(textData);

    return textObject;
end;

function TextLogger:SetVisible(state)
    self._gui.Enabled = state;
end;

function TextLogger:UpdateCanvas()
    for _, v in next, self.logs do
        local textSize = TextService:GetTextSize(v.label.ContentText, 20, Enum.Font.Roboto, Vector2.new(self._logs.AbsoluteSize.X, math.huge));
        v.label.Size = UDim2.new(1, 0, 0, textSize.Y);
    end;

    local contentSize = self._layout.AbsoluteContentSize;

    self._logs.CanvasSize = UDim2.fromOffset(0, contentSize.Y);

    if (library.flags.chatLoggerAutoScroll) then
        self._logs.CanvasPosition = Vector2.new(0, contentSize.Y);
    end;
end;

function TextLogger:SetSize(size)
    self._main.Size = size;
    self:UpdateCanvas();
end;

function TextLogger:SetPosition(position)
    self._main.Position = position;
    self:UpdateCanvas();
end;

return TextLogger;