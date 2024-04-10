SX_VM_CNONE();

local library = sharedRequire('../UILibrary.lua');
local Utility = sharedRequire('../utils/Utility.lua');
local Services = sharedRequire('../utils/Services.lua');

local RunService, UserInputService, HttpService = Services:Get('RunService', 'UserInputService', 'HttpService');

local EntityESP = {};

local worldToViewportPoint = clonefunction(Instance.new('Camera').WorldToViewportPoint);
local vectorToWorldSpace = CFrame.new().VectorToWorldSpace;
local getMouseLocation = clonefunction(UserInputService.GetMouseLocation);

local id = HttpService:GenerateGUID(false);
local userId = accountData.uuid:sub(1, 4);

local lerp = Color3.new().lerp;
local flags = library.flags;

local vector3New = Vector3.new;
local Vector2New = Vector2.new;

local mathFloor = math.floor;

local mathRad = math.rad;
local mathCos = math.cos;
local mathSin = math.sin;
local mathAtan2 = math.atan2;

local showTeam;
local allyColor;
local enemyColor;
local maxEspDistance;
local toggleBoxes;
local toggleTracers;
local unlockTracers;
local showHealthBar;
local proximityArrows;
local maxProximityArrowDistance;

local scalarPointAX, scalarPointAY;
local scalarPointBX, scalarPointBY;

local labelOffset, tracerOffset;
local boxOffsetTopRight, boxOffsetBottomLeft;

local healthBarOffsetTopRight, healthBarOffsetBottomLeft;
local healthBarValueOffsetTopRight, healthBarValueOffsetBottomLeft;

local realGetRPProperty;

local setRP;
local getRPProperty;
local destroyRP;

local scalarSize = 20;

if (not isSynapseV3) then
	local lineUpvalues = getupvalue(Drawing.new, 4).__index;
	local lineUpvalues2 = getupvalue(Drawing.new, 4).__newindex;

	-- destroyRP, getRPProperty = getupvalue(lineUpvalues, 3), getupvalue(lineUpvalues, 4);
	local realSetRP = getupvalue(lineUpvalues2, 4);
    local realDestroyRP = getupvalue(lineUpvalues, 3);
    realGetRPProperty = getupvalue(lineUpvalues, 4);

    assert(realSetRP);
    assert(realDestroyRP);
    assert(realGetRPProperty);

    setRP = function(object, p, v)
		local cache = object._cache;
        local cacheVal = cache[p];
        if (cacheVal == v) then return end;

        cache[p] = v;
        realSetRP(object.__OBJECT, p, v);
    end;

    getRPProperty = function(object, p)
        local cacheVal = object._cache[p];
        if (not cacheVal) then
            object._cache[p] = realGetRPProperty(object.__OBJECT, p);
            cacheVal = object._cache[p];
        end;

        return cacheVal;
    end;

    destroyRP = function(object)
        return realDestroyRP(object.__OBJECT);
    end;
else
	getRPProperty = function(self, p, v)
		return self[p];
	end;

	setRP = function(self, p, v)
		self[p] = v;
	end;

	destroyRP = function(self)
		return self:Remove();
	end;

    realGetRPProperty = getRPProperty;
end;

local ESP_RED_COLOR, ESP_GREEN_COLOR = Color3.fromRGB(192, 57, 43), Color3.fromRGB(39, 174, 96)
local TRIANGLE_ANGLE = mathRad(45);

