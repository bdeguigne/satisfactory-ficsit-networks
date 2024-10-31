averageSign = component.proxy('B707D627409A86D64D1FC7A73340C243')
averageLightPanel = component.proxy('004312864F21E3A7EEA4B6807BBB6C81')
controlPanel = component.proxy('D8F34A3F416397F86E478FBD9887E902')
screenGauche = component.proxy('673AB1364217656882094B8B857975AD')
screenDroite = component.proxy('675A1D4C4456722A024B9E80B6722154')
switchPanel = component.proxy('D511ABC94EEE260702B50F9CBB0B827A')
ecranSwitchPanel = component.proxy('1B65C78C43A3515337E779ABDAE097A2')
modularIndicator = component.proxy('B3F3A2254EEB1B1A4A725186FBBFBC92')
screenDroiteProduction = component.proxy('49E5133545051029EEF52FADFCD28C12')
stopPanel = component.proxy('97BE6C1548B3F56C93553E961B20DC7B')

foreground = { 0 ,247,255,1 }
background = { 52,97 ,134, 1 }
auxiliary = { 0.0091340569779277, 0.028445303440094, 0.059511236846447, 1.0 }

-- Adds the contents of t2 to t1
function tableConcat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

---Can the given value be found in a table of { key, values } ?
---@param t table
---@param value any
---@return boolean
function tableHasValue(t, value)
    if t == nil or value == nil then
        return false
    end

    for _, v in pairs(t) do
        if v == value then
            return true
        end
    end

    return false
end

---Find and return a table of all the NetworkComponent proxies that are of the given class[es]
---@param class any Class name or table (of tables) of class names
---@param boolean Return only one
---@return table | nil | proxy: indexed table of all NetworkComponents found
function getComponentsByClass(class, getOne)
    local results = {}

    if (getOne == nil) then
        getOne = false
    end

    if type(class) == "table" then
        for _, c in pairs(class) do
            local proxies = getComponentsByClass(c, getOne)
            if not getOne then
                tableConcat(results, proxies)
            else
                if (proxies ~= nil) then
                    return proxies
                end
            end
        end
    elseif type(class) == "string" then
        local ctype = classes[class]
        if ctype ~= nil then
            local comps = component.findComponent(ctype)
            for _, c in pairs(comps) do
                local proxy = component.proxy(c)
                if getOne and proxy ~= nil then
                    return proxy
                elseif not tableHasValue(results, proxy) then
                    table.insert(results, proxy)
                end
            end
        end
    end

    if (getOne) then
        return {}
    end

    return results
end

---Find and return a table of all the NetworkComponent proxies that are of the given class[es] and contain the given nick parts
---@param class any Class name or table (of tables) of class names
---@param class nickParts Nick or parts of a nick that we want to see
---@return table: indexed table of all NetworkComponents found
function getComponentsByClassAndNick(class, nickParts)
    if type(nickParts) == 'string' then
        nickParts = { nickParts }
    end

    local classComponents = getComponentsByClass(class)
    local results = {}

    for _, component in pairs(classComponents) do
        for _, nickPart in pairs(nickParts) do
            if component.nick:find(nickPart, 1, true) == nil then
                goto nextComponent
            end
        end

        table.insert(results, component)

        ::nextComponent::
    end

    return results
end

function updateSign(sign, element, value, icon, isError)
    local signData = sign:getPrefabSignData()
    iconElems, iconValues = signData:getIconElements()


    signData:setTextElement(element, value)

    if icon ~= nil then
        signData:setIconElement('Icon', icon)
    end

    if isError ~= nil then
        if isError == true then
            signData.background = { 255, 0, 0, 1 }
        else
            signData.background = auxiliary
        end
    end

    -- signData.foreground = foreground

    sign:setPrefabSignData(signData)

    return sign
end

