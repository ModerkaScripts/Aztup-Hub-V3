local library = sharedRequire('../../UILibrary.lua');
local Services = sharedRequire('../../utils/Services.lua');

local column1, column2 = unpack(library.columns);
local RunService = Services:Get('RunService');

local EVENT_STRINGS = {};
local SCORE_CONVERTER;

local Helding = {};
local grabVars;
local tracks;
local tracksSystem;
local generateNote;
local collectNpcsRewards;

do -- Scan
    local hooked = {};

    local LocalMain;
    local songDatabase;
    local curveUtil;
    local vipModule;

    local Applying = {};

    for i, v in next, getgc(true) do
        if(typeof(v) == 'table' and typeof(rawget(v, '_game_join')) == 'table') then
            LocalMain = v;
        elseif(typeof(v) == 'table' and rawget(v, 'DeltaTimeToTimescale')) then
            curveUtil = v;
        elseif(typeof(v) == 'table' and rawget(v, 'new') and islclosure(v.new)) then
            for i2, v2 in next, getconstants(v.new) do
                if (v2 == 'on_songkey_pressed') then
                    table.insert(Applying, v)
                end
            end
        elseif(typeof(v) == 'table' and rawget(v, 'key_has_combineinfo')) then
            songDatabase = v;
        elseif(typeof(v) == 'table' and rawget(v, 'playerblob_has_vip_for_current_day')) then
            vipModule = v;
        end;
    end;

    local oldDeltaTimeToTimescale = curveUtil.DeltaTimeToTimescale;
    local currentTime = 0;

    function curveUtil:DeltaTimeToTimescale(n)
        currentTime = n;
        return oldDeltaTimeToTimescale(self, n);
    end;

    function grabVars()
        local gamelocal = getupvalue(LocalMain._game_join.is_game_finished, 1);
        if(not gamelocal) then
            return;
        end;

        if(not hooked[gamelocal]) then
            local blKeys = {0, 1, 2, 3};

            hooked[gamelocal] = true;
            local oldGameLocalUpdate = gamelocal.update;
            function gamelocal:update(n)
                if(library.flags.songSpeed) then
                    n = currentTime / (1/60) * library.flags.songSpeedValue;
                end;

                return oldGameLocalUpdate(self, n);
            end;

            local old_control_just_pressed = gamelocal._input.control_just_pressed;
            function gamelocal._input:control_just_pressed(keyCode)
                if(library.flags.toggleAutoPlayer and table.find(blKeys, keyCode)) then
                    return;
                end;

                return old_control_just_pressed(self, keyCode);
            end;

            local old_control_just_released = gamelocal._input.control_just_released;
            function gamelocal._input:control_just_released(keyCode)
                if(library.flags.toggleAutoPlayer and table.find(blKeys, keyCode)) then
                    return;
                end;

                return old_control_just_released(self, keyCode);
            end;
        end;

        local game_slot = getupvalue(gamelocal.set_local_game_slot, 1);
        tracksSystem = getupvalue(gamelocal.setup_world, 2):get(game_slot);

        local tracksystems = getupvalue(gamelocal.post_update, 2);
        setupvalue(gamelocal.post_update, 1, tracksystems);

        if(not tracksSystem) then
            return;
        end;

        for i, v in next, tracksSystem do
            if(typeof(v) == "function" and i:sub(1, 1) == "_") then
                local constants = getconstants(v);
                local isPress = table.find(constants, "press");
                local isRelease = table.find(constants, "release");

                if(isPress) then
                    EVENT_STRINGS.PRESS_TRACK = i;
                elseif(isRelease) then
                    EVENT_STRINGS.RELEASE_TRACK = i;
                end;
            end;
        end;

        if(tracksSystem[EVENT_STRINGS.PRESS_TRACK]) then
            tracks = getupvalue(tracksSystem[EVENT_STRINGS.PRESS_TRACK], 4); -- // notes lol
        end;

        local function tableFind(t, v)
            for i, v2 in next, t do
                if(v2 == v) then
                    return v2;
                end;
            end;
        end;

        for i,v in next, tracks._table do
            if(not EVENT_STRINGS.CAN_PRESS_NOTE or not EVENT_STRINGS.CAN_RELEASE_NOTE) then
                for i2, v2 in next, v do
                    if(typeof(v2) == "function") then
                        local constants = getconstants(v2);
                        if(tableFind(constants, "get_delta_time_from_hit_time")) then
                            EVENT_STRINGS.CAN_PRESS_NOTE = i2;
                            EVENT_STRINGS.SCORE_FUNCTION = constants[2] == 'Pre' and constants[4] or constants[2];

                            _G.CAN_PRESS_NOTE = constants;

                            local SpUtil;
                            local upvalues = getupvalues(v2);

                            for i, v in next, upvalues do
                                if(typeof(v) == "table" and rawget(v, "color3")) then
                                    SpUtil = v;
                                    break;
                                end;
                            end;

                            local SCORE_FUNCTION = SpUtil[getconstant(SpUtil[EVENT_STRINGS.SCORE_FUNCTION], 1)];

                            local ScoreResult = getupvalue(SCORE_FUNCTION, 1);

                            local Meaning = {-1, 3, 2, 1};
                            -- -1 Miss
                            -- 3 Okay
                            -- 2 Great
                            -- 1 Perfect

                            for i, v in next, getconstants(SCORE_FUNCTION) do
                                Meaning[v] = Meaning[i];
                                Meaning[i] = nil;
                            end;

                            for i, v in next, ScoreResult do
                                Meaning[v] = Meaning[i];
                                Meaning[i] = nil;
                            end;

                            if (isUserTrolled) then
                                Meaning = {};
                            end;

                            SCORE_CONVERTER = Meaning;
                        elseif(tableFind(constants, "get_delta_time_from_release_time")) then
                            EVENT_STRINGS.CAN_RELEASE_NOTE = i2;
                        end;
                    end;
                end;
            end;
        end;
    end;

    local random = Random.new();

    function generateNote()
        if(library.flags.random) then
            return random:NextInteger(1, 3);
        end;

        local perfect = library.flags.perfect;
        local great = library.flags.great;
        local okay = library.flags.okay;
        local miss = library.flags.miss;

        local randomTable = {};

        for i = 1, perfect do
            table.insert(randomTable, 1);
        end;

        for i = 1, great do
            table.insert(randomTable, 2);
        end;

        for i = 1, okay do
            table.insert(randomTable, 3);
        end;

        for i = 1, miss do
            table.insert(randomTable, -1);
        end;

        if(#randomTable == 0) then return 0 end;
        return randomTable[random:NextInteger(1, #randomTable)] or 3;
    end;

    function collectNpcsRewards(toggle)
        if(not toggle or isUserTrolled) then
            return;
        end;

        repeat
            task.wait(15);

            LocalMain._player_blob_manager:do_sync();
            local EVENT_ENUMS = getupvalue(LocalMain._evt.server_generate_encodings, 1);

            LocalMain._evt:wait_on_event_once(EVENT_ENUMS.EVT_WebNPC_ServerInfoResponse, function(t)
                local WebNpcInfo = t.WebNPCInfo;
                for i, v in next, WebNpcInfo do
                    if(v.Tier == 1 or table.find(t.VisitedList, tostring(v.WebNPCID))) then continue end;
                    LocalMain._shop_local_protocol:visit_webnpc(v.WebNPCID, function() end);
                end;
            end);
            LocalMain._evt:fire_event_to_server(EVENT_ENUMS.EVT_WebNPC_ClientRequestInfo);
        until not library.flags.collectNpcsRewards;
    end;

    do -- // Unlock All Songs
        -- local StoredSongs = {};

        -- local function Apply(as,db)
        --     local MNM = db:name_to_key('MondayNightMonsters1')

        --     local old_new = as.new

        --     as.new = function(...)
        --         local as_self = old_new(...)
        --         local old_skp = as_self.on_songkey_pressed;
        --         as_self.on_songkey_pressed = function(self, song)

        --             local actual = tonumber(song);

        --             if library.flags.unlockAllSongs then
        --                 song = MNM
        --             end

        --             print(actual, db:get_title_for_key(actual));

        --             local title = db:get_title_for_key(actual)
        --             local data = StoredSongs[title]

        --             if not data then
        --                 for i,v in next, getloadedmodules() do
        --                     local req = require(v)
        --                     if (type(req) == 'table' and rawget(req, 'HitObjects')) then
        --                         StoredSongs[rawget(req, 'AudioFilename')] = req
        --                         if (rawget(req, 'AudioFilename') == title) then
        --                             data = req;
        --                         end
        --                     end
        --                 end
        --             end

        --             local all = getupvalue(db.add_key_to_data, 1);

        --             all:add(song, data);
        --             table.foreach(data, warn);
        --             data.__key = song;

        --             setupvalue(db.add_key_to_data, 1, all)

        --             return old_skp(self, song)
        --         end

        --         return as_self
        --     end
        -- end

        -- for _,AllSongs in next, Applying do
        --     Apply(AllSongs, songDatabase)
        -- end

        local oldGetVip = vipModule.playerblob_has_vip_for_current_day;
        vipModule.playerblob_has_vip_for_current_day = function(...)
            if(library.flags.unlockAllSongs) then return true end;

            return oldGetVip(...);
        end
    end

    coroutine.wrap(function()
        while true do
            RunService.Heartbeat:Wait();
            grabVars();

            if(not library.flags.toggleAutoPlayer) then continue end;
            if(not EVENT_STRINGS.CAN_PRESS_NOTE or not SCORE_CONVERTER) then
                warn('[RoBeats] [AutoPlayer]', EVENT_STRINGS.CAN_PRESS_NOTE, SCORE_CONVERTER);
                continue;
            end;

            debug.profilebegin('Auto Player');
            local t = tracks._table;
            local chosedNote = generateNote();

            for i = 1, #t do
                local v = t[i];

                local CanHit, NoteScore = v[EVENT_STRINGS.CAN_PRESS_NOTE]();
                local isHeld = v.get_delta_time_from_release_time;
                local index = v:get_track_index();

                NoteScore = SCORE_CONVERTER[NoteScore];

                if(CanHit and NoteScore == chosedNote and not Helding[v] and EVENT_STRINGS.PRESS_TRACK) then
                    print('press');
                    chosedNote = generateNote();
                    tracksSystem[EVENT_STRINGS.PRESS_TRACK](nil, nil, index);
                    if(isHeld) then
                        Helding[v] = true;
                    elseif(EVENT_STRINGS.RELEASE_TRACK) then
                        print('release');
                        -- delay(0.06, function()
                            tracksSystem[EVENT_STRINGS.RELEASE_TRACK](nil, nil, index);
                        -- end);
                    end;
                elseif(Helding[v] and EVENT_STRINGS.CAN_RELEASE_NOTE) then
                    local index = v:get_track_index();
                    local CanHit, NoteScore = v[EVENT_STRINGS.CAN_RELEASE_NOTE]();
                    NoteScore = SCORE_CONVERTER[NoteScore];
                    if(CanHit and NoteScore == chosedNote and EVENT_STRINGS.RELEASE_TRACK) then
                        -- delay(0.05, function()
                            tracksSystem[EVENT_STRINGS.RELEASE_TRACK](nil, nil, index);
                        -- end);

                        Helding[v] = nil;
                    end;
                end;
            end;
            debug.profileend();
        end;
    end)();
end;

local AutoPlayer = column1:AddSection("Auto Player");
local Misc = column2:AddSection("Misc");

AutoPlayer:AddToggle({text = 'Enable', flag = 'Toggle Auto Player'});
AutoPlayer:AddToggle({text = 'Random'});
AutoPlayer:AddSlider({text = 'Perfect', value = 65, min = 0, max = 100});
AutoPlayer:AddSlider({text = 'Great', value = 35, min = 0, max = 100});
AutoPlayer:AddSlider({text = 'Okay', min = 0, max = 100});
AutoPlayer:AddSlider({text = 'Miss', min = 0, max = 100});

Misc:AddToggle({text = 'Song Speed'}):AddSlider({flag = 'Song Speed Value', min = 0, max = 10, float = 0.1})
Misc:AddToggle({text = 'Collect Npcs Rewards', callback = collectNpcsRewards});
-- Misc:AddToggle({text = 'Unlock All Songs (Freeze Score)', flag = 'Unlock All Songs'});