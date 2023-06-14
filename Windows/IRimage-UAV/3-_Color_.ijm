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


﻿////////////////////////////////////////////////////////////////////////////////////////////////////////
// Function for generating false color images from thermal images
// -----------------------------------------------------------------------------------------------------
// 1. Ask for the directory of files to process
// 2. Ask for options
// 3. Calculate global temperature range (if selected)
// 4. Process each image
//   4.1. Apply colormap
//   4.2. Set temperature range
//   4.3. Add temperature scale bar (if selected)
//   4.4. Save color image as PNG
// -----------------------------------------------------------------------------------------------------

macro "IR-image-color" {

// 1. Ask for the directory of files to process
	dir = getDirectory("Select the thermal images folder");
	dirTEMP = dir+"temp"+File.separator;
	dirCOLOR = dir+"color"+File.separator;
	dirIRimage = getDir("plugins") + "IRimage-UAV" + File.separator;
	dirPalette = dirIRimage + "palette" + File.separator;
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

		run("Image Sequence...", "open=["+dirTEMP+"] sort use");	// open all images using a virtual stack
		
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
		if(colormap=="mpl-inferno") open(dirPalette+"IRimage.lut");		// set the default color palette included with IRimage (mpl-inferno)
		else run(colormap);		// apply the colormap using the standard available LUTs

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
		if(saveVideo==false) close();	// keep images open to later save as video
	}

// 4.5. Save all images as an AVI video file

	if(saveVideo==true) {
		//run("Image Sequence...", "open=["+dirCOLOR+"] file=.png sort use");	// open all png color images using a virtual stack  
		run("Images to Stack");

		firstFile = list[0];
		lastFile = list[list.length-1];
		firstFile = substring(firstFile, 0, lastIndexOf(firstFile, "."));
		lastFile = substring(lastFile, 0, lastIndexOf(lastFile, "."));
		videoFileName = firstFile + " - " + lastFile + ".avi";

		path = dirCOLOR + videoFileName;
		run("AVI... ", "compression=None frame=7 save=["+path+"]");

		close();
	}

	
	setBatchMode(false);
}


