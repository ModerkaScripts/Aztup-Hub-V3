local Services = sharedRequire('../utils/Services.lua');
local ContextActionService, HttpService = Services:Get('ContextActionService', 'HttpService');

local ControlModule = {};

do
    ControlModule.__index = ControlModule

    function ControlModule.new()
        local self = {
            forwardValue = 0,
            backwardValue = 0,
            leftValue = 0,
            rightValue = 0
        }

        setmetatable(self, ControlModule)
        self:init()
        return self
    end

    function ControlModule:init()
        local handleMoveForward = function(actionName, inputState, inputObject)
            self.forwardValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
            return Enum.ContextActionResult.Pass
        end

        local handleMoveBackward = function(actionName, inputState, inputObject)
            self.backwardValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
            return Enum.ContextActionResult.Pass
        end

        local handleMoveLeft = function(actionName, inputState, inputObject)
            self.leftValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
            return Enum.ContextActionResult.Pass
        end

        local handleMoveRight = function(actionName, inputState, inputObject)
            self.rightValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
            return Enum.ContextActionResult.Pass
        end

        ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveForward, false, Enum.KeyCode.W);
        ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveBackward, false, Enum.KeyCode.S);
        ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveLeft, false, Enum.KeyCode.A);
        ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveRight, false, Enum.KeyCode.D);
    end

    function ControlModule:GetMoveVector()
        return Vector3.new(self.leftValue + self.rightValue, 0, self.forwardValue + self.backwardValue)
    end
end

return ControlModule.new();