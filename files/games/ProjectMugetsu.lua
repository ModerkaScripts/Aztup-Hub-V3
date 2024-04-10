local library = sharedRequire('../UILibrary.lua');
local Services = sharedRequire('../utils/Services.lua');
local Maid = sharedRequire('../utils/Maid.lua');
local ToastNotif = sharedRequire('../classes/ToastNotif.lua');

local ReplicatedStorage, Players, MemStorageService, TeleportService, HttpService = Services:Get('ReplicatedStorage', 'Players', 'MemStorageService', 'TeleportService', 'HttpService');

local localPlayer = Players.LocalPlayer;
local column1 = unpack(library.columns);

local LOBBY_PLACE_ID = 9447079542;
local RANKED_PLACE_ID = 9952723123;
local GAME_PLACE_IDS = {10202329527, 9474703390, RANKED_PLACE_ID};

local funcs = {};

local maid = Maid.new();

local Remotes = ReplicatedStorage.Remotes;

local function getDataSize(obj)
    local clone = {};

    for _, v in next, obj:GetChildren() do
        local localObjClone = getDataSize(v);

        clone[v.Name] = localObjClone;
    end;

    pcall(function()
        clone[obj.Name] = obj.Value;
    end)
    return clone;
end;

local function isDatalossSet(myData)
    local length = 0;

    for _,v in next, myData:WaitForChild('Keys'):GetChildren() do
        length += string.len(v.Key.Value) * 2;
    end;

    return length >= 4000000;
end

if (table.find(GAME_PLACE_IDS, game.PlaceId)) then
    local ran = false;
    local serverRemote = Remotes.Server.Initiate_Server;

    local myDatas = ReplicatedStorage.Player_Datas:WaitForChild(localPlayer.Name, math.huge);
    local mySlotNumber = myDatas:WaitForChild('Current_Slot').Value;
    local myData = myDatas:WaitForChild(string.format('Slot_%d', mySlotNumber));

    function funcs.setUpDataloss(t)
        if (ran) then
            return ToastNotif.new({text = 'Already ran!'});
        end;

        ran = true;

        local changedCount = 0;

        -- Reset everything

        local keys = {
            ['AirWalk'] = 'T',
            ['Run'] = 'LeftShift',
            ['Move4'] = 'V',
            ['Meditate'] = 'K',
            ['Reiatsu'] = 'R',
            ['Reload'] = 'B',
            ['Move2'] = 'X',
            ['Dash'] = 'Q',
            ['Menu'] = 'M',
            ['ShiftLock'] = 'LeftControl',
            ['Move1'] = 'Z',
            ['Block'] = 'F',
            ['Evasive'] = 'G',
            ['Move3'] = 'C'
        }

        local myDataKeys = myData:WaitForChild('Keys', math.huge);
        local queueCount = 0;

        for _, v in next, myDataKeys:GetChildren() do
            originalFunctions.fireServer(serverRemote, 'UpdateKeys',v.Name,t and v.Name or keys[v.Name]);

            print(t and v.Name or keys[v.Name]);

            queueCount += 1;

            task.spawn(function()
                repeat
                    task.wait();
                until v.Key.Value == t and v.Name or keys[v.Name];

                queueCount -= 1;

                changedCount += 1;
            end);
        end;

        repeat
            print('waiting');
            task.wait();
        until queueCount <= 0;

        task.wait(1);

        if (not t) then
            ToastNotif.new({text = 'Dataloss unset success!'});
            return;
        end;

        changedCount = 0;
        local longStr = string.rep('\\', 199999);

        for _, v in next, myDataKeys:GetChildren() do
            local length = #HttpService:JSONEncode(getDataSize(getrenv()._G:GetData(localPlayer).Parent));
            local doBreak = false;
            print(length);

            local val = longStr;

            if (length >= 3700000) then
                local estimatedAmount = ((4194304-length)/2);
                estimatedAmount += 2950;

                val = string.rep('\\', estimatedAmount);
                doBreak = true;
            end;

            originalFunctions.fireServer(serverRemote, 'UpdateKeys', v.Name, val);

            repeat
                task.wait();
            until v.Key.Value == val;

            changedCount = changedCount + 1;

            if (doBreak) then
                break;
            end;
        end

        local length = #game.HttpService:JSONEncode(getDataSize(getrenv()._G:GetData(game.Players.LocalPlayer).Parent));
        print(length);

        ToastNotif.new({text = 'Dataloss setup success!'});
    end;

    function funcs.setUpDatalossNew(t)
        pcall(function()            
            local zone = myData.Which_Region.Value:gsub('\128', '');
            originalFunctions.fireServer(serverRemote, 'Change_Zone', t and zone .. string.char(128) or zone);

            ToastNotif.new({
                text = t and 'Dataloss set!' or 'Dataloss unset!'
            });
        end);
    end

    local dataLoss = column1:AddSection('Dataloss');
    dataLoss:AddButton({text = 'Undo old Dataloss', callback = function() funcs.setUpDataloss(false) end});

    dataLoss:AddButton({
        text = 'Set Dataloss',
        callback = function() funcs.setUpDatalossNew(true) end,
    });

    dataLoss:AddButton({
        text = 'Undo Dataloss',
        callback = function() funcs.setUpDatalossNew(false) end,
    });
    -- if (game.PlaceId == RANKED_PLACE_ID) then
    --     dataLoss:AddButton({text = 'Setup Dataloss', callback = function() funcs.setUpDataloss(true) end});

    --     if (MemStorageService:HasItem('setupDataloss')) then
    --         MemStorageService:RemoveItem('setupDataloss');
    --         funcs.setUpDataloss(true);

    --         TeleportService:Teleport(LOBBY_PLACE_ID);
    --     end;
    -- end;
