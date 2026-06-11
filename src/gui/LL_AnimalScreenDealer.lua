-- LL_AnimalScreenDealer
-- Extends AnimalScreenDealer and AnimalScreenDealerFarm with lease-specific logic.
--

LL_AnimalScreenDealer = {}

function LL_AnimalScreenDealer:applyLease(animalTypeIndex, itemIndex, numItems)
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    local subTypeIndex = item:getSubTypeIndex()
    local age = item:getAge()

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
        self.sourceActionFinished(true, g_i18n:getText("ll_leaseUnknownError"))
    end
end

function LL_AnimalScreenDealer:getApplyLeaseConfirmationText(animalTypeIndex, itemIndex, numItems)
    local item = self.sourceItems[animalTypeIndex][itemIndex]
    local buyPrice = math.abs(item:getPrice()) * numItems
    local leaseRate = math.ceil(buyPrice / 24)
    local rateStr = g_i18n:formatMoney(leaseRate, 0, true, true)
    local buyoutStr = g_i18n:formatMoney(buyPrice, 0, true, true)
    local animalType = item:getTitle() .. ", " .. item:getName()
    return string.namedFormat(g_i18n:getText("ll_leaseConfirm"),
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
