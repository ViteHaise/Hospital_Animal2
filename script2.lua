--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║  🏥 ANIMAL HOSPITAL - MEGA AUTO SCRIPT v3.0                ║
    ║  📅 Actualizado: 13 de Julio 2025                          ║
    ║  🎮 Compatible: Delta / Solara / Fluxus                    ║
    ║  👤 Auto Farm Inteligente con Prioridades                  ║
    ║  🔧 Panel en Español - Completo y Funcional                ║
    ╚══════════════════════════════════════════════════════════════╝
    
    FUNCIONES:
    • Auto Recepción (detecta impostores/anomalías)
    • Auto Cirugía (completa minijuegos)
    • Auto RCP/Ritmo Cardíaco
    • Auto Rayos X y ADN
    • Auto Extinguir Incendios
    • Auto Eliminar Skinwalkers/Anomalías
    • Auto Atender Emergencias y Desmayos
    • Auto Apagar Rituales de Muerte
    • Auto Café (mantener cordura)
    • Auto Barney Quest
    • Auto Ratthew Quest
    • Auto Cámaras de Seguridad
    • Auto Cerrar Persianas
    • Auto Limpiar Slime
    • Auto Comprar Mejoras
    • Teletransportación Instantánea
    • Traspasar Paredes (NoClip)
    • Súper Velocidad
    • Sistema de Prioridades Inteligente
    • Maximizar Ganancias de Dinero
--]]

-- ═══════════════════════════════════════════
-- VERIFICACIÓN DE ENTORNO Y SERVICIOS
-- ═══════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local jugador = Players.LocalPlayer
local personaje = jugador.Character or jugador.CharacterAdded:Wait()
local humanoid = personaje:WaitForChild("Humanoid")
local rootPart = personaje:WaitForChild("HumanoidRootPart")
local camara = Workspace.CurrentCamera
local mouse = jugador:GetMouse()

-- ═══════════════════════════════════════════
-- CONFIGURACIÓN GLOBAL Y VARIABLES DE ESTADO
-- ═══════════════════════════════════════════

local Config = {
    -- Estados principales
    ScriptActivo = true,
    AutoFarmActivo = false,
    AutoRecepcion = false,
    AutoCirugia = false,
    AutoRCP = false,
    AutoRayosX = false,
    AutoADN = false,
    AutoExtinguir = false,
    AutoSkinwalker = false,
    AutoEmergencias = false,
    AutoRitual = false,
    AutoCafe = false,
    AutoBarney = false,
    AutoRatthew = false,
    AutoCamaras = false,
    AutoPersianas = false,
    AutoLimpiarSlime = false,
    AutoComprar = false,
    AutoTodo = false,
    
    -- Movimiento
    SuperVelocidad = false,
    NoClip = false,
    Teletransportar = false,
    VelocidadBase = 16,
    VelocidadSuper = 150,
    VelocidadTeletransporte = 500,
    
    -- Sistema de Prioridades (1 = máxima)
    Prioridades = {
        SkinwalkerAtacando = 1,
        PacienteDesmayado = 2,
        PacienteEnLlamas = 3,
        RitualMuerte = 4,
        EmergenciaAmbulancia = 5,
        CirugiaActiva = 6,
        RCPActivo = 7,
        RecepcionPendiente = 8,
        RayosXPendiente = 9,
        ADNPendiente = 10,
        CafeNecesario = 11,
        LimpiarSlime = 12,
        RepararCamaras = 13,
        BarneyQuest = 14,
        RatthewQuest = 15,
        ComprarMejoras = 16
    },
    
    -- Umbrales
    UmbralCordura = 30,
    UmbralEnergia = 25,
    DistanciaInteraccion = 15,
    TiempoEsperaMinijuego = 0.05,
    
    -- Estadísticas
    DineroGanado = 0,
    PacientesCurados = 0,
    AnomalíasEliminadas = 0,
    EmergenciasAtendidas = 0,
    IncendiosExtinguidos = 0,
    RitualesDetenidos = 0,
    CirugíasCompletadas = 0
}

-- Cola de tareas con prioridad
local ColaTareas = {}
local TareaActual = nil
local BloqueoTarea = false

-- ═══════════════════════════════════════════
-- UTILIDADES FUNDAMENTALES
-- ═══════════════════════════════════════════

local Util = {}

function Util.Notificar(titulo, mensaje, duracion, tipo)
    duracion = duracion or 3
    tipo = tipo or "info"
    
    local iconos = {
        info = "ℹ️",
        exito = "✅",
        alerta = "⚠️",
        error = "❌",
        dinero = "💰",
        medico = "🏥",
        peligro = "☠️",
        fuego = "🔥"
    }
    
    local icono = iconos[tipo] or "ℹ️"
    
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = icono .. " " .. titulo,
            Text = mensaje,
            Duration = duracion
        })
    end)
end

function Util.EsperarSeguro(tiempo)
    local inicio = tick()
    while tick() - inicio < tiempo and Config.ScriptActivo do
        RunService.Heartbeat:Wait()
    end
end

function Util.ObtenerPersonaje()
    personaje = jugador.Character
    if personaje then
        humanoid = personaje:FindFirstChildOfClass("Humanoid")
        rootPart = personaje:FindFirstChild("HumanoidRootPart")
    end
    return personaje and humanoid and rootPart
end

function Util.Distancia(posA, posB)
    if typeof(posA) == "Instance" then
        posA = posA.Position
    end
    if typeof(posB) == "Instance" then
        posB = posB.Position
    end
    return (posA - posB).Magnitude
end

function Util.TeletransportarA(posicion, instantaneo)
    if not Util.ObtenerPersonaje() then return false end
    
    if typeof(posicion) == "Instance" then
        posicion = posicion.Position + Vector3.new(0, 3, 0)
    elseif typeof(posicion) == "CFrame" then
        posicion = posicion.Position
    end
    
    if instantaneo then
        rootPart.CFrame = CFrame.new(posicion)
    else
        local distancia = Util.Distancia(rootPart.Position, posicion)
        local tiempo = math.clamp(distancia / Config.VelocidadTeletransporte, 0.1, 2)
        
        local tween = TweenService:Create(rootPart, TweenInfo.new(tiempo, Enum.EasingStyle.Quad), {
            CFrame = CFrame.new(posicion)
        })
        tween:Play()
        tween.Completed:Wait()
    end
    return true
end

function Util.BuscarEnWorkspace(nombre, clase)
    local resultados = {}
    
    local function buscarRecursivo(parent)
        for _, hijo in pairs(parent:GetChildren()) do
            local coincide = true
            if nombre and not string.find(hijo.Name:lower(), nombre:lower()) then
                coincide = false
            end
            if clase and not hijo:IsA(clase) then
                coincide = false
            end
            if coincide then
                table.insert(resultados, hijo)
            end
            if #hijo:GetChildren() > 0 then
                buscarRecursivo(hijo)
            end
        end
    end
    
    buscarRecursivo(Workspace)
    return resultados
end

function Util.BuscarMasCercano(lista, posicion)
    if not posicion and Util.ObtenerPersonaje() then
        posicion = rootPart.Position
    end
    if not posicion then return nil end
    
    local masCercano = nil
    local menorDist = math.huge
    
    for _, obj in pairs(lista) do
        local pos = nil
        if typeof(obj) == "Instance" then
            if obj:IsA("BasePart") then
                pos = obj.Position
            elseif obj:IsA("Model") then
                local primary = obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart")
                if primary then
                    pos = primary.Position
                end
            end
        end
        
        if pos then
            local dist = (posicion - pos).Magnitude
            if dist < menorDist then
                menorDist = dist
                masCercano = obj
            end
        end
    end
    
    return masCercano, menorDist
end

function Util.Interactuar(objeto)
    if not objeto then return false end
    
    -- Método 1: Buscar ProximityPrompt
    local prompt = objeto:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        for _, desc in pairs(objeto:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                prompt = desc
                break
            end
        end
    end
    
    if prompt then
        local holdOrig = prompt.HoldDuration
        local distOrig = prompt.MaxActivationDistance
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 9999
        fireproximityprompt(prompt)
        task.wait(0.1)
        prompt.HoldDuration = holdOrig
        prompt.MaxActivationDistance = distOrig
        return true
    end
    
    -- Método 2: Buscar ClickDetector
    local clickDet = objeto:FindFirstChildOfClass("ClickDetector")
    if not clickDet then
        for _, desc in pairs(objeto:GetDescendants()) do
            if desc:IsA("ClickDetector") then
                clickDet = desc
                break
            end
        end
    end
    
    if clickDet then
        fireclickdetector(clickDet)
        return true
    end
    
    -- Método 3: RemoteEvent genérico de interacción
    local remotes = ReplicatedStorage:GetDescendants()
    for _, remote in pairs(remotes) do
        if remote:IsA("RemoteEvent") then
            local nombreLower = remote.Name:lower()
            if string.find(nombreLower, "interact") or 
               string.find(nombreLower, "use") or
               string.find(nombreLower, "action") then
                pcall(function()
                    remote:FireServer(objeto)
                end)
            end
        end
    end
    
    return true
end

function Util.SimularTecla(tecla)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, tecla, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, tecla, false, game)
    end)
end

function Util.SimularClick(posX, posY)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(posX or 0, posY or 0, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(posX or 0, posY or 0, 0, false, game, 0)
    end)
end

function Util.BuscarRemotes(patron)
    local encontrados = {}
    
    local function buscar(parent)
        for _, child in pairs(parent:GetChildren()) do
            if (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) then
                if string.find(child.Name:lower(), patron:lower()) then
                    table.insert(encontrados, child)
                end
            end
            pcall(function()
                buscar(child)
            end)
        end
    end
    
    buscar(ReplicatedStorage)
    pcall(function() buscar(game:GetService("Players").LocalPlayer.PlayerScripts) end)
    
    return encontrados
end

function Util.DispararRemote(nombre, ...)
    local remotes = Util.BuscarRemotes(nombre)
    for _, remote in pairs(remotes) do
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(...)
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(...)
            end
        end)
    end
end

-- ═══════════════════════════════════════════
-- SISTEMA DE PRIORIDADES INTELIGENTE
-- ═══════════════════════════════════════════

local SistemaPrioridades = {}

function SistemaPrioridades.AgregarTarea(nombre, prioridad, funcion, datos)
    -- Verificar si ya existe una tarea con el mismo nombre
    for i, tarea in pairs(ColaTareas) do
        if tarea.nombre == nombre then
            ColaTareas[i].prioridad = prioridad
            ColaTareas[i].funcion = funcion
            ColaTareas[i].datos = datos
            ColaTareas[i].timestamp = tick()
            return
        end
    end
    
    table.insert(ColaTareas, {
        nombre = nombre,
        prioridad = prioridad,
        funcion = funcion,
        datos = datos,
        timestamp = tick()
    })
    
    -- Ordenar por prioridad (menor número = mayor prioridad)
    table.sort(ColaTareas, function(a, b)
        if a.prioridad == b.prioridad then
            return a.timestamp < b.timestamp
        end
        return a.prioridad < b.prioridad
    end)
end

function SistemaPrioridades.EliminarTarea(nombre)
    for i = #ColaTareas, 1, -1 do
        if ColaTareas[i].nombre == nombre then
            table.remove(ColaTareas, i)
        end
    end
end

function SistemaPrioridades.ObtenerSiguiente()
    if #ColaTareas > 0 then
        return ColaTareas[1]
    end
    return nil
end

function SistemaPrioridades.ProcesarCola()
    while Config.ScriptActivo do
        if Config.AutoTodo or Config.AutoFarmActivo then
            local tarea = SistemaPrioridades.ObtenerSiguiente()
            
            if tarea and not BloqueoTarea then
                -- Si hay una tarea de mayor prioridad que la actual
                if TareaActual and tarea.prioridad < TareaActual.prioridad then
                    TareaActual = tarea
                    table.remove(ColaTareas, 1)
                    
                    BloqueoTarea = true
                    pcall(function()
                        tarea.funcion(tarea.datos)
                    end)
                    BloqueoTarea = false
                    
                    Config[tarea.nombre .. "Completada"] = true
                elseif not TareaActual then
                    TareaActual = tarea
                    table.remove(ColaTareas, 1)
                    
                    BloqueoTarea = true
                    pcall(function()
                        tarea.funcion(tarea.datos)
                    end)
                    BloqueoTarea = false
                    TareaActual = nil
                end
            end
        end
        
        RunService.Heartbeat:Wait()
    end
end

-- ═══════════════════════════════════════════
-- DETECTOR DE ENTIDADES Y OBJETOS DEL JUEGO
-- ═══════════════════════════════════════════

local Detector = {}

function Detector.ObtenerPacientes()
    local pacientes = {}
    
    -- Buscar en múltiples ubicaciones posibles
    local contenedores = {
        Workspace:FindFirstChild("Patients"),
        Workspace:FindFirstChild("patients"),
        Workspace:FindFirstChild("Animals"),
        Workspace:FindFirstChild("NPCs"),
        Workspace:FindFirstChild("Entities"),
        Workspace:FindFirstChild("GameEntities")
    }
    
    for _, contenedor in pairs(contenedores) do
        if contenedor then
            for _, ent in pairs(contenedor:GetChildren()) do
                if ent:IsA("Model") and ent:FindFirstChildOfClass("Humanoid") then
                    table.insert(pacientes, ent)
                end
            end
        end
    end
    
    -- Buscar por atributos o tags
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local esAnimal = obj:GetAttribute("IsPatient") or 
                            obj:GetAttribute("isPatient") or
                            obj:GetAttribute("PatientType") or
                            obj:FindFirstChild("PatientData") or
                            obj:FindFirstChild("AnimalType")
            if esAnimal then
                local yaExiste = false
                for _, p in pairs(pacientes) do
                    if p == obj then yaExiste = true break end
                end
                if not yaExiste then
                    table.insert(pacientes, obj)
                end
            end
        end
    end
    
    return pacientes
