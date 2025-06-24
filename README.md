# FlightGear F-15

Models F-15C, F-15D based on aerodynamic data from AFIT/GAE/ENY/90D-16

Notes: 

- F-15C in the critical aft c.g. configuration has a weight of 33,467
pounds and a c.g. location at 563.1 inches (6:12). To
convert c.g. location in inches to percent mean aerodynamic
chord, the following equation is used for all A through D
models of the F-15: (measurements in inches).
% MAC = (xcg - 408.1 * 100) / 191.33

-  The original report AD-A217 366 refers to the aero being in body axes in a few places, but then also confusingly we have the comment "CFX = FORCE IN STABILITY AXES X DIRECTION (CD IN BODY AXIS). Having checked the equations of motion I can't find where the body axes to stability axes transformation is made so my conclusion is that probably the aero is in stability axes. This is further supported by testing that gives us much higher alpha at low speed. For example on approach clean, with 7000lbs of fuel at ISA with 140kts indicated alpha is around 21 degrees and we're looking at the sky. Performance testing for continuous rate turn was unattainable with body axes forces. The VSPAERO model was also in the stability axes and was a fair match to the aero model. Unless I can find some other data that is more definitive I'm fairly confident that the original aero data is in the stasbility axes - it is simply a confusion in the report. See commit 932ae119, a9191f7a, 6def237d, 4b740f2b, 35f9e2af

- The performance has been matched using refs for F100-PW-220 perf data; reports TM-86042, TM-104278, AFRL-PR-WP-TR-1999-2069, NASA TP-1228, NASA  TP-1482, NASA TP-1373, NASA-TM-83446) max rate turn and level flight accel now match, see 0280adf8

- Ground effect simulated based on  NASA-TM-104278, p228

- Gear will fail if the descent rate exceeds 1200ft/min (and the gear is in contact with the ground; so it is possible (and usual) to damage only one side), based on NASA-TM-104278 that states that 600ft/min is the maximum recommeded for the strut.

- JSBSim axes system has origin so that 0,0,0 is the CG (25.65% MAC)


## RELEASE NOTES

### V1.12

* TEWS improvements
* VSD improvements
* MPCD SIT map rewrite
* Emesary damage
* Hyds, JFS simulation model improved
* aero model improved for flaps.
* nasal performance improvements
* weapons, radar updates.

#### detailed change log

+ 2022-10-19 : Move revised autopilot dialog
+ 2022-10-19 : Finish emexec changes
+ 2022-10-16 : Sim: Fix that some callsigns could mess up emesary communications. (#164)
+ 2022-07-17 : emexec changes to aircraft-main
+ 2022-07-17 : TEWS improvements
+ 2022-07-17 : VSD improvemets
+ 2022-07-17 : change to use emexec
+ 2022-07-17 : Use new Emesary Exec module (emexec)
+ 2022-07-15 : Fix VSD on backseat
+ 2022-07-10 : weapons update (#162)
+ 2022-02-06 : MPCD SIT readability
+ 2022-02-06 : Updated damage files
+ 2022-01-22 : Fix target lock over MP
+ 2022-01-20 : Fixes #151 : New SIT display on MPCD
+ 2021-08-16 : 2018.3 compatibility
+ 2021-08-16 : Fix JFS hyds
+ 2021-08-16 : fix JSBSim property initialization warnings.
+ 2021-06-19 : WIP Landing tutorial
+ 2021-05-27 : MP animations and external stores
+ 2021-05-27 : rework external stores select animations
+ 2021-05-27 : prevent changing of stuff according to usual convention.
+ 2021-05-21 : Forgot to commit this change to bomb weight.
+ 2021-05-21 : Small change to sending spiked msg to locked aircraft.
+ 2021-05-20 : Added failure mode for fire-control.
+ 2021-05-20 : Added GBU-10 Paveway II laser guided bombs. Added bomb release sound.
+ 2021-05-20 : Fix the ccippipper was rotating opposite.
+ 2021-05-20 : Fix same bug
+ 2021-05-20 : Fixed uncommmented line
+ 2021-05-20 : Wing inboard station pylon/rack weight now again done in JSBSim.
+ 2021-05-15 : Added training configuration (#83)
+ 2021-05-15 : Added Training option (#84)
+ 2021-01-28 : Remove JMaverick16 personal liveries;
+ 2021-01-28 : remove userarchive from model properties.
+ 2020-10-26 : Use PartitionProcessor from core libs
+ 2020-10-09 : HUD fix IAS speed tape
+ 2020-09-29 : Revert changes to MPCD (incorrect model saved)
+ 2020-09-03 : Emesary fixes
+ 2020-09-03 : Added missing aero reference
+ 2020-10-15 : Adding more missiles
+ 2020-09-29 : Revert changes to MPCD (incorrect model saved)
+ 2020-09-03 : Emesary fixes
+ 2020-09-03 : Added missing aero reference
+ 2020-03-26 : Tuning of flaps
+ 2020-02-23 : UV map fixes
+ 2019-12-21 : latest livery version
+ 2019-11-02 : Contrail now depends on weather rather than altitude


