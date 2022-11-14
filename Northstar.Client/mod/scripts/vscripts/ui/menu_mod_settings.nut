untyped
global function AddModSettingsMenu
global function AddConVarSetting
global function AddConVarSettingEnum
global function AddConVarSettingSlider
global function AddModTitle
global function AddModCategory
global function PureModulo

const int BUTTONS_PER_PAGE = 15
const string SETTING_ITEM_TEXT = "                        " // this is long enough to be the same size as the textentry field

enum eEmptySpaceType 
{
	None, 
	TopBar,
	BottomBar
}

struct ConVarData {
	string displayName
	bool isEnumSetting = false
	string conVar
	string type

	string modName
	string catName
	bool isCategoryName = false
	bool isModName = false

	bool isEmptySpace = false
	int spaceType = 0
	
	// SLIDER BULLSHIT
	bool sliderEnabled = false
	float min = 0.0
	float max = 1.0
	float stepSize = 0.05
	bool forceClamp = false

	bool isCustomButton = false
	void functionref() onPress

	array< string > values
	var customMenu
	bool hasCustomMenu = false
}

struct {
	var menu
	int scrollOffset = 0
	bool updatingList = false

	array< ConVarData > conVarList
	// if people use searches - i hate them but it'll do : )
	array< ConVarData > filteredList
	string filterText = ""
	table< int, int > enumRealValues
	table< string, bool > setFuncs
	array< var > modPanels
	array< MS_Slider > sliders
	table settingsTable
	string currentMod = ""
	string currentCat = ""
} file

struct {
	int deltaX = 0
	int deltaY = 0
} mouseDeltaBuffer

void function AddModSettingsMenu()
{
	AddMenu( "ModSettings", $"resource/ui/menus/mod_settings.menu", InitModMenu )
}

