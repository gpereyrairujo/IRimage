## ``IRimage`` Open source software for processing images from consumer thermal cameras

### Summary

``IRimage`` is able to extract raw data and calculate temperature values from images of thermal cameras, making this data available for further processing using widely used scientific image analysis software. This tool was implemented as a macro for the open source software [ImageJ] or [FIJI], and is based on the open source software [ExifTool] to extract raw values from the thermal images for further calculations. It was implemented and tested using FLIR cameras, but the algorithms are potentially adaptable for other cameras for which raw sensor data could be obtained.  It has been tested with images from more than 15 camera models, and calculated temperatures were in all cases within 0.01°C of those obtained with the manufacturer’s software.

``IRimage`` follows four steps when processing the images: 1. user input, 2. extraction of camera calibration and environmental parameters from input files and calculation of derived variables, 3. calculation of temperature from raw values, 4. storage of the resulting images. The algorithm used for temperature calculation is detailed in the [``IRimage documentation``](https://github.com/gpereyrairujo/IRimage/blob/master/documentation/IRimage_full_documentation.md).

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

### Testing the code
If you modify the macro code, you can check if it still working properly by using the provided test image, and comparing the results with the temperature values obtained with the FLIR Tools software. This can be done by following these steps:

1. Download the contents of the  [``IRimage/test``](https://github.com/gpereyrairujo/IRimage/tree/master/IRimage/test) folder in this repository. It includes two files: the JPG test image and a CSV file with temperature values obtained with the FLIR Tools software
2. Run your ``IRimage`` macro on this folder (using the parameters stored in the test image)
3. Download the macro file [``IRimage_test.ijm``](https://github.com/gpereyrairujo/IRimage/blob/master/IRimage/IRimage_test.ijm) from the [``IRimage``](https://github.com/gpereyrairujo/IRimage/tree/master/IRimage) folder in this repository
4. Go to ``Plugins|Macros|Run...`` on the FIJI/ImageJ menu and select the location of the downloaded ``IRimage_test.ijm`` file to run the test macro, selecting the dowloaded ``test`` folder
6. Open the resulting ``test_image.jpg_TESTRESULTS.txt`` file, and check if the 'Temperature differences above 0.01°C' value is 0%. You can also compare the resulting files and images with those in the [``IRimage/test_results``](https://github.com/gpereyrairujo/IRimage/tree/master/IRimage/test_results) folder in this repository.

### Contributing
Contributions are welcome! There are at least two ways to contribute:

1. If you find a bug or want to suggest an enhancement, use the [issues page](https://github.com/gpereyrairujo/IRimage/issues) on this repository.
2. If you modified, corrected or improved the macro code, you can use the [fork and pull request](https://help.github.com/articles/creating-a-pull-request-from-a-fork/) model.

For any type of contribution, please follow the [code of conduct](CODE_OF_CONDUCT.md).

---

### License

Software licensed [GPLv3](https://github.com/gpereyrairujo/IRimage/blob/master/LICENSE)  
Documentation licensed [CC-BY](https://creativecommons.org/licenses/by/2.0/)

### How to cite

If this macro contributes to a project or publication, please acknowledge this by citing as:

```
Pereyra Irujo, G. (2019). IRimage. Open source software for processing images from consumer thermal cameras. Available at: https://github.com/gpereyrairujo/IRimage/
```

### Contact

Gustavo Pereyra Irujo - gpereyrairujo.gustavo@conicet.gov.ar

[ImageJ]: https://imagej.nih.gov/ij/index.html
[FIJI]: https://imagej.net/Fiji
[ExifTool]: http://owl.phy.queensu.ca/~phil/exiftool/
[ExifTool Forum]: http://u88.n24.queensu.ca/exiftool/forum/index.php/topic,4898.0.html
