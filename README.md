

# Cobra DEMO

**Cobra** is a 2D space game with vertical scrolling (also called shmups), written with python (using pygame & cython) 
and playable with **PS3 controller and/or keyboard or mouse**.
The project is still ongoing.

### SYSTEM REQUIRMENT
CPU: Dual core or quad core 2.2Ghz.
Memory: at least 4GB (the current engine requires 2.8 GBytes)

### REQUIRED PYTHON LIBRARIES
Requires the following: 
```
pygame==2.4.0
numpy==1.19.5
psutil>=5.9.5
Cython==0.29.25
lz4>=3.1.3
PygameShader>=1.0.8
```
### VISUAL STUDIO BUILDING TOOLS 
```
Visual studio building tools 2015 - 2022
```
### HOW TO INSTALL 
 
1. Download the latest build (around 280MBytes)
2. Decompress the archive (zip)
3. cd into the main directory ```Cobra2P``` where setup_cobra.py is located
4. Run the following command with python3.11 (for better performances)
   ```bash
   C:\>python setupe_cobra.py build_ext --inplace
   ```
6. run
   ```bash
   C:\>python Engine29.py
   ```
### Compatibility 

The game works on most platforms (windows, linux) 
Architectures such as i686, x86_64, win32

To run Cobra on win32, you will have to extend to 4G the memory
limit used by the python.exe process. 

Locate the executable editbin.exe from the VC\Tools\MSVC folder and run
```
editbin.exe python.exe /LARGERADDRESSAWARE
```



![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump0.png) 
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump1.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump2.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump3.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump4.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump5.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/Screendump6.png)


### HOW TO PLAY 

#### Mouse for moving the spaceship

#### Keyboard 

**Key**                     | Assignement 
------------------------|-----------------------------------------------------
**ARROW KEYS**              | (LEFT, RIGHT, UP and DOWN) for spaceship direction or use mouse
**SPACEBAR**                |  Primary shot
**LEFT – CTRL**             | Secondary shot 
**B**                       | Cluster Bomb
**ENTER**                   | Atomic
**SHIFT LEFT**              | Super Laser
**RIGHT ALT**               | Nanobots
**PAUSE/BREAK**             | Pause the game
**ESC**                     | to quit

#### PS3 Joystick
**button**                  |   Assignement
--------------------------------------------------
**X**                       | Primary shot
**SQUARE**                  | Micro bots
**L3**                      | Directions
**L2**                      | Atomics
**R2**                      | Secondary shot and missiles

Note: _Insert your PS3 USB dongle if any otherwise use the keyboard_

### FEATURES

Works with Keyboard and PS3 controller Automatic player's central turret with pre-define strategy using AI (collision course calculation, and risks triage).

Fluid sprite animation made with **Timeline FX**.

Vertical scrolling with parallax background - 3 layers.

Personalised HUDS for life and energy (Life and energy levels are generated with Numpy arrays to create variable gradient colours).

Nuke explosion generating a halo that blows out enemies and objects in deep space using an elastic collision engine to calculate objects' direction and momentum vectors.

Collectables to grab throughout the space battle e.g. (nukes, energy cells, ammunitions and gems) Special effects created with python algorithm to generate random particles for homing missile propulsion, spaceship damage and super weapon effects.

Enemy spaceship with pre-defined class and AI strategies (following path e.g. Bezier curves or controlled by AI e.g. evasive manoeuvre). Lots of methods for “pygame” image/surface processing using Numpy arrays (blending colours and texture e.g. superposed images, ADD/SUB transparency) for more realistic effect.

Automated sound controller capable of supressing and adding sounds on demand.

### GUI in progress

![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/GUI0.png)   
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/GUI1.png)
![alt text](https://github.com/yoyoberenguer/Cobra/blob/master/GUI2.png)



 