void function InitModMenu()
{
	file.menu = GetMenu( "ModSettings" )
	// DumpStack(2)
	AddMenuFooterOption( file.menu, BUTTON_B, "#B_BUTTON_BACK", "#BACK" )

	// Safe I/O stuff
	// uncomment when safe i/o is merged.

	/*
	try
	{
		file.settingsTable = expect table( compilestring( "return NSLoadFile( \"Mod Settings\", \"settings\" )" )() )
	}
	catch ( ex )
	{
	}

	foreach ( string key, var value in file.settingsTable )
	{
		printt( key, expect string( value ) )
		try
		{
			SetConVarString( key, expect string( value ) )
		}
		catch ( ex )
		{
			
		}
	}*/

	// // // // // // // // // // // // // // /
	// BASE NORTHSTAR SETTINGS // 
	// // // // // // // // // // // // // // /

	// most of these are overrided in the cfg, maybe ask bob to remove the cfg stuff from there?
	// at the same time, might fuck with dedis so idk.
	// these are pretty long too, might need to e x t e n d the settings menu
	AddModTitle( "#NORTHSTAR_BASE_SETTINGS" )
	AddModCategory( "#PRIVATE_MATCH" )
	AddConVarSettingEnum( "ns_private_match_only_host_can_change_settings", "#ONLY_HOST_MATCH_SETTINGS", [ "#NO", "#YES" ] )
	AddConVarSettingEnum( "ns_private_match_only_host_can_change_settings", "#ONLY_HOST_CAN_START_MATCH", [ "#NO", "#YES" ] )
	AddConVarSettingSlider( "ns_private_match_countdown_length", "#MATCH_COUNTDOWN_LENGTH", 0, 30, 0.5 )
	// probably shouldn't add this as a setting?
	// AddConVarSettingEnum( "ns_private_match_override_maxplayers", "Override Max Player Count", "Northstar - Server", [ "#NO", "#YES" ] )
	AddModCategory( "#SERVER" )
	AddConVarSettingEnum( "ns_should_log_unknown_clientcommands", "#LOG_UNKNOWN_CLIENTCOMMANDS", [ "#NO", "#YES" ] )
	AddConVarSetting( "ns_disallowed_tacticals", "#DISALLOWED_TACTICALS" )
	AddConVarSetting( "ns_disallowed_tactical_replacement", "#TACTICAL_REPLACEMENT" )
	AddConVarSetting( "ns_disallowed_weapons", "#DISALLOWED_WEAPONS" )
	AddConVarSetting( "ns_disallowed_weapon_primary_replacement", "#REPLACEMENT_WEAPON" )
	AddConVarSettingEnum( "ns_should_return_to_lobby", "#SHOULD_RETURN_TO_LOBBY", [ "#NO", "#YES" ] )

	/*
	AddModTitle( "^FF000000EXAMPLE" )
	AddModCategory( "I wasted way too much time on this..." )
	AddModSettingsButton( "This is a custom button you can click on!", void function() : (){
		print( "HELLOOOOOO" )
	} )
	AddConVarSettingEnum( "filter_mods", "Very Huge Enum Example", split( "Never gonna give you up Never gonna let you down Never gonna run around and desert you Never gonna make you cry Never gonna say goodbye Never gonna tell a lie and hurt you", " " ) )
	*/
	// Nuke weird rui on filter switch :D
	// RuiSetString( Hud_GetRui( Hud_GetChild( file.menu, "SwtBtnShowFilter" ) ), "buttonText", "" )

	file.modPanels = GetElementsByClassname( file.menu, "ModButton" )

	AddMenuEventHandler( file.menu, eUIEvent.MENU_OPEN, OnModMenuOpened )
	AddMenuEventHandler( file.menu, eUIEvent.MENU_CLOSE, OnModMenuClosed )

	int len = file.modPanels.len()
	for ( int i = 0; i < len; i++ )
	{
		
		// AddButtonEventHandler( button, UIE_CHANGE, OnSettingButtonPressed  )
		// get panel
		var panel = file.modPanels[i]

		// reset to default nav
		var child = Hud_GetChild( panel, "BtnMod" )


		child.SetNavUp( Hud_GetChild( file.modPanels[ int( PureModulo( i - 1, len ) ) ], "BtnMod" ) )
		child.SetNavDown( Hud_GetChild( file.modPanels[ int( PureModulo( i + 1, len ) ) ], "BtnMod" ) )

		// Enum button nav
		child = Hud_GetChild( panel, "EnumSelectButton" )
		Hud_DialogList_AddListItem( child, SETTING_ITEM_TEXT, "main" )
		Hud_DialogList_AddListItem( child, SETTING_ITEM_TEXT, "next" )
		Hud_DialogList_AddListItem( child, SETTING_ITEM_TEXT, "prev" )

		child.SetNavUp( Hud_GetChild( file.modPanels[ int( PureModulo( i - 1, len ) ) ], "EnumSelectButton" ) )
		child.SetNavDown( Hud_GetChild( file.modPanels[ int( PureModulo( i + 1, len ) ) ], "EnumSelectButton" ) )
		Hud_AddEventHandler( child, UIE_CLICK, UpdateEnumSetting )

		// reset button nav
		
		child = Hud_GetChild( panel, "ResetModToDefault" )

		child.SetNavUp( Hud_GetChild( file.modPanels[ int( PureModulo( i - 1, len ) ) ], "ResetModToDefault" ) )
		child.SetNavDown( Hud_GetChild( file.modPanels[ int( PureModulo( i + 1, len ) ) ], "ResetModToDefault" ) )

		Hud_AddEventHandler( child, UIE_CLICK, ResetConVar )
		
		// text field nav
		child = Hud_GetChild( panel, "TextEntrySetting" )

		// 
		Hud_AddEventHandler( child, UIE_LOSE_FOCUS, SendTextPanelChanges )

		child.SetNavUp( Hud_GetChild( file.modPanels[ int( PureModulo( i - 1, len ) ) ], "TextEntrySetting" ) )
		child.SetNavDown( Hud_GetChild( file.modPanels[ int( PureModulo( i + 1, len ) ) ], "TextEntrySetting" ) )

		child = Hud_GetChild( panel, "Slider" )

		child.SetNavUp( Hud_GetChild( file.modPanels[ int( PureModulo( i - 1, len ) ) ], "Slider" ) )
		child.SetNavDown( Hud_GetChild( file.modPanels[ int( PureModulo( i + 1, len ) ) ], "Slider" ) )

		file.sliders.append( MS_Slider_Setup( child ) )

		Hud_AddEventHandler( child, UIE_CHANGE, OnSliderChange )

		child = Hud_GetChild( panel, "OpenCustomMenu" )

		Hud_AddEventHandler( child, UIE_CLICK, CustomButtonPressed )
	}

	// Hud_AddEventHandler( Hud_GetChild( file.menu, "BtnModsSearch" ), UIE_LOSE_FOCUS, OnFilterTextPanelChanged )
	Hud_AddEventHandler( Hud_GetChild( file.menu, "BtnFiltersClear" ), UIE_CLICK, OnClearButtonPressed )
	// mouse delta 
	AddMouseMovementCaptureHandler( file.menu, UpdateMouseDeltaBuffer )

	Hud_AddEventHandler( Hud_GetChild( file.menu, "BtnModsSearch" ), UIE_CHANGE, void function ( var inputField ) : (){
		file.filterText = Hud_GetUTF8Text( inputField )
		OnFiltersChange(0)
	} )
}

// "PureModulo"
// Used instead of modulo in some places.
// Why? beacuse PureModulo loops back onto positive numbers instead of going into the negatives.
// DO NOT TOUCH.
// a / b != floor( float( a ) / b ) 
// int( float( a ) / b ) != floor( float( a ) / b )
// Examples:
// -1 % 5 = -1
// PureModulo( -1, 5 ) = 4
float function PureModulo( int a, int b )
{
	return b * ( ( float( a ) / b ) - floor( float( a ) / b ) )
}

void function ResetConVar( var button )
{
	ConVarData conVar = file.filteredList[ int ( Hud_GetScriptID( Hud_GetParent( button ) ) ) + file.scrollOffset ]

	if ( conVar.isCategoryName )
	{
		ShowAreYouSureDialog( "#ARE_YOU_SURE", ResetAllConVarsForModEventHandler( conVar.catName ), "#WILL_RESET_ALL_SETTINGS"  )
	}
	else ShowAreYouSureDialog( "#ARE_YOU_SURE", ResetConVarEventHandler( int ( Hud_GetScriptID( Hud_GetParent( button ) ) ) + file.scrollOffset ), Localize( "#WILL_RESET_SETTING", Localize( conVar.displayName ) ) )
}

