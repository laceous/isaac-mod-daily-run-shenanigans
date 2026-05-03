local mod = RegisterMod('Daily Run Shenanigans', 1)
local game = Game()

if REPENTOGON then
  mod.controllerOverride = -1
  mod.controllers = {}
  mod.controllersMap = {}
  
  function mod:onModsLoaded()
    mod:setupImGui()
  end
  
  -- reset variables here rather than in MC_PRE_GAME_EXIT
  -- so we don't wipe out the controller override when holding R to restart
  function mod:onMainMenuRender()
    mod.controllerOverride = -1
  end
  
  function mod:onPlayerInit(player)
    if game:GetFrameCount() <= 0 and mod.controllerOverride > -1 then
      player:SetControllerIndex(mod.controllerOverride)
    end
  end
  
  function mod:fillControllers()
    mod.controllers = { 'Default' }
    mod.controllersMap = { -1 }
    
    for i = 0, 10000 do
      local name = Input.GetDeviceNameByIdx(i)
      if name == nil and i == 0 then
        name = 'Keyboard'
      end
      if name then
        table.insert(mod.controllers, i .. ' - ' .. name)
        table.insert(mod.controllersMap, i)
      end
    end
  end
  
  function mod:isValidDate(year, month, day)
    local t = os.time({ year = year, month = month, day = day })
    local d = os.date('*t', t)
    
    return d.year == year and d.month == month and d.day == day
  end
  
  function mod:setupImGuiMenu()
    if not ImGui.ElementExists('shenanigansMenu') then
      ImGui.CreateMenu('shenanigansMenu', '\u{f6d1} Shenanigans')
    end
  end
  
  function mod:setupImGui()
    ImGui.AddElement('shenanigansMenu', 'shenanigansMenuItemDailyRun', ImGuiElement.MenuItem, '\u{f073} Daily Run Shenanigans')
    ImGui.CreateWindow('shenanigansWindowDailyRun', 'Daily Run Shenanigans')
    ImGui.LinkWindowToElement('shenanigansWindowDailyRun', 'shenanigansMenuItemDailyRun')
    
    local d = os.date('*t')
    local year = d.year
    local month = d.month
    local day = d.day
    local months = { 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December' }
    local intYearId = 'shenanigansIntDailyRunYear'
    local cmbMonthId = 'shenanigansCmbDailyRunMonth'
    local intDayId = 'shenanigansIntDailyRunDay'
    ImGui.AddElement('shenanigansWindowDailyRun', '', ImGuiElement.SeparatorText, 'Date')
    ImGui.AddButton('shenanigansWindowDailyRun', 'shenanigansBtnDailyRunReset', 'Reset', function()
      year = d.year
      month = d.month
      day = d.day
      ImGui.UpdateData(intYearId, ImGuiData.Value, year)
      ImGui.UpdateData(cmbMonthId, ImGuiData.Value, month - 1)
      ImGui.UpdateData(intDayId, ImGuiData.Value, day)
    end, true)
    ImGui.AddSliderInteger('shenanigansWindowDailyRun', intYearId, 'Year', function(i)
      year = i
    end, year, year - 9, year)
    ImGui.AddCombobox('shenanigansWindowDailyRun', cmbMonthId, 'Month', function(i, m)
      month = i + 1
    end, months, month - 1, true)
    ImGui.AddSliderInteger('shenanigansWindowDailyRun', intDayId, 'Day', function(i)
      day = i
    end, day, 1, 31)
    
    mod:fillControllers()
    local controller = 0
    local cmbControllerId = 'shenanigansCmbDailyRunController'
    local btnControllerId = 'shenanigansBtnDailyRunController'
    ImGui.AddElement('shenanigansWindowDailyRun', '', ImGuiElement.SeparatorText, 'Controller')
    ImGui.AddCombobox('shenanigansWindowDailyRun', cmbControllerId, '', function(i)
      controller = i
    end, mod.controllers, controller, false)
    ImGui.AddElement('shenanigansWindowDailyRun', '', ImGuiElement.SameLine, '')
    ImGui.AddButton('shenanigansWindowDailyRun', btnControllerId, '\u{f021}', function()
      mod:fillControllers()
      controller = 0
      ImGui.UpdateData(cmbControllerId, ImGuiData.ListValues, mod.controllers)
      ImGui.UpdateData(cmbControllerId, ImGuiData.Value, controller)
    end, false)
    ImGui.SetTooltip(btnControllerId, 'Refresh (if you swap controllers)')
    
    ImGui.AddElement('shenanigansWindowDailyRun', '', ImGuiElement.SeparatorText, 'Go')
    ImGui.AddButton('shenanigansWindowDailyRun', 'shenanigansBtnDailyRun', 'Practice Daily Run', function()
      local gotActiveMenu, activeMenu = pcall(MenuManager.GetActiveMenu) -- IsActive
      if not gotActiveMenu then
        ImGui.PushNotification('Starting a daily run is disabled while in a run.', ImGuiNotificationType.ERROR, 5000)
        return
      end
      if activeMenu <= MainMenuType.SAVES then -- 2
        ImGui.PushNotification('Select a save slot before starting a daily run.', ImGuiNotificationType.ERROR, 5000)
        return
      end
      
      if not mod:isValidDate(year, month, day) then
        ImGui.PushNotification('Select a valid date for your daily run.', ImGuiNotificationType.ERROR, 5000)
        return
      end
      
      Isaac.StartDailyGame(tonumber(string.format('%04d%02d%02d', year, month, day)))
      mod.controllerOverride = mod.controllersMap[controller + 1] or -1
      ImGui.Hide()
    end, false)
    ImGui.AddElement('shenanigansWindowDailyRun', '', ImGuiElement.SameLine, '')
    ImGui.AddButton('shenanigansWindowDailyRun', 'shenanigansBtnDailyRunInfo', '\u{f05a}', function()
      local params = DailyChallenge.GetChallengeParams()
      local seeds = game:GetSeeds()
      if Isaac.IsInGame() and seeds:IsCustomRun() and params:GetEndStage() > 0 then
        local s = 'Seed: ' .. seeds:GetStartSeedString() -- GetStartSeed
        s = s .. '\nPlayer type: ' .. params:GetPlayerType()
        s = s .. '\nDifficulty: ' .. params:GetDifficulty() -- game.Difficulty
        s = s .. '\nEnd stage: ' .. params:GetEndStage()
        s = s .. '\nRoom filter: ' .. table.concat(params:GetRoomFilter(), ',')
        s = s .. '\nAlt path: ' .. (params:IsAltPath() and 'yes' or 'no')
        s = s .. '\nBeast path: ' .. (params:IsBeastPath() and 'yes' or 'no')
        s = s .. '\nMega Satan run: ' .. (params:IsMegaSatanRun() and 'yes' or 'no')
        s = s .. '\nSecret path: ' .. (params:IsSecretPath() and 'yes' or 'no')
        ImGui.PushNotification(s, ImGuiNotificationType.INFO, 5000)
        print(s .. '\n--------------------')
      else
        ImGui.PushNotification('Start a daily run to get its info.', ImGuiNotificationType.ERROR, 5000)
      end
    end, false)
  end
  
  mod:setupImGuiMenu()
  mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, mod.onModsLoaded)
  mod:AddCallback(ModCallbacks.MC_MAIN_MENU_RENDER, mod.onMainMenuRender)
  mod:AddPriorityCallback(ModCallbacks.MC_POST_PLAYER_INIT, CallbackPriority.IMPORTANT, mod.onPlayerInit, PlayerVariant.PLAYER)
end