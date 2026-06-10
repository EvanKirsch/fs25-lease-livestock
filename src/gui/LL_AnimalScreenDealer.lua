-- LL_AnimalScreenDealer
-- Extends AnimalScreenDealer and AnimalScreenDealerFarm with lease-specific logic.
--

LL_AnimalScreenDealer = {}

function LL_AnimalScreenDealer:applyLease(animalTypeIndex, itemIndex, numItems)
    print("AnimalScreen applyLease")
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    local subTypeIndex = item:getSubTypeIndex()
    local age = item:getAge()
    local buyPrice = math.abs(item:getPrice()) * numItems
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

function LL_AnimalScreenDealer:onAnimalLeased(errorCode)
    g_messageCenter:unsubscribe(LL_AnimalLeaseEvent, self)
    self.actionTypeCallback(AnimalScreenBase.ACTION_TYPE_NONE, nil)
    local mapping = LL_AnimalScreen.LEASE_ERROR_CODE_MAPPING[errorCode]
    if mapping ~= nil then
        self.sourceActionFinished(mapping.isWarning, g_i18n:getText(mapping.text))
    else
        self.sourceActionFinished(true, "Unknown lease error (" .. tostring(errorCode) .. ")")
    end
end

function LL_AnimalScreenDealer:getApplyLeaseConfirmationText(animalTypeIndex, itemIndex, numItems)
    print("AnimalScreenDealer getApplyLeaseConfirmationText")
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    local buyPrice = math.abs(item:getPrice()) * numItems
    local leaseRate = math.ceil(buyPrice / 24)
    local textKey = numItems == 1 and "ll_leaseConfirmSingular" or "ll_leaseConfirm"
    local rateStr = g_i18n:formatMoney(leaseRate, 0, true, true)
    local buyoutStr = g_i18n:formatMoney(buyPrice, 0, true, true)
    local animalType = item:getTitle() .. ", " .. item:getName()
    return string.namedFormat(g_i18n:getText(textKey),
        "numAnimals", numItems,
        "animalType", animalType,
        "rate",       rateStr,
        "buyout",     buyoutStr
    )
end

-- Configure lease buttons on dealer screens

AnimalScreenDealer.applyLease = LL_AnimalScreenDealer.applyLease
AnimalScreenDealer.onAnimalLeased = LL_AnimalScreenDealer.onAnimalLeased
AnimalScreenDealer.getApplyLeaseConfirmationText = LL_AnimalScreenDealer.getApplyLeaseConfirmationText

AnimalScreenDealerFarm.applyLease = LL_AnimalScreenDealer.applyLease
AnimalScreenDealerFarm.onAnimalLeased = LL_AnimalScreenDealer.onAnimalLeased
AnimalScreenDealerFarm.getApplyLeaseConfirmationText = LL_AnimalScreenDealer.getApplyLeaseConfirmationText
