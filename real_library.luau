-- < Real UI : Visual Command > --
-- < made by someone else > --

-- // Services
local CoreGui = game:GetService('CoreGui')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')
local TextService = game:GetService('TextService')
local GuiService = game:GetService('GuiService')
local Players = game:GetService('Players')
local Workspace = game:GetService('Workspace')
local RunService = game:GetService('RunService')

-- // Variables
local Library = {}
local Utility = {}
local Commands = {}
local Connections = {}     -- global (UserInputService) connections, disconnected on Destroy
local ThemeListeners = {}  -- callbacks run when the theme changes, cleared on Destroy
local Dragging = false

-- // Utility Functions
do
    function Utility:Log(Type, Message)
        Type = Type:lower()

        if Type == 'error' then
            error('[ Rbx ] Error: ' .. Message)
        elseif Type == 'log' then
            print('[ Rbx ] ' .. Message)
        elseif Type == 'warn' then
            warn('[ Rbx ] Warning: ' .. Message)
        end
    end

    function Utility:HasProperty(Object, Property)
        local Success = pcall(function()
            return Object[Property]
        end)

        return Success and not Object:FindFirstChild(Property)
    end

    function Utility:Tween(Object, Properties, Duration, ...)
        local Info = TweenInfo.new(Duration, ...)
        TweenService:Create(Object, Info, Properties):Play()
    end

    function Utility:Create(InstanceName, Properties, Children)
        local Object = Instance.new(InstanceName)
        Properties = Properties or {}
        Children = Children or {}

        for Index, Property in next, Properties do
            Object[Index] = Property
        end

        for _, Child in next, Children do
            Child.Parent = Object
        end

        return Object
    end

    function Utility:Lighten(Color)
        local H, S, V = Color:ToHSV()
        return Color3.fromHSV(H, S, math.clamp(V + 0.03, 0, 1))
    end

    function Utility:Darken(Color)
        local H, S, V = Color:ToHSV()
        return Color3.fromHSV(H, S, math.clamp(V - 0.35, 0, 1))
    end

    -- Escapes a string so it can be used safely inside a Lua pattern
    function Utility:EscapePattern(String)
        return (String:gsub('%W', '%%%0'))
    end

    -- Escapes a string so it can be used safely inside RichText
    function Utility:EscapeRichText(String)
        String = tostring(String)
        String = String:gsub('&', '&amp;')
        String = String:gsub('<', '&lt;')
        String = String:gsub('>', '&gt;')
        return String
    end

    function Utility:Connect(Signal, Callback)
        local Connection = Signal:Connect(Callback)
        table.insert(Connections, Connection)
        return Connection
    end

    function Utility:EnableDragging(Handle, Target)
        local DragStart, StartOffset

        Handle.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging = true
                DragStart = Input.Position.X
                StartOffset = Target.Position.X.Offset
            end
        end)

        Utility:Connect(UserInputService.InputChanged, function(Input)
            if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                local Camera = Workspace.CurrentCamera
                if not Camera then return end

                local Viewport = Camera.ViewportSize.X
                local Width = Target.AbsoluteSize.X
                local Scale = Target.Position.X.Scale
                local Anchor = Target.AnchorPoint.X

                -- keep the window fully on screen
                local Min = -Scale * Viewport + Anchor * Width
                local Max = Viewport - Width - Scale * Viewport + Anchor * Width
                local NewOffset = math.clamp(StartOffset + (Input.Position.X - DragStart), Min, Max)

                Target.Position = UDim2.new(Scale, NewOffset, Target.Position.Y.Scale, Target.Position.Y.Offset)
            end
        end)

        Utility:Connect(UserInputService.InputEnded, function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Dragging = false
            end
        end)
    end

    function Utility:StringToKeyCode(String)
        if type(String) ~= 'string' or String == '' then
            return nil
        end

        -- allow key names such as 'LeftControl'
        if #String > 1 then
            local Success, KeyCode = pcall(function()
                return Enum.KeyCode[String]
            end)

            if Success and KeyCode then
                return KeyCode
            end
        end

        local Byte = string.byte(String:lower())

        for _, KeyCode in next, Enum.KeyCode:GetEnumItems() do
            if KeyCode.Value == Byte then
                return KeyCode
            end
        end
    end

    function Utility:KeyCodeToString(KeyCode)
        if KeyCode.Value < 127 and KeyCode.Value > 33 then
            return string.char(KeyCode.Value)
        else
            return KeyCode.Name
        end
    end

    function Utility:GetProperty(Level, Name, Properties)
        local AllProperties = {
            Window = {
                Name = { 'Name', 'NAME', 'name' },
                IntroText = { 'IntroText', 'INTROTEXT', 'introText', 'introtext', 'Introtext' },
                IntroIcon = { 'IntroIcon', 'INTROICON', 'introIcon', 'introicon', 'Introicon' },
                IntroBlur = { 'IntroBlur', 'Introblur', 'INTROBLUR', 'introBlur', 'introblur' },
                IntroBlurIntensity = {
                    'introblurintensity', 'Introblurintensity', 'INTROBLURINTENSITY', 'introBlurintensity',
                    'IntroBlurintensity', 'introblurIntensity', 'IntroblurIntensity', 'introBlurIntensity',
                    'IntroBlurIntensity'
                },
                Theme = { 'Theme', 'THEME', 'theme' },
                Position = { 'Position', 'position', 'POSITION' },
                Draggable = { 'Draggable', 'DRAGGABLE', 'draggable' },
                Prefix = { 'Prefix', 'PREFIX', 'prefix' }
            }
        }

        local PossibleNames = AllProperties[Level][Name]

        for _, PossibleName in next, PossibleNames do
            if Properties[PossibleName] ~= nil then
                return Properties[PossibleName]
            end
        end
    end

    function Utility:Destroy()
        table.clear(ThemeListeners)

        for _, Connection in next, Connections do
            Connection:Disconnect()
        end
        table.clear(Connections)

        pcall(function()
            RunService:UnbindFromRenderStep('ToolTip')
        end)

        Dragging = false

        for _, UI in next, CoreGui:GetChildren() do
            if UI.Name == 'Command UI Library' then
                local Main = UI:FindFirstChild('Main')
                local ToolTip = UI:FindFirstChild('ToolTip')

                if Main then
                    for _, Item in next, Main:GetChildren() do
                        if Item.Name ~= 'MainCorner' and Item.Name ~= 'MainStroke' then
                            Item:Destroy()
                        end
                    end

                    Utility:Tween(Main, {Size = UDim2.new(0, 500, 0, 0)}, 0.25)
                end

                if ToolTip then
                    Utility:Tween(ToolTip, {BackgroundTransparency = 1}, 0.25)
                end

                task.wait(0.25)

                UI:Destroy()
            end
        end
    end
