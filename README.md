## ``IRimage`` Open source software for processing images from consumer thermal cameras

### Summary

``IRimage`` is able to extract raw data and calculate temperature values from images of thermal cameras, making this data available for further processing using widely used scientific image analysis software. This tool was implemented as a macro for the open source software [ImageJ] or [FIJI], and is based on the open source software [ExifTool] to extract raw values from the thermal images for further calculations. It was implemented and tested using FLIR cameras, but the algorithms are potentially adaptable for other cameras for which raw sensor data could be obtained.

``IRimage`` follows four steps when processing the images: 1. user input, 2. extraction of camera calibration and environmental parameters from input files and calculation of derived variables, 3. calculation of temperature from raw values, 4. storage of the resulting images. The algorithm used for temperature calculation is detailed in the [IRimage documentation](https://github.com/gpereyrairujo/IRimage/blob/master/documentation/IRimage_full_documentation.md).

``IRimage`` is open source, in order to allow users to know the algorithms used to obtain the temperature values, as well as to encourage future improvement, modification and adaptation.

---

### Installation

1. Install [ImageJ](https://imagej.nih.gov/ij/download.html) or [FIJI](https://imagej.net/Fiji/Downloads)
2. Install [ExifTool](http://owl.phy.queensu.ca/~phil/exiftool/install.html)
3. Download the macro file [``IRimage.ijm``](https://github.com/gpereyrairujo/IRimage/blob/master/IRimage/IRimage.ijm) from the [``IRimage``](https://github.com/gpereyrairujo/IRimage/tree/master/IRimage) folder in this repository
4. Save this file in the ``ImageJ.app/macros/toolsets`` folder (or the ``Fiji.app/macros/toolsets`` folder if you installed FIJI) in your computer

### Usage

1. Open ImageJ (or FIJI)
2. Click on the ``>>`` button ("More tools") at the end of the toolbar, and click on 'IRimage'
3. An 'IRimage' button should appear in the toolbar. Click on it to run the macro
4. Select the folder with the original JPG images from the thermal camera
5. Choose whether you want to set global parameters for all the images, or use the parameters stored in each file
6. If the first option was selected, modify the default parameter values and click OK
7. The resulting images will be stored in the same folder

---

### Acknowledgements

This work was largely based on the methods described by user 'tomas123' in the [ExifTool Forum].

### Author

Gustavo Pereyra Irujo  
orcid: 0000-0002-2261-6928  
affiliations: Instituto Nacional de Tecnología Agropecuaria (INTA), Consejo Nacional de Investigaciones Científicas y Técnicas (CONICET)  
contact: pereyrairujo.gustavo@conicet.gov.ar

### License

Software licensed [GPLv3](https://github.com/gpereyrairujo/IRimage/blob/master/LICENSE)  
Documentation licensed [CC-BY](https://creativecommons.org/licenses/by/2.0/)


[ImageJ]: https://imagej.nih.gov/ij/index.html
[FIJI]: https://imagej.net/Fiji
[ExifTool]: http://owl.phy.queensu.ca/~phil/exiftool/
[ExifTool Forum]: http://u88.n24.queensu.ca/exiftool/forum/index.php/topic,4898.0.html
