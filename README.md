Overview
========
a script for semi-manual tracking of object (pollen tube) movement in 2D & time
and kymogram extraction

Functionality
=============

1. Registers multiple movie channels coherently based on one (most stable channel).

2. Based on the path of the object tracked manually by the user on 2D `(x,y)`, returns:

- a kymogram [dimensions: `(r,t)`]

- 2D `(r,t)` path of the object on the kymogram as a ImageJ ROI

3. Based on the obtained 2D paths in `(x,y)` and `(r,t)` surfaces,
returns 3D `(x,y,t)` path.

4. Given a 3D path and the object radius (and possibly an `r[x,y]`-lag), 
returns a mask and applies to the original movie. 
This yields a signal in the object as a time course.
      

Inputs
======
a TIFF movie and the object's 2D path in ImageJ ROI format are taken as input


Output
======
a kymogram