void function ShowAreYouSureDialog( string header, void functionref() func, string details )
{
	DialogData dialogData
	dialogData.header = header
	dialogData.message = details

	AddDialogButton( dialogData, "#NO" )
	AddDialogButton( dialogData, "#YES", func )

	AddDialogFooter( dialogData, "#A_BUTTON_SELECT" )
	AddDialogFooter( dialogData, "#B_BUTTON_BACK" )

	OpenDialog( dialogData )
}

void functionref() function ResetAllConVarsForModEventHandler( string catName )
{
	return void function() : ( catName )
	{
		for ( int i = 0; i < file.conVarList.len(); i++ )
		{
			ConVarData c = file.conVarList[i]
			if ( c.catName != catName || c.isCategoryName || c.isEmptySpace ) continue
			SetConVarToDefault( c.conVar )

			int index = file.filteredList.find( c )
			if ( file.filteredList.find( c ) < 0 ) continue

			if ( min( BUTTONS_PER_PAGE, max( 0, index - file.scrollOffset ) ) == index - file.scrollOffset )
				Hud_SetText( Hud_GetChild( file.modPanels[ i - file.scrollOffset ], "TextEntrySetting" ), c.isEnumSetting ? c.values[ GetConVarInt( c.conVar ) ] : GetConVarString( c.conVar ) )
		}
	}
}

void functionref() function ResetConVarEventHandler( int modIndex )
{
	return void function() : ( modIndex )
	{
		ConVarData c = file.filteredList[ modIndex ]
		SetConVarToDefault( c.conVar )
		if ( min( BUTTONS_PER_PAGE, max( 0, modIndex - file.scrollOffset ) ) == modIndex - file.scrollOffset )
			Hud_SetText( Hud_GetChild( file.modPanels[ modIndex - file.scrollOffset ], "TextEntrySetting" ), c.isEnumSetting ? c.values[ GetConVarInt( c.conVar ) ] : GetConVarString( c.conVar ) )
	}
}

// // // // // // // // // // // // 
// slider
// // // // // // // // // // // // 
void function UpdateMouseDeltaBuffer( int x, int y )
{
	mouseDeltaBuffer.deltaX += x
	mouseDeltaBuffer.deltaY += y

	SliderBarUpdate()
}

void function FlushMouseDeltaBuffer()
{
	mouseDeltaBuffer.deltaX = 0
	mouseDeltaBuffer.deltaY = 0
}

void function SliderBarUpdate()
{
	if ( file.filteredList.len() < = 15 )
	{
		FlushMouseDeltaBuffer()
		return
	}

	var sliderButton = Hud_GetChild( file.menu , "BtnModListSlider" )
	var sliderPanel = Hud_GetChild( file.menu , "BtnModListSliderPanel" )
	var movementCapture = Hud_GetChild( file.menu , "MouseMovementCapture" )

	Hud_SetFocused( sliderButton )

	float minYPos = -40.0 * ( GetScreenSize()[1] / 1080.0 ) // why the hardcoded positions?!?!?!?!?!
	float maxHeight = 615.0  * ( GetScreenSize()[1] / 1080.0 )
	float maxYPos = minYPos - ( maxHeight - Hud_GetHeight( sliderPanel ) )
	float useableSpace = ( maxHeight - Hud_GetHeight( sliderPanel ) )

	float jump = minYPos - ( useableSpace / ( float( file.filteredList.len() ) ) )

	// got local from official respaw scripts, without untyped throws an error
	local pos =	Hud_GetPos( sliderButton )[1]
	local newPos = pos - mouseDeltaBuffer.deltaY
	FlushMouseDeltaBuffer()

	if ( newPos < maxYPos ) newPos = maxYPos
	if ( newPos > minYPos ) newPos = minYPos

	Hud_SetPos( sliderButton , 2, newPos )
	Hud_SetPos( sliderPanel , 2, newPos )
	Hud_SetPos( movementCapture , 2, newPos )

	file.scrollOffset = -int( ( ( newPos - minYPos ) / useableSpace ) * ( file.filteredList.len() - BUTTONS_PER_PAGE ) )
	UpdateList()
}

void function UpdateListSliderHeight()
{
	var sliderButton = Hud_GetChild( file.menu , "BtnModListSlider" )
	var sliderPanel = Hud_GetChild( file.menu , "BtnModListSliderPanel" )
	var movementCapture = Hud_GetChild( file.menu , "MouseMovementCapture" )
	
	float mods = float ( file.filteredList.len() )

	float maxHeight = 615.0 * ( GetScreenSize()[1] / 1080.0 ) // why the hardcoded 320/80???
	float minHeight = 80.0 * ( GetScreenSize()[1] / 1080.0 )

	float height = maxHeight * ( float( BUTTONS_PER_PAGE ) / mods )

	if ( height > maxHeight ) height = maxHeight
	if ( height < minHeight ) height = minHeight

	Hud_SetHeight( sliderButton , height )
	Hud_SetHeight( sliderPanel , height )
	Hud_SetHeight( movementCapture , height )
}

