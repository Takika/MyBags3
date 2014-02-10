local L = LibStub("AceLocale-3.0"):NewLocale("MyBagsCache", "enUS", true, true)

if not L then 
	print("AceLocale not loaded")
	return
end

L["ACE_TEXT_OF"] = "of";
L["CHARACTER_DELIMITOR"] = " of ";
L["SplitString must be passed a string as the first argument"] = "SplitString must be passed a string as the first argument";

