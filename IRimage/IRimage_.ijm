////////////////////////////////////////////////////////////////////////////////////////////////////////
// IRimage
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
// Menu icon

var menuItems = newArray("Process", "Color", "Measure", "Test");
var lCmds = newMenu("IRimage Menu Tool", menuItems);
  
macro "IRimage Menu Tool - C209T0809IT3809RCb03T1f06iT3f06mT8f06aTbf06gTff06e" {
	cmd = getArgument();
	if (cmd==menuItems[0]) IRimage_process();
	if (cmd==menuItems[1]) IRimage_color();
	if (cmd==menuItems[2]) IRimage_measure();
	if (cmd==menuItems[3]) IRimage_test();
}






////////////////////////////////////////////////////////////////////////////////////////////////////////
// Function for converting radiometric JPG files to temperature values in degrees C

function IRimage_process() {

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
	//dirRAW_TIFF = dir+"raw_tiff"+File.separator;
	dirTEXT = dir+"text"+File.separator;
	dirCOLOR = dir+"color"+File.separator;
	dirTEMP = dir+"temp"+File.separator;
	dirRESULTS = dir+"results"+File.separator;
	if (!File.exists(dirRAW_PNG)) File.makeDirectory(dirRAW_PNG); 
	//if (!File.exists(dirRAW_TIFF)) File.makeDirectory(dirRAW_TIFF); 
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
			parameters = exec("exiftool", "-Planck*", "-Atmospheric*", "-Reflected*", "-Emissivity*",  "-Relative*", "-Object*", "-RawThermalImageType", "-CameraModel", "-DateTimeOriginal", path);
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
				Dialog.addNumber("Reflected Temperature (°C)", appReflTemp_C,1,5,"C");
				Dialog.addNumber("Object Emissivity", objEmissivity,2,5,"");
				Dialog.addNumber("Air Temperature (°C)", airTemp_C,1,5,"C");
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
		//pathRAW_TIFF = dirRAW_TIFF+imageName+".TIF";
		output = exec("exiftool", path, "-RawThermalImage", "-b", "-w", dirRAW_PNG+"%f.PNG");
        IJ.redirectErrorMessages();
        open(pathRAW_PNG);
		//saveAs("tiff", pathRAW_TIFF);

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
		setResult("Date", nResults-1, imgDate);
		setResult("Time", nResults-1, imgTime);
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
		run("mpl-inferno");		// select the mpl-inferno color palette
		saveAs("png", pathCOLOR);

// 3.5. Save results table
		pathRESULTS = dirRESULTS+"parameters.csv";
		saveAs("Results", pathRESULTS);

// 4. Close image and results table
		run("Close All");
		firstfile=false;
	}

}






﻿/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Function for generating false color images from thermal images

