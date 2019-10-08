## ``IRimage`` Open source software for processing images from consumer thermal cameras

### Summary

Thermal imaging has many uses in scientific research. In recent years, thermal cameras have lowered their price, and affordable consumer cameras are now available. These cameras, available as stand-alone devices or smartphone attachments, have the potential to improve access to thermography in many fields of research. These cameras, however, are usually coupled to limited software, aimed at an non-scientific users. This software is usually limited to providing color-coded images and simple temperature measurements of manually-selected points or areas in the image. In many cases, the images are a result of blending visible and thermal images for improved resolution, which limits the extraction of temperature data from them. Moreover, software is usually closed-source, which does not allow the user to know the algorithms used to obtain the temperature measurements and the final image. For a thermal camera (or any sensor) to be useful for research, the user should be able to have control over (or at least information about) the processing steps between the raw sensor data and the final measurement.

``IRimage`` allows researchers to extract raw data and calculate temperature values from images of thermal cameras, making this data available for further processing using widely used scientific image analysis software. This tool was implemented as a macro for the open source software [ImageJ] [[1]] or [FIJI] [[2]], and is based on the open source software [ExifTool] [[3]] to extract raw values from the thermal images for further calculations. It was implemented and tested using FLIR cameras, but the algorithms are potentially adaptable for other cameras for which raw sensor data could be obtained. Earlier versions of this tool were used to benchmark a low cost thermal camera [[4]] and to analyze thermal images of wheat varieties [[5]]. It has been tested with images from more than 15 camera models, and calculated temperatures were in all cases within 0.01°C (0.0002°C on average) of those obtained with the manufacturer’s software.

``IRimage`` follows four steps when processing the images: 1. user input, 2. extraction of camera calibration and environmental parameters from input files and calculation of derived variables, 3. calculation of temperature from raw values, 4. storage of the resulting images. The algorithm used for temperature calculation is detailed in this documentation.

``IRimage`` is published with an open source licence, in order to encourage future improvement, modification and adaptation.

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

