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

@set_config
@process_arguments

runScript: "bin" + pathSep$ + "uhm-o-meter" + pathSep$ + "syllablenuclei.praat", operatingSystem$, inputFileSpec$, preProcessing$, silenceTreshhold, minimumDipNearPeak, minimumPauseDuration, language$, filledPauseThreshold 
@uhm_postprocessing

if allignment$ = "aeneas"
    @aeneas_preprocessing
    if operatingSystem$ == "Windows" 
        @aeneas_windows
    else
        @aeneas_unix
        endif
    endif

if allignment$ == "maus"
    @maus
    endif

if operatingSystem$ == "Windows" 
    runSystem: "py -3 .\bin\pos_tagging.py -d " + outputDir$ + " -a " + allignment$
else
    runSystem: "pyhon3 ./bin/pos_tagging -d " + outputDir$ + " -a " + allignment$
    endif

if operatingSystem$ == "Windows" 
    runSystem: "py -3 .\bin\repititions.py -d " + outputDir$ + " -m " + max_repitition_read$
else
    runSystem: "pyhon3 ./bin/repititions.py -d " + outputDir$ + " -m " + max_repitition_read$
    endif

if operatingSystem$ == "Windows" 
    runSystem: "py -3 .\bin\word_frequencies.py -d " + outputDir$
else
    runSystem: "pyhon3 ./bin/word_frequencies.py -d " + outputDir$
    endif

@postprocessing
@cleanup

# Runs aeneas from the CMD commandline.
# This is done instead of running as a python library because the library for python 3 requires local compiling, which is difficult for users to set up on windows.
# Writing custom Python 2 code would be a safty concern. As little Python 2 is run as possible.
procedure aeneas_windows
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
        Insert string: 0, base$ + " " + inputDir$ + pathSep$ + soundFile$ + " " + inputDir$ + pathSep$ + tokensFile$[file] + args$ + " " + outputDir$ + pathSep$ + outputFileTokens$
        Insert string: 0, base$ + " " + inputDir$ + pathSep$ + soundFile$ + " " + inputDir$ + pathSep$ + phrasesFile$[file] + args$ + " " + outputDir$ + pathSep$ + outputFilePhrases$ 
        endfor
    Insert string: 0, "py -3 .\bin\aeneas_postprocess.py -d " + outputDir$
    Save as raw text file: "dynamicfluency_aeneas.auto.cmd"
    Remove
    runSystem: "dynamicfluency_aeneas.auto.cmd"
    deleteFile: "dynamicfluency_aeneas.auto.cmd"

    for file to nrFiles 
        deleteFile: inputDir$ + pathSep$ + tokensFile$[file]
        deleteFile: inputDir$ + pathSep$ + phrasesFile$[file]
        endfor
    endproc

# Parses the transcription into the format Aenas takes.
procedure aeneas_preprocessing

    for file to nrFiles
        selectObject: idSoundsList
        soundFile$ = Get string: file
        soundExt$ = right$(soundFile$, length(soundFile$)-rindex(soundFile$, ".")+1)

        if transcriptionFormat$ == "TextGrid"
            idTrans = Read from file: inputDir$ + pathSep$ + replace$(soundFile$, soundExt$, ".TextGrid", 1)
            selectObject: idTrans
            transcription$ = Get label of interval: 1, 1
            endif

        if transcriptionFormat$ == "txt"
            idTrans = Read Strings from raw text file: inputDir$ + pathSep$ + replace$(soundFile$, soundExt$, ".txt", 1)
            selectObject: idTrans
            transcription$ = Get string: 1
            endif

        idPhrase = Create Strings from tokens: replace$(soundFile$, soundExt$, ".tokens", 1), transcription$, ",."
        Save as raw text file: inputDir$ + pathSep$ + replace$(soundFile$, soundExt$, ".phrases.txt", 1)

        tokenTranscription$ = replace_regex$(transcription$, "[.,]", "", 0)
        idTokens = Create Strings from tokens: replace$(soundFile$, soundExt$, ".tokens", 1), tokenTranscription$, ""
        selectObject: idTokens
        Save as raw text file: inputDir$ + pathSep$ + replace$(soundFile$, soundExt$, ".tokens.txt", 1)
        removeObject: idTrans, idTokens, idPhrase
        endfor
    endproc

