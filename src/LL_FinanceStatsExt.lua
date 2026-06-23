-- Add Money Type and entries needed to display on finance screen

table.insert(FinanceStats.statNames, "livestockLeasingCost")
FinanceStats.statNameToIndex["livestockLeasingCost"] = #FinanceStats.statNames

FinanceStats.new = Utils.overwrittenFunction(FinanceStats.new, function(customMt, superFunc)
    local self = superFunc(customMt)
    FinanceStats.statNamesI18n["livestockLeasingCost"] = g_i18n:getText("ll_finance_livestockLeasingCost", g_currentModName)
    return self
end)

MoneyType.LIVESTOCK_LEASING_COST = MoneyType.register("livestockLeasingCost", "ll_finance_livestockLeasingCost", g_currentModName)
