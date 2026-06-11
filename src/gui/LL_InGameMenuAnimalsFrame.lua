-- LL_InGameMenuAnimalsFrame
-- Override functions in InGameMenuAnimalsFrame
--

-- Append the leased label to animal cards in the main menu animals overview.
InGameMenuAnimalsFrame.populateCellForItemInSection = Utils.overwrittenFunction(
    InGameMenuAnimalsFrame.populateCellForItemInSection,
    function(self, superFunc, list, section, index, cell)
        superFunc(self, list, section, index, cell)
        local subTypeIndex = self.husbandrySubTypes[section]
        local cluster = self.subTypeIndexToClusters[subTypeIndex][index]
        if cluster ~= nil and cluster.isLeased then
            local nameElement = cell:getAttribute("name")
            nameElement:setText(nameElement:getText() .. " " .. g_i18n:getText("ll_leased"))
        end
    end
)
