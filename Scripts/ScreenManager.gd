extends Node

@export_category("Screens")
@export var last_screen = ""
@export var curr_screen = "log-in"

@export_category("icons")
const ALLAPPS = preload("uid://i80dkch7n5qj")
const DISK = preload("uid://ot4fdpgnhd6q")
const FRIENDS = preload("uid://c7as87lcfooae")
const MESSAGES = preload("uid://cobkwdulqydv0")
const SETTINGS = preload("uid://evjsvhmmjjru")
const SNAP = preload("uid://xaokn1vv7l8q")
const SIGN_IN = preload("uid://1o2ds6fe3k2f")
const STEAM_LOGO = preload("uid://cimtc5to5b8t0")
const MS_STORE_LIGHT = preload("uid://1ffd65fy5er")
const EGS_LOGO = preload("uid://bytngrh4n4ev6")

@export_category("No User")
@export var is_restricted = true

@export_category("Global Preferences")
@export var PreferredStore = "none"
@export var Language = "English"