else
    function funcs.setUpDataloss(t)
        if (t and not library:ShowConfirm('Please note none of your slot will load for 30 mins once you\'ll start clicking on the spin btn this will get fixed after 30mins')) then
            return;
        end;

        local myDatas = ReplicatedStorage.Player_Datas:WaitForChild(localPlayer.Name, math.huge);
        local myData = myDatas:WaitForChild(string.format('Slot_%d', myDatas:WaitForChild('Current_Slot').Value));

        if (isDatalossSet(myData) and not debugMode) then
            return ToastNotif.new({text = 'Dataloss already set.'});
        end;

        ToastNotif.new({text = 'Teleporting...'});
        MemStorageService:SetItem('setupDataloss', 'true');

        while true do
            TeleportService:Teleport(RANKED_PLACE_ID);
            task.wait(10)
        end;
    end;
end;


if (game.PlaceId == LOBBY_PLACE_ID) then
    local spinSection = column1:AddSection('Auto Spin');

    function funcs.rollBackData(t, bypass)
        if (ReplicatedStorage.SelectedSlot.Value == false and not bypass) then
            ToastNotif.new({text = 'Please load in a slot first!'});
            return false;
        end;

        local myDatas = ReplicatedStorage.Player_Datas:WaitForChild(localPlayer.Name, math.huge);
        local myData = myDatas:WaitForChild(string.format('Slot_%d', myDatas:WaitForChild('Current_Slot').Value));

        if (t and not isDatalossSet(myData)) then
            ToastNotif.new({text = 'You cannot use this feature without using setup dataloss.'});
            return false;
        end;

        --You can't rollback your data currently please join the main game and try!

        local customizationEvent = ReplicatedStorage.Remotes.Customization
        local n = t and 0/0 or 0.5;

        for _, v in next, myData.Customization:GetChildren() do
            originalFunctions.fireServer(customizationEvent, {["Number"] = n,["Type"] = v.Name,["Action"] = "Update"});
            originalFunctions.fireServer(customizationEvent, {["Hsv"] = Color3.new(n, n, n),["Type"] = "SetColor",["Action"] = "Update",["Act"] = v.Name});
            originalFunctions.fireServer(customizationEvent, {["Hsv"] = Color3.new(n, n, n),["Type"] = "SetColor2",["Action"] = "Update",["Act"] = v.Name});
        end;

        task.wait(1);

        if t then
            ToastNotif.new({text = string.format('Dataloss set.')});
        else
            ToastNotif.new({text = string.format('Dataloss unset.')});
        end;

        return true;
    end

    function funcs.doSpin(bypass)
        local myDatas = ReplicatedStorage.Player_Datas:WaitForChild(localPlayer.Name, math.huge);
        local myData = myDatas:WaitForChild(string.format('Slot_%d', myDatas:WaitForChild('Current_Slot').Value));

        if (not isDatalossSet(myData)) then
            return ToastNotif.new({text = 'Please setup dataloss first'});
        end;

        for clanDisplayName, value in next, library.flags.clans do
            local clanName = clanDisplayName:match('%w+ %p (%w+)');
            print(clanDisplayName, '=', clanName);

            if (clanName == myData.Clan.Value and value) then
                return ToastNotif.new({text = 'You already have this clan.'});
            end;
        end;

        if (not MemStorageService:HasItem('doSpinTotal')) then
            MemStorageService:SetItem('doSpinTotal', 0);
        end;

        ToastNotif.new({
            text = string.format(
                'Searching on slot %s, %s spins left, %s total clans rolled.',
                myDatas.Current_Slot.Value,
                myData.Spins.Value,
                MemStorageService:GetItem('doSpinTotal')
            )
        });

        local waitingToTp = false;

        local lastTpAt = 0;
        local rollCount = 0;

        maid.doSpin = task.spawn(function()
            --This yields
            if not funcs.rollBackData(true, bypass) then
                return;
            end;

            while true do
                task.defer(function()
                    if localPlayer.Gamepasses:FindFirstChild('57562532') then -- skip spins gamepass
                        originalFunctions.invokeServer(ReplicatedStorage.Spin, 1, true);
                    end
                end);

                local suc = originalFunctions.invokeServer(ReplicatedStorage.Spin, 1);
                print(suc);

                local newClanName = myData.Clan.Value;

                if (suc) then
                    rollCount += 1;

                    print('Got', newClanName);
                    ToastNotif.new({text = string.format('Just rolled %s', newClanName)});
                    MemStorageService:SetItem('doSpinTotal', MemStorageService:GetItem('doSpinTotal') + rollCount);

                    for clanDisplayName, value in next, library.flags.clans do
                        local clanName = clanDisplayName:match('%w+ %p (%w+)');

                        if (value and clanName == newClanName) then
                            MemStorageService:RemoveItem('doSpinSlot');
                            MemStorageService:RemoveItem('doSpinTotal');

                            funcs.rollBackData(false, bypass); --This prob should force them to join the main game to get rid of the rollback evidence
                            ToastNotif.new({text = 'You\'ve just got ' .. clanName .. ', please leave the game and re-connect.'});

                            return;
                        end;
                    end;

                    continue;
                end;

                if (not waitingToTp) then
                    waitingToTp = true;

                    MemStorageService:SetItem('doSpinSlot', myDatas:WaitForChild('Current_Slot').Value);
                    ToastNotif.new({text = string.format('Rolled %d clans total. Your data is still rolled back.', rollCount)});
                end;

                if (tick() - lastTpAt > 10 and library.flags.autoRejoin) then
                    lastTpAt = tick();
                    TeleportService:Teleport(LOBBY_PLACE_ID);
                    ToastNotif.new({text = 'Attempting to join a new server.'});
                end;
            end;
        end);
    end;

    if (MemStorageService:HasItem('doSpinSlot')) then
        library.OnLoad:Connect(function()
            if (not ReplicatedStorage.Player_Datas:FindFirstChild(localPlayer.Name)) then
                local gameLoadedAt = tick();
                ToastNotif.new({text = 'Waiting for game to load'});

                repeat
                    task.wait();
                until ReplicatedStorage.Player_Datas:FindFirstChild(localPlayer.Name) or tick() - gameLoadedAt > (debugMode and 30 or 60);

                if (not ReplicatedStorage.Player_Datas:FindFirstChild(localPlayer.Name)) then
                    ToastNotif.new({text = 'Attempting to join a new server.'});

                    while true do
                        TeleportService:Teleport(LOBBY_PLACE_ID);
                        task.wait(10);
                    end;

                    return;
                end;
            end;

            -- print('oui');

            -- local whichType = ReplicatedStorage:WaitForChild('Which_Type');

            -- repeat
            --     originalFunctions.invokeServer(ReplicatedStorage:WaitForChild('Change_Slot'), tonumber(MemStorageService:GetItem('doSpinSlot')));
            --     originalFunctions.fireServer(ReplicatedStorage:WaitForChild('Thang'), 'Character_Customization');
            --     task.wait(1);
            -- until whichType.Value == 'Character_Customization';

            -- funcs.doSpin(true);
        end);
    end;

    local clanList = require(game.ReplicatedStorage.Clans_);
    local allClans = {};

    for clanRarity, data in next, clanList do

        for _, clanName in next, data do
            table.insert(allClans, clanRarity .. ' - ' .. clanName);
        end;
    end;

    ToastNotif.new({
        text = 'Script is patched. If you want to undo dataloss join the main game and click undo dataloss'
    });

    -- spinSection:AddList({text = 'Clans', multiselect = true, values = allClans});
    -- spinSection:AddToggle({text = 'Auto Rejoin'});
    -- spinSection:AddButton({text = 'Spin', callback = funcs.doSpin});
    -- spinSection:AddButton({text = 'Undo dataloss', callback = function() funcs.rollBackData(false) end});
    -- spinSection:AddButton({text = 'Setup dataloss', callback = function() funcs.setUpDataloss(true) end});

    return;
end;