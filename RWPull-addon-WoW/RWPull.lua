if SetTimer then return end

local timers = {}

function SetTimer(interval, callback, recur, ...)
   local timer = {
      interval = interval,
      callback = callback,
      recur = recur,
      update = 0,
      args = {...}
   }
   timers[timer] = timer
   return timer
end

function KillTimer(timer)
   timers[timer] = nil
end

-- How often to check timers. Lower values are more CPU intensive.
local granularity = 0.1

local totalElapsed = 0
local function OnUpdate(self, elapsed)
   totalElapsed = totalElapsed + elapsed
   if totalElapsed > granularity then
      for k, t in pairs(timers) do
         t.update = t.update + totalElapsed
         if t.update > t.interval then
            local success, rv = pcall(t.callback, unpack(t.args))
            if not rv and t.recur then
               t.update = 0
            else
               timers[t] = nil             
            end
         end
      end
      totalElapsed = 0
   end
end
CreateFrame('Frame'):SetScript('OnUpdate', OnUpdate)

local pullState = { count = 0, showMessage = false, isReseted = false }
local pizzaState = { count = 0, showMessage = false, isLastMinute = false }
local pullMessage = "Pull"  -- custom message 

local function print(...)
   _G.print('|cffffff00<RWP>:', ...)
end

local function pullCountdown(state)
   if state.count > 1 and not state.isReseted then
      SendChatMessage(pullMessage.. " in "  .. state.count - 1, "RAID_WARNING")
      state.count = state.count - 1
   elseif state.count == 1 then
      state.showMessage = true
   end
   
   if state.count <= 0 then
      print('Timer aborted')
      return true
   end
   
   if state.count > 1 and state.isReseted then
      SendChatMessage("{rt7} Pull Aborted!! {rt7}", "RAID_WARNING")
      state.count = 0
      state.isReseted = false
      return true  -- abort recurring timer
   end
   
   if state.showMessage and not state.isReseted then
      SendChatMessage(pullMessage.. " now!!", "RAID_WARNING")
      state.count = 0
      state.showMessage = false
      return true -- abort recurring timer
   end
end

local function pizzaCountdown(state)
   state.count = state.count - 1
   if state.count > 0 then
      local message = "Break ends in " .. state.count .. " minutes!"
      if state.count == 1 then
         message = "Break ends in 1 minute!"
      end
      SendChatMessage(message, "RAID_WARNING")
   end
   
   if state.count == 0 and not state.showMessage then
      SendChatMessage("Break ended!! ", "RAID_WARNING")
      state.count = 0
      state.showMessage = true
   end
   
   if state.showMessage then
      state.showMessage = false
      return true -- abort recurring timer
   end
end

SlashCmdList["RWC"] = function()
   if pullState.count >= 0 then
      pullState.isReseted = true   
   else
      print('No active timer to execute this command')
   end
end

SlashCmdList["RWP_PULL"] = function(msg, editBox)
   local pullTime = tonumber(msg) or 15   
   pullState.isReseted = false
   if pullState.count > 0 then
      pullState.count = pullTime
      SendChatMessage("New pull timer: " .. pullTime .. " seconds.", "RAID_WARNING")
   else
      pullState.count = pullTime
      if pullTime <= 0 then
         print('Please input a number greater than 0')
      else
         SendChatMessage("Pull countdown initiated: " .. pullTime .. " seconds", "RAID_WARNING")
         SetTimer(1, pullCountdown, true, pullState)
      end
   end
end

SlashCmdList["RWP_PIZZA"] = function(msg, editBox)
   local pizzaTime = tonumber(msg) or 5   
   if pizzaState.count > 0 then
      pizzaState.count = pizzaTime
      SendChatMessage("New break timer: " .. pizzaTime .. " minutes.", "RAID_WARNING")
   else
      pizzaState.count = pizzaTime
      if pizzaTime <= 0 then
         print('Please input a number greater than 0')
      else
         SendChatMessage("Break countdown initiated: " .. pizzaTime .. " minutes!", "RAID_WARNING")                     
      end
      SetTimer(60, pizzaCountdown, true, pizzaState)
   end   
end  

SlashCmdList["RWP_MSG"] = function(msg, editBox)
   pullMessage = msg
   print('New pull message set: ' .. pullMessage)
end

SlashCmdList["RWP_HELP"] = function(msg)
   print('usage: /rwpull <seconds> - Send a raid warning pull with X seconds, Default: 15')
   print('usage: /rwpizza <minutes> - Send a raid warning break with X minutes, Default: 5')
   print('usage: /rwpmsg <message> - Replaces the default pull message')
   print('usage: /rwc - Abort the current pull timer ')
end

SLASH_RWC1 = "/rwc"
SLASH_RWP_PULL1 = "/rwpull"
SLASH_RWP_PIZZA1 = "/rwpizza"
SLASH_RWP_MSG1 = "/rwpmsg"
SLASH_RWP_HELP1 = '/rwp'

print('loaded use /rwp for more info')