void function UpdateList()
{
	Hud_SetFocused( Hud_GetChild( file.menu, "BtnModsSearch" ) )
	file.updatingList = true

	array< ConVarData > filteredList = []
	
	array< string > filters = split( file.filterText, "," )
	array< ConVarData > list = file.conVarList
	if ( filters.len() < = 0 )
		filters.append( "" )
	foreach( string f in filters )
	{
		string filter = strip( f )
		string lastCatNameInFilter = ""
		string lastModNameInFilter = ""
		int curCatIndex = 0
		int curModTitleIndex = -1
		for ( int i = 0; i < list.len(); i++ )
		{
			ConVarData prev = list[ maxint( 0, i - 1 ) ]
			ConVarData c = list[i]
			ConVarData next = list[ minint( list.len() - 1, i + 1 ) ]
			if ( c.isEmptySpace ) continue

			string displayName = c.displayName
			if ( c.isModName ) {
				displayName = c.modName
				curModTitleIndex = i
			}
			if ( c.isCategoryName ) {
				displayName = c.catName
				curCatIndex = i
			}
			if ( filter == "" || SanitizeDisplayName( Localize( displayName ) ).tolower().find( filter.tolower() ) != null )
			{
				if ( c.isModName )
				{
					lastModNameInFilter = c.modName
					array< ConVarData > modVars = GetAllVarsInMod( list, c.modName )
					if ( filteredList.len() < = 0 && modVars[0].spaceType == eEmptySpaceType.None )
						filteredList.extend( modVars.slice( 1, modVars.len() ) )
					else 
						filteredList.extend( modVars )
					i += modVars.len() - 1
				}
				else if ( c.isCategoryName )
				{
					if ( lastModNameInFilter != c.modName )
					{
						array< ConVarData > modVars = GetModConVarDatas( list, curModTitleIndex )
						if ( filteredList.len() < = 0 && modVars[0].spaceType == eEmptySpaceType.None )
							filteredList.extend( modVars.slice( 1, modVars.len() ) )
						else
							filteredList.extend( modVars )
						lastModNameInFilter = c.modName
					}
					filteredList.extend( GetAllVarsInCategory( list, c.catName ) )
					i += GetAllVarsInCategory( list, c.catName ).len() - 1
					lastCatNameInFilter = c.catName
				}
				else {
					if ( lastModNameInFilter != c.modName )
					{
						array< ConVarData > modVars = GetModConVarDatas( list, curModTitleIndex )
						if ( filteredList.len() < = 0 && modVars[0].spaceType == eEmptySpaceType.None )
							filteredList.extend( modVars.slice( 1, modVars.len() ) )
						else
							filteredList.extend( modVars )
						lastModNameInFilter = c.modName
					}
					if ( lastCatNameInFilter != c.catName )
					{
						filteredList.extend( GetCatConVarDatas( curCatIndex ) )
						lastCatNameInFilter = c.catName
					}
					filteredList.append( c )
				}
			}
		}
		list = filteredList
		filteredList = []
	}
	filteredList = list
	

	file.filteredList = filteredList

	int j = int( min( file.filteredList.len() + file.scrollOffset, BUTTONS_PER_PAGE ) )

	for ( int i = 0; i < BUTTONS_PER_PAGE; i++ )
	{
		Hud_SetEnabled( file.modPanels[i], i < j )
		Hud_SetVisible( file.modPanels[i], i < j )
		
		if ( i < j )
			SetModMenuNameText( file.modPanels[i] )
	}
	file.updatingList = false
}

array< ConVarData > function GetModConVarDatas( array< ConVarData > arr, int index )
{
	if ( index < = 1 )
		return [ arr[ index - 1 ], arr[ index ], arr[ index + 1 ] ]	
	return [ arr[ index - 2 ], arr[ index - 1 ], arr[ index ], arr[ index + 1 ] ]	
}

array< ConVarData > function GetCatConVarDatas( int index )
{
	if ( index == 0 )
		return [ file.conVarList[ index ] ]	
	return [ file.conVarList[ index - 1 ], file.conVarList[ index ] ]	
}

array< ConVarData > function GetAllVarsInCategory( array< ConVarData > arr, string catName )
{
	array< ConVarData > vars = []
	for ( int i = 0; i < arr.len(); i++ )
	{
		ConVarData c = arr[i]
		if ( c.catName == catName ) 
		{
			vars.append( arr[i] )
			// printt( file.conVarList[i].conVar + " is in mod " + file.conVarList[i].modName )
		}
	}
	/*ConVarData empty
	empty.isEmptySpace = true
	vars.append( empty )*/
	return vars
}

array< ConVarData > function GetAllVarsInMod( array< ConVarData > arr, string modName )
{
	array< ConVarData > vars = []
	for ( int i = 0; i < arr.len(); i++ )
	{
		ConVarData c = arr[i]
		if ( c.modName == modName ) 
		{
			vars.append( arr[i] )
			// printt( file.conVarList[i].conVar + " is in mod " + file.conVarList[i].modName )
		}
	}
	/*ConVarData empty
	empty.isEmptySpace = true
	vars.append( empty )*/
	return vars
}

string function ConVarDataToString( int index )
{
	ConVarData d = file.filteredList[ index ] 
	int i = 0
	for ( i = 0; file.conVarList[i] != d; i++ )
	{}
	string type = d.isModName ? "Mod" : "Setting"
	if ( d.isCategoryName ) type = "Category" 
	switch ( type )
	{
		case "Mod":
			return "Mod Title " + d.modName + " at index " + index
		case "Setting":
			return "ConVar " + d.displayName + " ( " + d.conVar + " ) at index " + index + "/" + i
		case "Category":
			return "Category " + d.catName + " at index " + index + "/" + i
	}

	return "EMPTY SPACE	"
}

