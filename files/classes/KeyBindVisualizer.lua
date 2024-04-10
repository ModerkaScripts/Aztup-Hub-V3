local Services = sharedRequire('@utils/Services.lua');
local UserInputService = Services:Get('UserInputService');
local Maid = sharedRequire('@utils/Maid.lua');

local keybindVisualizer = {};
keybindVisualizer.__index = keybindVisualizer;

local viewportSize = workspace.CurrentCamera.ViewportSize;
local library;

function keybindVisualizer.new()
    local self = setmetatable({}, keybindVisualizer);

    self._textSizes = {};
    self._maid = Maid.new();

    self:_init();

    local dragObject;
    local dragging;
    local dragStart;
    local startPos;

    self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 and self:MouseInFrame()) then
            dragObject = self._textBox
            dragging = true
            dragStart = input.Position
            startPos = dragObject.Position
        end;
    end));

    self._maid:GiveTask(UserInputService.InputChanged:connect(function(input)
        if dragging and input.UserInputType.Name == 'MouseMovement' and not self._destroyed then
            if dragging then
                local delta = input.Position - dragStart;
                local yPos = (startPos.Y + delta.Y) < -36 and -36 or startPos.Y + delta.Y;

                self._textBox.Position = Vector2.new(startPos.X + delta.X,  yPos);
                library.configVars.keybindVisualizerPos = tostring(self._textBox.Position);
            end;
        end;
    end));

    self._maid:GiveTask(UserInputService.InputEnded:connect(function(input)
        if input.UserInputType.Name == 'MouseButton1' then
            dragging = false
        end
    end));

    library.OnLoad:Connect(function()
        if (not library.configVars.keybindVisualizerPos) then return end;
        self._textBox.Position = Vector2.new(unpack(library.configVars.keybindVisualizerPos:split(',')));
    end);

    return self;
end;

function keybindVisualizer:_getTextBounds(text, fontSize)
    local t = Drawing.new('Text');
    t.Text = text;
    t.Size = fontSize;

    local res = t.TextBounds;
    t:Remove();
    return res.X;
end;

function keybindVisualizer:_createDrawingInstance(instanceType, properties)
    local instance = Drawing.new(instanceType);

    if (properties.Visible == nil) then
        properties.Visible = true;
    end;

    for i,  v in next,  properties do
        instance[i] = v;
    end;

    return instance;
end;

function keybindVisualizer:_init()
    self._textBox = self:_createDrawingInstance('Text', {
        Size = 30,
        Position = viewportSize-Vector2.new(180, viewportSize.Y/2),
        Color = Color3.new(255, 255, 255)
    });
end

function keybindVisualizer:GetLargest()
    table.sort(self._textSizes, function(a, b) return a.magnitude>b.magnitude; end)
    return self._textSizes[1] or Vector2.new(0, 30);
end

function keybindVisualizer:AddText(txt)
    if (self._destroyed) then return end;
    self._largest = self:GetLargest();

    local tab = string.split(self._textBox.Text, '\n');
    if (table.find(tab, txt)) then return end;

    local textSize = Vector2.new(self:_getTextBounds(txt, 30), 30);
    table.insert(self._textSizes, textSize);

    table.insert(tab, txt);
    table.sort(tab, function(a, b) return #a < #b; end)

    self._textBox.Text = table.concat(tab, '\n');
    self._textBox.Position -= Vector2.new(0, 30);
end

function keybindVisualizer:MouseInFrame()
	local mousePos = UserInputService:GetMouseLocation();
	local framePos = self._textBox.Position;
	local bottomRight = framePos + self._textBox.TextBounds

	return (mousePos.X >= framePos.X and mousePos.X <= bottomRight.X) and (mousePos.Y >= framePos.Y and mousePos.Y <= bottomRight.Y)
end;

function keybindVisualizer:RemoveText(txt)
    if (self._destroyed) then return end;
    local textSize = Vector2.new(self:_getTextBounds(txt, 30), 30);
	table.remove(self._textSizes, table.find(self._textSizes,  textSize));

    self._largest = self:GetLargest();

    local tab = string.split(self._textBox.Text, '\n');
    table.remove(tab, table.find(tab, txt));

    self._textBox.Text = table.concat(tab, '\n');
    self._textBox.Position += Vector2.new(0, 30);
end

function keybindVisualizer:UpdateColor(color)
    if (self._destroyed) then return end;
    self._textBox.Color = color;
end;

function keybindVisualizer:SetEnabled(state)
    if (self._destroyed) then return end;
    self._textBox.Visible = state;
end;

function keybindVisualizer:Remove()
    self._destroyed = true;
    self._maid:Destroy();
    self._textBox:Remove();
end;

function keybindVisualizer.init(newLibrary)
    library = newLibrary;
end;

return keybindVisualizer;