-- LL_leaseLivestock
-- Main driver for LL
--

LL_leaseLivestock = {}
LL_leaseLivestock.dir = g_currentModDirectory
LL_leaseLivestock.leases = {}     -- [leaseId] = { farmId, subTypeIndex, numAnimals, leaseRatePerPeriod, buyoutPrice, totalPaid }
LL_leaseLivestock.nextLeaseId = 1

function LL_leaseLivestock:loadMap()
    g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
    -- TODO: load leases from savegame XML

    -- g_animalScreen.onGuiSetupFinished already fired before mod extraSourceFiles load,
    -- so we create the Lease button here while g_animalScreen is live.
    if g_animalScreen ~= nil and g_animalScreen.buttonBuy ~= nil then
        g_animalScreen.buttonLease = g_animalScreen.buttonBuy:clone(g_animalScreen.buttonsPanel)
        g_animalScreen.buttonLease:setText(g_i18n:getText("ll_leaseButton"))
        g_animalScreen.buttonLease:setVisible(false)
        g_animalScreen.buttonLease.onClickCallback = AnimalScreen.onClickLease
        g_animalScreen.buttonLease.onClickCallbackTarget = g_animalScreen
        g_animalScreen.buttonsPanel:invalidateLayout()
    end
end

function LL_leaseLivestock:onPeriodChanged()
    if not g_currentMission:getIsServer() then return end
    for _, lease in pairs(LL_leaseLivestock.leases) do
        g_currentMission:addMoney(-lease.leaseRatePerPeriod, lease.farmId, MoneyType.OTHER, true, true)
        lease.totalPaid = lease.totalPaid + lease.leaseRatePerPeriod
    end
end

-- Adds animals to the husbandry, charges the first period, and records the lease.
-- Returns the new leaseId.
function LL_leaseLivestock:addLease(object, subTypeIndex, age, numAnimals, farmId, leaseRatePerPeriod, buyoutPrice)
    object:addAnimals(subTypeIndex, numAnimals, age)
    g_currentMission:addMoney(-leaseRatePerPeriod, farmId, MoneyType.OTHER, true, true)

    local leaseId = LL_leaseLivestock.nextLeaseId
    LL_leaseLivestock.nextLeaseId = LL_leaseLivestock.nextLeaseId + 1
    LL_leaseLivestock.leases[leaseId] = {
        farmId             = farmId,
        subTypeIndex       = subTypeIndex,
        numAnimals         = numAnimals,
        leaseRatePerPeriod = leaseRatePerPeriod,
        buyoutPrice        = buyoutPrice,
        totalPaid          = leaseRatePerPeriod,
    }
    -- TODO: persist leases to savegame XML
    return leaseId
end

-- Charges the remaining buyout balance and clears the lease record.
-- Animals stay in the barn — they are now fully owned.
function LL_leaseLivestock:rebuyLease(leaseId, farmId)
    local lease     = LL_leaseLivestock.leases[leaseId]
    local remaining = math.max(lease.buyoutPrice - lease.totalPaid, 0)
    if remaining > 0 then
        g_currentMission:addMoney(-remaining, farmId, MoneyType.NEW_ANIMALS_COST, true, true)
    end
    LL_leaseLivestock.leases[leaseId] = nil
    -- TODO: persist leases to savegame XML
end

addModEventListener(LL_leaseLivestock)
