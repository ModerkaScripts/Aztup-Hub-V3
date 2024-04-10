local Maid = sharedRequire('@utils/Maid.lua');
local Services = sharedRequire('@utils/Services.lua');
local library = sharedRequire('@UILibrary.lua');

local RunService = Services:Get('RunService');

local oldVolume = UserSettings().GameSettings.MasterVolume;
local playingAudios = 0;

UserSettings().GameSettings:GetPropertyChangedSignal('MasterVolume'):Connect(function()
    local newVolume = UserSettings().GameSettings.MasterVolume;

    if (playingAudios <= 0) then
        oldVolume = newVolume;
    end;
end);

local AudioPlayer = {};
AudioPlayer.__index = AudioPlayer;

local audioFolder = Instance.new('Folder');

if (not gethui) then
    syn.protect_gui(audioFolder);
end;

audioFolder.Parent = gethui and gethui() or Services:Get('CoreGui');
if (not isfolder('Aztup Hub V3/sounds')) then
    makefolder('Aztup Hub V3/sounds');
end;

function AudioPlayer.new(options)
    local self = setmetatable({}, AudioPlayer);

    options = options or {};
    options.forcedAudio = options.forcedAudio;

    self._options = options;

    self._sound = Instance.new('Sound');
    self._sound.Volume = options.volume or 1;
    self._sound.Looped = options.looped or false;

    self._sound.Parent = audioFolder;

    self._maid = Maid.new();

    if (options.soundId) then
        self._sound.SoundId = options.soundId;
    elseif (options.url) then
        local fileName = syn.crypt.hash(options.url) .. '.bin';
        local filePath = string.format('Aztup Hub V3/sounds/%s', fileName);

        if (not isfile(filePath)) then 
            local success, data = pcall(syn.request, {Url = options.url});
            if (success) then
                writefile(filePath, data.Body);
            end;
        end;

        self._sound.SoundId = getsynasset(filePath);
    end;

    if (options.autoPlay) then
        self:Play();
    end;

    self._maid:GiveTask(self._sound.Ended:Connect(function()
        playingAudios -= 1;
        self._maid.loop = nil;
        if (not self._options.forcedAudio) then return end;
        UserSettings().GameSettings.MasterVolume = oldVolume;
    end));

    return self;
end;

function AudioPlayer:GetSound()
    return self._sound;
end;

function AudioPlayer:Play()
    playingAudios += 1;

    if (self._options.forcedAudio) then
        self._maid.loop = RunService.Heartbeat:Connect(function()
            UserSettings().GameSettings.MasterVolume = 10;
        end);
    end;

    self._sound:Play();
end;

function AudioPlayer:Stop()
    playingAudios -= 1;

    self._maid.loop = nil;
    UserSettings().GameSettings.MasterVolume = oldVolume;

    self._sound:Stop();
end;

return AudioPlayer;