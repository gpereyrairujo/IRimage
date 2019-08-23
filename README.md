## ``IRimage`` Open source software for processing images from consumer thermal cameras

### Summary

Thermal imaging has many uses in scientific research. In recent years, thermal cameras have lowered their price, and even affordable (<$300) consumer cameras are now available. These cameras, available as stand-alone devices or smartphone attachments, have the potential to improve access to thermography in many fields of research. These cameras, however, are usually coupled to limited software, aimed at an non-scientific users. This software is usually limited to providing color-coded images and simple temperature measurements of manually-selected points or areas in the image. In many cases, the images are a result of blending visible and thermal images for improved resolution, which limits the extraction of temperature data from them. Moreover, software is usually closed-source, which does not allow the user to know the algorithms used to obtain the temperature measurements and the final image. For a thermal camera (or any sensor) to be useful for research, the user should be able to have control over (or at least information about) the processing steps between the raw sensor data and the final measurement.

``IRimage`` allows researchers to extract temperature data from images of thermal cameras. This software was implemented as a macro for the open source software [ImageJ] or [FIJI], which are widely used for scientific image analysis. It uses the open source software [ExifTool] to extract raw values from the thermal images. It was implemented and tested using FLIR cameras, but the algorithms are potentially adaptable for other cameras for which raw sensor data could be obtained. 

``IRimage`` follows four steps when processing the images: 1. user input, 2. extraction of camera calibration and environmental parameters from input files and calculation of derived variables, 3. calculation of temperature from raw values, 4. storage of the resulting images. The algorithm used for temperature calculation is detailed in the documentation.

``IRimage`` is published with an open source licence, in order to encourage future improvement, modification and adaptation.

### Installation

1. Install [ImageJ](https://imagej.nih.gov/ij/download.html) or [FIJI](https://imagej.net/Fiji/Downloads)
2. Install [ExifTool](http://owl.phy.queensu.ca/~phil/exiftool/install.html)
3. Download the macro file ``IRimage.ijm`` from the ``macro`` folder in this repository
4. Save this file in the ``ImageJ.app/macros/toolsets`` folder (or the ``Fiji.app/macros/toolsets`` folder if you installed FIJI)

### Usage

1. Open ImageJ (or FIJI)
2. Click on the ``>>`` button ("More tools") at the end of the toolbar, and click on 'IRimage'
3. An 'IRimage' button should appear in the toolbar. Click on it to run the macro
4. Select the folder with the original JPG images
5. Choose whether you want to set global parameters for all the images, or use the parameters stored in each file
6. If the first option was selected, modify the default parameter values and click OK
7. The resulting images will be stored in the same folder

### Theory

#### Relationship between temperature and infrared radiation

<img src="https://latex.codecogs.com/svg.latex?S=G\cdot&space;L&plus;O%0">

<img src="https://latex.codecogs.com/svg.latex?L_{\lambda}=\varepsilon&space;\cdot&space;\frac{2hc^{2}}{\lambda^{5}&space;}&space;\cdot&space;\frac{1}{e^{\frac{hc}{\lambda&space;kT}}-1}">

<img src="https://latex.codecogs.com/svg.latex?L_{\lambda}=\varepsilon&space;\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T}}-1)}">

<img src="https://latex.codecogs.com/svg.latex?S=G\cdot&space;\varepsilon&space;\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T}}-1)}&plus;O">

#### Sources of radiation

<img src="https://latex.codecogs.com/svg.latex?S=\tau&space;\cdot&space;S_{obj}&plus;\tau&space;\cdot&space;S_{refl}&plus;S_{atm}">

#### Estimation of atmospheric transmissivity

<img src="https://latex.codecogs.com/svg.latex?H=RH\cdot&space;e^{(1.5587\:&space;&plus;\:&space;6.939\cdot&space;10^{-2}\cdot&space;t\:&space;-\:&space;2.7816\cdot&space;10^{-4}\cdot&space;t^{2}\:&space;&plus;\:&space;6.8455\cdot&space;10^{-7}\cdot&space;t^{3})}">

<img src="https://latex.codecogs.com/svg.latex?\tau&space;=X\cdot&space;e^{[-\sqrt{d}\cdot&space;(\alpha&space;_{1}&plus;\beta&space;_{1}\cdot&space;\sqrt{H})]}&plus;(1-X)\cdot&space;e^{[-\sqrt{d}\cdot&space;(\alpha&space;_{2}&plus;\beta&space;_{2}\cdot&space;\sqrt{H})]}">

#### Estimation of digital signal values for different radiation sources

<img src="https://latex.codecogs.com/svg.latex?S_{obj}=G\cdot&space;\varepsilon&space;\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T_{obj}}}-1)}&plus;O">

<img src="https://latex.codecogs.com/svg.latex?S_{atm}=G\cdot&space;(1-\tau)&space;\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T_{atm}}}-1)}&plus;O">

<img src="https://latex.codecogs.com/svg.latex?S_{atm}=G\cdot&space;(1-\varepsilon&space;)\cdot&space;(\varepsilon&space;_{refl})&space;\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T_{refl}}}-1)}&plus;O">

<img src="https://latex.codecogs.com/svg.latex?S_{atm}=G\cdot&space;(1-\varepsilon&space;)\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T_{app.refl}}}-1)}&plus;O">

#### Object temperature calculation

<img src="https://latex.codecogs.com/svg.latex?S_{obj}=\frac{S_{tot}}{\tau&space;}-S_{refl}-\frac{S_{atm}}{\tau&space;}">

<img src="https://latex.codecogs.com/svg.latex?T_{obj}=\frac{B}{log(\frac{G\cdot&space;\varepsilon&space;}{R\cdot&space;(S_{obj}-O)}&plus;1)}">

### Implementation

The image processing steps are implemented as a macro for the [ImageJ] software, thus allowing simple modification and adaptation to other scientific image processing pipelines.  The method relies on having access to the raw sensor data obtained from the camera. In the case of FLIR cameras, this data is stored in the EXIF data in the “radiometric jpg” files, together with the camera-specific and user-set parameters needed to calculate temperature. This data can be extracted through the use of the [ExifTool] software. 

The algorithm consists of these steps:

#### User input

Considering the most common use cases, the macro was built so as to process complete folders of thermal images. Since user-set parameters are stored within individual images, the macro can either: 1) use a set of global parameters for all images (this is useful when all images were captured under the same conditions, or if parameters need to be modified), or 2) process each file using the stored parameters (this is useful when the user has manually modified these parameters according to specific conditions for each image). In case the first option is selected, a dialog box is shown where all parameters can be confirmed or modified (the default parameter values are those extracted from the first file in the folder).

