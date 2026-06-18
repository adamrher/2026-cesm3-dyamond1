#!/bin/bash

#PBS -N esmf
#PBS -A P03010039
#PBS -l walltime=01:59:00
#PBS -q main
#PBS -l job_priority=premium
#PBS -j oe
#PBS -l select=4:ncpus=128:mpiprocs=128

date

module load cray-mpich/8.1.29 mkl/2024.2.2 hdf5/1.12.3 parallel-netcdf/1.14.0
module load ncarenv/24.12 intel/2024.2.1 ncarcompilers/1.0.0 cray-mpich/8.1.29 netcdf/4.9.2 
module load esmf/8.8.0

esmf_path="/glade/u/apps/cseg/derecho/23.06/spack/opt/spack/linux-sles15-x86_64_v3/oneapi-2023.0.0/esmf-8.6.0b04-mkg7dasd7hipsqte2ibfflqzfe7cwgos/bin"

src_scrip="/glade/campaign/cesm/cesmdata/inputdata/share/scripgrids/mpasa3.75_SCRIP_desc-20210803.nc"
dst_scrip="/glade/campaign/cgd/amp/aherring/mpas-uniform/mpasa3p75/analysis/wgtfiles/G9896_latlon_scrip.nc"
remap_type="conserve"
weightnam="mpasa3p75_TO_G9896_cnsrv.nc"

mpiexec -np 512 -ppn 128 ${esmf_path}/ESMF_RegridWeightGen -s ${src_scrip} -d ${dst_scrip} -m ${remap_type} -w ${weightnam} --64bit_offset

date
