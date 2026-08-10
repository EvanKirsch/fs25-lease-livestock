-- LL_AnimalScreen
-- AnimalScreen hooks, lease buttons and lease error codes
--

-- The Buy/Sell buttons are each one of two known fields depending on screen layout.
local function getBuyButton(self)
    if self.ll_buyButton == nil then
        self.ll_buyButton = self.buttonApply or self.buttonBuy
    end
    return self.ll_buyButton
end

local function getSellButton(self)
    if self.ll_sellButton == nil then
        self.ll_sellButton = self.buttonApply or self.buttonSell
    end
    return self.ll_sellButton
end

-- The "Prices" section header has no stable id exposed to Lua, so it's located by its default text.
local function getPricesLabel(self)
    if self.ll_pricesLabel == nil then
        local pricesText = g_i18n:getText("ui_prices")
        self.ll_pricesLabel = self:getFirstDescendant(function(element)
            return element.getText ~= nil and element:getText() == pricesText
        end)
    end
    return self.ll_pricesLabel
end

-- The currently selected item on the buy side (source list), used to compute the lease rate.
local function getLeaseSourceItem(self)
    local animalIndex = self.sourceList.selectedIndex
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
    local items = self.controller.sourceItems[animalTypeIndex]
    return items ~= nil and items[animalIndex] or nil
end

-- Refreshes the Buy/Sell button text, the Lease toggle's text and pressed state, and the Prices
-- header to match the screen's current buy/sell mode and lease state.
local function refreshLeaseLabels(self)
    local pricesLabel = getPricesLabel(self)

    if self.isBuyMode then
        local buyButton = getBuyButton(self)
        if buyButton ~= nil then
            buyButton:setText(self.isLeaseMode and g_i18n:getText("ll_leaseButton") or self.controller:getSourceActionText())
        end
        if self.buttonBuyLeaseMode ~= nil then
            self.buttonBuyLeaseMode:setText(self.isLeaseMode and g_i18n:getText("ll_buyMode") or g_i18n:getText("ll_leaseMode"))
        end
        if pricesLabel ~= nil then
            pricesLabel:setText(self.isLeaseMode and g_i18n:getText("ll_leasePrices") or g_i18n:getText("ui_prices"))
        end
    else
        local item = self.controller:getTargetItems()[self.sourceList.selectedIndex]
        local isLeased = item ~= nil and item.cluster ~= nil and item.cluster.isLeased

        local sellButton = getSellButton(self)
        if sellButton ~= nil then
            sellButton:setText(isLeased and g_i18n:getText("ll_returnButton") or self.controller:getTargetActionText())
        end
        if pricesLabel ~= nil then
            pricesLabel:setText(isLeased and g_i18n:getText("ll_terminatedLeaseRefund") or g_i18n:getText("ui_prices"))
        end
    end
end

-- Add buy/lease mode change selection state
AnimalScreen.setSelectionState = Utils.overwrittenFunction(
    AnimalScreen.setSelectionState,
    function(self, superFunc, state, ...)
        local result = superFunc(self, state, ...)
        if self.buttonBuyLeaseMode ~= nil then
            self.buttonBuyLeaseMode:setVisible(self.isBuyMode)
            self.buttonsPanel:invalidateLayout()
        end
        refreshLeaseLabels(self)
        return result
    end
)

-- Show lease pricing in the Price/Fee/Total rows while lease mode is toggled on, and drop the
-- transport fee when terminating a lease (return is fee-free, unlike a normal sell).
AnimalScreen.getPrice = Utils.overwrittenFunction(
    AnimalScreen.getPrice,
    function(self, superFunc, numAnimals)
        if self.isBuyMode and self.isLeaseMode then
            local item = getLeaseSourceItem(self)
            if item ~= nil then
                local leaseRate = LL_LeaseLivestock:getAnimalLeaseRate(item:getSubTypeIndex()) * numAnimals
                return true, leaseRate, 0, leaseRate
            end
        elseif not self.isBuyMode then
            local item = self.controller:getTargetItems()[self.sourceList.selectedIndex]
            if item ~= nil and item.cluster ~= nil and item.cluster.isLeased then
                local leaseRate = LL_LeaseLivestock:getAnimalLeaseRate(item:getSubTypeIndex()) * numAnimals
                return true, leaseRate, 0, leaseRate
            end
        end
        return superFunc(self, numAnimals)
    end
)

-- Buy button click: lease instead of buy while lease mode is toggled on.
AnimalScreen.onClickBuy = Utils.overwrittenFunction(
    AnimalScreen.onClickBuy,
    function(self, superFunc)
        if self.isLeaseMode then
            self.numAnimals = self.numAnimalsElement:getState()
            local animalIndex = self.sourceList.selectedIndex
            local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
            local text = self.controller:getApplyLeaseConfirmationText(animalTypeIndex, animalIndex, self.numAnimals)
            local buttonText = g_i18n:getText("ll_leaseButton")
            YesNoDialog.show(self.onYesNoLease, self, text, g_i18n:getText("ui_attention"), buttonText, g_i18n:getText("button_back"))
            return true
        end
        return superFunc(self)
    end
)

-- Sell button click: Terminate lease animals instead of sell while animal custer is leased
AnimalScreen.onClickSell = Utils.overwrittenFunction(
    AnimalScreen.onClickSell,
    function(self, superFunc)
        local animalIndex = self.sourceList.selectedIndex
        local item = self.controller:getTargetItems()[animalIndex]
        if item ~= nil and item.cluster ~= nil and item.cluster.isLeased then
            self.numAnimals = self.numAnimalsElement:getState()
            local text = self.controller:getTerminateLeaseConfimationText(animalIndex, self.numAnimals)
            local buttonText = self.controller:getTargetActionText()
            YesNoDialog.show(self.onYesNoTarget, self, text, g_i18n:getText("ui_attention"), buttonText, g_i18n:getText("button_back"))
            return true
        end
        return superFunc(self)
    end
)

