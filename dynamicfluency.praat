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
@assert_output_empty

runScript: "scripts" + pathSep$ + "uhm-o-meter" + pathSep$ + "SyllableNuclei.praat", inputFileSpec$, preProcessing$, silenceTreshhold, minimumDipNearPeak, minimumPauseDuration, language$, filledPauseThreshold 
@uhm_postprocessing

if allignment$ = "aeneas"
    @aeneas_preprocessing
    if windows
        @aeneas_windows
    else
        @aeneas_unix
        endif
    endif

if allignment$ == "maus"
    @maus
    endif

if windows
    runSystem: "py -3.10 -m dynamicfluency.scripts.make_postagged_grids_from_alligned_grids -d " + outputDir$ + " -a " + allignment$ + " -l" + language$
else
    runSystem: "python3 -m dynamicfluency.scripts.make_postagged_grids_from_alligned_grids -d " + outputDir$ + " -a " + allignment$ + " -l" + language$
    endif

if windows 
    runSystem: "py -3.10 -m dynamicfluency.scripts.make_repetitionstagged_grids_from_postagged_grids -d " + outputDir$ + " -m " + maxRepititionRead$ + " -i " + toIgnore$
else
    runSystem: "python3 -m dynamicfluency.scripts.make_repetitionstagged_grids_from_postagged_grids -d " + outputDir$ + " -m " + maxRepititionRead$ + " -i " + toIgnore$
    endif
 
if windows
    runSystem: "py -3.10 -m dynamicfluency.scripts.make_frequencytagged_girds_from_alligned_grids -d " + outputDir$ + " -t " + databaseTable$ + " -b " + database$ + " -i " + toIgnore$ + " -a " + allignment$
else
    runSystem: "python3 -m dynamicfluency.scripts.make_frequencytagged_girds_from_alligned_grids -d " + outputDir$ + " -t " + databaseTable$ + " -b " + database$ + " -i " + toIgnore$ + " -a " + allignment$
    endif

if windows
    runSystem: "py -3.10 -m dynamicfluency.scripts.make_syntax_grids_from_postagged_grids -d " + outputDir$ + " -l" + language$
else
    runSystem: "python3 -m dynamicfluency.scripts.make_syntax_grids_from_postagged_grids -d " + outputDir$ + " -l" + language$
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
    Insert string: 0, "py -3.10 -m dynamicfluency.scripts.convert_aeneas_to_textgrids -d " + outputDir$
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

        if windows
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
        if windows
            runSystem: "move /-Y " + inputDir$ + pathSep$ + uhmFile$ + " " + outputDir$ + pathSep$  + uhmFile$
        else
            runSystem: "mv " + inputDir$ + pathSep$ + uhmFile$ + " " + outputDir$ + pathSep$  + uhmFile$
            endif
        
        idObject = Read from file: outputDir$ + pathSep$ + uhmFile$

        # Phrases
        nrIntervals = Get number of intervals: 2
        for i to nrIntervals
            label$ = Get label of interval: 2, i
            if label$ == ""
                intervalStart = Get start time of interval: 2, i
                intervalEnd = Get end time of interval: 2, i
                Set interval text: 2, i, string$((intervalEnd-intervalStart)/2)
            else
                Set interval text: 2, i, "0"
                endif
            endfor

        # DFauto
        nrIntervals = Get number of intervals: 3
        for j to nrIntervals
            label$ = Get label of interval: 3, j
            intervalStart = Get start time of interval: 3, j
            intervalEnd = Get end time of interval: 3, j
            
            if label$ == ""
                phrasesInterval = Get interval at time: 2, (intervalEnd+intervalStart)/2
                phrasesText$ = Get label of interval: 2, phrasesInterval
                if phrasesText$ == "0"
                    Set interval text: 3, j, "0"
                else
                    Set interval text: 3, j, ""
                    endif
            else
                Set interval text: 3, j, string$((intervalEnd-intervalStart)/2)
                endif
            endfor

        Save as text file: outputDir$ + pathSep$ + uhmFile$
        Remove
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
    if numberOfLines > 26
        @settings_error_later
        endif
    if numberOfLines < 26
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

        if left$(line$, sep) == "Input File Spec="
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
        
        # Dynamicity Settings
        elif left$(line$, sep) == "Steps per second="
            stepsPerSecond = number(right$(line$, len-sep))

        elif left$(line$, sep) == "Window length="
            windowLength = number(right$(line$, len-sep))
        
        elif left$(line$, sep) == "Kernel Type="
            kernelType$ = right$(line$, len-sep)
            endif

        endfor

