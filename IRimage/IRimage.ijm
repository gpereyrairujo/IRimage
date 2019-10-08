/////////////////////////////////////////////////////////////////////////////////////////////////////////
// IRimage
// ImageJ macro for converting raw thermal png files from FLIR cameras to temperature values in degrees C
// Author: Gustavo Pereyra Irujo - pereyrairujo.gustavo@conicet.gov.ar
// Licensed under GNU GENERAL PUBLIC LICENSE Version 3
// https://github.com/gpereyrairujo/IRimage

macro "IRimage Action Tool - C209T0809IT3809RCb03T1f06iT3f06mT8f06aTbf06gTff06e" {

// ---------------------------------------------------------------------------------------------------------
// 1. User input
//    1.1. Ask for the directory of files to process
//    1.2. Ask for parameter options
// 2. File processing
//    2.1. Find JPG files
//    2.2. Extract parameters
//    2.3. Ask for user confirmation of parameters
//    2.4. Calculate derived variables
//    2.5. Extract raw data to a PNG image
//    2.6. Extract raw signal data from PNG image
//    2.7. Calculate temperature values for each pixel
// 3. Outputs
//    3.1. Print image statistics to the Results window
//    3.2. Save file as TIFF
//    3.3. Save file as text table
//    3.4. Save file as false-color PNG
// 4. Close image
// ---------------------------------------------------------------------------------------------------------

// 1. User input
// 1.1. Ask for the directory of files to process
	dir = getDirectory("Choose a Directory");

// 1.2. Ask for parameter options
	Dialog.create("Parameter options");
		options = newArray("Set global parameters for all images", "Use parameters stored in each file");
		Dialog.addRadioButtonGroup("", options, 2, 1, options[0]);
		Dialog.show();
	globalparameters = (Dialog.getRadioButton()==options[0]);


// 2. File processing
	setBatchMode(true);
    list = getFileList(dir);
    firstfile=true;
    for (i=0; i<list.length; i++) {

// 2.1. Find JPG files
		isjpg=false;
		do {
			imageName=list[i];
			if( endsWith(imageName,"jpg") ) isjpg=true;
			if( endsWith(imageName,"jpeg") ) isjpg=true;
			if( endsWith(imageName,"JPG") ) isjpg=true;
			if( endsWith(imageName,"JPEG") ) isjpg=true;
			if(isjpg==false) i++;
			if(i>=list.length) exit;
		} while (isjpg==false); 
		path = dir+imageName;
		showProgress(i, list.length);

// 2.2. Extract parameters
		if((globalparameters==false)|(firstfile==true)) extract=true; else extract=false;
		if(globalparameters & firstfile) userdialog=true; else userdialog=false;
		firstfile=false;
		
		if(extract==true) {
			parameters = exec("exiftool", "-Planck*", "-Atmospheric*", "-Reflected*", "-Emissivity*",  "-Relative*", "-Object*", "-RawThermalImageType", "-CameraModel", path);
			rows=split(parameters, "\n"); 
			param=newArray(rows.length); 
			value=newArray(rows.length);
			for(j=0; j<rows.length; j++){ 
				columns=split(rows[j],":"); 
				param[j]=columns[0]; 
				value[j]=parseFloat(columns[1]);
				}
			
			columns=split(rows[rows.length-2],":"); 	// extract raw thermal image type
			imageType=substring(columns[1],1);
			if(imageType=="TIFF") byteOrderLittleEndian=false;   // when raw data is stored in PNG format, byte order is usually "little-endian" - correct if this is not the case
			if(imageType=="PNG") byteOrderLittleEndian=true;
			
			columns=split(rows[rows.length-1],":"); 	// extract camera model
			cameraModel=substring(columns[1],1);

			if(cameraModel=="ThermaCAM EX320") byteOrderLittleEndian=false;   // known exception to the TIFF/PNG rule
			if(cameraModel=="P20 NTSC") byteOrderLittleEndian=false;   // known exception to the TIFF/PNG rule
			if(cameraModel=="S65 NTSC") byteOrderLittleEndian=false;   // known exception to the TIFF/PNG rule

			sensorG = value[0];
			sensorB = value[1];
			sensorF = value[2];
			sensorO = value[3];
			sensorR = value[4];
			atmAlpha1 = value[6];
			atmAlpha2 = value[7];
			atmBeta1 = value[8];
			atmBeta2 = value[9];
			atmX = value[10];
			appReflTemp_C = value[11];
			objEmissivity = value[12];
			airTemp_C = value[5];
			airRelHumidity_perc = value[13];
			objDistance_m = value[14];
		}

// 2.3. Ask for user confirmation of parameters
		if(userdialog==true) {
			Dialog.create("Parameters");
				Dialog.addMessage("Camera model: "+cameraModel);
				Dialog.addMessage("Calibration / camera-specific parameters");
				Dialog.addNumber("Sensor Gain", sensorG, 3, 12,"");
				Dialog.addNumber("Sensor parameter B", sensorB,1,12,"");
				Dialog.addNumber("Sensor parameter F", sensorF,1,12,"");
				Dialog.addNumber("Sensor Offset", sensorO,1,12,"");
				Dialog.addNumber("Sensor parameter R", sensorR,9,12,"");
				Dialog.addCheckbox("Little-endian byte order", byteOrderLittleEndian);
				Dialog.addMessage("Atmospheric transmission parameters");
				Dialog.addNumber("Alpha 1", atmAlpha1,6,12,"");
				Dialog.addNumber("Alpha 2", atmAlpha2,6,12,"");
				Dialog.addNumber("Beta 1", atmBeta1,6,12,"");
				Dialog.addNumber("Beta 2", atmBeta2,6,12,"");
				Dialog.addNumber("X", atmX,6,12,"");
				Dialog.addMessage("User-set parameters");
				Dialog.addNumber("Reflected Temperature (°C)", appReflTemp_C,1,5,"C");
				Dialog.addNumber("Object Emissivity", objEmissivity,2,5,"");
				Dialog.addNumber("Air Temperature (°C)", airTemp_C,1,5,"C");
				Dialog.addNumber("Air Relative Humidity (%)", airRelHumidity_perc,0,5,"");
				Dialog.addNumber("Object Distance (m)", objDistance_m,0,5,"m");
				Dialog.show();

			sensorG=Dialog.getNumber();
			sensorB=Dialog.getNumber();
			sensorF=Dialog.getNumber();
			sensorO=Dialog.getNumber();
			sensorR=Dialog.getNumber();
			byteOrderLittleEndian=Dialog.getCheckbox();
			atmAlpha1=Dialog.getNumber();
			atmAlpha2=Dialog.getNumber();
			atmBeta1=Dialog.getNumber();
			atmBeta2=Dialog.getNumber();
			atmX=Dialog.getNumber();
			appReflTemp_C=Dialog.getNumber();
			objEmissivity=Dialog.getNumber();
			airTemp_C=Dialog.getNumber();
			airRelHumidity_perc=Dialog.getNumber();
			objDistance_m=Dialog.getNumber();
		}		
		
// 2.4. Calculate derived variables
		if(extract==true) {
			appReflTemp_K = appReflTemp_C+273.15;
			airTemp_K = airTemp_C+273.15;
			airWaterContent = airRelHumidity_perc /100 * exp(1.5587 + 0.06939 * airTemp_C - 0.00027816 * pow(airTemp_C,2) + 0.00000068455 *pow(airTemp_C,3));
			atmTau = atmX * exp(-pow(objDistance_m,0.5) * (atmAlpha1 + atmBeta1 * pow(airWaterContent,0.5))) + (1-atmX) * exp(-pow(objDistance_m,0.5) * (atmAlpha2 + atmBeta2 * pow(airWaterContent,0.5)));
			atmRawSignal_DN = sensorG/(sensorR*(exp(sensorB/(airTemp_K))-sensorF))-sensorO;
			reflRawSignal_DN = sensorG/(sensorR*(exp(sensorB/(appReflTemp_K))-sensorF))-sensorO;
		}

// 2.5. Extract raw data to a PNG image
		pathRAW = substring(path, 0, lastIndexOf(path, "."));
		pathRAW = pathRAW+"_RAW.PNG";
		output = exec("exiftool", path, "-RawThermalImage", "-b", "-w", "%d%f_RAW.PNG");

// 2.6. Extract raw signal data from PNG image
        IJ.redirectErrorMessages();
        open(pathRAW);
        if (nImages>0) {
			run("32-bit");
			w = getWidth;
			h = getHeight;
			for (y=0; y<h; y++) {
				for (x=0; x<w; x++) {
					rawSignal_DN = getPixel(x,y);

// 2.7. Calculate temperature values for each pixel
					if (byteOrderLittleEndian==true) rawSignal_DN=(rawSignal_DN-(rawSignal_DN%256))/256+(rawSignal_DN%256)*256;
					objRawSignal_DN=(rawSignal_DN-atmRawSignal_DN*(1-atmTau)-reflRawSignal_DN*(1-objEmissivity)*atmTau)/objEmissivity/atmTau;
					objTemp_C=sensorB/log(sensorG/(sensorR*(objRawSignal_DN+sensorO))+sensorF)-273.15;
					setPixel(x,y,objTemp_C);
					}
				}
			resetMinAndMax;
		}

// 3. Outputs
// 3.1. Print image statistics to the Results window
		getStatistics(area, mean, min, max, std);
		setResult("Image", nResults, imageName);
		setResult("Area", nResults-1, area);
		setResult("Mean", nResults-1, mean);
		setResult("Min", nResults-1, min);
		setResult("Max", nResults-1, max);
		setResult("StDev", nResults-1, std);
		setResult("CamModel", nResults-1, cameraModel);

// 3.2. Save file as TIFF
		saveAs("tiff", path+"_TEMP");

// 3.3. Save file as text table
		saveAs("Text Image", path+"_TEXT");

// 3.4. Save file as false-color PNG
		run("Fire");
		saveAs("png", path+"_COLOR");

// 4. Close image
		run("Close");
	}
	
}