#### Extraction of parameters from JPEG files

The macro then processes all images in JPG format within the user-selected folder. First, using the ExifTool software, raw data is extracted in PNG format. Next, all camera-specific and user-set parameters are also extracted.

Parameter / Variable | Variable name in macro | Symbol used in equations | Eq. | EXIF tag name in FLIR JPG file
--- | --- | --- | --- | ---
_Calibration / camera-specific parameters_ | 
Raw Thermal Image Type (PNG or TIFF) | imageType |  |  | Raw Thermal Image Type
Camera Model | cameraModel |  |  | Camera Model
Sensor gain | sensorG | G | 1 | Planck R1
Sensor offset | sensorO | O | 1 | Planck O
Sensor calibration parameter B | sensorB | B | 4 | Planck B
Sensor calibration parameter F * | sensorF |  |  | Planck F
Sensor calibration parameter R | sensorR | R | 4 | Planck R2
_Atmospheric parameters_ | 
Atmospheric transmissivity parameter 1 | atmAlpha1 | 1 | 7 | Atmospheric Trans Alpha 1
Atmospheric transmissivity parameter 2 | atmAlpha2 | 2 | 7 | Atmospheric Trans Alpha 2
Atmospheric transmissivity parameter 1 | atmBeta1 | 1 | 7 | Atmospheric Trans Beta 1
Atmospheric transmissivity parameter 2 | atmBeta2 | 2 | 7 | Atmospheric Trans Beta 2
Atmospheric transmissivity parameter X | atmX | X | 7 | Atmospheric Trans X
User-selected parameters |  |  |  | 
Apparent reflected temperature (°C) | appReflTemp_C |  |  | Reflected Apparent Temperature
Air temperature (°C) | airTemp_C | t | 6 | Atmospheric Temperature
Object emissivity | objEmissivity |  | 4 | Emissivity
Air relative humidity | airRelHumidity_perc | RH | 6 | Relative Humidity
Object distance from camera | objDistance_m | d | 7 | Object Distance

_* This parameter is included in the JPG EXIF tags but it is always equal to 1, and is equivalent to the value of 1 in the term (eBT-1)in Eq. 4_

#### Calculation of derived variables

The next step is the calculation of variables derived from these parameters, including the calculation of atmospheric transmissivity (using Eq. 6-7) and the estimated digital signal from reflected objects and the atmosphere (using Eq. 9-11). Both the extraction of parameters and the calculation of these variables are either performed for each file or only for the first file in the folder, depending on the option selected by the user.

Parameter / variable | Variable name in macro | Symbol used in equations | Eq.
--- | --- | --- | ---
Raw image byte order / endianness | byteOrderLittleEndian |  | 
Aparent reflected temperature (K) | appReflTemp_K | Tapp.refl | 11
Air temperature (K) | airTemp_K | Tatm | 9
Air water content | airWaterContent | H | 7
Atmospheric transmissivity | atmTau |  | 5
Raw signal from atmosphere (DN) | atmRawSignal_DN | Satm | 5
Raw signal from reflected radiation (DN) | reflRawSignal_DN | Srefl | 5

#### Temperature calculation

First, using the exiftool software, raw data is extracted in PNG format. The resulting image containing the raw sensor data is then opened within the ImageJ software, and each pixel containing the digital signal from the sensor is processed sequencially. First, the object signal is estimated using Eq. 12, and then the temperature value is calculated using Eq. 13. 

Parameter / Variable | Variable name in macro | Symbol used in equations | Eq. | EXIF tag name in FLIR JPG file
--- | --- | --- | --- | ---
Raw sensor signal (DN) * | rawSignal_DN | S | 1 | Raw Thermal Image
Raw signal from object (DN) | objRawSignal_DN | Sobj | 5 | 
Object temperature (°C) | objTemp_C | Tobj | 8 | 

_* All raw sensor signal values are extracted as a PNG format image, then each pixel is processed sequencially, storing each value in the rawSignal_DN variable._

#### Outputs

The resulting image with temperature values for each pixel is stored in a separate file in TIFF format, under the same filename with a 'TEMP' suffix and a .TIF extension. The temperature values are also exported as comma-separated text values, with a 'TEXT' suffix and a .TXT extension. Finally, the image is converted to a false-color RGB image and stored in PNG format, with a 'COLOR' suffix and a .PNG extension.

### Evaluation

### References

[ImageJ]: https://imagej.nih.gov/ij/index.html
[FIJI]: https://imagej.net/Fiji
[ExifTool]: http://owl.phy.queensu.ca/~phil/exiftool/
