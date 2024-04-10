local LocalPlayer = game:GetService('Players').LocalPlayer;
local ReplicatedStorage = game:GetService('ReplicatedStorage');

local Maid = sharedRequire('@/utils/Maid.lua');
local ToastNotif = sharedRequire('@classes/ToastNotif.lua');

local function createCirclet(parent, weldPart, cframe, color)
    local circlet = game:GetObjects('rbxassetid://12562484379')[1]:Clone();
    circlet.Size = Vector3.new(1.372, 0.198, 1.396);
    circlet.Parent = parent;

    if (color) then
        circlet.Color = color;
    end;

    local weld = Instance.new('Weld', circlet);
    weld.Part0 = weldPart;
    weld.Part1 = circlet;
    weld.C0 = cframe;

    return circlet;
end;

return function (misc)
    local functions = {};
    local globalMaid = Maid.new();

    local function makeToggle(name, parts, offset)
        local maid = Maid.new();
        local currentColor;

        misc:AddToggle({
            text = name,
            callback = function(t)
                if (not t) then
                    maid:DoCleaning();
                    return;
                end;

                local function onCharacterAdded(character)
                    if (not character) then return end;

                    for i, partName in next, parts do
                        task.spawn(function()
                            local partObject = character:WaitForChild(partName, 5);
                            if (not partObject) then return end;

                            maid[name .. i] = createCirclet(character, partObject, offset, currentColor);
                        end);
                    end;
                end;

                onCharacterAdded(LocalPlayer.Character);
                maid:GiveTask(LocalPlayer.CharacterAdded:Connect(onCharacterAdded));
            end
        }):AddColor({
            text = name,
            callback = function(color)
                for i = 1, #parts do
                    if (not maid[name..i]) then continue end;
                    maid[name .. i].Color = color;
                end;

                currentColor = color;
            end
        });
    end;

    local turnedOn = false;

    function functions.lightbornSkinColor(t)
        if (not t) then
            globalMaid.lightbornSkinColor = nil;
            if (turnedOn) then
                turnedOn = false;
                ToastNotif.new({text = 'Respawn to get back old skin color'});
            end;
            return;
        end;

        turnedOn = true;

        globalMaid.lightbornSkinColor = task.spawn(function()
            while true do
                task.wait(0.1);
                if (not LocalPlayer.Character) then continue end;
                pcall(function()
                    LocalPlayer.Character.Head.FaceMount.DGFace.Texture = "rbxassetid://6466188578"
                end);
                for _, v in next, LocalPlayer.Character:GetChildren() do
                    if (v.Name == 'LightbornCirclet') then continue end;
                    if (v:FindFirstChild('MarkingMount')) then
                        v.MarkingMount.Color = Color3.fromRGB(253, 234, 141);
                    elseif (v:IsA('BasePart')) then
                        v.Color = Color3.fromRGB(253, 234, 141);
                    end;
                end;
            end;
        end);
    end;

    local function contractorToggle(t)
        if (not t) then
            globalMaid.contractorCharAdded = nil;
            globalMaid.contractorParts = nil;
            return;
        end;

        local function onCharacterAdded(character)
            if (not character) then return end;
            local char = LocalPlayer.Character;
            local hrp = char:WaitForChild('HumanoidRootPart', 10);
            if (not hrp) then return end;

            local string = ReplicatedStorage.Assets.Effects.ContractorString;
            local clone1, clone2, clone3, clone4;

            do
                clone1 = string:Clone();
                clone1.Parent = hrp;

                local attachment1 = Instance.new("Attachment",hrp);
                attachment1.Position = Vector3.new(1,5,0);
                attachment1.Name = "StringAttach1";--AboveHrp

                local attachment2 = Instance.new("Attachment",char.RightHand);
                attachment2.Position = Vector3.new(0.5,0,0);
                attachment2.Name = "StringAttach2";--RightHand

                clone1.Attachment1 = attachment1;
                clone1.Attachment0 = attachment2;


                clone2 = string:Clone();
                clone2.Parent = hrp;

                local attachment3 = Instance.new("Attachment",hrp);
                attachment3.Position = Vector3.new(-1,5,0);
                attachment3.Name = "StringAttach3";--AboveHrp

                local attachment4 = Instance.new("Attachment",char.LeftHand);
                attachment4.Position = Vector3.new(-0.5,0,0);
                attachment4.Name = "StringAttach4";--LeftHand

                clone2.Attachment1 = attachment3;
                clone2.Attachment0 = attachment4;
            end

            do
                clone3 = string:Clone();
                clone3.Parent = hrp;

                local attachment3 = Instance.new("Attachment",hrp);
                attachment3.Position = Vector3.new(0.5,5,0);
                attachment3.Name = "StringAttach3";--RightShoulder

                clone3.Attachment1 = attachment3;
                clone3.Attachment0 = char.Torso.RightCollarAttachment;

                clone4 = string:Clone();
                clone4.Parent = hrp;

                local attachment4 = Instance.new("Attachment",hrp);
                attachment4.Position = Vector3.new(-1,5,0);
                attachment4.Name = "StringAttach4"; --LeftShoulder

                clone4.Attachment1 = attachment4;
                clone4.Attachment0 = char.Torso.LeftCollarAttachment;
            end

            globalMaid.contractorParts = function()
                clone1:Destroy();
                clone2:Destroy();
                clone3:Destroy();
                clone4:Destroy();
            end;
        end

        onCharacterAdded(LocalPlayer.Character);
        globalMaid.contractorCharAdded = LocalPlayer.CharacterAdded:Connect(onCharacterAdded);
    end

    misc:AddToggle({text = 'Lightborn Skin Color', callback = functions.lightbornSkinColor})

    makeToggle('Lightborn (Variant 1)', {'Head'}, CFrame.new(-0.001, 0.754, -0.002));
    makeToggle('Lightborn (Variant 2)', {'Head'}, CFrame.new(-0.001, -0.35, -0.002));
    makeToggle('Lightborn (Variant 3)', {'Right Arm', 'Left Arm'}, CFrame.new(-0.001, -0.5, -0.002));

    misc:AddToggle({
        text = 'Contractor',
        callback = contractorToggle
    })
end;