////////////////////////////////////////////////////////////////////////////////////////////////////////
// IRimage-UAV
//
// ImageJ code for processing thermal images from DJI cameras
// - Converts radiometric JPG files to TIFF format
// - Allows for the modification of parameters (emissivity, reflected temperature, distance, air humidity)
// - Copies EXIF data (latitude/longitude, capture date/time, etc)
// - Generates false color images from previously converted thermal images
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
//    2.1. Find radiometric JPG files
//    2.2. Ask for user confirmation of parameters
//    2.3. Get parameters from CSV input file
//    2.4. Extract temperature data in RAW format
//    2.5. Open RAW image in ImageJ
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
	dirRAW = dir+"raw"+File.separator;
	dirTEXT = dir+"text"+File.separator;
	dirCOLOR = dir+"color"+File.separator;
	dirTEMP = dir+"temp"+File.separator;
	dirRESULTS = dir+"results"+File.separator;
	dirIRimage = getDir("plugins") + "IRimage-UAV" + File.separator;
	// Exiftool path in Windows version (Exiftool portable version included with IRimage)
	dirExifTool = dirIRimage + "exiftool" + File.separator;
	// Exiftool path in MacOS version (Exiftool installed separately)
	// dirExifTool = "/usr/local/bin/";
	dirDJIThermalSDK = dirIRimage + "dji_thermal_sdk" + File.separator;
	dirPalette = dirIRimage + "palette" + File.separator;
	if (!File.exists(dirRAW)) File.makeDirectory(dirRAW); 
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


// 2.1. Find radiometric JPG files
		isjpg=false;
		do {
			imageNameExt=list[i];
			if( endsWith(imageNameExt,".jpg") ) isjpg=true;
			if( endsWith(imageNameExt,".jpeg") ) isjpg=true;
			if( endsWith(imageNameExt,".JPG") ) isjpg=true;
			if( endsWith(imageNameExt,".JPEG") ) isjpg=true;
			if(isjpg==false) i++;
			if(i>=list.length) exit;
		} while (isjpg==false); 
		imageName = substring(imageNameExt, 0, lastIndexOf(imageNameExt, "."));
		path = dir+imageNameExt;
		showProgress(i, list.length);


// 2.2. Ask for user confirmation of parameters
		if(globalParameters & firstfile) userdialog=true; else userdialog=false;

		if(userdialog==true) {
			Dialog.create("Parameters");
			
				Dialog.addNumber("Reflected Temperature", 23.0, 1, 5,"-40 - 500C");
				Dialog.addNumber("Object Emissivity", 1.0, 2, 5,"0.1 - 1.0");
				Dialog.addNumber("Air Relative Humidity", 70, 0, 5,"20 - 100%");
				Dialog.addNumber("Object Distance", 5, 0, 5,"1 - 25m");
				Dialog.show();

			appReflTemp_C=Dialog.getNumber();
			objEmissivity=Dialog.getNumber();
			airRelHumidity_perc=Dialog.getNumber();
			objDistance_m=Dialog.getNumber();
		}		


// 2.3. Get parameters from CSV input file
		if(parametersFromFile==true) {
			for(j=1; j<parametersFileRows.length; j++){
				parametersData=split(parametersFileRows[j],",;");
				inputImage=parametersData[imageColumn];
				if(inputImage==imageName) {		// look for the image filename in the parameters file - if it's not found, the parameters won't be updated and those stored in the image file will be used
					objEmissivity = parseFloat(parametersData[objEmissivityColumn]);
					objDistance_m = parseFloat(parametersData[objDistanceColumn]);
					airRelHumidity_perc = parseFloat(parametersData[objRelHumidityColumn]);
					appReflTemp_C = parseFloat(parametersData[appReflTempColumn]);
				}
			}		
		}



// 2.4. Extract temperature data in RAW format

		pathRAW = dirRAW+imageName+".RAW";

		if(parametersFromImage==true) {
			output = exec(dirDJIThermalSDK+"dji_irp", "-s", path, "-a", "measure", "-o", pathRAW, "--measurefmt", "float32");
		} else {
			output = exec(dirDJIThermalSDK+"dji_irp", "-s", path, "-a", "measure", "-o", pathRAW, "--measurefmt", "float32", "--distance", toString(objDistance_m), "--humidity", toString(airRelHumidity_perc), "--emissivity", toString(objEmissivity), "--reflection", toString(appReflTemp_C));
		}
		
// 2.5. Open RAW image in ImageJ
	
		// parse dji_irp output
		rows=split(output, "\n"); 
		n_rows = rows.length;
		imageWidth = 0;
		imageHeight = 0;
		for(j=0; j<n_rows; j++){ 
			// image dimensions
			prefix = substring(rows[j], 0, 11);
			if(prefix=="      image") {
				prefix = substring(rows[j], 0, 18);
				if(prefix=="      image  width") {
					 columns=split(rows[j],":");
					 imageWidth=parseInt(columns[1]);
				}
				if(prefix=="      image height") {
					 columns=split(rows[j],":");
					 imageHeight=parseInt(columns[1]);
				}
			}
			// error code
			prefix = substring(rows[j], 0, 9);
			if(prefix=="Test done") {
				 errorCode = parseInt(substring(rows[j], 27));
				 if(errorCode!=0) exit(output);
			}
		}
		if(imageWidth==0) exit("Error obtaining image dimensions\n" + output);
		if(imageHeight==0) exit("Error obtaining image dimensions\n" + output);
		
		run("Raw...", "open=[" + pathRAW + "] image=[32-bit Real] width=" + toString(imageWidth) + " height=" + toString(imageHeight) + " little-endian");



// 3. Outputs
// 3.1. Print image data and parameter values to the Results window
		if(firstfile==true) run("Clear Results");
		setResult("Image", nResults, imageName);
		//setResult("Date", nResults-1, imgDate);
		//setResult("Time", nResults-1, imgTime);
		if(parametersFromImage!=true) {
			setResult("Obj_emissivity", nResults-1, objEmissivity);
			setResult("Obj_distance", nResults-1, objDistance_m);
			setResult("Air_rel_hum", nResults-1, airRelHumidity_perc);
			setResult("App_refl_temp", nResults-1, appReflTemp_C);
		}

// 3.2. Save file as TIFF

		// set contrast and palette
		run("Enhance Contrast...", "saturated=0.3 use");	// set contrast
		open(dirPalette+"IRimage.lut");		// set the default color palette (mpl-inferno)

		// save as TIFF
		pathTEMP = dirTEMP+imageName+".TIF";
		saveAs("tiff", pathTEMP);
		
		// copy EXIF data from orginal file (capture date and time, gps data, etc.)
		output = exec(dirExifTool+"exiftool", "-TagsFromFile", path, pathTEMP, "-overwrite_original");


// 3.3. Save file as text table
		pathTEXT = dirTEXT+imageName+".TXT";
		saveAs("Text Image", pathTEXT);


// 3.4. Save file as false-color PNG
		pathCOLOR = dirCOLOR+imageName+".PNG";
		saveAs("png", pathCOLOR);


// 3.5. Save results table
		pathRESULTS = dirRESULTS+"parameters.csv";
		saveAs("Results", pathRESULTS);


// 4. Close image and results table
		run("Close All");
		firstfile=false;
	}
	//selectWindow("Results");
	//run("Close");
}
