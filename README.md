## ``IRimage`` Open source software for processing images from consumer thermal cameras

### Summary

Thermal imaging has many uses in scientific research. In recent years, thermal cameras have lowered their price, and even affordable (<$300) consumer cameras are now available. These cameras, available as stand-alone devices or smartphone attachments, have the potential to improve access to thermography in many fields of research. These cameras, however, are usually coupled to limited software, aimed at an non-scientific users. This software is usually limited to providing color-coded images and simple temperature measurements of manually-selected points or areas in the image. In many cases, the images are a result of blending visible and thermal images for improved resolution, which limits the extraction of temperature data from them. Moreover, software is usually closed-source, which does not allow the user to know the algorithms used to obtain the temperature measurements and the final image. For a thermal camera (or any sensor) to be useful for research, the user should be able to have control over (or at least information about) the processing steps between the raw sensor data and the final measurement.

``IRimage`` allows researchers to extract temperature data from images of thermal cameras. This software was implemented as a macro for the software ImageJ (cita) or FIJI (cita), which are widely used for biological image analysis. It was implemented and tested using FLIR cameras, but the algorithms are potentially adaptable for other cameras for which raw sensor data could be obtained. 

``IRimage`` follows four steps when processing the images: 1. user input, 2. extraction of camera calibration and environmental parameters from input files and calculation of derived variables, 3. calculation of temperature from raw values, 4. storage of the resulting images. The algorithm used for temperature calculation is detailed in the documentation.

``IRimage`` is published with an open source licence, in order to encourage future improvement, modification and adaptation.

### Usage

### Installation

### Theory

#### Relationship between temperature and infrared radiation

#### Sources of radiation

#### Estimation of atmospheric transmissivity

#### Estimation of digital signal values for different radiation sources

#### Object temperature calculation

### Implementation

#### User input

#### Extraction of parameters from JPEG files

#### Calculation of derived variables

#### Temperature calculation

#### Outputs

### Evaluation

### References
