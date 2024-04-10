local Services = sharedRequire('../utils/Services.lua');
local library = sharedRequire('../UILibrary.lua');

local column1, column2 = unpack(library.columns);
local ReplicatedStorage = Services:Get('ReplicatedStorage');

local gameLocal = require(ReplicatedStorage.RobeatsGameCore.RobeatsGame);
local oldGameLocal = gameLocal.new;

local noteResult = require(ReplicatedStorage.RobeatsGameCore.Enums.NoteResult);

local AutoPlayer = column1:AddSection("Auto Player");

AutoPlayer:AddToggle({text = 'Enable', flag = 'Toggle Auto Player'});
AutoPlayer:AddToggle({text = 'Random'});
AutoPlayer:AddSlider({text = 'Marvelous', min = 0, max = 100});
AutoPlayer:AddSlider({text = 'Perfect', value = 65, min = 0, max = 100});
AutoPlayer:AddSlider({text = 'Great', value = 35, min = 0, max = 100});
AutoPlayer:AddSlider({text = 'Good', min = 0, max = 100});
AutoPlayer:AddSlider({text = 'Miss', min = 0, max = 100});

local randomiser = Random.new();

local function generateRandomScore()
    if (library.flags.random) then
        return math.random(1, 5);
    else
        local chances = {
            [noteResult.Marvelous] = library.flags.marvelous,
            [noteResult.Perfect] = library.flags.perfect,
            [noteResult.Great] = library.flags.great,
            [noteResult.Good] = library.flags.good,
            [noteResult.Bad] = library.flags.bad
        };

        local randomTable = {};

        for i, v in next, chances do
            for i2 = 1, v do
                table.insert(randomTable, i);
            end;
        end;

        return randomTable[randomiser:NextInteger(1, #randomTable)];
    end;
end;

_G.test = generateRandomScore;

local function performGameLocalHook(gameLocal)
    local oldUpdate = gameLocal.update;

    function gameLocal:update(delta)
        local trackSystem = self:get_local_tracksystem();
        if (trackSystem and library.flags.toggleAutoPlayer) then
            local notes = trackSystem:get_notes();


            for noteIndex, note in next, notes._table do
                local canHit, noteScore = note:test_hit();
                local canHit2, noteScore2 = note:test_release();
                local wantedScore = generateRandomScore();

                if (note.ClassName == 'SingleNote') then
                    canHit2 = true;
                    noteScore2 = wantedScore;
                end;

                local trackIndex = note:get_track_index();

                if (canHit and noteScore == wantedScore) then
                    trackSystem:press_track_index(trackIndex);
                end;

                if (canHit2 and noteScore2 == wantedScore) then
                    trackSystem:release_track_index(trackIndex);
                end;
            end;
        end;

        return oldUpdate(self, delta);
    end;
end

gameLocal.new = function(...)
    local newGameLocal = oldGameLocal(...);
    performGameLocalHook(newGameLocal);

    return newGameLocal;
end;

for i, v in next, getgc(true) do
    if (typeof(v) == 'table' and rawget(v, '_game')) then
        performGameLocalHook(v._game);
        break;
    end;
end;