; print_filename.ncl
; Read date/datesec from a CAM history file and write a new NetCDF containing
; a datestamp variable in YYYY-MM-DD-SSSSS format for each time slice.
;
; Environment variables:
;   INFILE  - path to input NetCDF file
;   OUTFILE - path to output NetCDF file
begin
    infile  = getenv("INFILE")
    outfile = getenv("OUTFILE")

    fin = addfile(infile, "r")

    date_in    = fin->date      ; YYYYMMDD
    datesec_in = fin->datesec   ; seconds of current day
    time_in    = fin->time
    ntimes     = dimsizes(date_in)

    ; Build YYYY-MM-DD-SSSSS strings
    stamps = new(ntimes, string)
    do i = 0, ntimes-1
        d    = tointeger(date_in(i))
        s    = tointeger(datesec_in(i))
        yyyy =  d / 10000
        mm   = (d % 10000) / 100
        dd   =  d % 100
        stamps(i) = sprinti("%0.4i", yyyy) + "-" + \
                    sprinti("%0.2i", mm)   + "-" + \
                    sprinti("%0.2i", dd)   + "-" + \
                    sprinti("%0.5i", s)
    end do
    stamps!0 = "time"

    ; Write output as NetCDF4
    setfileoption("nc", "Format", "NetCDF4")
    fout = addfile(outfile, "c")

    fout->time    = time_in
    fout->date    = date_in
    fout->datesec = datesec_in
    ; Declare datestamp on the already-written time dimension before assigning,
    ; so NCL uses it rather than creating a generic ncl1 dimension.
    filevardef(fout, "datestamp", "string", "time")
    fout->datestamp = (/ stamps /)
    fout->datestamp@long_name = "date stamp (YYYY-MM-DD-SSSSS)"

    print("Wrote " + ntimes + " datestamp(s) to " + outfile)
end
