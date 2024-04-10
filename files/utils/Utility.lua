SX_VM_CNONE();

local Services = sharedRequire('./Services.lua');
local library = sharedRequire('../UILibrary.lua');
local Signal = sharedRequire('./Signal.lua');

local Players, UserInputService, HttpService, CollectionService = Services:Get('Players', 'UserInputService', 'HttpService', 'CollectionService');
local LocalPlayer = Players.LocalPlayer;

local Utility = {};

Utility.onPlayerAdded = Signal.new();
Utility.onCharacterAdded = Signal.new();
Utility.onLocalCharacterAdded = Signal.new();

local mathFloor = clonefunction(math.floor)
local isDescendantOf = clonefunction(game.IsDescendantOf);
local findChildIsA = clonefunction(game.FindFirstChildWhichIsA);
local findFirstChild = clonefunction(game.FindFirstChild);

local IsA = clonefunction(game.IsA);

local getMouseLocation = clonefunction(UserInputService.GetMouseLocation);
local getPlayers = clonefunction(Players.GetPlayers);

local worldToViewportPoint = clonefunction(Instance.new(getServerConstant('Camera')).WorldToViewportPoint);

function Utility:countTable(t)
    local found = 0;

    for i, v in next, t do
        found = found + 1;
    end;

    return found;
end;

function Utility:roundVector(vector)
    return Vector3.new(vector.X, 0, vector.Z);
end;

function Utility:getCharacter(player)
    local playerData = self:getPlayerData(player);
    if (not playerData.alive) then return end;

    local maxHealth, health = playerData.maxHealth, playerData.health;
    return playerData.character, maxHealth, (health / maxHealth) * 100, mathFloor(health), playerData.rootPart;
end;

function Utility:isTeamMate(player)
    local playerData, myPlayerData = self:getPlayerData(player), self:getPlayerData();
    local playerTeam, myTeam = playerData.team, myPlayerData.team;

    if(playerTeam == nil or myTeam == nil) then
        return false;
    end;

    return playerTeam == myTeam;
end;

function Utility:getRootPart(player)
    local playerData = self:getPlayerData(player);
    return playerData and playerData.rootPart;
end;

function Utility:renderOverload(data) end;

local function castPlayer(origin, direction, rayParams, playerToFind)
    local distanceTravalled = 0;

    while true do
        distanceTravalled = distanceTravalled + direction.Magnitude;

        local target = workspace:Raycast(origin, direction, rayParams);

        if(target) then
            if(isDescendantOf(target.Instance, playerToFind)) then
                return false;
            elseif(target and target.Instance.CanCollide) then
                return true;
            end;
        elseif(distanceTravalled > 2000) then
            return false;
        end;

        origin = origin + direction;
    end;
end;

function Utility:getClosestCharacter(rayParams)
    rayParams = rayParams or RaycastParams.new();
    rayParams.FilterDescendantsInstances = {}

    local myCharacter = Utility:getCharacter(LocalPlayer);
    local myHead = myCharacter and findFirstChild(myCharacter, 'Head');
    if(not myHead) then return end;

    if(rayParams.FilterType == Enum.RaycastFilterType.Blacklist) then
        table.insert(rayParams.FilterDescendantsInstances, myHead.Parent);
    end;

    local camera = workspace.CurrentCamera;
    if(not camera) then return end;

    local mousePos = library.flags.useFOV and getMouseLocation(UserInputService);
    local lastDistance, lastPlayer = math.huge, {};

    local maxFov = library.flags.useFOV and library.flags.aimbotFOV or math.huge;
    local whitelistedPlayers = library.options.aimbotWhitelistedPlayers.values;

    for _, player in next, getPlayers(Players) do
        if(player == LocalPlayer or table.find(whitelistedPlayers, player.Name)) then continue end;

        local character, health = Utility:getCharacter(player);

        if(not character or health <= 0 or findChildIsA(character, 'ForceField')) then continue; end;
        if(library.flags.checkTeam and Utility:isTeamMate(player)) then continue end;

        local head = character and findFirstChild(character, 'Head');
        if(not head) then continue end;

        local newDistance = (myHead.Position - head.Position).Magnitude;
        if(newDistance > lastDistance) then continue end;

        if (mousePos) then
            local screenPosition, visibleOnScreen = worldToViewportPoint(camera, head.Position);
            screenPosition = Vector2.new(screenPosition.X, screenPosition.Y);

            if((screenPosition - mousePos).Magnitude > maxFov or not visibleOnScreen) then continue end;
        end;

        local isBehindWall = library.flags.visibilityCheck and castPlayer(myHead.Position, (head.Position - myHead.Position).Unit * 100, rayParams, head.Parent);
        if (isBehindWall) then continue end;

        lastPlayer = {Player = player, Character = character, Health = health};
        lastDistance = newDistance;
    end;

    return lastPlayer, lastDistance;
end;

