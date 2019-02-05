

Cobra DEMO

Cobra is a 2D space game with vertical scrolling (also called shmups), written exclusively in python 3.6 (using pygam & cython) 
and playable with PS3 controller and/or keyboard.
The project is under active development, but the coding is going pretty smoothly and I hope
to deliver a solid engine within a few months with a couple of playable levels.

Screendump are taken from the most recent engine that will be used for a commercial version of Cobra
See also the GUI screendump at the bottom of the page.

If you are curious or interest by the project, you can always drop me a line at yoyoberenguer@gmail.com


![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump0.png)   
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump3.png) 
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump4.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump5.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump8.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump9.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump10.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump11.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump12.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump13.png)

SYSTEM REQUIRMENT
CPU: Dual core or quad core 2.2Ghz.
Memory: 4GB 
Display: 1280x1024 32 bit 

HOW TO INSTALL 
2 methods: 
1) Downloads Installer.exe parts and double click on the batch file. 
   This will launch a window installer.  
   
2) Download the project (including Assets directory) and double click on the batch file Cobra.exe.10485760.combine.bat.  
   Run Cobra.exe

HOW TO PLAY 
Keyboard: 
ARROW KEYS: (LEFT, RIGHT, UP and DOWN) for spaceship direction

SPACEBAR:  Primary shot

LEFT – CTRL: Secondary shot

PAUSE/BREAK : Pause the game

ESC: to quit

PS3 Joystick:
X: Primary shot

SQUARE: Micro bots

L3: Directions

L2: Atomics

R2: Secondary shot and missiles

** PS Insert your PS3 USB dongle if any otherwise use the keyboard

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

# GUI in progress

![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/GUI0.png)   
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/GUI1.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/GUI2.png)



 


