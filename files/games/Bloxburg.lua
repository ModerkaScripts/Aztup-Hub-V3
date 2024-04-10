local Services = sharedRequire('../utils/Services.lua');
local library = sharedRequire('../UILibrary.lua');
local Maid = sharedRequire('../utils/Maid.lua');
local prettyPrint = sharedRequire('../utils/prettyPrint.lua');

local column1, column2 = unpack(library.columns);

local Players, ReplicatedStorage, HttpService, PathfindingService, RunService, TweenService = Services:Get(
    'Players',
    'ReplicatedStorage',
    'HttpService',
    'PathfindingService',
    'RunService',
    'TweenService'
);

local LocalPlayer = Players.LocalPlayer;
local Heartbeat = RunService.Heartbeat;

do -- // Functions
    local framework = require(ReplicatedStorage:WaitForChild('Framework'));
    framework = getupvalue(framework, 3);

    local modules;
    local network;

    local jobManager;
    local guiHandler;

    repeat
        task.wait();

        modules = framework.Modules;
        if (not modules) then continue end;

        network = framework.net;
        if (not network) then continue end;

        jobManager = modules.JobHandler;
        if (not jobManager) then continue end;

        guiHandler = modules.GUIHandler;
        if (not guiHandler) then continue end;
    until modules and network and jobManager and guiHandler;

    local saveHouse;
    local loadHouse;

    if (not isfolder('Aztup Hub V3/Bloxburg Houses')) then
        makefolder('Aztup Hub V3/Bloxburg Houses');
    end;

    hookfunction(getfenv(network.FireServer).i, function()
        print('Ban attempt lel');
    end);

    -- if(not debugMode) then
        guiHandler:AlertBox(
            'If you encounter any bugs using the auto farm make sure you post them in the discord #bug-reports channel.In all case to not get banned make sure that you buy a car after you finished your shift and make sure that you dont farm overnight.\n\nWe are not responsible in any shape of form if you get banned!',
            'Warning',
            0.5
        );
    -- end;

    function saveHouse(player)
        local plot = workspace.Plots[string.format("Plot_%s", player.Name)];
        local ground = plot.Ground;

        local saveData = {};
        saveData.Walls = {};
        saveData.Paths = {};
        saveData.Floors = {};
        saveData.Roofs = {};
        saveData.Pools = {};
        saveData.Fences = {};
        saveData.Ground = {};
        saveData.Ground.Counters = {};
        saveData.Ground.Objects = {};
        saveData.Basements = {};

        local objects = {};
        local counters = {};

        local function getRotation(object)
            return tostring(plot.PrimaryPart.CFrame:ToObjectSpace(object));
            --local rot = -math.atan2(object.lookVector.z, object.lookVector.x) - math.pi * 0.5;

            --if(rot < 0) then
            --    rot = 2 * math.pi + rot;
            --end;

            -- return rot;
        end;

        local function getFloor(position)
            local currentFloor, currentFloorDistance = nil, math.huge;

            for i, v in next, plot.House.Floor:GetChildren() do
                if((v.Part.Position - position).Magnitude <= currentFloorDistance) then
                    currentFloor = v;
                    currentFloorDistance = (v.Part.Position - position).Magnitude;
                end;
            end;

            return currentFloor;
        end;

        local function getPolePosition(pole)
            pole = pole.Value;
            if(pole.Parent:IsA('BasePart')) then
                return pole.Parent.Position;
            else
                return pole.Parent.Value;
            end;

            return error('something went wrong!');
        end;

        for _, object in next, plot.House.Objects:GetChildren() do
            local floor = getFloor(object.Position) or plot;

            local objectData = {};
            objectData.Name = object.Name;
            objectData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(object);
            objectData.Rot = getRotation(object.CFrame);
            objectData.Position = tostring(ground.CFrame:PointToObjectSpace(object.Position));

            if(not objects[floor]) then
                objects[floor] = {};
            end;

            if(object:FindFirstChild('ItemHolder')) then
                for _, item in next, object.ItemHolder:GetChildren() do
                    if(item:FindFirstChild('RailingSegment')) then
                        if(not objectData.Fences) then
                            objectData.Fences = {};
                        end;
                        local _, from = framework.Shared.FenceService:GetEdgePositions(item);

                        local offSetFrom = ground.CFrame:PointToObjectSpace(from);

                        local itemData = {};
                        itemData.Name = item.Name;
                        itemData.From = tostring(offSetFrom);
                        itemData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(item);
                        itemData.Segment = item.RailingSegment.Value.Name;

                        table.insert(objectData.Fences, itemData);
                    else
                        if(not objectData.Items) then
                            objectData.Items = {};
                        end;

                        local itemData = {};
                        itemData.Name = item.Name;
                        itemData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(item);
                        itemData.Rot = getRotation(item.CFrame);
                        itemData.Position = tostring(ground.CFrame:PointToObjectSpace(item.Position));
                        table.insert(objectData.Items, itemData);
                    end;
                end;
            end;

            table.insert(objects[floor], objectData);
        end;

        for _, counter in next, plot.House.Counters:GetChildren() do
            local floor = getFloor(counter.Position) or plot;

            local counterData = {};
            counterData.Name = counter.Name;
            counterData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(counter);
            counterData.Rot = getRotation(counter.CFrame);
            counterData.Position = tostring(ground.CFrame:PointToObjectSpace(counter.Position));

            if(not counters[floor]) then
                counters[floor] = {};
            end;

            if(counter:FindFirstChild('ItemHolder')) then
                for _, item in next, counter.ItemHolder:GetChildren() do
                    if(not counterData.Items) then
                        counterData.Items = {};
                    end;

                    local itemData = {};
                    itemData.Name = item.Name;
                    itemData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(item);
                    itemData.Rot = getRotation(item.CFrame);
                    itemData.Position = tostring(ground.CFrame:PointToObjectSpace(item.Position));
                    table.insert(counterData.Items, itemData);
                end;
            end;

            table.insert(counters[floor], counterData);
        end;

        for _, wall in next, plot.House.Walls:GetChildren() do
            if(wall.Name ~= 'Poles') then
                local offSetFrom, offSetTo = ground.CFrame:PointToObjectSpace(getPolePosition(wall.BPole)), ground.CFrame:PointToObjectSpace(getPolePosition(wall.FPole));

                local wallData = {};
                wallData.From = tostring(offSetFrom);
                wallData.To = tostring(offSetTo);
                wallData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(wall);
                wallData.Items = {};

                if(wall:FindFirstChild('ItemHolder')) then
                    for _, item in next, wall.ItemHolder:GetChildren() do
                        local itemData = {};

                        itemData.Name = item.Name;
                        itemData.Position = tostring(ground.CFrame:PointToObjectSpace(item.Position));
                        itemData.Side = item:FindFirstChild("SideValue") and item.SideValue.Value == -1 or nil;
                        itemData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(item);

                        local itemConfig = framework.Items:GetItem(item.Name);
                        if(itemConfig.Type ~= 'Windows' and itemConfig.Type ~= 'Doors') then
                            itemData.Rot = getRotation(item.CFrame);
                        end;


                        if(item:FindFirstChild('ItemHolder')) then
                            itemData.Items = {};
                            for _, item2 in next, item.ItemHolder:GetChildren() do
                                local itemData2 = {};

                                itemData2.Name = item2.Name;
                                itemData2.Rot = getRotation(item2.CFrame);
                                itemData2.Position = tostring(ground.CFrame:PointToObjectSpace(item2.Position));
                                itemData2.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(item2);

                                table.insert(itemData.Items, itemData2);
                            end;
                        end;

                        table.insert(wallData.Items, itemData);
                    end;
                end;

                table.insert(saveData.Walls, wallData);
            end;
        end;

        for _, floor in next, plot.House.Floor:GetChildren() do
            local floorData = {};
            floorData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(floor);
            floorData.Points = {};
            floorData.Objects = objects[floor] or {};
            floorData.Counters = counters[floor] or {};

            for i, v in next, floor.PointData:GetChildren() do
                table.insert(floorData.Points, tostring(v.Value));
            end;

            table.insert(saveData.Floors, floorData);
        end;

        for _, roof in next, plot.House.Roof:GetChildren() do
            local roofData = {};
            roofData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(roof);
            roofData.Name = roof.Name;
            roofData.Points = {};
            roofData.Items = {};

            for i, v in next, roof.PointData:GetChildren() do
                table.insert(roofData.Points, tostring(v.Value));
            end;

            if(roof:FindFirstChild('ItemHolder')) then
                for _, item in next, roof.ItemHolder:GetChildren() do
                    local itemData = {};
                    itemData.Name = item.Name;
                    itemData.Position = tostring(ground.CFrame:PointToObjectSpace(item.Position));
                    itemData.Rot = getRotation(item.CFrame);
                    itemData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(item);

                    table.insert(roofData.Items, itemData);
                end;
            end;

            table.insert(saveData.Roofs, roofData);
        end;

        for _, path in next, plot.House.Paths:GetChildren() do
            if(path.Name ~= 'Poles') then
                local offSetFrom, offSetTo = ground.CFrame:PointToObjectSpace(getPolePosition(path.BPole)), ground.CFrame:PointToObjectSpace(getPolePosition(path.FPole));
                local floorData = {};

                floorData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(path);
                floorData.From = tostring(offSetFrom);
                floorData.To = tostring(offSetTo);

                table.insert(saveData.Paths, floorData);
            end;
        end;

        for _, pool in next, plot.House.Pools:GetChildren() do
            local poolData = {};
            poolData.Position = tostring(ground.CFrame:ToObjectSpace(pool.HitBox.CFrame));
            poolData.Size = tostring(Vector2.new(pool.HitBox.Size.X, pool.HitBox.Size.Z));
            poolData.Type = pool.Name;

            table.insert(saveData.Pools, poolData);
        end;

        for _, basement in next, plot.House.Basements:GetChildren() do
            local basementData = {};
            basementData.Position = tostring(ground.CFrame:ToObjectSpace(basement.HitBox.CFrame));
            basementData.Size = tostring(Vector2.new(basement.HitBox.Size.X, basement.HitBox.Size.Z));
            basementData.Type = basement.Name;

            table.insert(saveData.Basements, basementData);
        end;

        for _, fence in next, plot.House.Fences:GetChildren() do
            if(fence.Name ~= 'Poles') then
                local to, from = framework.Shared.FenceService:GetEdgePositions(fence);

                local offSetTo, offSetFrom = ground.CFrame:PointToObjectSpace(to), ground.CFrame:PointToObjectSpace(from);
                local fenceData = {};

                fenceData.To = tostring(offSetTo);
                fenceData.From = tostring(offSetFrom);
                fenceData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(fence);
                fenceData.Name = fence.Name;
                fenceData.Items = {};

                if(fence:FindFirstChild('ItemHolder')) then
                    for _, item in next, fence.ItemHolder:GetChildren() do
                        local itemData = {};
                        itemData.AppearanceData = framework.Shared.ObjectService:GetAppearanceData(item);
                        itemData.Name = item.Name;
                        itemData.Rot = getRotation(item.CFrame);
                        itemData.Position = tostring(ground.CFrame:PointToObjectSpace(item.Position));

                        table.insert(fenceData.Items, itemData);
                    end;
                end;

                table.insert(saveData.Fences, fenceData);
            end;
        end;

        if(objects[plot]) then
            saveData.Ground.Objects = objects[plot];
        end;

        if(counters[plot]) then
            saveData.Ground.Counters = counters[plot]
        end;

        local playerHouses = ReplicatedStorage.Stats[player.Name].Houses;
        local playerHouse;

        for _, v in next, ReplicatedStorage.Stats[player.Name].Houses:GetChildren() do
            if(v.Value == playerHouses.Value) then
                playerHouse = v;
            end;
        end;

        saveData.totalValue = playerHouse.TotalValue.Value or 'Unknown';
        saveData.bsValue = playerHouse.BSValue.Value or 'Unknown';

        writefile(string.format('Aztup Hub V3/Bloxburg Houses/%s.json', player.Name), HttpService:JSONEncode(saveData))
    end;

    function loadHouse(houseData)
        local myPlot = workspace.Plots['Plot_' .. Players.LocalPlayer.Name];
        local myGround = myPlot.Ground;

        local placements = 0;
        local oldFramework = framework;

        local streamRefTypes = {
            'PlaceObject',
            'PlaceWall',
            'PlaceFloor',
            'PlacePath',
            'PlaceRoof'
        };

        local framework = {
            net = setmetatable({
                InvokeServer = function(self, data)
                    placements = placements + 1;
                    if(placements >= 4) then
                        placements = 0;
                        task.wait(3);
                    end;

                    local dataType = data.Type;
                    local returnData = {oldFramework.net:InvokeServer(data)};

                    if (table.find(streamRefTypes, dataType)) then
                        returnData[1] = typeof(returnData[1]) == 'Instance' and returnData[1].Value;
                    end;

                    return unpack(returnData);
                end;
            }, {__index = oldFramework.net});
        };

        local position = framework.net:InvokeServer({
            Type = 'ToPlot',
            Player = LocalPlayer;
        });
        LocalPlayer.Character:SetPrimaryPartCFrame(position);

        framework.net:InvokeServer({
            Type = 'EnterBuild',
            Plot = myPlot
        })

        local function convertToVector3(vectorString)
            return myGround.CFrame:PointToWorldSpace(Vector3.new(unpack(vectorString:split(','))));
        end;

        local function convertPoints(points)
            local newPoints = {};

            for i, v in next, points do
                table.insert(newPoints, convertToVector3(v));
            end;

            return newPoints;
        end;

        local function convertRot(cf)
            if(not cf) then
                return;
            end;

            local newCf = myGround.CFrame:ToWorldSpace(CFrame.new(unpack(cf:split(','))));
            local rot = -math.atan2(newCf.lookVector.z, newCf.lookVector.x) - math.pi * 0.5;

            if(rot < 0) then
                rot = 2 * math.pi + rot;
            end;

            return rot;
        end

        local count = 0;
        local totalCount = 0;
        for i, v in next, houseData do
            if(typeof(v) == 'table') then
                totalCount = totalCount + #v;
            end;
        end;

        print('starting for', count);

        for _, wallData in next, houseData.Walls do
            local offSetFrom, offSetTo = convertToVector3(wallData.From), convertToVector3(wallData.To);
            local wall = framework.net:InvokeServer({
                Type = 'PlaceWall',
                From = offSetFrom,
                To = offSetTo
            })

            for _, itemData in next, wallData.Items do
                local item = framework.net:InvokeServer({
                    Type = 'PlaceObject',
                    Name = itemData.Name,
                    TargetModel = wall,
                    Rot = convertRot(itemData.Rot),
                    Pos = convertToVector3(itemData.Position),
                });

                if(itemData.Items) then
                    for _, itemData2 in next, itemData.Items do
                        local item2 = framework.net:InvokeServer({
                            Type = 'PlaceObject',
                            Name = itemData2.Name,
                            TargetModel = item,
                            Rot = convertRot(itemData2.Rot),
                            Pos = convertToVector3(itemData2.Position),
                        });

                        framework.net:InvokeServer({
                            Type = 'ColorObject',
                            Object = item2,
                            UseMaterials = true,
                            Data = itemData2.AppearanceData
                        })
                    end;
                end;

                framework.net:InvokeServer({
                    Type = 'ColorObject',
                    Object = item,
                    UseMaterials = true,
                    Data = itemData.AppearanceData
                })
            end;

            framework.net:InvokeServer({
                Type = 'ColorObject',
                Object = wall,
                UseMaterials = true,
                Data = {wallData.AppearanceData[1], {}, {}, {}},
                Side = 'R'
            })

            framework.net:InvokeServer({
                Type = 'ColorObject',
                Object = wall,
                UseMaterials = true,
                Data = {wallData.AppearanceData[2], {}, {}, {}},
                Side = 'L'
            })
        end;

        for _, floorData in next, houseData.Floors do
            local floor = framework.net:InvokeServer({
                Type = 'PlaceFloor',
                Points = convertPoints(floorData.Points)
            });

            for _, itemData in next, floorData.Objects or {} do
                local item = framework.net:InvokeServer({
                    Type = 'PlaceObject',
                    Name = itemData.Name,
                    TargetModel = floor,
                    Rot = convertRot(itemData.Rot),
                    Pos = convertToVector3(itemData.Position),
                });

                framework.net:InvokeServer({
                    Type = 'ColorObject',
                    Object = item,
                    UseMaterials = true,
                    Data = itemData.AppearanceData
                })

                if(itemData.Fences and item) then
                    for _, fenceData in next, itemData.Fences do
                        local fence = framework.net:InvokeServer({
                            Type = 'PlaceObject',
                            Name = fenceData.Name,
                            Pos = convertToVector3(fenceData.From),
                            RailingSegment = item.ObjectModel.Railings[fenceData.Segment]
                        });

                        if(not fence and debugMode) then
                            warn(fence);
                            error('failed to place fence');
                        end;

                        framework.net:InvokeServer({
                            Type = 'ColorObject',
                            Object = fence,
                            UseMaterials = true,
                            Data = fenceData.AppearanceData
                        })
                    end;
                end;

                if(itemData.Items) then
                    for _, itemData2 in next, itemData.Items do
                        local item2 = framework.net:InvokeServer({
                            Type = 'PlaceObject',
                            Name = itemData2.Name,
                            TargetModel = item,
                            Rot = convertRot(itemData2.Rot),
                            Pos = convertToVector3(itemData2.Position),
                        });

                        framework.net:InvokeServer({
                            Type = 'ColorObject',
                            Object = item2,
                            UseMaterials = true,
                            Data = itemData2.AppearanceData
                        })
                    end;
                end;
            end;

            for _, counterData in next, floorData.Counters or {} do
                local item = framework.net:InvokeServer({
                    Type = 'PlaceObject',
                    Name = counterData.Name,
                    TargetModel = floor,
                    Rot = convertRot(counterData.Rot),
                    Pos = convertToVector3(counterData.Position),
                });

                if(counterData.Items) then
                    for _, itemData in next, counterData.Items do
                        local item2 = framework.net:InvokeServer({
                            Type = 'PlaceObject',
                            Name = itemData.Name,
                            TargetModel = item,
                            Rot = convertRot(itemData.Rot),
                            Pos = convertToVector3(itemData.Position),
                        });

                        framework.net:InvokeServer({
                            Type = 'ColorObject',
                            Object = item2,
                            UseMaterials = true,
                            Data = itemData.AppearanceData
                        })
                    end;
                end;

                framework.net:InvokeServer({
                    Type = 'ColorObject',
                    Object = item,
                    UseMaterials = true,
                    Data = counterData.AppearanceData
                })
            end;

            framework.net:InvokeServer({
                Type = 'ColorObject',
                Object = floor,
                UseMaterials = true,
                Data = floorData.AppearanceData
            })
        end;

        for _, pathData in next, houseData.Paths do
            local path = framework.net:InvokeServer({
                Type = 'PlacePath',
                To = convertToVector3(pathData.To),
                From = convertToVector3(pathData.From)
            })

            framework.net:InvokeServer({
                Type = 'ColorObject',
                Object = path,
                UseMaterials = true,
                Data = pathData.AppearanceData
            })
        end;

        for _, roofData in next, houseData.Roofs do
            local roof = framework.net:InvokeServer({
                Type = 'PlaceRoof',
                Points = convertPoints(roofData.Points),
                Start = convertToVector3(roofData.Points[1]),
                Settings = {
                    IsPreview = true,
                    Type = roofData.Name,
                    RotateNum = 0
                }
            });

            for _, itemData in next, roofData.Items or {} do
                local item = framework.net:InvokeServer({
                    Type = 'PlaceObject',
                    Name = itemData.Name,
                    TargetModel = roof,
                    Rot = convertRot(itemData.Rot),
                    Pos = convertToVector3(itemData.Position),
                });

                framework.net:InvokeServer({
                    Type = 'ColorObject',
                    Object = item,
                    UseMaterials = true,
                    Data = itemData.AppearanceData
                })
            end;

            framework.net:InvokeServer({
                Type = 'ColorObject',
                Object = roof,
                UseMaterials = true,
                Data = roofData.AppearanceData
            })
        end;

        for _, poolData in next, houseData.Pools do
            framework.net:InvokeServer({
                Type = 'PlacePool',
                Size = Vector2.new(unpack(poolData.Size:split(','))),
                Center = CFrame.new(unpack(poolData.Position:split(','))),
                ItemType = poolData.Type
            });
            count = count + 1;
        end;

        for _, basementData in next, houseData.Basements do
            framework.net:InvokeServer({
                Type = 'PlaceBasement',
                ItemType = 'Basements',
                Size = Vector2.new(unpack(basementData.Size:split(','))),
                Center = CFrame.new(unpack(basementData.Position:split(','))) - Vector3.new(0, -12.49, 0)
            });
        end;

        for _, fenceData in next, houseData.Fences do
            local fence = framework.net:InvokeServer({
                Type = 'PlaceObject',
                Name = fenceData.Name,
                StartPos = convertToVector3(fenceData.From),
                Pos = convertToVector3(fenceData.To),
                ItemType = fenceData.Name
            })

            for _, itemData in next, fenceData.Items do
                local item = framework.net:InvokeServer({
                    Type = 'PlaceObject',
                    Name = itemData.Name,
                    TargetModel = fence,
                    Rot = convertRot(itemData.Rot),
                    Pos = convertToVector3(itemData.Position),
                });

                framework.net:InvokeServer({
                    Type = 'ColorObject',
                    Object = item,
                    UseMaterials = true,
                    Data = itemData.AppearanceData
                })
            end;

            framework.net:InvokeServer({
                Type = 'ColorObject',
                Object = fence,
                UseMaterials = true,
                Data = fenceData.AppearanceData
            })
        end;

        for _, groundItem in next, houseData.Ground.Objects do
            local item = framework.net:InvokeServer({
                Type = 'PlaceObject',
                Name = groundItem.Name,
                TargetModel = myPlot.GroundParts.Ground,
                Rot = convertRot(groundItem.Rot),
                Pos = convertToVector3(groundItem.Position),
            })

            if(groundItem.Fences and item) then
                for _, fenceData in next, groundItem.Fences do
                    local fence = framework.net:InvokeServer({
                        Type = 'PlaceObject',
                        Name = fenceData.Name,
                        Pos = convertToVector3(fenceData.From),
                        RailingSegment = item.ObjectModel.Railings[fenceData.Segment]
                    })

                    framework.net:InvokeServer({
                        Type = 'ColorObject',
                        Object = fence,
                        UseMaterials = true,
                        Data = fenceData.AppearanceData
                    })
                end;
            end;

            if(groundItem.Items) then
                for _, itemData2 in next, groundItem.Items do
                    local item2 = framework.net:InvokeServer({
                        Type = 'PlaceObject',
                        Name = itemData2.Name,
                        TargetModel = item,
                        Rot = convertRot(itemData2.Rot),
                        Pos = convertToVector3(itemData2.Position),
                    });

                    framework.net:InvokeServer({
                        Type = 'ColorObject',
                        Object = item2,
                        UseMaterials = true,
                        Data = itemData2.AppearanceData
                    })
                end;
            end;

            framework.net:InvokeServer({
                Type = 'ColorObject',
                Object = item,
                UseMaterials = true,
                Data = groundItem.AppearanceData
            })
        end;

        for _, counterItem in next, houseData.Ground.Counters do
            local item = framework.net:InvokeServer({
                Type = 'PlaceObject',
                Name = counterItem.Name,
                Pos = convertToVector3(counterItem.Position),
                Rot = convertRot(counterItem.Rot),
                TargetModel = myPlot.GroundParts.Ground,
            })

            if(counterItem.Items) then
                for _, itemData in next, counterItem.Items do
                    local item2 = framework.net:InvokeServer({
                        Type = 'PlaceObject',
                        Name = itemData.Name,
                        TargetModel = item,
                        Rot = convertRot(itemData.Rot),
                        Pos = convertToVector3(itemData.Position),
                    });

                    framework.net:InvokeServer({
                        Type = 'ColorObject',
                        Object = item2,
                        UseMaterials = true,
                        Data = itemData.AppearanceData
                    })
                end;
            end;

            framework.net:InvokeServer({
                Type = 'ColorObject',
                Object = item,
                UseMaterials = true,
                Data = counterItem.AppearanceData
            })
        end;

        framework.net:FireServer({
            Type = 'ExitBuild'
        });
    end;

    do -- // Remote Spy
        local oldFireServer = network.FireServer;
        local blacklistedTypes = {'LookDir', 'GetServerTime', 'CheckOwnsAsset', 'VehicleUpdate'};

        oldFireServer = hookfunction(network.FireServer, function(self, data, ...)
            if (data.Type == 'EndShift' and library.flags.pizzaDelivery) then return end;

            if (not table.find(blacklistedTypes, data.Type)) then
                print(prettyPrint({
                    data = data,
                    traceback = debug.traceback()
                }));
            end;

            return pcall(oldFireServer, self, data, ...);
        end);

        local oldInvokeServer = network.InvokeServer;
        oldInvokeServer = hookfunction(network.InvokeServer, function(self, data, ...)
            local fireType = data.Type;
            local returnData = {select(2, pcall(oldInvokeServer, self, data, ...))};

            if (not table.find(blacklistedTypes, fireType)) then
                print(prettyPrint({
                    returnData = returnData,
                    data = data,
                    type = fireType,
                    traceback = debug.traceback()
                }))
            end;


            return unpack(returnData);
        end);
    end;

    local function findCurrentWorkstation(workStations, justFindIt)
        local closestDistance, currentWorkstation = math.huge, nil;
        local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;

        if(not rootPart) then
            return
        end;

        for i, v in next, workStations:GetChildren() do
            local distance = (rootPart.Position - v.PrimaryPart.Position).Magnitude;

            if(distance <= closestDistance and (v.InUse.Value == nil or v.InUse.Value == LocalPlayer)) then
                closestDistance, currentWorkstation = distance, v;
            end;
        end;

        return currentWorkstation;
    end;

    local function findCurrentWorkstationBens(workStations)
        for i,v in next, workStations:GetChildren() do
            local customer = v.Occupied.Value;
            if(customer and customer.Order.Value == '') then
                return v;
            end;
        end;
    end

    local function tweenTeleport(position)
        local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
        if(not rootPart) then
            return warn('no root part for tween tp :/');
        end;


        local path = PathfindingService:CreatePath();
        path:ComputeAsync(rootPart.Position, position);

        local waypoints = path:GetWaypoints();
        local cfValue = Instance.new('CFrameValue');
        local connection;

        cfValue.Value = rootPart.CFrame;

        connection = cfValue:GetPropertyChangedSignal('Value'):Connect(function()
            LocalPlayer.Character:SetPrimaryPartCFrame(cfValue.Value);
        end);

        for i, v in next, waypoints do
            local tweenInfo = TweenInfo.new((rootPart.Position - v.Position).Magnitude / 20, Enum.EasingStyle.Linear);
            local tween = TweenService:Create(cfValue, tweenInfo, {Value = CFrame.new(v.Position + Vector3.new(0, 4, 0))});

            tween:Play();
            tween.Completed:Wait();
        end

        connection:Disconnect();
        connection = nil;

        cfValue:Destroy();
        cfValue = nil;

        path.Blocked:Connect(function()
            warn('BLOCKED IN PATH!');
        end);
    end;

    local function getOrder()
        local box = workspace.Environment.Locations.PizzaPlanet.Conveyor.MovingBoxes:WaitForChild('Box_1');
        local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
        if(not rootPart) then
            return print('No root part :/');
        end;

        if((box.Position - rootPart.Position).Magnitude <= 8) then
            local order = framework.net:InvokeServer({
                Type = "TakePizzaBox",
                Box = box
            });

            if(order) then
                return order;
            else
                return getOrder();
            end;
        else
            print('tween teleport');
            tweenTeleport(Vector3.new(1171.3407, 13.6576843, 273.778717));
            return getOrder();
        end;
    end;

    function copyPlayerHousePrompt(targetPlayer)
        task.wait();
        if(not guiHandler:ConfirmBox(string.format('\nThis will copy the house of %s into your executor workspace folder with the name Bloxburg_House.json.\nIf you want to copy this house simply press Yes (Make sure you can see the house you want to copy or use the teleport to player plot otherwise save house won\'t work properly)\n', targetPlayer.Name, targetPlayer.Name), 'House Copier')) then
            return;
        end;

        saveHouse(targetPlayer);
        return guiHandler:MessageBox(string.format('House of %s has been copied', targetPlayer.Name), 'Success')
    end;

    function loadPlayerHousePrompt(house)
        task.wait();
        local success, houseData = pcall(readfile, string.format('Aztup Hub V3/Bloxburg Houses/%s', house));
        if(not success) then
            return guiHandler:AlertBox('There was an error.','Error');
        end;

        houseData = HttpService:JSONDecode(houseData);
        local bsValue = houseData.bsValue;
        local totalValue = houseData.totalValue - (bsValue * 20);

        if(not guiHandler:ConfirmBox(string.format('\nAre you sure? You are about to load an house.\nMoney Required: %s\nBloxBux Required: %s\nIf you clicked on this button by mistake simply press No.\n', totalValue, bsValue), 'House Loader', 5)) then
            return;
        end;

        loadHouse(houseData);
    end

    local oldNamecall;

    oldNamecall = hookmetamethod(game, '__namecall', function(...)
        SX_VM_CNONE();
        local args = {...};
        local self = args[1];

        if(typeof(self) ~= 'Instance') then return oldNamecall(...) end;

        if (checkcaller() and getnamecallmethod() == 'FireServer' and args[2].Order and args[2].Workstation) then
            if (args[2].Workstation.Parent.Name == 'HairdresserWorkstations' and library.flags.stylezHairDresser) then
                args[2].Order = {
                    args[2].Workstation.Occupied.Value.Order.Style.Value,
                    args[2].Workstation.Occupied.Value.Order.Color.Value
                }
            elseif (args[2].Workstation.Parent.Name == 'CashierWorkstations' and library.flags.bloxyBurgers) then
                args[2].Order = {
                    args[2].Workstation.Occupied.Value.Order.Burger.Value,
                    args[2].Workstation.Occupied.Value.Order.Fries.Value,
                    args[2].Workstation.Occupied.Value.Order.Cola.Value
                }
            elseif (args[2].Workstation.Parent.Name == 'BakerWorkstations' and library.flags.pizzaBaker) then
                args[2].Order = {
                    true,
                    true,
                    true,
                    args[2].Workstation.Order.Value
                };
            end;
        end;

        return oldNamecall(unpack(args));
    end);

    function stylezHairDresser(toggle)
        if(not toggle) then
            return;
        end;

       repeat
            if(jobManager:GetJob() == 'StylezHairdresser') then
                local workstation = findCurrentWorkstation(workspace.Environment.Locations.StylezHairStudio.HairdresserWorkstations);
                if(workstation) then
                    if workstation.Mirror:FindFirstChild("HairdresserGUI") then
                        workstation.Mirror.HairdresserGUI.Overlay:FindFirstChild("false").ImageRectOffset = Vector2.new(0, 0)
                        workstation.Mirror.HairdresserGUI.Overlay:FindFirstChild("false").ImageColor3 = Color3.new(0, 255, 0)

                        for i, v in next, getconnections(workstation.Mirror.HairdresserGUI.Frame.Done.Activated) do
                            v.Function();
                        end

                        task.wait(1)
                    end
                end;
            end;
            Heartbeat:Wait();
       until not library.flags.stylezHairDresser;
    end;

    local function GetBurgerWorkstations()
        if workspace.Environment.Locations:FindFirstChild("BloxyBurgers") then
            local stations = {}
            for i, v in next, workspace.Environment.Locations.BloxyBurgers.CashierWorkstations:GetChildren() do
                if v.InUse.Value == LocalPlayer and v.Occupied.Value ~= nil then
                    table.insert(stations, v)
                end
                if v.InUse.Value == nil and v.Occupied.Value ~= nil then
                    table.insert(stations, v)
                end
            end
            return stations
        end
    end;

    function bloxyBurgers(toggle)
       repeat
            if(jobManager:GetJob() == 'BloxyBurgersCashier') then
                for i,workstation in next, GetBurgerWorkstations() do
                    if(workstation) then
                        if workstation.OrderDisplay.DisplayMain:FindFirstChild("CashierGUI") then
                            workstation.OrderDisplay.DisplayMain.CashierGUI.Overlay:FindFirstChild("false").ImageRectOffset = Vector2.new(0, 0)
                            workstation.OrderDisplay.DisplayMain.CashierGUI.Overlay:FindFirstChild("false").ImageColor3 = Color3.new(0, 255, 0)
                            for i, v in next, getconnections(workstation.OrderDisplay.DisplayMain.CashierGUI.Frame.Done.Activated) do
                                v.Function();
                            end

                            task.wait(1)
                        end
                    end;
                end
            end;
            Heartbeat:Wait();
       until not library.flags.bloxyBurgers;
    end;

    function FindClosestCrate()
        local closestBlock
        local closestDistance = math.huge

        for i, v in next, workspace.Environment.Locations.Supermarket.Crates:GetChildren() do
            if LocalPlayer:DistanceFromCharacter(v.Position) < closestDistance and v.Name == "Crate" then
                closestDistance = LocalPlayer:DistanceFromCharacter(v.Position)
                closestBlock = v
            end
        end
        if closestBlock == nil then
            task.wait(0.5)
            --FindClosest("Crate")
        end

        return closestBlock
    end

    function FindClosestEmptyShelf()
        local closestBlock
        local closestDistance = math.huge

        for i, v in next, workspace.Environment.Locations.Supermarket.Shelves:GetChildren() do
            if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position) < closestDistance and v.IsEmpty.Value == true then
                closestDistance = LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position)
                closestBlock = v
            end
        end

        if closestBlock == nil then
            task.wait(0.5)
            --FindClosest("EmptyShelf")
        end

        return closestBlock
    end

    local GoToShelf, TakeCrate

    GoToShelf = function()
        if jobManager:GetJob() == "SupermarketStocker" and library.flags.supermarketStocker then
            local shelf = FindClosestEmptyShelf()
            local gotopart = shelf:FindFirstChild("Part")
            tweenTeleport(gotopart.Position)
            network:FireServer({
                Type = "RestockShelf",
                Shelf = shelf
            })
            TakeCrate()
        end
    end;

    TakeCrate = function()
        if jobManager:GetJob() == "SupermarketStocker" and library.flags.supermarketStocker then
            local Crate = FindClosestCrate()
            tweenTeleport(Crate.Position)
            network:FireServer({
                Type = "TakeFoodCrate",
                Object = Crate
            })
            GoToShelf()
        end
    end

    function Stocker(toggle)
        if not toggle then return end

        spawn(function()
            repeat
                if library.flags.supermarketStocker and jobManager:GetJob() == "SupermarketStocker" then
                    LocalPlayer.Character.Humanoid:ChangeState(11)
                end

                Heartbeat:Wait()
            until not library.flags.supermarketStocker
        end)

        if jobManager:GetJob() == "SupermarketStocker" and library.flags.supermarketStocker then
            TakeCrate()
        end
    end

    local function Fish()
        repeat
            task.wait()
        until LocalPlayer.Character:FindFirstChild("Fishing Rod") and jobManager:GetJob() == "HutFisherman"
        local start_time = tick()
        network:FireServer({
            Type = "UseFishingRod",
            State = true;
            Pos = LocalPlayer.Character:FindFirstChild("Fishing Rod").Line.Position
        })

        task.wait(2)

        if LocalPlayer.Character:FindFirstChild("Fishing Rod") then

            local originalBobberPosition = LocalPlayer.Character["Fishing Rod"].Bobber.Position.Y
            if LocalPlayer.Character:FindFirstChild("Fishing Rod") then
                local con

                con = LocalPlayer.Character["Fishing Rod"].Bobber:GetPropertyChangedSignal("Position"):Connect(function()
                    if LocalPlayer.Character:FindFirstChild("Fishing Rod") then
                        if originalBobberPosition - LocalPlayer.Character["Fishing Rod"].Bobber.Position.Y < 3 then
                            local time_elapsed = tick() - start_time
                            network:FireServer({
                                Type = "UseFishingRod",
                                State = false,
                                Time = time_elapsed
                            })

                            con:Disconnect()

                            if library.flags.fisherman then
                                Fish()
                            end
                        end
                    end
                end)
            end
        end
    end

    function fisherMan(toggle)
        if(not toggle) then
            return;
        end;

        Fish()
    end

    function pizzaBaker(toggle)
        if(not toggle) then
            return;
        end;

       repeat
            if(jobManager:GetJob() == 'PizzaPlanetBaker') then
                local workstation = findCurrentWorkstation(workspace.Environment.Locations.PizzaPlanet.BakerWorkstations);
                if(workstation) then
                    local order = workstation.Order;
                    local oldPosition = LocalPlayer.Character.PrimaryPart.Position;

                    if(order.IngredientsLeft.Value == 0) then
                        local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;

                        rootPart.CFrame =  CFrame.new(1167.14685, 13.6576815, 255.879852);

                        task.wait(0.5);

                        network:FireServer({
                            Type = "TakeIngredientCrate",
                            Object = workspace.Environment.Locations.PizzaPlanet.IngredientCrates.Crate
                        })

                        task.wait(0.5);

                        network:FireServer({
                            Type = "TakeIngredientCrate",
                            Object = workspace.Environment.Locations.PizzaPlanet.IngredientCrates.Crate
                        })

                        rootPart.CFrame = CFrame.new(oldPosition);

                        task.wait(0.5);

                        network:FireServer({
                            Type = "RestockIngredients",
                            Workstation = workstation
                        })
                    elseif(order.Value ~= 'true') then
                        if workstation:FindFirstChild("OrderDisplay") and workstation.OrderDisplay:FindFirstChild("DisplayMain") and workstation.OrderDisplay.DisplayMain:FindFirstChild("BakerGUI") then
                            workstation.OrderDisplay.DisplayMain.BakerGUI.Overlay:FindFirstChild("false").ImageRectOffset = Vector2.new(0, 0)
                            workstation.OrderDisplay.DisplayMain.BakerGUI.Overlay:FindFirstChild("false").ImageColor3 = Color3.new(0, 255, 0)
                            for i, v in next, getconnections(workstation.OrderDisplay.DisplayMain.BakerGUI.Frame.Done.Activated) do
                                v.Function();
                            end
                        end
                    end;

                    task.wait(1);
                end;
            end;
            Heartbeat:Wait();
       until not library.flags.pizzaBaker;
    end;

    local function DeliveryMovement(character, cf)
        local cfValue = Instance.new('CFrameValue');
        local distance = (character:GetPivot().Position - cf.Position).Magnitude;
        local speed = 35;

        local tween = TweenService:Create(cfValue, TweenInfo.new(distance / speed, Enum.EasingStyle.Linear), {Value = CFrame.new(cf.Position)});
        cfValue.Value = CFrame.new(character.PrimaryPart.Position);

        local maid = Maid.new();

        maid:GiveTask(tween);
        maid:GiveTask(cfValue);
        maid:GiveTask(RunService.Heartbeat:Connect(function()
            character:PivotTo(cfValue.Value);
        end));

        tween:Play();
        tween.Completed:Wait();

        return maid;
    end

    local GroceryCashierFunctions = {
        BagAmount = function(station)
            local amount = 0
            for i, v in next, station.Bags:GetChildren() do
                if v.Transparency == 0 then
                    amount = amount + 1
                end
            end
            return amount
        end;
        RestockBags = function(stat)
            local Crate = workspace.Environment.Locations.Supermarket.Crates:FindFirstChild("BagCrate")
            tweenTeleport(Crate.Position + Vector3.new(5, 0, -5), 12)
            network:FireServer({
                Type = "TakeNewBags",
                Object = Crate
            })
            repeat
                task.wait()
            until LocalPlayer.Character:FindFirstChild("BFF Bags")
            tweenTeleport(stat.Scanner.Position - Vector3.new(3, 0, 0), 12)
            network:FireServer({
                Type = "RestockBags",
                Workstation = stat
            })
            repeat
                task.wait()
            until stat.BagsLeft.Value > 0
        end;
        GetFreeCashierStation = function()
            if workspace.Environment.Locations:FindFirstChild("Supermarket") then
                local Station
                local EmptyStations = {}
                for i, v in next, workspace.Environment.Locations.Supermarket.CashierWorkstations:GetChildren() do
                    if v:FindFirstChild("InUse") and v.InUse.Value == LocalPlayer then
                        Station = v
                    end
                end
                for i, v in next, workspace.Environment.Locations.Supermarket.CashierWorkstations:GetChildren() do
                    if v:FindFirstChild("InUse") and v.InUse.Value == nil then
                        table.insert(EmptyStations, v)
                    end
                end
                if Station == nil and #EmptyStations > 0 then
                    local closest = nil
                    local distance = math.huge
                    for i, v in next, EmptyStations do
                        if LocalPlayer:DistanceFromCharacter(v.Scanner.Position) < distance then
                            distance = LocalPlayer:DistanceFromCharacter(v.Scanner.Position)
                            closest = v
                        end
                    end
                    Station = closest
                end
                if Station == nil then
                    task.wait()
                    --GetFreeCashierStation()
                end
                return Station
            end
        end
    }

    function NextCustomer()
        if jobManager:GetJob() == "SupermarketCashier" and library.flags.supermarketCashier then
            local Station = GroceryCashierFunctions.GetFreeCashierStation()
            count = 0
            CurrentBags = 1
            if Station.BagsLeft.Value == 0 then
                GroceryCashierFunctions.RestockBags(Station)
            end
            repeat
                for i, v in next, Station.DroppedFood:GetChildren() do
                    count = count + 1
                    if count / CurrentBags == 3 then
                        network:FireServer({
                            Type = "TakeNewBag",
                            Workstation = Station
                        })
                        CurrentBags = CurrentBags + 1
                        if Station.BagsLeft.Value == 0 then
                            GroceryCashierFunctions.RestockBags(Station)
                            task.wait()
                        end
                    end
                    network:FireServer({
                        Type = "ScanDroppedItem",
                        Item = v
                    })
                    task.wait(0.1)
                end
                task.wait()
            until jobManager:GetJob() ~= "SupermarketCashier" or Station.Occupied.Value ~= nil and (Station.Occupied.Value.Head.Position - Station.CustomerTarget_2.Position).magnitude < 3
            network:FireServer({
                Type = "JobCompleted",
                Workstation = Station
            })
            NextCustomer()
        end
    end

    function supermarketCashier(toggle)
        if not toggle then return end

        repeat task.wait() until jobManager:GetJob() == "SupermarketCashier"

        if library.flags.supermarketCashier then
            NextCustomer()
        end
    end

    local interactionHandler = framework.Modules.InteractionHandler;
    local interactionsDatas = getupvalue(interactionHandler.AddInteraction, 2);

    function pizzaDelivery(toggle)
        if(not toggle) then
            if(LocalPlayer.Character.PrimaryPart:FindFirstChild('funny')) then
                LocalPlayer.Character.PrimaryPart.funny:Destroy();
            end;
            return;
        end;

        local hasVehicle = false;

        repeat
            task.wait();

            if(jobManager:GetJob() ~= 'PizzaPlanetDelivery') then
                continue;
            end;

            if(not LocalPlayer.Character.PrimaryPart:FindFirstChild('funny')) then
                local bodyVelocity = Instance.new('BodyVelocity');
                bodyVelocity.Name = 'funny';

                bodyVelocity.Velocity = Vector3.new(0, 0, 0);
                bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
                bodyVelocity.Parent = LocalPlayer.Character.PrimaryPart;
            end;

            local vehicle, customer;

            if (not hasVehicle) then
                repeat
                    for object, interactionData in next, interactionsDatas do
                        if (object.Name == 'DeliveryMoped') then
                            select(3, interactionData[1][1]())();
                            break;
                        end;
                    end;

                    task.wait(0.5);
                    vehicle = LocalPlayer.Character:FindFirstChild('Vehicle_Delivery Moped');
                until vehicle;
            end;

            -- hasVehicle = true;

            repeat
                task.wait(0.1);
                LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(1170, 14, 275));

                local box = workspace.Environment.Locations:WaitForChild('PizzaPlanet'):WaitForChild('Conveyor'):WaitForChild('MovingBoxes'):FindFirstChildOfClass('UnionOperation');
                if (not box) then continue end;

                customer = network:InvokeServer({
                    Type = 'TakePizzaBox';
                    Box = box
                });
            until customer;

            LocalPlayer.Character:SetPrimaryPartCFrame(CFrame.new(1170, -50, 275));
            task.wait(0.5);

            local maid = DeliveryMovement(LocalPlayer.Character, customer.PrimaryPart.CFrame * CFrame.new(0, -10, 0));
            task.wait(0.5);

            network:FireServer({
                Type = "DeliverPizza",
                Customer = customer
            });

            repeat
                task.wait();
            until not LocalPlayer.Character:FindFirstChild('Pizza Box');

            task.wait(0.5);

            maid:Destroy();
            maid = nil;

            task.wait();
        until not library.flags.pizzaDelivery;
    end;

    local function GetClosestTree()
        local closestDistance = math.huge
        local closestBlock

        for i, v in next, workspace.Environment.Trees:GetChildren() do
            if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position) < closestDistance and v.PrimaryPart.Position.Y > 5 then
                closestDistance = LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position)
                closestBlock = v
            end
        end

        return closestBlock
    end

    function lumber(toggle)
        if not toggle then
            return
        end

        spawn(function()
            repeat
                if library.flags.lumber and jobManager:GetJob() == "LumberWoodcutter" then
                    LocalPlayer.Character.Humanoid:ChangeState(11)
                end

                Heartbeat:Wait()
            until not library.flags.lumber
        end)

        repeat
            if jobManager:GetJob() == "LumberWoodcutter" then
                local Tree = GetClosestTree()

                if Tree then
                    local tweenInfo = TweenInfo.new((LocalPlayer.Character.HumanoidRootPart.Position - Tree.PrimaryPart.Position).Magnitude / 45, Enum.EasingStyle.Linear);
                    local tween = TweenService:Create(LocalPlayer.Character.HumanoidRootPart, tweenInfo, {CFrame = Tree.PrimaryPart.CFrame});

                    tween:Play();
                    tween.Completed:Wait();

                    repeat
                        network:FireServer({
                            Type = "UseHatchet",
                            Tree = Tree
                        })

                        task.wait()
                    until (Tree.PrimaryPart.Position.Y < 0) or (jobManager:GetJob() ~= "LumberWoodcutter") or (library.flags.lumber == false)
                end
            end

            Heartbeat:Wait()
        until not library.flags.lumber
    end

    local ColorsValue = {
        "Dark stone grey";
        "Dark orange";
        "Deep orange";
        "Lime green";
        "Royal purple";
    }

    local function FindClosestStone()
        local closestDistance = math.huge
        local closestBlock
        local closestY = math.huge

        for i, v in next, workspace.Environment.Locations.Static_MinerCave.Folder:GetChildren() do
            if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position) < closestDistance and v.PrimaryPart.Position.Y < closestY then
                if (not v:FindFirstChild("B")) or (v:FindFirstChild("B").BrickColor.Name ~= "Bright red") then
                    closestDistance = LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position)
                    closestBlock = v
                    closestY = v.PrimaryPart.Position.Y
                end
            end
        end

        return closestBlock
    end

    local function FindClosestOre()
        local closestDistance = math.huge
        local closestBlock

        local bestColor = "Dark stone grey"
        for i, v in next, workspace.Environment.Locations.Static_MinerCave.Folder:GetChildren() do
            if v:FindFirstChild("M") then
                if table.find(ColorsValue, bestColor) < table.find(ColorsValue, v:FindFirstChild("M").BrickColor.Name) then
                    closestBlock = v
                    bestColor = v:FindFirstChild("M").BrickColor.Name
                elseif table.find(ColorsValue, bestColor) == table.find(ColorsValue, v:FindFirstChild("M").BrickColor.Name) then
                    if LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position) < closestDistance then
                        closestDistance = LocalPlayer:DistanceFromCharacter(v.PrimaryPart.Position)
                        closestBlock = v
                    end
                end
            end
        end

        if closestBlock == nil then
            closestBlock = FindClosestStone()
        end

        return closestBlock
    end

    function miner(toggle)
        if not toggle then
            if LocalPlayer.Character.HumanoidRootPart:FindFirstChildOfClass("BodyVelocity") then
                LocalPlayer.Character.HumanoidRootPart:FindFirstChildOfClass("BodyVelocity"):Destroy()
            end

            return
        end

        local bv = Instance.new("BodyVelocity", LocalPlayer.Character.HumanoidRootPart)
        bv.Velocity = Vector3.new(0, 0, 0)

        spawn(function()
            repeat
                if library.flags.miner then
                    LocalPlayer.Character.Humanoid:ChangeState(11)
                end

                Heartbeat:Wait()
            until not library.flags.miner
        end)

        repeat
            if library.flags.miner and jobManager:GetJob() == "CaveMiner" and workspace.Environment.Locations:FindFirstChild("Static_MinerCave") then
                local TargetBlock = FindClosestOre()

                TargetBlock.PrimaryPart.CanCollide = false
                if TargetBlock then
                    tweenTeleport(TargetBlock.PrimaryPart.Position, 20)

                    local TargetX, TargetY, TargetZ = string.match(TargetBlock.Name, "(.+):(.+):(.+)")
                    local TargetVector = Vector3.new(TargetX, TargetY, TargetZ)

                    network:InvokeServer({
                        Type = "MineBlock",
                        P = TargetVector
                    })
                end
            end
        until not library.flags.miner
    end

    function bensIceCream(toggle)
        if(not toggle) then
            return;
        end;

        repeat
            local workstation = findCurrentWorkstationBens(workspace.Environment.Locations.BensIceCream.CustomerTargets);
            if(jobManager:GetJob() == 'BensIceCreamSeller' and workstation) then
                local customer = workstation.Occupied.Value;
                local iceCup;

                
                repeat
                    framework.net:FireServer({
                        Type = 'TakeIceCreamCup'
                    })

                    iceCup = framework.Shared.EquipmentService:GetEquipped(LocalPlayer);
                    task.wait();
                until iceCup or not library.flags.bensIceCream;

                if(not library.flags.bensIceCream) then
                    return;
                end;

                for x = 1, 2 do
                    framework.net:FireServer({
                        Type = 'AddIceCreamScoop',
                        Taste = customer.Order['Flavor' .. tostring(x)].Value,
                        Ball = iceCup:WaitForChild('Ball' .. tostring(x));
                    });
                    task.wait(0.1);
                end;

                if(customer.Order.Topping.Value ~= '') then
                    framework.net:FireServer({
                        Type = 'AddIceCreamTopping',
                        Taste = customer.Order.Topping.Value
                    });
                end;

                task.wait(0.1);

                framework.net:FireServer({
                    Type = "JobCompleted",
                    Workstation = workstation
                });
                task.wait(1);
            end;
            task.wait();
        until not library.flags.bensIceCream;
    end;

    local function GetMotorWorkstation()
        if workspace.Environment.Locations:FindFirstChild("MikesMotors") then
            local Station
            for i, v in next, workspace.Environment.Locations.MikesMotors.MechanicWorkstations:GetChildren() do
                if v:FindFirstChild("InUse") and v.InUse.Value == LocalPlayer then
                    Station = v
                end
            end
            for i, v in next, workspace.Environment.Locations.MikesMotors.MechanicWorkstations:GetChildren() do
                if v:FindFirstChild("InUse") and v:FindFirstChild("Occupied") and v.InUse.Value == nil and v.Occupied.Value ~= nil then
                    Station = v
                end
            end
            if Station == nil then
                task.wait()
                GetMotorWorkstation()
            end
            return Station
        end
    end;

    local WheelPos = {
        ["Bloxster"] = Vector3.new(1155.36475, 13.3524084, 411.294983),
        ["Classic"] = Vector3.new(1156, 13.3524084, 396.650177),
        ["Moped"] = Vector3.new(1154, 13, 402)
    }

    function mechanic(toggle)
        if(not toggle) then
            return;
        end;

        repeat
            if jobManager:GetJob() == "MikesMechanic" then
                local v = GetMotorWorkstation()
                if v then
                    local customer = v.Occupied.Value
                    if customer then
                        local Order = customer:WaitForChild("Order")
                        if Order:FindFirstChild("Oil") then
                            local Oil = Order.Oil.Value
                            if Oil ~= nil then
                                repeat
                                    tweenTeleport(Vector3.new(1194, 13, 389), 12)
                                    network:FireServer({
                                        Type = "TakeOil";
                                        Object = workspace.Environment.Locations.MikesMotors.OilCans:FindFirstChildWhichIsA("Model")
                                    })
                                    task.wait()
                                until LocalPlayer.Character:FindFirstChild("Oil Can") or not library.flags.mechanic
                                tweenTeleport(v.Display.Screen.Position + Vector3.new(0, 0, 5), 12)
                                network:FireServer({
                                    Type = "FixBike";
                                    Workstation = v
                                })
                                repeat
                                    task.wait()
                                until (not LocalPlayer.Character:FindFirstChild("Oil Can")) or not library.flags.mechanic
                                network:FireServer({
                                    Type = "JobCompleted";
                                    Workstation = v
                                })
                                task.wait(2)
                            end
                        elseif Order:FindFirstChild("Wheels") then
                            local WheelType = Order.Wheels.Value
                            for i = 1, 2 do
                                repeat
                                    tweenTeleport(WheelPos[WheelType], 12)
                                    network:FireServer({
                                        Type = "TakeWheel";
                                        Object = workspace.Environment.Locations.MikesMotors.TireRacks:FindFirstChild(WheelType)
                                    })
                                    task.wait()
                                until LocalPlayer.Character:FindFirstChild(WheelType.." Wheel") or not library.flags.mechanic
                                tweenTeleport(v.Display.Screen.Position + Vector3.new(0, 0, 5), 12)
                                if i == 1 then
                                    network:FireServer({
                                        Type = "FixBike";
                                        Workstation = v;
                                        Front = true
                                    })
                                elseif i == 2 then
                                    network:FireServer({
                                        Type = "FixBike";
                                        Workstation = v;
                                    })
                                end
                                repeat
                                    task.wait()
                                until (not LocalPlayer.Character:FindFirstChild(WheelType.." Wheel")) or not library.flags.mechanic
                                if i == 2 then
                                    network:FireServer({
                                        Type = "JobCompleted";
                                        Workstation = v
                                    })
                                end
                                task.wait(2)
                            end
                        elseif Order:FindFirstChild("Color") then
                            local ColorValue = Order.Color.Value
                            if ColorValue ~= nil then
                                repeat
                                    tweenTeleport(Vector3.new(1173, 13, 388), 12)
                                    network:FireServer({
                                        Type = "TakePainter";
                                        Object = workspace.Environment.Locations.MikesMotors.PaintingEquipment:FindFirstChild(ColorValue)
                                    })
                                    task.wait()
                                until LocalPlayer.Character:FindFirstChild("Spray Painter") or not library.flags.mechanic
                                tweenTeleport(v.Display.Screen.Position + Vector3.new(0, 0, 5), 12)
                                network:FireServer({
                                    Type = "FixBike";
                                    Workstation = v
                                })
                                repeat
                                    task.wait()
                                until (not LocalPlayer.Character:FindFirstChild("Spray Painter")) or not library.flags.mechanic
                                network:FireServer({
                                    Type = "JobCompleted";
                                    Workstation = v
                                })
                                task.wait(2)
                            end
                        end
                    end
                end
            end

            Heartbeat:Wait()
        until not library.flags.mechanic
    end

    local function FindClosestTrash()
        local closestDistance = math.huge
        local closestBlock

        for i, v in next, workspace.Environment.Locations.GreenClean.Spawns:GetChildren() do
            if LocalPlayer:DistanceFromCharacter(v.Position) < closestDistance and v:FindFirstChildWhichIsA("Decal", true) then
                closestDistance = LocalPlayer:DistanceFromCharacter(v.Position)
                closestBlock = v
            end
        end

        if closestBlock == nil then
            task.wait()
            FindClosestTrash()
        end

        return closestBlock
    end

    function janitor(toggle)
        if not toggle then
            return
        end

        spawn(function()
            repeat
                if library.flags.janitor then
                    LocalPlayer.Character.Humanoid:ChangeState(11)
                end

                Heartbeat:Wait()
            until not library.flags.janitor
        end)

        repeat
            if library.flags.janitor and jobManager:GetJob() == "CleanJanitor" then
                local Trash = FindClosestTrash()

                if Trash then
                    if Trash:FindFirstChild("Object") and Trash:FindFirstChild("Object"):IsA("Part") then
                        tweenTeleport(Trash.Object.Position)
                    else
                        tweenTeleport(Trash.Position)
                    end

                    network:InvokeServer({
                        Type = "CleanJanitorObject",
                        Spawn = Trash
                    })
                end
            end

            Heartbeat:Wait()
        until not library.flags.janitor
    end

    function teleportToPlayerPlot(targetPlayer)
        local position = framework.net:InvokeServer({
            Type = 'ToPlot',
            Player = targetPlayer;
        });

        LocalPlayer.Character:SetPrimaryPartCFrame(position);
    end;

    library.OnLoad:Connect(function()
        while true do
            local loadHouseList = library.options.loadHouse;
            local newList = listfiles('Aztup Hub V3\\Bloxburg Houses')

            for i, file in next, newList do
                file = file:match('Aztup Hub V3\\Bloxburg Houses\\(.+)');
                newList[i] = file;

                if (not table.find(loadHouseList.values, file)) then
                    loadHouseList:AddValue(file);
                end;
            end;

            for _, file in next, loadHouseList.values do
                if (not table.find(newList, file)) then
                    loadHouseList:RemoveValue(file);
                end;
            end;

            task.wait(1);
        end;
    end);