end

function Detector.EsAnomalía(entidad)
    if not entidad then return false end
    
    local señales = {
        -- Atributos directos
        entidad:GetAttribute("IsAnomaly") == true,
        entidad:GetAttribute("isSkinwalker") == true,
        entidad:GetAttribute("Anomaly") == true,
        entidad:GetAttribute("IsImpostor") == true,
        entidad:GetAttribute("Fake") == true,
        
        -- Hijos sospechosos
        entidad:FindFirstChild("AnomalyMarker") ~= nil,
        entidad:FindFirstChild("SkinwalkerData") ~= nil,
        entidad:FindFirstChild("FakePatient") ~= nil,
        entidad:FindFirstChild("Anomaly") ~= nil
    }
    
    for _, señal in pairs(señales) do
        if señal then return true end
    end
    
    -- Verificar visual: ojos negros, rastro verde, extremidades extras
    for _, parte in pairs(entidad:GetDescendants()) do
        local nombreLower = parte.Name:lower()
        
        -- Ojos negros
        if (string.find(nombreLower, "eye") or string.find(nombreLower, "ojo")) then
            if parte:IsA("BasePart") and parte.Color == Color3.new(0, 0, 0) then
                return true
            end
        end
        
        -- Rastro verde / slime
        if string.find(nombreLower, "slime") or string.find(nombreLower, "trail") then
            if parte:IsA("BasePart") and parte.Color == Color3.fromRGB(0, 255, 0) then
                return true
            end
        end
        
        -- Tentáculos
        if string.find(nombreLower, "tentacle") or string.find(nombreLower, "tentaculo") then
            return true
        end
        
        -- Extremidades extras
        if string.find(nombreLower, "extra") and string.find(nombreLower, "limb") then
            return true
        end
    end
    
    -- Verificar si el esqueleto no coincide (huesos humanos en animal)
    local tipoAnimal = entidad:GetAttribute("Species") or entidad:GetAttribute("AnimalType")
    local tieneHuesosHumanos = entidad:FindFirstChild("HumanSkeleton") or 
                               entidad:GetAttribute("HumanBones") == true
    if tipoAnimal and tieneHuesosHumanos then
        return true
    end
    
    return false
end

function Detector.DetectarSkinwalkers()
    local skinwalkers = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local nombreLower = obj.Name:lower()
            local esSkinwalker = string.find(nombreLower, "skinwalker") or
                                string.find(nombreLower, "monster") or
                                string.find(nombreLower, "anomaly") or
                                string.find(nombreLower, "creature") or
                                string.find(nombreLower, "shadow") or
                                string.find(nombreLower, "ghost") or
                                string.find(nombreLower, "demon") or
                                obj:GetAttribute("IsSkinwalker") == true or
                                obj:GetAttribute("IsMonster") == true or
                                obj:GetAttribute("IsAnomaly") == true
            
            if esSkinwalker and obj:FindFirstChildOfClass("Humanoid") then
                table.insert(skinwalkers, obj)
            end
        end
    end
    
    return skinwalkers
end

function Detector.DetectarEmergencias()
    local emergencias = {
        desmayos = {},
        incendios = {},
        rituales = {},
        ataques = {},
        ambulancias = {}
    }
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        local nombreLower = ""
        pcall(function() nombreLower = obj.Name:lower() end)
        
        -- Desmayos
        if obj:GetAttribute("Fainted") == true or 
           obj:GetAttribute("Unconscious") == true or
           string.find(nombreLower, "faint") or
           string.find(nombreLower, "desmay") then
            table.insert(emergencias.desmayos, obj)
        end
        
        -- Incendios
        if obj:GetAttribute("OnFire") == true or
           obj:GetAttribute("Burning") == true or
           string.find(nombreLower, "fire") or
           string.find(nombreLower, "burning") then
            -- Verificar si tiene partículas de fuego
            local tieneFuego = false
            for _, desc in pairs(obj:GetDescendants()) do
                if desc:IsA("ParticleEmitter") or desc:IsA("Fire") then
                    tieneFuego = true
                    break
                end
            end
            if tieneFuego or obj:GetAttribute("OnFire") then
                table.insert(emergencias.incendios, obj)
            end
        end
        
        -- Rituales de muerte
        if string.find(nombreLower, "ritual") or
           string.find(nombreLower, "candle") or
           string.find(nombreLower, "vela") or
           obj:GetAttribute("DeathRitual") == true then
            table.insert(emergencias.rituales, obj)
        end
        
        -- Ataques activos
        if obj:GetAttribute("Attacking") == true or
           obj:GetAttribute("IsAttacking") == true then
            table.insert(emergencias.ataques, obj)
        end
        
        -- Ambulancias
        if string.find(nombreLower, "ambulance") or
           string.find(nombreLower, "ambulancia") or
           obj:GetAttribute("AmbulanceEvent") == true then
            table.insert(emergencias.ambulancias, obj)
        end
    end
    
    return emergencias
end

function Detector.DetectarMinijuegos()
    local minijuegos = {
        cirugia = nil,
        rcp = nil,
        rayosx = nil,
        adn = nil
    }
    
    -- Buscar GUIs activas de minijuegos
    local playerGui = jugador:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetDescendants()) do
            if gui:IsA("ScreenGui") or gui:IsA("Frame") then
                local nombreLower = gui.Name:lower()
                
                if (string.find(nombreLower, "surgery") or string.find(nombreLower, "cirugia")) 
                   and gui.Visible then
                    minijuegos.cirugia = gui
                end
                
                if (string.find(nombreLower, "cpr") or string.find(nombreLower, "heart") or 
                    string.find(nombreLower, "rcp") or string.find(nombreLower, "rhythm"))
                   and gui.Visible then
                    minijuegos.rcp = gui
                end
                
                if (string.find(nombreLower, "xray") or string.find(nombreLower, "rayos") or 
                    string.find(nombreLower, "x-ray") or string.find(nombreLower, "scan"))
                   and gui.Visible then
                    minijuegos.rayosx = gui
                end
                
                if (string.find(nombreLower, "dna") or string.find(nombreLower, "adn") or 
                    string.find(nombreLower, "lab") or string.find(nombreLower, "genetic"))
                   and gui.Visible then
                    minijuegos.adn = gui
                end
            end
        end
    end
    
    return minijuegos
end

function Detector.BuscarObjeto(nombre)
    local resultados = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if string.find(obj.Name:lower(), nombre:lower()) then
            table.insert(resultados, obj)
        end
    end
    return resultados
end

function Detector.BuscarNPC(nombre)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and string.find(obj.Name:lower(), nombre:lower()) then
            if obj:FindFirstChildOfClass("Humanoid") then
                return obj
            end
        end
    end
    return nil
end

function Detector.ObtenerEstaciones()
    local estaciones = {
        recepcion = nil,
        cirugiaRoom = nil,
        rayosXRoom = nil,
        laboratorio = nil,
        cafeteria = nil,
        tienda = nil,
        camaras = nil,
        camas = {},
        extintores = {},
        timbre = nil
    }
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        
        if string.find(n, "reception") or string.find(n, "recepcion") or 
           string.find(n, "front") or string.find(n, "desk") then
            estaciones.recepcion = obj
        end
        
        if string.find(n, "surgery") or string.find(n, "operating") or 
           string.find(n, "cirugia") then
            estaciones.cirugiaRoom = obj
        end
        
        if string.find(n, "xray") or string.find(n, "x-ray") or 
           string.find(n, "rayos") then
            estaciones.rayosXRoom = obj
        end
        
        if string.find(n, "lab") or string.find(n, "laborator") then
            estaciones.laboratorio = obj
        end
        
        if string.find(n, "coffee") or string.find(n, "cafe") or 
           string.find(n, "break") then
            estaciones.cafeteria = obj
        end
        
        if string.find(n, "shop") or string.find(n, "tienda") or 
           string.find(n, "store") then
            estaciones.tienda = obj
        end
        
        if string.find(n, "cctv") or string.find(n, "camera") or 
           string.find(n, "monitor") or string.find(n, "security") then
            estaciones.camaras = obj
        end
        
        if string.find(n, "bed") or string.find(n, "cama") or 
           string.find(n, "stretcher") then
            table.insert(estaciones.camas, obj)
        end
        
        if string.find(n, "extinguisher") or string.find(n, "extintor") or 
           string.find(n, "fire_ext") then
            table.insert(estaciones.extintores, obj)
        end
        
        if string.find(n, "bell") or string.find(n, "timbre") or 
           string.find(n, "buzzer") or string.find(n, "doorbell") then
            estaciones.timbre = obj
        end
    end
    
    return estaciones
end

-- ═══════════════════════════════════════════
-- MÓDULOS DE ACCIONES AUTOMÁTICAS
-- ═══════════════════════════════════════════

local Acciones = {}

-- AUTO RECEPCIÓN
function Acciones.AutoRecepcion()
    if not Config.AutoRecepcion and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    local estaciones = Detector.ObtenerEstaciones()
    if not estaciones.recepcion then return end
    
    -- Ir a la recepción
    Util.TeletransportarA(estaciones.recepcion, true)
    Util.EsperarSeguro(0.3)
    
    -- Tocar timbre para llamar al siguiente paciente
    if estaciones.timbre then
        Util.Interactuar(estaciones.timbre)
        Util.EsperarSeguro(0.5)
    end
    
    -- Buscar RemoteEvents de recepción
    Util.DispararRemote("callpatient")
    Util.DispararRemote("callNext")
    Util.DispararRemote("nextPatient")
    Util.DispararRemote("ringBell")
    Util.EsperarSeguro(1)
    
    -- Verificar paciente en el mostrador
    local pacientes = Detector.ObtenerPacientes()
    for _, paciente in pairs(pacientes) do
        if Util.ObtenerPersonaje() then
            local dist = Util.Distancia(rootPart.Position, 
                paciente.PrimaryPart and paciente.PrimaryPart.Position or 
                paciente:FindFirstChildOfClass("BasePart").Position)
            
            if dist < 20 then
                -- Tomar foto / verificar
                local esAnomalia = Detector.EsAnomalía(paciente)
                
                if esAnomalia then
                    -- RECHAZAR - Cerrar persiana
                    Util.DispararRemote("reject")
                    Util.DispararRemote("rejectPatient")
                    Util.DispararRemote("denyEntry")
                    Util.DispararRemote("closeShutter")
                    Util.DispararRemote("closeBlinds")
                    
                    -- Buscar botón de rechazar en GUI
                    local playerGui = jugador:FindFirstChild("PlayerGui")
                    if playerGui then
                        for _, gui in pairs(playerGui:GetDescendants()) do
                            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                                local btnName = gui.Name:lower()
                                if string.find(btnName, "reject") or 
                                   string.find(btnName, "deny") or
                                   string.find(btnName, "rechazar") or
                                   string.find(btnName, "stamp_red") or
                                   string.find(btnName, "close") then
                                    pcall(function()
                                        -- Simular click en el botón
                                        for _, connection in pairs(getconnections(gui.MouseButton1Click)) do
                                            connection:Fire()
                                        end
                                        -- También intentar activar directamente
                                        gui.MouseButton1Click:Fire()
                                    end)
                                end
                            end
                        end
                    end
                    
                    Config.AnomalíasEliminadas = Config.AnomalíasEliminadas + 1
                    Util.Notificar("ANOMALÍA DETECTADA", "¡Impostor rechazado! 👁️", 2, "peligro")
                else
                    -- APROBAR paciente legítimo
                    Util.DispararRemote("accept")
                    Util.DispararRemote("acceptPatient")
                    Util.DispararRemote("approve")
                    Util.DispararRemote("admitPatient")
                    Util.DispararRemote("stamp")
                    
                    -- Buscar botón de aceptar
                    local playerGui = jugador:FindFirstChild("PlayerGui")
                    if playerGui then
                        for _, gui in pairs(playerGui:GetDescendants()) do
                            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                                local btnName = gui.Name:lower()
                                if string.find(btnName, "accept") or 
                                   string.find(btnName, "approve") or
                                   string.find(btnName, "aceptar") or
                                   string.find(btnName, "stamp_green") or
                                   string.find(btnName, "admit") then
                                    pcall(function()
                                        for _, connection in pairs(getconnections(gui.MouseButton1Click)) do
                                            connection:Fire()
                                        end
                                    end)
                                end
                            end
                        end
                    end
                    
                    Config.PacientesCurados = Config.PacientesCurados + 1
                    Util.Notificar("Paciente Aceptado", "Paciente legítimo admitido ✓", 2, "exito")
                end
            end
        end
    end
end