function Utility:getClosestCharacterWithEntityList(entityList, rayParams, options)
    rayParams = rayParams or RaycastParams.new();
    rayParams.FilterDescendantsInstances = {}

    options = options or {};
    options.maxDistance = options.maxDistance or math.huge;

    local myCharacter = Utility:getCharacter(LocalPlayer);
    local myHead = myCharacter and findFirstChild(myCharacter, 'Head');
    if(not myHead) then return end;

    if(rayParams.FilterType == Enum.RaycastFilterType.Blacklist) then
        table.insert(rayParams.FilterDescendantsInstances, myHead.Parent);
    end;

    local camera = workspace.CurrentCamera;
    if(not camera) then return end;

    local mousePos = library.flags.useFOV and getMouseLocation(UserInputService);
    local lastDistance, lastPlayer = math.huge, {};
    local whitelistedPlayers = library.options.aimbotWhitelistedPlayers.values;

    local maxFov = library.flags.useFOV and library.flags.aimbotFOV or math.huge;

    for _, player in next, entityList do
        if(player == myCharacter or table.find(whitelistedPlayers, player.Name)) then continue end;

        local humanoid = findChildIsA(player, 'Humanoid');
        if (not humanoid or humanoid.Health <= 0) then continue end;

        local character = player;

        if(not character or findChildIsA(character, 'ForceField')) then continue; end;

        local head = character and findFirstChild(character, 'Head');
        if(not head) then continue end;

        local newDistance = (myHead.Position - head.Position).Magnitude;
        if(newDistance > lastDistance or newDistance > options.maxDistance) then continue end;

        if (mousePos) then
            local screenPosition, visibleOnScreen = worldToViewportPoint(camera, head.Position);
            screenPosition = Vector2.new(screenPosition.X, screenPosition.Y);

            if((screenPosition - mousePos).Magnitude > maxFov or not visibleOnScreen) then continue end;
        end;

        local isBehindWall = library.flags.visibilityCheck and castPlayer(myHead.Position, (head.Position - myHead.Position).Unit * 100, rayParams, head.Parent);
        if (isBehindWall) then continue end;

        lastPlayer = {Player = player, Character = character, Health = humanoid.Health};
        lastDistance = newDistance;
    end;

    return lastPlayer, lastDistance;
end;

function panic()
    library:Unload();
end;

local playersData = {};

local function onCharacterAdded(player)
    local playerData = playersData[player];
    if (not playerData) then return end;

    local character = player.Character;
    if (not character) then return end;

    local localAlive = true;

    table.clear(playerData.parts);

    Utility.listenToChildAdded(character, function(obj)
        if (obj.Name == 'Humanoid') then
            playerData.humanoid = obj;
        elseif (obj.Name == 'HumanoidRootPart') then
            playerData.rootPart = obj;
        elseif (obj.Name == 'Head') then
            playerData.head = obj;
        end;
    end);

    if (player == LocalPlayer) then
        Utility.listenToDescendantAdded(character, function(obj)
            if (IsA(obj, 'BasePart')) then
                table.insert(playerData.parts, obj);

                local con;
                con = obj:GetPropertyChangedSignal('Parent'):Connect(function()
                    if (obj.Parent) then return end;
                    con:Disconnect();
                    table.remove(playerData.parts, table.find(playerData.parts, obj));
                end);
            end;
        end);
    end;

    local function onPrimaryPartChanged()
        playerData.primaryPart = character.PrimaryPart;
        playerData.alive = not not playerData.primaryPart;
    end

    local hum = character:WaitForChild('Humanoid', 30);
    playerData.humanoid = hum;
    if (not playerData.humanoid) then return warn('[Utility] [onCharacterAdded] Player is missing humanoid ' .. player:GetFullName()) end;
    if (not player.Parent or not character.Parent) then return end;

    character:GetPropertyChangedSignal('PrimaryPart'):Connect(onPrimaryPartChanged);

    if (character.PrimaryPart) then
        onPrimaryPartChanged();
    end;

    playerData.character = character;
    playerData.alive = true;
    playerData.health = playerData.humanoid.Health;
    playerData.maxHealth = playerData.humanoid.MaxHealth;

    hum.Destroying:Connect(function()
        playerData.alive = false;
        localAlive = false;
    end);

    hum.Died:Connect(function()
        playerData.alive = false;
        localAlive = false;
    end);

    playerData.humanoid:GetPropertyChangedSignal('Health'):Connect(function()
        playerData.health = hum.Health;
    end);

    playerData.humanoid:GetPropertyChangedSignal('MaxHealth'):Connect(function()
        playerData.maxHealth = hum.MaxHealth;
    end);

    local function fire()
        if (not localAlive) then return end;
        Utility.onCharacterAdded:Fire(playerData);

        if (player == LocalPlayer) then
            Utility.onLocalCharacterAdded:Fire(playerData);
        end;
    end;

    if (library.OnLoad) then
        library.OnLoad:Connect(fire);
    else
        fire();
    end;
end;

