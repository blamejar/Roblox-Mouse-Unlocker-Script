-- [[ CONFIGURATION ]]
local TOGGLE_KEY        = Enum.KeyCode.V
local PANIC_KEY         = Enum.KeyCode.End
local AUTO_OFF_MINUTES  = 10

-- [[ CORE SERVICES ]]
local Players          = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui", 5)
local uniqueTag = "TrueRightClickUnlocker_v105"
local bindName  = "MouseUnlockerPriorityLoop_v105"

-- [[ 1. MEMORY & TELEPORT CLEANUP ]]
local function globalCleanup()
    pcall(function() RunService:UnbindFromRenderStep(bindName) end)
    for _, obj in pairs(CoreGui:GetChildren()) do
        if obj:GetAttribute(uniqueTag) or obj.Name == "InternalMouseControlMax" then 
            pcall(function() obj:Destroy() end) 
        end
    end
    if playerGui then
        for _, obj in pairs(playerGui:GetChildren()) do
            if obj:GetAttribute(uniqueTag) or obj.Name == "InternalMouseControlMax" then 
                pcall(function() obj:Destroy() end) 
            end
        end
    end
end
globalCleanup() 

-- [[ 2. UI CONTAINER ]]
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InternalMouseControlMax"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui:SetAttribute(uniqueTag, true)

local parentSuccess = pcall(function() screenGui.Parent = CoreGui end)
if not parentSuccess and playerGui then screenGui.Parent = playerGui end

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "MaxOverride"
toggleBtn.Size = UDim2.new(0, 0, 0, 0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Text = ""
toggleBtn.Modal = false 
toggleBtn.Parent = screenGui

-- [[ 3. SMART CAMERA & SHIFT-LOCK PROFILER ]]
local function isFirstPerson()
    local cam = workspace.CurrentCamera
    if not cam then return false end
    
    if player.CameraMode == Enum.CameraMode.LockFirstPerson then return true end
    
    local char = player.Character
    if not char then return false end

    local trackingPart = char:FindFirstChild("Head") 
        or char:FindFirstChild("HumanoidRootPart") 
        or char.PrimaryPart
        
    if trackingPart then
        local distance = (cam.CFrame.Position - trackingPart.Position).Magnitude
        return distance <= 2.2
    end

    return false
end

-- [[ 4. PRIORITY RENDER LOOP ]]
local rightMouseDown = false
local startTime = os.time()

local function priorityFrameUpdate()
    if (os.time() - startTime) >= (AUTO_OFF_MINUTES * 60) then
        toggleBtn.Modal = false
        pcall(function() RunService:UnbindFromRenderStep(bindName) end)
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        return
    end

    if toggleBtn.Modal and not isFirstPerson() then
        toggleBtn.Modal = false
        pcall(function() RunService:UnbindFromRenderStep(bindName) end)
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        return
    end

    if toggleBtn.Modal then
        if rightMouseDown then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        else
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        end
    end
end

-- [[ 5. HARDENED EVENT LISTENERS ]]
local connections = {}

local function terminateSystem()
    toggleBtn.Modal = false
    globalCleanup()
    for _, conn in pairs(connections) do
        if conn then conn:Disconnect() end
    end
    table.clear(connections)
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == TOGGLE_KEY then
        if not isFirstPerson() then return end
        
        toggleBtn.Modal = not toggleBtn.Modal
        if toggleBtn.Modal then
            UserInputService.MouseIconEnabled = true
            startTime = os.time() 
            RunService:BindToRenderStep(bindName, Enum.RenderPriority.Camera.Value + 1, priorityFrameUpdate)
        else
            pcall(function() RunService:UnbindFromRenderStep(bindName) end)
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    elseif input.KeyCode == PANIC_KEY then
        terminateSystem()
    end
    
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseDown = true
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rightMouseDown = false
    end
end))

table.insert(connections, UserInputService.WindowFocusReleased:Connect(function()
    rightMouseDown = false
end))