do --// Entity ESP
    EntityESP = {};
    EntityESP.__index = EntityESP;
    EntityESP.__ClassName = 'entityESP';

    EntityESP.id = 0;

    local emptyTable = {};

    function EntityESP.new(player)
        EntityESP.id += 1;

        local self = setmetatable({}, EntityESP);

        self._id = EntityESP.id;
        self._player = player;
        self._playerName = player.Name;

        self._triangle = Drawing.new('Triangle');
        self._triangle.Visible = true;
        self._triangle.Thickness = 0;
        self._triangle.Color = Color3.fromRGB(255, 255, 255);
        self._triangle.Filled = true;

        self._label = Drawing.new('Text');
        self._label.Visible = false;
        self._label.Center = true;
        self._label.Outline = true;
        self._label.Text = '';
        self._label.Font = Drawing.Fonts[library.flags.espFont];
        self._label.Size = library.flags.textSize;
        self._label.Color = Color3.fromRGB(255, 255, 255);

        self._box = Drawing.new('Quad');
        self._box.Visible = false;
        self._box.Thickness = 1;
        self._box.Filled = false;
        self._box.Color = Color3.fromRGB(255, 255, 255);

        self._healthBar = Drawing.new('Quad');
        self._healthBar.Visible = false;
        self._healthBar.Thickness = 1;
        self._healthBar.Filled = false;
        self._healthBar.Color = Color3.fromRGB(255, 255, 255);

        self._healthBarValue = Drawing.new('Quad');
        self._healthBarValue.Visible = false;
        self._healthBarValue.Thickness = 1;
        self._healthBarValue.Filled = true;
        self._healthBarValue.Color = Color3.fromRGB(0, 255, 0);

        self._line = Drawing.new('Line');
        self._line.Visible = false;
        self._line.Color = Color3.fromRGB(255, 255, 255);

        for i, v in next, self do
            if (typeof(v) == 'table' and rawget(v, '__OBJECT')) then
                rawset(v, '_cache', {});
            end;
        end;

        self._labelObject = isSynapseV3 and self._label or self._label.__OBJECT;

        return self;
    end;

    function EntityESP:Plugin()
        return emptyTable;
    end;

    function EntityESP:ConvertVector(...)
        -- if(flags.twoDimensionsESP) then
            -- return vector3New(...));
        -- else
            return vectorToWorldSpace(self._cameraCFrame, vector3New(...));
        -- end;
    end;

    function EntityESP:GetOffsetTrianglePosition(closestPoint, radiusOfDegree)
        local cosOfRadius, sinOfRadius = mathCos(radiusOfDegree), mathSin(radiusOfDegree);
        local closestPointX, closestPointY = closestPoint.X, closestPoint.Y;

        local sameBCCos = (closestPointX + scalarPointBX * cosOfRadius);
        local sameBCSin = (closestPointY + scalarPointBX * sinOfRadius);

        local sameACSin = (scalarPointAY * sinOfRadius);
        local sameACCos = (scalarPointAY * cosOfRadius)

        local pointX1 = (closestPointX + scalarPointAX * cosOfRadius) - sameACSin;
        local pointY1 = closestPointY + (scalarPointAX * sinOfRadius) + sameACCos;

        local pointX2 = sameBCCos - (scalarPointBY * sinOfRadius);
        local pointY2 = sameBCSin + (scalarPointBY * cosOfRadius);

        local pointX3 = sameBCCos - sameACSin;
        local pointY3 = sameBCSin + sameACCos;

        return Vector2New(mathFloor(pointX1), mathFloor(pointY1)), Vector2New(mathFloor(pointX2), mathFloor(pointY2)), Vector2New(mathFloor(pointX3), mathFloor(pointY3));
    end;

    function EntityESP:Update(t)
        local camera = self._camera;
        if(not camera) then return self:Hide() end;

        local character, maxHealth, floatHealth, health, rootPart = Utility:getCharacter(self._player);
        if(not character) then return self:Hide() end;

        rootPart = rootPart or Utility:getRootPart(self._player);
        if(not rootPart) then return self:Hide() end;

        local rootPartPosition = rootPart.Position;

        local labelPos, visibleOnScreen = worldToViewportPoint(camera, rootPartPosition + labelOffset);
        local triangle = self._triangle;

        local isTeamMate = Utility:isTeamMate(self._player);
        if(isTeamMate and not showTeam) then return self:Hide() end;

        local distance = (rootPartPosition - self._cameraPosition).Magnitude;
        if(distance > maxEspDistance) then return self:Hide() end;

        local espColor = isTeamMate and allyColor or enemyColor;
        local canView = false;

        if (proximityArrows and not visibleOnScreen and distance < maxProximityArrowDistance) then
            local vectorUnit;

            if (labelPos.Z < 0) then
                vectorUnit = -(Vector2.new(labelPos.X, labelPos.Y) - self._viewportSizeCenter).Unit; --PlayerPos-Center.Unit
            else
                vectorUnit = (Vector2.new(labelPos.X, labelPos.Y) - self._viewportSizeCenter).Unit; --PlayerPos-Center.Unit
            end;

            local degreeOfCorner = -mathAtan2(vectorUnit.X, vectorUnit.Y) - TRIANGLE_ANGLE;
            local closestPointToPlayer = self._viewportSizeCenter + vectorUnit * scalarSize --screenCenter+unit*scalar (Vector 2)

            local pointA, pointB, pointC = self:GetOffsetTrianglePosition(closestPointToPlayer, degreeOfCorner);

            setRP(triangle, 'PointA', pointA);
            setRP(triangle, 'PointB', pointB);
            setRP(triangle, 'PointC', pointC);

            setRP(triangle, 'Color', espColor);
            canView = true;
        end;

        setRP(triangle, 'Visible', canView);
        if (not visibleOnScreen) then return self:Hide(true) end;

        self._visible = visibleOnScreen;

        local label, box, line, healthBar, healthBarValue = self._label, self._box, self._line, self._healthBar, self._healthBarValue;
        local pluginData = self:Plugin();

        local text = '[' .. (pluginData.playerName or self._playerName) .. '] [' .. mathFloor(distance) .. ']\n[' .. mathFloor(health) .. '/' .. mathFloor(maxHealth) .. '] [' .. mathFloor(floatHealth) .. ' %]' .. (pluginData.text or '') .. ' [' .. userId .. ']';

        setRP(label, 'Visible', visibleOnScreen);
        setRP(label, 'Position', Vector2New(labelPos.X, labelPos.Y - realGetRPProperty(self._labelObject, 'TextBounds').Y));
        setRP(label, 'Text', text);
        setRP(label, 'Color', espColor);

        if(toggleBoxes) then
            local boxTopRight = worldToViewportPoint(camera, rootPartPosition + boxOffsetTopRight);
            local boxBottomLeft = worldToViewportPoint(camera, rootPartPosition + boxOffsetBottomLeft);

            local topRightX, topRightY = boxTopRight.X, boxTopRight.Y;
            local bottomLeftX, bottomLeftY = boxBottomLeft.X, boxBottomLeft.Y;

            setRP(box, 'Visible', visibleOnScreen);

            setRP(box, 'PointA', Vector2New(topRightX, topRightY));
            setRP(box, 'PointB', Vector2New(bottomLeftX, topRightY));
            setRP(box, 'PointC', Vector2New(bottomLeftX, bottomLeftY));
            setRP(box, 'PointD', Vector2New(topRightX, bottomLeftY));
            setRP(box, 'Color', espColor);
        else
            setRP(box, 'Visible', false);
        end;

        if(toggleTracers) then
            local linePosition = worldToViewportPoint(camera, rootPartPosition + tracerOffset);

            setRP(line, 'Visible', visibleOnScreen);

            setRP(line, 'From', unlockTracers and getMouseLocation(UserInputService) or self._viewportSize);
            setRP(line, 'To', Vector2New(linePosition.X, linePosition.Y));
            setRP(line, 'Color', espColor);
        else
            setRP(line, 'Visible', false);
        end;

        if(showHealthBar) then
            local healthBarValueHealth = (1 - (floatHealth / 100)) * 7.4;

            local healthBarTopRight = worldToViewportPoint(camera, rootPartPosition + healthBarOffsetTopRight);
            local healthBarBottomLeft = worldToViewportPoint(camera, rootPartPosition + healthBarOffsetBottomLeft);

            local healthBarTopRightX, healthBarTopRightY = healthBarTopRight.X, healthBarTopRight.Y;
            local healthBarBottomLeftX, healthBarBottomLeftY = healthBarBottomLeft.X, healthBarBottomLeft.Y;

            local healthBarValueTopRight = worldToViewportPoint(camera, rootPartPosition + healthBarValueOffsetTopRight - self:ConvertVector(0, healthBarValueHealth, 0));
            local healthBarValueBottomLeft = worldToViewportPoint(camera, rootPartPosition - healthBarValueOffsetBottomLeft);

            local healthBarValueTopRightX, healthBarValueTopRightY = healthBarValueTopRight.X, healthBarValueTopRight.Y;
            local healthBarValueBottomLeftX, healthBarValueBottomLeftY = healthBarValueBottomLeft.X, healthBarValueBottomLeft.Y;

            setRP(healthBar, 'Visible', visibleOnScreen);
            setRP(healthBar, 'Color', espColor);

            setRP(healthBar, 'PointA', Vector2New(healthBarTopRightX, healthBarTopRightY));
            setRP(healthBar, 'PointB', Vector2New(healthBarBottomLeftX, healthBarTopRightY));
            setRP(healthBar, 'PointC', Vector2New(healthBarBottomLeftX, healthBarBottomLeftY));
            setRP(healthBar, 'PointD', Vector2New(healthBarTopRightX, healthBarBottomLeftY));

            setRP(healthBarValue, 'Visible', visibleOnScreen);
            setRP(healthBarValue, 'Color', lerp(ESP_RED_COLOR, ESP_GREEN_COLOR, floatHealth / 100));

            setRP(healthBarValue, 'PointA', Vector2New(healthBarValueTopRightX, healthBarValueTopRightY));
            setRP(healthBarValue, 'PointB', Vector2New(healthBarValueBottomLeftX, healthBarValueTopRightY));
            setRP(healthBarValue, 'PointC', Vector2New(healthBarValueBottomLeftX, healthBarValueBottomLeftY));
            setRP(healthBarValue, 'PointD', Vector2New(healthBarValueTopRightX, healthBarValueBottomLeftY));
        else
            setRP(healthBar, 'Visible', false);
            setRP(healthBarValue, 'Visible', false);
        end;
    end;

    function EntityESP:Destroy()
        if (not self._label) then return end;

        destroyRP(self._label);
        self._label = nil;

        destroyRP(self._box);
        self._box = nil;

        destroyRP(self._line);
        self._line = nil;

        destroyRP(self._healthBar);
        self._healthBar = nil;

        destroyRP(self._healthBarValue);
        self._healthBarValue = nil;

        destroyRP(self._triangle);
        self._triangle = nil;
    end;

    function EntityESP:Hide(bypassTriangle)
        if (not bypassTriangle) then
            setRP(self._triangle, 'Visible', false);
        end;

        if (not self._visible) then return end;
        self._visible = false;

        setRP(self._label, 'Visible', false);
        setRP(self._box, 'Visible', false);
        setRP(self._line, 'Visible', false);

        setRP(self._healthBar, 'Visible', false);
        setRP(self._healthBarValue, 'Visible', false);
    end;

    function EntityESP:SetFont(font)
        setRP(self._label, 'Font', font);
    end;

    function EntityESP:SetTextSize(textSize)
        setRP(self._label, 'Size', textSize);
    end;

    local function updateESP()
        local camera = workspace.CurrentCamera;
        EntityESP._camera = camera;
        if (not camera) then return end;

        EntityESP._cameraCFrame = EntityESP._camera.CFrame;
        EntityESP._cameraPosition = EntityESP._cameraCFrame.Position;

        local viewportSize = camera.ViewportSize;

        EntityESP._viewportSize = Vector2New(viewportSize.X / 2, viewportSize.Y - 10);
        EntityESP._viewportSizeCenter = viewportSize / 2;

        showTeam = flags.showTeam;
        allyColor = flags.allyColor;
        enemyColor = flags.enemyColor;
        maxEspDistance = flags.maxEspDistance;
        toggleBoxes = flags.toggleBoxes;
        toggleTracers = flags.toggleTracers;
        unlockTracers = flags.unlockTracers;
        showHealthBar = flags.showHealthBar;
        maxProximityArrowDistance = flags.maxProximityArrowDistance;
        proximityArrows = flags.proximityArrows;

        scalarSize = library.flags.proximityArrowsSize or 20;

        scalarPointAX, scalarPointAY = scalarSize, scalarSize;
        scalarPointBX, scalarPointBY = -scalarSize, -scalarSize;

        labelOffset = EntityESP:ConvertVector(0, 3.25, 0);
        tracerOffset = EntityESP:ConvertVector(0, -4.5, 0);

        boxOffsetTopRight = EntityESP:ConvertVector(2.5, 3, 0);
        boxOffsetBottomLeft = EntityESP:ConvertVector(-2.5, -4.5, 0);

        healthBarOffsetTopRight = EntityESP:ConvertVector(-3, 3, 0);
        healthBarOffsetBottomLeft = EntityESP:ConvertVector(-3.5, -4.5, 0);

        healthBarValueOffsetTopRight = EntityESP:ConvertVector(-3.05, 2.95, 0);
        healthBarValueOffsetBottomLeft = EntityESP:ConvertVector(3.45, 4.45, 0);
    end;

    updateESP();
    RunService:BindToRenderStep(id, Enum.RenderPriority.Camera.Value, updateESP);
end;

return EntityESP;