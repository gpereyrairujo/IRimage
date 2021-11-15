## ``IRimage`` Open source software for processing images from infrared thermal cameras

### Summary

``IRimage`` aims at increasing throughput, accuracy and reproducibility of results obtained from thermal images, especially those produced with affordable, consumer-oriented cameras. IRimage efficiently processes hundreds of thermal images, extracting raw data and calculating temperature values with an open and fully documented algorithm, making this data available for further processing using image analysis software. It also allows to make reproducible measurements of the temperature of objects in series of images, and produce visual outputs (images and videos) suitable for scientific reporting. IRimage is implemented in a scripting language of the scientific image analysis software ImageJ, allowing its use through a graphical user interface and also allowing for an easy modification or expansion of its functionality. IRimage was validated against standard software for 15 camera models of the most widely used brand. IRimage's functionalities make it better suited for research purposes than many currently available alternatives, and could contribute to making affordable consumer-grade thermal cameras useful for reproducible research.

``IRimage`` is open source, in order to allow users to know the algorithms used to obtain the temperature values, as well as to encourage future improvement, modification and adaptation.

---

### Installation

1. Install [ImageJ](https://imagej.nih.gov/ij/download.html) or [FIJI](https://imagej.net/Fiji/Downloads) (take note of the location where it is installed - you will need it in step 3)
2. Download the complete [IRimage repository](https://github.com/gpereyrairujo/IRimage) using the 'Download ZIP' option in the green 'Code' button, save the ``IRimage-main.zip`` file and extract its contents 
3. Find the ``IRimage`` folder (not the ``IRimage-main`` folder) and copy it to the ``ImageJ.app/plugins`` folder (or the ``Fiji.app/plugins`` folder if you installed FIJI)

### Basic usage

1. Open ImageJ (or FIJI)
2. Open the 'Plugins' menu and you will find the 'IRimage' submenu
3. Select the 'Process' option
4. Select the folder with the original JPG images from the thermal camera
5. Choose whether you want to use the parameters stored in each file (when these were set in the camera), manually set global parameters for all the images, or use previously defined parameters (e.g. to repeat a previous analysis)
6. If the second option was selected, modify the default parameter values and click OK
7. The resulting images and data will be stored in subfolders within the input folder

More details about IRimage's implementation, functions and usage are included in the IRimage paper (soon to be published...).

### Contributing
Contributions are welcome! There are at least two ways to contribute:

1. If you find a bug or want to suggest an enhancement, use the [issues page](https://github.com/gpereyrairujo/IRimage/issues) on this repository.
2. If you modified, corrected or improved the macro code, you can use the [fork and pull request](https://help.github.com/articles/creating-a-pull-request-from-a-fork/) model.

For any type of contribution, please follow the [code of conduct](CODE_OF_CONDUCT.md).

---

### License

Software licensed [GNU Affero General Public License v3.0](https://github.com/gpereyrairujo/IRimage/blob/master/LICENSE)  
Documentation licensed [CC-BY-SA](https://creativecommons.org/licenses/by/2.0/)

### How to cite

If this macro contributes to a project or publication, please acknowledge this by citing as:

```
Pereyra Irujo, G. (2021). IRimage. Open source software for processing images from consumer thermal cameras. Available at: https://github.com/gpereyrairujo/IRimage/
```

### Contact

Gustavo Pereyra Irujo - gpereyrairujo.gustavo@conicet.gov.ar
