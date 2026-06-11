-- LL_leaseLivestock
-- Main driver for LL
--

LL_leaseLivestock = {}
LL_leaseLivestock.dir = g_currentModDirectory

function LL_leaseLivestock:loadMap()
    g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
    if g_animalScreen ~= nil and g_animalScreen.buttonBuy ~= nil then
        g_animalScreen.buttonLease = g_animalScreen.buttonBuy:clone(g_animalScreen.buttonsPanel)
        g_animalScreen.buttonLease:setText(g_i18n:getText("ll_leaseButton"))
        g_animalScreen.buttonLease:setInputAction("LL_LEASE")
        g_animalScreen.buttonLease:setVisible(false)
        g_animalScreen.buttonLease.onClickCallback = AnimalScreen.onClickLease
        g_animalScreen.buttonLease.onClickCallbackTarget = g_animalScreen
        g_animalScreen.buttonsPanel:invalidateLayout()
    end
end

function LL_leaseLivestock:onPeriodChanged()
    -- TODO: implement
end

-- Adds animals to the husbandry, charges the first period, and records the lease.
function LL_leaseLivestock:addLease(object, subTypeIndex, age, numAnimals, farmId, leaseRatePerPeriod, buyoutPrice)
    local animalSystem = g_currentMission.animalSystem
    local cluster = animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
    cluster.isLeased = true
    if cluster:getSupportsMerging() then
        cluster.numAnimals = numAnimals
        cluster.age = age
        cluster.subTypeIndex = subTypeIndex
        object:addCluster(cluster)
    else
        for _ = 1, numAnimals do
            cluster = animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
            cluster.isLeased = true
            cluster.numAnimals = 1
            cluster.age = age
            object:addCluster(cluster)
        end
    end

    g_currentMission:addMoney(-leaseRatePerPeriod, farmId, MoneyType.OTHER, true, true)
end

addModEventListener(LL_leaseLivestock)
