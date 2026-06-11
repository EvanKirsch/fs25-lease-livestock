-- LL_AnimalScreen
-- AnimalScreen hooks, lease buttons and lease error codes
--

-- Mirror the Buy button's visibility on the Lease button.
AnimalScreen.setSelectionState = Utils.overwrittenFunction(
    AnimalScreen.setSelectionState,
    function(self, superFunc, state, ...)
        local result = superFunc(self, state, ...)
        if self.buttonLease ~= nil then
            self.buttonLease:setVisible(self.selectionState == AnimalScreen.SELECTION_AMOUNT and self.isBuyMode)
            self.buttonsPanel:invalidateLayout()
        end
        return result
    end
)

-- Add the lease status to the animal's name in the info box
AnimalScreen.updateInfoBox = Utils.overwrittenFunction(
    AnimalScreen.updateInfoBox,
    function(self, superFunc, ...)
        local result = superFunc(self, ...)
        if not self.isBuyMode and not g_gui.currentlyReloading then
            local item = self.controller:getTargetItems()[self.sourceList.selectedIndex]
            if item ~= nil and item.cluster ~= nil and item.cluster.isLeased then
                self.infoName:setText(self.infoName:getText() .. " " .. g_i18n:getText("ll_leased"))
            end
        end
        return result
    end
)

-- Append the leased label to the name on each animal card in the sell list.
AnimalScreen.populateCellForItemInSection = Utils.overwrittenFunction(
    AnimalScreen.populateCellForItemInSection,
    function(self, superFunc, list, section, index, cell)
        superFunc(self, list, section, index, cell)
        if list == self.sourceList and not self.isBuyMode then
            local item = self.controller:getTargetItems()[index]
            if item ~= nil and item.cluster ~= nil and item.cluster.isLeased then
                local nameElement = cell:getAttribute("name")
                nameElement:setText(nameElement:getText() .. " " .. g_i18n:getText("ll_leased"))
            end
        end
    end
)

-- Lease button click: show confirmation dialog.
function AnimalScreen:onClickLease()
    self.numAnimals = self.numAnimalsElement:getState()
    local animalIndex = self.sourceList.selectedIndex
    local animalTypeIndex = self.sourceSelectorStateToAnimalType[self.sourceSelector:getState()]

    if self.controller.getApplyLeaseConfirmationText == nil then
        InfoDialog.show(g_i18n:getText("ll_leaseNotAvailable"))
        return true
    end

    local text = self.controller:getApplyLeaseConfirmationText(animalTypeIndex, animalIndex, self.numAnimals)
    local buttonText = g_i18n:getText("ll_leaseButton")
    YesNoDialog.show(self.onYesNoLease, self, text, g_i18n:getText("ui_attention"), buttonText, g_i18n:getText("button_back"))
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