void function SetModMenuNameText( var button )
{
	int index = int ( Hud_GetScriptID( button ) ) + file.scrollOffset
	ConVarData conVar = file.filteredList[ int ( Hud_GetScriptID( button ) ) + file.scrollOffset ]

	var panel = file.modPanels[ int ( Hud_GetScriptID( button ) ) ]

	var label = Hud_GetChild( panel, "BtnMod" )
	var textField = Hud_GetChild( panel, "TextEntrySetting" )
	var enumButton = Hud_GetChild( panel, "EnumSelectButton" )
	var resetButton = Hud_GetChild( panel, "ResetModToDefault" )
	var bottomLine = Hud_GetChild( panel, "BottomLine" )
	var topLine = Hud_GetChild( panel, "TopLine" )
	var modTitle = Hud_GetChild( panel, "ModTitle" )
	var customMenuButton = Hud_GetChild( panel, "OpenCustomMenu" )
	var slider = Hud_GetChild( panel, "Slider" )
	Hud_SetVisible( slider, false )
	Hud_SetEnabled( slider, true )


	if ( conVar.isEmptySpace )
	{
		string s = ""
		Hud_SetPos( label, 0, 0 )
		Hud_SetVisible( label, false )
		Hud_SetVisible( textField, false )
		Hud_SetVisible( enumButton, false )
		Hud_SetVisible( resetButton, false )
		Hud_SetVisible( modTitle, false )
		Hud_SetVisible( customMenuButton, false )
		Hud_SetVisible( bottomLine, false )
		Hud_SetVisible( topLine, false )
		switch ( conVar.spaceType )
		{
			case eEmptySpaceType.TopBar:
				Hud_SetVisible( topLine, true )
				return
				
			case eEmptySpaceType.BottomBar:
				Hud_SetVisible( bottomLine, true )
				return
			
			case eEmptySpaceType.None:
				return
		}
	}

	Hud_SetVisible( textField, !conVar.isCategoryName )
	Hud_SetVisible( bottomLine, conVar.isCategoryName || conVar.spaceType == eEmptySpaceType.BottomBar )
	Hud_SetVisible( topLine, false )
	Hud_SetVisible( enumButton, !conVar.isCategoryName && conVar.isEnumSetting )
	Hud_SetVisible( modTitle, conVar.isModName )
	Hud_SetVisible( customMenuButton, false )
	float scaleX = GetScreenSize()[1] / 1080.0
	float scaleY = GetScreenSize()[1] / 1080.0
	if ( conVar.sliderEnabled )
	{
		Hud_SetSize( slider, int( 320 * scaleX ), int( 45 * scaleY ) )
		MS_Slider s = file.sliders[ int ( Hud_GetScriptID( button ) ) ]
		MS_Slider_SetMin( s, conVar.min )
		MS_Slider_SetMax( s, conVar.max )
		MS_Slider_SetStepSize( s, conVar.stepSize )
		MS_Slider_SetValue( s, GetConVarFloat( conVar.conVar ) )
	}
	else
		Hud_SetSize( slider, 0, int( 45 * scaleY ) )
	if ( conVar.isCustomButton )
	{
		Hud_SetVisible( label, false )
		Hud_SetVisible( textField, false )
		Hud_SetVisible( enumButton, false )
		Hud_SetVisible( resetButton, false )
		Hud_SetVisible( modTitle, false )
		Hud_SetVisible( customMenuButton, true )
		Hud_SetText( customMenuButton, conVar.displayName )
	}
	else if ( conVar.isModName )
	{
		Hud_SetText( modTitle, conVar.modName ) 
		Hud_SetSize( resetButton, 0, int( 40 * scaleY ) )
		Hud_SetPos( label, 0, 0 )
		Hud_SetVisible( label, false )
		Hud_SetVisible( textField, false )
		Hud_SetVisible( enumButton, false )
		Hud_SetVisible( resetButton, false )
		Hud_SetVisible( bottomLine, false )
		Hud_SetVisible( topLine, false )
	}
	else if ( conVar.isCategoryName ) {
		Hud_SetText( label, conVar.catName ) 
		Hud_SetText( resetButton, "#MOD_SETTINGS_RESET_ALL" ) 
		Hud_SetSize( resetButton, int( 120 * scaleX ), int( 40 * scaleY ) )
		Hud_SetPos( label, 0, 0 )
		Hud_SetSize( label, int( scaleX * ( 1180 - 420 - 85 ) ), int( scaleY * 40 ) )
		// Hud_SetSize( customMenuButton, int( 85 * scaleX ), int( 40 * scaleY ) )
		// Hud_SetVisible( customMenuButton, conVar.hasCustomMenu )
		Hud_SetVisible( label, true )
		Hud_SetVisible( textField, false )
		Hud_SetVisible( enumButton, false )
		Hud_SetVisible( resetButton, true )
	}
	else {
		Hud_SetVisible( slider, conVar.sliderEnabled )
		
		Hud_SetText( label, conVar.displayName ) 
		if ( conVar.type == "float" )
			Hud_SetText( textField, string( GetConVarFloat( conVar.conVar ) ) )
		else Hud_SetText( textField, conVar.isEnumSetting ? conVar.values[ GetConVarInt( conVar.conVar ) ] : GetConVarString( conVar.conVar ) )
		Hud_SetPos( label, int( scaleX * 25 ), 0 )
		Hud_SetText( resetButton, "#MOD_SETTINGS_RESET" ) 
		Hud_SetSize( resetButton, int( scaleX * 90 ), int( scaleY * 40 ) )
		if ( conVar.sliderEnabled )
			Hud_SetSize( label, int( scaleX * ( 375 + 85 ) ), int( scaleY * 40 ) )
		else Hud_SetSize( label, int( scaleX * ( 375 + 405 ) ), int( scaleY * 40 ) )
		// Hud_SetSize( customMenuButton, 0, 40 )
		Hud_SetVisible( label, true )
		Hud_SetVisible( textField, true )
		// Hud_SetVisible( enumButton, true )
		Hud_SetVisible( resetButton, true )
	}
}

