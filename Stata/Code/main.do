/*******************************************************************************
							Template Main do-file							   
*******************************************************************************/

	* Set version
	version 18

	* Set project global(s)	
	// User 1
	if "`c(username)'" == "wb558768" {
        global onedrive "C:/Users/wb558768/WBG/Maria Ruth Jones - GitHub-Workflow-training"
		global github 	"C:/Users/wb558768/Documents/GitHub/GitHub-MockProject-jul22"
    }
	
	// User 2 
	di "`c(username)'" 	//Check username and copy to set project globals by user
	
	if "`c(username)'" == "wb614536" {
        global onedrive "C:/Users/wb614536/OneDrive - WBG/Documents/GithubTraining/"
		global github 	"C:/Users/wb614536/Github/GitHub-MockProject-jul22"
    }
	
	// User: you 
	di "`c(username)'" 	//Check username and copy to set project globals by user
	
	if "`c(username)'" == "wb628619" {
        global onedrive ""
		global github 	"C:\Users\wb628619\Documents\GitHub\GitHub-MockProject-jul22"
    }
	
	
	* Set globals for sub-folders 
	global data 	"${onedrive}/Data"
	global code 	"${github}/Stata/Code"
	global outputs 	"${github}/Stata/Outputs/"


	* Install packages 
	sysdir set PLUS "${code}/ado"
	local user_commands	ietoolkit iefieldkit winsor sumstats estout //Add required user-written commands

	foreach command of local user_commands {
	   cap which `command'
	   if _rc == 111 {
		   ssc install `command'
	   }
	}

	* Run do files 
	* Switch to 0/1 to not-run/run do-files 
	if (1) do "${code}/01-processing-data.do"
	if (1) do "${code}/02-data-construction.do"
	

* End of do-file!	
