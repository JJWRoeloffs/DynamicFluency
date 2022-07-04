CREATE TABLE IF NOT EXISTS subtlexus (
    word        text    PRIMARY KEY     NOT NULL,
    freq_count  integer,   
    cd_count    integer,   
    freq_low    integer,   	    
    cd_low	    real,   
    subtlwf		real,   
    lg10wf	    real,   
    subtlcd     real,   
    lg10cd      real   
);