function monitorProductivity(refineries)
    local count = 0
    local total_productivity = 0
    local underperforming = {} -- Table pour les machines sous-performantes
    local all_machines = {}   -- Table pour toutes les machines

    for _, component in ipairs(refineries) do
        local productivity = component.productivity * 100
        total_productivity = total_productivity + productivity
        count = count + 1

        -- Ajouter les détails de chaque machine à la table all_machines
        table.insert(all_machines, {
            component = component,
        })

        -- Ajouter à la liste des sous-performants si la productivité est inférieure à 100%
        if math.ceil(component.productivity * 100) < 100 then
            table.insert(underperforming, {
                component = component,
            })
        end
    end

    -- Calcul de la moyenne de productivité
    if count > 0 then
        local average_productivity = total_productivity / count
        updateSign(averageSign, "Label", string.format("%.2f", average_productivity))
    else
        print("No components found.")
    end

    -- Affichage des machines sous-performantes
    if #underperforming > 0 then
        --print("Underperforming Machines:")
        for _, machine in ipairs(underperforming) do
            --print("Machine:", machine.component.nick, "Productivity:", machine.productivity)
        end
    else
        print("All machines are at 100% productivity.")
    end

    return all_machines, underperforming
end

function updateMonitoringSigns()
    if (selected_machine == nil) then
        return
    end

    print((selected_machine.component.productivity * 100))
    local productivityRounded = math.floor(selected_machine.component.productivity * 100)
    local formattedString = string.format("%s\n──────\n┌            ┐\n%d%%\n└            ┘\n", 
                                        selected_machine.component.nick, productivityRounded)

    if productivityRounded == 100 then
        updateSign(screenGauche, "Name", formattedString, 598, false)
    elseif productivityRounded == 0 then
        updateSign(screenGauche, "Name", formattedString, 341, true)
    else 
        updateSign(screenGauche, "Name", formattedString, 362, false)
    end

    
    -- if (selectedMachineOutput == nil and selectedMachineOutput:getInventory():getStack(0).item == nil) then
    --     updateSign(screenDroiteProduction, "Name", "No output")
    -- else
    --     updateSign(screenDroiteProduction, "Name", selectedMachineOutput:getInventory():getStack(0).item.type.name)
    -- end


    -- if selectedMachineOutput ~= nil then
    --     local outputItem = selectedMachineOutput:getItem()
    --     if outputItem ~= nil then
    --         updateSign(screenDroiteProduction, "Name", outputItem.name)
    --     end
    -- end
end