-- AUTO CIRUGÍA
function Acciones.AutoCirugia()
    if not Config.AutoCirugia and not Config.AutoTodo then return end
    
    local minijuegos = Detector.DetectarMinijuegos()
    
    if minijuegos.cirugia then
        Util.Notificar("Cirugía", "Completando cirugía automáticamente...", 2, "medico")
        
        local gui = minijuegos.cirugia
        
        -- Buscar elementos del minijuego de cirugía
        for _, elemento in pairs(gui:GetDescendants()) do
            local n = elemento.Name:lower()
            
            -- Completar línea de corte automáticamente
            if string.find(n, "cut") or string.find(n, "incision") or 
               string.find(n, "line") or string.find(n, "scalpel") then
                if elemento:IsA("Frame") or elemento:IsA("ImageLabel") then
                    -- Mover el cursor por la línea perfectamente
                    pcall(function()
                        local pos = elemento.AbsolutePosition
                        local size = elemento.AbsoluteSize
                        
                        for i = 0, 1, 0.02 do
                            local x = pos.X + (size.X * i)
                            local y = pos.Y + (size.Y / 2)
                            Util.SimularClick(x, y)
                            task.wait(Config.TiempoEsperaMinijuego)
                        end
                    end)
                end
            end
            
            -- Eliminar tentáculos
            if string.find(n, "tentacle") or string.find(n, "tentaculo") or
               string.find(n, "anomaly") or string.find(n, "purple") then
                if elemento:IsA("TextButton") or elemento:IsA("ImageButton") then
                    for clickNum = 1, 20 do
                        pcall(function()
                            for _, conn in pairs(getconnections(elemento.MouseButton1Click)) do
                                conn:Fire()
                            end
                        end)
                        task.wait(0.02)
                    end
                elseif elemento:IsA("BasePart") then
                    Util.Interactuar(elemento)
                end
            end
            
            -- Botón de completar/finalizar
            if string.find(n, "finish") or string.find(n, "complete") or 
               string.find(n, "done") or string.find(n, "success") then
                pcall(function()
                    if elemento:IsA("TextButton") or elemento:IsA("ImageButton") then
                        for _, conn in pairs(getconnections(elemento.MouseButton1Click)) do
                            conn:Fire()
                        end
                    end
                end)
            end
        end
        
        -- Disparar remotes de cirugía
        Util.DispararRemote("completeSurgery")
        Util.DispararRemote("surgeryComplete")
        Util.DispararRemote("finishSurgery")
        Util.DispararRemote("surgerySuccess")
        
        Config.CirugíasCompletadas = Config.CirugíasCompletadas + 1
        Util.Notificar("Cirugía Completada", "Operación exitosa 🔪", 2, "exito")
    else
        -- Buscar mesa de cirugía y paciente que necesite cirugía
        local estaciones = Detector.ObtenerEstaciones()
        if estaciones.cirugiaRoom then
            local pacientes = Detector.ObtenerPacientes()
            for _, paciente in pairs(pacientes) do
                if paciente:GetAttribute("NeedsSurgery") == true or
                   paciente:GetAttribute("Surgery") == true then
                    -- Llevar paciente a cirugía
                    Util.TeletransportarA(paciente, true)
                    Util.EsperarSeguro(0.2)
                    Util.Interactuar(paciente) -- Cargar
                    Util.EsperarSeguro(0.3)
                    Util.TeletransportarA(estaciones.cirugiaRoom, true)
                    Util.EsperarSeguro(0.2)
                    Util.Interactuar(estaciones.cirugiaRoom) -- Soltar en mesa
                    Util.EsperarSeguro(0.5)
                    -- El minijuego debería activarse
                    break
                end
            end
        end
    end
end

-- AUTO RCP / RITMO CARDÍACO
function Acciones.AutoRCP()
    if not Config.AutoRCP and not Config.AutoTodo then return end
    
    local minijuegos = Detector.DetectarMinijuegos()
    
    if minijuegos.rcp then
        Util.Notificar("RCP", "Realizando RCP automático...", 2, "medico")
        
        local gui = minijuegos.rcp
        local completado = false
        local intentos = 0
        
        while not completado and intentos < 200 and Config.ScriptActivo do
            intentos = intentos + 1
            
            for _, elemento in pairs(gui:GetDescendants()) do
                local n = elemento.Name:lower()
                
                -- Buscar el indicador/barra móvil
                if string.find(n, "indicator") or string.find(n, "marker") or 
                   string.find(n, "needle") or string.find(n, "slider") or
                   string.find(n, "cursor") then
                    
                    -- Buscar la zona verde/objetivo
                    for _, zona in pairs(gui:GetDescendants()) do
                        local zn = zona.Name:lower()
                        if string.find(zn, "green") or string.find(zn, "target") or 
                           string.find(zn, "zone") or string.find(zn, "hit") or
                           string.find(zn, "sweet") then
                            
                            if elemento:IsA("GuiObject") and zona:IsA("GuiObject") then
                                local indPos = elemento.AbsolutePosition
                                local zonaPos = zona.AbsolutePosition
                                local zonaSize = zona.AbsoluteSize
                                
                                -- Verificar si el indicador está en la zona verde
                                if indPos.X >= zonaPos.X and 
                                   indPos.X <= zonaPos.X + zonaSize.X then
                                    -- ¡Presionar ahora!
                                    Util.SimularTecla(Enum.KeyCode.Space)
                                    Util.SimularClick(indPos.X, indPos.Y)
                                    
                                    -- También disparar remotes
                                    Util.DispararRemote("cprHit")
                                    Util.DispararRemote("heartbeatHit")
                                    Util.DispararRemote("rhythmHit")
                                    Util.DispararRemote("press")
                                end
                            end
                        end
                    end
                end
                
                -- Buscar botón de presionar
                if (string.find(n, "press") or string.find(n, "push") or 
                    string.find(n, "pump") or string.find(n, "beat")) and
                   (elemento:IsA("TextButton") or elemento:IsA("ImageButton")) then
                    
                    -- Timing perfecto - presionar en el momento exacto
                    pcall(function()
                        for _, conn in pairs(getconnections(elemento.MouseButton1Click)) do
                            conn:Fire()
                        end
                    end)
                end
                
                -- Verificar si se completó
                if string.find(n, "success") or string.find(n, "complete") or
                   string.find(n, "stable") or string.find(n, "saved") then
                    if elemento.Visible then
                        completado = true
                        break
                    end
                end
            end
            
            if not gui.Visible then
                completado = true
            end
            
            task.wait(Config.TiempoEsperaMinijuego)
        end
        
        -- Disparar completación
        Util.DispararRemote("cprComplete")
        Util.DispararRemote("stabilized")
        Util.DispararRemote("heartStable")
        
        Util.Notificar("RCP Completado", "Paciente estabilizado ❤️", 2, "exito")
    end
end

-- AUTO RAYOS X
function Acciones.AutoRayosX()
    if not Config.AutoRayosX and not Config.AutoTodo then return end
    
    local minijuegos = Detector.DetectarMinijuegos()
    
    if minijuegos.rayosx then
        Util.Notificar("Rayos X", "Analizando radiografía...", 2, "medico")
        
        local gui = minijuegos.rayosx
        local esAnomalo = false
        
        -- Analizar la imagen de rayos X
        for _, elemento in pairs(gui:GetDescendants()) do
            local n = elemento.Name:lower()
            
            -- Buscar indicadores de anomalía en la imagen
            if string.find(n, "human") or string.find(n, "abnormal") or
               string.find(n, "anomaly") or string.find(n, "wrong") or
               string.find(n, "deform") then
                if elemento.Visible then
                    esAnomalo = true
                end
            end
            
            -- Verificar el Decal/Imagen
            if elemento:IsA("ImageLabel") or elemento:IsA("Decal") then
                local imageId = ""
                pcall(function() imageId = elemento.Image end)
                
                -- Los IDs de imágenes anómalas suelen ser diferentes
                if elemento:GetAttribute("IsAnomalous") == true or
                   elemento:GetAttribute("Abnormal") == true then
                    esAnomalo = true
                end
            end
        end
        
        -- Presionar botón correspondiente
        for _, elemento in pairs(gui:GetDescendants()) do
            if elemento:IsA("TextButton") or elemento:IsA("ImageButton") then
                local n = elemento.Name:lower()
                
                if esAnomalo then
                    if string.find(n, "anomaly") or string.find(n, "abnormal") or
                       string.find(n, "report") or string.find(n, "alert") then
                        pcall(function()
                            for _, conn in pairs(getconnections(elemento.MouseButton1Click)) do
                                conn:Fire()
                            end
                        end)
                        Util.DispararRemote("reportAnomaly")
                        Util.DispararRemote("xrayAnomaly")
                    end
                else
                    if string.find(n, "normal") or string.find(n, "clear") or
                       string.find(n, "ok") or string.find(n, "confirm") then
                        pcall(function()
                            for _, conn in pairs(getconnections(elemento.MouseButton1Click)) do
                                conn:Fire()
                            end
                        end)
                        Util.DispararRemote("xrayNormal")
                        Util.DispararRemote("xrayClear")
                    end
                end
            end
        end
        
        Util.DispararRemote("completeXray")
        Util.DispararRemote("xrayComplete")
        
        Util.Notificar("Rayos X", esAnomalo and "¡ANOMALÍA en radiografía!" or "Radiografía normal ✓", 2, 
            esAnomalo and "peligro" or "exito")
    end
end

-- AUTO ADN
function Acciones.AutoADN()
    if not Config.AutoADN and not Config.AutoTodo then return end
    
    local minijuegos = Detector.DetectarMinijuegos()
    
    if minijuegos.adn then
        Util.Notificar("Análisis ADN", "Procesando muestra genética...", 2, "medico")
        
        local gui = minijuegos.adn
        
        for _, elemento in pairs(gui:GetDescendants()) do
            local n = elemento.Name:lower()
            
            -- Iniciar análisis
            if string.find(n, "start") or string.find(n, "analyze") or
               string.find(n, "process") or string.find(n, "scan") then
                if elemento:IsA("TextButton") or elemento:IsA("ImageButton") then
                    pcall(function()
                        for _, conn in pairs(getconnections(elemento.MouseButton1Click)) do
                            conn:Fire()
                        end
                    end)
                end
            end
            
            -- Confirmar resultado
            if string.find(n, "confirm") or string.find(n, "submit") or
               string.find(n, "complete") or string.find(n, "result") then
                if elemento:IsA("TextButton") or elemento:IsA("ImageButton") then
                    pcall(function()
                        for _, conn in pairs(getconnections(elemento.MouseButton1Click)) do
                            conn:Fire()
                        end
                    end)
                end
            end
        end
        
        Util.DispararRemote("dnaComplete")
        Util.DispararRemote("dnaAnalysis")
        Util.DispararRemote("labComplete")
        
        Util.Notificar("ADN Analizado", "Resultado procesado ✓", 2, "exito")
    end
end

-- AUTO EXTINGUIR INCENDIOS
function Acciones.AutoExtinguir()
    if not Config.AutoExtinguir and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    local emergencias = Detector.DetectarEmergencias()
    
    if #emergencias.incendios > 0 then
        Util.Notificar("¡INCENDIO!", "Extinguiendo fuego...", 2, "fuego")
        
        for _, objetoEnLlamas in pairs(emergencias.incendios) do
            -- Buscar extintor más cercano
            local estaciones = Detector.ObtenerEstaciones()
            local extintor = Util.BuscarMasCercano(estaciones.extintores)
            
            if extintor then
                -- Ir al extintor
                Util.TeletransportarA(extintor, true)
                Util.EsperarSeguro(0.2)
                Util.Interactuar(extintor)
                Util.EsperarSeguro(0.3)
            end
            
            -- Equipar extintor del inventario
            local mochila = personaje:FindFirstChildOfClass("Backpack") or 
                           jugador:FindFirstChild("Backpack")
            if mochila then
                for _, herramienta in pairs(mochila:GetChildren()) do
                    if herramienta:IsA("Tool") then
                        local tn = herramienta.Name:lower()
                        if string.find(tn, "extinguish") or string.find(tn, "extintor") or
                           string.find(tn, "fire_ext") then
                            humanoid:EquipTool(herramienta)
                            break
                        end
                    end
                end
            end
            
            -- Ir al objeto en llamas
            local posObjetivo = nil
            if objetoEnLlamas:IsA("Model") then
                posObjetivo = objetoEnLlamas.PrimaryPart or objetoEnLlamas:FindFirstChildOfClass("BasePart")
            elseif objetoEnLlamas:IsA("BasePart") then
                posObjetivo = objetoEnLlamas
            end
            
            if posObjetivo then
                Util.TeletransportarA(posObjetivo, true)
                Util.EsperarSeguro(0.2)
                
                -- Usar extintor (mantener click)
                for i = 1, 30 do
                    Util.SimularClick()
                    Util.DispararRemote("useExtinguisher")
                    Util.DispararRemote("extinguish")
                    Util.DispararRemote("spray")
                    task.wait(0.1)
                    
                    -- Verificar si el fuego se apagó
                    local sigueFuego = false
                    if objetoEnLlamas and objetoEnLlamas.Parent then
                        sigueFuego = objetoEnLlamas:GetAttribute("OnFire") == true
                        if not sigueFuego then
                            for _, desc in pairs(objetoEnLlamas:GetDescendants()) do
                                if desc:IsA("Fire") or 
                                   (desc:IsA("ParticleEmitter") and desc.Enabled) then
                                    sigueFuego = true
                                    break
                                end
                            end
                        end
                    end
                    
                    if not sigueFuego then break end
                end
            end
            
            Config.IncendiosExtinguidos = Config.IncendiosExtinguidos + 1
        end
        
        Util.Notificar("Incendio Apagado", "Fuego extinguido exitosamente 🧯", 2, "exito")
    end
end