function IRimage_color() {

// ------------------------------------------------------------------------------------------------------------------
// 1. Ask for the directory of files to process
// 2. Ask for options
// 3. Calculate global temperature range (if selected)
// 4. Process each image
//   4.1. Apply colormap
//   4.2. Set temperature range
//   4.3. Add temperature scale bar (if selected)
//   4.4. Save color image as PNG
// ------------------------------------------------------------------------------------------------------------------


// 1. Ask for the directory of files to process
	dir = getDirectory("Select the thermal images folder");
	dirTEMP = dir+"temp"+File.separator;
	dirCOLOR = dir+"color"+File.separator;
	list = getFileList(dirTEMP);
	
// 2. Ask for options
	Dialog.create("False-color image options");
	
		Dialog.addMessage("1. Color palette", 15);
		colors = newArray("mpl-inferno: \"thermal\" palette", "Grays: \"white-hot\" grayscale");
		Dialog.addChoice("   ", colors, colors[0]);

		Dialog.addMessage(" \n2. Image Contrast", 15);
		levels = newArray("Low contrast", "Normal", "High contrast");
		Dialog.addChoice("   ", levels, levels[1]);
	
		Dialog.addMessage(" \n3. Temperature range", 15);
		Dialog.addCheckbox("Use a global temperature range for all images", false);
	
		Dialog.addMessage(" \n4. Temperature scale bar", 15);
		Dialog.addCheckbox("Add temperature scale bar", true);
		sizes = newArray("Small", "Large");
		Dialog.addMessage("Scale bar size:");
		Dialog.addChoice("   ", sizes, sizes[0]);
		Dialog.addMessage("Text size:");
		Dialog.addChoice("   ", sizes, sizes[0]);
				
		Dialog.addMessage(" \n5. Video", 15);
		Dialog.addCheckbox("Save image sequence as a video file", false);
	
		Dialog.show();

	colormap = Dialog.getChoice(); 
	colormap = substring(colormap, 0, lastIndexOf(colormap, ":"));	// leave only the name of the colormap/palette/LUT, without the description

	contrast = Dialog.getChoice(); 

	globalTempRange = Dialog.getCheckbox();

	addScaleBar = Dialog.getCheckbox();
	scaleBarSize = Dialog.getChoice(); 
	textSize = Dialog.getChoice(); 

	saveVideo = Dialog.getCheckbox();


// 3. Calculate global temperature range (if selected)
	setBatchMode(true);
	if(globalTempRange==true) {

		firstFile = list[0];
		run("Image Sequence...", "open=["+dirTEMP+firstFile+"] sort use");	// open all images using a virtual stack
		
		if(contrast=="Low contrast") run("Enhance Contrast...", "saturated=0 use");
		if(contrast=="Normal") run("Enhance Contrast...", "saturated=0.3 use");
		if(contrast=="High contrast") run("Enhance Contrast...", "saturated=3 use");
		getMinAndMax(min, max);
		globalMin = floor(min);		// round min and max to integer values
		globalMax = floor(max)+1;

		close();
	}


// 4. Process each image
	for (i=0; i<list.length; i++) {
		showProgress(i, list.length);
		imageNameExt = list[i];
		imageName = substring(imageNameExt, 0, lastIndexOf(imageNameExt, "."));
		path = dirTEMP + imageNameExt;
		open(path);

// 4.1. Apply colormap
		run(colormap);

// 4.2. Set temperature range

		if(globalTempRange==false) {
			if(contrast=="Normal") run("Enhance Contrast...", "saturated=0.3");
			if(contrast=="High contrast") run("Enhance Contrast...", "saturated=3");
			getMinAndMax(min, max);
			min = floor(min);		// round min and max to integer values
			max = floor(max)+1;
			setMinAndMax(min, max);
		}
		else {
			setMinAndMax(globalMin, globalMax);			
		}

// 4.3. Add temperature scale bar (if selected)
		if(addScaleBar==true) {

			getDimensions(width, height, channels, slices, frames);
			scaleBarZoom = 0.0064 * height;		// the size of the scale bar is proportional to the height of the image
			if(scaleBarSize=="Small") scaleBarZoom = 0.5 * scaleBarZoom;
			if(textSize=="Small") textFontSize = 11; 
				else textFontSize = 16;
			if(scaleBarSize=="Small") textFontSize = 2 * textFontSize;	// font size is also proportional to the size of the scale bar
	
			run("Calibration Bar...", "location=[Upper Left] fill=None label=[Light Gray] number=2 decimal=0 font=" + toString(textFontSize) + " zoom=" + toString(scaleBarZoom) + " bold overlay");
		}

// 4.4. Save color image as PNG
		path = dirCOLOR + imageName + ".png";
		saveAs("png", path);
		close();	
	}

// 4.5. Save all images as an AVI video file

	if(saveVideo==true) {

		firstFile = list[0];
		lastFile = list[list.length-1];
		run("Image Sequence...", "open=["+dirCOLOR+firstFile+"] file=.png sort use");	// open all png color images using a virtual stack

		firstFile = substring(firstFile, 0, lastIndexOf(firstFile, "."));
		lastFile = substring(lastFile, 0, lastIndexOf(lastFile, "."));
		videoFileName = firstFile + " - " + lastFile + ".avi";
		path = dirCOLOR + videoFileName;
		run("AVI... ", "compression=None frame=7 save=["+path+"]");

		close();
	}

	
	setBatchMode(false);
}





/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Function for measuring the temperature of objects in thermal images

