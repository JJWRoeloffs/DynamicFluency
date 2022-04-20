#Configuration wizard for Dynamic Fluency.
#This scrip will propt a wizard that guides the user through the configuration.
#It saves the configuration to dynamicfluency_configuration.txt in the directory the scrip is executed.
#
#This script can be run on its own, in which case it will run the wizard and save the file without running the main dynamicfluency script.

beginPause: "OS"
    optionMenu: "Operating_System", 1
        option: "Windows"
        option: "Linux"
#       option: "MacOS (Not Implemented)"
endPause: "Next", 1

beginPause: "Destenation of Output"
    optionMenu: "Data", 1
        option: "TextGrid(s) only"
        option: "Praat Info window"
        option: "Save as text file"
        option: "Table"
    optionMenu: "DataCollectionType", 2 
        option: "OverWriteData"
        option: "AppendData"
    boolean: "Keep_Objects_(when_processing_files)", 1
endPause: "Next", 1

beginPause: "Uhm-o-meter settings"
    comment:  "Parameters Syllabe Nuclei:"
    optionMenu: "Pre_processing", 1
        option: "None"
        option: "Band pass (300..3300 Hz)"
        option: "Reduce noise"
    real: "Silence_threshold_(dB)", -25
    real: "Minimum_dip_near_peak_(dB)", 2
    real: "Minimum_pause_duration_(s)", 0.3
#   real: "Pitch_floor_(Hz)", 30
#   real: "Voicing_threshold", 0.25
#   optionMenu: "Parser", 2
#       option: "peak-dip"		; save code in case anybody requests backwards compatibility
#       option: "dip-peak-dip"
    comment: "________________________________________________________________________________"
    comment: "Parameters Filled Pauses:"
    boolean: "Detect_Filled_Pauses", 1
    real: "Filled_Pause_threshold", 1.00
endPause: "Next", 1