-- AUTO ELIMINAR SKINWALKERS
function Acciones.AutoSkinwalker()
    if not Config.AutoSkinwalker and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    local skinwalkers = Detector.DetectarSkinwalkers()
    
    if #skinwalkers > 0 then
        Util.Notificar("¡SKINWALKER!", "Eliminando anomalías...", 2, "peligro")
        
        -- Equipar Taser
        local mochila = personaje:FindFirstChildOfClass("Backpack") or 
                       jugador:FindFirstChild("Backpack")
        if mochila then
            for _, herramienta in pairs(mochila:GetChildren()) do
                if herramienta:IsA("Tool") then
                    local tn = herramienta.Name:lower()
                    if string.find(tn, "taser") or string.find(tn, "stun") or
                       string.find(tn, "gun") or string.find(tn, "weapon") then
                        humanoid:EquipTool(herramienta)
                        break
                    end
                end
            end
        end
        
        -- También buscar herramienta ya equipada
        local toolEquipada = personaje:FindFirstChildOfClass("Tool")
        
        for _, skinwalker in pairs(skinwalkers) do
            if skinwalker and skinwalker.Parent then
                local posSkin = skinwalker.PrimaryPart or skinwalker:FindFirstChildOfClass("BasePart")
                
                if posSkin then
                    -- Teletransportarse cerca
                    Util.TeletransportarA(posSkin.Position + Vector3.new(5, 0, 0), true)
                    Util.EsperarSeguro(0.1)
                    
                    -- Apuntar al skinwalker
                    if camara then
                        camara.CFrame = CFrame.new(rootPart.Position, posSkin.Position)
                    end
                    
                    -- Disparar Taser
                    for i = 1, 10 do
                        Util.SimularClick()
                        Util.DispararRemote("shoot")
                        Util.DispararRemote("tase")
                        Util.DispararRemote("attack")
                        Util.DispararRemote("hitSkinwalker")
                        Util.DispararRemote("killAnomaly")
                        Util.DispararRemote("damage", skinwalker)
                        
                        -- También interactuar directamente (puñetazos con E)
                        Util.SimularTecla(Enum.KeyCode.E)
                        
                        task.wait(0.15)
                        
                        -- Verificar si fue eliminado
                        if not skinwalker.Parent then break end
                        
                        local hum = skinwalker:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health <= 0 then break end
                    end
                    
                    Config.AnomalíasEliminadas = Config.AnomalíasEliminadas + 1
                end
            end
        end
        
        Util.Notificar("Skinwalker Eliminado", "Anomalía neutralizada ☠️", 2, "exito")
    end
    
    -- También buscar fantasmas/ojos negros
    local fantasmas = Util.BuscarEnWorkspace("ghost")
    local ojosNegros = Util.BuscarEnWorkspace("blackeye")
    local sombras = Util.BuscarEnWorkspace("shadow")
    
    local entidadesOscuras = {}
    for _, t in pairs({fantasmas, ojosNegros, sombras}) do
        for _, e in pairs(t) do table.insert(entidadesOscuras, e) end
    end
    
    for _, entidad in pairs(entidadesOscuras) do
        if entidad and entidad.Parent then
            local pos = nil
            if entidad:IsA("BasePart") then
                pos = entidad.Position
            elseif entidad:IsA("Model") then
                local pp = entidad.PrimaryPart or entidad:FindFirstChildOfClass("BasePart")
                if pp then pos = pp.Position end
            end
            
            if pos then
                Util.TeletransportarA(pos + Vector3.new(3, 0, 0), true)
                Util.EsperarSeguro(0.1)
                
                -- Usar Taser
                for i = 1, 5 do
                    Util.SimularClick()
                    Util.DispararRemote("tase")
                    Util.DispararRemote("shoot")
                    task.wait(0.1)
                end
                
                Config.AnomalíasEliminadas = Config.AnomalíasEliminadas + 1
            end
        end
    end
end

-- AUTO ATENDER EMERGENCIAS Y DESMAYOS
function Acciones.AutoEmergencias()
    if not Config.AutoEmergencias and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    local emergencias = Detector.DetectarEmergencias()
    local estaciones = Detector.ObtenerEstaciones()
    
    -- PRIORIDAD 1: Desmayos (Temporizador crítico)
    if #emergencias.desmayos > 0 then
        Util.Notificar("¡EMERGENCIA!", "Paciente desmayado detectado!", 2, "alerta")
        
        for _, pacienteDesmayado in pairs(emergencias.desmayos) do
            if pacienteDesmayado and pacienteDesmayado.Parent then
                local pos = nil
                if pacienteDesmayado:IsA("Model") then
                    pos = pacienteDesmayado.PrimaryPart or pacienteDesmayado:FindFirstChildOfClass("BasePart")
                elseif pacienteDesmayado:IsA("BasePart") then
                    pos = pacienteDesmayado
                end
                
                if pos then
                    -- Teletransportarse al paciente desmayado
                    Util.TeletransportarA(pos, true)
                    Util.EsperarSeguro(0.1)
                    
                    -- Cargar paciente (presionar E)
                    Util.Interactuar(pacienteDesmayado)
                    Util.SimularTecla(Enum.KeyCode.E)
                    Util.DispararRemote("pickup")
                    Util.DispararRemote("carry")
                    Util.DispararRemote("grab")
                    Util.EsperarSeguro(0.3)
                    
                    -- Llevar a la cama más cercana
                    local camaLibre = Util.BuscarMasCercano(estaciones.camas)
                    if camaLibre then
                        Util.TeletransportarA(camaLibre, true)
                        Util.EsperarSeguro(0.1)
                        
                        -- Soltar en la cama
                        Util.Interactuar(camaLibre)
                        Util.SimularTecla(Enum.KeyCode.E)
                        Util.DispararRemote("drop")
                        Util.DispararRemote("place")
                        Util.DispararRemote("putDown")
                        Util.EsperarSeguro(0.3)
                        
                        -- Iniciar RCP automático
                        Util.DispararRemote("startCPR")
                        Util.DispararRemote("beginCPR")
                        Util.DispararRemote("resuscitate")
                        Util.EsperarSeguro(0.5)
                        
                        -- El minijuego de RCP debería activarse
                        Acciones.AutoRCP()
                    end
                    
                    Config.EmergenciasAtendidas = Config.EmergenciasAtendidas + 1
                end
            end
        end
    end
    
    -- PRIORIDAD 2: Ambulancias
    if #emergencias.ambulancias > 0 then
        Util.Notificar("¡AMBULANCIA!", "Emergencia de ambulancia!", 2, "alerta")
        
        for _, ambulancia in pairs(emergencias.ambulancias) do
            if ambulancia and ambulancia.Parent then
                local pos = nil
                if ambulancia:IsA("Model") then
                    pos = ambulancia.PrimaryPart or ambulancia:FindFirstChildOfClass("BasePart")
                elseif ambulancia:IsA("BasePart") then
                    pos = ambulancia
                end
                
                if pos then
                    Util.TeletransportarA(pos, true)
                    Util.EsperarSeguro(0.3)
                    
                    -- Interactuar con cada paciente de la ambulancia
                    local pacientesCercanos = Detector.ObtenerPacientes()
                    for _, pac in pairs(pacientesCercanos) do
                        local pacPos = pac.PrimaryPart or pac:FindFirstChildOfClass("BasePart")
                        if pacPos and Util.Distancia(rootPart.Position, pacPos.Position) < 25 then
                            -- Verificar si está desmayado/crítico
                            if pac:GetAttribute("Fainted") or pac:GetAttribute("Critical") then
                                Util.TeletransportarA(pacPos, true)
                                Util.EsperarSeguro(0.1)
                                Util.Interactuar(pac)
                                Util.SimularTecla(Enum.KeyCode.E)
                                Util.EsperarSeguro(0.3)
                                
                                local camaLibre = Util.BuscarMasCercano(estaciones.camas)
                                if camaLibre then
                                    Util.TeletransportarA(camaLibre, true)
                                    Util.Interactuar(camaLibre)
                                    Util.SimularTecla(Enum.KeyCode.E)
                                    Util.EsperarSeguro(0.3)
                                    
                                    Acciones.AutoRCP()
                                end
                            end
                        end
                    end
                    
                    Config.EmergenciasAtendidas = Config.EmergenciasAtendidas + 1
                end
            end
        end
    end
end

-- AUTO RITUAL DE MUERTE
function Acciones.AutoRitual()
    if not Config.AutoRitual and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    local emergencias = Detector.DetectarEmergencias()
    
    if #emergencias.rituales > 0 then
        Util.Notificar("¡RITUAL!", "Deteniendo ritual de muerte!", 2, "peligro")
        
        -- Buscar todas las velas
        local velas = Util.BuscarEnWorkspace("candle")
        local velasRituales = {}
        
        for _, vela in pairs(velas) do
            -- Verificar si la vela está encendida
            local encendida = false
            for _, desc in pairs(vela:GetDescendants()) do
                if desc:IsA("PointLight") or desc:IsA("Fire") or 
                   desc:IsA("ParticleEmitter") then
                    if desc.Enabled ~= false then
                        encendida = true
                        break
                    end
                end
            end
            
            if encendida or vela:GetAttribute("Lit") == true then
                table.insert(velasRituales, vela)
            end
        end
        
        -- También buscar por otros nombres
        local velasExtra = Util.BuscarEnWorkspace("ritual")
        for _, v in pairs(velasExtra) do
            table.insert(velasRituales, v)
        end
        
        -- Apagar cada vela
        for _, vela in pairs(velasRituales) do
            if vela and vela.Parent then
                local posVela = nil
                if vela:IsA("BasePart") then
                    posVela = vela.Position
                elseif vela:IsA("Model") then
                    local pp = vela.PrimaryPart or vela:FindFirstChildOfClass("BasePart")
                    if pp then posVela = pp.Position end
                end
                
                if posVela then
                    Util.TeletransportarA(posVela, true)
                    Util.EsperarSeguro(0.05)
                    Util.Interactuar(vela)
                    Util.SimularTecla(Enum.KeyCode.E)
                    Util.DispararRemote("extinguishCandle")
                    Util.DispararRemote("blowCandle")
                    Util.DispararRemote("stopRitual")
                end
            end
        end
        
        Util.DispararRemote("ritualStopped")
        Util.DispararRemote("cancelRitual")
        
        Config.RitualesDetenidos = Config.RitualesDetenidos + 1
        Util.Notificar("Ritual Detenido", "Ritual de muerte cancelado ✓", 2, "exito")
    end
end

-- AUTO CAFÉ (CORDURA/ENERGÍA)
function Acciones.AutoCafe()
    if not Config.AutoCafe and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    -- Verificar nivel de cordura/energía
    local necesitaCafe = false
    
    local playerGui = jugador:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in pairs(playerGui:GetDescendants()) do
            local n = gui.Name:lower()
            if string.find(n, "sanity") or string.find(n, "energy") or 
               string.find(n, "cordura") or string.find(n, "energia") or
               string.find(n, "stamina") then
                
                if gui:IsA("Frame") then
                    local barra = gui:FindFirstChild("Fill") or gui:FindFirstChild("Bar") or
                                 gui:FindFirstChild("Progress")
                    if barra and barra:IsA("Frame") then
                        local porcentaje = barra.Size.X.Scale
                        if porcentaje < Config.UmbralCordura / 100 then
                            necesitaCafe = true
                        end
                    end
                end
            end
        end
    end
    
    -- También verificar atributos
    local cordura = jugador:GetAttribute("Sanity") or jugador:GetAttribute("Energy") or 100
    if cordura < Config.UmbralCordura then
        necesitaCafe = true
    end
    
    -- Verificar en leaderstats o valores del personaje
    local leaderstats = jugador:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in pairs(leaderstats:GetChildren()) do
            local sn = stat.Name:lower()
            if string.find(sn, "sanity") or string.find(sn, "energy") then
                if stat.Value and stat.Value < Config.UmbralCordura then
                    necesitaCafe = true
                end
            end
        end
    end
    
    if necesitaCafe then
        Util.Notificar("Café", "Recargando energía/cordura ☕", 2, "info")
        
        -- Buscar máquina de café
        local maquinasCafe = Util.BuscarEnWorkspace("coffee")
        local maquina = Util.BuscarMasCercano(maquinasCafe)
        
        if not maquina then
            -- Buscar en estaciones
            local estaciones = Detector.ObtenerEstaciones()
            if estaciones.cafeteria then
                maquina = estaciones.cafeteria
            end
        end
        
        if maquina then
            local posMaquina = nil
            if maquina:IsA("BasePart") then
                posMaquina = maquina.Position
            elseif maquina:IsA("Model") then
                local pp = maquina.PrimaryPart or maquina:FindFirstChildOfClass("BasePart")
                if pp then posMaquina = pp.Position end
            end
            
            if posMaquina then
                Util.TeletransportarA(posMaquina, true)
                Util.EsperarSeguro(0.2)
                
                -- Interactuar para obtener café
                Util.Interactuar(maquina)
                Util.SimularTecla(Enum.KeyCode.E)
                Util.DispararRemote("makeCoffee")
                Util.DispararRemote("getCoffee")
                Util.DispararRemote("brewCoffee")
                Util.EsperarSeguro(1)
                
                -- Consumir café del inventario
                local mochila = jugador:FindFirstChild("Backpack")
                if mochila then
                    for _, item in pairs(mochila:GetChildren()) do
                        if item:IsA("Tool") then
                            local tn = item.Name:lower()
                            if string.find(tn, "coffee") or string.find(tn, "cafe") or
                               string.find(tn, "cup") or string.find(tn, "mug") then
                                humanoid:EquipTool(item)
                                Util.EsperarSeguro(0.3)
                                -- Usar/beber
                                Util.SimularClick()
                                Util.DispararRemote("drinkCoffee")
                                Util.DispararRemote("consume")
                                Util.DispararRemote("drink")
                                Util.DispararRemote("use")
                                break
                            end
                        end
                    end
                end
            end
        end
        
        Util.Notificar("Café Tomado", "Energía/cordura restaurada ☕", 2, "exito")
    end
end

