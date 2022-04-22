form Find Speaking Fluency
    comment Do you want to run the settings wizard?
    comment   - Selecting yes will cause the program to open a configuration wizard in which you can change the 
    comment     settings for this script and all its subsystems.
    comment   - If you don't run the wizard, a configiration file will be used instead, to be specified below.
    comment   - The settings wizard will generate one of these configuration files, and will save (and override)
    comment     it in the default file location. This means using the default file will run with previous settings.

    boolean Run_Settings_Wizard yes
    sentence Configuration_File configuration.txt
    endform

@read_config

procedure read_config

    if run_Settings_Wizard
        runScript: "configurationwizard.praat"
        endif
    if run_Settings_Wizard
        configiration_File$ = "configuration.txt"
        endif

    config = Read Strings from raw text file: configuration_File$
    numberOfLines = Get number of strings
    
    header$ = Get string: 1
    assert header$ == "DynamicFluency configuration file"
    
    removeObject: config
    endproc
        