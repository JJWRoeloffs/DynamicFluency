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
@process_arguments

if operatingSystem$ == "Windows"
    runScript: "bin\uhm-o-meter\syllablenuclei.praat", operatingSystem$, inputFileSpec$, preProcessing$, silenceTreshhold, minimumDipNearPeak, minimumPauseDuration, language$, filledPauseThreshold
else
    runScript: "bin/uhm-o-meter/syllablenuclei.praat", operatingSystem$, inputFileSpec$, pre_processing$, silence_treshhold, minimum_dip_near_peak, minimum_pause_duration, language$, filled_Pause_threshold
    endif

if (transcriptionFormat$ == "TextGrid") or (transcriptionFormat$ == "txt")
    @aeneas_preprocessing
    endif

@cleanup

procedure aeneas_preprocessing

    for file to nrFiles
        selectObject: idSoundsList
        soundFile$[file] = Get string: file
        soundExt$ = right$(soundFile$[file], length(soundFile$[file])-rindex(soundFile$[file], ".")+1)

        if transcriptionFormat$ == "TextGrid"
            idTrans = Read from file: inputDirectory$ + replace$(soundFile$[file], soundExt$, ".TextGrid", 1)
            selectObject: idTrans
            transcription$ = Get label of interval: 1, 1
            endif

        if transcriptionFormat$ == "txt"
            idTrans = Read Strings from raw text file: inputDirectory$ + replace$(soundFile$[file], soundExt$, ".txt", 1)
            selectObject: idTrans
            transcription$ = Get string: 1
            endif

        transcription$ = replace_regex$(transcription$, "[.,]", "", 0)
        idTokens = Create Strings from tokens: replace$(soundFile$[file], soundExt$, ".tokens", 1), transcription$, ""
        selectObject: idTokens
        Save as raw text file: inputDirectory$ + replace$(soundFile$[file], soundExt$, ".tokens.txt", 1)
        removeObject: idTrans, idTokens
        endfor


procedure read_config
    if run_Settings_Wizard
        runScript: "configurationwizard.praat"
        configiration_File$ = "configuration.txt"
        endif

    idConfig = Read Strings from raw text file: configuration_File$
    numberOfLines = Get number of strings
    
    header$ = Get string: 1
    assert header$ == "DynamicFluency configuration file"

    #General:
    operatingSystem$ = "Windows"
    inputFileSpec$ = "test/*.wav"
    transcriptionFormat$ = "TextGrid"
    language$ = "English"

    #uhm-o-meter:
    preProcessing$ = "None"
    silenceTreshhold = -25
    minimumDipNearPeak = 2
    minimumPauseDuration = 0.3
    filledPauseThreshold = 1

    removeObject: idConfig
    endproc
    
procedure process_arguments
    len = length(inputFileSpec$)
    sep = rindex_regex(inputFileSpec$, "[\\/]")
    inputDirectory$ = left$(inputFileSpec$, sep)
    selection$      = right$(inputFileSpec$, len-sep)   

    idSoundsList = Create Strings as file list: "SoundsList", inputDirectory$ + selection$
    nrFiles      = Get number of strings

    idSnd# = zero#(nrFiles)
    endproc

procedure cleanup
    selectObject: idSoundsList
    Remove
    endproc