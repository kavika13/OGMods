enum character_trigger_types {	check_id = 0,
								check_team = 1,
								any_character = 2,
								any_player = 3,
								any_npc = 4
							};

enum hotspot_trigger_types {	on_enter = 0,
								on_exit = 1};

class DrikaOnCharacterEnterExit : DrikaElement{
	string character_team;
	int character_id;
	int new_character_trigger_type;
	int new_hotspot_trigger_type;

	character_trigger_types character_trigger_type;
	hotspot_trigger_types hotspot_trigger_type;

	bool triggered = false;

	DrikaOnCharacterEnterExit(int _character_trigger_type = 0, string _param = "-1", int _hotspot_trigger_type = int(on_enter)){
		character_trigger_type = character_trigger_types(_character_trigger_type);
		hotspot_trigger_type = hotspot_trigger_types(_hotspot_trigger_type);
		new_hotspot_trigger_type = hotspot_trigger_type;
		new_character_trigger_type = character_trigger_type;

		drika_element_type = drika_on_character_enter_exit;

		if(character_trigger_type == check_id){
			character_id = atoi(_param);
		}else{
			character_team = _param;
		}
		has_settings = true;
	}

	string GetSaveString(){
		if(character_trigger_type == check_id){
			return "on_character_enter_exit" + param_delimiter + int(character_trigger_type) + param_delimiter + character_id + param_delimiter + int(hotspot_trigger_type);
		}else{
			return "on_character_enter_exit" + param_delimiter + int(character_trigger_type) + param_delimiter + character_team + param_delimiter + int(hotspot_trigger_type);
		}
	}

	string GetDisplayString(){
		string trigger_message = "";
		if(character_trigger_type == check_id){
			trigger_message = "" + character_id;
		}else if(character_trigger_type == check_team){
			trigger_message = character_team;
		}else if(character_trigger_type == any_character){
			trigger_message = "Any Character";
		}else if(character_trigger_type == any_player){
			trigger_message = "Any Player";
		}else if(character_trigger_type == any_npc){
			trigger_message = "Any NPC";
		}
		return "OnCharacter" + ((hotspot_trigger_type == on_enter)?"Enter":"Exit") + " " + trigger_message;
	}

	void AddSettings(){
		if(ImGui_Combo("Check for", new_character_trigger_type, {"Check ID", "Check Team", "Any Character", "Any Player", "Any NPC"})){
			character_trigger_type = character_trigger_types(new_character_trigger_type);
		}
		if(ImGui_Combo("Trigger when", new_hotspot_trigger_type, {"On Enter", "On Exit"})){
			hotspot_trigger_type = hotspot_trigger_types(new_hotspot_trigger_type);
		}
		if(character_trigger_type == check_id){
			ImGui_InputInt("ID", character_id);
		}else if(character_trigger_type == check_team){
			ImGui_InputText("Team", character_team, 64);
		}
	}

	void DrawEditing(){
		if(character_trigger_type == check_id && character_id != -1 && MovementObjectExists(character_id)){
			MovementObject@ character = ReadCharacterID(character_id);
			DebugDrawLine(character.position, this_hotspot.GetTranslation(), vec3(1.0), _delete_on_update);
		}
	}

	void ReceiveMessage(string message, int param){
		if((hotspot_trigger_type == on_enter && message == "CharacterEnter") ||
			(hotspot_trigger_type == on_exit && message == "CharacterExit")){
			Log(info, "character " + param);
			if(MovementObjectExists(param)){
				MovementObject@ character = ReadCharacterID(param);
				Log(info, int(character_trigger_type) + " MovementObjectExists " + character.controlled);
				if(	character_trigger_type == check_id && character_id == param ||
					character_trigger_type == any_character ||
					character_trigger_type == any_player && character.controlled ||
					character_trigger_type == any_npc && !character.controlled){
					Log(info, "OnEnterExit triggered");
					triggered = true;
				}
			}
		}
	}

	void ReceiveMessage(string message, string param){
		if((character_trigger_type == check_team && hotspot_trigger_type == on_enter && message == "CharacterEnter") ||
			(character_trigger_type == check_team && hotspot_trigger_type == on_exit && message == "CharacterExit")){
			//Removed all the spaces.
			string no_spaces_param = join(param.split(" "), "");
			//Teams are , seperated.
			array<string> teams = no_spaces_param.split(",");
			if(teams.find(character_team) != -1){
				triggered = true;
			}
		}
	}

	bool Trigger(){
		if(triggered){
			triggered = false;
			return true;
		}else{
			return false;
		}
	}
}