# Throwing errors for essential missing values.
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

    if windows
        pathSep$ = "\"
    else
        pathSep$ = "/"
        endif

    idSoundsList = Create Strings as file list: "SoundsList", inputDir$ + pathSep$ + selection$
    nrFiles      = Get number of strings

    if (transcriptionFormat$ == "TextGrid") or (transcriptionFormat$ == "txt")
        allignment$ = "aeneas"
        nrAllignmentTiers = 2
    elif transcriptionFormat$ == "Maus"
        allignment$ = "maus"
        nrAllignmentTiers = 3
    elif transcriptionFormat# == "Whisper"
        allignment$ = "whisper"
        nrAllignmentTiers = 4
    else:
        exitScript: "Unknown transcription type:" + transcriptionFormat$
        endif

    if (language$ == "English" and databaseTable$ == "Default")
        databaseTable$ = "subtlexus"
        endif

    if (language$ == "Dutch" and databaseTable$ == "Default")
        databaseTable$ = "subtlexnl"
        endif

    endproc

procedure assert_output_empty
    .filesInOutput$# = fileNames$#: outputDir$
    if size(.filesInOutput$#) != 0
        beginPause: "Specified output directory contains files"
            comment: "The specified output directory: " + outputDir$
            comment: "currently contains files that might be overwritten."
            comment: "Do you want to delete ALL files in that directory?"
            .deleteFiles = endPause: "Yes", "No", 2

        if .deleteFiles == 2
            removeObject: idSoundsList
            exitScript()
        else
            for i from 1 to size(.filesInOutput$#)
                deleteFile: outputDir$ + pathSep$ + .filesInOutput$#[i]
                endfor
            endif
        endif
    endproc

procedure settings_error_later
    beginPause: "Settings Error"
        comment: "It appears the settings file you specified was made for a later version of DynamicFluency."
        comment: "Please install the latest version from https://github.com/JJWRoeloffs/DynamicFluency"
        comment: "________________________________________________________________________________"
        comment: "Do you want to run the script anyway?"
        run_anyway = endPause: "Yes", "No", 2
        if run_anyway == 2
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
        if run_anyway == 2
            removeObject: idConfig
            exitScript()
            endif
    endproc

procedure dynamicity 
    # Requires idMerged to be set.
    selectObject: idMerged
    nrTiers = Get number of tiers

    for i from 1 to nrTiers - nrAllignmentTiers
        selectObject: idMerged
        idTier[i] = Extract one tier: i + nrAllignmentTiers
        runScript: "scripts" + pathSep$ + "dynamicity.praat", stepsPerSecond, windowLength, kernelType$
        Remove tier: 1
        endfor

    selectObject: idTier[1]
    for i from 2 to nrTiers - nrAllignmentTiers
        plusObject: idTier[i]
        endfor

    dynamicmerge = Merge

    for i from 1 to nrTiers - nrAllignmentTiers
        removeObject: idTier[i]
        endfor

endproc


# Takes all the individually generated textgrids from the different tools, and merges them together.
# Also loads the files into the praat gui if the user asked for this.
procedure postprocessing

    for file to nrFiles
        selectObject: idSoundsList
        soundFile$ = Get string: file
        soundExt$ = right$(soundFile$, length(soundFile$)-rindex(soundFile$, ".")+1)

        allignmentFile$ = replace$(soundFile$, soundExt$, ".allignment.TextGrid", 1)
        uhmFile$ = replace$(soundFile$, soundExt$, ".uhm.TextGrid", 1)
        posFile$ = replace$(soundFile$, soundExt$, ".pos_tags.TextGrid", 1)
        repFile$ = replace$(soundFile$, soundExt$, ".repetitions.TextGrid", 1)
        freqFile$ = replace$(soundFile$, soundExt$, ".frequencies.TextGrid", 1)
        syntFile$ = replace$(soundFile$, soundExt$, ".syntax.TextGrid", 1)
        mergedFile$ = replace$(soundFile$, soundExt$, ".merged.TextGrid", 1) 
        dynamictable$ =  replace$(soundFile$, soundExt$, ".dynamic.txt", 1)

        idAllignment = Read from file: outputDir$ + pathSep$ + allignmentFile$
        idUhm = Read from file: outputDir$ + pathSep$ + uhmFile$
        idPOS = Read from file: outputDir$ + pathSep$ + posFile$
        idRep = Read from file: outputDir$ + pathSep$ + repFile$
        idFreq = Read from file: outputDir$ + pathSep$ + freqFile$
        idSynt = Read from file: outputDir$ + pathSep$ + syntFile$

        # It appears this guarantees order, and makes the allignmentFile first
        selectObject: idAllignment, idUhm, idPOS, idRep, idFreq, idSynt
        idMerged = Merge
        Save as text file: outputDir$ + pathSep$ + mergedFile$

        @dynamicity

        selectObject: dynamicmerge
        Down to Table: "no", 6, "yes", "no"
        Insert column: 1, "SoundfileID"
        nrowsinfile = Get number of rows
        for irow to nrowsinfile
           Set string value: irow, "SoundfileID", soundFile$ 
        endfor
        Save as tab-separated file: outputDir$ + pathSep$ + dynamictable$
 
        if (showIntermediateObjects == 0) or (showResultInPraat == 0)
            removeObject: idUhm, idAllignment, idPOS, idRep, idFreq, idSynt
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
    removeObject: idSoundsList
    endproc
