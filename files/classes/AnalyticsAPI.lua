local HttpService = game:GetService('HttpService');

local Analytics = {}
Analytics.__index = Analytics;

do
    function Analytics.new(id)
        local self = setmetatable({}, Analytics);

        self._id = id;

        return self;
    end;

    function Analytics:Report(Category, Action, Value)
        local Label = string.format('AH:%s', accountData.username);

        task.spawn(syn.request, {
            Url = 'http://www.google-analytics.com/collect',
            Method = 'POST',
            Body = string.format('v=1&t=event&sc=start&tid=%s&cid=%s&ec=%s&ea=%s&el=%s&ev=%s', self._id, accountData.uuid, HttpService:UrlEncode(Category), HttpService:UrlEncode(Action), HttpService:UrlEncode(Label), HttpService:UrlEncode(Value)),
            Headers = {
                ['Content-Type'] = 'application/x-www-form-urlencoded'
            }
        })
    end;
end;

return Analytics;