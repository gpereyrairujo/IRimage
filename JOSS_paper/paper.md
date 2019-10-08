---
title: 'IRimage: Open source software for processing images from consumer thermal cameras'
tags:
  - ImageJ
  - Image analysis
  - Thermal imaging
  - Infrared imaging
authors:
  - name: Gustavo Pereyra Irujo
    orcid: 0000-0002-2261-6928
    affiliation: 1, 2
affiliations:
 - name: Instituto Nacional de Tecnología Agropecuaria (INTA)
   index: 1
 - name: Consejo Nacional de Investigaciones Científicas y Técnicas (CONICET)
   index: 2
date: 8 October 2019
bibliography: paper.bib
---

# Summary

Thermal imaging has many uses in scientific research. In recent years, thermal cameras have lowered their price, and affordable consumer cameras are now available. These cameras, available as stand-alone devices or smartphone attachments, have the potential to improve access to thermography in many fields of research. These cameras, however, are usually coupled to limited software, aimed at an non-scientific users. This software is usually limited to providing color-coded images and simple temperature measurements of manually-selected points or areas in the image. In many cases, the images are a result of blending visible and thermal images for improved resolution, which limits the extraction of temperature data from them. Moreover, software is usually closed-source, which does not allow the user to know the algorithms used to obtain the temperature measurements and the final image. For a thermal camera (or any sensor) to be useful for research, the user should be able to have control over (or at least information about) the processing steps between the raw sensor data and the final measurement.

``IRimage`` allows researchers to extract raw data and calculate temperature values from images of thermal cameras, making this data available for further processing using widely used scientific image analysis software. This tool was implemented as a macro for the open source software ImageJ [@Rueden:2017] or FIJI [@Schindelin:2012], and is based on the open source software ExifTool [@Harvey:2003] to extract raw values from the thermal images for further calculations. It was implemented and tested using FLIR cameras, but the algorithms are potentially adaptable for other cameras for which raw sensor data could be obtained. Earlier versions of this tool were used to benchmark a low cost thermal camera [@PereyraIrujo:2015] and to analyze thermal images of wheat varieties [@Cacciabue:2016]. It has been tested with images from more than 15 camera models, and calculated temperatures were in all cases within 0.01°C (0.0002°C on average) of those obtained with the manufacturer’s software.

``IRimage`` follows four steps when processing the images: 1. user input, 2. extraction of camera calibration and environmental parameters from input files and calculation of derived variables, 3. calculation of temperature from raw values, 4. storage of the resulting images. The algorithm used for temperature calculation is detailed in this documentation.

``IRimage`` is published with an open source license, in order to encourage future improvement, modification and adaptation.

# References