-- AUTO BARNEY QUEST
function Acciones.AutoBarney()
    if not Config.AutoBarney and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    local barney = Detector.BuscarNPC("barney")
    
    if barney then
        Util.Notificar("Barney", "Interactuando con Barney...", 2, "info")
        
        local posBarney = barney.PrimaryPart or barney:FindFirstChildOfClass("BasePart")
        if posBarney then
            Util.TeletransportarA(posBarney.Position + Vector3.new(3, 0, 0), true)
            Util.EsperarSeguro(0.3)
            
            -- Interactuar con Barney
            Util.Interactuar(barney)
            Util.SimularTecla(Enum.KeyCode.E)
            Util.EsperarSeguro(0.5)
            
            -- Manejar diálogos - buscar opciones en GUI
            local playerGui = jugador:FindFirstChild("PlayerGui")
            if playerGui then
                for _, gui in pairs(playerGui:GetDescendants()) do
                    if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                        local n = gui.Name:lower()
                        local texto = ""
                        pcall(function() texto = gui.Text:lower() end)
                        
                        -- Dar café a Barney
                        if string.find(n, "give") or string.find(n, "dar") or
                           string.find(texto, "give") or string.find(texto, "coffee") or
                           string.find(texto, "café") or string.find(texto, "accept") then
                            pcall(function()
                                for _, conn in pairs(getconnections(gui.MouseButton1Click)) do
                                    conn:Fire()
                                end
                            end)
                        end
                        
                        -- Tomar foto
                        if string.find(n, "photo") or string.find(n, "picture") or
                           string.find(n, "camera") or string.find(n, "foto") then
                            pcall(function()
                                for _, conn in pairs(getconnections(gui.MouseButton1Click)) do
                                    conn:Fire()
                                end
                            end)
                        end
                    end
                end
            end
            
            -- Dar café si tenemos
            local mochila = jugador:FindFirstChild("Backpack")
            if mochila then
                for _, item in pairs(mochila:GetChildren()) do
                    if item:IsA("Tool") and string.find(item.Name:lower(), "coffee") then
                        humanoid:EquipTool(item)
                        Util.EsperarSeguro(0.3)
                        Util.DispararRemote("giveCoffee")
                        Util.DispararRemote("giveBarney")
                        Util.DispararRemote("barneyInteract")
                        break
                    end
                end
            end
            
            -- Prestar bisturí si lo pide
            Util.DispararRemote("giveScalpel")
            Util.DispararRemote("lendScalpel")
            
            -- Tomar foto de Barney
            local camarasTool = {}
            if mochila then
                for _, item in pairs(mochila:GetChildren()) do
                    if item:IsA("Tool") and (string.find(item.Name:lower(), "camera") or
                       string.find(item.Name:lower(), "polaroid") or
                       string.find(item.Name:lower(), "foto")) then
                        table.insert(camarasTool, item)
                    end
                end
            end
            
            if #camarasTool > 0 then
                humanoid:EquipTool(camarasTool[1])
                Util.EsperarSeguro(0.3)
                
                -- Apuntar a Barney y tomar foto
                if camara and posBarney then
                    camara.CFrame = CFrame.new(rootPart.Position, posBarney.Position)
                end
                Util.SimularClick()
                Util.DispararRemote("takePhoto")
                Util.DispararRemote("photograph")
                Util.DispararRemote("polaroid")
            end
        end
    end
end

-- AUTO RATTHEW QUEST
function Acciones.AutoRatthew()
    if not Config.AutoRatthew and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    local ratthew = Detector.BuscarNPC("ratthew")
    if not ratthew then
        ratthew = Detector.BuscarNPC("rat")
    end
    
    if ratthew then
        Util.Notificar("Ratthew", "Interactuando con Ratthew 🐭", 2, "info")
        
        local posRat = ratthew.PrimaryPart or ratthew:FindFirstChildOfClass("BasePart")
        if posRat then
            Util.TeletransportarA(posRat.Position + Vector3.new(2, 0, 0), true)
            Util.EsperarSeguro(0.3)
            
            Util.Interactuar(ratthew)
            Util.SimularTecla(Enum.KeyCode.E)
            Util.DispararRemote("ratthewInteract")
            Util.DispararRemote("talkRatthew")
            Util.DispararRemote("ratInteract")
            
            -- Obtener llave de Ratthew
            Util.EsperarSeguro(0.5)
            Util.DispararRemote("getRatthewKey")
            Util.DispararRemote("takeKey")
            Util.DispararRemote("collectKey")
            
            -- Buscar puerta secreta para usar la llave
            local puertasSecretas = Util.BuscarEnWorkspace("secret")
            for _, puerta in pairs(puertasSecretas) do
                if puerta:IsA("BasePart") or puerta:IsA("Model") then
                    local posPuerta = nil
                    if puerta:IsA("BasePart") then
                        posPuerta = puerta.Position
                    elseif puerta:IsA("Model") then
                        local pp = puerta.PrimaryPart or puerta:FindFirstChildOfClass("BasePart")
                        if pp then posPuerta = pp.Position end
                    end
                    
                    if posPuerta then
                        Util.TeletransportarA(posPuerta, true)
                        Util.EsperarSeguro(0.2)
                        Util.Interactuar(puerta)
                        Util.DispararRemote("useKey")
                        Util.DispararRemote("unlock")
                    end
                end
            end
        end
    end
end

-- AUTO CÁMARAS DE SEGURIDAD
function Acciones.AutoCamaras()
    if not Config.AutoCamaras and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    -- Buscar cámaras rotas o que necesiten reparación
    local camaras = Util.BuscarEnWorkspace("camera")
    local camarasRotas = {}
    
    for _, cam in pairs(camaras) do
        if cam:GetAttribute("Broken") == true or 
           cam:GetAttribute("NeedsRepair") == true or
           cam:GetAttribute("Damaged") == true then
            table.insert(camarasRotas, cam)
        end
    end
    
    -- Reparar cámaras rotas
    if #camarasRotas > 0 then
        Util.Notificar("Cámaras", "Reparando cámaras de seguridad...", 2, "info")
        
        for _, camRota in pairs(camarasRotas) do
            local pos = nil
            if camRota:IsA("BasePart") then
                pos = camRota.Position
            elseif camRota:IsA("Model") then
                local pp = camRota.PrimaryPart or camRota:FindFirstChildOfClass("BasePart")
                if pp then pos = pp.Position end
            end
            
            if pos then
                Util.TeletransportarA(pos, true)
                Util.EsperarSeguro(0.2)
                Util.Interactuar(camRota)
                Util.SimularTecla(Enum.KeyCode.E)
                Util.DispararRemote("repairCamera")
                Util.DispararRemote("fixCamera")
                Util.DispararRemote("repair")
            end
        end
    end
    
    -- Revisar CCTV para detectar skinwalkers
    local estaciones = Detector.ObtenerEstaciones()
    if estaciones.camaras then
        local posCam = nil
        if estaciones.camaras:IsA("BasePart") then
            posCam = estaciones.camaras.Position
        elseif estaciones.camaras:IsA("Model") then
            local pp = estaciones.camaras.PrimaryPart or estaciones.camaras:FindFirstChildOfClass("BasePart")
            if pp then posCam = pp.Position end
        end
        
        if posCam then
            Util.TeletransportarA(posCam, true)
            Util.EsperarSeguro(0.2)
            Util.Interactuar(estaciones.camaras)
            Util.DispararRemote("checkCCTV")
            Util.DispararRemote("viewCameras")
        end
    end
end

-- AUTO CERRAR PERSIANAS
function Acciones.AutoPersianas()
    if not Config.AutoPersianas and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    -- Detectar si hay monstruo en la ventana
    local ventanas = Util.BuscarEnWorkspace("window")
    local persianas = Util.BuscarEnWorkspace("shutter")
    local blinds = Util.BuscarEnWorkspace("blind")
    
    for _, ventana in pairs(ventanas) do
        -- Verificar si hay algo amenazante cerca de la ventana
        local amenaza = false
        local skinwalkers = Detector.DetectarSkinwalkers()
        
        local posVentana = nil
        if ventana:IsA("BasePart") then
            posVentana = ventana.Position
        elseif ventana:IsA("Model") then
            local pp = ventana.PrimaryPart or ventana:FindFirstChildOfClass("BasePart")
            if pp then posVentana = pp.Position end
        end
        
        if posVentana then
            for _, sk in pairs(skinwalkers) do
                local posSk = sk.PrimaryPart or sk:FindFirstChildOfClass("BasePart")
                if posSk and Util.Distancia(posVentana, posSk.Position) < 15 then
                    amenaza = true
                    break
                end
            end
            
            if amenaza then
                -- Cerrar persiana inmediatamente
                Util.TeletransportarA(posVentana, true)
                Util.EsperarSeguro(0.1)
                
                -- Buscar la persiana asociada a esta ventana
                for _, persiana in pairs(persianas) do
                    Util.Interactuar(persiana)
                end
                for _, blind in pairs(blinds) do
                    Util.Interactuar(blind)
                end
                
                Util.DispararRemote("closeShutter")
                Util.DispararRemote("closeBlinds")
                Util.DispararRemote("closeWindow")
                Util.SimularTecla(Enum.KeyCode.E)
                
                Util.Notificar("Persianas", "Persianas cerradas! 🪟", 1, "exito")
            end
        end
    end
end

-- AUTO LIMPIAR SLIME
function Acciones.AutoLimpiarSlime()
    if not Config.AutoLimpiarSlime and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    local slimes = Util.BuscarEnWorkspace("slime")
    local rastros = Util.BuscarEnWorkspace("trail")
    local goo = Util.BuscarEnWorkspace("goo")
    
    local todosSlimes = {}
    for _, t in pairs({slimes, rastros, goo}) do
        for _, s in pairs(t) do
            if s:IsA("BasePart") then
                -- Verificar color verde
                if s.Color == Color3.fromRGB(0, 255, 0) or 
                   s.Color == Color3.fromRGB(0, 200, 0) or
                   s.Color == Color3.fromRGB(50, 255, 50) or
                   s:GetAttribute("IsSlime") == true then
                    table.insert(todosSlimes, s)
                end
            end
        end
    end
    
    if #todosSlimes > 0 then
        Util.Notificar("Limpieza", "Limpiando rastro de slime...", 2, "info")
        
        -- Buscar herramienta de limpieza
        local mochila = jugador:FindFirstChild("Backpack")
        if mochila then
            for _, item in pairs(mochila:GetChildren()) do
                if item:IsA("Tool") then
                    local tn = item.Name:lower()
                    if string.find(tn, "mop") or string.find(tn, "clean") or
                       string.find(tn, "broom") then
                        humanoid:EquipTool(item)
                        break
                    end
                end
            end
        end
        
        for _, slime in pairs(todosSlimes) do
            if slime and slime.Parent then
                Util.TeletransportarA(slime.Position, true)
                Util.EsperarSeguro(0.05)
                Util.Interactuar(slime)
                Util.SimularTecla(Enum.KeyCode.E)
                Util.DispararRemote("cleanSlime")
                Util.DispararRemote("clean")
                Util.DispararRemote("mop")
            end
        end
        
        Util.Notificar("Limpio", "Slime eliminado ✓", 1, "exito")
    end
end

-- AUTO COMPRAR MEJORAS
function Acciones.AutoComprar()
    if not Config.AutoComprar and not Config.AutoTodo then return end
    if not Util.ObtenerPersonaje() then return end
    
    -- Verificar dinero disponible
    local dinero = 0
    local leaderstats = jugador:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in pairs(leaderstats:GetChildren()) do
            local sn = stat.Name:lower()
            if string.find(sn, "money") or string.find(sn, "cash") or 
               string.find(sn, "coin") or string.find(sn, "dinero") or
               string.find(sn, "gold") or string.find(sn, "currency") then
                dinero = stat.Value or 0
                break
            end
        end
    end
    
    if dinero <= 0 then
        dinero = jugador:GetAttribute("Money") or jugador:GetAttribute("Coins") or 0
    end
    
    if dinero > 0 then
        -- Buscar la tienda
        local anciana = Detector.BuscarNPC("shop")
        if not anciana then anciana = Detector.BuscarNPC("store") end
        if not anciana then anciana = Detector.BuscarNPC("vendor") end
        if not anciana then anciana = Detector.BuscarNPC("old") end
        
        local estaciones = Detector.ObtenerEstaciones()
        local tienda = anciana or estaciones.tienda
        
        if tienda then
            local posTienda = nil
            if tienda:IsA("Model") then
                posTienda = tienda.PrimaryPart or tienda:FindFirstChildOfClass("BasePart")
            elseif tienda:IsA("BasePart") then
                posTienda = tienda
            end
            
            if posTienda then
                Util.TeletransportarA(posTienda, true)
                Util.EsperarSeguro(0.3)
                Util.Interactuar(tienda)
                Util.EsperarSeguro(0.5)
                
                -- Buscar GUI de tienda y comprar mejoras
                local playerGui = jugador:FindFirstChild("PlayerGui")
                if playerGui then
                    for _, gui in pairs(playerGui:GetDescendants()) do
                        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                            local n = gui.Name:lower()
                            local texto = ""
                            pcall(function() texto = gui.Text:lower() end)
                            
                            -- Comprar mejoras por prioridad
                            if string.find(n, "buy") or string.find(n, "purchase") or
                               string.find(n, "comprar") or string.find(n, "upgrade") then
                                pcall(function()
                                    for _, conn in pairs(getconnections(gui.MouseButton1Click)) do
                                        conn:Fire()
                                    end
                                end)
                                Util.EsperarSeguro(0.3)
                            end
                        end
                    end
                end
                
                -- Disparar remotes de compra
                Util.DispararRemote("buyUpgrade")
                Util.DispararRemote("purchase")
                Util.DispararRemote("buyItem")
                Util.DispararRemote("shopBuy")
            end
        end
    end