function IRimage_measure() {

// ------------------------------------------------------------------------------------------------------------------
// 1. Ask for the directory of files to measure
// 2. Ask for options
// 3. Create or open mask image
//   3.1. Manual selection
//   3.2. Open mask image
//   3.3. Create reference image for the mask
// 4. Measure temperature of objects
//   4.1. Open images with temperature data
//   5.1. Identify objects coded in the mask image
//   5.2. Measure temperature of each object in all images
// 5. Save measurements table
// 6. Close images
// ------------------------------------------------------------------------------------------------------------------


// 1. Ask for the directory of files to measure
	dir = getDirectory("Select the thermal images folder");
	dirTEMP = dir+"temp"+File.separator;
	dirMASK = dir+"mask"+File.separator;
	dirRESULTS = dir+"results"+File.separator;
	list = getFileList(dirTEMP);
	
// 2. Ask for options
	Dialog.create("Object selection");
		Dialog.addMessage("Object selection", 15);
		options = newArray("Manual selection", "Use mask image");
		Dialog.addRadioButtonGroup("", options, 2, 1, options[0]);
		Dialog.show();
	selection = Dialog.getRadioButton();
	manualSelection = (selection==options[0]);
	useMaskImage = (selection==options[1]);

// 3. Create or open mask image

// 3.1. Manual selection
	if(manualSelection==true) {
		// Open first image
		path = dirTEMP + list[0];
		open(path);
		run("mpl-inferno");
		run("Enhance Contrast...", "saturated=0.3 use");
		run("In [+]");
		rename("temperature");
		// Create new mask image
		run("Duplicate...", "title=mask");
		run("8-bit");
		run("Set...", "value=0");
		run("glasbey");
		run("In [+]");
		selectWindow("temperature");
		run("Tile");
		// User selection
		nObjects = getNumber("Enter the number of objects to measure (enter 0 to measure the complete image)", 0);
		
		for(i=1; i<nObjects+1; i++) {
			selectWindow("temperature");
			Dialog.createNonBlocking("Select object number: " + toString(i));
			msg = "Create or modify a selection and press \"OK\" to add it.\nSelection can be a rectangle, oval, polygon, freehand,\nstraight/segmented/freehand line, single point,\nor wand selection.";
			Dialog.addMessage(msg);
			Dialog.show(); 

			if(selectionType>-1) {
				if((selectionType==5)|(selectionType==6)|(selectionType==7)) run("Line to Area"); 	// convert line selection to area	
				if(selectionType==10) run("To Bounding Box"); 	// convert point selection to area	
				selectWindow("mask");
				run("Restore Selection");
				run("Set...", "value=" + toString(i));
				run("Select None");				
			} else {		
				i--;	// if there is no selection when clicking OK, ask again
			}
		}
		selectWindow("temperature");
		run("Close");
		selectWindow("mask");
		if (!File.exists(dirMASK)) File.makeDirectory(dirMASK);
		File.setDefaultDir(dirMASK);
		saveAs("TIFF");
		dirMASK = getDir("file");
		filenameMASK = getTitle;
		nameMASK = substring(filenameMASK, 0, lastIndexOf(filenameMASK, "."));
		rename("mask");
		File.setDefaultDir(dir);
	}

// 3.2. Open mask image
	setBatchMode(true);
	if(useMaskImage==true) {
		if (!File.exists(dirMASK)) File.setDefaultDir(dirMASK);
		pathMASK = File.openDialog("Select a mask image");
		open(pathMASK);
		dirMASK = File.getDirectory(pathMASK);
		filenameMASK = File.getName(pathMASK);
		nameMASK = File.getNameWithoutExtension(pathMASK);
		rename("mask");
		File.setDefaultDir(dir);
	}

// 3.3. Create reference image for the mask
	selectWindow("mask");
	run("Duplicate...", "title=reference");
	rename("reference");
	run("RGB Color");
	for (i=0; i<256; i++) {		// loop through all possible objects coded in the mask image, starting with value=0 (background or complete image if there are no objects selected)
		selectWindow("mask");
		setThreshold(i, i);
		run("Create Selection");
		if(selectionType>-1) {
			setForegroundColor("black");
			selectWindow("reference");
			run("Restore Selection");
			run("To Bounding Box");		// transform selection into a rectangle
			run("Draw", "slice");
			getSelectionBounds(x, y, width, height);
			y=y+height;	 // use bottom left corner instead of top left
			setFont("SansSerif", 9, "bold antiliased");
			setColor("white");
			drawString(toString(i), x, y, "black");		// label the selected area
		}
	}
	selectWindow("reference");
	pathREF = dirMASK + nameMASK + "_reference.png";
	saveAs("png", pathREF);
	close();

// 4. Measure temperature of objects

// 4.1. Open images with temperature data
	firstFile = list[0];
	run("Image Sequence...", "open=["+dirTEMP+firstFile+"] sort use");	// open all images using a virtual stack
	rename("temperature");

// 4.2. Identify objects coded in the mask image
	for (i=0; i<256; i++) {		// loop through all possible objects coded in the mask image, starting with value=0 (background or complete image if there are no objects selected)
		selectWindow("mask");
		setThreshold(i, i);
		run("Create Selection");

// 4.3. Measure temperature of each object in all images
		if(selectionType>-1) {
			selectWindow("temperature");
			run("Restore Selection");
			for (j=1; j<nSlices+1; j++) {
				showProgress(j, nSlices);
				setSlice(j);
				imageName = getInfo("slice.label");
				getStatistics(area, mean, min, max, std);
				setResult("Mask_image", nResults, nameMASK);
				setResult("Object", nResults-1, i);
				setResult("Image", nResults-1, imageName);
 				setResult("Obj_area", nResults-1, area);
				setResult("Obj_mean_temp", nResults-1, mean);
				setResult("Obj_min_temp", nResults-1, min);
				setResult("Obj_max_temp", nResults-1, max);
				setResult("Obj_st_dev_temp", nResults-1, std);
			}
		}
	}

// 5. Save measurements table
	pathRESULTS = dirRESULTS+"measurements_"+nameMASK+".csv";
	saveAs("Results", pathRESULTS);
		
// 6. Close images
	run("Close All");
	setBatchMode(false);
}





