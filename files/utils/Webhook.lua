local Services = sharedRequire('@utils/Services.lua');
local HttpService = Services:Get('HttpService');

local Webhook = {};
Webhook.__index = Webhook;

function Webhook.new(url)
    local self = setmetatable({}, Webhook);

    self._url = url;

    return self;
end;

function Webhook:Send(data, yields)
    if (typeof(data) == 'string') then
        data = {content = data};
    end;

    local function send()
        syn.request({
            Url = self._url,
            Method = 'POST',
            Headers = {['Content-Type'] = 'application/json'},
            Body = originalFunctions.jsonEncode(HttpService, data)
        });
    end;

    if (yields) then
        pcall(send);
    else
        task.spawn(send);
    end;
end;

return Webhook;