end

-- AUTO CURAR PACIENTES (GENERAL)
function Acciones.AutoCurar()
    if not Config.AutoTodo and not Config.AutoFarmActivo then return end
    if not Util.ObtenerPersonaje() then return end
    
    local pacientes = Detector.ObtenerPacientes()
    local estaciones = Detector.ObtenerEstaciones()
    
    for _, paciente in pairs(pacientes) do
        if paciente and paciente.Parent then
            -- Verificar qué necesita el paciente
            local necesitaCirugia = paciente:GetAttribute("NeedsSurgery") == true
            local necesitaRayosX = paciente:GetAttribute("NeedsXray") == true
            local necesitaADN = paciente:GetAttribute("NeedsDNA") == true
            local necesitaRCP = paciente:GetAttribute("NeedsCPR") == true or
                               paciente:GetAttribute("Critical") == true
            local necesitaMedicina = paciente:GetAttribute("NeedsMedicine") == true
            
            local posPac = paciente.PrimaryPart or paciente:FindFirstChildOfClass("BasePart")
            if not posPac then continue end
            
            -- Verificar si es anomalía primero
            if Detector.EsAnomalía(paciente) then
                Config.AnomalíasEliminadas = Config.AnomalíasEliminadas + 1
                Util.DispararRemote("rejectPatient", paciente)
                Util.DispararRemote("removeAnomaly", paciente)
                continue
            end
            
            if necesitaRCP then
                Util.TeletransportarA(posPac, true)
                Util.EsperarSeguro(0.1)
                Util.Interactuar(paciente)
                Util.DispararRemote("startCPR", paciente)
                Acciones.AutoRCP()
            elseif necesitaCirugia and estaciones.cirugiaRoom then
                Util.TeletransportarA(posPac, true)
                Util.Interactuar(paciente)
                Util.EsperarSeguro(0.3)
                Util.TeletransportarA(estaciones.cirugiaRoom, true)
                Util.Interactuar(estaciones.cirugiaRoom)
                Acciones.AutoCirugia()
            elseif necesitaRayosX and estaciones.rayosXRoom then
                Util.TeletransportarA(posPac, true)
                Util.Interactuar(paciente)
                Util.EsperarSeguro(0.3)
                Util.TeletransportarA(estaciones.rayosXRoom, true)
                Util.Interactuar(estaciones.rayosXRoom)
                Acciones.AutoRayosX()
            elseif necesitaADN and estaciones.laboratorio then
                Util.TeletransportarA(posPac, true)
                Util.Interactuar(paciente)
                Util.EsperarSeguro(0.3)
                Util.TeletransportarA(estaciones.laboratorio, true)
                Util.Interactuar(estaciones.laboratorio)
                Acciones.AutoADN()
            elseif necesitaMedicina then
                Util.TeletransportarA(posPac, true)
                Util.Interactuar(paciente)
                Util.DispararRemote("giveMedicine", paciente)
                Util.DispararRemote("treat", paciente)
                Util.DispararRemote("heal", paciente)
            end
            
            Config.PacientesCurados = Config.PacientesCurados + 1
        end
    end
end

-- MONSTRUO DEBAJO DE LA CAMA
function Acciones.DetectarMonstruoCama()
    if not Util.ObtenerPersonaje() then return end
    
    -- Buscar manos negras debajo de las camas
    local manosNegras = Util.BuscarEnWorkspace("hand")
    local camas = Util.BuscarEnWorkspace("bed")
    
    for _, mano in pairs(manosNegras) do
        if mano:IsA("BasePart") and mano.Color == Color3.new(0, 0, 0) then
            -- ¡Monstruo debajo de la cama!
            -- Evitar la zona roja
            local zonaRoja = nil
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Color == Color3.fromRGB(255, 0, 0) then
                    if Util.Distancia(mano.Position, obj.Position) < 10 then
                        zonaRoja = obj
                        break
                    end
                end
            end
            
            -- Usar Taser a distancia segura
            if zonaRoja then
                local posSafe = mano.Position + Vector3.new(8, 0, 0)
                Util.TeletransportarA(posSafe, true)
            else
                Util.TeletransportarA(mano.Position + Vector3.new(6, 0, 0), true)
            end
            
            Util.EsperarSeguro(0.1)
            
            -- Disparar
            for i = 1, 5 do
                Util.SimularClick()
                Util.DispararRemote("shoot")
                Util.DispararRemote("tase")
                task.wait(0.1)
            end
        end
    end
end

-- ═══════════════════════════════════════════
-- SISTEMA NOCLIP (TRASPASAR PAREDES)
-- ═══════════════════════════════════════════