local function onPlayerAdded(player)
    local playerData = {};

    playerData.player = player;
    playerData.team = player.Team;
    playerData.parts = {};

    playersData[player] = playerData;

    local function fire()
        Utility.onPlayerAdded:Fire(player);
    end;

    task.spawn(onCharacterAdded, player);

    player.CharacterAdded:Connect(function()
        onCharacterAdded(player);
    end);

    player:GetPropertyChangedSignal('Team'):Connect(function()
        playerData.team = player.Team;
    end);

    if (library.OnLoad) then
        library.OnLoad:Connect(fire);
    else
        fire();
    end;
end;

function Utility:getPlayerData(player)
    return playersData[player or LocalPlayer] or {};
end;

function Utility.listenToChildAdded(folder, listener, options)
    options = options or {listenToDestroying = false};

    local createListener = typeof(listener) == 'table' and listener.new or listener;

    assert(typeof(folder) == 'Instance', 'listenToChildAdded folder #1 listener has to be an instance');
    assert(typeof(createListener) == 'function', 'listenToChildAdded #2 listener has to be a function');

    local function onChildAdded(child)
        local listenerObject = createListener(child);

        if (options.listenToDestroying) then
            child.Destroying:Connect(function()
                local removeListener = typeof(listener) == 'table' and (function() local a = (listener.Destroy or listener.Remove); a(listenerObject) end) or listenerObject;

                if (typeof(removeListener) ~= 'function') then
                    warn('[Utility] removeListener is not definded possible memory leak for', folder);
                else
                    removeListener(child);
                end;
            end);
        end;
    end

    debug.profilebegin(string.format('Utility.listenToChildAdded(%s)', folder:GetFullName()));

    for _, child in next, folder:GetChildren() do
        task.spawn(onChildAdded, child);
    end;

    debug.profileend();

    return folder.ChildAdded:Connect(createListener);
end;

function Utility.listenToChildRemoving(folder, listener)
    local createListener = typeof(listener) == 'table' and listener.new or listener;

    assert(typeof(folder) == 'Instance', 'listenToChildRemoving folder #1 listener has to be an instance');
    assert(typeof(createListener) == 'function', 'listenToChildRemoving #2 listener has to be a function');

    return folder.ChildRemoved:Connect(createListener);
end;

function Utility.listenToDescendantAdded(folder, listener, options)
    options = options or {listenToDestroying = false};

    local createListener = typeof(listener) == 'table' and listener.new or listener;

    assert(typeof(folder) == 'Instance', 'listenToDescendantAdded folder #1 listener has to be an instance');
    assert(typeof(createListener) == 'function', 'listenToDescendantAdded #2 listener has to be a function');

    local function onDescendantAdded(child)
        local listenerObject = createListener(child);

        if (options.listenToDestroying) then
            child.Destroying:Connect(function()
                local removeListener = typeof(listener) == 'table' and (listener.Destroy or listener.Remove) or listenerObject;

                if (typeof(removeListener) ~= 'function') then
                    warn('[Utility] removeListener is not definded possible memory leak for', folder);
                else
                    removeListener(child);
                end;
            end);
        end;
    end

    debug.profilebegin(string.format('Utility.listenToDescendantAdded(%s)', folder:GetFullName()));

    for _, child in next, folder:GetDescendants() do
        task.spawn(onDescendantAdded, child);
    end;

    debug.profileend();

    return folder.DescendantAdded:Connect(onDescendantAdded);
end;

function Utility.listenToDescendantRemoving(folder, listener)
    local createListener = typeof(listener) == 'table' and listener.new or listener;

    assert(typeof(folder) == 'Instance', 'listenToDescendantRemoving folder #1 listener has to be an instance');
    assert(typeof(createListener) == 'function', 'listenToDescendantRemoving #2 listener has to be a function');

    return folder.DescendantRemoving:Connect(createListener);
end;

function Utility.listenToTagAdded(tagName, listener)
    for _, v in next, CollectionService:GetTagged(tagName) do
        task.spawn(listener, v);
    end;

    return CollectionService:GetInstanceAddedSignal(tagName):Connect(listener);
end;

function Utility.getFunctionHash(f)
    if (typeof(f) ~= 'function') then return error('getFunctionHash(f) #1 has to be a function') end;

    local constants = getconstants(f);
    local protos = getprotos(f);

    local total = HttpService:JSONEncode({constants, protos});

    return syn.crypt.hash(total);
end;

local function onPlayerRemoving(player)
    playersData[player] = nil;
end;

for _, player in next, Players:GetPlayers() do
    task.spawn(onPlayerAdded, player);
end;

Players.PlayerAdded:Connect(onPlayerAdded);
Players.PlayerRemoving:Connect(onPlayerRemoving);

function Utility.find(t, c)
    for i, v in next, t do
        if (c(v, i)) then
            return v, i;
        end;
    end;

    return nil;
end;

function Utility.map(t, c)
    local ret = {};

    for i, v in next, t do
        local val = c(v, i);
        if (val) then
            table.insert(ret, val);
        end;
    end;

    return ret;
end;

return Utility;