local Services = sharedRequire('./Services.lua');
local library = sharedRequire('../UILibrary.lua');
local AltManagerAPI = sharedRequire('../classes/AltManagerAPI.lua');
local Players, GuiService, HttpService, StarterGui, VirtualInputManager, CoreGui = Services:Get('Players', 'GuiService', 'HttpService', 'StarterGui', 'VirtualInputManager', 'CoreGui');
local LocalPlayer = Players.LocalPlayer;

local BlockUtils = {};
local IsFriendWith = LocalPlayer.IsFriendsWith;

local apiAccount;

task.spawn(function()
    apiAccount = AltManagerAPI.new(LocalPlayer.Name);
end);

local function isFriendWith(userId)
    local suc, data = pcall(IsFriendWith, LocalPlayer, userId);

    if (suc) then
        return data;
    end;

    return true;
end;

function BlockUtils:BlockUser(userId)
    if(library.flags.useAltManagerToBlock and apiAccount) then
        apiAccount:BlockUser(userId);

        local blockedListRetrieved, blockList = pcall(HttpService.JSONDecode, HttpService, apiAccount:GetBlockedList());
        if(blockedListRetrieved and typeof(blockList) == 'table' and blockList.success and blockList.total >= 20) then
            apiAccount:UnblockEveryone();
        end;
    else
        library.base.Enabled = false;

        local blockedUserIds = StarterGui:GetCore('GetBlockedUserIds');
        local playerToBlock = Instance.new('Player');
        playerToBlock.UserId = tonumber(userId);

        local lastList = #blockedUserIds;
        GuiService:ClearError();

        repeat
            StarterGui:SetCore('PromptBlockPlayer', playerToBlock);

            local confirmButton = CoreGui.RobloxGui.PromptDialog.ContainerFrame:FindFirstChild('ConfirmButton');
            if (not confirmButton) then break end;

            local btnPosition = confirmButton.AbsolutePosition + Vector2.new(40, 40);

            VirtualInputManager:SendMouseButtonEvent(btnPosition.X, btnPosition.Y, 0, false, game, 1);
            task.wait();
            VirtualInputManager:SendMouseButtonEvent(btnPosition.X, btnPosition.Y, 0, true, game, 1);
            task.wait();
        until #StarterGui:GetCore('GetBlockedUserIds') ~= lastList;

        task.wait(0.2);

        library.base.Enabled = true;
    end;
end;

function BlockUtils:UnblockUser()

end;

function BlockUtils:BlockRandomUser()
    for _, v in next, Players:GetPlayers() do
        if (v ~= LocalPlayer and not isFriendWith(v.UserId)) then
            self:BlockUser(v.UserId);
            break;
        end;
    end;
end;

return BlockUtils;