#Configuration wizard for Dynamic Fluency.
#This scrip will propt a wizard that guides the user through the configuration.
#It saves the configuration to dynamicfluency_configuration.txt in the directory the scrip is executed.
#
#This script can be run on its own, in which case it will run the wizard and save the file without running the main dynamicfluency script.

form Find Speaking Fluency Configuration
    comment Dynamic Fluency Configuration - Creating a configuration file without running the application.
    comment ________________________________________________________________________________
    comment Please specify the name you want to give the new configuration file.
    comment If this file already exists, it will be overwritten. 
    sentence Configuration_File configuration.txt
    endform

beginPause: "General Settings"
    optionMenu: "Operating_System", 1
        option: "Windows"
        option: "Linux"
#       option: "MacOS  (not yet implemented)"
    optionMenu: "Language", 1
        option: "English"
#       option Mandarin (not yet implemented)
#       option Spanish  (not yet implemented)
#       option Dutch    (not yet implemented)
    comment: "________________________________________________________________________________"
    sentence: "Input_File_Spec", "input/*.wav"
    sentence: "Output_Directory", "output"
    boolean: "Show_Intermediate_Objects", 1
    boolean: "Show_Results_In_Praat", 1
    comment: "________________________________________________________________________________"
    comment: "If aenas is configured, you can use a .TextGrid or .txt with the same name for the transcription"
    comment: "if you are using this, specify the transcription format."
    comment: "else, keep this setting at maus."
    optionMenu: "Transcription_Format", 1
        option: "maus"
        option: "TextGrid"
        option: "txt"
    endPause: "Next", 1

beginPause: "Uhm-o-meter settings"
    comment:  "Parameters Syllabe Nuclei:"
    optionMenu: "Pre_processing", 1
        option: "None"
        option: "Band pass (300..3300 Hz)"
        option: "Reduce noise"
    real: "Silence_threshold_dB", -25
    real: "Minimum_dip_near_peak_dB", 2
    real: "Minimum_pause_duration_s", 0.3
    comment: "________________________________________________________________________________"
    comment: "Parameters Filled Pauses:"
    real: "Filled_Pause_threshold", 1.00
    endPause: "Next", 1

beginPause: "Uhm-o-meter settings"
    comment: "Specify words to ignore in repitition and frequency analisys, seperated by only commas."
    sentence: "To_Ignore", "uh,uhm"
    real: "Max_Repitition_Read", 300
    comment: "________________________________________________________________________________"
    comment: "Setting the database table to default will use the one build-in for the language"
    comment: "However, you can also use your own, initialised with resources/add_frequency_dictionairy.py"
    sentence: "Database_Table", "Default"
    sentence: "Database_File", "databases/main.db"
    endPause: "Next", 1

beginPause: "Dynamicity settings"
    comment: "parameters for the  Moving Average across a textgrid."
    comment: "does not perform an fft convolution, instead using a dumb algorithm."
    real: "steps_per_second", 5
    real: "window_length_sec", 5
    optionMenu: "kernel", 1
        option: "moving_average"
#       option: "gaussian"
    endPause: "Finish", 1

# A simple but ugly write to file.
id = Create Strings from tokens: "configuration", "DynamicFluency configuration file", "_"

Insert string: 2, ""
Insert string: 3, "General Settings"
Insert string: 4, "OS=" + operating_System$
Insert string: 5, "Input File Spec=" + input_File_Spec$
Insert string: 6, "Output Dir=" + output_Directory$
Insert string: 7, "Language=" + language$
Insert string: 8, "Show Intermediate Objects=" + string$(show_Intermediate_Objects) 
Insert string: 9, "Show Results in Praat=" + string$(show_Results_In_Praat)
Insert string: 10, "Transcription Format=" + transcription_Format$
Insert string: 11, ""
Insert string: 12, "Uhm-o-meter Settings"
Insert string: 13, "Pre-processing=" + pre_processing$
Insert string: 14, "Silence Treshhold=" + string$(silence_threshold_dB)
Insert string: 15, "Minimum dip near peak=" + string$(minimum_dip_near_peak_dB)
Insert string: 16, "Minimum pause duration=" + string$(minimum_pause_duration_s)
Insert string: 17, "Filled pause threshold=" + string$(filled_Pause_threshold)
Insert string: 18, ""
Insert string: 19, "Repititions and Word Frequencies"
Insert string: 20, "To Ignore=" + to_Ignore$
Insert string: 21, "Max Repitition Read=" + string$(max_Repitition_Read)
Insert string: 22, "Database File=" + database_File$ 
Insert string: 23, "Database Table=" + database_Table$
Insert string: 24, ""
Insert string: 25, "Steps per second=" + string$(steps_per_second)
Insert string: 26, "Window length=" + string$(window_length_sec)
Insert string: 27, "Kernel Type=" + kernel$

Save as raw text file: configuration_File$

removeObject: id