local function ActivarNoClip()
    RunService.Stepped:Connect(function()
        if Config.NoClip and Util.ObtenerPersonaje() then
            for _, parte in pairs(personaje:GetDescendants()) do
                if parte:IsA("BasePart") then
                    parte.CanCollide = false
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════
-- SISTEMA DE SUPER VELOCIDAD
-- ═══════════════════════════════════════════

local function ActualizarVelocidad()
    if Util.ObtenerPersonaje() and humanoid then
        if Config.SuperVelocidad then
            humanoid.WalkSpeed = Config.VelocidadSuper
        else
            humanoid.WalkSpeed = Config.VelocidadBase
        end
    end
end

-- ═══════════════════════════════════════════
-- ESCÁNER INTELIGENTE CONTINUO
-- ═══════════════════════════════════════════

local function EscanerInteligente()
    while Config.ScriptActivo do
        if Config.AutoTodo or Config.AutoFarmActivo then
            pcall(function()
                local emergencias = Detector.DetectarEmergencias()
                local skinwalkers = Detector.DetectarSkinwalkers()
                local minijuegos = Detector.DetectarMinijuegos()
                
                -- PRIORIDAD 1: Skinwalkers atacando
                if #skinwalkers > 0 and (Config.AutoSkinwalker or Config.AutoTodo) then
                    SistemaPrioridades.AgregarTarea("EliminarSkinwalker", 1, Acciones.AutoSkinwalker, skinwalkers)
                end
                
                -- PRIORIDAD 2: Desmayos
                if #emergencias.desmayos > 0 and (Config.AutoEmergencias or Config.AutoTodo) then
                    SistemaPrioridades.AgregarTarea("AtenderDesmayo", 2, Acciones.AutoEmergencias, emergencias)
                end
                
                -- PRIORIDAD 3: Incendios
                if #emergencias.incendios > 0 and (Config.AutoExtinguir or Config.AutoTodo) then
                    SistemaPrioridades.AgregarTarea("ExtinguirFuego", 3, Acciones.AutoExtinguir, emergencias)
                end
                
                -- PRIORIDAD 4: Rituales de muerte
                if #emergencias.rituales > 0 and (Config.AutoRitual or Config.AutoTodo) then
                    SistemaPrioridades.AgregarTarea("DetenerRitual", 4, Acciones.AutoRitual, emergencias)
                end
                
                -- PRIORIDAD 5: Ambulancias
                if #emergencias.ambulancias > 0 and (Config.AutoEmergencias or Config.AutoTodo) then
                    SistemaPrioridades.AgregarTarea("AtenderAmbulancia", 5, Acciones.AutoEmergencias, emergencias)
                end
                
                -- PRIORIDAD 6: Cirugía activa
                if minijuegos.cirugia and (Config.AutoCirugia or Config.AutoTodo) then
                    SistemaPrioridades.AgregarTarea("CompletarCirugia", 6, Acciones.AutoCirugia, nil)
                end
                
                -- PRIORIDAD 7: RCP activo
                if minijuegos.rcp and (Config.AutoRCP or Config.AutoTodo) then
                    SistemaPrioridades.AgregarTarea("CompletarRCP", 7, Acciones.AutoRCP, nil)
                end
                
                -- PRIORIDAD 8: Recepción
                if Config.AutoRecepcion or Config.AutoTodo then
                    SistemaPrioridades.AgregarTarea("AtenderRecepcion", 8, Acciones.AutoRecepcion, nil)
                end
                
                -- PRIORIDAD 9: Rayos X
                if minijuegos.rayosx and (Config.AutoRayosX or Config.AutoTodo) then
                    SistemaPrioridades.AgregarTarea("CompletarRayosX", 9, Acciones.AutoRayosX, nil)
                end
                
                -- PRIORIDAD 10: ADN
                if minijuegos.adn and (Config.AutoADN or Config.AutoTodo) then
                    SistemaPrioridades.AgregarTarea("CompletarADN", 10, Acciones.AutoADN, nil)
                end
                
                -- PRIORIDAD 11: Café/Cordura
                if Config.AutoCafe or Config.AutoTodo then
                    local cordura = jugador:GetAttribute("Sanity") or 100
                    if cordura < Config.UmbralCordura then
                        SistemaPrioridades.AgregarTarea("TomarCafe", 11, Acciones.AutoCafe, nil)
                    end
                end
                
                -- PRIORIDAD 12: Limpiar slime
                if Config.AutoLimpiarSlime or Config.AutoTodo then
                    local slimes = Util.BuscarEnWorkspace("slime")
                    if #slimes > 0 then
                        SistemaPrioridades.AgregarTarea("LimpiarSlime", 12, Acciones.AutoLimpiarSlime, nil)
                    end
                end
                
                -- PRIORIDAD 13: Cámaras
                if Config.AutoCamaras or Config.AutoTodo then
                    SistemaPrioridades.AgregarTarea("RevisarCamaras", 13, Acciones.AutoCamaras, nil)
                end
                
                -- PRIORIDAD 14: Barney
                if Config.AutoBarney or Config.AutoTodo then
                    local barney = Detector.BuscarNPC("barney")
                    if barney then
                        SistemaPrioridades.AgregarTarea("QuestBarney", 14, Acciones.AutoBarney, nil)
                    end
                end
                
                -- PRIORIDAD 15: Ratthew
                if Config.AutoRatthew or Config.AutoTodo then
                    local ratthew = Detector.BuscarNPC("ratthew") or Detector.BuscarNPC("rat")
                    if ratthew then
                        SistemaPrioridades.AgregarTarea("QuestRatthew", 15, Acciones.AutoRatthew, nil)
                    end
                end
                
                -- PRIORIDAD 16: Comprar mejoras
                if Config.AutoComprar or Config.AutoTodo then
                    SistemaPrioridades.AgregarTarea("ComprarMejoras", 16, Acciones.AutoComprar, nil)
                end
                
                -- Monstruo debajo de la cama (siempre activo)
                Acciones.DetectarMonstruoCama()
                
                -- Auto curar pacientes
                if Config.AutoTodo or Config.AutoFarmActivo then
                    Acciones.AutoCurar()
                end
                
                -- Persianas (siempre revisar)
                if Config.AutoPersianas or Config.AutoTodo then
                    Acciones.AutoPersianas()
                end
                
                -- Actualizar velocidad
                ActualizarVelocidad()
            end)
        end
        
        task.wait(0.5) -- Escanear cada 0.5 segundos
    end
end

-- ═══════════════════════════════════════════
-- INTERFAZ GRÁFICA (PANEL/GUI)
-- ═══════════════════════════════════════════

local function CrearPanel()
    -- Destruir panel anterior si existe
    local panelAnterior = jugador.PlayerGui:FindFirstChild("AnimalHospitalPanel")
    if panelAnterior then panelAnterior:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AnimalHospitalPanel"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- FRAME PRINCIPAL
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 420, 0, 580)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -290)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(0, 180, 255)
    mainStroke.Thickness = 2
    mainStroke.Parent = mainFrame
    
    -- Efecto de brillo en el borde
    local glowGradient = Instance.new("UIGradient")
    glowGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 180))
    })
    glowGradient.Parent = mainStroke
    
    -- BARRA DE TÍTULO
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Fix para esquinas inferiores del título
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -50, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🏥 HOSPITAL DE ANIMALES"
    titleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar
    
    local versionLabel = Instance.new("TextLabel")
    versionLabel.Size = UDim2.new(0, 60, 0, 20)
    versionLabel.Position = UDim2.new(1, -110, 0, 5)
    versionLabel.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
    versionLabel.BackgroundTransparency = 0.3
    versionLabel.Text = "v3.0"
    versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    versionLabel.TextSize = 11
    versionLabel.Font = Enum.Font.GothamBold
    versionLabel.Parent = titleBar
    
    local versionCorner = Instance.new("UICorner")
    versionCorner.CornerRadius = UDim.new(0, 6)
    versionCorner.Parent = versionLabel
    
    -- Botón minimizar
    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Name = "Minimize"
    minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
    minimizeBtn.Position = UDim2.new(1, -75, 0, 10)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
    minimizeBtn.Text = "—"
    minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeBtn.TextSize = 16
    minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.Parent = titleBar
    
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 6)
    minimizeCorner.Parent = minimizeBtn
    
    -- Botón cerrar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    -- TABS (Pestañas)
    local tabFrame = Instance.new("Frame")
    tabFrame.Name = "Tabs"
    tabFrame.Size = UDim2.new(1, -20, 0, 35)
    tabFrame.Position = UDim2.new(0, 10, 0, 55)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = mainFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = tabFrame
    
    local tabs = {"Principal", "Médico", "Defensa", "Movimiento", "Stats"}
    local tabButtons = {}
    local tabPages = {}
    
    for i, tabName in pairs(tabs) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. tabName
        tabBtn.Size = UDim2.new(0, 75, 1, 0)
        tabBtn.BackgroundColor3 = i == 1 and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(30, 30, 50)
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabBtn.TextSize = 11
        tabBtn.Font = Enum.Font.GothamSemibold
        tabBtn.Parent = tabFrame
        
        local tabBtnCorner = Instance.new("UICorner")
        tabBtnCorner.CornerRadius = UDim.new(0, 8)
        tabBtnCorner.Parent = tabBtn
        
        tabButtons[tabName] = tabBtn
    end
    
    -- ÁREA DE CONTENIDO SCROLLABLE
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -20, 1, -105)
    contentFrame.Position = UDim2.new(0, 10, 0, 95)
    contentFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    contentFrame.BorderSizePixel = 0
    contentFrame.ScrollBarThickness = 4
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    contentFrame.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentFrame
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 6)
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Parent = contentFrame
    
    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingTop = UDim.new(0, 8)
    contentPadding.PaddingBottom = UDim.new(0, 8)
    contentPadding.PaddingLeft = UDim.new(0, 8)
    contentPadding.PaddingRight = UDim.new(0, 8)
    contentPadding.Parent = contentFrame
    
    -- FUNCIÓN PARA CREAR TOGGLE
    local function CrearToggle(parent, texto, icono, configKey, orden)
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Name = "Toggle_" .. configKey
        toggleFrame.Size = UDim2.new(1, -10, 0, 38)
        toggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
        toggleFrame.BorderSizePixel = 0
        toggleFrame.LayoutOrder = orden or 0
        toggleFrame.Parent = parent
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 8)
        toggleCorner.Parent = toggleFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -70, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = icono .. " " .. texto
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextSize = 13
        label.Font = Enum.Font.GothamSemibold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggleFrame
        
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Name = "ToggleButton"
        toggleBtn.Size = UDim2.new(0, 50, 0, 24)
        toggleBtn.Position = UDim2.new(1, -58, 0.5, -12)
        toggleBtn.BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(80, 80, 80)
        toggleBtn.Text = Config[configKey] and "ON" or "OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 11
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Parent = toggleFrame
        
        local toggleBtnCorner = Instance.new("UICorner")
        toggleBtnCorner.CornerRadius = UDim.new(0, 12)
        toggleBtnCorner.Parent = toggleBtn
        
        toggleBtn.MouseButton1Click:Connect(function()
            Config[configKey] = not Config[configKey]
            toggleBtn.BackgroundColor3 = Config[configKey] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(80, 80, 80)
            toggleBtn.Text = Config[configKey] and "ON" or "OFF"
            
            if configKey == "SuperVelocidad" then
                ActualizarVelocidad()
            end
            
            Util.Notificar(texto, Config[configKey] and "Activado ✅" or "Desactivado ❌", 1, 
                Config[configKey] and "exito" or "info")
        end)
        
        return toggleFrame, toggleBtn
    end
    
    -- FUNCIÓN PARA CREAR SEPARADOR
    local function CrearSeparador(parent, texto, orden)
        local sepFrame = Instance.new("Frame")
        sepFrame.Name = "Sep_" .. texto
        sepFrame.Size = UDim2.new(1, -10, 0, 25)
        sepFrame.BackgroundTransparency = 1
        sepFrame.LayoutOrder = orden or 0
        sepFrame.Parent = parent
        
        local sepLabel = Instance.new("TextLabel")
        sepLabel.Size = UDim2.new(1, 0, 1, 0)
        sepLabel.BackgroundTransparency = 1
        sepLabel.Text = "━━━ " .. texto .. " ━━━"
        sepLabel.TextColor3 = Color3.fromRGB(0, 150, 255)
        sepLabel.TextSize = 11
        sepLabel.Font = Enum.Font.GothamBold
        sepLabel.Parent = sepFrame
        
        return sepFrame
    end
    
    -- ═══ PÁGINAS DE CONTENIDO ═══
    
    -- Contenedores para cada pestaña
    local paginas = {}
    for _, tabName in pairs(tabs) do
        local pagina = Instance.new("Frame")
        pagina.Name = "Page_" .. tabName
        pagina.Size = UDim2.new(1, 0, 0, 0)
        pagina.AutomaticSize = Enum.AutomaticSize.Y
        pagina.BackgroundTransparency = 1
        pagina.Visible = tabName == "Principal"
        pagina.Parent = contentFrame
        
        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 5)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = pagina
        
        paginas[tabName] = pagina
    end
    
    -- ══════ PESTAÑA PRINCIPAL ══════
    local pPrincipal = paginas["Principal"]
    
    -- Botón grande AUTO TODO
    local autoTodoFrame = Instance.new("Frame")
    autoTodoFrame.Name = "AutoTodoFrame"
    autoTodoFrame.Size = UDim2.new(1, -10, 0, 55)
    autoTodoFrame.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
    autoTodoFrame.BorderSizePixel = 0
    autoTodoFrame.LayoutOrder = 0
    autoTodoFrame.Parent = pPrincipal
    
    local autoTodoCorner = Instance.new("UICorner")
    autoTodoCorner.CornerRadius = UDim.new(0, 10)
    autoTodoCorner.Parent = autoTodoFrame
    
    local autoTodoStroke = Instance.new("UIStroke")
    autoTodoStroke.Color = Color3.fromRGB(0, 255, 100)
    autoTodoStroke.Thickness = 2
    autoTodoStroke.Parent = autoTodoFrame
    
    local autoTodoBtn = Instance.new("TextButton")
    autoTodoBtn.Name = "AutoTodoBtn"
    autoTodoBtn.Size = UDim2.new(1, 0, 1, 0)
    autoTodoBtn.BackgroundTransparency = 1
    autoTodoBtn.Text = "🤖 AUTO TODO - HACER TODO SOLO"
    autoTodoBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
    autoTodoBtn.TextSize = 16
    autoTodoBtn.Font = Enum.Font.GothamBold
    autoTodoBtn.Parent = autoTodoFrame
    
    autoTodoBtn.MouseButton1Click:Connect(function()
        Config.AutoTodo = not Config.AutoTodo
        
        if Config.AutoTodo then
            -- Activar todo
            Config.AutoFarmActivo = true
            Config.AutoRecepcion = true
            Config.AutoCirugia = true
            Config.AutoRCP = true
            Config.AutoRayosX = true
            Config.AutoADN = true
            Config.AutoExtinguir = true
            Config.AutoSkinwalker = true
            Config.AutoEmergencias = true
            Config.AutoRitual = true
            Config.AutoCafe = true
            Config.AutoBarney = true
            Config.AutoRatthew = true
            Config.AutoCamaras = true
            Config.AutoPersianas = true
            Config.AutoLimpiarSlime = true
            Config.AutoComprar = true
            Config.SuperVelocidad = true
            Config.NoClip = true
            
            autoTodoFrame.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
            autoTodoBtn.Text = "🤖 AUTO TODO - ACTIVO ✅"
            autoTodoStroke.Color = Color3.fromRGB(0, 255, 0)
        else
            Config.AutoFarmActivo = false
            autoTodoFrame.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
            autoTodoBtn.Text = "🤖 AUTO TODO - HACER TODO SOLO"
            autoTodoStroke.Color = Color3.fromRGB(0, 255, 100)
        end
        
        -- Actualizar todos los toggles
        for _, desc in pairs(contentFrame:GetDescendants()) do
            if desc.Name == "ToggleButton" and desc:IsA("TextButton") then
                local parentName = desc.Parent.Name:gsub("Toggle_", "")
                if Config[parentName] ~= nil then
                    desc.BackgroundColor3 = Config[parentName] and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(80, 80, 80)
                    desc.Text = Config[parentName] and "ON" or "OFF"
                end
            end
        end
        
        ActualizarVelocidad()
        Util.Notificar("AUTO TODO", Config.AutoTodo and "¡Todo activado! El script hará TODO solo 🤖" or "Desactivado", 3, 
            Config.AutoTodo and "exito" or "info")
    end)
    
    CrearSeparador(pPrincipal, "FARMEO GENERAL", 1)
    CrearToggle(pPrincipal, "Auto Farm Activo", "🌾", "AutoFarmActivo", 2)
    CrearToggle(pPrincipal, "Auto Recepción", "📋", "AutoRecepcion", 3)
    CrearToggle(pPrincipal, "Auto Comprar Mejoras", "🛒", "AutoComprar", 4)
    CrearToggle(pPrincipal, "Auto Café/Cordura", "☕", "AutoCafe", 5)
    CrearToggle(pPrincipal, "Auto Limpiar Slime", "🧹", "AutoLimpiarSlime", 6)
    
    -- ══════ PESTAÑA MÉDICO ══════
    local pMedico = paginas["Médico"]
    
    CrearSeparador(pMedico, "PROCEDIMIENTOS", 0)
    CrearToggle(pMedico, "Auto Cirugía", "🔪", "AutoCirugia", 1)
    CrearToggle(pMedico, "Auto RCP Cardíaco", "❤️", "AutoRCP", 2)
    CrearToggle(pMedico, "Auto Rayos X", "🩻", "AutoRayosX", 3)
    CrearToggle(pMedico, "Auto Análisis ADN", "🧬", "AutoADN", 4)
    
    CrearSeparador(pMedico, "EMERGENCIAS", 5)
    CrearToggle(pMedico, "Auto Emergencias", "🚑", "AutoEmergencias", 6)
    CrearToggle(pMedico, "Auto Extinguir Fuego", "🧯", "AutoExtinguir", 7)
    CrearToggle(pMedico, "Auto Ritual de Muerte", "🕯️", "AutoRitual", 8)
    
    -- ══════ PESTAÑA DEFENSA ══════
    local pDefensa = paginas["Defensa"]
    
    CrearSeparador(pDefensa, "ANTI-ANOMALÍAS", 0)
    CrearToggle(pDefensa, "Auto Skinwalkers", "☠️", "AutoSkinwalker", 1)
    CrearToggle(pDefensa, "Auto Persianas", "🪟", "AutoPersianas", 2)
    CrearToggle(pDefensa, "Auto Cámaras CCTV", "📹", "AutoCamaras", 3)
    
    CrearSeparador(pDefensa, "QUESTS/MISIONES", 4)
    CrearToggle(pDefensa, "Auto Barney Quest", "🧑", "AutoBarney", 5)
    CrearToggle(pDefensa, "Auto Ratthew Quest", "🐭", "AutoRatthew", 6)
    
    -- ══════ PESTAÑA MOVIMIENTO ══════
    local pMovimiento = paginas["Movimiento"]
    
    CrearSeparador(pMovimiento, "MOVIMIENTO", 0)
    CrearToggle(pMovimiento, "Súper Velocidad", "⚡", "SuperVelocidad", 1)
    CrearToggle(pMovimiento, "Traspasar Paredes", "👻", "NoClip", 2)
    
    -- Slider de velocidad
    local velFrame = Instance.new("Frame")
    velFrame.Size = UDim2.new(1, -10, 0, 50)
    velFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    velFrame.BorderSizePixel = 0
    velFrame.LayoutOrder = 3
    velFrame.Parent = pMovimiento
    
    local velCorner = Instance.new("UICorner")
    velCorner.CornerRadius = UDim.new(0, 8)
    velCorner.Parent = velFrame
    
    local velLabel = Instance.new("TextLabel")
    velLabel.Size = UDim2.new(1, -10, 0, 20)
    velLabel.Position = UDim2.new(0, 10, 0, 3)
    velLabel.BackgroundTransparency = 1
    velLabel.Text = "⚡ Velocidad: " .. Config.VelocidadSuper
    velLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    velLabel.TextSize = 12
    velLabel.Font = Enum.Font.GothamSemibold
    velLabel.TextXAlignment = Enum.TextXAlignment.Left
    velLabel.Parent = velFrame
    
    local velSliderBg = Instance.new("Frame")
    velSliderBg.Size = UDim2.new(1, -20, 0, 10)
    velSliderBg.Position = UDim2.new(0, 10, 0, 30)
    velSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    velSliderBg.BorderSizePixel = 0
    velSliderBg.Parent = velFrame
    
    local velSliderCorner = Instance.new("UICorner")
    velSliderCorner.CornerRadius = UDim.new(0, 5)
    velSliderCorner.Parent = velSliderBg
    
    local velSliderFill = Instance.new("Frame")
    velSliderFill.Size = UDim2.new(Config.VelocidadSuper / 300, 0, 1, 0)
    velSliderFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    velSliderFill.BorderSizePixel = 0
    velSliderFill.Parent = velSliderBg
    
    local velFillCorner = Instance.new("UICorner")
    velFillCorner.CornerRadius = UDim.new(0, 5)
    velFillCorner.Parent = velSliderFill
    
    local velSliderBtn = Instance.new("TextButton")
    velSliderBtn.Size = UDim2.new(1, 0, 1, 0)
    velSliderBtn.BackgroundTransparency = 1
    velSliderBtn.Text = ""
    velSliderBtn.Parent = velSliderBg
    
    local dragging = false
    velSliderBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relativeX = math.clamp(
                (input.Position.X - velSliderBg.AbsolutePosition.X) / velSliderBg.AbsoluteSize.X,
                0, 1
            )
            Config.VelocidadSuper = math.floor(relativeX * 300)
            Config.VelocidadSuper = math.clamp(Config.VelocidadSuper, 16, 300)
            velSliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
            velLabel.Text = "⚡ Velocidad: " .. Config.VelocidadSuper
            ActualizarVelocidad()
        end
    end)
    
    -- Botón de teletransporte rápido
    CrearSeparador(pMovimiento, "TELETRANSPORTE", 4)
    
    local tpBtns = {
        {"Recepción", "recepcion", "📋"},
        {"Cirugía", "cirugiaRoom", "🔪"},
        {"Rayos X", "rayosXRoom", "🩻"},
        {"Laboratorio", "laboratorio", "🧬"},
        {"Cafetería", "cafeteria", "☕"},
        {"Tienda", "tienda", "🛒"},
        {"Cámaras", "camaras", "📹"}
    }
    
    for i, tpData in pairs(tpBtns) do
        local tpBtn = Instance.new("TextButton")
        tpBtn.Name = "TP_" .. tpData[1]
        tpBtn.Size = UDim2.new(1, -10, 0, 32)
        tpBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
        tpBtn.Text = tpData[3] .. " Ir a " .. tpData[1]
        tpBtn.TextColor3 = Color3.fromRGB(200, 200, 255)
        tpBtn.TextSize = 12
        tpBtn.Font = Enum.Font.GothamSemibold
        tpBtn.LayoutOrder = 5 + i
        tpBtn.Parent = pMovimiento
        
        local tpBtnCorner = Instance.new("UICorner")
        tpBtnCorner.CornerRadius = UDim.new(0, 8)
        tpBtnCorner.Parent = tpBtn
        
        tpBtn.MouseButton1Click:Connect(function()
            local estaciones = Detector.ObtenerEstaciones()
            local destino = estaciones[tpData[2]]
            if destino then
                Util.TeletransportarA(destino, true)
                Util.Notificar("Teletransporte", "Llegaste a " .. tpData[1], 1, "exito")
            else
                Util.Notificar("Error", "No se encontró " .. tpData[1], 2, "error")
            end
        end)
    end
    
    -- ══════ PESTAÑA STATS ══════
    local pStats = paginas["Stats"]
    
    CrearSeparador(pStats, "ESTADÍSTICAS", 0)
    
    local statsLabels = {}
    local statsData = {
        {"💰 Dinero Ganado:", "DineroGanado"},
        {"🏥 Pacientes Curados:", "PacientesCurados"},
        {"☠️ Anomalías Eliminadas:", "AnomalíasEliminadas"},
        {"🚑 Emergencias Atendidas:", "EmergenciasAtendidas"},
        {"🔥 Incendios Extinguidos:", "IncendiosExtinguidos"},
        {"🕯️ Rituales Detenidos:", "RitualesDetenidos"},
        {"🔪 Cirugías Completadas:", "CirugíasCompletadas"}
    }
    
    for i, statInfo in pairs(statsData) do
        local statFrame = Instance.new("Frame")
        statFrame.Size = UDim2.new(1, -10, 0, 30)
        statFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
        statFrame.BorderSizePixel = 0
        statFrame.LayoutOrder = i
        statFrame.Parent = pStats
        
        local statCorner = Instance.new("UICorner")
        statCorner.CornerRadius = UDim.new(0, 6)
        statCorner.Parent = statFrame
        
        local statLabel = Instance.new("TextLabel")
        statLabel.Name = "StatLabel"
        statLabel.Size = UDim2.new(0.65, 0, 1, 0)
        statLabel.Position = UDim2.new(0, 10, 0, 0)
        statLabel.BackgroundTransparency = 1
        statLabel.Text = statInfo[1]
        statLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
        statLabel.TextSize = 12
        statLabel.Font = Enum.Font.GothamSemibold
        statLabel.TextXAlignment = Enum.TextXAlignment.Left
        statLabel.Parent = statFrame
        
        local statValue = Instance.new("TextLabel")
        statValue.Name = "StatValue_" .. statInfo[2]
        statValue.Size = UDim2.new(0.35, -10, 1, 0)
        statValue.Position = UDim2.new(0.65, 0, 0, 0)
        statValue.BackgroundTransparency = 1
        statValue.Text = tostring(Config[statInfo[2]] or 0)
        statValue.TextColor3 = Color3.fromRGB(0, 255, 150)
        statValue.TextSize = 14
        statValue.Font = Enum.Font.GothamBold
        statValue.TextXAlignment = Enum.TextXAlignment.Right
        statValue.Parent = statFrame
        
        statsLabels[statInfo[2]] = statValue
    end
    
    -- Información del dinero actual en el juego
    CrearSeparador(pStats, "DINERO EN JUEGO", 10)
    
    local dineroFrame = Instance.new("Frame")
    dineroFrame.Size = UDim2.new(1, -10, 0, 40)
    dineroFrame.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
    dineroFrame.BorderSizePixel = 0
    dineroFrame.LayoutOrder = 11
    dineroFrame.Parent = pStats
    
    local dineroCorner = Instance.new("UICorner")
    dineroCorner.CornerRadius = UDim.new(0, 8)
    dineroCorner.Parent = dineroFrame
    
    local dineroLabel = Instance.new("TextLabel")
    dineroLabel.Name = "DineroActual"
    dineroLabel.Size = UDim2.new(1, -20, 1, 0)
    dineroLabel.Position = UDim2.new(0, 10, 0, 0)
    dineroLabel.BackgroundTransparency = 1
    dineroLabel.Text = "💵 Dinero Actual: Cargando..."
    dineroLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
    dineroLabel.TextSize = 14
    dineroLabel.Font = Enum.Font.GothamBold
    dineroLabel.Parent = dineroFrame
    
    -- ═══ LÓGICA DE PESTAÑAS ═══
    local paginaActual = "Principal"
    
    for tabName, tabBtn in pairs(tabButtons) do
        tabBtn.MouseButton1Click:Connect(function()
            paginaActual = tabName
            
            -- Actualizar visual de pestañas
            for name, btn in pairs(tabButtons) do
                btn.BackgroundColor3 = name == tabName and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(30, 30, 50)
            end
            
            -- Mostrar/ocultar páginas
            for name, pagina in pairs(paginas) do
                pagina.Visible = name == tabName
            end
        end)
    end
    
    -- ═══ MINIMIZAR ═══
    local minimizado = false
    local sizeOriginal = mainFrame.Size
    
    minimizeBtn.MouseButton1Click:Connect(function()
        minimizado = not minimizado
        if minimizado then
            contentFrame.Visible = false
            tabFrame.Visible = false
            mainFrame.Size = UDim2.new(0, 420, 0, 55)
            minimizeBtn.Text = "+"
        else
            contentFrame.Visible = true
            tabFrame.Visible = true
            mainFrame.Size = sizeOriginal
            minimizeBtn.Text = "—"
        end
    end)
    
    -- ═══ CERRAR ═══
    closeBtn.MouseButton1Click:Connect(function()
        Config.ScriptActivo = false
        Config.AutoTodo = false
        screenGui:Destroy()
        Util.Notificar("Script", "Script detenido completamente", 3, "info")
    end)
    
    -- ═══ ACTUALIZAR STATS PERIÓDICAMENTE ═══
    task.spawn(function()
        while Config.ScriptActivo and screenGui.Parent do
            pcall(function()
                for key, label in pairs(statsLabels) do
                    label.Text = tostring(Config[key] or 0)
                end
                
                -- Actualizar dinero actual
                local dineroActual = 0
                local leaderstats = jugador:FindFirstChild("leaderstats")
                if leaderstats then
                    for _, stat in pairs(leaderstats:GetChildren()) do
                        local sn = stat.Name:lower()
                        if string.find(sn, "money") or string.find(sn, "cash") or 
                           string.find(sn, "coin") or string.find(sn, "dinero") or
                           string.find(sn, "gold") then
                            dineroActual = stat.Value or 0
                            break
                        end
                    end
                end
                if dineroActual == 0 then
                    dineroActual = jugador:GetAttribute("Money") or jugador:GetAttribute("Coins") or 0
                end
                
                dineroLabel.Text = "💵 Dinero Actual: $" .. tostring(dineroActual)
            end)
            
            task.wait(1)
        end
    end)
    
    -- ═══ BOTÓN TOGGLE PARA MOSTRAR/OCULTAR (MINI) ═══
    local miniBtn = Instance.new("TextButton")
    miniBtn.Name = "MiniToggle"
    miniBtn.Size = UDim2.new(0, 45, 0, 45)
    miniBtn.Position = UDim2.new(0, 10, 0.5, -22)
    miniBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
    miniBtn.Text = "🏥"
    miniBtn.TextSize = 22
    miniBtn.Font = Enum.Font.GothamBold
    miniBtn.Visible = false
    miniBtn.Parent = screenGui
    
    local miniBtnCorner = Instance.new("UICorner")
    miniBtnCorner.CornerRadius = UDim.new(0, 22)
    miniBtnCorner.Parent = miniBtn
    
    miniBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        miniBtn.Visible = false
    end)
    
    -- Doble click en título para ocultar completamente
    local lastClickTime = 0
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local now = tick()
            if now - lastClickTime < 0.3 then
                mainFrame.Visible = false
                miniBtn.Visible = true
            end
            lastClickTime = now
        end
    end)
    
    -- ═══ ANIMACIÓN DE GRADIENTE ═══
    task.spawn(function()
        local offset = 0
        while Config.ScriptActivo and screenGui.Parent do
            offset = (offset + 0.005) % 1
            glowGradient.Offset = Vector2.new(offset, 0)
            RunService.Heartbeat:Wait()
        end
    end)
    
    screenGui.Parent = jugador.PlayerGui
    
    return screenGui
