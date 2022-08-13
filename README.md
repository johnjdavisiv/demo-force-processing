# Demo force data processing

Bertec treadmill force plate data (recorded by QTM) to OpenSim-compatible .mot data. Filters raw force signal *before* CoP calculations. Marker data come along for the ride.  This works **for aerial running only**. Will not work out-of-the-box for walking or grounded running.  

## Workflow  

Running `main.m` does the following things:  

1) Read the raw force data and marker data from TSVs (marker data are needed for force-to-foot assignment)  
2) Save raw force data as an intermediary .sto file and flip the markers around so they show up correctly in OpenSim (forces get flipped later). Note that OpenSim never sees this .sto, it's just a useful tabular data storage format.    
3) Use a sliding window approach to "undrift" the GRF data (treadmill heats up over time, baseline "zero" value can drift by several tens of Newtons). Roughly inspired by [Dryft](https://github.com/alcantarar/dryft) by Alcantara et al. but with some tweaks and simplifications.  
4) Combine force data from both belts into one force plate (necessary if subjects had cross-strikes on both belts or switched back and forth between belts)  
5) Detect steps using conservatively filtered force data (recommend ~50 Hz) and f_threshold (recommend ~25 N)
6) Filter original data at more aggressive cutoff (~18 Hz) ([necessary to avoid impact artifacts in kinetics](https://www.sciencedirect.com/science/article/pii/S0021929011007792))
7) Compute COP from global coordinate forces and moments  
8) Format forces for OpenSim (flip coordinate system)  
9) Assign forces to feet using a virtual force plate technique where there are two "virtual" force plates superimposed on one another (one that only applies force to the left foot, and one that only applies force to the right foot). Also does some clever interpolation during swing phase when CoP is undefined; this helps avoid issues at initial contact/toe-off.   

Resulting .mot and .trc files can be viewed in OpenSim with the `File > Preview Experimental Data...` feature. The final, fully processed files to view are `JDX_S999_run_0021.trc` (markers) and `JDX_S999_run_0021_undrift.mot` (force). 

## Useful references  

http://www.kwon3d.com/theory/grf/reac.html  
http://www.kwon3d.com/theory/grf/cop.html  
http://www.kwon3d.com/theory/grf/pad.html  
https://biomch-l.isbweb.org/forum/biomch-l-forums/general-discussion/44299-summing-free-moments-from-two-force-plates-on-a-cross-strike  
https://biomch-l.isbweb.org/forum/biomch-l-forums/general-discussion/32938-non-planar-moving-force-plates-in-c3d?p=39057#post39057  
https://github.com/opensim-org/opensim-core/issues/2256#issuecomment-510695284  
https://simtk.org/plugins/phpBB/viewtopicPhpbb.php?f=91&t=14766&p=42785&start=0&view=
https://www.sciencedirect.com/science/article/pii/S0021929011007792