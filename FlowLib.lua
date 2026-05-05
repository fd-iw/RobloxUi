--[[
    ╔═══════════════════════════════════════════╗
    ║           F L O W   U I   L I B           ║
    ║      Modern Cloud UI Library v1.0         ║
    ╚═══════════════════════════════════════════╝

    USAGE:
        local Flow = loadstring(...)()
        local Window = Flow:CreateWindow("My Script", "@tag")

        local Tab = Window:AddTab("Main")
        local Card = Tab:AddCard("Silent Aim")

        Card:Toggle("Enabled", false, function(v) print(v) end)
        Card:Slider("Hit Chance", 0, 100, 85, function(v) print(v) end)
        Card:Button("Apply", function() print("clicked") end)
        Card:Dropdown("Target", {"Head","Torso","Arms"}, function(v) print(v) end)
        Card:Textbox("Custom Key", "e.g. X", function(v) print(v) end)
]]

local FlowLib = {}
FlowLib.__index = FlowLib

-- ─────────────────────────────────────────────
--  Services
-- ─────────────────────────────────────────────
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local LP   = Players.LocalPlayer
local PGui = LP:WaitForChild("PlayerGui")

-- ─────────────────────────────────────────────
--  Theme
-- ─────────────────────────────────────────────
local T = {
    -- Backgrounds
    BG           = Color3.fromRGB(12, 12, 20),
    Surface      = Color3.fromRGB(18, 18, 30),
    Card         = Color3.fromRGB(22, 22, 38),
    CardHover    = Color3.fromRGB(28, 28, 46),
    Header       = Color3.fromRGB(16, 16, 28),
    Sidebar      = Color3.fromRGB(14, 14, 24),
    FloatBG      = Color3.fromRGB(20, 20, 34),

    -- Borders
    Border       = Color3.fromRGB(48, 48, 80),
    BorderFocus  = Color3.fromRGB(90, 70, 160),
    BorderFloat  = Color3.fromRGB(70, 55, 130),

    -- Accents
    Accent       = Color3.fromRGB(120, 90, 240),
    AccentBright = Color3.fromRGB(160, 130, 255),
    AccentSoft   = Color3.fromRGB(80, 60, 160),
    AccentGlow   = Color3.fromRGB(100, 75, 200),

    -- Text
    Text         = Color3.fromRGB(220, 218, 235),
    TextSub      = Color3.fromRGB(150, 148, 175),
    TextMuted    = Color3.fromRGB(90, 88, 115),
    TextAccent   = Color3.fromRGB(175, 155, 255),

    -- Elements
    Toggle       = Color3.fromRGB(35, 35, 58),
    ToggleOn     = Color3.fromRGB(110, 85, 220),
    SliderTrack  = Color3.fromRGB(30, 30, 50),
    SliderFill   = Color3.fromRGB(110, 85, 220),
    InputBG      = Color3.fromRGB(16, 16, 28),
    Divider      = Color3.fromRGB(32, 32, 54),
    White        = Color3.fromRGB(255, 255, 255),
    Black        = Color3.fromRGB(0, 0, 0),

    -- Fonts
    Bold    = Enum.Font.GothamBold
    Semi    = Enum.Font.GothamBold
    Regular = Enum.Font.Gotham

    -- Radii
    RadiusWin    = UDim.new(0, 12),
    RadiusCard   = UDim.new(0, 10),
    RadiusElem   = UDim.new(0, 7),
    RadiusSmall  = UDim.new(0, 5),
    RadiusPill   = UDim.new(1, 0),
}

-- ─────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────
local function New(class, props, children)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, c in ipairs(children or {}) do
        c.Parent = obj
    end
    return obj
end

local function Corner(r)
    return New("UICorner", { CornerRadius = r or T.RadiusElem })
end

local function Stroke(color, thick, mode)
    return New("UIStroke", {
        Color               = color or T.Border,
        Thickness           = thick or 1,
        ApplyStrokeMode     = mode or Enum.ApplyStrokeMode.Border,
    })
end

local function Padding(t, b, l, r)
    return New("UIPadding", {
        PaddingTop    = UDim.new(0, t or 6),
        PaddingBottom = UDim.new(0, b or 6),
        PaddingLeft   = UDim.new(0, l or 10),
        PaddingRight  = UDim.new(0, r or 10),
    })
end

local function ListLayout(padding, align)
    return New("UIListLayout", {
        SortOrder         = Enum.SortOrder.LayoutOrder,
        Padding           = UDim.new(0, padding or 0),
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
    })
end

local function Tween(obj, props, t, style, dir)
    local info = TweenInfo.new(
        t or 0.25,
        style or Enum.EasingStyle.Quart,
        dir or Enum.EasingDirection.Out
    )
    TweenService:Create(obj, info, props):Play()
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local drag, startMouse, startPos = false, nil, nil

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            startMouse = inp.Position
            startPos  = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    drag = false
                end
            end)
        end
    end)

    local lastInput
    handle.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            lastInput = inp
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if drag and inp == lastInput then
            local d = inp.Position - startMouse
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

-- Rounded top only fix (frame covering bottom radius)
local function RoundTop(frame, color, zIndex)
    return New("Frame", {
        Size              = UDim2.new(1, 0, 0.5, 0),
        Position          = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3  = color,
        BorderSizePixel   = 0,
        ZIndex            = (zIndex or 1),
        Parent            = frame,
    })
