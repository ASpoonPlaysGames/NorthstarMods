"resource/ui/menus/panels/mod_setting.res"
{
	"BtnMod"
	{
		"ControlName" "Label"
		"InheritProperties" "RuiSmallButton"
		"labelText" "Mod"
		//"auto_wide_tocontents" "1"
		"navRight" "EnumSelectButton"
		"navLeft" "TextEntrySetting"
		"wide" "390"
		"tall" "45"
	}
	// we're getting to the top of this :)
	"TopLine"
	{
		"ControlName" "ImagePanel"
		"InheritProperties" "MenuTopBar"
		"ypos" "0"
		"wide" "%100"
		"pin_to_sibling" "BtnMod"
		"pin_corner_to_sibling" "TOP_LEFT"
		"pin_to_sibling_corner" "TOP_LEFT"
	}
	"ModTitle"
	{
		"ControlName" "Label"
		"InheritProperties" "RuiSmallButton"
		"labelText" "Mod"
		"font"		"DefaultBold_43"
		//"auto_wide_tocontents" "1"
		"zpos"	"-999"
		"textAlignment"				"center"
		"navRight" "EnumSelectButton"
		"navLeft" "TextEntrySetting"
		"wide" "1200"
		"tall" "45"

	}
	"Slider"
	{
		"ControlName"			"SliderControl"
		//"InheritProperties"	"RuiSmallButton"
		minValue				0.0
		maxValue				2.0
		stepSize				0.05
		"pin_to_sibling" "BtnMod"
		"pin_corner_to_sibling" "TOP_LEFT"
		"pin_to_sibling_corner" "TOP_RIGHT"
		"navRight" "ResetModToDefault"
		"navLeft" "TextEntrySetting"
		//isValueClampedToStepSize 1
		BtnDropButton
		{
			ControlName				RuiButton
			//InheritProperties		WideButton
			style					SliderButton
			"wide"		"320"
			"tall"		"45"
			"labelText"		""
			"auto_wide_tocontents"		"0"
		}
		"wide"		"320"
		"tall"		"45"
	}
	"EnumSelectButton"
	{
		"ControlName" "RuiButton"
		"InheritProperties" "RuiSmallButton"
		"style" "DialogListButton"
		"labelText" ""
		"zpos" "4"
		"wide" "225"
		"tall" "45"
		"xpos"		"10"
		"scriptID" "0"
		"pin_to_sibling" "ResetModToDefault"
		"pin_corner_to_sibling" "TOP_LEFT"
		"pin_to_sibling_corner" "TOP_RIGHT"
		"navLeft" "ResetModToDefault"
		"navRight" "TextEntrySetting"
	}
	"ResetModToDefault"
	{
		"ControlName" "RuiButton"
		"InheritProperties" "RuiSmallButton"
		"labelText" "Reset"
		"zpos" "4"
		"xpos"		"10"
		"wide" "120"
		"tall" "45"
		"scriptID" "0"
		"pin_to_sibling" "Slider"
		"pin_corner_to_sibling" "TOP_LEFT"
		"pin_to_sibling_corner" "TOP_RIGHT"
		"navLeft" "Slider"
		"navRight" "TextEntrySetting"
	}
	"OpenCustomMenu"
	{
		"ControlName" "RuiButton"
		"InheritProperties" "RuiSmallButton"
		"labelText" "Open"
		"zpos" "4"
		"wide" "85"
		"xpos"		"10"
		"tall" "45"
		"scriptID" "0"
		"pin_to_sibling" "BtnMod"
		"pin_corner_to_sibling" "TOP_LEFT"
		"pin_to_sibling_corner" "TOP_RIGHT"
		"navLeft" "TextEntrySetting"
		"navRight" "TextEntrySetting"
	}
	"TextEntrySetting"
	{
		"ControlName" "TextEntry"
		"classname" "MatchSettingTextEntry"
		"xpos" "-35"
		"ypos" "-5"
		"zpos" "100"	// This works around input weirdness when the control is constructed by code instead of VGUI blackbox.
		"wide" "160"
		"tall" "30"
		"scriptID" "0"
		"textHidden" "0"
		"editable" "1"
		// NumericInputOnly 1
		"font" "Default_21"
		"allowRightClickMenu" "0"
		"allowSpecialCharacters" "1"
		"unicode" "0"
		"pin_to_sibling" "EnumSelectButton"
		"pin_corner_to_sibling" "TOP_RIGHT"
		"pin_to_sibling_corner" "TOP_RIGHT"
		"navLeft" "EnumSelectButton"
		"navRight" "EnumSelectButton"
	}
	// we're getting to the bottom of this :)
	"BottomLine"
	{
		"ControlName" "ImagePanel"
		"InheritProperties" "MenuTopBar"
		"ypos" "0"
		"wide" "%100"
		"pin_to_sibling" "BtnMod"
		"pin_corner_to_sibling" "TOP_LEFT"
		"pin_to_sibling_corner" "BOTTOM_LEFT"
	}
}