end;

local Autofarm = column1:AddSection('Auto Farm');
local Autobuild = column2:AddSection('Auto Build');
local Misc = column1:AddSection('Misc');

Autofarm:AddToggle({text = 'Pizza Delivery', callback = pizzaDelivery});
Autofarm:AddToggle({text = 'Bens Ice Cream', callback = bensIceCream});
Autofarm:AddToggle({text = 'Stylez Hair Dresser', callback = stylezHairDresser});
Autofarm:AddToggle({text = 'Bloxy Burgers', callback = bloxyBurgers});
Autofarm:AddToggle({text = 'Pizza Baker', callback = pizzaBaker});
Autofarm:AddToggle({text = "Fisherman", callback = fisherMan})
Autofarm:AddToggle({text = "Mechanic", callback = mechanic})
Autofarm:AddToggle({text = "Lumber", callback = lumber})
Autofarm:AddToggle({text = "Miner", callback = miner})
Autofarm:AddToggle({text = "Janitor", callback = janitor})
Autofarm:AddToggle({text = "Supermarket Cashier", callback = supermarketCashier})
Autofarm:AddToggle({text = "Supermarket Stocker", callback = Stocker})
Autobuild:AddList({text = 'Copy House', skipflag = true, noload = true, playerOnly = true, callback = copyPlayerHousePrompt});
Autobuild:AddList({text = 'Load House', flag = 'Load House', skipflag = true, noload = true, values = {}, callback = loadPlayerHousePrompt});

Misc:AddList({text = 'Teleport To Player Plot', skipflag = true, noload = true, playerOnly = true, callback = teleportToPlayerPlot});