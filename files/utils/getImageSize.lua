local Buffer = {};

Buffer.ClassName = 'Buffer';
Buffer.__index = Buffer;

function Buffer.new(data)
    local self = setmetatable({}, Buffer);

    self._data = data;
    self._pos = 0;

    return self;
end;

function Buffer:read(num)
    local data = self._data:sub(self._pos + 1, self._pos + num);
    self._pos = self._pos + num;

    return data;
end;

local function read(str)
    return str:sub(1,1):byte() * 16777216 + str:sub(2,2):byte() * 65536 + str:sub(3,3):byte() * 256 + str:sub(4,4):byte();
end;

local function getImageSize(imageData)
    local buffer = Buffer.new(imageData);

    buffer:read(1);

    if(buffer:read(3) == 'PNG') then
        buffer:read(12);

        local width = read(buffer:read(4));
        local height = read(buffer:read(4));

        return Vector2.new(width, height);
    end;

    buffer:read(-4);

    if (buffer:read(4) == "GIF8") then
        buffer:read(2);

        local width = buffer:read(1):byte()+buffer:read(1):byte()*256;
        local height = buffer:read(1):byte()+buffer:read(1):byte()*256;

        return Vector2.new(width, height);
    end;
end;

return getImageSize;