end

-- // Library Defaults
Library.Transparency = 0
Library.Themes = {
    ['dark'] = {
        BackgroundColor = Color3.fromRGB(40, 40, 40),
        SecondaryColor = Color3.fromRGB(50, 50, 50),
        AccentColor = Color3.fromRGB(100, 100, 100),
        PrimaryTextColor = Color3.fromRGB(255, 255, 255),
        SecondaryTextColor = Color3.fromRGB(175, 175, 175)
    },
    ['light'] = {
        BackgroundColor = Color3.fromRGB(255, 255, 255),
        SecondaryColor = Color3.fromRGB(225, 225, 225),
        AccentColor = Color3.fromRGB(125, 125, 125),
        PrimaryTextColor = Color3.fromRGB(0, 0, 0),
        SecondaryTextColor = Color3.fromRGB(75, 75, 75)
    },
    ['discord'] = {
        BackgroundColor = Color3.fromRGB(54, 57, 63),
        PrimaryTextColor = Color3.fromRGB(255, 255, 255),
        SecondaryTextColor = Color3.fromRGB(110, 110, 115),
        AccentColor = Color3.fromRGB(75, 75, 75),
        SecondaryColor = Color3.fromRGB(59, 65, 72)
    },
    ['redandblack'] = {
        BackgroundColor = Color3.fromRGB(0, 0, 0),
        PrimaryTextColor = Color3.fromRGB(255, 255, 255),
        SecondaryTextColor = Color3.fromRGB(135, 135, 135),
        AccentColor = Color3.fromRGB(255, 0, 0),
        SecondaryColor = Color3.fromRGB(50, 50, 50)
    },
    ['nordicdark'] = {
        BackgroundColor = Color3.fromRGB(25, 30, 35),
        PrimaryTextColor = Color3.fromRGB(255, 255, 255),
        SecondaryTextColor = Color3.fromRGB(135, 135, 135),
        AccentColor = Color3.fromRGB(50, 60, 70),
        SecondaryColor = Color3.fromRGB(50, 55, 60)
    },
    ['nordiclight'] = {
        BackgroundColor = Color3.fromRGB(67, 75, 94),
        PrimaryTextColor = Color3.fromRGB(255, 255, 255),
        SecondaryTextColor = Color3.fromRGB(135, 135, 135),
        AccentColor = Color3.fromRGB(92, 97, 116),
        SecondaryColor = Color3.fromRGB(82, 87, 106)
    },
    ['purple'] = {
        BackgroundColor = Color3.fromRGB(30, 30, 45),
        PrimaryTextColor = Color3.fromRGB(255, 255, 255),
        SecondaryTextColor = Color3.fromRGB(135, 135, 135),
        AccentColor = Color3.fromRGB(60, 60, 80),
        SecondaryColor = Color3.fromRGB(60, 60, 80)
    },
    ['sentinel'] = {
        BackgroundColor = Color3.fromRGB(30, 30, 30),
        PrimaryTextColor = Color3.fromRGB(130, 190, 130),
        SecondaryTextColor = Color3.fromRGB(230, 35, 70),
        AccentColor = Color3.fromRGB(50, 50, 50),
        SecondaryColor = Color3.fromRGB(35, 35, 35)
    },
    ['synapsex'] = {
        BackgroundColor = Color3.fromRGB(50, 50, 50),
        PrimaryTextColor = Color3.fromRGB(255, 255, 255),
        SecondaryTextColor = Color3.fromRGB(125, 125, 125),
        AccentColor = Color3.fromRGB(70, 70, 70),
        SecondaryColor = Color3.fromRGB(65, 65, 65)
    },
    ['krnl'] = {
        BackgroundColor = Color3.fromRGB(40, 40, 40),
        PrimaryTextColor = Color3.fromRGB(255, 255, 255),
        SecondaryTextColor = Color3.fromRGB(125, 125, 125),
        AccentColor = Color3.fromRGB(60, 60, 60),
        SecondaryColor = Color3.fromRGB(40, 40, 40)
    },
    ['scriptware'] = {
        BackgroundColor = Color3.fromRGB(30, 30, 30),
        PrimaryTextColor = Color3.fromRGB(0, 125, 255),
        SecondaryTextColor = Color3.fromRGB(255, 255, 255),
        AccentColor = Color3.fromRGB(0, 125, 255),
        SecondaryColor = Color3.fromRGB(45, 45, 45)
    },
    ['kiriot'] = {
        BackgroundColor = Color3.fromRGB(35, 35, 35),
        PrimaryTextColor = Color3.fromRGB(255, 255, 255),
        SecondaryTextColor = Color3.fromRGB(135, 135, 135),
        AccentColor = Color3.fromRGB(255, 170, 60),
        SecondaryColor = Color3.fromRGB(50, 50, 50)
    }
}
Library.Prefix = Utility:StringToKeyCode(';')
Library.Theme = nil

