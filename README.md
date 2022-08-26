# ax530_picorv32
A picorv32 playground for the ALINX AX530 dev board (this is a work-in-progress and probably won't work for you)

This repo uses the [Hog (HDL-on-git)](https://gitlab.com/hog-cern/Hog) project to organize the Quartus projects.

To generate the projects follow the instructions [here](https://hog.readthedocs.io/en/latest/01-Getting-Started/01-howto-existingProjects.html).

In short, clone this repo with
   
    git clone --recursive https://github.com/malcircuit/ax530_picorv32.git
   
Generate quartus projects by running

    ./Hog/CreateProject.sh <project>
    
The projects will then show up in `Projects` dir.
    
Available projects:

- `ax530/usb_test` - Test for the FX2LP-backed USB FIFO connection
- `ax530/picorv32_axi` - picorv32 base project (Platform Designer-based)
