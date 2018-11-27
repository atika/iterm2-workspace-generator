
-- iTerm2 workspace launcher
-- Read the config (plist) in app bundle, start a new session with profile_name, cd to project_path, and run command project_cmd
-- If a session already exists, split the window vertically if "vertically" is true, otherwise horizontally
-- Split the session and cd to project_path if "assistant" is not false

on run
	
	# Config File		
	if (path to me as text) ends with ".app:" then
		set configPath to POSIX path of ((path to me as text) & "Contents:Resources:") & "config.plist"
	else
		set configPath to POSIX path of ((path to me as text) & "::") & "config-test.plist"
	end if
	
	-- Property List Settings
	tell application "System Events"
		tell property list file configPath
			
			set profile_name to value of property list item "profile_name" -- iterm profile name
			set project_path to value of property list item "project_path" -- absolute path
			set project_cmd to value of property list item "project_cmd" -- cmd to execute
			
			-- assistant is a second session created with the project working directory
			if property list item "assistant" exists then
				set assistant to value of property list item "assistant"
			else
				set assistant to true
			end if
			
			-- vertical: when true split the session vertically if another session exists, default false
			if property list item "vertically" exists then
				set vertically to value of property list item "vertically"
			else
				set vertically to false
			end if
			
		end tell
	end tell
	
	set window_exist to false
	
	tell application "iTerm"
		
		-- Search if a window profile already exists
		repeat with win in windows
			set profile to profile name of first session of current tab of win
			if profile is equal to profile_name then
				set window_exist to true
				set profile_session to first session of current tab of win
				exit repeat
			end if
		end repeat
		
		-- Create a window with the profile if not exist
		if window_exist is false then
			-- Create new window
			set win to create window with profile profile_name
			set profile_session to current session of win
		else
			-- window exists wait to execute the script (could be another one executing)
			delay 3
		end if
		
		activate
		
		delay 1
		
		tell win
			tell current tab
				
				-- CD and execute the command
				tell profile_session
					
					-- Nothing is running can execute project command
					if is at shell prompt then
						
						-- Go to project_path
						tell me to goto(profile_session, project_path)
						
						delay 0.5
						
						-- Execute the project command
						if project_cmd is not missing value then
							write text project_cmd
						end if
						
					else
						-- a command is already running
						if name contains project_cmd then
							
							-- The first session already execute the command
							tell me to activate
							tell me to display alert "Your Project command is already running in first session > " & project_cmd as critical
							-- does not create second session because the command is already running
							set assistant to false
							
						else
							
							-- Create a new session to execute the new project command
							if vertically is true then
								set terminal_session to split vertically with same profile
							else
								set terminal_session to split horizontally with same profile
							end if
							
							tell terminal_session
								select
								
								-- Go to project_path
								tell me to goto(terminal_session, project_path)
								
								delay 0.5
								
								-- Execute the project command
								if project_cmd is not missing value then
									write text project_cmd
								end if
								
							end tell
							
						end if
					end if
					
				end tell
				
				# Second terminal after last session and cd to project_path
				
				if assistant is true then
					
					set sessions_count to count of sessions
					
					tell last session
						select
						
						if sessions_count > 2 then
							set terminal_session to split vertically with default profile
						else
							set terminal_session to split horizontally with default profile
						end if
						
						
						delay 1
						
						# Path
						tell me to goto(terminal_session, project_path)
						
					end tell
				end if
				
			end tell -- current tab
		end tell -- current win
		
	end tell -- iterm
	
end run


on goto(profile_session, project_path)
	tell application "iTerm"
		tell profile_session
			set current_path to get variable named "session.path"
			
			if current_path is not equal to project_path then
				write text "cd " & project_path & " && clear"
			end if
		end tell
	end tell
end goto
