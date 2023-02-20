#!/usr/bin/env python3

# I/O Options
# storage directories
data_dir  = r''         # where input satellite datas are stored
outp_dir  = r''         # where to write eddy tracked files
work_dir  = r'./'       # for writing temp files (delete at the end of the script)

# list of altimetry input files where to made the detection
# example :
# filenames = ['cmems_obs-sl_glo_phy-ssh_my_allsat-l4-duacs-0.25deg_P1D_2011.nc',
#              'cmems_obs-sl_glo_phy-ssh_my_allsat-l4-duacs-0.25deg_P1D_2012.nc']
filenames = []

logger_type = 'ERROR'  # (py-eddy-tracker) options: ERROR, WARNING, INFO, DEBUG


# Algorithm Options
variable   = 'adt'
wavelength = 400       # Bessel filter

# --------------------------------------------------------------------------------------
#
import os
import numpy as np
import xarray as xr
import warnings

from datetime import datetime
from matplotlib import pyplot as plt

from py_eddy_tracker import start_logger
from py_eddy_tracker.dataset.grid import RegularGridDataset

warnings.filterwarnings("ignore", category=DeprecationWarning)
warnings.filterwarnings("ignore")

start_logger().setLevel(logger_type)

# Script
if __name__ == '__main__':
    for fname in filenames:
        ds  = xr.load_dataset(os.path.join(data_dir, fname))
        
        for t in range(ds.dims['time']):
            dt   = ds['time'][t]
            tstp = ((dt - np.datetime64('1970-01-01T00:00:00'))/np.timedelta64(1, 's'))
            date = datetime.utcfromtimestamp(tstp)
            
            sel  = ds.isel({'time': t})
            sel.to_netcdf(os.path.join(work_dir, 'temp.nc'))
            
            temp = os.path.join(work_dir, 'temp.nc')
            grid = RegularGridDataset(temp, 'longitude', 'latitude', centered=True, 
                                      nan_masking=True)
            
            grid.add_uv(variable, 'ugosa', 'vgosa')
            grid.copy(variable, "{}_raw".format(variable))
            grid.bessel_high_filter(variable, wavelength)
    
            AC_det, C_det = grid.eddy_identification(variable, "ugosa", "vgosa", 
                                                     date, 0.002)
            
            outname = "%(path)s/%(sign_type)s_{}.nc".format(date.strftime("%Y%m%d"))
            C_det.write_file(path=outp_dir, filename=outname)
    
            os.remove(os.path.join(work_dir, 'temp.nc'))


