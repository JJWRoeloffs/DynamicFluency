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
#	This fork by J J W Roeloffs is edited to work in the Dynamic Fluency system.


form Detect Syllables and Filled Pauses in Speech Utterances
  optionmenu Os 1
    option Windows
    option Linux
    option Mac

  sentence FileSpec ./*.flac
  comment ________________________________________________________________________________

  comment  Parameters Syllabe Nuclei:
  optionmenu Pre_processing 1
    option None
    option Band pass (300..3300 Hz)
    option Reduce noise
   real Silence_threshold_(dB) -25
   real Minimum_dip_near_peak_(dB) 2
   real Minimum_pause_duration_(s) 0.3
#  real Pitch_floor_(Hz) 30
#  real Voicing_threshold 0.25
# optionmenu Parser 2
#   option peak-dip		; save code in case anybody requests backwards compatibility
#   option dip-peak-dip
  comment ________________________________________________________________________________

  comment  Parameters Filled Pauses:
  optionmenu Language 1
    option English
#   option Mandarin (not yet implemented)
#   option Spanish  (not yet implemented)
    option Dutch
   real Filled_Pause_threshold 1.00
  endform

# the next arguments are hidden for normal use
data$             = "TextGrid"
pitch_floor       = 30
voicing_threshold = 0.25
parser$           = "dip-peak-dip"

@processArgs

for file to nrFiles
  idSnd#[file] = Read from file: directory$ + filename$[file]
  @findSyllableNuclei
  ext$ = right$(filename$[file], length(filename$[file])-rindex(filename$[file], ".")+1)
  selectObject: idSnd#[file], idTG#[file]
  runScript: "FilledPauses.praat", language$, filled_Pause_threshold, data$ == "Table"
  @countFilledPauses: idTG#[file]
  selectObject: idTG#[file]
  Save as text file: directory$ + replace$(filename$[file], ext$, ".uhm.TextGrid", 1)
  removeObject: idSnd#[file], idTG#[file]
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
  Set tier name: 1, "Pauzes"
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
  Insert point tier: 1, "Syllables"

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
  endproc

procedure processArgs

  nrObjects = 0
  nrStr     = 0

  len        = length(fileSpec$)
  sep        = rindex_regex(fileSpec$, "[\\/]")
  if os$ = "Windows"
    directory$ = "..\\..\\" + left$(fileSpec$, sep)
  else
    directory$ = "../../" + left$(fileSpec$, sep)
    endif
  selection$ = right$(fileSpec$, len-sep)
  idStr      = Create Strings as file list: "fileList", directory$ + selection$
  nrFiles    = Get number of strings
  nrObjects  = 0

  if nrFiles
    idSnd# = zero#(nrFiles)
    idTG#  = zero#(nrFiles)
    idTbl# = zero#(nrFiles)
    endif
  for file to nrFiles
    filename$[file] = Get string: file
    endfor
  endproc

procedure coda
  removeObject: idStr
  endproc
