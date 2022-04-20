form Find Speaking Fluency
    comment Do you want to run the settings wizard?
    comment   - Selecting yes will cause the program to open a configuration wizard in which you can change the 
    comment     settings for this script and all its subsystems.
    comment   - If you don't run the wizard, a configiration file will be used instead, to be specified below.
    comment   - The settings wizard will generate one of these configuration files, and will save (and override)
    comment     it in the default file location. This means using the default file will run with previous settings.

    boolean Run_Settings_Wizard yes
    sentence Configuration_File dynamicfluency_configuration.txt
    endform

if run_Settings_Wizard
    runScript: "dynamicfluency_configurationwizard.praat"
    endif
if run_Settings_Wizard
    configiration_File$ = "dynamicfluency_configuration.txt"
    endif

@read_config

procedure read_config
    config = Read Strings from raw text file: configuration_File$
    writeInfoLine("Parsing config files")
    numberOfLines = Get number if strings
    
    for i from 0 to numberOfLines
        line = Get string: i
        appendInfoLine: line
        endfor
    
    removeObject: config
    endproc
        