-- Add the lease status to the animal's name in the info box
AnimalScreen.updateInfoBox = Utils.overwrittenFunction(
    AnimalScreen.updateInfoBox,
    function(self, superFunc, ...)
        local result = superFunc(self, ...)
        if not self.isBuyMode and not g_gui.currentlyReloading then
            -- in sell mode only tag as leased if from leased cluster
            local item = self.controller:getTargetItems()[self.sourceList.selectedIndex]
            if item ~= nil and item.cluster ~= nil and item.cluster.isLeased then
                self.infoName:setText(self.infoName:getText() .. " " .. g_i18n:getText("ll_leased"))
            end
        elseif self.isBuyMode and self.isLeaseMode and not g_gui.currentlyReloading then
            -- if buy mode and lease mode, add lease tag to all info boxes
            local item = self.controller:getTargetItems()[self.sourceList.selectedIndex]
            if item ~= nil then
                self.infoName:setText(self.infoName:getText() .. " " .. g_i18n:getText("ll_leased"))
            end
        end
        return result
    end
)

-- Append the leased label to the name on each animal card in the sell list, and show the lease
-- rate instead of the buy price on each card in the buy list while lease mode is toggled on.
AnimalScreen.populateCellForItemInSection = Utils.overwrittenFunction(
    AnimalScreen.populateCellForItemInSection,
    function(self, superFunc, list, section, index, cell)
        superFunc(self, list, section, index, cell)
        if list == self.sourceList and not self.isBuyMode then
            -- In sell mode always display leased tag for livestock
            local item = self.controller:getTargetItems()[index]
            if item ~= nil and item.cluster ~= nil and item.cluster.isLeased then
                local nameElement = cell:getAttribute("name")
                nameElement:setText(nameElement:getText() .. " " .. g_i18n:getText("ll_leased"))
            end
        elseif list == self.sourceList and self.isBuyMode and self.isLeaseMode then
            -- In buy mode, if in lease mode display leased tag for livestock and override the price
            local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
            local item = self.controller:getSourceItems(animalTypeIndex, self.isBuyMode)[index]
            if item ~= nil then
                local nameElement = cell:getAttribute("name")
                nameElement:setText(nameElement:getText() .. " " .. g_i18n:getText("ll_leased"))
                local leaseRate = LL_LeaseLivestock:getAnimalLeaseRate(item:getSubTypeIndex())
                cell:getAttribute("price"):setValue(leaseRate)
            end
        end
    end
)

-- Registers the LL_BUY_LEASE_MODE hotkey alongside the base game's action events; setInputAction()
-- on the button only sets its key glyph, it does not by itself make the key do anything.
AnimalScreen.registerActionEvents = Utils.overwrittenFunction(
    AnimalScreen.registerActionEvents,
    function(self, superFunc, ...)
        local result = superFunc(self, ...)
        g_inputBinding:registerActionEvent(InputAction.LL_BUY_LEASE_MODE, self, self.onClickToggleLeaseMode, false, true, false, true)
        return result
    end
)

-- Lease button click: toggle the screen mode between buying and leasing.
function AnimalScreen:onClickToggleLeaseMode()
    if not self.isLeaseMode and self.controller.getApplyLeaseConfirmationText == nil then
        InfoDialog.show(g_i18n:getText("ll_leaseNotAvailable"))
        return true
    end
    self.isLeaseMode = not self.isLeaseMode
    refreshLeaseLabels(self)
    self:updatePrice()
    self.sourceList:reloadData(true)
    return true
end

function AnimalScreen:onYesNoLease(yes)
    if yes then
        local animalIndex = self.sourceList.selectedIndex
        local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
        self.controller:applyLease(animalTypeIndex, animalIndex, self.numAnimals)
    end
end

-- Error codes for animal screen

LL_AnimalScreen = {}
LL_AnimalScreen.LEASE_ERROR_CODE_MAPPING = {
    [LL_AnimalLeaseEvent.LEASE_SUCCESS] = {
        isWarning = false,
        text      = "ll_leaseSuccess",
    },
    [LL_AnimalLeaseEvent.LEASE_ERROR_NO_PERMISSION] = {
        isWarning = true,
        text      = "shop_messageNoPermissionToTradeAnimals",
    },
    [LL_AnimalLeaseEvent.LEASE_ERROR_NOT_ENOUGH_MONEY] = {
        isWarning = true,
        text      = "shop_messageNotEnoughMoneyToBuy",
    },
    [LL_AnimalLeaseEvent.LEASE_ERROR_NOT_ENOUGH_SPACE] = {
        isWarning = true,
        text      = "shop_messageNotEnoughSpaceAnimals",
    },
    [LL_AnimalLeaseEvent.LEASE_ERROR_ANIMAL_NOT_SUPPORTED] = {
        isWarning = true,
        text      = "shop_messageAnimalTypeNotSupported",
    },
    [LL_AnimalLeaseEvent.LEASE_ERROR_ANIMAL_GLOBAL_LIMIT_REACHED] = {
        isWarning = true,
        text      = "shop_messageAnimalGlobalLimitReached",
    },
    [LL_AnimalLeaseEvent.LEASE_ERROR_OBJECT_DOES_NOT_EXIST] = {
        isWarning = true,
        text      = "shop_messageHusbandryDoesNotExist",
    },
    [LL_AnimalLeaseEvent.LEASE_ERROR_NO_BARN_AVAILABLE] = {
        isWarning = true,
        text      = "shop_messageHusbandryBuyBarnFirst",
    },
}
