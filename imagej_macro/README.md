`BatchAlign_Subfolders.ijm`
===========================

a script for Registration of multichannel movies

requires user input (GUI)

## Prerequisites

### Plugin
The `MultiStackRegFix_s` (supplied) modification of 
P.Thevenaz ImageJ java programme is required 

### Folder tree
The folder structure assumed:
  
    rootFolder
       |
       |------ folderExperiment_1 [folder]
       |            |-------- violetDots.tiff
       |            |-------- GFP.tiff
       |            |-------- YFP.tiff
       |            |-------- xxx-channel.tiff
       |
       |------ MyNobelPrizeExperiment [folder]
       |            |-------- violetDots.tiff
       |            |-------- GFP.tiff
       |            |-------- YFP.tiff
       |            |-------- xxx-channel.tiff
       |
       |
       |------ MyNaturePaperExperiment [folder]
       |            |-------- violetDots.tiff
       |            |-------- GFP.tiff
       |            |-------- YFP.tiff
       |            |-------- xxx-channel.tiff
       |
      ...

Each folder contains (at least) the same set of TIFF files, representing channels of the movie. 
Their names will be requested by the macros.

These files are assumed to have the same number of frames within one folder.

The script goes through each sub-folder, generates transformation matrices, 
registers and stores the result in the corresponding sub-folders.

### Preliminary Knowledge

Find out which channel is best suited as a reference channel. 

Namely, one that has:

1. no expected motile objects

2. least fluorescence intenisty variation
   In case of a ratiometric (FRET) sensor, 
   use the emission channel of the donor