end

-- Auto-resize scrolling frame
local function AutoScroll(layout, scroll)
    local function update()
        local size = layout.AbsoluteContentSize
        scroll.CanvasSize = UDim2.new(0, 0, 0, size.Y + 20)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(update)
    update()
end

-- ─────────────────────────────────────────────
--  Window Constructor
-- ─────────────────────────────────────────────
function FlowLib:CreateWindow(title, subtitle)
    local W = setmetatable({}, { __index = FlowLib })
    W._tabs    = {}
    W._cards   = {}
    W._active  = nil

    -- Root GUI
    W.GUI = New("ScreenGui", {
        Name            = "FlowLib_" .. (title or "Window"),
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        Parent          = PGui,
    })

    -- ── Main Frame ──────────────────────────────
    W.Win = New("Frame", {
        Name              = "MainWindow",
        Size              = UDim2.new(0, 620, 0, 440),
        Position          = UDim2.new(0.5, -310, 0.5, -220),
        BackgroundColor3  = T.BG,
        BorderSizePixel   = 0,
        ClipsDescendants  = false,
        Parent            = W.GUI,
    }, { Corner(T.RadiusWin), Stroke(T.Border, 1.5) })

    -- Drop shadow
    New("ImageLabel", {
        Name              = "Shadow",
        AnchorPoint       = Vector2.new(0.5, 0.5),
        Size              = UDim2.new(1, 60, 1, 60),
        Position          = UDim2.new(0.5, 0, 0.5, 8),
        BackgroundTransparency = 1,
        Image             = "rbxassetid://7912134082",
        ImageColor3       = T.Black,
        ImageTransparency = 0.55,
        ScaleType         = Enum.ScaleType.Slice,
        SliceCenter       = Rect.new(49, 49, 450, 450),
        ZIndex            = 0,
        Parent            = W.Win,
    })

    -- ── Title Bar ───────────────────────────────
    W.TitleBar = New("Frame", {
        Name              = "TitleBar",
        Size              = UDim2.new(1, 0, 0, 46),
        BackgroundColor3  = T.Sidebar,
        BorderSizePixel   = 0,
        ZIndex            = 5,
        Parent            = W.Win,
    }, { Corner(T.RadiusWin) })

    -- Cover bottom-half of title bar corners
    RoundTop(W.TitleBar, T.Sidebar, 4)

    -- Subtle gradient line at bottom of titlebar
    New("Frame", {
        Size              = UDim2.new(1, 0, 0, 1),
        Position          = UDim2.new(0, 0, 1, -1),
        BackgroundColor3  = T.Border,
        BorderSizePixel   = 0,
        ZIndex            = 6,
        Parent            = W.TitleBar,
    })

    -- Title & subtitle
    New("TextLabel", {
        Text              = title or "Flow",
        Font              = T.Bold,
        TextSize          = 17,
        TextColor3        = T.White,
        Size              = UDim2.new(0, 250, 1, 0),
        Position          = UDim2.new(0, 56, 0, 0),
        BackgroundTransparency = 1,
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 7,
        Parent            = W.TitleBar,
    })
    New("TextLabel", {
        Text              = subtitle or "",
        Font              = T.Regular,
        TextSize          = 11,
        TextColor3        = T.TextMuted,
        Size              = UDim2.new(0, 250, 1, 0),
        Position          = UDim2.new(0, 56, 0, 22),
        BackgroundTransparency = 1,
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 7,
        Parent            = W.TitleBar,
    })

    -- Logo dot
    New("Frame", {
        Size              = UDim2.new(0, 8, 0, 8),
        Position          = UDim2.new(0, 16, 0.5, -4),
        BackgroundColor3  = T.Accent,
        BorderSizePixel   = 0,
        ZIndex            = 7,
        Parent            = W.TitleBar,
    }, { Corner(T.RadiusPill) })
    New("Frame", {
        Size              = UDim2.new(0, 14, 0, 14),
        Position          = UDim2.new(0, 13, 0.5, -7),
        BackgroundColor3  = T.AccentSoft,
        BackgroundTransparency = 0.5,
        BorderSizePixel   = 0,
        ZIndex            = 6,
        Parent            = W.TitleBar,
    }, { Corner(T.RadiusPill) })

    -- Window controls
    local function WinBtn(icon, color, xOffset)
        local btn = New("TextButton", {
            Text              = icon,
            Font              = T.Bold,
            TextSize          = 16,
            TextColor3        = T.TextMuted,
            Size              = UDim2.new(0, 26, 0, 26),
            Position          = UDim2.new(1, xOffset, 0.5, -13),
            BackgroundColor3  = color,
            BackgroundTransparency = 1,
            BorderSizePixel   = 0,
            ZIndex            = 8,
            Parent            = W.TitleBar,
        }, { Corner(T.RadiusSmall) })
        btn.MouseEnter:Connect(function()
            Tween(btn, { BackgroundTransparency = 0.1 }, 0.15)
            Tween(btn, { TextColor3 = T.White }, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, { BackgroundTransparency = 1 }, 0.15)
            Tween(btn, { TextColor3 = T.TextMuted }, 0.15)
        end)
        return btn
    end

    local closeBtn = WinBtn("×", Color3.fromRGB(200, 55, 55), -10)
    local minBtn   = WinBtn("−", Color3.fromRGB(200, 170, 30), -42)

    closeBtn.MouseButton1Click:Connect(function()
        Tween(W.Win, { BackgroundTransparency = 1 }, 0.2)
        task.delay(0.2, function() W.GUI:Destroy() end)
    end)

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(W.Win, {
            Size = minimized
                and UDim2.new(0, 620, 0, 46)
                or  UDim2.new(0, 620, 0, 440)
        }, 0.3, Enum.EasingStyle.Quart)
    end)

    MakeDraggable(W.Win, W.TitleBar)

    -- ── Body ────────────────────────────────────
    W.Body = New("Frame", {
        Name              = "Body",
        Size              = UDim2.new(1, 0, 1, -46),
        Position          = UDim2.new(0, 0, 0, 46),
        BackgroundTransparency = 1,
        BorderSizePixel   = 0,
        ClipsDescendants  = true,
        Parent            = W.Win,
    })

    -- ── Sidebar ─────────────────────────────────
    W.Sidebar = New("Frame", {
        Name              = "Sidebar",
        Size              = UDim2.new(0, 148, 1, 0),
        BackgroundColor3  = T.Sidebar,
        BorderSizePixel   = 0,
        ZIndex            = 3,
        Parent            = W.Body,
    })

    -- Sidebar right divider
    New("Frame", {
        Size              = UDim2.new(0, 1, 1, 0),
        Position          = UDim2.new(1, 0, 0, 0),
        BackgroundColor3  = T.Border,
        BorderSizePixel   = 0,
        ZIndex            = 4,
        Parent            = W.Sidebar,
    })

    -- Sidebar bottom corner cover
    New("Frame", {
        Size              = UDim2.new(1, 0, 0, 12),
        Position          = UDim2.new(0, 0, 1, -12),
        BackgroundColor3  = T.Sidebar,
        BorderSizePixel   = 0,
        ZIndex            = 2,
        Parent            = W.Sidebar,
    })

    W.SidebarList = New("ScrollingFrame", {
        Size              = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel   = 0,
        ScrollBarThickness = 0,
        ZIndex            = 4,
        Parent            = W.Sidebar,
    }, { ListLayout(3), Padding(10, 10, 8, 8) })

    -- ── Content ─────────────────────────────────
    W.Content = New("Frame", {
        Name              = "Content",
        Size              = UDim2.new(1, -148, 1, 0),
        Position          = UDim2.new(0, 148, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel   = 0,
        Parent            = W.Body,
    })

    -- ─────────────────────────────────────────
    --  Tab API
    -- ─────────────────────────────────────────
    function W:AddTab(name)
        local tabData = { Name = name, Cards = {}, Active = false }
        table.insert(W._tabs, tabData)

        -- ── Tab Button ──────────────────────────
        local btn = New("TextButton", {
            Text              = "",
            Size              = UDim2.new(1, 0, 0, 34),
            BackgroundColor3  = T.Card,
            BackgroundTransparency = 1,
            BorderSizePixel   = 0,
            LayoutOrder       = #W._tabs,
            ZIndex            = 5,
            Parent            = W.SidebarList,
        }, { Corner(T.RadiusElem) })

        -- Active pill indicator
        local pill = New("Frame", {
            Size              = UDim2.new(0, 3, 0.55, 0),
            Position          = UDim2.new(0, 0, 0.225, 0),
            BackgroundColor3  = T.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel   = 0,
            ZIndex            = 7,
            Parent            = btn,
        }, { Corner(UDim.new(0, 3)) })

        -- Button label
        local lbl = New("TextLabel", {
            Text              = name,
            Font              = T.Semi,
            TextSize          = 13,
            TextColor3        = T.TextMuted,
            Size              = UDim2.new(1, -14, 1, 0),
            Position          = UDim2.new(0, 14, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment    = Enum.TextXAlignment.Left,
            ZIndex            = 6,
            Parent            = btn,
        })

        -- ── Tab Content Frame ────────────────────
        local scroll = New("ScrollingFrame", {
            Name              = name .. "_Content",
            Size              = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel   = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.AccentSoft,
            Visible           = false,
            Parent            = W.Content,
        })
        local scrollLayout = New("UIListLayout", {
            SortOrder         = Enum.SortOrder.LayoutOrder,
            Padding           = UDim.new(0, 8),
            Parent            = scroll,
        })
        Padding(10, 10, 10, 10).Parent = scroll
        AutoScroll(scrollLayout, scroll)

        tabData.Btn    = btn
        tabData.Pill   = pill
        tabData.Label  = lbl
        tabData.Scroll = scroll

        -- Hover
        btn.MouseEnter:Connect(function()
            if not tabData.Active then
                Tween(btn,  { BackgroundTransparency = 0.85 }, 0.15)
                Tween(lbl,  { TextColor3 = T.Text }, 0.15)
            end
        end)
        btn.MouseLeave:Connect(function()
            if not tabData.Active then
                Tween(btn, { BackgroundTransparency = 1 }, 0.15)
                Tween(lbl, { TextColor3 = T.TextMuted }, 0.15)
            end
        end)

        -- Click
        btn.MouseButton1Click:Connect(function()
            W:_SelectTab(tabData)
        end)

        -- Auto-select first
        if #W._tabs == 1 then W:_SelectTab(tabData) end

        -- ─────────────────────────────────────
        --  Card API (returned from AddTab)
        -- ─────────────────────────────────────
        local Tab = {}

        function Tab:AddCard(cardTitle)
            local cd = { Title = cardTitle, Elems = {}, Collapsed = false, Detached = false }
            table.insert(tabData.Cards, cd)
            table.insert(W._cards, cd)

            -- ── Card Frame ──────────────────────
            local card = New("Frame", {
                Name              = cardTitle .. "_Card",
                Size              = UDim2.new(1, 0, 0, 0),
                BackgroundColor3  = T.Card,
                BorderSizePixel   = 0,
                AutomaticSize     = Enum.AutomaticSize.Y,
                LayoutOrder       = #tabData.Cards,
                ClipsDescendants  = false,
                Parent            = scroll,
            }, { Corner(T.RadiusCard), Stroke(T.Border, 1) })

            -- ── Card Header ─────────────────────
            local hdr = New("Frame", {
                Name              = "Header",
                Size              = UDim2.new(1, 0, 0, 36),
                BackgroundColor3  = T.Header,
                BorderSizePixel   = 0,
                ZIndex            = 3,
                Parent            = card,
            }, { Corner(T.RadiusCard) })

            -- Cover bottom-half of header radius
            RoundTop(hdr, T.Header, 2)

            -- Header accent bar
            New("Frame", {
                Size              = UDim2.new(0, 3, 0, 16),
                Position          = UDim2.new(0, 10, 0.5, -8),
                BackgroundColor3  = T.Accent,
                BorderSizePixel   = 0,
                ZIndex            = 4,
                Parent            = hdr,
            }, { Corner(UDim.new(0, 2)) })

            -- Card title
            New("TextLabel", {
                Text              = cardTitle,
                Font              = T.Semi,
                TextSize          = 13,
                TextColor3        = T.Text,
                Size              = UDim2.new(1, -76, 1, 0),
                Position          = UDim2.new(0, 22, 0, 0),
                BackgroundTransparency = 1,
                TextXAlignment    = Enum.TextXAlignment.Left,
                ZIndex            = 4,
                Parent            = hdr,
            })

            -- Collapse button
            local colBtn = New("TextButton", {
                Text              = "▾",
                Font              = T.Bold,
                TextSize          = 14,
                TextColor3        = T.TextMuted,
                Size              = UDim2.new(0, 28, 0, 28),
                Position          = UDim2.new(1, -60, 0.5, -14),
                BackgroundTransparency = 1,
                BorderSizePixel   = 0,
                ZIndex            = 5,
                Parent            = hdr,
            })

            -- Detach button
            local detBtn = New("TextButton", {
                Text              = "⊡",
                Font              = T.Bold,
                TextSize          = 13,
                TextColor3        = T.TextMuted,
                Size              = UDim2.new(0, 28, 0, 28),
                Position          = UDim2.new(1, -30, 0.5, -14),
                BackgroundTransparency = 1,
                BorderSizePixel   = 0,
                ZIndex            = 5,
                Parent            = hdr,
            })

            -- Button hovers
            for _, b in ipairs({ colBtn, detBtn }) do
                b.MouseEnter:Connect(function()
                    Tween(b, { TextColor3 = T.AccentBright }, 0.15)
                end)
                b.MouseLeave:Connect(function()
                    Tween(b, { TextColor3 = T.TextMuted }, 0.15)
                end)
            end

            -- ── Card Body ───────────────────────
            local body = New("Frame", {
                Name              = "Body",
                Size              = UDim2.new(1, 0, 0, 0),
                Position          = UDim2.new(0, 0, 0, 36),
                BackgroundTransparency = 1,
                BorderSizePixel   = 0,
                AutomaticSize     = Enum.AutomaticSize.Y,
                ZIndex            = 3,
                Parent            = card,
            })
            local bodyLayout = New("UIListLayout", {
                SortOrder         = Enum.SortOrder.LayoutOrder,
                Padding           = UDim.new(0, 1),
                Parent            = body,
            })
            Padding(6, 8, 10, 10).Parent = body

            cd.Frame   = card
            cd.Header  = hdr
            cd.Body    = body
            cd.Layout  = bodyLayout

            -- ── Collapse Logic ──────────────────
            colBtn.MouseButton1Click:Connect(function()
                cd.Collapsed = not cd.Collapsed
                if cd.Collapsed then
                    body.Visible = false
                    Tween(colBtn, { TextTransparency = 0, Rotation = -90 }, 0.2)
                else
                    body.Visible = true
                    Tween(colBtn, { TextTransparency = 0, Rotation = 0 }, 0.2)
                end
            end)

            -- ── Detach Logic ────────────────────
            detBtn.MouseButton1Click:Connect(function()
                W:_DetachCard(cd)
            end)

            -- ── Element Builders ────────────────
            local Card = {}

            -- Row helper
            local function MakeRow(name, height)
                return New("Frame", {
                    Name              = name,
                    Size              = UDim2.new(1, 0, 0, height or 34),
                    BackgroundTransparency = 1,
                    LayoutOrder       = #cd.Elems + 1,
                    Parent            = cd.Body,
                })
            end

            -- ── Toggle ──────────────────────────
            function Card:Toggle(label, default, callback)
                local on = default or false
                local row = MakeRow(label .. "_Toggle", 34)
                table.insert(cd.Elems, row)

                New("TextLabel", {
                    Text              = label,
                    Font              = T.Regular,
                    TextSize          = 13,
                    TextColor3        = T.Text,
                    Size              = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = row,
                })

                local track = New("Frame", {
                    Size              = UDim2.new(0, 38, 0, 20),
                    Position          = UDim2.new(1, -38, 0.5, -10),
                    BackgroundColor3  = on and T.ToggleOn or T.Toggle,
                    BorderSizePixel   = 0,
                    Parent            = row,
                }, { Corner(T.RadiusPill) })

                local knob = New("Frame", {
                    Size              = UDim2.new(0, 14, 0, 14),
                    Position          = on
                        and UDim2.new(1, -17, 0.5, -7)
                        or  UDim2.new(0, 3,  0.5, -7),
                    BackgroundColor3  = T.White,
                    BorderSizePixel   = 0,
                    ZIndex            = 2,
                    Parent            = track,
                }, { Corner(T.RadiusPill) })

                local function Set(val)
                    on = val
                    Tween(track, { BackgroundColor3 = on and T.ToggleOn or T.Toggle }, 0.2)
                    Tween(knob, {
                        Position = on
                            and UDim2.new(1, -17, 0.5, -7)
                            or  UDim2.new(0,  3,  0.5, -7)
                    }, 0.2, Enum.EasingStyle.Quart)
                end

                track.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        Set(not on)
                        if callback then callback(on) end
                    end
                end)

                return {
                    Set = Set,
                    Get = function() return on end,
                }
            end

            -- ── Slider ──────────────────────────
            function Card:Slider(label, min, max, default, callback)
                min = min or 0; max = max or 100
                local val  = math.clamp(default or min, min, max)
                local frac = (val - min) / (max - min)

                local row = MakeRow(label .. "_Slider", 50)
                table.insert(cd.Elems, row)

                -- Top row: label + value
                local top = New("Frame", {
                    Size              = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Parent            = row,
                })
                New("TextLabel", {
                    Text              = label,
                    Font              = T.Regular,
                    TextSize          = 13,
                    TextColor3        = T.Text,
                    Size              = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = top,
                })
                local valLbl = New("TextLabel", {
                    Text              = tostring(val),
                    Font              = T.Semi,
                    TextSize          = 12,
                    TextColor3        = T.TextAccent,
                    Size              = UDim2.new(0, 50, 1, 0),
                    Position          = UDim2.new(1, -50, 0, 0),
                    BackgroundTransparency = 1,
                    TextXAlignment    = Enum.TextXAlignment.Right,
                    Parent            = top,
                })

                -- Track
                local track = New("Frame", {
                    Size              = UDim2.new(1, 0, 0, 5),
                    Position          = UDim2.new(0, 0, 0, 32),
                    BackgroundColor3  = T.SliderTrack,
                    BorderSizePixel   = 0,
                    Parent            = row,
                }, { Corner(T.RadiusPill) })

                local fill = New("Frame", {
                    Size              = UDim2.new(frac, 0, 1, 0),
                    BackgroundColor3  = T.SliderFill,
                    BorderSizePixel   = 0,
                    Parent            = track,
                }, { Corner(T.RadiusPill) })

                local knob = New("Frame", {
                    Size              = UDim2.new(0, 13, 0, 13),
                    Position          = UDim2.new(frac, -6, 0.5, -6),
                    BackgroundColor3  = T.White,
                    BorderSizePixel   = 0,
                    ZIndex            = 2,
                    Parent            = track,
                }, { Corner(T.RadiusPill), Stroke(T.AccentGlow, 1.5) })

                local dragging = false

                local function Update(inputX)
                    local rel = (inputX - track.AbsolutePosition.X) / track.AbsoluteSize.X
                    rel = math.clamp(rel, 0, 1)
                    val = math.round(min + (max - min) * rel)
                    valLbl.Text = tostring(val)
                    fill.Size     = UDim2.new(rel, 0, 1, 0)
                    knob.Position = UDim2.new(rel, -6, 0.5, -6)
                    if callback then callback(val) end
                end

                track.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        Update(inp.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        Update(inp.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                return {
                    Set = function(v)
                        val = math.clamp(v, min, max)
                        local r = (val - min) / (max - min)
                        valLbl.Text = tostring(val)
                        fill.Size     = UDim2.new(r, 0, 1, 0)
                        knob.Position = UDim2.new(r, -6, 0.5, -6)
                    end,
                    Get = function() return val end,
                }
            end

            -- ── Button ──────────────────────────
            function Card:Button(label, callback)
                local btn = New("TextButton", {
                    Name              = label .. "_Btn",
                    Text              = label,
                    Font              = T.Semi,
                    TextSize          = 13,
                    TextColor3        = T.Text,
                    Size              = UDim2.new(1, 0, 0, 30),
                    BackgroundColor3  = T.Surface,
                    BorderSizePixel   = 0,
                    LayoutOrder       = #cd.Elems + 1,
                    Parent            = cd.Body,
                }, { Corner(T.RadiusElem), Stroke(T.Divider, 1) })
                table.insert(cd.Elems, btn)

                btn.MouseEnter:Connect(function()
                    Tween(btn, { BackgroundColor3 = T.Accent, TextColor3 = T.White }, 0.2)
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, { BackgroundColor3 = T.Surface, TextColor3 = T.Text }, 0.2)
                end)
                btn.MouseButton1Click:Connect(function()
                    Tween(btn, { BackgroundColor3 = T.AccentBright }, 0.05)
                    task.delay(0.12, function()
                        Tween(btn, { BackgroundColor3 = T.Accent }, 0.2)
                    end)
                    if callback then callback() end
                end)
            end

            -- ── Dropdown ────────────────────────
            function Card:Dropdown(label, options, callback)
                local sel  = options[1] or "Select…"
                local open = false

                local wrap = New("Frame", {
                    Name              = label .. "_DD",
                    Size              = UDim2.new(1, 0, 0, 52),
                    BackgroundTransparency = 1,
                    ClipsDescendants  = false,
                    LayoutOrder       = #cd.Elems + 1,
                    Parent            = cd.Body,
                })
                table.insert(cd.Elems, wrap)

                New("TextLabel", {
                    Text              = label,
                    Font              = T.Regular,
                    TextSize          = 12,
                    TextColor3        = T.TextSub,
                    Size              = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = wrap,
                })

                local arrow = "▾"
                local ddBtn = New("TextButton", {
                    Text              = sel .. "  " .. arrow,
                    Font              = T.Semi,
                    TextSize          = 12,
                    TextColor3        = T.Text,
                    Size              = UDim2.new(1, 0, 0, 28),
                    Position          = UDim2.new(0, 0, 0, 20),
                    BackgroundColor3  = T.InputBG,
                    BorderSizePixel   = 0,
                    Parent            = wrap,
                }, { Corner(T.RadiusElem), Stroke(T.Border, 1) })

                -- Dropdown list (rendered above sibling frames via high ZIndex)
                local ddList = New("Frame", {
                    Name              = "DDList",
                    Size              = UDim2.new(1, 0, 0, 0),
                    Position          = UDim2.new(0, 0, 1, 4),
                    BackgroundColor3  = T.Surface,
                    BorderSizePixel   = 0,
                    ClipsDescendants  = true,
                    ZIndex            = 20,
                    Visible           = false,
                    Parent            = ddBtn,
                }, { Corner(T.RadiusElem), Stroke(T.BorderFocus, 1) })

                local ddLayout = New("UIListLayout", {
                    SortOrder         = Enum.SortOrder.LayoutOrder,
                    Padding           = UDim.new(0, 2),
                    Parent            = ddList,
                })
                Padding(4, 4, 4, 4).Parent = ddList

                for i, opt in ipairs(options) do
                    local ob = New("TextButton", {
                        Text              = opt,
                        Font              = T.Regular,
                        TextSize          = 12,
                        TextColor3        = T.Text,
                        Size              = UDim2.new(1, 0, 0, 26),
                        BackgroundColor3  = T.Card,
                        BackgroundTransparency = 1,
                        BorderSizePixel   = 0,
                        LayoutOrder       = i,
                        ZIndex            = 22,
                        Parent            = ddList,
                    }, { Corner(T.RadiusSmall) })

                    ob.MouseEnter:Connect(function()
                        Tween(ob, { BackgroundTransparency = 0.5, TextColor3 = T.AccentBright }, 0.1)
                    end)
                    ob.MouseLeave:Connect(function()
                        Tween(ob, { BackgroundTransparency = 1, TextColor3 = T.Text }, 0.1)
                    end)
                    ob.MouseButton1Click:Connect(function()
                        sel = opt
                        ddBtn.Text = sel .. "  " .. arrow
                        open = false
                        ddList.Visible = false
                        if callback then callback(sel) end
                    end)
                end

                ddBtn.MouseButton1Click:Connect(function()
                    open = not open
                    ddList.Visible = open
                    if open then
                        local h = math.min(ddLayout.AbsoluteContentSize.Y + 10, 140)
                        ddList.Size = UDim2.new(1, 0, 0, h)
                    end
                end)
            end

            -- ── Textbox ─────────────────────────
            function Card:Textbox(label, placeholder, callback)
                local wrap = New("Frame", {
                    Name              = label .. "_TB",
                    Size              = UDim2.new(1, 0, 0, 52),
                    BackgroundTransparency = 1,
                    LayoutOrder       = #cd.Elems + 1,
                    Parent            = cd.Body,
                })
                table.insert(cd.Elems, wrap)

                New("TextLabel", {
                    Text              = label,
                    Font              = T.Regular,
                    TextSize          = 12,
                    TextColor3        = T.TextSub,
                    Size              = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    Parent            = wrap,
                })

                local box = New("TextBox", {
                    PlaceholderText   = placeholder or "Type here…",
                    PlaceholderColor3 = T.TextMuted,
                    Text              = "",
                    Font              = T.Regular,
                    TextSize          = 12,
                    TextColor3        = T.Text,
                    Size              = UDim2.new(1, 0, 0, 28),
                    Position          = UDim2.new(0, 0, 0, 20),
                    BackgroundColor3  = T.InputBG,
                    BorderSizePixel   = 0,
                    ClearTextOnFocus  = false,
                    Parent            = wrap,
                }, { Corner(T.RadiusElem), Stroke(T.Border, 1), Padding(0, 0, 8, 8) })

                box.Focused:Connect(function()
                    Tween(box, { BackgroundColor3 = T.Surface }, 0.15)
                    -- find stroke child and recolor
                    for _, c in ipairs(box:GetChildren()) do
                        if c:IsA("UIStroke") then
                            Tween(c, { Color = T.BorderFocus }, 0.15)
                        end
                    end
                end)
                box.FocusLost:Connect(function(enter)
                    Tween(box, { BackgroundColor3 = T.InputBG }, 0.15)
                    for _, c in ipairs(box:GetChildren()) do
                        if c:IsA("UIStroke") then
                            Tween(c, { Color = T.Border }, 0.15)
                        end
                    end
                    if callback then callback(box.Text, enter) end
                end)
            end

            -- ── Label ────────────────────────────
            function Card:Label(text)
                New("TextLabel", {
                    Text              = text,
                    Font              = T.Regular,
                    TextSize          = 12,
                    TextColor3        = T.TextSub,
                    Size              = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    TextWrapped       = true,
                    LayoutOrder       = #cd.Elems + 1,
                    Parent            = cd.Body,
                })
            end

            -- ── Divider ──────────────────────────
            function Card:Divider()
                New("Frame", {
                    Name              = "Div",
                    Size              = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3  = T.Divider,
                    BorderSizePixel   = 0,
                    LayoutOrder       = #cd.Elems + 1,
                    Parent            = cd.Body,
                })
            end

            return Card
        end -- AddCard

        -- Add a label section header in sidebar
        function Tab:SidebarSection(text)
            New("TextLabel", {
                Text              = text:upper(),
                Font              = T.Bold,
                TextSize          = 10,
                TextColor3        = T.TextMuted,
                Size              = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                TextXAlignment    = Enum.TextXAlignment.Left,
                LayoutOrder       = #W._tabs + 0.5,
                Parent            = W.SidebarList,
            }, { Padding(4, 0, 10, 0) })
        end

        return Tab
    end -- AddTab

    -- ─────────────────────────────────────────
    --  Internal: Select Tab
    -- ─────────────────────────────────────────
    function W:_SelectTab(target)
        for _, t in ipairs(W._tabs) do
            local isTarget = (t == target)
            t.Active         = isTarget
            t.Scroll.Visible = isTarget
            Tween(t.Pill,  { BackgroundTransparency = isTarget and 0 or 1 }, 0.2)
            Tween(t.Label, { TextColor3 = isTarget and T.Text or T.TextMuted }, 0.2)
            Tween(t.Btn,   { BackgroundTransparency = isTarget and 0.88 or 1 }, 0.2)
        end
        W._active = target
    end

    -- ─────────────────────────────────────────
    --  Internal: Detach Card → Floating Window
    -- ─────────────────────────────────────────
    function W:_DetachCard(cd)
        if cd.Detached then return end
        cd.Detached = true

        local absPos = cd.Frame.AbsolutePosition

        -- ── Floating Container ─────────────────
        local fw = New("Frame", {
            Name              = cd.Title .. "_Float",
            Size              = UDim2.new(0, 250, 0, 0),
            Position          = UDim2.fromOffset(absPos.X + 20, absPos.Y - 20),
            BackgroundColor3  = T.FloatBG,
            BorderSizePixel   = 0,
            AutomaticSize     = Enum.AutomaticSize.Y,
            ZIndex            = 15,
            Parent            = W.GUI,
        }, { Corner(T.RadiusCard), Stroke(T.BorderFloat, 1.5) })

        -- Float shadow
        New("ImageLabel", {
            AnchorPoint       = Vector2.new(0.5, 0.5),
            Size              = UDim2.new(1, 50, 1, 50),
            Position          = UDim2.new(0.5, 0, 0.5, 6),
            BackgroundTransparency = 1,
            Image             = "rbxassetid://7912134082",
            ImageColor3       = T.Black,
            ImageTransparency = 0.5,
            ScaleType         = Enum.ScaleType.Slice,
            SliceCenter       = Rect.new(49, 49, 450, 450),
            ZIndex            = 14,
            Parent            = fw,
        })

        -- ── Float Header ───────────────────────
        local fh = New("Frame", {
            Size              = UDim2.new(1, 0, 0, 36),
            BackgroundColor3  = T.Header,
            BorderSizePixel   = 0,
            ZIndex            = 16,
            Parent            = fw,
        }, { Corner(T.RadiusCard) })
        RoundTop(fh, T.Header, 15)

        -- Accent bar
        New("Frame", {
            Size              = UDim2.new(0, 3, 0, 16),
            Position          = UDim2.new(0, 10, 0.5, -8),
            BackgroundColor3  = T.AccentBright,
            BorderSizePixel   = 0,
            ZIndex            = 17,
            Parent            = fh,
        }, { Corner(UDim.new(0, 2)) })

        New("TextLabel", {
            Text              = cd.Title,
            Font              = T.Semi,
            TextSize          = 13,
            TextColor3        = T.Text,
            Size              = UDim2.new(1, -76, 1, 0),
            Position          = UDim2.new(0, 22, 0, 0),
            BackgroundTransparency = 1,
            TextXAlignment    = Enum.TextXAlignment.Left,
            ZIndex            = 17,
            Parent            = fh,
        })

        -- Float collapse
        local fColBtn = New("TextButton", {
            Text              = "▾",
            Font              = T.Bold,
            TextSize          = 14,
            TextColor3        = T.TextMuted,
            Size              = UDim2.new(0, 28, 0, 28),
            Position          = UDim2.new(1, -60, 0.5, -14),
            BackgroundTransparency = 1,
            BorderSizePixel   = 0,
            ZIndex            = 18,
            Parent            = fh,
        })

        -- Float reattach / close
        local fClose = New("TextButton", {
            Text              = "×",
            Font              = T.Bold,
            TextSize          = 16,
            TextColor3        = T.TextMuted,
            Size              = UDim2.new(0, 28, 0, 28),
            Position          = UDim2.new(1, -30, 0.5, -14),
            BackgroundTransparency = 1,
            BorderSizePixel   = 0,
            ZIndex            = 18,
            Parent            = fh,
        })

        for _, b in ipairs({ fColBtn, fClose }) do
            b.MouseEnter:Connect(function()
                Tween(b, { TextColor3 = T.AccentBright }, 0.15)
            end)
            b.MouseLeave:Connect(function()
                Tween(b, { TextColor3 = T.TextMuted }, 0.15)
            end)
        end

        -- ── Float Body ─────────────────────────
        local fb = New("Frame", {
            Size              = UDim2.new(1, 0, 0, 0),
            Position          = UDim2.new(0, 0, 0, 36),
            BackgroundTransparency = 1,
            AutomaticSize     = Enum.AutomaticSize.Y,
            ZIndex            = 16,
            Parent            = fw,
        })
        New("UIListLayout", {
            SortOrder         = Enum.SortOrder.LayoutOrder,
            Padding           = UDim.new(0, 1),
            Parent            = fb,
        })
        Padding(6, 8, 10, 10).Parent = fb

        -- Transfer child elements to float body
        local transferred = {}
        for _, child in ipairs(cd.Body:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UILayout") and not child:IsA("UIPadding") then
                child.Parent = fb
                child.ZIndex = child.ZIndex + 10
                table.insert(transferred, child)
            end
        end

        -- Hide original card
        cd.Frame.Visible = false

        MakeDraggable(fw, fh)

        -- Float collapse
        local fCollapsed = false
        fColBtn.MouseButton1Click:Connect(function()
            fCollapsed = not fCollapsed
            fb.Visible = not fCollapsed
            Tween(fColBtn, { Rotation = fCollapsed and -90 or 0 }, 0.2)
        end)

        -- Reattach on close
        fClose.MouseButton1Click:Connect(function()
            -- Return elements
            for _, child in ipairs(transferred) do
                child.Parent = cd.Body
                child.ZIndex = child.ZIndex - 10
            end
            cd.Frame.Visible = true
            cd.Detached = false
            Tween(fw, { BackgroundTransparency = 1 }, 0.15)
            task.delay(0.15, function() fw:Destroy() end)
        end)
    end

    -- ─────────────────────────────────────────
    --  Convenience: toggle window visibility
    -- ─────────────────────────────────────────
    function W:Toggle()
        W.Win.Visible = not W.Win.Visible
    end

    -- Bind a key to toggle (optional)
    function W:BindToggle(key)
        UserInputService.InputBegan:Connect(function(inp, gpe)
            if gpe then return end
            if inp.KeyCode == key then
                W:Toggle()
            end
        end)
    end

    return W
end

return FlowLib

-- ─────────────────────────────────────────────────────────────
--  Example Usage (uncomment to test):
-- ─────────────────────────────────────────────────────────────
--[[
local Flow   = require(script.FlowLib)  -- or loadstring
local Window = Flow:CreateWindow("Flow", "@yourscript")
Window:BindToggle(Enum.KeyCode.RightShift)

local MainTab = Window:AddTab("Main")

local AimCard = MainTab:AddCard("Silent Aim")
AimCard:Toggle("Enabled",      false, function(v) print("Aim:", v) end)
AimCard:Toggle("Team Check",   true,  function(v) print("Team:", v) end)
AimCard:Toggle("Visible Check",false, function(v) print("Vis:", v) end)
AimCard:Dropdown("Target Part", {"Head","Torso","Left Arm","Right Arm"}, function(v) print("Part:", v) end)
AimCard:Slider("Hit Chance", 0, 100, 85, function(v) print("Chance:", v) end)

local AimbotCard = MainTab:AddCard("Aimbot")
AimbotCard:Toggle("Enabled",     false, function(v) print(v) end)
AimbotCard:Toggle("Team Check",  true,  function(v) print(v) end)
AimbotCard:Slider("Smoothness",  1, 20, 8, function(v) print("Smooth:", v) end)
AimbotCard:Button("Apply Preset", function() print("Applied!") end)

local MiscTab = Window:AddTab("Misc")
local ESPCard = MiscTab:AddCard("ESP Settings")
ESPCard:Toggle("Box ESP",    true,  function(v) print(v) end)
ESPCard:Toggle("Name ESP",   true,  function(v) print(v) end)
ESPCard:Toggle("Health Bar", false, function(v) print(v) end)
ESPCard:Slider("Max Distance", 0, 2000, 1000, function(v) print(v) end)
ESPCard:Divider()
ESPCard:Label("Changes apply on next render frame")

local ConfigCard = MiscTab:AddCard("Config")
ConfigCard:Textbox("Config Name", "e.g. MyConfig", function(t) print("Name:", t) end)
ConfigCard:Button("Save Config",  function() print("Saved!") end)
ConfigCard:Button("Load Config",  function() print("Loaded!") end)
]]