void function CustomButtonPressed( var button )
{
	var panel = Hud_GetParent( button )
	ConVarData c = file.filteredList[ int( Hud_GetScriptID( panel ) ) + file.scrollOffset ]
	c.onPress()
}

void function OnScrollDown( var button )
{
	if ( file.filteredList.len() < = BUTTONS_PER_PAGE ) return
	file.scrollOffset += 5
	if ( file.scrollOffset + BUTTONS_PER_PAGE > file.filteredList.len() ) {
		file.scrollOffset = file.filteredList.len() - BUTTONS_PER_PAGE
	}
	UpdateList()
	UpdateListSliderPosition()
}

void function OnScrollUp( var button )
{
	file.scrollOffset -= 5
	if ( file.scrollOffset < 0 ) {
		file.scrollOffset = 0
	}
	UpdateList()
	UpdateListSliderPosition()
}

void function UpdateListSliderPosition()
{
	var sliderButton = Hud_GetChild( file.menu , "BtnModListSlider" )
	var sliderPanel = Hud_GetChild( file.menu , "BtnModListSliderPanel" )
	var movementCapture = Hud_GetChild( file.menu , "MouseMovementCapture" )
	
	float mods = float ( file.filteredList.len() )

	float minYPos = -40.0 * ( GetScreenSize()[1] / 1080.0 )
	float useableSpace = ( 615.0 * ( GetScreenSize()[1] / 1080.0 ) - Hud_GetHeight( sliderPanel ) )

	float jump = minYPos - ( useableSpace / ( mods - float( BUTTONS_PER_PAGE ) ) * file.scrollOffset )

	// jump = jump * ( GetScreenSize()[1] / 1080.0 )

	if ( jump > minYPos ) jump = minYPos

	Hud_SetPos( sliderButton , 2, jump )
	Hud_SetPos( sliderPanel , 2, jump )
	Hud_SetPos( movementCapture , 2, jump )
}

void function OnModMenuOpened()
{
	file.scrollOffset = 0
	file.filterText = ""
	
	RegisterButtonPressedCallback( MOUSE_WHEEL_UP , OnScrollUp )
	RegisterButtonPressedCallback( MOUSE_WHEEL_DOWN , OnScrollDown )
	// RegisterButtonPressedCallback( KEY_F1, ToggleHideMenu )

	// SetBlurEnabled( false )
	// UI_SetPresentationType( ePresentationType.INACTIVE )
	// Hud_SetVisible( file.menu, true )
	
	OnFiltersChange(0)
}

void function OnFiltersChange( var n )
{
	file.scrollOffset = 0
	
	// HideAllButtons()
	
	// RefreshModsArray()
	
	UpdateList()
	
	UpdateListSliderHeight()
}

void function OnModMenuClosed()
{
	try
	{
		DeregisterButtonPressedCallback( MOUSE_WHEEL_UP , OnScrollUp )
		DeregisterButtonPressedCallback( MOUSE_WHEEL_DOWN , OnScrollDown )
		// DeregisterButtonPressedCallback( KEY_F1 , ToggleHideMenu )
	}
	catch ( ex ) {}
	
	file.scrollOffset = 0
	// UI_SetPresentationType( ePresentationType.DEFAULT )
	// SetBlurEnabled( !IsMultiplayer() )
	// Hud_SetVisible( file.menu, false )
}

void function AddModTitle( string modName )
{
	file.currentMod = modName
	if ( file.conVarList.len() > 0 )
	{
		ConVarData catData

		catData.isEmptySpace = true
		catData.modName = file.currentMod

		file.conVarList.append( catData )
	}
	ConVarData topBar
	topBar.isEmptySpace = true
	topBar.modName = modName
	topBar.spaceType = eEmptySpaceType.TopBar
	
	
	ConVarData modData

	modData.modName = modName
	modData.displayName = modName
	modData.isModName = true


	ConVarData botBar
	botBar.isEmptySpace = true
	botBar.modName = modName
	botBar.spaceType = eEmptySpaceType.BottomBar
	file.conVarList.extend( [ topBar, modData, botBar ] )
	file.setFuncs[ expect string( getstackinfos(2)[ "func" ] ) ] < - false
}

void function AddModCategory( string catName )
{
	if ( !( getstackinfos(2)[ "func" ] in file.setFuncs ) )
		throw getstackinfos(2)[ "src" ] + " #" + getstackinfos(2)[ "line" ] + "\nCannot add a category before a mod title!"
	if ( file.currentCat != "" )
	{
		ConVarData space
		space.isEmptySpace = true
		space.modName = file.currentMod
		space.catName = catName
		file.conVarList.append( space )
	}

	ConVarData catData

	catData.catName = catName
	catData.displayName = catName
	catData.modName = file.currentMod
	catData.isCategoryName = true

	file.conVarList.append( catData )
	
	file.currentCat = catName
	file.setFuncs[ expect string( getstackinfos(2)[ "func" ] ) ] = true
}