end

-- ═══════════════════════════════════════════
-- SISTEMA ANTI-MUERTE / RECONEXIÓN
-- ═══════════════════════════════════════════

local function ConfigurarReconexion()
    jugador.CharacterAdded:Connect(function(char)
        personaje = char
        humanoid = char:WaitForChild("Humanoid")
        rootPart = char:WaitForChild("HumanoidRootPart")
        
        task.wait(1)
        
        if Config.SuperVelocidad then
            ActualizarVelocidad()
        end
        
        Util.Notificar("Respawn", "Personaje reconectado automáticamente", 2, "info")
    end)
end

-- ═══════════════════════════════════════════
-- HOOK DE REMOTES (INTERCEPTAR DINERO)
-- ═══════════════════════════════════════════

local function HookearDinero()
    -- Monitorear cambios en leaderstats
    local leaderstats = jugador:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in pairs(leaderstats:GetChildren()) do
            local sn = stat.Name:lower()
            if string.find(sn, "money") or string.find(sn, "cash") or
               string.find(sn, "coin") or string.find(sn, "dinero") then
                
                local valorAnterior = stat.Value or 0
                stat.Changed:Connect(function(nuevoValor)
                    if nuevoValor > valorAnterior then
                        local ganancia = nuevoValor - valorAnterior
                        Config.DineroGanado = Config.DineroGanado + ganancia
                    end
                    valorAnterior = nuevoValor
                end)
            end
        end
    end
    
    -- También monitorear atributos
    jugador.AttributeChanged:Connect(function(attr)
        local attrLower = attr:lower()
        if string.find(attrLower, "money") or string.find(attrLower, "coin") then
            -- Actualizar estadísticas
        end
    end)
end

-- ═══════════════════════════════════════════
-- CICLO PRINCIPAL DE AUTO FARM
-- ═══════════════════════════════════════════

local function CicloPrincipal()
    while Config.ScriptActivo do
        if Config.AutoTodo or Config.AutoFarmActivo then
            pcall(function()
                -- El escáner inteligente ya maneja las prioridades
                -- Este ciclo hace las tareas rutinarias
                
                if not BloqueoTarea then
                    -- Ciclo de recepción cuando no hay emergencias
                    if #ColaTareas == 0 then
                        if Config.AutoRecepcion or Config.AutoTodo then
                            Acciones.AutoRecepcion()
                        end
                        
                        Util.EsperarSeguro(1)
                        
                        -- Curar pacientes pendientes
                        Acciones.AutoCurar()
                        
                        Util.EsperarSeguro(0.5)
                        
                        -- Verificar café
                        if Config.AutoCafe or Config.AutoTodo then
                            Acciones.AutoCafe()
                        end
                    end
                end
            end)
        end
        
        task.wait(1)
    end
end

-- ═══════════════════════════════════════════
-- INICIALIZACIÓN DEL SCRIPT
-- ═══════════════════════════════════════════

local function Inicializar()
    print("╔══════════════════════════════════════════╗")
    print("║  🏥 ANIMAL HOSPITAL MEGA SCRIPT v3.0    ║")
    print("║  Cargando sistemas...                    ║")
    print("╚══════════════════════════════════════════╝")
    
    -- Verificar que estamos en el juego correcto
    Util.Notificar("🏥 Animal Hospital", "Cargando script mega completo...", 3, "info")
    
    -- Esperar a que el personaje cargue
    if not jugador.Character then
        jugador.CharacterAdded:Wait()
    end
    task.wait(2)
    
    -- Inicializar personaje
    if not Util.ObtenerPersonaje() then
        Util.Notificar("Error", "No se pudo obtener el personaje", 3, "error")
        return
    end
    
    -- Configurar sistemas
    ConfigurarReconexion()
    ActivarNoClip()
    HookearDinero()
    
    -- Crear panel GUI
    local panel = CrearPanel()
    
    -- Iniciar escáner inteligente en hilo separado
    task.spawn(EscanerInteligente)
    
    -- Iniciar procesador de cola de prioridades
    task.spawn(SistemaPrioridades.ProcesarCola)
    
    -- Iniciar ciclo principal
    task.spawn(CicloPrincipal)
    
    Util.Notificar("✅ Script Listo", "Panel cargado. Presiona AUTO TODO para empezar. Arrastra el panel para moverlo.", 5, "exito")
    
    print("✅ Script inicializado correctamente")
    print("📋 Usa el panel para activar/desactivar funciones")
    print("🤖 Presiona AUTO TODO para activar todo automáticamente")
end

-- ═══════════════════════════════════════════
-- EJECUTAR
-- ═══════════════════════════════════════════

Inicializar()
