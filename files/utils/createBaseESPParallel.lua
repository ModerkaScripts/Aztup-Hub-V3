return [[
    local Players = game:GetService('Players');
    local RunService = game:GetService('RunService');
    local LocalPlayer = Players.LocalPlayer;

    local camera, rootPart, rootPartPosition;

    local originalCommEvent = ...;
    local commEvent;

    if (typeof(originalCommEvent) == 'table') then
        commEvent = {
            _event = originalCommEvent._event,

            Connect = function(self, f)
                return self._event.Event:Connect(f)
            end,

            Fire = function(self, ...)
                self._event:Fire(...);
            end
        };
    else
        commEvent = getgenv().syn.get_comm_channel(originalCommEvent);
    end;

    local flags = {};

    local updateTypes = {};

    local BaseESPParallel = {};
    BaseESPParallel.__index = BaseESPParallel;

    local container = {};
    local DEFAULT_ESP_COLOR = Color3.fromRGB(255, 255, 255);

    local mFloor = math.floor;
    local isSynapseV3 = not not gethui;

    local worldToViewportPoint = Instance.new('Camera').WorldToViewportPoint;
    local vector2New = Vector2.new;

    local realSetRP;
    local realDestroyRP;
    local realGetRPProperty;

    if (isSynapseV3) then
        realGetRPProperty = function(self, p, v)
            return self[p];
        end;

        realSetRP = function(self, p, v)
            self[p] = v;
        end;

        realDestroyRP = function(self)
            return self:Remove();
        end;

        realGetRPProperty = getRPProperty;
    else
        local lineUpvalues = getupvalue(Drawing.new, 4).__index;
        local lineUpvalues2 = getupvalue(Drawing.new, 4).__newindex;

        realSetRP = getupvalue(lineUpvalues2, 4);
        realDestroyRP = getupvalue(lineUpvalues, 3);
        realGetRPProperty = getupvalue(lineUpvalues, 4);

        assert(realSetRP);
        assert(realDestroyRP);
        assert(realGetRPProperty);
    end;


    local updateDrawingQueue = {};
    local destroyDrawingQueue = {};

    local activeContainer = {};
    local customInstanceCache = {};

    local gameName;
    local enableESPSearch = false;

    local sLower = string.lower;
    local sFind = string.find;

    local findFirstChild = clonefunction(game.FindFirstChild);
    local getAttribute = clonefunction(game.GetAttribute);

    if (isSynapseV3) then
        setRP = realSetRP;
        getRPProperty = realGetRPProperty;
    else
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
    end;


    function BaseESPParallel.new(data, showESPFlag, customInstance)
        local self = setmetatable(data, BaseESPParallel);

        if (customInstance) then
            if (not customInstanceCache[data._code]) then
                local func = loadstring(data._code);
                getfenv(func).library = setmetatable({}, {__index = function(self, p) return flags end});

                customInstanceCache[data._code] = func;
            end;
            self._instance = customInstanceCache[data._code](unpack(data._vars));
        end;

        local instance, tag, color, isLazy = self._instance, self._tag, self._color, self._isLazy;
        self._showFlag2 = showESPFlag;


		if (isSynapseV3 and typeof(instance) == 'Instance' and false) then
			-- if (typeof(instance) == 'table') then
			-- 	task.spawn(error, instance);
			-- end;

			self._label = TextDynamic.new(PointInstance.new(instance));
			self._label.Color = DEFAULT_ESP_COLOR;
			self._label.XAlignment = XAlignment.Center;
			self._label.YAlignment = YAlignment.Center;
			self._label.Outlined = true;
			self._label.Text = string.format('[%s]', tag);
		else
			self._label = Drawing.new('Text');
			self._label.Transparency = 1;
			self._label.Color = color;
			self._label.Text = '[' .. tag .. ']';
			self._label.Center = true;
			self._label.Outline = true;
		end;

		local flagValue = flags[self._showFlag];
		-- self._object = isSynapseV3 and self._label or self._label.__OBJECT;

		for i, v in next, self do
            if (typeof(v) == 'table' and rawget(v, '__OBJECT')) then
                rawset(v, '_cache', {});
            end;
        end;

		container[self._id] = self;

		if (isLazy) then
			self._instancePosition = instance.Position;
		end;

        self:UpdateContainer();
        return self;
    end;

	function BaseESPParallel:Destroy()
		container[self._id] = nil;
        if (table.find(activeContainer, self)) then
            table.remove(activeContainer, table.find(activeContainer, self));
        end;
        table.insert(destroyDrawingQueue, self._label);
    end;

    function BaseESPParallel:Unload()
        table.insert(updateDrawingQueue, {
            label = self._label,
            visible = false
        });
    end;

	function BaseESPParallel:BaseUpdate(espSearch)
		local instancePosition = self._instancePosition or self._instance.Position;
		if (not instancePosition) then return self:Unload() end;

		local distance = (rootPartPosition - instancePosition).Magnitude;
		local maxDist = flags[self._maxDistanceFlag] or 10000;
		if(distance >= maxDist and maxDist ~= 10000) then return self:Unload(); end;

		local visibleState = flags[self._showFlag];
		local label, text = self._label, self._text;

		if(visibleState == nil) then
			visibleState = true;
		elseif (not visibleState) then
			return self:Unload();
		end;

		-- if (isSynapseV3) then return end;

		local position, visible = worldToViewportPoint(camera, instancePosition);
		if(not visible) then return self:Unload(); end;

		local newPos = vector2New(position.X, position.Y);

		local labelText = '';

		if (flags[self._showHealthFlag]) then
            -- Custom instance do not touch they have custom funcs
            local humanoid = self._instance:FindFirstChildWhichIsA('Humanoid') or self._instance.Parent and self._instance.Parent:FindFirstChild('Humanoid');

            if (not humanoid) then
                if (gameName == 'Arcane Odyssey') then
                    local attributes = findFirstChild(self._instance.Parent, 'Attributes');
                    if (attributes) then
                        humanoid = {
                            Health = attributes.Health.Value,
                            MaxHealth = attributes.MaxHealth.Value,
                        }
                    end
                elseif (gameName == 'Voxl Blade') then
                    humanoid = {
                        Health = getAttribute(self._instance, 'HP'),
                        MaxHealth = getAttribute(self._instance, 'MAXHP'),
                    }
                end;
            end;

			if (humanoid) then
				local health = mFloor(humanoid.Health);
				local maxHealth = mFloor(humanoid.MaxHealth);

				labelText = labelText .. '[' .. health .. '/' .. maxHealth ..']';
			end;
		end;

		labelText = labelText .. '[' .. text .. ']';

        local visible = true;

        if (enableESPSearch and espSearch and not sFind(sLower(labelText), espSearch)) then
            visible = false;
        end;

		local newColor = flags[self._colorFlag] or flags[self._colorFlag2] or DEFAULT_ESP_COLOR;

		if (flags[self._showDistanceFlag]) then
			labelText = labelText .. ' [' .. mFloor(distance) .. ']';
		end;

        table.insert(updateDrawingQueue, {
            position = newPos,
            color = newColor,
            text = labelText,
            label = label,
            visible = visible
        });
	end;

    function BaseESPParallel:UpdateContainer()
        local showFlag, showFlag2 = self._showFlag, self._showFlag2;

        if (flags[showFlag] == false or not flags[showFlag2]) then
            local exists = table.find(activeContainer, self);
            if (exists) then table.remove(activeContainer, exists); end;
            self:Unload();
        elseif (not table.find(activeContainer, self)) then
            table.insert(activeContainer, self);
        end;
    end;

    function updateTypes.new(data)
        local showESPFlag = data.showFlag;
        local isCustomInstance = data.isCustomInstance;
        data = data.data;

        BaseESPParallel.new(data, showESPFlag, isCustomInstance);
    end;

    function updateTypes.destroy(data)
        task.desynchronize();
        local id = data.id;

        for _, v in next, container do
            if (v._id == id) then
                v:Destroy();
            end;
        end;
    end;

    local event;
    local flagChanged;

    local containerUpdated = false;

    function updateTypes.giveEvent(data)
        event = data.event;
        gameName = data.gameName;

        enableESPSearch = gameName == 'Voxl Blade' or gameName == 'DeepWoken' or gameName == 'Rogue Lineage';

        event.Event:Connect(function(data)
            if (data.type == 'color') then
                flags[data.flag] = data.color;
            elseif (data.type == 'slider') then
                flags[data.flag] = data.value;
            elseif (data.type == 'toggle') then
                flags[data.flag] = data.state;
            elseif (data.type == 'box') then
                flags[data.flag] = data.value;
            end;
    
            if (data.type ~= 'toggle' or containerUpdated) then return end;
            containerUpdated = true;
    
            task.defer(function()
                debug.profilebegin('containerUpdates');
                for _, v in next, container do
                    v:UpdateContainer();
                end;
                debug.profileend();
    
                containerUpdated = false;
            end);
        end);
    end;

    commEvent:Connect(function(data)
        local f = updateTypes[data.updateType];
        if (not f) then return end;
        f(data);
    end);

    commEvent:Fire({updateType = 'ready'});

    RunService.Heartbeat:Connect(function(deltaTime)
        task.desynchronize();

        camera = workspace.CurrentCamera;
        rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
        rootPartPosition = rootPart and rootPart.Position;

		if(not camera or not rootPart) then return; end;

        local espSearch = enableESPSearch and flags.espSearch;

        if (espSearch and espSearch ~= '') then
            espSearch = sLower(espSearch);
        end;

        for i = 1, #activeContainer do
            activeContainer[i]:BaseUpdate(espSearch);
        end;

        local goSerial = #updateDrawingQueue ~= 0 or #destroyDrawingQueue ~= 0;
        if (goSerial) then task.synchronize(); end;
        debug.profilebegin('updateDrawingQueue');

        for i = 1, #updateDrawingQueue do
            local v = updateDrawingQueue[i];
            local label, position, visible, color, text = v.label, v.position, v.visible, v.color, v.text;

            if (isSynapseV3) then
                if (position) then
                    label.Position = position;
                end;
    
                if (visible ~= nil) then
                    label.Visible = visible;
                end;
    
                if (color) then
                    label.Color = color;
                end;
    
                if (text) then
                    label.Text = text;
                end;
            else                
                if (position) then
                    setRP(label, 'Position', position);
                end;
    
                if (visible ~= nil) then
                    setRP(label, 'Visible', visible);
                end;
    
                if (color) then
                    setRP(label, 'Color', color);
                end;
    
                if (text) then
                    setRP(label, 'Text', text);
                end;
            end;
        end;

        debug.profileend();
        debug.profilebegin('destroyDrawingQueue');

        for i = 1, #destroyDrawingQueue do
            destroyDrawingQueue[i]:Remove();
        end;

        debug.profileend();
        debug.profilebegin('table clear');

        updateDrawingQueue = {};
        destroyDrawingQueue = {};

        debug.profileend();
    end);
]];