////////////////////////////////////////////////////////////////////////////////////////////////////////
// IR-image
//
// ImageJ code for processing thermal images from FLIR cameras
// - Converts radiometric JPG files to temperature values in degrees C
// - Generates false color images from previously converted thermal images
// - Compares temperature values from thermal images exported with FLIR Tools or exported with IRimage
//
// Author: Gustavo Pereyra Irujo - pereyrairujo.gustavo@conicet.gov.ar
// Licensed under GNU AFFERO GENERAL PUBLIC LICENSE Version 3
// https://github.com/gpereyrairujo/IRimage
//


////////////////////////////////////////////////////////////////////////////////////////////////////////
// Function for converting radiometric JPG files to temperature values in degrees C
// -----------------------------------------------------------------------------------------------------
// 1. User input
//    1.1. Ask for the directory of files to process
//    1.2. Ask for parameter options
//    1.3. Create output folders
//    1.4. Open CSV file with user parameters
// 2. File processing
//    2.1. Find JPG files
//    2.2. Extract parameters
//    2.3. Ask for user confirmation of parameters
//    2.4. Get parameters from CSV input file
//    2.5. Calculate derived variables
//    2.6. Extract raw data to a PNG image
//    2.7. Extract raw signal data from PNG image
//    2.8. Calculate temperature values for each pixel
// 3. Outputs
//    3.1. Print image data, temperature statistics and parameter values to the Results window
//    3.2. Save file as TIFF
//    3.3. Save file as text table
//    3.4. Save file as false-color PNG
//    3.5. Save results table
// 4. Close image
// -----------------------------------------------------------------------------------------------------


