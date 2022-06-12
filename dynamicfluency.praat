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
    @uhm_postprocessing_windows
else
    runScript: "bin/uhm-o-meter/syllablenuclei.praat", operatingSystem$, inputFileSpec$, pre_processing$, silence_treshhold, minimum_dip_near_peak, minimum_pause_duration, language$, filled_Pause_threshold
    @uhm_postprocessing_unix
    endif

if allignment$ = "aeneas"
    @aeneas_preprocessing
    if operatingSystem$ == "Windows" 
        @aeneas_windows
    else
        @aeneas_unix
        endif
    endif

if allignment$ = "maus"
    if operatingSystem$ == "Windows" 
        @maus_windows
    else
        @maus_unix
        endif
    endif

if operatingSystem$ == "Windows"
    @postprocessing_windows
else
    @postprocessing_unix
    endif

@cleanup

procedure aeneas_windows
    inputFolder$  = replace$(inputDirectory$ + "\", "/", "", 0)
    outputFolder$ = outputDirectory$ + "\"
    idScript      = Create Strings from tokens: "script", "::Automatically generated commandprompt file for dynamicfluency", "."
    for file to nrFiles
        base$ = "py -2.7 -m aeneas.tools.execute_task -r=""cew=False"""

        selectObject: idSoundsList
        soundFile$ = Get string: file
        soundExt$ = right$(soundFile$, length(soundFile$)-rindex(soundFile$, ".")+1)

        tokensFile$[file] = replace$(soundFile$, soundExt$, ".tokens.txt", 1)
        outputFileTokens$  = replace$(soundFile$, soundExt$, ".tokens.json", 1)
        phrasesFile$[file] = replace$(soundFile$, soundExt$, ".phrases.txt", 1)
        outputFilePhrases$  = replace$(soundFile$, soundExt$, ".phrases.json", 1)

        if language$ == "English"
            args$ = " ""task_language=eng|os_task_file_format=json|is_text_type=plain"""
        else
            exitScript: "language not implemented"
            endif

        selectObject: idScript
        Insert string: 0, base$ + " " + inputFolder$ + soundFile$ + " " + inputFolder$ + tokensFile$[file] + args$ + " " + outputFolder$ + outputFileTokens$
        Insert string: 0, base$ + " " + inputFolder$ + soundFile$ + " " + inputFolder$ + phrasesFile$[file] + args$ + " " + outputFolder$ + outputFilePhrases$ 
        endfor
    Insert string: 0, "py -3 .\bin\aeneas_postprocess.py"
    Save as raw text file: "dynamicfluency_aeneas.auto.cmd"
    Remove
    runSystem: "dynamicfluency_aeneas.auto.cmd"
    deleteFile: "dynamicfluency_aeneas.auto.cmd"

    for file to nrFiles 
        deleteFile: inputFolder$ + tokensFile$[file]
        deleteFile: inputFolder$ + phrasesFile$[file]
        endfor
    endproc

procedure aeneas_preprocessing

    for file to nrFiles
        selectObject: idSoundsList
        soundFile$ = Get string: file
        soundExt$ = right$(soundFile$, length(soundFile$)-rindex(soundFile$, ".")+1)

        if transcriptionFormat$ == "TextGrid"
            idTrans = Read from file: inputDirectory$ + replace$(soundFile$, soundExt$, ".TextGrid", 1)
            selectObject: idTrans
            transcription$ = Get label of interval: 1, 1
            endif

        if transcriptionFormat$ == "txt"
            idTrans = Read Strings from raw text file: inputDirectory$ + replace$(soundFile$, soundExt$, ".txt", 1)
            selectObject: idTrans
            transcription$ = Get string: 1
            endif

        idPhrase = Create Strings from tokens: replace$(soundFile$, soundExt$, ".tokens", 1), transcription$, ",."
        Save as raw text file: inputDirectory$ + replace$(soundFile$, soundExt$, ".phrases.txt", 1)

        tokenTranscription$ = replace_regex$(transcription$, "[.,]", "", 0)
        idTokens = Create Strings from tokens: replace$(soundFile$, soundExt$, ".tokens", 1), tokenTranscription$, ""
        selectObject: idTokens
        Save as raw text file: inputDirectory$ + replace$(soundFile$, soundExt$, ".tokens.txt", 1)
        removeObject: idTrans, idTokens, idPhrase
        endfor
    endproc

procedure maus_windows
    inputFolder$  = replace$(inputDirectory$ + "\", "/", "", 0)
    outputFolder$ = outputDirectory$ + "\"

    for file to nrFiles
        selectObject: idSoundsList
        soundFile$ = Get string: file
        soundExt$ = right$(soundFile$, length(soundFile$)-rindex(soundFile$, ".")+1)

        mausFile$ = replace$(soundFile$, soundExt$, ".TextGrid", 1)
        allignmentFile$ = replace$(soundFile$, soundExt$, ".allignment.TextGrid", 1)

        runSystem: "copy /-Y " + inputFolder$ + mausFile$ + " " + outputFolder$ + allignmentFile$
        endfor
    endproc

procedure uhm_postprocessing_windows
    inputFolder$  = replace$(inputDirectory$ + "\", "/", "", 0)
    outputFolder$ = outputDirectory$ + "\"

    for file to nrFiles
        selectObject: idSoundsList
        soundFile$ = Get string: file
        soundExt$ = right$(soundFile$, length(soundFile$)-rindex(soundFile$, ".")+1)

        uhmFile$ = replace$(soundFile$, soundExt$, ".uhm.TextGrid", 1)
        runSystem: "move /-Y " + inputFolder$ + uhmFile$ + " " + outputFolder$ + uhmFile$
        endfor
    endproc

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
    transcriptionFormat$ = "maus"
    language$ = "English"

    #uhm-o-meter:
    preProcessing$ = "None"
    silenceTreshhold = -25
    minimumDipNearPeak = 2
    minimumPauseDuration = 0.3
    filledPauseThreshold = 1

    #hidden settings:
    outputDirectory$ = "output"

    removeObject: idConfig
    endproc
    
procedure process_arguments
    len = length(inputFileSpec$)
    sep = rindex_regex(inputFileSpec$, "[\\/]")
    inputDirectory$ = left$(inputFileSpec$, sep)
    selection$      = right$(inputFileSpec$, len-sep)   

    idSoundsList = Create Strings as file list: "SoundsList", inputDirectory$ + selection$
    nrFiles      = Get number of strings

    if (transcriptionFormat$ == "TextGrid") or (transcriptionFormat$ == "txt")
        allignment$ = "aeneas"
    else
        allignment$ = "maus"
        endif
    endproc

procedure postprocessing_windows
    outputFolder$ = outputDirectory$ + "\"
    inputFolder$  = replace$(inputDirectory$ + "\", "/", "", 0)

    for file to nrFiles
        selectObject: idSoundsList
        soundFile$ = Get string: file
        soundExt$ = right$(soundFile$, length(soundFile$)-rindex(soundFile$, ".")+1)

        uhmFile$ = replace$(soundFile$, soundExt$, ".uhm.TextGrid", 1)
        allignmentFile$ = replace$(soundFile$, soundExt$, ".allignment.TextGrid", 1)
        mergedFile$ = replace$(soundFile$, soundExt$, ".merged.TextGrid", 1)

        idSound = Read from file: inputFolder$ + soundFile$
        idUhm = Read from file: outputFolder$ + uhmFile$
        idAllignment = Read from file: outputFolder$ + allignmentFile$

        selectObject: idUhm, idAllignment
        Merge
        Save as text file: outputFolder$ + mergedFile$
        endfor    
    endproc

procedure cleanup
    selectObject: idSoundsList
    Remove
    endproc