void function AddModSettingsButton( string buttonLabel, void functionref() onPress )
{
	if ( !( getstackinfos(2)[ "func" ] in file.setFuncs ) || !file.setFuncs[ expect string( getstackinfos(2)[ "func" ] ) ] )
		throw getstackinfos(2)[ "src" ] + " #" + getstackinfos(2)[ "line" ] + "\nCannot add a button before a category and mod title!"

	ConVarData data

	data.isCustomButton = true
	data.displayName = buttonLabel
	data.modName = file.currentMod
	data.catName = file.currentCat
	data.onPress = onPress

	file.conVarList.append( data )
}

void function AddConVarSetting( string conVar, string displayName, string type = "" )
{
	if ( !( getstackinfos(2)[ "func" ] in file.setFuncs ) || !file.setFuncs[ expect string( getstackinfos(2)[ "func" ] ) ] )
		throw getstackinfos(2)[ "src" ] + " #" + getstackinfos(2)[ "line" ] + "\nCannot add a setting before a category and mod title!"
	ConVarData data

	data.catName = file.currentCat
	data.conVar = conVar
	data.modName = file.currentMod
	data.displayName = displayName
	data.type = type

	file.conVarList.append( data )
}

void function AddConVarSettingSlider( string conVar, string displayName, float min = 0.0, float max = 1.0, float stepSize = 0.1, bool forceClamp = false )
{
	if ( !( getstackinfos(2)[ "func" ] in file.setFuncs ) || !file.setFuncs[ expect string( getstackinfos(2)[ "func" ] ) ] )
		throw getstackinfos(2)[ "src" ] + " #" + getstackinfos(2)[ "line" ] + "\nCannot add a setting before a category and mod title!"
	ConVarData data

	data.catName = file.currentCat
	data.conVar = conVar
	data.modName = file.currentMod
	data.displayName = displayName
	data.type = "float"
	data.sliderEnabled = true
	data.forceClamp = false
	data.min = min
	data.max = max
	data.stepSize = stepSize

	file.conVarList.append( data )
}

void function AddConVarSettingEnum( string conVar, string displayName, array< string > values )
{
	if ( !( getstackinfos(2)[ "func" ] in file.setFuncs ) || !file.setFuncs[ expect string( getstackinfos(2)[ "func" ] ) ] )
		throw getstackinfos(2)[ "src" ] + " #" + getstackinfos(2)[ "line" ] + "\nCannot add a setting before a category and mod title!"
	ConVarData data

	data.catName = file.currentCat
	data.modName = file.currentMod
	data.conVar = conVar
	data.displayName = displayName
	data.values = values
	data.isEnumSetting = true
	data.min = 0
	data.max = values.len() - 1.0	
	data.sliderEnabled = values.len() > 2
	data.forceClamp = true
	data.stepSize = 1

	file.conVarList.append( data )
}

void function OnSliderChange( var button )
{
	if ( file.updatingList )
		return 
	var panel = Hud_GetParent( button )
	ConVarData c = file.filteredList[ int( Hud_GetScriptID( panel ) ) + file.scrollOffset ]
	var textPanel = Hud_GetChild( panel, "TextEntrySetting" )

	if ( c.isEnumSetting )
	{
		int val = int( RoundToNearestInt( Hud_SliderControl_GetCurrentValue( button ) ) )
		SetConVarInt( c.conVar, val )
		Hud_SetText( textPanel, ( c.values[ GetConVarInt( c.conVar ) ] ) )
		MS_Slider_SetValue( file.sliders[ int( Hud_GetScriptID( Hud_GetParent( textPanel ) ) ) ], float( val ) )

		return
	}
	float val = Hud_SliderControl_GetCurrentValue( button )
	if ( c.forceClamp )
	{
		int mod = int( RoundToNearestInt( val % c.stepSize / c.stepSize ) )
		val = ( int( val / c.stepSize ) + mod ) * c.stepSize
	}
	SetConVarFloat( c.conVar, val )
	MS_Slider_SetValue( file.sliders[ int( Hud_GetScriptID( Hud_GetParent( textPanel ) ) ) ], val )

	Hud_SetText( textPanel, string( GetConVarFloat( c.conVar ) ) )
}