﻿/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Function for comparing temperature values from thermal images exported with FLIR Tools or exported with IRimage

function IRimage_test() {

// ------------------------------------------------------------------------------------------------------------------
// 1. Ask for the directory of files to process
// 2. File processing
//   2.1. Open CSV file (FLIR Tools data)
//   2.2. Open corresponding TXT file (IRimage data)
//   2.3. Read temperature values
// 3. Outputs
//   3.1. Print temperature difference statistics
//   3.2. Save results text file
//   3.3. Plot values
//   3.4. Save plot image
// 4. Close images
// ------------------------------------------------------------------------------------------------------------------


// 1. Ask for the directory of files to process
	dir = getDirectory("Select the thermal images folder");
	dirTEXT = dir+"text"+File.separator;
	dirCSV = dir+"csv"+File.separator;
	dirRESULTS = dir+"results"+File.separator;

	
// 2. File processing
    list = getFileList(dirCSV);
    for (f=0; f<list.length; f++) {
		showProgress(f, list.length);
		setBatchMode(true);

// 2.1. Open CSV file (FLIR Tools data)
		iscsv=false;
		do {
			imageName=list[f];
			if( endsWith(imageName,"csv") ) iscsv=true;
			if( endsWith(imageName,"CSV") ) iscsv=true;
			if(iscsv==false) f++;
			if(f>=list.length) exit;
		} while (iscsv==false);
		path1 = dirCSV+imageName;
	    run("Text Image... ", "open=["+path1+"]");
	    file1=File.name;

// 2.2. Open corresponding TXT file (IRimage data)
		path2 = dirTEXT + substring(imageName, 0, lastIndexOf(imageName, ".")) + ".txt";		// open corresponding IRimage TXT file
	    run("Text Image... ", "open=["+path2+"]");
	    file2=File.name;

// 2.3. Read temperature values
		selectWindow(file1);
		w = getWidth;
		h = getHeight;

		i = 0;
		data1 = newArray(w*h);
		data2 = newArray(w*h);
		diffAboveThreshold=0;
		diffSum=0;
		diffCount=0;

		for (y=0; y<h; y++) {
			for (x=0; x<w; x++) {
				selectWindow(file1);
				data1[i] = getPixel(x,y);		// get temperature value in image 1
				selectWindow(file2);
				data2[i] = getPixel(x,y);		// get temperature value in image 2

				difference = abs(data2[i]-data1[i]);
				if (data1[i]>=-40) {		// exclude values below -40C
					if (difference > 0.01) diffAboveThreshold++;	// count temperature differences below 0.005 C
					diffSum=diffSum+difference;
					diffCount++;	// count total temperature differences analyzed
				}

				i++;
			}
		}


// 3. Outputs

// 3.1. Print temperature difference statistics
		print("\\Clear");
		print(file1,"vs.",file2);
		print("Excluded pixels with temperature below -40 C:", (1-(diffCount/(w*h)))*100,"%");
		print("Average temperature difference:", diffSum/diffCount," C");
		print("Temperature differences above 0.01 C:", diffAboveThreshold/diffCount*100,"%");

// 3.2. Save results text file
		logpath = dirRESULTS + "test_" + substring(imageName, 0, lastIndexOf(imageName, ".")) + ".txt";
		selectWindow("Log");
		saveAs("Text", logpath);

// 3.3. Plot values
		Plot.create("Plot", "X-axis Label", "Y-axis Label");
		Plot.setFrameSize(280, 280);
		Plot.setFontSize(20, "options");
		Plot.setLimits(-100, 200, -100, 200);
		Plot.setXYLabels("Temperature, C (Reference)", "Temperature, C (IRimage)");
		Plot.drawLine(-100, -100, 200, 200);
		Plot.setColor("blue");
		Plot.setLineWidth(3);
		Plot.add("circle", data1, data2);
		Plot.show();

// 3.4. Save plot image
		selectWindow("Plot");
		plotpath = dirRESULTS + "test_plot_" + substring(imageName, 0, lastIndexOf(imageName, ".")) + ".png";
		saveAs("png", plotpath);


// 4. Close images
		run("Close All");
		setBatchMode(false);
    }
}