-- // CreateWindow - Name, Theme, Position, Draggable, Prefix
function Library:CreateWindow(Properties)
    Properties = Properties or {}

    -- // Properties
    local Name = Utility:GetProperty('Window', 'Name', Properties) or 'Command UI Library'
    local Theme = Utility:GetProperty('Window', 'Theme', Properties) or Library.Themes.dark
    local Position = string.lower(Utility:GetProperty('Window', 'Position', Properties) or 'top')
    local Draggable = Utility:GetProperty('Window', 'Draggable', Properties) or false
    local Prefix = Utility:StringToKeyCode(Utility:GetProperty('Window', 'Prefix', Properties)) or Utility:StringToKeyCode(';')

    local IsCustomTheme = type(Theme) == 'table'

    if type(Theme) == 'string' then
        Theme = Library.Themes[Theme:lower()] or Library.Themes.dark
    end

    -- // Destroy Old UI (also clears old connections / theme listeners)
    Utility:Destroy()

    -- // Set Library Properties
    Library.Prefix = Prefix
    Library.Theme = Theme

    if IsCustomTheme then
        Library.Themes['custom'] = Theme
    end

    -- // Layout
    local XScales = {
        top = 0.5, bottom = 0.5,
        topleft = 0, bottomleft = 0,
        topright = 1, bottomright = 1
    }

    if XScales[Position] == nil then
        Position = 'top'
    end

    local IsBottom = string.find(Position, 'bottom') ~= nil
    local XScale = XScales[Position]
    local YScale = IsBottom and 1 or 0
    local ClosedY = IsBottom and 36 or -72
    local OpenY = IsBottom and 0 or -36

    local FillerY = IsBottom and 60 or 0
    local InputAnchor = IsBottom and Vector2.new(0.5, 1) or Vector2.new(0.5, 0)
    local InputPosition = IsBottom and UDim2.new(0.5, 0, 1, -5) or UDim2.new(0.5, 0, 0, 5)
    local TitleY = IsBottom and 4 or 40
    local HolderY = IsBottom and -305 or 70

    -- // Create Elements
    local Container = Utility:Create('ScreenGui', {
        Parent = CoreGui,
        Name = 'Command UI Library',
        ResetOnSpawn = false
    }, {
        Utility:Create('Frame', {
            Name = 'Main',
            BackgroundColor3 = Theme.BackgroundColor,
            BorderSizePixel = 0,
            BackgroundTransparency = 0,
            AnchorPoint = Vector2.new(XScale, YScale),
            Position = UDim2.new(XScale, 0, YScale, ClosedY),
            Size = UDim2.new(0, 500, 0, 65) -- FIX: Main was never given a size
        }, {
            Utility:Create('UIStroke', {
                Name = 'MainStroke',
                ApplyStrokeMode = 'Contextual',
                Color = Theme.AccentColor,
                LineJoinMode = 'Round',
                Thickness = 1
            }),
            Utility:Create('UICorner', {
                CornerRadius = UDim.new(0, 5),
                Name = 'MainCorner'
            })
        }),
    })

    local Main = Container.Main

    -- // Dragging
    if Draggable then
        Utility:EnableDragging(Main, Main)
    end

    -- // Fillers And Lines
    Utility:Create('Frame', {
        Parent = Main, Name = 'Filler1', BackgroundColor3 = Theme.BackgroundColor, BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, FillerY), Size = UDim2.new(0, 5, 0, 5)
    })
    Utility:Create('Frame', {
        Parent = Main, Name = 'Filler2', BackgroundColor3 = Theme.BackgroundColor, BorderSizePixel = 0,
        Position = UDim2.new(0, 495, 0, FillerY), Size = UDim2.new(0, 5, 0, 5)
    })
    Utility:Create('Frame', {
        Parent = Main, Name = 'Line1', BackgroundColor3 = Theme.AccentColor, BorderSizePixel = 0,
        Position = UDim2.new(0, -1, 0, FillerY), Size = UDim2.new(0, 1, 0, 10)
    })
    Utility:Create('Frame', {
        Parent = Main, Name = 'Line2', BackgroundColor3 = Theme.AccentColor, BorderSizePixel = 0,
        Position = UDim2.new(0, 500, 0, FillerY), Size = UDim2.new(0, 1, 0, 10)
    })

    -- // Main Elements
    Utility:Create('TextBox', {
        Font = Enum.Font.Gotham,
        PlaceholderColor3 = Theme.SecondaryTextColor,
        PlaceholderText = 'Enter Command',
        Text = '',
        TextColor3 = Theme.PrimaryTextColor,
        TextSize = 14,
        ClearTextOnFocus = false,
        Parent = Main,
        BackgroundColor3 = Theme.SecondaryColor,
        BorderSizePixel = 0,
        TextTransparency = 0,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = false,
        Name = 'CommandInput',
        AnchorPoint = InputAnchor,
        Position = InputPosition,
        Size = UDim2.new(0, 490, 0, 30)
    }, {
        Utility:Create('UIStroke', {
            Name = 'CommandInputStroke',
            ApplyStrokeMode = 'Border',
            Color = Theme.AccentColor,
            LineJoinMode = 'Round',
            Thickness = 0
        }),
        Utility:Create('UICorner', {
            CornerRadius = UDim.new(0, 5),
            Name = 'CommandInputCorner'
        }),
        Utility:Create('UIPadding', {
            PaddingLeft = UDim.new(0, 5),
            Name = 'CommandInputPadding'
        }),
    })

    Utility:Create('TextLabel', {
        Name = 'Title',
        Parent = Main,
        BackgroundColor3 = Theme.BackgroundColor,
        BackgroundTransparency = 1,
        TextTransparency = 1,
        Position = UDim2.new(0, 0, 0, TitleY),
        Size = UDim2.new(0, 250, 0, 20),
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
        Text = Name,
        TextColor3 = Theme.PrimaryTextColor,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    }, {
        Utility:Create('UIPadding', {
            Name = 'TitlePadding',
            PaddingLeft = UDim.new(0, 7)
        })
    })

    Utility:Create('TextButton', {
        Name = 'CloseButton',
        Position = UDim2.new(0, 475, 0, TitleY),
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = Theme.BackgroundColor,
        TextColor3 = Theme.PrimaryTextColor,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        Parent = Main,
        TextYAlignment = Enum.TextYAlignment.Center,
        BorderSizePixel = 0,
        TextSize = 30,
        Text = '×'
    }, {
        Utility:Create('UICorner', {
            Name = 'CloseButtonCorner',
            CornerRadius = UDim.new(0, 5)
        })
    })

    Utility:Create('Frame', {
        Parent = Main,
        BackgroundColor3 = Theme.BackgroundColor,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Name = 'CommandsHolder',
        Visible = false,
        Position = UDim2.new(0, 0, 0, HolderY),
        Size = UDim2.new(0, 500, 0, 300)
    }, {
        Utility:Create('UIStroke', {
            Name = 'CommandsHolderStroke',
            ApplyStrokeMode = 'Contextual',
            Color = Theme.AccentColor,
            LineJoinMode = 'Round',
            Thickness = 1
        }),
        Utility:Create('UICorner', {
            CornerRadius = UDim.new(0, 5),
            Name = 'CommandsHolderCorner'
        }),
        Utility:Create('ScrollingFrame', {
            BackgroundColor3 = Theme.BackgroundColor,
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ScrollBarThickness = 1,
            ScrollBarImageColor3 = Theme.AccentColor,
            Name = 'CommandsHolderScrolling',
            Position = UDim2.new(0, 0, 0, 5),
            Size = UDim2.new(0, 500, 0, 290)
        }, {
            Utility:Create('UIListLayout', {
                Name = 'CommandsHolderScrollingListLayout',
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 3)
            })
        })
    })

    Utility:Create('TextLabel', {
        Name = 'ToolTip',
        Parent = Container,
        BackgroundColor3 = Theme.BackgroundColor,
        BackgroundTransparency = 0,
        TextTransparency = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        RichText = true,
        ZIndex = 100,
        Visible = false, -- FIX: was visible (and never bound) by default
        Text = '',
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
        TextColor3 = Theme.PrimaryTextColor,
        TextSize = 15
    }, {
        Utility:Create('UICorner', {
            Name = 'ToolTipCorner',
            CornerRadius = UDim.new(0, 5)
        }),
        Utility:Create('UIPadding', {
            Name = 'ToolTipPadding',
            PaddingLeft = UDim.new(0, 3),
            PaddingTop = UDim.new(0, 3)
        }),
        Utility:Create('UIStroke', {
            Name = 'ToolTipStroke',
            ApplyStrokeMode = 'Border',
            Color = Theme.AccentColor,
            LineJoinMode = 'Round',
            Thickness = 1
        })
    })

    -- // Variables
    local CommandInput = Main.CommandInput
    local CommandInputStroke = CommandInput.CommandInputStroke
    local CloseButton = Main.CloseButton
    local CommandsHolder = Main.CommandsHolder
    local CommandsHolderScrolling = CommandsHolder.CommandsHolderScrolling

    local IsOpen = false
    local Busy = false
    local IsInCommandsHolder = false

    -- // Theme Update (listener based, replaces the per-frame polling loops)
    local function OnThemeChanged(Callback)
        table.insert(ThemeListeners, Callback)
    end

    OnThemeChanged(function()
        local T = Library.Theme

        Utility:Tween(Main, {BackgroundColor3 = T.BackgroundColor}, 0.25)
        Utility:Tween(Main.MainStroke, {Color = T.AccentColor}, 0.25)
        Utility:Tween(Main.Filler1, {BackgroundColor3 = T.BackgroundColor}, 0.25)
        Utility:Tween(Main.Filler2, {BackgroundColor3 = T.BackgroundColor}, 0.25)
        Utility:Tween(Main.Line1, {BackgroundColor3 = T.AccentColor}, 0.25)
        Utility:Tween(Main.Line2, {BackgroundColor3 = T.AccentColor}, 0.25)
        Utility:Tween(CommandInput, {
            BackgroundColor3 = T.SecondaryColor,
            TextColor3 = T.PrimaryTextColor,
            PlaceholderColor3 = T.SecondaryTextColor
        }, 0.25)
        Utility:Tween(CommandInputStroke, {Color = T.AccentColor}, 0.25)
        Utility:Tween(Main.Title, {BackgroundColor3 = T.BackgroundColor, TextColor3 = T.PrimaryTextColor}, 0.25)
        Utility:Tween(CloseButton, {BackgroundColor3 = T.BackgroundColor, TextColor3 = T.PrimaryTextColor}, 0.25)
        Utility:Tween(CommandsHolder, {BackgroundColor3 = T.BackgroundColor}, 0.25)
        Utility:Tween(CommandsHolderScrolling, {
            BackgroundColor3 = T.BackgroundColor,
            ScrollBarImageColor3 = T.AccentColor
        }, 0.25)
        Utility:Tween(CommandsHolder.CommandsHolderStroke, {Color = T.AccentColor}, 0.25)
        Utility:Tween(Container.ToolTip, {BackgroundColor3 = T.BackgroundColor, TextColor3 = T.PrimaryTextColor}, 0.25)
        Utility:Tween(Container.ToolTip.ToolTipStroke, {Color = T.AccentColor}, 0.25)
    end)

    -- // Animate Elements
    task.wait(0.25)

    for _, Element in next, Main:GetChildren() do
        if Element:IsA('TextBox') or Element:IsA('TextLabel') or Element:IsA('TextButton') or Element:IsA('ImageButton') then
            Element.Visible = true

            if Utility:HasProperty(Element, 'BackgroundTransparency') then
                Utility:Tween(Element, {BackgroundTransparency = 0}, 0.25)
            end

            if Utility:HasProperty(Element, 'TextTransparency') then
                Utility:Tween(Element, {TextTransparency = 0}, 0.25)
            end

            if Utility:HasProperty(Element, 'ImageTransparency') then
                Utility:Tween(Element, {ImageTransparency = 0}, 0.25)
            end
        end
    end

    CommandInputStroke.Thickness = 1

    CloseButton.MouseEnter:Connect(function()
        Utility:Tween(CloseButton, {TextColor3 = Utility:Darken(Library.Theme.PrimaryTextColor)}, 0.25)
    end)

    CloseButton.MouseLeave:Connect(function()
        Utility:Tween(CloseButton, {TextColor3 = Library.Theme.PrimaryTextColor}, 0.25)
    end)

    -- // Update Command Holder Sizes
    local function UpdateFrameSizes()
        local Count = 0

        for _, Item in next, CommandsHolderScrolling:GetChildren() do
            if Item:IsA('Frame') and Item.Visible then
                Count += 1
            end
        end

        local CanvasHeight = math.max(Count * 33 - 3, 0)
        local HolderHeight, ViewHeight

        if Count == 0 then
            HolderHeight, ViewHeight = 0, 0
        elseif Count < 9 then
            HolderHeight, ViewHeight = CanvasHeight + 10, CanvasHeight
        else
            HolderHeight, ViewHeight = 270, 260
        end

        local Y = IsBottom and -(HolderHeight + 5) or 70

        Utility:Tween(CommandsHolder, {
            Size = UDim2.new(0, 500, 0, HolderHeight),
            Position = UDim2.new(0, 0, 0, Y)
        }, 0.25)

        Utility:Tween(CommandsHolderScrolling, {
            Size = UDim2.new(0, 500, 0, ViewHeight),
            CanvasSize = UDim2.new(0, 500, 0, CanvasHeight)
        }, 0.25)
    end

    CommandsHolderScrolling.ChildAdded:Connect(UpdateFrameSizes)
    CommandsHolderScrolling.ChildRemoved:Connect(UpdateFrameSizes)

    -- // Tool Tips (FIX: was a global function)
    local function CreateToolTip(Text, PlainText, Enabled)
        local ToolTip = Container:FindFirstChild('ToolTip')
        if not ToolTip then return end

        pcall(function()
            RunService:UnbindFromRenderStep('ToolTip')
        end)

        if Enabled then
            local Size = TextService:GetTextSize(PlainText, ToolTip.TextSize, ToolTip.Font, Vector2.new(300, math.huge))
            ToolTip.Size = UDim2.new(0, Size.X + 8, 0, Size.Y + 8)
            ToolTip.Text = Text
            ToolTip.Visible = true

            RunService:BindToRenderStep('ToolTip', 1, function()
                local Mouse = UserInputService:GetMouseLocation()
                local Inset = GuiService:GetGuiInset()

                -- FIX: GetMouseLocation includes the GUI inset, the ScreenGui does not
                ToolTip.Position = UDim2.fromOffset(Mouse.X, Mouse.Y - Inset.Y + 20)
            end)
        else
            ToolTip.Visible = false
        end
    end

    -- // Open / Close (FIX: replaces the duplicated, position-comparing animation blocks)
    local function MoveMain(OffsetY)
        Utility:Tween(Main, {
            Position = UDim2.new(Main.Position.X.Scale, Main.Position.X.Offset, YScale, OffsetY)
        }, 0.25)
    end

    local function FadeCommands(Visible)
        for _, Item in next, CommandsHolderScrolling:GetDescendants() do
            if Item:IsA('Frame') then
                Utility:Tween(Item, {BackgroundTransparency = Visible and 0.25 or 1}, 0.25)
            elseif Item:IsA('TextLabel') then
                Utility:Tween(Item, {TextTransparency = Visible and 0 or 1}, 0.25)
            end
        end
    end

    local function OpenUI()
        if IsOpen or Busy then return end

        Busy = true
        IsOpen = true

        UpdateFrameSizes()
        CommandInput:CaptureFocus()
        MoveMain(OpenY)

        task.wait(0.25)

        CommandsHolder.Visible = true
        Utility:Tween(CommandsHolder, {BackgroundTransparency = 0.25}, 0.25)

        task.wait(0.25)

        FadeCommands(true)
        Busy = false
    end

    local function CloseUI()
        if not IsOpen or Busy then return end

        Busy = true
        IsOpen = false
        IsInCommandsHolder = false

        CommandInput.Text = ''
        CommandInput:ReleaseFocus()
        CreateToolTip(nil, nil, false)
        FadeCommands(false)

        task.wait(0.25)

        Utility:Tween(CommandsHolder, {BackgroundTransparency = 1}, 0.25)

        task.wait(0.25)

        CommandsHolder.Visible = false
        MoveMain(ClosedY)

        task.wait(0.25)

        Busy = false
    end

    -- // Main Button Callbacks
    CloseButton.MouseButton1Down:Connect(function()
        Utility:Tween(CloseButton, {TextColor3 = Utility:Darken(Library.Theme.PrimaryTextColor)}, 0.25)

        task.wait(0.25)

        Utility:Tween(CloseButton, {TextColor3 = Library.Theme.PrimaryTextColor}, 0.25)

        task.wait(0.25)

        Utility:Destroy()
    end)

    -- // Prefix
    Utility:Connect(UserInputService.InputBegan, function(Input, GameProcessedEvent)
        if GameProcessedEvent or Input.UserInputType ~= Enum.UserInputType.Keyboard then return end

        if Library.Prefix and Input.KeyCode == Library.Prefix then
            if not IsOpen then
                OpenUI()
            elseif not Busy then
                CommandInput:CaptureFocus()
            end
        end
    end)

    -- // Execute Command
    local function Execute(String)
        local Words = {}

        for Word in string.gmatch(String, '%S+') do
            table.insert(Words, Word)
        end

        CommandInput.Text = ''

        if #Words == 0 then return end

        -- FIX: prefix is escaped (it is used as a pattern) and only stripped from the start
        local PrefixPattern = '^' .. Utility:EscapePattern(Utility:KeyCodeToString(Library.Prefix))
        local First = (Words[1]:lower():gsub(PrefixPattern, ''))

        local Command = Commands[First]

        -- FIX: assert() threw inside the caller; just warn instead
        if not Command then
            Utility:Log('Warn', 'Command Not Found: ' .. First)
            return
        end

        local Arguments = { table.unpack(Words, 2) }

        if #Arguments < #Command.Arguments then
            local Missing = {}

            for Index = #Arguments + 1, #Command.Arguments do
                table.insert(Missing, tostring(Command.Arguments[Index]))
            end

            -- FIX: 'Error' threw here, which stopped the UI from ever closing afterwards
            Utility:Log('Warn', 'Missing Arguments: ' .. table.concat(Missing, ', ') .. ' | Command: ' .. First)
            return
        end

        task.spawn(Command.Callback, Arguments, Players.LocalPlayer)
    end

    -- // Search Commands
    CommandInput:GetPropertyChangedSignal('Text'):Connect(function()
        local Text = CommandInput.Text

        -- remove the prefix character that gets typed when the box is focused with the prefix key
        local Stripped = Text:gsub('^' .. Utility:EscapePattern(Utility:KeyCodeToString(Library.Prefix)), '')

        if Stripped ~= Text then
            CommandInput.Text = Stripped
            return
        end

        -- FIX: Text:split() split on commas and the query was used as a Lua pattern
        local Query = Text:lower():match('^%s*(%S*)') or ''

        for _, Item in next, CommandsHolderScrolling:GetChildren() do
            if Item:IsA('Frame') then
                local CommandName = Item.Name:gsub('CommandHolder$', ''):lower()
                Item.Visible = string.find(CommandName, Query, 1, true) ~= nil
            end
        end

        UpdateFrameSizes()
    end)

    -- // Command Entered
    CommandInput.FocusLost:Connect(function(EnterPressed)
        if not IsOpen or Busy or Dragging then return end
        if IsInCommandsHolder and not EnterPressed then return end

        -- FIX: only run a command on Enter (clicking away used to run an empty command)
        if EnterPressed and CommandInput.Text ~= '' then
            Execute(CommandInput.Text)
        end

        CloseUI()
    end)

    local WindowFunctions = {}

    function WindowFunctions:ChangePrefix(NewPrefix)
        local KeyCode = Utility:StringToKeyCode(NewPrefix)

        if KeyCode then
            Library.Prefix = KeyCode
        else
            Utility:Log('Warn', 'Invalid prefix: ' .. tostring(NewPrefix))
        end
    end

    function WindowFunctions:AddTheme(ThemeName, NewTheme)
        if Library.Themes[ThemeName:lower()] then
            Utility:Log('Error', 'A Theme Already Exists With The Name ' .. ThemeName)
        else
            Library.Themes[ThemeName:lower()] = NewTheme
        end
    end

    function WindowFunctions:GetThemes(Names)
        if Names then
            local Table = {}

            for Index in next, Library.Themes do
                table.insert(Table, Index)
            end

            return Table
        else
            return Library.Themes
        end
    end

    function WindowFunctions:ChangeTheme(NewTheme)
        if type(NewTheme) == 'table' then
            Library.Themes['custom'] = NewTheme
            Library.Theme = NewTheme -- FIX: table themes were never applied
        elseif type(NewTheme) == 'string' and Library.Themes[NewTheme:lower()] then
            Library.Theme = Library.Themes[NewTheme:lower()]
        else
            Utility:Log('Error', 'Theme Doesn\'t exist: ' .. tostring(NewTheme))
        end

        Theme = Library.Theme

        for _, Callback in next, ThemeListeners do
            task.spawn(pcall, Callback)
        end
    end

    function WindowFunctions:CreateNotification(Title, Text, Duration)
        -- FIX: the 0.5s wait used to block the caller
        task.spawn(function()
            Title = Title or 'Title'
            Text = Text or 'Text'
            Duration = Duration or 5

            task.wait(0.5)

            if not Container.Parent then return end

            local TextSize = TextService:GetTextSize(Text, 14, Enum.Font.Gotham, Vector2.new(293, math.huge))
            local Height = TextSize.Y + 30
            local T = Library.Theme

            -- FIX: stack using the real existing notifications instead of name counting
            -- (names collided once an older notification was destroyed)
            local PreviousSizes = 0

            for _, Child in next, Container:GetChildren() do
                if Child.Name == 'Notification' then
                    PreviousSizes += Child.Size.Y.Offset + 5
                end
            end

            local Holder = Utility:Create('Frame', {
                Parent = Container,
                Name = 'Notification',
                BackgroundColor3 = T.BackgroundColor,
                BorderSizePixel = 0,
                Position = UDim2.new(1, 300, 1, -30 - PreviousSizes),
                Size = UDim2.new(0, 300, 0, Height),
                BackgroundTransparency = 0,
                AnchorPoint = Vector2.new(1, 1)
            }, {
                Utility:Create('UICorner', {
                    CornerRadius = UDim.new(0, 5),
                    Name = 'NotificationCorner'
                }),
                Utility:Create('UIStroke', {
                    Name = 'NotificationStroke',
                    ApplyStrokeMode = 'Contextual',
                    Color = T.AccentColor,
                    LineJoinMode = 'Round',
                    Thickness = 1
                }),
                Utility:Create('TextLabel', {
                    Name = 'NotificationTitle',
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, -1),
                    Size = UDim2.new(0, 300, 0, 30),
                    Font = Enum.Font.Gotham,
                    Text = Title,
                    TextColor3 = T.PrimaryTextColor,
                    TextSize = 16,
                    TextXAlignment = Enum.TextXAlignment.Left
                }, {
                    Utility:Create('UIPadding', {
                        Name = 'NotificationTitlePadding',
                        PaddingLeft = UDim.new(0, 7)
                    })
                }),
                Utility:Create('TextLabel', {
                    Name = 'NotificationText',
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 25),
                    Size = UDim2.new(0, 300, 0, TextSize.Y),
                    Font = Enum.Font.Gotham,
                    Text = Text,
                    TextWrapped = true,
                    TextColor3 = T.SecondaryTextColor,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top
                }, {
                    Utility:Create('UIPadding', {
                        Name = 'NotificationTextPadding',
                        PaddingLeft = UDim.new(0, 7)
                    })
                })
            })

            local TitleObj = Holder.NotificationTitle
            local TextObj = Holder.NotificationText

            Utility:Tween(Holder, {Position = UDim2.new(1, -30, 1, -30 - PreviousSizes)}, 0.25)

            task.wait(math.max(Duration - 0.5, 0))

            if not Holder.Parent then return end

            Utility:Tween(Holder, {BackgroundTransparency = 0.8}, 0.25)
            Utility:Tween(TitleObj, {TextTransparency = 0.5}, 0.25)
            Utility:Tween(TextObj, {TextTransparency = 0.5}, 0.25)

            task.wait(0.25)

            if not Holder.Parent then return end

            Utility:Tween(Holder, {Position = UDim2.new(1, 300, 1, Holder.Position.Y.Offset)}, 0.25)

            task.wait(0.25)

            Holder:Destroy()
        end)
    end

    function WindowFunctions:AddCommand(CommandName, Arguments, Description, Callback)
        Arguments = Arguments or {}
        Description = Description or ''

        local Key = CommandName:lower()

        Commands[Key] = {
            Name = Key,
            Arguments = Arguments,
            Description = Description,
            Callback = Callback
        }

        -- replace an existing entry instead of creating duplicate rows
        local Existing = CommandsHolderScrolling:FindFirstChild(Key .. 'CommandHolder')

        if Existing then
            Existing:Destroy()
        end

        -- FIX: '%d' errors on non-integer values like 127.5 / 135.00000001
        local function Highlight(String, Color)
            return string.format(
                '<font color="rgb(%d, %d, %d)">%s</font>',
                math.floor(Color.R * 255 + 0.5),
                math.floor(Color.G * 255 + 0.5),
                math.floor(Color.B * 255 + 0.5),
                Utility:EscapeRichText(String)
            )
        end

        local function ConstructString(Highlighted)
            if Highlighted then
                local String = Highlight(CommandName, Library.Theme.PrimaryTextColor) .. ' '

                for _, Argument in next, Arguments do
                    String = String .. Highlight('{' .. Argument .. '}', Library.Theme.SecondaryTextColor) .. ' '
                end

                return String .. Highlight('| ', Library.Theme.AccentColor) .. Highlight(Description, Library.Theme.SecondaryTextColor)
            else
                local String = CommandName .. ' '

                for _, Argument in next, Arguments do
                    String = String .. '{' .. Argument .. '} '
                end

                return String .. '| ' .. Description
            end
        end

        local T = Library.Theme

        local CommandHolder = Utility:Create('Frame', {
            Parent = CommandsHolderScrolling,
            BackgroundColor3 = T.BackgroundColor,
            BorderSizePixel = 0,
            BackgroundTransparency = 0.25,
            Name = Key .. 'CommandHolder',
            Size = UDim2.new(0, 490, 0, 30)
        }, {
            Utility:Create('UICorner', {
                CornerRadius = UDim.new(0, 5),
                Name = Key .. 'CommandsHolderCorner'
            }),
            Utility:Create('TextLabel', {
                Name = Key .. 'Text',
                BackgroundColor3 = T.BackgroundColor,
                BackgroundTransparency = 1,
                TextTransparency = 0,
                BorderSizePixel = 0,
                RichText = true,
                Size = UDim2.new(0, 490, 0, 30),
                Font = Enum.Font.Gotham,
                Text = ConstructString(true),
                TextColor3 = T.PrimaryTextColor,
                TextSize = 15,
                ZIndex = 2,
                TextXAlignment = Enum.TextXAlignment.Left
            }, {
                Utility:Create('UIPadding', {
                    PaddingLeft = UDim.new(0, 5),
                    Name = Key .. 'Padding'
                })
            }),
            Utility:Create('TextButton', {
                Name = Key .. 'Button',
                Size = UDim2.new(0, 490, 0, 30),
                BackgroundTransparency = 1,
                AutoButtonColor = false,
                BorderSizePixel = 0,
                ZIndex = 100,
                Text = ''
            }, {
                Utility:Create('UICorner', {
                    CornerRadius = UDim.new(0, 5),
                    Name = Key .. 'ButtonCorner'
                })
            })
        })

        local Label = CommandHolder[Key .. 'Text']
        local Button = CommandHolder[Key .. 'Button']

        -- // Theme Updates
        OnThemeChanged(function()
            local NewTheme = Library.Theme

            Utility:Tween(CommandHolder, {BackgroundColor3 = NewTheme.BackgroundColor}, 0.25)
            Utility:Tween(Label, {
                BackgroundColor3 = NewTheme.BackgroundColor,
                TextColor3 = NewTheme.PrimaryTextColor
            }, 0.25)
            Label.Text = ConstructString(true)
        end)

        -- // Events
        Button.MouseButton1Down:Connect(function()
            Utility:Tween(CommandHolder, {BackgroundColor3 = Utility:Lighten(Library.Theme.BackgroundColor)}, 0.25)

            -- FIX: was pcall(Execute(Name)), which ran Execute unprotected
            local Success, Err = pcall(Execute, Key)

            if not Success then
                Utility:Log('Warn', tostring(Err))
            end

            Utility:Tween(CommandHolder, {BackgroundColor3 = Library.Theme.BackgroundColor}, 0.25)

            CloseUI()
        end)

        -- FIX: IsInCommandsHolder was never set, so clicking a command could close the UI first
        CommandHolder.MouseEnter:Connect(function()
            IsInCommandsHolder = true
            Utility:Tween(CommandHolder, {BackgroundColor3 = Utility:Lighten(Library.Theme.BackgroundColor)}, 0.25)

            CreateToolTip(ConstructString(true), ConstructString(false), true)
        end)

        CommandHolder.MouseLeave:Connect(function()
            IsInCommandsHolder = false
            Utility:Tween(CommandHolder, {BackgroundColor3 = Library.Theme.BackgroundColor}, 0.25)

            CreateToolTip(nil, nil, false)
        end)
    end

    return WindowFunctions
end

return Library