macro "IR-image-process" {

// 1. User input
// 1.1. Ask for the directory of files to process
	dir = getDirectory("Select the thermal images folder");


// 1.2. Ask for parameter options
	Dialog.create("Parameter options");
		Dialog.addMessage("Parameter options", 15);
		options = newArray("Use parameters stored in each image", "Set global parameters for all images", "Use parameters from file");
		Dialog.addRadioButtonGroup("", options, 3, 1, options[0]);
		Dialog.show();
	selection = Dialog.getRadioButton();
	parametersFromImage = (selection==options[0]);
	globalParameters = (selection==options[1]);
	parametersFromFile = (selection==options[2]);


// 1.3. Create output folders
	dirRAW_PNG = dir+"raw"+File.separator;
	dirTEXT = dir+"text"+File.separator;
	dirCOLOR = dir+"color"+File.separator;
	dirTEMP = dir+"temp"+File.separator;
	dirRESULTS = dir+"results"+File.separator;
	dirIRimage = getDir("plugins") + "IRimage" + File.separator;
	dirExifTool = dirIRimage + "exiftool" + File.separator;
	dirPalette = dirIRimage + "palette" + File.separator;
	if (!File.exists(dirRAW_PNG)) File.makeDirectory(dirRAW_PNG); 
	if (!File.exists(dirTEXT)) File.makeDirectory(dirTEXT); 
	if (!File.exists(dirCOLOR)) File.makeDirectory(dirCOLOR); 
	if (!File.exists(dirTEMP)) File.makeDirectory(dirTEMP); 
	if (!File.exists(dirRESULTS)) File.makeDirectory(dirRESULTS); 


// 1.4. Open CSV file with user parameters
	if(parametersFromFile==true) {
		File.setDefaultDir(dirRESULTS);
		pathPARAMETERS = File.openDialog("Select a CSV file with parameter values");
		parametersFileString = File.openAsString(pathPARAMETERS);
		parametersFileRows=split(parametersFileString, "\n");
		parametersFileHeaders=split(parametersFileRows[0],",;");
		for(i=0; i<parametersFileHeaders.length; i++){
			header=parametersFileHeaders[i];
			if(header=="Image") imageColumn=i;
			if(header=="Obj_emissivity") objEmissivityColumn=i;
			if(header=="Obj_distance") objDistanceColumn=i;
			if(header=="Air_temp") airTempColumn=i;
			if(header=="Air_rel_hum") objRelHumidityColumn=i;
			if(header=="App_refl_temp") appReflTempColumn=i;
		}		
		File.setDefaultDir(dir);
	}


// 2. File processing
	setBatchMode(true);
    list = getFileList(dir);
    firstfile=true;
    for (i=0; i<list.length; i++) {


// 2.1. Find JPG files
		isjpg=false;
		do {
			imageNameExt=list[i];
			if( endsWith(imageNameExt,"jpg") ) isjpg=true;
			if( endsWith(imageNameExt,"jpeg") ) isjpg=true;
			if( endsWith(imageNameExt,"JPG") ) isjpg=true;
			if( endsWith(imageNameExt,"JPEG") ) isjpg=true;
			if(isjpg==false) i++;
			if(i>=list.length) exit;
		} while (isjpg==false); 
		imageName = substring(imageNameExt, 0, lastIndexOf(imageNameExt, "."));
		path = dir+imageNameExt;
		showProgress(i, list.length);


// 2.2. Extract parameters
		if((globalParameters==false)|(firstfile==true)) extract=true; else extract=false;
		if(globalParameters & firstfile) userdialog=true; else userdialog=false;
		
		if(extract==true) {
			parameters = exec(dirExifTool+"exiftool", "-Planck*", "-Atmospheric*", "-Reflected*", "-Emissivity*",  "-Relative*", "-Object*", "-RawThermalImageType", "-CameraModel", "-DateTimeOriginal", path);
			rows=split(parameters, "\n"); 

			// parse numerical values
			n_params = 15;
			param=newArray(n_params); 
			value=newArray(n_params);
			for(j=0; j<n_params; j++){ 
				columns=split(rows[j],":"); 
				param[j]=columns[0]; 
				value[j]=parseFloat(columns[1]);
				}
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

			// parse text values
			columns=split(rows[15],":"); 	// extract raw thermal image type
			imageType=substring(columns[1],1);
			if(imageType=="TIFF") byteOrderLittleEndian=false;   // when raw data is stored in PNG format, byte order is usually "little-endian" - correct if this is not the case
			if(imageType=="PNG") byteOrderLittleEndian=true;
			
			columns=split(rows[16],":"); 	// extract camera model
			cameraModel=substring(columns[1],1);

			if(cameraModel=="ThermaCAM EX320") byteOrderLittleEndian=false;   // known exception to the TIFF/PNG rule
			if(cameraModel=="P20 NTSC") byteOrderLittleEndian=false;   // known exception to the TIFF/PNG rule
			if(cameraModel=="S65 NTSC") byteOrderLittleEndian=false;   // known exception to the TIFF/PNG rule
			// add camera models as necessary

			columns=split(rows[17],": -."); 	// extract original date and time
			imgYear = columns[2];
			imgMonth = columns[3];
			imgDay = columns[4];
			imgHour = columns[5];
			imgMinute = columns[6];
			imgSecond = columns[7];
			imgDate = imgYear + "-" + imgMonth + "-" + imgDay;
			imgTime = imgHour + ":" + imgMinute + ":" + imgSecond;			
		}


// 2.3. Ask for user confirmation of parameters
		if(userdialog==true) {
			Dialog.create("Parameters");
				/* 'Advanced' parameters (rarely modified - uncomment if necessary, e.g. for troubleshooting)
				Dialog.addMessage("1. Calibration / camera-specific parameters", 15);
				Dialog.addNumber("Sensor Gain", sensorG, 3, 12,"");
				Dialog.addNumber("Sensor parameter B", sensorB,1,12,"");
				Dialog.addNumber("Sensor parameter F", sensorF,1,12,"");
				Dialog.addNumber("Sensor Offset", sensorO,1,12,"");
				Dialog.addNumber("Sensor parameter R", sensorR,9,12,"");
				Dialog.addMessage("Camera model: "+cameraModel);
				Dialog.addCheckbox("Little-endian byte order", byteOrderLittleEndian);
				Dialog.addMessage(" \n2. Atmospheric transmission parameters", 15);
				Dialog.addNumber("Alpha 1", atmAlpha1,6,12,"");
				Dialog.addNumber("Alpha 2", atmAlpha2,6,12,"");
				Dialog.addNumber("Beta 1", atmBeta1,6,12,"");
				Dialog.addNumber("Beta 2", atmBeta2,6,12,"");
				Dialog.addNumber("X", atmX,6,12,"");
				Dialog.addMessage(" \n3. User-set parameters", 15) ;
				*/				
				Dialog.addNumber("Reflected Temperature (C)", appReflTemp_C,1,5,"C");
				Dialog.addNumber("Object Emissivity", objEmissivity,2,5,"");
				Dialog.addNumber("Air Temperature (C)", airTemp_C,1,5,"C");
				Dialog.addNumber("Air Relative Humidity (%)", airRelHumidity_perc,0,5,"");
				Dialog.addNumber("Object Distance (m)", objDistance_m,0,5,"m");
				Dialog.show();

			/* 'Advanced' parameters
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
			*/
			appReflTemp_C=Dialog.getNumber();
			objEmissivity=Dialog.getNumber();
			airTemp_C=Dialog.getNumber();
			airRelHumidity_perc=Dialog.getNumber();
			objDistance_m=Dialog.getNumber();
		}		


// 2.4. Get parameters from CSV input file
		if(parametersFromFile==true) {
			for(j=1; j<parametersFileRows.length; j++){
				parametersData=split(parametersFileRows[j],",;");
				inputImage=parametersData[imageColumn];
				if(inputImage==imageName) {		// look for the image filename in the parameters file - if it's not found, the parameters won't be updated and those stored in the image file will be used
					objEmissivity = parseFloat(parametersData[objEmissivityColumn]);
					objDistance_m = parseFloat(parametersData[objDistanceColumn]);
					airTemp_C = parseFloat(parametersData[airTempColumn]);
					airRelHumidity_perc = parseFloat(parametersData[objRelHumidityColumn]);
					appReflTemp_C = parseFloat(parametersData[appReflTempColumn]);
				}
			}		
		}

	
// 2.5. Calculate derived variables
		if(extract==true) {
			appReflTemp_K = appReflTemp_C+273.15;
			airTemp_K = airTemp_C+273.15;
			airWaterContent = airRelHumidity_perc /100 * exp(1.5587 + 0.06939 * airTemp_C - 0.00027816 * pow(airTemp_C,2) + 0.00000068455 *pow(airTemp_C,3));
			atmTau = atmX * exp(-pow(objDistance_m,0.5) * (atmAlpha1 + atmBeta1 * pow(airWaterContent,0.5))) + (1-atmX) * exp(-pow(objDistance_m,0.5) * (atmAlpha2 + atmBeta2 * pow(airWaterContent,0.5)));
			atmRawSignal_DN = sensorG/(sensorR*(exp(sensorB/(airTemp_K))-sensorF))-sensorO;
			reflRawSignal_DN = sensorG/(sensorR*(exp(sensorB/(appReflTemp_K))-sensorF))-sensorO;

		}


// 2.6. Extract raw data to PNG and TIFF (16-bit) images
		pathRAW_PNG = dirRAW_PNG+imageName+".PNG";
		output = exec(dirExifTool+"exiftool", path, "-RawThermalImage", "-b", "-w", dirRAW_PNG+"%f.PNG");
        IJ.redirectErrorMessages();
        open(pathRAW_PNG);


// 2.7. Extract raw signal data from PNG image
        if (nImages>0) {

			run("32-bit");
			w = getWidth;
			h = getHeight;
			for (y=0; y<h; y++) {
				for (x=0; x<w; x++) {

					rawSignal_DN = getPixel(x,y);


// 2.8. Calculate temperature values for each pixel

					if (byteOrderLittleEndian==true) rawSignal_DN=(rawSignal_DN-(rawSignal_DN%256))/256+(rawSignal_DN%256)*256;

					objRawSignal_DN=(rawSignal_DN-atmRawSignal_DN*(1-atmTau)-reflRawSignal_DN*(1-objEmissivity)*atmTau)/objEmissivity/atmTau;
					
					objTemp_C=sensorB/log(sensorG/(sensorR*(objRawSignal_DN+sensorO))+sensorF)-273.15;
					
					setPixel(x,y,objTemp_C);
					
					}
				}
			resetMinAndMax;
		}


// 3. Outputs
// 3.1. Print image data and parameter values to the Results window
		if(firstfile==true) run("Clear Results");
		setResult("Image", nResults, imageName);
		//setResult("Date", nResults-1, imgDate);
		//setResult("Time", nResults-1, imgTime);
		setResult("Obj_emissivity", nResults-1, objEmissivity);
		setResult("Obj_distance", nResults-1, objDistance_m);
		setResult("Air_temp", nResults-1, airTemp_C);
		setResult("Air_rel_hum", nResults-1, airRelHumidity_perc);
		setResult("App_refl_temp", nResults-1, appReflTemp_C);
		setResult("Camera_model", nResults-1, cameraModel);


// 3.2. Save file as TIFF
		pathTEMP = dirTEMP+imageName+".TIF";
		saveAs("tiff", pathTEMP);


// 3.3. Save file as text table
		pathTEXT = dirTEXT+imageName+".TXT";
		saveAs("Text Image", pathTEXT);


// 3.4. Save file as false-color PNG
		pathCOLOR = dirCOLOR+imageName+".PNG";
		run("Enhance Contrast...", "saturated=0.3 use");	// set contrast
		open(dirPalette+"IRimage.lut");		// set the default color palette (mpl-inferno)
		saveAs("png", pathCOLOR);


// 3.5. Save results table
		pathRESULTS = dirRESULTS+"parameters.csv";
		saveAs("Results", pathRESULTS);


// 4. Close image and results table
		run("Close All");
		firstfile=false;
	}
	selectWindow("Results");
	run("Close");
}
