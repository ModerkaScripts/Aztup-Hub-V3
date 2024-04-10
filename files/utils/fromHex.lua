local function fromHex(str)
    return (string.gsub(str, '..', function (cc)
        return string.char(tonumber(cc, 16));
    end));
end;

return fromHex;