form Find Speaking Fluency
    comment Dynamic Fluency - understand a speaker's ability as it changes over time.
    comment ________________________________________________________________________________
    comment You can configure the settings for this application either by going through a 
    comment graphical settings wizard, or by specifying a settings file that contains them. 
    comment ________________________________________________________________________________
    comment Do you want to run the settings wizard?
    comment   - Selecting yes will make the program open a configuration wizard in which you can change the 
    comment     settings for this script and all its subsystems.
    comment   - If you don't run the wizard, a configuration file will be used instead, to be specified below.
    comment   - If you run the wizard, this configuration file will still be created with the name specified below.
    comment   - If you wish to make a config file without running the system, run configurationwizard.praat instead.
    comment   - In all cases, creating a new file will overwrite any old file with the same name.

    boolean Run_Settings_Wizard yes
    sentence Configuration_File configuration.txt
    endform

@set_config
@process_arguments

runScript: "scripts" + pathSep$ + "uhm-o-meter" + pathSep$ + "SyllableNuclei.praat", operatingSystem$, inputFileSpec$, preProcessing$, silenceTreshhold, minimumDipNearPeak, minimumPauseDuration, language$, filledPauseThreshold 
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
    runSystem: "py -3 -m dynamicfluency.scripts.make_postagged_grids_from_alligned_grids -d " + outputDir$ + " -a " + allignment$
else
    runSystem: "python3 -m dynamicfluency.scripts.make_postagged_grids_from_alligned_grids -d " + outputDir$ + " -a " + allignment$
    endif

if operatingSystem$ == "Windows" 
    runSystem: "py -3 -m dynamicfluency.scripts.make_repetitionstagged_grids_from_postagged_grids -d " + outputDir$ + " -m " + maxRepititionRead$ + " -i " + toIgnore$
else
    runSystem: "python3 -m dynamicfluency.scripts.make_repetitionstagged_grids_from_postagged_grids -d " + outputDir$ + " -m " + maxRepititionRead$ + " -i " + toIgnore$
    endif
 
if operatingSystem$ == "Windows" 
    runSystem: "py -3 -m dynamicfluency.scripts.make_frequencytagged_girds_from_postagged_grids -d " + outputDir$ + " -t " + databaseTable$ + " -b " + database$ + " -i " + toIgnore$ + " -a " + allignment$
else
    runSystem: "python3 -m dynamicfluency.scripts.make_frequencytagged_girds_from_postagged_grids -d " + outputDir$ + " -t " + databaseTable$ + " -b " + database$ + " -i " + toIgnore$ + " -a " + allignment$
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
    Insert string: 0, "py -3 -m dynamicfluency.scripts.convert_aeneas_to_textgrids -d " + outputDir$
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
            runSystem: "cp " + inputDir$ + pathSep$ + mausFile$ + " " + outputDir$ + pathSep$ + allignmentFile$
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
        if operatingSystem$ == "Windows"
            runSystem: "move /-Y " + inputDir$ + pathSep$ + uhmFile$ + " " + outputDir$ + pathSep$  + uhmFile$
        else
            runSystem: "mv " + inputDir$ + pathSep$ + uhmFile$ + " " + outputDir$ + pathSep$  + uhmFile$
            endif
        endfor
    endproc

