## Autoload to hold information used by the main menu that needs to persist between scene changes

extends Node


enum ReturnMenu {MAIN,LEVEL_SELECT}


## This value is only true for the first frame of the game running
var first_start = true
## The sub-menu that should be shown upon returning to the main menu scene
var return_to_menu: ReturnMenu = ReturnMenu.MAIN


func _ready():
	(func(): MenuManager.first_start = false).call_deferred()
