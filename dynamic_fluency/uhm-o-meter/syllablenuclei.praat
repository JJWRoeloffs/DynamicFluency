#  Praat Script Syllable Nuclei, version 3 (Syllable Detector)
#
# counts syllables of selected sounds
# NB unstressed syllables are sometimes overlooked
# NB filter sounds that are quite noisy beforehand
# NB use Silence threshold (dB) = -25 (or -20?)
# NB use Minimum dip between peaks (dB) = between 2-4 (you can first try;
#                                                      For clean and filtered: 4)
#
# Original by:
# Copyright (C) 2019  Nivja de Jong, Ton Wempe, Jos J A Pacilly
#
#	This fork by J J W Roeloffs is slightly edited to work in the Dynamic Fluency system.

form Detect Syllables and Filled Pauses in Speech Utterances
  optionmenu Operating_System 1
    option Windows
    option Linux
    #button MacOS (Not Implemented)
  
  sentence OutFile ../outputdata/*.wav
  sentence InFile ../imputdata/*.wav

  optionmenu Pre_processing 1
    option None
    option Band pass (300..3300 Hz)
    option Reduce noise
   real Silence_threshold_(dB) -25
   real Minimum_dip_near_peak_(dB) 2
   real Minimum_pause_duration_(s) 0.3

  boolean Detect_Filled_Pauses yes
  optionmenu Language 1
    option English
#   option Mandarin (not yet implemented)
#   option Spanish  (not yet implemented)
#   option Dutch (not jet implemented)
   real Filled_Pause_threshold 1.00

  optionmenu Data 1
    option TextGrid(s) only
    option Praat Info window
    option Save as text file
    option Table
  choice DataCollectionType 2
    button OverWriteData
    button AppendData
  boolean Keep_Objects_(when_processing_files) yes
  endform

# the next arguments are hidden for normal use
pitch_floor       = 30
voicing_threshold =  0.25
parser$           = "dip-peak-dip"

@processArgs

for file to nrObjects
  selectObject: idSnd#[file]
  @findSyllableNuclei
  if detect_Filled_Pauses
    selectObject: idSnd#[file], idTG#[file]
    runScript: "FilledPauses.praat", language$, filled_Pause_threshold, data$ == "Table"
    if data$ == "Table"
      idTbl#[file] = selected("Table")
      endif
    @countFilledPauses: idTG#[file]
  else
    @terminateLines
    endif
  endfor

for file to nrFiles
  idSnd#[file] = Read from file: directory$ + filename$[file]
  @findSyllableNuclei
  ext$ = right$(filename$[file], length(filename$[file])-rindex(filename$[file], ".")+1)
  if detect_Filled_Pauses
    selectObject: idSnd#[file], idTG#[file]
    runScript: "FilledPauses.praat", language$, filled_Pause_threshold, data$ == "Table"
    if data$ == "Table"
      idTbl#[file] = selected("Table")
      selectObject: idTbl#[file]
      Save as tab-separated file: directory$ + replace$(filename$[file], ext$, ".auto.Table", 1)
      endif
    @countFilledPauses: idTG#[file]
  else
    @terminateLines
    endif
  selectObject: idTG#[file]
  Save as text file: directory$ + replace$(filename$[file], ext$, ".auto.TextGrid", 1)
  if not keep_Objects
    removeObject: idSnd#[file], idTG#[file]
    if detect_Filled_Pauses and data$ == "Table"
      removeObject: idTbl#[file]
      endif
    endif
  endfor

@coda


procedure findSyllableNuclei
  name$ = selected$("Sound")

  if pre_processing$ == "None"
    idSnd = selected ("Sound")
  elif pre_processing$ == "Band pass (300..3300 Hz)"
    idSnd = Filter (pass Hann band): 300, 3300, 100
    Scale peak: 0.99
  elif pre_processing$ == "Reduce noise"
    idSnd = noprogress Reduce noise: 0, 0, 0.025, 80, 10000, 40, -20, "spectral-subtraction"
    Scale peak: 0.99
    endif

  tsSnd  = Get start time
  teSnd  = Get end time
  dur    = Get total duration

  idInt  = To Intensity: 50, 0, "yes"		; use intensity to get threshold
  dbMin  = Get minimum: 0, 0, "Parabolic"
  dbMax  = Get maximum: 0, 0, "Parabolic"
  dbQ99  = Get quantile: 0, 0, 0.99		; get .99 quantile to get maximum (without influence of non-speech sound bursts)

# estimate Intensity threshold
  threshold  = dbQ99 + silence_threshold
  threshold2 = dbMax - dbQ99
  threshold3 = silence_threshold - threshold2
  if threshold < dbMin
    threshold = dbMin
    endif

# get pauses (silences) and speakingtime
  idTG = To TextGrid (silences): threshold3, minimum_pause_duration, 0.1, "", "sound"
  Set tier name: 1, "Phrases"
  nrIntervals = Get number of intervals: 1
  nsounding   = 0
  speakingtot = 0
  for interval to nrIntervals
    lbl$ = Get label of interval: 1, interval
    if lbl$ <> ""
      ts = Get start time of interval: 1, interval
      te = Get end time of interval:   1, interval
      nsounding   += 1
      speakingtot += te - ts
      Set interval text: 1, interval, string$(nsounding)
      endif
    endfor

  selectObject: idInt
  idPeak = To IntensityTier (peaks)
  selectObject: idSnd
  idP = noprogress To Pitch (ac): 0.02, pitch_floor, 4, "no", 0.03, voicing_threshold, 0.01, 0.35, 0.25, 450

# fill array with intensity values
  peakcount = 0
  selectObject: idPeak
  nrPeaks = Get number of points
  for peak to nrPeaks
    selectObject: idPeak
    time  = Get time from index: peak
    dbMax = Get value at index: peak
    selectObject: idP
    voiced = Get value at time: time, "Hertz", "Linear"
    if dbMax > threshold and (voiced <> undefined)
      peakcount      += 1
      t [peakcount*2] = time		; peaks at EVEN indices (base 2)
      db[peakcount*2] = dbMax
      endif
    endfor

# get Minima between peaks		; minima at ODD indices (base 1) t[1, 3, 5..]
  t[0]               = Get start time
  t[2*(peakcount+1)] = Get end time
  selectObject: idInt
  for valley to peakcount+1
    t [2*valley-1] = Get time of minimum: t[2*(valley-1)], t[2*valley], "Parabolic"
    db[2*valley-1] = Get minimum:         t[2*(valley-1)], t[2*valley], "Parabolic"
    endfor

  selectObject: idTG
  Insert point tier: 1, "Nuclei"

  tierDebug = 0
  if tierDebug
    Insert point tier: tierDebug, "DEBUG"
    endif

# fill array with the largest peaks *followed* by a dip > minimum_dip_near_peak (obsolete), OR
# with the largest peaks *surrounded* by a dip > minimum_dip_near_peak (current default method)

  voicedcount = 0	; nrNuclei
  tp[voicedcount] = t[0]
  tRise           = t[0]
  tFall           = t[0]
  tMax            = t[0]
  tMin            = t[0]
  dbMax           = db[1]
  dbMin           = db[1]
  nrPoints        = 2*peakcount+1
  selectObject: idTG

  for point to nrPoints
    if tierDebug
      Insert point: tierDebug, t[point], fixed$(db[point], 2)
      endif

    if db[point] > dbMax
      tMax  =  t[point]
      dbMax = db[point]
      if db[point] - dbMin > minimum_dip_near_peak
        tRise =  t[point]
        dbMin = db[point]
        endif

    elif db[point] < dbMin
      tMin  =  t[point]
      dbMin = db[point]
      if dbMax - db[point] > minimum_dip_near_peak
        tFall =  t[point]
        dbMax = db[point]
        endif
      endif

#   Insert voiced peaks in TextGrid (note that the code for the obsolete
#   "peak-dip" parser is kept only for backward compatibility reasons)

    if parser$ ==     "peak-dip" and                   tRise < tFall and tFall <> t[0] or
...    parser$ == "dip-peak-dip" and tRise <> t[0] and tRise < tFall and tFall <> t[0]

      i  = Get interval at time: 2, tMax
      l$ = Get label of interval: 2, i
      if l$ <> ""
        voicedcount    += 1
        tp[voicedcount] = tMax
        Insert point: 1, tMax, string$(voicedcount)
        tMax  = t [point]
        tMin  = t [point]
        dbMin = db[point]
        dbMax = db[point]
        tRise = t [0]
        tFall = t [0]
        endif
      endif
    endfor
  tp[voicedcount+1] = t[2*(peakcount+1)]

# verify that shift in time between various objects is no longer an issue
  tsTG = Get start time
  teTG = Get end time
  assert tsSnd == tsTG and teSnd == teTG

# clean up before next sound file is opened
  removeObject: idInt, idPeak, idP
  if pre_processing$ <> "None"
    removeObject: idSnd
    endif
  idTG#[file] = idTG

# summarize results in Info window
  speakingrate = voicedcount / dur
  articulationrate = voicedcount / speakingtot
  npause = nsounding - 1
  asd = speakingtot / voicedcount

  if data$ == "Praat Info window"
    appendInfo: "'name$', 'voicedcount', 'npause', 'dur:2', 'speakingtot:2', 'speakingrate:2', 'articulationrate:2', 'asd:3'"
  elif data$ == "Save as text file"
    appendFile: "SyllableNuclei.txt", "'name$', 'voicedcount', 'npause', 'dur:2', 'speakingtot:2', 'speakingrate:2', 'articulationrate:2', 'asd:3'"
  elif data$ == "Table"
    appendFile: temporaryDirectory$ + "/SyllableNuclei.tmp", "'name$', 'voicedcount', 'npause', 'dur:2', 'speakingtot:2', 'speakingrate:2', 'articulationrate:2', 'asd:3'"
    endif
  endproc

procedure countFilledPauses: .id
  selectObject: .id
  .nrInt = Get number of intervals: 3
  .nrFP  = 0
  .tFP   = 0
  for .int to .nrInt
    .lbl$ = Get label of interval: 3, .int
    if .lbl$ == "fp"
      .nrFP += 1
      .ts = Get start time of interval: 3, .int
      .te = Get end time of interval: 3, .int
      .tFP += (.te - .ts)
      endif
    endfor
  if data$ == "Praat Info window"
    appendInfoLine: ", '.nrFP', '.tFP:3'"
  elif data$ == "Save as text file"
    appendFileLine: "SyllableNuclei.txt", ", '.nrFP', '.tFP:3'"
  elif data$ == "Table"
    appendFileLine: temporaryDirectory$ + "/SyllableNuclei.tmp", ", '.nrFP', '.tFP:3'"
    endif
  endproc

procedure terminateLines
  if data$ == "Praat Info window"
    appendInfoLine: ""
  elif data$ == "Save as text file"
    appendFileLine: "SyllableNuclei.txt", ""
  elif data$ == "Table"
    appendFileLine: temporaryDirectory$ + "/SyllableNuclei.tmp", ""
    endif
  endproc

procedure processArgs
  nrObjects = numberOfSelected("Sound")
  nrStr     = numberOfSelected("Strings")

  if nrObjects and nrStr == 0
    idSnd#  = selected#("Sound")
    idTG#   = zero#(nrObjects)
    idTbl#  = zero#(nrObjects)
    nrFiles = 0
  elif nrStr and nrObjects == 0
    for str to nrStr
      idStr[str] = selected("Strings", str)
      endfor
    idStr = Append
    nrFiles    = Get number of strings
    directory$ = ""
  elif nrStr == 0 and fileSpec$ <> ""
    len        = length(fileSpec$)
    sep        = rindex_regex(fileSpec$, "[\\/]")
    directory$ =  left$(fileSpec$, sep)
    selection$ = right$(fileSpec$, len-sep)
    idStr      = Create Strings as file list: "fileList", directory$ + selection$
    nrFiles    = Get number of strings
    nrObjects  = 0
#   appendInfoLine: directory$ + selection$
  else
    exit Unsupported Input Selection
    endif

  if nrFiles
    idSnd# = zero#(nrFiles)
    idTG#  = zero#(nrFiles)
    idTbl# = zero#(nrFiles)
    endif
  for file to nrFiles
    filename$[file] = Get string: file
    endfor

  if data$ == "Praat Info window" and dataCollectionType$ == "OverWriteData"
# print a single header line with column names and units
    writeInfo: "name, nsyll, npause, dur(s), phonationtime(s), speechrate(nsyll/dur), articulation_rate(nsyll/phonationtime), ASD(speakingtime/nsyll)"
  elif data$ == "Save as text file" and dataCollectionType$ == "OverWriteData"
    writeFile: "SyllableNuclei.txt", "name, nsyll, npause, dur(s), phonationtime(s), speechrate(nsyll/dur), articulation_rate(nsyll/phonationtime), ASD(speakingtime/nsyll)"
  elif data$ == "Table"
    writeFile: temporaryDirectory$ + "/SyllableNuclei.tmp", "name, nsyll, npause, dur(s), phonationtime(s), speechrate(nsyll/dur), articulation_rate(nsyll/phonationtime), ASD(speakingtime/nsyll)"
    endif

  if detect_Filled_Pauses
    if data$ == "Praat Info window" and dataCollectionType$ == "OverWriteData"
      appendInfoLine: ", nrFP, tFP(s)"
    elif data$ == "Save as text file" and dataCollectionType$ == "OverWriteData"
      appendFileLine: "SyllableNuclei.txt", ", nrFP, tFP(s)"
    elif data$ == "Table"
      appendFileLine: temporaryDirectory$ + "/SyllableNuclei.tmp", ", nrFP, tFP(s)"
      endif
  else
    if data$ == "Praat Info window" and dataCollectionType$ == "OverWriteData"
      appendInfoLine: ""
    elif data$ == "Save as text file" and dataCollectionType$ == "OverWriteData"
      appendFileLine: "SyllableNuclei.txt", ""
    elif data$ == "Table"
      appendFileLine: temporaryDirectory$ + "/SyllableNuclei.tmp", ""
      endif
    endif
  endproc

procedure coda
  if nrObjects and nrStr == 0
    selectObject: idTG#
    if detect_Filled_Pauses and data$ == "Table"
      plusObject: idTbl#
      endif
  elif nrStr
    selectObject: idStr
    Remove
    for str to nrStr
      plusObject: idStr[str]
      endfor
  elif nrStr == 0 and fileSpec$ <> ""
    removeObject: idStr
    endif
  if data$ == "Table"
    Read Table from comma-separated file: temporaryDirectory$ + "/SyllableNuclei.tmp"
    deleteFile: temporaryDirectory$ + "/SyllableNuclei.tmp"
    endif
  if nrFiles and keep_Objects
    selectObject: idSnd#, idTG#
    if detect_Filled_Pauses and data$ == "Table"
      plusObject: idTbl#
      endif
    endif
  endproc