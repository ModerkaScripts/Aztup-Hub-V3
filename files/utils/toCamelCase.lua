SX_VM_CNONE();
local stringPattern = getServerConstant('%s(.)');
return function (text)
    return string.lower(text):gsub(stringPattern, string.upper);
end;