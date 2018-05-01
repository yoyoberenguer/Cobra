# Cobra
Cobra is a 2D space game with vertical scrolling (also called shmups), written exclusively in python 3.6 (using pygame) and playable with PS3 controller and/or keyboard. 
The project is under active development (no GUI available right now), but the coding is going pretty smoothly and I hope to deliver a solid engine within a few months with a couple playable levels.

DEMO AVAILABLE 
- Download the project (including Assets directory) and double click ont he batch file Cobra.exe.10485760.combine.bat.
- Run Cobra.exe 

FEATURES
Works with Keyboard and PS3 controller Automatic player's central turret with pre-define strategy using AI (collision course calculation, and risks triage). 
Fluid sprite animation made with Timeline FX. 
Vertical scrolling with parallax background - 3 layers. 
Personalised HUDS for life and energy (Life and energy levels are generated with Numpy arrays to create variable gradient colours). 
Real time spaceship status damage monitoring (wings, nose etc.) and the possibility to launch micro-bots to fix hull damages.
Nuke explosion generating a halo that blows out enemies and objects in deep space using an elastic collision engine to calculate objects' direction and momentum vectors. 
Collectables to grab throughout the space battle e.g. (nukes, energy cells, ammunitions and gems) Special effects created with python algorithm to generate random particles for homing missile propulsion, spaceship damage and super weapon effects. 
Enemy spaceship with pre-defined class and AI strategies (following path e.g. Bezier curves or controlled by AI e.g. evasive manoeuvre). Lots of methods for “pygame” image/surface processing using Numpy arrays (blending colours and texture e.g. superposed images, ADD/SUB transparency) for more realistic effect.
Some multi-threading for background processing.
Automated sound controller capable of supressing and adding sounds on demand.
And a lot of cython.


 