# Moves the .TextGrid files Maus outputs to the correct directory under the correct name
procedure maus

    for file to nrFiles
        selectObject: idSoundsList
        soundFile$ = Get string: file
        soundExt$ = right$(soundFile$, length(soundFile$)-rindex(soundFile$, ".")+1)

        mausFile$ = replace$(soundFile$, soundExt$, ".TextGrid", 1)
        allignmentFile$ = replace$(soundFile$, soundExt$, ".allignment.TextGrid", 1)

        if operatingSystem$ == "Windows"
            runSystem: "copy /-Y " + inputDir$ + pathSep$ + mausFile$ + " " + outputDir$ + pathSep$ + allignmentFile$
        else
            runSystem: "mv " + inputDir$ + pathSep$ + mausFile$ + " " + outputDir$ + pathSep$ + allignmentFile$
            endif
        endfor
    endproc

# Uhm-o-meter by default creates all files in the same directory as the input.
# This function moves the files to the output directory.
procedure uhm_postprocessing
    for file to nrFiles
        selectObject: idSoundsList
        soundFile$ = Get string: file
        soundExt$ = right$(soundFile$, length(soundFile$)-rindex(soundFile$, ".")+1)

        uhmFile$ = replace$(soundFile$, soundExt$, ".uhm.TextGrid", 1)
        runSystem: "move /-Y " + inputDir$ + pathSep$ + uhmFile$ + " " + outputDir$ + pathSep$  + uhmFile$
        endfor
    endproc

# Running adn reading the configuration file and setting global variables acordingly.
procedure set_config
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
    outputDir$ = "output"

    showResultInPraat = 1
    showIntermediateObjects = 1

    #uhm-o-meter:
    preProcessing$ = "None"
    silenceTreshhold = -25
    minimumDipNearPeak = 2
    minimumPauseDuration = 0.3
    filledPauseThreshold = 1

    #Repititions
    max_repitition_read$ = "300"

    removeObject: idConfig
    endproc

# Processes the user input to set more global variables the script uses.
procedure process_arguments
    len = length(inputFileSpec$)
    sep = rindex_regex(inputFileSpec$, "[\\/]")
    inputDir$  = left$(inputFileSpec$, sep - 1)
    selection$ = right$(inputFileSpec$, len-sep)

    if operatingSystem$ == "Windows"
        pathSep$ = "\"
    else
        pathSep$ = "/"
        endif

    idSoundsList = Create Strings as file list: "SoundsList", inputDir$ + pathSep$ + selection$
    nrFiles      = Get number of strings

    if (transcriptionFormat$ == "TextGrid") or (transcriptionFormat$ == "txt")
        allignment$ = "aeneas"
    else
        allignment$ = "maus"
        endif
    endproc

# Takes all the individually generated textgrids from the different tools, and merges them together.
# Also loads the files into the praat gui if the user asked for this.
procedure postprocessing

    for file to nrFiles
        selectObject: idSoundsList
        soundFile$ = Get string: file
        soundExt$ = right$(soundFile$, length(soundFile$)-rindex(soundFile$, ".")+1)

        uhmFile$ = replace$(soundFile$, soundExt$, ".uhm.TextGrid", 1)
        allignmentFile$ = replace$(soundFile$, soundExt$, ".allignment.TextGrid", 1)
        posFile$ = replace$(soundFile$, soundExt$, ".pos_tags.TextGrid", 1)
        repFile$ = replace$(soundFile$, soundExt$, ".repetitions.TextGrid", 1)
        freqFile$ = replace$(soundFile$, soundExt$, ".frequencies.TextGrid", 1)
        mergedFile$ = replace$(soundFile$, soundExt$, ".merged.TextGrid", 1) 

        idUhm = Read from file: outputDir$ + pathSep$ + uhmFile$
        idAllignment = Read from file: outputDir$ + pathSep$ + allignmentFile$
        idPOS = Read from file: outputDir$ + pathSep$ + posFile$
        idRep = Read from file: outputDir$ + pathSep$ + repFile$
        idFreq = Read from file: outputDir$ + pathSep$ + freqFile$


        selectObject: idUhm, idAllignment, idPOS, idRep, idFreq
        idMerged = Merge
        Save as text file: outputDir$ + pathSep$ + mergedFile$
        
        if (showIntermediateObjects == 0) or (showResultInPraat == 0)
            removeObject: idUhm, idAllignment, idPOS, idRep, idFreq
            endif
        if showResultInPraat == 1
            idSound = Read from file: inputDir$ + pathSep$ + soundFile$
        else 
            removeObject: idMerged
            endif
        endfor    
    endproc

# Cleans away "global variables" stored as cashed text files.
procedure cleanup
    selectObject: idSoundsList
    Remove
    endproc