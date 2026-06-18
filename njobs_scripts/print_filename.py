#!/usr/bin/env python3
"""
Read date/datesec from a CAM history file and write a new NetCDF containing
a datestamp variable in YYYY-MM-DD-SSSSS format for each time slice.

Environment variables:
    INFILE  - path to input NetCDF file
    OUTFILE - path to output NetCDF file
"""
import os
import numpy as np
import netCDF4 as nc

infile  = os.environ["INFILE"]
outfile = os.environ["OUTFILE"]

with nc.Dataset(infile) as fin, \
     nc.Dataset(outfile, "w", format="NETCDF4_CLASSIC") as fout:

    dates    = fin.variables["date"][:]     # YYYYMMDD
    datesecs = fin.variables["datesec"][:]  # seconds of current day
    ntimes   = len(dates)

    # Build YYYY-MM-DD-SSSSS strings
    stamps = []
    for d, s in zip(dates.tolist(), datesecs.tolist()):
        yyyy =  d // 10000
        mm   = (d % 10000) // 100
        dd   =  d % 100
        stamps.append(f"{yyyy:04d}-{mm:02d}-{dd:02d}-{s:05d}")

    nchar = 16  # length of "YYYY-MM-DD-SSSSS"
    fout.createDimension("time", ntimes)
    fout.createDimension("datestamplen", nchar)

    # Copy time, date, datesec with their attributes
    for vname in ("time", "date", "datesec"):
        src = fin.variables[vname]
        dst = fout.createVariable(vname, src.dtype, ("time",))
        dst[:] = src[:]
        dst.setncatts({a: src.getncattr(a) for a in src.ncattrs()})

    # Write datestamp as fixed-length char array
    ds = fout.createVariable("datestamp", "S1", ("time", "datestamplen"))
    ds.long_name = "date stamp (YYYY-MM-DD-SSSSS)"
    ds[:] = nc.stringtochar(np.array(stamps, dtype=f"S{nchar}"))

print(f"Wrote {ntimes} datestamp(s) to {outfile}")