function selectMachineByPotentiometer(all_machines, potentiometer_value)
    local index = math.min(math.max(1, potentiometer_value), #all_machines) -- Assure l'index dans les limites

    if (selected_machine == nil) then
        selected_machine = all_machines[1]
    else
        selected_machine = all_machines[index]
    end

    -- update the light indicator --
    if selected_machine.standby == true then
        stopButton:setColor(255, 0, 0, 0.01)
    else
        stopButton:setColor(0, 255, 0, 0.01)
    end

    -- Génère la chaîne de caractères pour le panneau de droite
    local selectionString = ""
    for i = 1, #all_machines do
        if i == index then
            selectionString = selectionString .. "■" -- Carré plein pour la machine sélectionnée
        else
            selectionString = selectionString .. "□" -- Carré vide pour les autres machines
        end

        -- Ajouter un retour à la ligne tous les 9 carrés, sauf après le dernier carré
        if i % 9 == 0 and i ~= #all_machines then
            selectionString = selectionString .. "\n"
        end
    end

    -- Met à jour le panneau de droite avec la chaîne de sélection
    updateSign(screenDroite, "Name", selectionString)

    print(selected_machine.component:getType():isChildOf(classes.Manufacturer:getType()))

    if (selected_machine.component:getType():isChildOf(classes.Manufacturer:getType())) then
        local selectedMachineRecipe = getMachineRecipe(selected_machine.component)
        updateSign(screenDroiteProduction, "Name", selectedMachineRecipe)
    else
        updateSign(screenDroiteProduction, "Name", "No recipe")
    end

    -- factoryConnectors = selected_machine.component:getFactoryConnectors()

    -- output = factoryConnectors[1];

    -- event.listen(output)
end

function handleItemTransfer( edata )
    if edata == nil or type( edata[ 1 ] ) ~= "string" or edata[ 1 ] ~= "ItemTransfer" then return nil, nil end
    
    local connector = edata[ 2 ]
    local item = edata[ 3 ]
    local machine = connector.owner
    
    return machine, item
end

function getMachineRecipe( machine )
    return machine:getRecipe():getProducts()[1].type.name
end

function listenToAllMachineFactoryConnectorsByDirection( machines, direction )
    for _, md in pairs( machines ) do
        local actor = md.component
        local connectors = actor:getFactoryConnectors()
        for _, connector in pairs( connectors ) do
            if connector.direction == direction then
                if connector.isConnected then
                    event.listen( connector )
                end
            end
        end
        
    end
end

function getMachines()
    refineries = getComponentsByClass("Factory", false)
    potentiometer.max = #refineries

    selected_machine = {component = refineries[1]}
end

function getModules()

    -- Potentiometer module --
    potentiometer = controlPanel:getModule(0, 0)
    potentiometer.value = 1
    potentiometer.min = 1
    event.listen(potentiometer)

      -- Ecran Switch module --
    ecranSwitch = ecranSwitchPanel:getModule(0, 0)
    ecranSwitch:setText('All')

     -- Switch button module --
    switch = switchPanel:getModule(0, 0)
    event.listen(switch)

    -- Light indicator module --
    light = modularIndicator:getModule(0)
    light:setColor(255, 255, 0, 0.01)

    -- Average light indicator module --
    averageIndicator = averageLightPanel:getModule(0, 0)
    averageIndicator:setColor(255, 0, 0, 0.001)

    -- Stop button module --
    stopButton = stopPanel:getModule(0, 0)
    stopButton:setColor(0, 255, 0, 0.01)
    event.listen(stopButton)
end

function Init()
    event.ignoreAll()
    event.clear()

    debugMode = false --when true, show only underperforming machines
    selected_machine = nil
    getModules()
    getMachines()
end


-- Event handling
function handleEvent(eventData, all_machines, underperforming)
    if eventData == nil then
        return
    end

    local event = eventData[1]
    local sender = eventData[2]
    local val = eventData[3]

    if sender == potentiometer then
        if (debugMode == true) then
            selectMachineByPotentiometer(underperforming, val, potentiometer)
        else
            selectMachineByPotentiometer(all_machines, val, potentiometer)
        end
    elseif sender == switch then
        debugMode = val
        if val == true then
            ecranSwitch:setText("Troubleshoot")
            potentiometer.max = #underperforming
            selectMachineByPotentiometer(underperforming, potentiometer.value, potentiometer)
        else
            ecranSwitch:setText("All")
            potentiometer.max = #all_machines
            selectMachineByPotentiometer(all_machines, potentiometer.value, potentiometer)
        end
    elseif sender == stopButton then
        print("Stop button pressed")
        if (selected_machine.component.standby == true) then
            stopButton:setColor(0, 255, 0, 0.01)
      
            selected_machine.component.standby = false
            print(selected_machine.component.standby)
        else
            stopButton:setColor(255, 0, 0, 0.01)
            selected_machine.component.standby = true
            print(selected_machine.component.standby)
        end
        -- selected_machine.component:stop()
    -- elseif sender == output then
    --     print(val)
    --     if val ~= nil then
    --         -- print("OUTPUT EVENT", val.type.name)
    --     end
    end
end

-- Main --
function Main()
    while true do
        local eventData = { event.pull(5) }

        local all_machines, underperforming = monitorProductivity(refineries)


        -- listenToAllMachineFactoryConnectorsByDirection(all_machines, 1)

        -- local edata = { event.pull( 10.0 ) }            -- Wait for an event, but timeout after 10s
        -- machine, item = handleItemTransfer( edata )

        handleEvent(eventData, all_machines, underperforming)

        updateMonitoringSigns()
    end
end

Init()
Main()
