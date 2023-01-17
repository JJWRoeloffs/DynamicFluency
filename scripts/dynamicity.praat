form Textgrid Convolution
    comment calculate a Moving Average across a textgrid.
    comment does not perform an fft convolution, instead using a dumb algorithm.
    comment presumes the textgrid is selected.  
    real steps_per_second 5
    real window_length_sec 5
    optionmenu kernel 1
        option moving_average
#       option gaussian
    endform

nrTiers    = Get number of tiers
isInterval = Is interval tier: 1

if nrTiers != 1
    exitScript: "Can only use dynamicity.praat on a TextGrid with exactly one Interval Tier"
    endif

if isInterval != 1
    exitScript: "Can only use dynamicity.praat on a TextGrid with exactly one Interval Tier"
    endif

nrIntervals = Get number of intervals: 1

# clean intervals, and trow error early.
for i to nrIntervals
    label$ = Get label of interval: 1, i
    if label$ != ""
        variable = number(label$)
        Set interval text: 1, i, string$(variable)
    endif
endfor  

# Calculate the amount of steps the algorithm will actually have to do.
start = Get start time
end   = Get end time
duration = end - start
nrSteps = floor((duration-window_length_sec)*steps_per_second)
if nrSteps < 1
    nrSteps = 1
    endif

# Actual algorithm
k=1
movingStart = start
movingEnd = start+window_length_sec
result# = zero#(nrSteps)
for i to nrSteps
    intervalStart = Get start time of interval: 1, k
    while intervalStart > movingStart
        k+=1
        intervalStart = Get start time of interval: 1, k
        endwhile
    
    label$ = Get label of interval: 1, k 
    movingSum = 0
    amountSummed = 0

    j=0
    repeat
        label$ = Get label of interval: 1, k+j 
        if label$ != ""
            movingSum += number(label$)
            amountSummed+= 1
            endif

        intervalEnd = Get end time of interval: 1, k+j 

        j+=1
    until intervalEnd > movingEnd

    movingStart+=(1/steps_per_second)
    movingEnd+=(1/steps_per_second)
    
    result#[i] = movingSum/amountSummed
    endfor

# Write to TextGrid
tierName$ = Get tier name: 1
Insert interval tier: 2, tierName$ + "Dynamicity"

movingBoundary = window_length_sec/2
Insert boundary: 2, movingBoundary
for i to nrSteps
    movingBoundary+= 1/steps_per_second
    Insert boundary: 2, movingBoundary
    Set interval text: 2, i+1, string$(result#[i])
    endfor
