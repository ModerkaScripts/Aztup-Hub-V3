local library = sharedRequire('../UILibrary.lua');
local Services = sharedRequire('../utils/Services.lua');
local Maid = sharedRequire('../utils/Maid.lua');
local ToastNotif = sharedRequire('../classes/ToastNotif.lua');

local ReplicatedStorage, Players, MemStorageService, TeleportService = Services:Get('ReplicatedStorage', 'Players', 'MemStorageService', 'TeleportService');

local localPlayer = Players.LocalPlayer;
local column1 = unpack(library.columns);

local acServer = require(ReplicatedStorage.Modules.Server.Skills_Modules_Handler);

hookfunction(acServer.Kick, function(...)
    print('Ban Attempt', ...);
end);

local LOBBY_PLACE_ID = 5956785391;
local GAME_PLACE_ID = 6152116144;
local GAME_PLACE_ID2 = 11468159863;
local functions = {};

local maid = Maid.new();

local Remotes = ReplicatedStorage.Remotes;

local serverRemoteFunction = Remotes.To_Server.Handle_Initiate_S_;
local serverRemote = Remotes.To_Server.Handle_Initiate_S;

local changeValue = require(ReplicatedStorage.Modules.Server.Server_Modules.Change_Value);

if (game.PlaceId == GAME_PLACE_ID or game.PlaceId == GAME_PLACE_ID2) then
    local ran = false;
    function functions.setUpDataloss()
        if (ran) then return end;
        ran = true;

        local myData = ReplicatedStorage.Player_Data:WaitForChild(localPlayer.Name, math.huge);
        local yen = myData.Yen.Value;
        local mapUI = myData.MapUi;
        local mapLocations = mapUI.UnlockedLocations;

        if #mapLocations:GetChildren() >= 21 then return ToastNotif.new({text = 'You can already use dataloss go join the lobby game!'}); end
        if yen <= 25200 then return ToastNotif.new({text = 'You do not have enough yen for this feature you need atleast 25200'}); end --You don't have enough yen for this feature

        --Disable notifications
        getrenv()._G.Notify = function() return; end

        for _, v in next, getconnections(ReplicatedStorage.Remotes.To_Client.Handle_Initiate_C.OnClientEvent) do
            v:Disable();
        end;

        for _ = 1, 21 do --Buying map points
            serverRemote:FireServer('buy_tang_map_points', localPlayer);
        end

        repeat task.wait() until mapUI.Map_Points.Value >= 21; --Wait for us to have more than 21 map points

        for i = 1, 21 do --Spending Map Points
            serverRemote:FireServer('change_eq_tang103', localPlayer, 'Dungeon'..i);
        end

        repeat task.wait(0.1); until #mapLocations:GetChildren() >= 21;

        while true do
            game.TeleportService:Teleport(5956785391);
            task.wait(1);
        end;
    end;

    local dataLoss = column1:AddSection('Dataloss');
    dataLoss:AddButton({text = 'Setup Dataloss', callback = functions.setUpDataloss});
end