For any type of contribution, please follow the [code of conduct](https://github.com/gpereyrairujo/IRimage/blob/master/CODE_OF_CONDUCT.md).

---

### Theory

#### Relationship between temperature and infrared radiation

Thermal cameras are based on the detection of infrared radiation emitted from objects by means of an array of sensors. Each of these sensors generates a digital signal, which is a function of radiance (![L](https://latex.codecogs.com/svg.latex?\inline&space;L)). Radiance is the radiant flux (i.e. amount of energy emitted, reflected, transmitted or received per unit time, usually measured in Watts, ![W](https://latex.codecogs.com/svg.latex?\inline&space;\textup{W})) per unit surface and solid angle (in ![W.sr-1.m-2](https://latex.codecogs.com/svg.latex?\inline&space;\textup{W}\cdot&space;\textup{sr}^{-1}\cdot&space;\textup{m}^{-2})). The relationship between the signal (![S](https://latex.codecogs.com/svg.latex?\inline&space;S)) resulting from the voltage/current generated by the sensor and the associated electronics (usually quantified as Digital Numbers; ![DN](https://latex.codecogs.com/svg.latex?\inline&space;DN)) and ![L](https://latex.codecogs.com/svg.latex?\inline&space;L) is usually linear, and gain (![G](https://latex.codecogs.com/svg.latex?\inline&space;G)) and offset (![O](https://latex.codecogs.com/svg.latex?\inline&space;O)) factors can be calibrated:

&nbsp; <img src="https://latex.codecogs.com/svg.latex?S=G\cdot&space;L&plus;O%0"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.1)

Measuring radiance can be used to measure temperature because the total amount of energy emitted by an object is is a function of absolute temperature to the fouth power (according to the Stefan-Boltzmann law). The emission is, however, not equal at different wavelengths (even for a perfect emitter, i.e. a black body): according to Wien's displacement law, the wavelength corresponding to the peak of emission also depends on temperature. For instance, the peak emission of the sun is around 500nm (in the visible portion of the spectrum), while that of a body at 25°C is around 10μm (in the far infrared). Since detectors are only sensitive to part of the spectrum, it is necessary to take into account only the spectral radiance (![Llambda](https://latex.codecogs.com/svg.latex?\inline&space;L_{\lambda&space;})) for a given wavelength (according to the Lambert's cosine law and the Planck's law) which is equal to:

&nbsp; <img src="https://latex.codecogs.com/svg.latex?L_{\lambda}=\varepsilon&space;\cdot&space;\frac{2hc^{2}}{\lambda^{5}&space;}&space;\cdot&space;\frac{1}{e^{\frac{hc}{\lambda&space;kT}}-1}"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.2)

where ![epsilon](https://latex.codecogs.com/svg.latex?\inline&space;\varepsilon) is the emissivity of the surface, ![h](https://latex.codecogs.com/svg.latex?\inline&space;h) is the Planck constant, ![k](https://latex.codecogs.com/svg.latex?\inline&space;k) is the Boltzmann constant, ![c](https://latex.codecogs.com/svg.latex?\inline&space;c) is the speed of light in the medium, ![lambda](https://latex.codecogs.com/svg.latex?\inline&space;\lambda) is the wavelength, and ![T](https://latex.codecogs.com/svg.latex?\inline&space;T) is the absolute temperature of that surface (in kelvins). This equation needs to be integrated over the spectral band corresponding to the detector sensitivity (SW, MW, LW, depending on the type of sensor) or, for simplicity, be multiplied by the spectral sensitivity range [[6]]. For a given camera (i.e., combination of electronics, sensors and lenses) this equation can be simplified:

&nbsp; <img src="https://latex.codecogs.com/svg.latex?L_{\lambda}=\varepsilon&space;\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T}}-1)}"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.3)

By combining equations 1 and 3, it is possible to obtain an equation that represents the relationship between ![S](https://latex.codecogs.com/svg.latex?\inline&space;S) and ![T](https://latex.codecogs.com/svg.latex?\inline&space;T) for a given sensor, and can be used for calibration:

&nbsp; <img src="https://latex.codecogs.com/svg.latex?S=G\cdot&space;\varepsilon&space;\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T}}-1)}&plus;O"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.4)

#### Sources of radiation

The radiation received by the camera sensor is not equal to the radiation emitted by the object(s) in its field of view. Depending on the emissivity of the object’s surface, radiation reflected by the object’s surface can contribute significantly to the radiation received by the sensor. Furthermore, this radiation is then attenuated by the atmosphere (mainly by water molecules, but also by carbon dioxide) even at short distances [[7]]. Taking this into account, the signal detected by the sensor (![DN](https://latex.codecogs.com/svg.latex?\inline&space;DN)) can be considered to be composed of three terms:

&nbsp; <img src="https://latex.codecogs.com/svg.latex?S=\tau&space;\cdot&space;S_{obj}&plus;\tau&space;\cdot&space;S_{refl}&plus;S_{atm}"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.5)

The first term is the equivalent digital signal originating from the target object (![Sobj](https://latex.codecogs.com/svg.latex?\inline&space;S_{obj})), attenuated by the atmosphere, which is represented by the atmospheric transmissivity factor tau (![tau](https://latex.codecogs.com/svg.latex?\inline&space;\tau)). The second term is the equivalent digital signal from the reflected radiation originating from the target object’s surroundings (![Srefl](https://latex.codecogs.com/svg.latex?\inline&space;S_{refl})), also attenuated by the atmosphere. The last term is the equivalent digital signal originated from the atmosphere itself in the path between the object and the sensor (![Satm](https://latex.codecogs.com/svg.latex?\inline&space;S_{atm})).

#### Estimation of atmospheric transmissivity

There are many different models available to estimate atmospheric transmissivity. For short distances, simple models that take into account the amount of water in the air can provide adequate estimates. For long distances (e.g. for infrared cameras used in satellites),  more sophisticated models which take into account not only water but also carbon dioxide, ozone, and other moleculas, and other atmospheric factors such as scattering, e.g.: the method by Więcek; the Pasman - Larmore tables, which take into account not only water content, but also carbon dioxide (absortion at λ=4.3µm) concentration in the air, and can be used for different wavelengths [[6]]; more sophisticated models which take into account many different atmospheric factors, which are used for corrections in long distance measurements (e.g. from satellites) such as the LOWTRAN model [[8]].

In this paper, the method used in FLIR Systems’ cameras was adopted [[9]], which estimates atmospheric transmissivity (![tau](https://latex.codecogs.com/svg.latex?\inline&space;\tau)) based on air water content (![H](https://latex.codecogs.com/svg.latex?\inline&space;H), calculated from air temperature, ![t](https://latex.codecogs.com/svg.latex?\inline&space;t), and relative humidity, ![RH](https://latex.codecogs.com/svg.latex?\inline&space;RH)), and the distance between the object and the sensor (![d](https://latex.codecogs.com/svg.latex?\inline&space;d)):

&nbsp; <img src="https://latex.codecogs.com/svg.latex?H=RH\cdot&space;e^{(1.5587\:&space;&plus;\:&space;6.939\cdot&space;10^{-2}\cdot&space;t\:&space;-\:&space;2.7816\cdot&space;10^{-4}\cdot&space;t^{2}\:&space;&plus;\:&space;6.8455\cdot&space;10^{-7}\cdot&space;t^{3})}"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.6)

&nbsp; <img src="https://latex.codecogs.com/svg.latex?\tau&space;=X\cdot&space;e^{[-\sqrt{d}\cdot&space;(\alpha&space;_{1}&plus;\beta&space;_{1}\cdot&space;\sqrt{H})]}&plus;(1-X)\cdot&space;e^{[-\sqrt{d}\cdot&space;(\alpha&space;_{2}&plus;\beta&space;_{2}\cdot&space;\sqrt{H})]}"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.7)

#### Estimation of digital signal values for different radiation sources

Assuming all temperatures and emissivities are know, the digital signal values originated from the different radiation sources can be estimated using equation 4. For the target object, the digital signal (![Sobj](https://latex.codecogs.com/svg.latex?\inline&space;S_{obj})) can be calculated based on the object temperature (![Tobj](https://latex.codecogs.com/svg.latex?\inline&space;T_{obj})) and its emissivity (![epsilon](https://latex.codecogs.com/svg.latex?\inline&space;\varepsilon)):

&nbsp; <img src="https://latex.codecogs.com/svg.latex?S_{obj}=G\cdot&space;\varepsilon&space;\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T_{obj}}}-1)}&plus;O"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.8)

The digital signal originated from the atmosphere between the object and the sensor (![Satm](https://latex.codecogs.com/svg.latex?\inline&space;S_{atm})) can be calculated based on air temperature (![Tatm](https://latex.codecogs.com/svg.latex?\inline&space;T_{atm})) and its emissivity, which is equal to ![1-tau](https://latex.codecogs.com/svg.latex?\inline&space;1-\tau):

&nbsp; <img src="https://latex.codecogs.com/svg.latex?S_{atm}=G\cdot&space;(1-\tau)&space;\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T_{atm}}}-1)}&plus;O"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.9)

For estimating the digital signal from reflected by the target object (![Srefl](https://latex.codecogs.com/svg.latex?\inline&space;S_{refl})), one must take into account the reflectivity of the object, which is equal to ![1-epsilon](https://latex.codecogs.com/svg.latex?\inline&space;1-\varepsilon). Also, it should be necessary to know the temperature of the surrounding objects (![Trefl](https://latex.codecogs.com/svg.latex?\inline&space;T_{refl})) and their emissivity (![epsilonrefl](https://latex.codecogs.com/svg.latex?\inline&space;\varepsilon&space;_{refl})):

&nbsp; <img src="https://latex.codecogs.com/svg.latex?S_{atm}=G\cdot&space;(1-\varepsilon&space;)\cdot&space;(\varepsilon&space;_{refl})&space;\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T_{refl}}}-1)}&plus;O"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.10)

Since in most cases it would be difficult to determine the temperature and emissivity of the reflected objects, the usual procedure is to estimate an “aparent reflected temperature” (![Tapp.refl](https://latex.codecogs.com/svg.latex?\inline&space;T_{app.refl})), by measuring the apparent temperature of a reflective material (![epsilonequalzero](https://latex.codecogs.com/svg.latex?\inline&space;\varepsilon\approx&space;0)). Using this procedure, Eq. 10 would be replaced by:

&nbsp; <img src="https://latex.codecogs.com/svg.latex?S_{atm}=G\cdot&space;(1-\varepsilon&space;)\cdot&space;\frac{1}{R\cdot&space;(e^{\frac{B}{T_{app.refl}}}-1)}&plus;O"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.11)

#### Object temperature calculation

Finally, in order to calculate object temperature:

&nbsp; <img src="https://latex.codecogs.com/svg.latex?S_{obj}=\frac{S_{tot}}{\tau&space;}-S_{refl}-\frac{S_{atm}}{\tau&space;}"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.12)

&nbsp; <img src="https://latex.codecogs.com/svg.latex?T_{obj}=\frac{B}{\textup{log}(\frac{G\cdot&space;\varepsilon&space;}{R\cdot&space;(S_{obj}-O)}&plus;1)}"> &nbsp; &nbsp; &nbsp; &nbsp; (Eq.13)

---

### Implementation

The image processing steps are implemented as a macro for the [ImageJ] software [[1]], thus allowing simple modification and adaptation to other scientific image processing pipelines.  The method relies on having access to the raw sensor data obtained from the camera. In the case of FLIR cameras, this data is stored in the EXIF data in the “radiometric jpg” files, together with the camera-specific and user-set parameters needed to calculate temperature. This data can be extracted through the use of the [ExifTool] software [[3]].

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
Sensor gain | sensorG | ![G](https://latex.codecogs.com/svg.latex?\inline&space;G) | 1 | Planck R1
Sensor offset | sensorO | ![O](https://latex.codecogs.com/svg.latex?\inline&space;O) | 1 | Planck O
Sensor calibration parameter B | sensorB | ![B](https://latex.codecogs.com/svg.latex?\inline&space;B) | 4 | Planck B
Sensor calibration parameter F * | sensorF |  |  | Planck F
Sensor calibration parameter R | sensorR | ![R](https://latex.codecogs.com/svg.latex?\inline&space;R) | 4 | Planck R2
_Atmospheric parameters_ |
Atmospheric transmissivity parameter 1 | atmAlpha1 | ![alpha1](https://latex.codecogs.com/svg.latex?\inline&space;\alpha_{1}) | 7 | Atmospheric Trans Alpha 1
Atmospheric transmissivity parameter 2 | atmAlpha2 | ![alpha2](https://latex.codecogs.com/svg.latex?\inline&space;\alpha_{2}) | 7 | Atmospheric Trans Alpha 2
Atmospheric transmissivity parameter 1 | atmBeta1 | ![beta1](https://latex.codecogs.com/svg.latex?\inline&space;\beta_{1}) | 7 | Atmospheric Trans Beta 1
Atmospheric transmissivity parameter 2 | atmBeta2 | ![beta2](https://latex.codecogs.com/svg.latex?\inline&space;\beta_{2}) | 7 | Atmospheric Trans Beta 2
Atmospheric transmissivity parameter X | atmX | ![X](https://latex.codecogs.com/svg.latex?\inline&space;X) | 7 | Atmospheric Trans X
User-selected parameters |  |  |  |
Apparent reflected temperature (°C) | appReflTemp_C |  |  | Reflected Apparent Temperature
Air temperature (°C) | airTemp_C | ![t](https://latex.codecogs.com/svg.latex?\inline&space;t) | 6 | Atmospheric Temperature
Object emissivity | objEmissivity | ![epsilon](https://latex.codecogs.com/svg.latex?\inline&space;\varepsilon) | 4 | Emissivity
Air relative humidity | airRelHumidity_perc | ![RH](https://latex.codecogs.com/svg.latex?\inline&space;RH) | 6 | Relative Humidity
Object distance from camera | objDistance_m | ![d](https://latex.codecogs.com/svg.latex?\inline&space;d) | 7 | Object Distance

_* This parameter is included in the JPG EXIF tags but it is always equal to 1, and is equivalent to the value of 1 in the term ![eBT-1](https://latex.codecogs.com/svg.latex?\inline&space;(e^{\frac{B}{T}}-1)) in Eq. 4_

#### Calculation of derived variables

The next step is the calculation of variables derived from these parameters, including the calculation of atmospheric transmissivity (using Eq. 6-7) and the estimated digital signal from reflected objects and the atmosphere (using Eq. 9-11). Both the extraction of parameters and the calculation of these variables are either performed for each file or only for the first file in the folder, depending on the option selected by the user.

Parameter / variable | Variable name in macro | Symbol used in equations | Eq.
--- | --- | --- | ---
Raw image byte order / endianness | byteOrderLittleEndian |  |
Aparent reflected temperature (K) | appReflTemp_K | ![Tapp.refl](https://latex.codecogs.com/svg.latex?\inline&space;T_{app.refl}) | 11
Air temperature (K) | airTemp_K | ![Tatm](https://latex.codecogs.com/svg.latex?\inline&space;T_{atm}) | 9
Air water content | airWaterContent | ![H](https://latex.codecogs.com/svg.latex?\inline&space;H) | 7
Atmospheric transmissivity | atmTau | ![tau](https://latex.codecogs.com/svg.latex?\inline&space;\tau) | 5
Raw signal from atmosphere (DN) | atmRawSignal_DN | ![Satm](https://latex.codecogs.com/svg.latex?\inline&space;S_{atm}) | 5
Raw signal from reflected radiation (DN) | reflRawSignal_DN | ![Srefl](https://latex.codecogs.com/svg.latex?\inline&space;S_{refl}) | 5

#### Temperature calculation

First, using the exiftool software, raw data is extracted in PNG format. The resulting image containing the raw sensor data is then opened within the ImageJ software, and each pixel containing the digital signal from the sensor is processed sequencially. First, the object signal is estimated using Eq. 12, and then the temperature value is calculated using Eq. 13.

Parameter / Variable | Variable name in macro | Symbol used in equations | Eq. | EXIF tag name in FLIR JPG file
--- | --- | --- | --- | ---
Raw sensor signal (DN) * | rawSignal_DN | ![S](https://latex.codecogs.com/svg.latex?\inline&space;S) | 1 | Raw Thermal Image
Raw signal from object (DN) | objRawSignal_DN | ![Sobj](https://latex.codecogs.com/svg.latex?\inline&space;S_{obj}) | 5 |
Object temperature (°C) | objTemp_C | ![Tobj](https://latex.codecogs.com/svg.latex?\inline&space;T_{obj}) | 8 |

_* All raw sensor signal values are extracted as a PNG format image, then each pixel is processed sequencially, storing each value in the rawSignal_DN variable._

#### Outputs

The resulting image with temperature values for each pixel is stored in a separate file in TIFF format, under the same filename with a 'TEMP' suffix and a .TIF extension. The temperature values are also exported as comma-separated text values, with a 'TEXT' suffix and a .TXT extension. Finally, the image is converted to a false-color RGB image and stored in PNG format, with a 'COLOR' suffix and a .PNG extension.

### Evaluation

The macro was evaluated by comparing the resulting temperature values with those exported manually using the [FLIR Tools] software (FLIR Systems, Inc., USA, [version 5.13.18031.2002])

26 images taken with 15 different FLIR camera models were downloaded from [Wikimedia Commons] (all those available as unmodified jpg files on 16 Jun 2019 from https://commons.wikimedia.org/wiki/Category:Photos_taken_with_FLIR_Systems. All the images were processed using ``IRimage``, and also the temperature values were manually exported for each file using FLIR Tools.

A [test macro](https://github.com/gpereyrairujo/IRimage/blob/master/IRimage/IRimage_test.ijm) was used to automatically compare the results for each image. Temperature values obtained with ``IRimage`` were in all cases within 0.01°C of those obtained with FLIR Tools, with an average difference of 0.0002°C.

The only exception in which temperature values differed significantly was when calculated values were lower than -40°C. In those cases, temperature values exported using FLIR Tools were always equal to -40°C, irrespective of the initial raw values, whereas ``IRimage`` showed values that could reach -70°C. This is clearly shown in some of the scatter plots shown in the following table.

Img # | Original image | Processed image | Temperature correlation FLIR Tools vs IRimage
--- | --- | --- | ---
1 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/200_deg_neutral.jpg" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/200_deg_neutral.jpg_COLOR.png" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/200_deg_neutral_PLOT.png" width="160">
2 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/20080128191209!IRWaterCooler.jpg" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/20080128191209!IRWaterCooler.jpg_COLOR.png" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/20080128191209!IRWaterCooler_PLOT.png" width="160">
3 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/20120726211114!Thermal_image_of_four_ducks_swimming.jpg" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/20120726211114!Thermal_image_of_four_ducks_swimming.jpg_COLOR.png" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/20120726211114!Thermal_image_of_four_ducks_swimming_PLOT.png" width="160">
4 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/AFCIs_Infrared.jpg" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/AFCIs_Infrared.jpg_COLOR.png" width="160">| *
5 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Aqua_Tower_thermal_image.jpg" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Aqua_Tower_thermal_image.jpg_COLOR.png" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Aqua_Tower_thermal_image_PLOT.png" width="160">
6 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Aqua_Tower_thermal_imaging.jpg" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Aqua_Tower_thermal_imaging.jpg_COLOR.png" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Aqua_Tower_thermal_imaging_PLOT.png" width="160">
7 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/BillHotFlashThermography.jpg" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/BillHotFlashThermography.jpg_COLOR.png" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/BillHotFlashThermography_PLOT.png" width="160">
8 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Image_thermique_de_l'émission_d'un_radiateur_à_travers_un_mur.jpg" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Image_thermique_de_l'émission_d'un_radiateur_à_travers_un_mur.jpg_COLOR.png" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Image_thermique_de_l'émission_d'un_radiateur_à_travers_un_mur_PLOT.png" width="160">
9 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Infrared_image_of_people_in_the_laboratory.jpg" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Infrared_image_of_people_in_the_laboratory.jpg_COLOR.png" width="160">| <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Infrared_image_of_people_in_the_laboratory_PLOT.png" width="160">
10 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/IR_Fussbodenheizung.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/IR_Fussbodenheizung.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/IR_Fussbodenheizung_PLOT.png" width="160">
11 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/IR_moving_car.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/IR_moving_car.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/IR_moving_car_PLOT.png" width="160">
12 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/IR_moving_mercedes.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/IR_moving_mercedes.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/IR_moving_mercedes_PLOT.png" width="160">
13 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/IRWater.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/IRWater.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/IRWater_PLOT.png" width="160">
14 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Kujawy_wiatrak.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Kujawy_wiatrak.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Kujawy_wiatrak_PLOT.png" width="160">
15 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Linear_load.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Linear_load.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Linear_load_PLOT.png" width="160">
16 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Man_in_water_-_IR_image.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Man_in_water_-_IR_image.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Man_in_water_-_IR_image_PLOT.png" width="160">
17 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Solar_halo_thermal.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Solar_halo_thermal.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Solar_halo_thermal_PLOT.png" width="160">
18 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Steam_Train_Valves_Thermal_Image.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Steam_Train_Valves_Thermal_Image.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Steam_Train_Valves_Thermal_Image_PLOT.png" width="160">
19 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Termografía.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Termografía.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Termografía_PLOT.png" width="160">
20 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Thermal_image_of_a_group_of_grey-headed_flying_foxes_during_an_extreme_temperature_event.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Thermal_image_of_a_group_of_grey-headed_flying_foxes_during_an_extreme_temperature_event.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Thermal_image_of_a_group_of_grey-headed_flying_foxes_during_an_extreme_temperature_event_PLOT.png" width="160">
21 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Thermal_image_of_a_juvenile_grey-headed_flying_fox_during_an_extreme_temperature_event.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Thermal_image_of_a_juvenile_grey-headed_flying_fox_during_an_extreme_temperature_event.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Thermal_image_of_a_juvenile_grey-headed_flying_fox_during_an_extreme_temperature_event_PLOT.png" width="160">
22 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Thermogramme_infiltrométrie.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Thermogramme_infiltrométrie.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Thermogramme_infiltrométrie_PLOT.png" width="160">
23 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Thermographie_de_rue.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Thermographie_de_rue.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Thermographie_de_rue_PLOT.png" width="160">
24 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Thermographie_photovoltaique.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Thermographie_photovoltaique.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Thermographie_photovoltaique_PLOT.png" width="160">
25 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Videocamera_Termica.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Videocamera_Termica.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Videocamera_Termica_PLOT.png" width="160">
26 | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/Windmill_Thermal_Image.jpg" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_results/Windmill_Thermal_Image.jpg_COLOR.png" width="160"> | <img src="https://github.com/gpereyrairujo/IRimage/blob/master/documentation/example_images/example_images_test/Windmill_Thermal_Image_PLOT.png" width="160">

_*unmodified raw data could not be obtained with FLIR Tools_

---

### References

[ImageJ]: https://imagej.nih.gov/ij/index.html
[FIJI]: https://imagej.net/Fiji
[ExifTool]: http://owl.phy.queensu.ca/~phil/exiftool/
[1]: https://doi.org/10.1186/s12859-017-1934-z
[2]: https://doi.org/10.1038/nmeth.2019
[3]: http://owl.phy.queensu.ca/~phil/exiftool/
[4]: https://www.plant-phenotyping.org/lw_resource/datapool/_items/item_321/book_of_abstracts_web.pdf
[5]: http://intrabalc.inta.gob.ar/dbtw-wpd/images/Cacciabue-G-N.pdf
[6]: https://doi.org/10.1007/978-94-011-0711-2
[7]: https://doi.org/10.5194/jsss-5-17-2016
[8]: https://doi.org/10.1016/j.infrared.2016.06.025
[9]: http://support.flir.com/DocDownload/Assets/dl/557344$b.pdf
[ExifTool Forum]: http://u88.n24.queensu.ca/exiftool/forum/index.php/topic,4898.0.html
[FLIR Tools]: https://www.flir.com/products/flir-tools/
[version 5.13.18031.2002]: https://support.flir.com/SwDownload/app/RssSWDownload.aspx?ID=120
[Wikimedia Commons]: https://commons.wikimedia.org/

[[1]] Rueden, C. T.; Schindelin, J. & Hiner, M. C. et al. (2017). ImageJ2: ImageJ for the next generation of scientific image data. BMC Bioinformatics 18:529, PMID 29187165, https://doi.org/10.1186/s12859-017-1934-z

[[2]] Schindelin, J.; Arganda-Carreras, I. & Frise, E. et al. (2012). Fiji: an open-source platform for biological-image analysis. Nature methods 9(7): 676-682, PMID 22743772, https://doi.org/10.1038/nmeth.2019

[[3]] Harvey, P. (2003). ExifTool. Software package available at http://owl.phy.queensu.ca/~phil/exiftool/

[[4]] Pereyra Irujo, G; Aguirrezábal, L.; Fiorani, F.; Pieruschka, R. (2015). Benchmarking of an affordable thermal camera for plant phenotyping. EPPN Plant Phenotyping Symposium, Barcelona, Spain. Book of Abstracts, p. 31. Available at https://www.plant-phenotyping.org/lw_resource/datapool/_items/item_321/book_of_abstracts_web.pdf

[[5]] Cacciabue, G.N. (2016). Protocolos de medición de temperatura de canopeo y su relación con el rendimiento potencial de cultivares de trigo. Trabajo de Graduación. Ing.Agr. Universidad Nacional de Mar del Plata; Facultad de Ciencias Agrarias: Balcarce, Buenos Aires, AR. 2016 . 42p. Available at http://intrabalc.inta.gob.ar/dbtw-wpd/images/Cacciabue-G-N.pdf

[[6]] Gaussorgues, G. (1994). Infrared thermography. Microwave technology series. Springer. https://doi.org/10.1007/978-94-011-0711-2

[[7]] Minkina, W. and Klecha, D. (2016). Atmospheric transmission coefficient modelling in the infrared for thermovision measurements, J. Sens. Sens. Syst., 5, 17-23, https://doi.org/10.5194/jsss-5-17-2016

[[8]] Zhang, Y. C., Chen, Y. M., Fu, X. B., & Luo, C. (2016). The research on the effect of atmospheric transmittance for the measuring accuracy of infrared thermal imager. Infrared Physics & Technology, 77, 375-381. https://doi.org/10.1016/j.infrared.2016.06.025

[[9]] FLIR Systems. Toolkit IC2 Dig16 Developer’s Guide 1.01 AGEMA® 550/570, ThermaCAM™ PM5X5 and the ThermoVision™family (en‑US). FLIR Publication number 557344 version B. Available online at http://flir.custhelp.com/app/account/fl_download_manuals (http://support.flir.com/DocDownload/Assets/dl/557344$b.pdf)

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

### How to cite

If this macro contributes to a project or publication, please acknowledge this by citing as:

```
Pereyra Irujo, G. (2019). IRimage. Open source software for processing images from consumer thermal cameras. Available at: https://github.com/gpereyrairujo/IRimage/
```
