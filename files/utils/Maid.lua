SX_VM_CNONE();
---	Manages the cleaning of events and other things.
-- Useful for encapsulating state and make deconstructors easy
-- @classmod Maid
-- @see Signal

local Signal = sharedRequire('./Signal.lua');
local tableStr = getServerConstant('table');
local classNameStr = getServerConstant('Maid');
local funcStr = getServerConstant('function');
local threadStr = getServerConstant('thread');

local Maid = {}
Maid.ClassName = "Maid"

--- Returns a new Maid object
-- @constructor Maid.new()
-- @treturn Maid
function Maid.new()
	return setmetatable({
		_tasks = {}
	}, Maid)
end

function Maid.isMaid(value)
	return type(value) == tableStr and value.ClassName == classNameStr
end

--- Returns Maid[key] if not part of Maid metatable
-- @return Maid[key] value
function Maid.__index(self, index)
	if Maid[index] then
		return Maid[index]
	else
		return self._tasks[index]
	end
end

--- Add a task to clean up. Tasks given to a maid will be cleaned when
--  maid[index] is set to a different value.
-- @usage
-- Maid[key] = (function)         Adds a task to perform
-- Maid[key] = (event connection) Manages an event connection
-- Maid[key] = (Maid)             Maids can act as an event connection, allowing a Maid to have other maids to clean up.
-- Maid[key] = (Object)           Maids can cleanup objects with a `Destroy` method
-- Maid[key] = nil                Removes a named task. If the task is an event, it is disconnected. If it is an object,
--                                it is destroyed.
function Maid:__newindex(index, newTask)
	if Maid[index] ~= nil then
		error(("'%s' is reserved"):format(tostring(index)), 2)
	end

	local tasks = self._tasks
	local oldTask = tasks[index]

	if oldTask == newTask then
		return
	end

	tasks[index] = newTask

	if oldTask then
		if type(oldTask) == "function" then
			oldTask()
		elseif typeof(oldTask) == "RBXScriptConnection" then
			oldTask:Disconnect();
		elseif typeof(oldTask) == 'table' then
			oldTask:Remove();
		elseif (Signal.isSignal(oldTask)) then
			oldTask:Destroy();
		elseif (typeof(oldTask) == 'thread') then
			task.cancel(oldTask);
		elseif oldTask.Destroy then
			oldTask:Destroy();
		end
	end
end

--- Same as indexing, but uses an incremented number as a key.
-- @param task An item to clean
-- @treturn number taskId
function Maid:GiveTask(task)
	if not task then
		error("Task cannot be false or nil", 2)
	end

	local taskId = #self._tasks+1
	self[taskId] = task

	return taskId
end

--- Cleans up all tasks.
-- @alias Destroy
function Maid:DoCleaning()
	local tasks = self._tasks

	-- Disconnect all events first as we know this is safe
	for index, task in pairs(tasks) do
		if typeof(task) == "RBXScriptConnection" then
			tasks[index] = nil
			task:Disconnect()
		end
	end

	-- Clear out tasks table completely, even if clean up tasks add more tasks to the maid
	local index, taskData = next(tasks)
	while taskData ~= nil do
		tasks[index] = nil
		if type(taskData) == funcStr then
			taskData()
		elseif typeof(taskData) == "RBXScriptConnection" then
			taskData:Disconnect()
		elseif (Signal.isSignal(taskData)) then
			taskData:Destroy();
		elseif typeof(taskData) == tableStr then
			taskData:Remove();
		elseif (typeof(taskData) == threadStr) then
			task.cancel(taskData);
		elseif taskData.Destroy then
			taskData:Destroy()
		end
		index, taskData = next(tasks)
	end
end

--- Alias for DoCleaning()
-- @function Destroy
Maid.Destroy = Maid.DoCleaning

return Maid;