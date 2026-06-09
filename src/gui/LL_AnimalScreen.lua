-- LL_AnimalScreen
-- Hooks into AnimalScreen to add a Lease button alongside the Buy button.
-- Also extends AnimalScreenDealer with lease-specific logic.
--
-- NOTE: g_animalScreen is created in main.lua before any mod extraSourceFiles are
-- loaded, so onGuiSetupFinished has already fired by the time this file executes.
-- The Lease button is therefore cloned in LL_leaseLivestock:loadMap() instead.

-- AnimalScreen hooks

-- Mirror the Buy button's visibility on the Lease button.
AnimalScreen.setSelectionState = Utils.overwrittenFunction(
    AnimalScreen.setSelectionState,
    function(self, superFunc, state, ...)
        local result = superFunc(self, state, ...)
        if self.buttonLease ~= nil then
            self.buttonLease:setVisible(state == AnimalScreen.SELECTION_AMOUNT and self.isBuyMode)
            self.buttonsPanel:invalidateLayout()
        end
        return result
    end
)

-- Lease button click: show confirmation dialog.
function AnimalScreen:onClickLease()
    self.numAnimals = self.numAnimalsElement:getState()
    local animalIndex   = self.sourceList.selectedIndex
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]

    if self.controller.getApplyLeaseConfirmationText == nil then
        InfoDialog.show("Leasing is not available here.")
        return true
    end

    local text       = self.controller:getApplyLeaseConfirmationText(animalTypeIndex, animalIndex, self.numAnimals)
    local buttonText = g_i18n:getText("ll_leaseButton")
    YesNoDialog.show(self.onYesNoLease, self, text, g_i18n:getText("ui_attention"), buttonText, g_i18n:getText("button_back"))
    return true
end

function AnimalScreen:onYesNoLease(yes)
    if yes then
        local animalIndex     = self.sourceList.selectedIndex
        local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]
        self.controller:applyLease(animalTypeIndex, animalIndex, self.numAnimals)
    end
end

-- AnimalScreenDealer extension

function AnimalScreenDealer:applyLease(animalTypeIndex, itemIndex, numItems)
    local item           = self.sourceItems[animalTypeIndex][itemIndex]
    local subTypeIndex   = item:getSubTypeIndex()
    local age            = item:getAge()
    local buyPrice       = math.abs(item:getPrice()) * numItems
    local leaseRatePerPeriod = math.ceil(buyPrice / 24)

    local errorCode = LL_AnimalLeaseEvent.validate(
        self.husbandry, subTypeIndex, age, numItems, leaseRatePerPeriod,
        self.husbandry:getOwnerFarmId()
    )
    if errorCode ~= nil then
        local mapping = LL_AnimalScreen.LEASE_ERROR_CODE_MAPPING[errorCode]
        self.errorCallback(mapping ~= nil and g_i18n:getText(mapping.text) or "Lease failed")
        return false
    end

    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_SOURCE, g_i18n:getText("ll_leasingAnimals"))
    g_messageCenter:subscribe(LL_AnimalLeaseEvent, self.onAnimalLeased, self)
    g_client:getServerConnection():sendEvent(LL_AnimalLeaseEvent.new(self.husbandry, subTypeIndex, age, numItems))
    return true
end

function AnimalScreenDealer:onAnimalLeased(errorCode)
    g_messageCenter:unsubscribe(LL_AnimalLeaseEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local mapping = LL_AnimalScreen.LEASE_ERROR_CODE_MAPPING[errorCode]
    if mapping ~= nil then
        self.sourceActionFinished(mapping.isWarning, g_i18n:getText(mapping.text))
    else
        self.sourceActionFinished(true, "Unknown lease error (" .. tostring(errorCode) .. ")")
    end
end

function AnimalScreenDealer:getApplyLeaseConfirmationText(animalTypeIndex, itemIndex, numItems)
    local item       = self.sourceItems[animalTypeIndex][itemIndex]
    local buyPrice   = math.abs(item:getPrice()) * numItems
    local leaseRate  = math.ceil(buyPrice / 24)
    local textKey    = numItems == 1 and "ll_leaseConfirmSingular" or "ll_leaseConfirm"
    local rateStr    = g_i18n:formatMoney(leaseRate, 0, true, true)
    local buyoutStr  = g_i18n:formatMoney(buyPrice, 0, true, true)
    local animalType = item:getTitle() .. ", " .. item:getName()
    return string.namedFormat(g_i18n:getText(textKey),
        "numAnimals", numItems,
        "animalType", animalType,
        "rate",       rateStr,
        "buyout",     buyoutStr
    )
end

-- Error codes

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
