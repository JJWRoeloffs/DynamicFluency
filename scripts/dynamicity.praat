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
    exitScript: "Can only use dynamicity.praat on a TextGrid with exactly one Tier"
    endif

if isInterval == 1
    @preposess_intervals
    @calculate_nr_steps
    @interval_convolution
    @write_to_textgrid
else
    @calculate_nr_steps
    @point_convolution
    @write_to_textgrid
    endif


procedure preposess_intervals
    nrIntervals = Get number of intervals: 1

    for i to nrIntervals
        label$ = Get label of interval: 1, i
        if label$ != "" and label$ != "MISSING"
            variable = number(label$)
            Set interval text: 1, i, string$(variable)
        endif
    endfor  
endproc

procedure calculate_nr_steps
    start = Get start time
    end   = Get end time
    duration = end - start
    nrSteps = floor((duration-window_length_sec)*steps_per_second)
    if nrSteps < 1
        nrSteps = 1
        endif
endproc

procedure interval_convolution
    k=1
    movingStart = start
    movingEnd = start+window_length_sec
    nrIntervals = Get number of intervals: 1
    result# = zero#(nrSteps)
    for i to nrSteps
        intervalStart = Get start time of interval: 1, k
        while (intervalStart < movingStart) and (k < nrIntervals)
            k+=1
            intervalStart = Get start time of interval: 1, k
            endwhile
        
        movingSum = 0
        amountSummed = 0

        j=0
        repeat
            if k+j <= nrIntervals
                label$ = Get label of interval: 1, k+j 
                if label$ != "" and label$ != "MISSING"
                    movingSum += number(label$)
                    amountSummed+= 1
                    endif

                intervalEnd = Get end time of interval: 1, k+j 

                j+=1
            else
                # Poor man's break statement
                intervalEnd = end
                endif
        until intervalEnd > movingEnd

        movingStart+=(1/steps_per_second)
        movingEnd+=(1/steps_per_second)
        
        if amountSummed == 0
            result#[i] = ""
        else
            result#[i] = movingSum/amountSummed
            endif
        endfor
endproc

procedure point_convolution
    k=1
    movingStart = start
    movingEnd = start+window_length_sec
    nrPoints = Get number of points: 1
    result# = zero#(nrSteps)
    for i to nrSteps
        pointStart = Get time of point: 1, k
        while (pointStart < movingStart) and (k < nrPoints)
            k+=1
            pointStart = Get time of point: 1, k
            endwhile
        
        movingSum = 0
        amountSummed = 0

        j=0
        repeat
            if k+j <= nrPoints
                movingSum += 1
                pointEnd = Get time of point: 1, k+j 
                j+=1
            else
                # Poor man's break statement
                pointEnd = end
                endif
        until pointEnd > movingEnd

        movingStart+=(1/steps_per_second)
        movingEnd+=(1/steps_per_second)
        
        result#[i] = movingSum
        endfor   
endproc

procedure write_to_textgrid
    tierName$ = Get tier name: 1
    Insert interval tier: 2, tierName$ + "Dynamicity"

    movingBoundary = window_length_sec/2
    Insert boundary: 2, movingBoundary
    for i to nrSteps
        movingBoundary+= 1/steps_per_second
        Insert boundary: 2, movingBoundary
        Set interval text: 2, i+1, string$(result#[i])
        endfor
endproc
