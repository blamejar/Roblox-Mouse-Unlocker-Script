-- Universal Mouse Lock Fix
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local unlocked = false

local function applyMouseState(state)
    unlocked = state
    if unlocked then
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        UserInputService.MouseIconEnabled = false
        GuiService.SelectedCoreObject = nil
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.V and not gameProcessed then
        applyMouseState(not unlocked)
    end
end)

localPlayer.CharacterAdded:Connect(function()
    applyMouseState(false)
end)

print("Universal Mouse Lock Fix Loaded!")