# Running adn reading the configuration file and setting global variables acordingly.
procedure set_config
    if run_Settings_Wizard
        runScript: "configurationwizard.praat", configuration_File$
        endif

    idConfig = Read Strings from raw text file: configuration_File$
    header$ = Get string: 1
    if header$ != "DynamicFluency configuration file"
        exitScript: "The configuration file specified does not appear to be a DynamicFluency configuration file"
        endif

    numberOfLines = Get number of strings
    if numberOfLines > 27
        @settings_error_later
        endif
    if numberOfLines < 27
        @settings_error_earlier
        endif
    
    #Setting defaults, then overriding them if they are present in the file.

    #General Settings:
    showResultInPraat = 1
    showIntermediateObjects = 1

    #uhm-o-meter Settings:
    preProcessing$ = "None"
    silenceTreshhold = -25
    minimumDipNearPeak = 2
    minimumPauseDuration = 0.3
    filledPauseThreshold = 1

    #Repititions and Word Frequencies
    toIgnore$ = "uh,uhm"
    maxRepititionRead$ = "300"
    database$ = "databases/main.db"
    databaseTable$ = "Default"

    #Dynamicity settings
    stepsPerSecond = 5
    windowLength = 5
    kernelType$ = "moving_average"
    

    for i to numberOfLines
        line$ = Get string: i
        len = length(line$)
        sep = rindex_regex(line$, "[=]")

        # General Settings
        if left$(line$, sep) == "OS="
            operatingSystem$ = right$(line$, len-sep)

        elif left$(line$, sep) == "Input File Spec="
            inputFileSpec$ = right$(line$, len-sep)
        
        elif left$(line$, sep) == "Output Dir="
            outputDir$ = right$(line$, len-sep)

        elif left$(line$, sep) == "Language="
            language$ = right$(line$, len-sep)
            
        elif left$(line$, sep) == "Show Intermediate Objects="
            showIntermediateObjects = number(right$(line$, len-sep))

        elif left$(line$, sep) == "Show Results in Praat="
            showResultInPraat = number(right$(line$, len-sep))
            
        elif left$(line$, sep) == "Transcription Format="
            transcriptionFormat$ = right$(line$, len-sep)
        
        # Uhm-o-meter Settings
        elif left$(line$, sep) == "Pre-processing="
            preProcessing$ = right$(line$, len-sep)
            
        elif left$(line$, sep) == "Silence Treshhold="
            silenceTreshhold = number(right$(line$, len-sep))
            
        elif left$(line$, sep) == "Minimum dip near peak="
            minimumDipNearPeak = number(right$(line$, len-sep))
            
        elif left$(line$, sep) == "Minimum pause duration="
            minimumPauseDuration = number(right$(line$, len-sep))
            
        elif left$(line$, sep) == "Filled pause threshold="
            filledPauseThreshold = number(right$(line$, len-sep))
        
        # Repititions and Word Frequencies
        elif left$(line$, sep) == "To Ignore="
            toIgnore$ = right$(line$, len-sep)
            
        elif left$(line$, sep) == "Max Repitition Read="
            maxRepititionRead$ = right$(line$, len-sep)
            
        elif left$(line$, sep) == "Database File="
            database$ = right$(line$, len-sep)
                        
        elif left$(line$, sep) == "Database Table="
            databaseTable$ = right$(line$, len-sep)
            endif
        
        # Dynamicity Settings
        elif left$(line$, sep) == "Steps per second="
            stepsPerSecond = number(right$(line$, len-sep))
            endif

        elif left$(line$, sep) == "Window length="
            windowLength = number(right$(line$, len-sep))
        
        elif left$(line$, sep) == "Kernel Type="
            kernelType$ = right$(line$, len-sep)
            endif

        endfor
        
    # Throwing errors for essential missing values.
    if not operatingSystem$ <> ""
        writeInfoLine: operatingSystem$
        exitScript: "No Operating System specified"
        endif

    if not inputFileSpec$ <> ""
        exitScript: "No input file spec specified"
        endif

    if not outputDir$ <> ""
        exitScript: "No output directory specified"
        endif

    if not language$ <> ""
        exitScript: "No language specified"
        endif

    if not transcriptionFormat$ <> ""
        exitScript: "No Transcription Format specified"
        endif

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

    if (language$ == "English" and databaseTable$ == "Default")
        databaseTable$ = "subtlexus"

    endproc


procedure settings_error_later
    beginPause: "Settings Error"
        comment: "It appears the settings file you specified was made for a later version of DynamicFluency."
        comment: "Please install the latest version from https://github.com/JJWRoeloffs/DynamicFluency"
        comment: "________________________________________________________________________________"
        comment: "Do you want to run the script anyway?"
        run_anyway = endPause: "Yes", "No", 2
        if run_anyway = 2
            removeObject: idConfig
            exitScript()
            endif
    endproc

procedure settings_error_earlier       
    beginPause: "Settings Error"
        comment: "It appears the settings file you specified was made for an earier version of DynamicFluency."
        comment: "If you run the script with the current installation, any new features will run with default settings."
        comment: "________________________________________________________________________________"
        comment: "Do you want to run the script anyway?"
        run_anyway = endPause: "Yes", "No", 2
        if run_anyway = 2
            removeObject: idConfig
            exitScript()
            endif
    endproc

procedure dynamicity 
    # This hard-coding the relevant tiers.
    # Requires idMerged to be set.

    for tier from 8 to 17
        selectObject: idMerged
        idTier[tier] = Extract one tier: tier
        runScript: "scripts" + pathSep$ + "dynamicity.praat", stepsPerSecond, windowLength, kernelType$
        Remove tier: 1
        endfor
    
    selectObject: idTier[8]
    for tier from 8+1 to 17
        plusObject: idTier[tier]
        endfor
    Merge

    selectObject: idTier[8]
    for tier from 8+1 to 17
        plusObject: idTier[tier]
        endfor
    Remove

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

        @dynamicity
        
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
