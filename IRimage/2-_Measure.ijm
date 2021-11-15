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
// Function for measuring the temperature of objects in thermal images
// -----------------------------------------------------------------------------------------------------
// 1. Ask for the directory of files to measure
// 2. Ask for options
// 3. Create or open mask image
//   3.1. Manual selection
//   3.2. Open mask image
//   3.3. Create reference image for the mask
// 4. Measure temperature of objects
//   4.1. Open images with temperature data
//   4.2. Identify objects coded in the mask image
//   4.3. Measure temperature of each object in each image
//   4.4. Extract the date and time of capture
// 5. Save measurements table
// 6. Close images
// -----------------------------------------------------------------------------------------------------

macro "IR-image-measure" {

// 1. Ask for the directory of files to measure
	dir = getDirectory("Select the thermal images folder");
	dirTEMP = dir+"temp"+File.separator;
	dirMASK = dir+"mask"+File.separator;
	dirRESULTS = dir+"results"+File.separator;
	dirIRimage = getDir("plugins") + "IRimage" + File.separator;
	dirPalette = dirIRimage + "palette" + File.separator;
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
		open(dirPalette+"IRimage.lut");		// set the default color palette (mpl-inferno)
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
			msg = "Create or modify a selection in the thermal image\nand press \"OK\" to add it to the mask image.\n \nSelection can be a rectangle, oval, polygon, freehand,\nstraight/segmented/freehand line, single point,\nor wand selection.\n \nYou can zoom in and out using the + and - keys.";
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

		if(nObjects==0) {		// if the user entered 0 to measure the complete image, select the complete image as object 1
			selectWindow("mask");
			run("Select All");
			run("Set...", "value=" + toString(1));
			run("Select None");
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
	run("Select None"); // (if the file contains a selection (e.g. if it was modified manually) then it would only duplicate the selected area)
	run("Duplicate...", "title=reference");
	rename("reference");
	run("RGB Color");
	for (i=1; i<256; i++) {		// loop through all possible objects coded in the mask image, starting with value=1
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
	run("Image Sequence...", "open=["+dirTEMP+"] sort use");	// open all images using a virtual stack
	rename("temperature");

// 4.4. Extract the date and time of capture
	Table.create("DateTime");
	for (j=1; j<nSlices+1; j++) {
		showProgress(j, nSlices*2);
		setSlice(j);
		imageName = getInfo("slice.label");
		pathJPG = dir + imageName + ".jpg";
		parameters = exec("exiftool", "-DateTimeOriginal", pathJPG);
		columns=split(parameters,": -."); 	// extract original date and time
		imgYear = columns[2];
		imgMonth = columns[3];
		imgDay = columns[4];
		imgHour = columns[5];
		imgMinute = columns[6];
		imgSecond = columns[7];
		imgDate = imgYear + "-" + imgMonth + "-" + imgDay;
		imgTime = imgHour + ":" + imgMinute + ":" + imgSecond;		

		Table.set("Date", j-1, imgDate);
		Table.set("Time", j-1, imgTime);
	}
	Table.update()

// 4.2. Identify objects coded in the mask image
	for (i=1; i<256; i++) {		// loop through all possible objects coded in the mask image, starting with value=1
		selectWindow("mask");
		setThreshold(i, i);
		run("Create Selection");

// 4.3. Measure temperature of each object in each image
		if(selectionType>-1) {
			selectWindow("temperature");
			run("Restore Selection");
			for (j=1; j<nSlices+1; j++) {
				showProgress(j+nSlices, nSlices*2);
				setSlice(j);
				imageName = getInfo("slice.label");
				imageDate = Table.getString("Date", j-1, "DateTime");
				imageTime = Table.getString("Time", j-1, "DateTime");
				getStatistics(area, mean, min, max, std);
				setResult("Mask_image", nResults, nameMASK);
				setResult("Object", nResults-1, i);
				setResult("Image", nResults-1, imageName);
				setResult("Date", nResults-1, imageDate);
				setResult("Time", nResults-1, imageTime);
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