void function SendTextPanelChanges( var textPanel ) 
{
	ConVarData c = file.filteredList[ int( Hud_GetScriptID( Hud_GetParent( textPanel ) ) ) + file.scrollOffset ]
	if ( c.conVar == "" ) return
	// enums don't need to do this
	if ( !c.isEnumSetting )
	{
		string newSetting = Hud_GetUTF8Text( textPanel )

		switch ( c.type )
		{
			case "int":
				try 
				{
					SetConVarInt( c.conVar, newSetting.tointeger() )
					file.settingsTable[ c.conVar ] < - newSetting
				}
				catch ( ex )
				{
					ThrowInvalidValue( "This setting is an integer, and only accepts whole numbers." )
					Hud_SetText( textPanel, GetConVarString( c.conVar ) )
				}
			case "bool":
				if ( newSetting != "0" && newSetting != "1" )
				{
					ThrowInvalidValue( "This setting is a boolean, and only accepts values of 0 or 1." )

					// set back to previous value : )
					Hud_SetText( textPanel, string( GetConVarBool( c.conVar ) ) )

					break
				}
				SetConVarBool( c.conVar, newSetting == "1" )
				file.settingsTable[ c.conVar ] < - newSetting
				break
			case "float":
				try
				{
					SetConVarFloat( c.conVar, newSetting.tofloat() )
					file.settingsTable[ c.conVar ] < - newSetting
				}
				catch ( ex )
				{
					printt( ex )
					ThrowInvalidValue( "This setting is a float, and only accepts a number - we could not parse this!\n\n( Use \".\" for the floating point, not \",\". )" )
				}
				if ( c.sliderEnabled )
				{
					var panel = Hud_GetParent( textPanel )
					MS_Slider s = file.sliders[ int ( Hud_GetScriptID( panel ) ) ]

					MS_Slider_SetValue( s, GetConVarFloat( c.conVar ) )
				}
				break
			case "float2":
				try
				{
					array< string > split = split( newSetting, " " )
					if ( split.len() != 2 )
					{
						ThrowInvalidValue( "This setting is a float2, and only accepts a pair of numbers - you put in " + split.len() + "!" )
						Hud_SetText( textPanel, GetConVarString( c.conVar ) )
						break
					}
					vector settingTest = < split[0].tofloat(), split[1].tofloat(), 0 >

					SetConVarString( c.conVar, newSetting )
					file.settingsTable[ c.conVar ] < - newSetting
				}
				catch ( ex )
				{
					ThrowInvalidValue( "This setting is a float2, and only accepts a pair of numbers - you put something we could not parse!\n\n( Use \".\" for the floating point, not \",\". )" )
					Hud_SetText( textPanel, GetConVarString( c.conVar ) )
				}
				break
			// idk sometimes it's called Float3 most of the time it's called vector, I am not complaining.
			case "vector":
			case "float3":
				try
				{
					array< string > split = split( newSetting, " " )
					if ( split.len() != 3 )
					{
						ThrowInvalidValue( "This setting is a float3, and only accepts a trio of numbers - you put in " + split.len() + "!" )
						Hud_SetText( textPanel, GetConVarString( c.conVar ) )
						break
					}
					vector settingTest = < split[0].tofloat(), split[1].tofloat(), 0 >

					SetConVarString( c.conVar, newSetting )
					file.settingsTable[ c.conVar ] < - newSetting
				}
				catch ( ex )
				{
					ThrowInvalidValue( "This setting is a float3, and only accepts a trio of numbers - you put something we could not parse!\n\n( Use \".\" for the floating point, not \",\". )" )
					Hud_SetText( textPanel, GetConVarString( c.conVar ) )
				}
				break
			default:
				SetConVarString( c.conVar, newSetting )
				file.settingsTable[ c.conVar ] < - newSetting
				break;
		}
		try
		{
			compilestring( "return function ( t ) : () { NSSaveFile( \"Mod Settings\", \"settings\", t ) }" )() ( file.settingsTable )
		}
		catch ( ex )
		{

		}
	}
	else Hud_SetText( textPanel, Localize( c.values[ GetConVarInt( c.conVar ) ] ) )
}

void function ThrowInvalidValue( string desc )
{
	DialogData dialogData
	dialogData.header = "Invalid Value" 
	dialogData.image = $"ui/menu/common/dialog_error"
	dialogData.message = desc
	AddDialogButton( dialogData, "#OK" )
	OpenDialog( dialogData )
}

void function UpdateEnumSetting( var button )
{
	int scriptId = int( Hud_GetScriptID( Hud_GetParent( button ) ) )
	ConVarData c = file.filteredList[ scriptId + file.scrollOffset ]

	var panel = file.modPanels[ scriptId ]
	
	var textPanel = Hud_GetChild( panel, "TextEntrySetting" )
	
	string selectionVal = Hud_GetDialogListSelectionValue( button )

	if ( selectionVal == "main" )
		return
					
	int enumVal = GetConVarInt( c.conVar )
	if ( selectionVal == "next" ) // enum val += 1
		enumVal = ( enumVal + 1 ) % c.values.len()
	else // enum val -= 1
	{
		enumVal--
		if ( enumVal == -1 )
			enumVal = c.values.len() - 1
	}
	
	SetConVarInt( c.conVar, enumVal )
	Hud_SetText( textPanel, c.values[ enumVal ] )

	Hud_SetDialogListSelectionValue( button, "main" )
}

void function OnClearButtonPressed( var button )
{
	file.filterText = ""
	Hud_SetText( Hud_GetChild( file.menu, "BtnModsSearch" ), "" )

	OnFiltersChange(0)
}

string function SanitizeDisplayName( string displayName )
{
	array< string > parts = split( displayName, "^" )
	string result = ""
	if ( parts.len() == 1 )
		return parts[0]
	foreach ( string p in parts )
	{
		if ( p == "" )
		{
			result += "^"
			continue
		}
		int i = 0
		for ( i = 0; i < 8 && i < p.len(); i++ )
		{
			var c = p[i]
			if ( ( c < 'a' || c > 'f' ) && ( c < 'A' || c > 'F' ) && ( c < '0' || c > '9' ) )
				break
		}
		if ( i == 0 )
			result += p
		else result += p.slice( i, p.len() )
	}
	print( result )
	return result
}