if (game.PlaceId == LOBBY_PLACE_ID) then
    local spinSection = column1:AddSection('Auto Spin');

    local longStr = string.rep(' ',199999);
    function functions.rollBackData(t)
        local myData = ReplicatedStorage.Player_Data:WaitForChild(localPlayer.Name, math.huge);
        local unlockedLocations = myData:FindFirstChild("UnlockedLocations",true);

        if #unlockedLocations:GetChildren() < 21 then ToastNotif.new({text = "You cannot use this feature without using setup dataloss in the main game!"}); return false; end --You can't rollback your data currently please join the main game and try!

        local changedCount = 0;
        for _,v in next, unlockedLocations:GetChildren() do
            task.spawn(function()
                serverRemote:FireServer("Change_Value",v,t and longStr or v.Name);

                if t then
                    repeat task.wait() until t and v.Value == longStr or not t and v.Value == v.Name;
                end
                changedCount=changedCount+1;
            end)
        end

        repeat
            task.wait(0.5)
            warn(changedCount)
        until changedCount >= 21

        if t then
            ToastNotif.new({text = string.format('Dataloss set.')});
        else
            ToastNotif.new({text = string.format('Dataloss unset.')});
        end

        return true;
    end

    function functions.doSpin()
        local myData = ReplicatedStorage.Player_Data:FindFirstChild(localPlayer.Name, math.huge);
        if (not myData) then
            return ToastNotif.new({text = 'Please select a slot first.'});
        end;

        local valueObject = myData.MapUi.UnlockedLocations:FindFirstChildWhichIsA('StringValue');
        if (not valueObject) then
            return localPlayer:Kick('dm aztup');
        end;

        local oldValue = valueObject.Value;

        changeValue(valueObject, 'test');

        if (valueObject.Value ~= 'test') then
            return ToastNotif.new({text = 'Looks like script is patched sorry :('});
        end;

        valueObject.Value = oldValue;

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
                localPlayer.Slot.Value,
                myData.Spins.Value,
                MemStorageService:GetItem('doSpinTotal')
            )
        });

        local waitingToTp = false;

        local lastTpAt = 0;
        local rollCount = 0;

        maid.doSpin = task.spawn(function()
            if not functions.rollBackData(true) then
                return;
            end --This yields

            while true do
                local suc, newClanName = serverRemoteFunction:InvokeServer('check_can_spin');

                if (suc) then
                    rollCount += 1;

                    print('Got', newClanName);

                    local gotClan = false;

                    for clanDisplayName, value in next, library.flags.clans do
                        local clanName = clanDisplayName:match('%w+ %p (%w+)');

                        if (value and clanName == newClanName) then
                            MemStorageService:RemoveItem('doSpinSlot');
                            MemStorageService:RemoveItem('doSpinTotal');

                            functions.rollBackData(false); --This prob should force them to join the main game to get rid of the rollback evidence
                            ToastNotif.new({text = 'You\'ve just got ' .. clanName .. ', please leave the game and re-connect.'});

                            return;
                        end;
                    end;

                    continue;
                end;

                if (not suc) then
                    if (not waitingToTp) then
                        waitingToTp = true;
                        MemStorageService:SetItem('doSpinSlot', localPlayer.Slot.Value);
                        MemStorageService:SetItem('doSpinTotal', MemStorageService:GetItem('doSpinTotal') + rollCount);

                        ToastNotif.new({text = string.format('Rolled %d clans total. Your data is still rolled back.', rollCount)});
                    end;

                    if (tick() - lastTpAt > 10) and library.flags.autoRejoin then
                        lastTpAt = tick();
                        TeleportService:Teleport(LOBBY_PLACE_ID);
                        ToastNotif.new({text = 'Attempting to join a new server.'});
                    end;
                end;
            end;
        end);
    end;

    if (MemStorageService:HasItem('doSpinSlot')) then
        library.OnLoad:Connect(function()
            task.spawn(function()
                localPlayer:WaitForChild('PlayerGui'):WaitForChild('Character_Slot_Select').Enabled = false;
            end);

            localPlayer:WaitForChild('Slot', math.huge);
            Remotes.Apply_Slot:InvokeServer(MemStorageService:GetItem('doSpinSlot'));

            functions.doSpin();
        end);
    end;

    local clanList = {
        {'Supreme', { 'Kamado', 'Agatsuma', 'Rengoku' }},
        {'Mythic', { 'Tomioka', 'Tokito', 'Hashibira', 'Soyama'}},
        {'Legendary', { 'Shinazugawa', 'Kocho', 'Sabito', 'Tamayo', 'Kuwajima', 'Makamo' }},
        {'Rare', {  'Kanamori', 'Haganezuka', 'Ubuyashiki', 'Urokodaki', 'Kanzaki' }},
        {'Uncommon', { 'Kaneki', 'Nakahara', 'Terauchi', 'Takada' }},
        {'Common', { 'Sakurai', 'Fujiwara', 'Mori', 'Hashimoto', 'Saito', 'Ishida', 'Nishimura', 'Ando', 'Onishi', 'Fukuda', 'Kurosaki', 'Haruno', 'Bakugo', 'Toka', 'Izuku', 'Suzuki', 'Kurosaki', 'Todoroki' }}
    };

    local allClans = {};

    for _, data in next, clanList do
        local clanRarity, clanData = unpack(data);

        for _, clanName in next, clanData do
            table.insert(allClans, clanRarity .. ' - ' .. clanName);
        end;
    end;

    spinSection:AddList({text = 'Clans', multiselect = true, values = allClans});

    spinSection:AddToggle({text = 'Auto Rejoin'});
    spinSection:AddButton({text = 'Spin', callback = functions.doSpin});

    return;
end;