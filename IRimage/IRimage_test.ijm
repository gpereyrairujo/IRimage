//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ImageJ macro for comparing temperature values from thermal images exported with FLIR Tools or exported with IRimage
// Author: Gustavo Pereyra Irujo - pereyrairujo.gustavo@conicet.gov.ar
// Licensed under GNU GENERAL PUBLIC LICENSE Version 3
// https://github.com/gpereyrairujo/IRimage/test

macro "IRimage_test Action Tool - C209T0809IT3809RCb03T1f06tT4f06eT8f06sTcf06t" {

// ---------------------------------------------------------------------------------------------------------
// 1. Ask for the directory of files to process
// 2. File processing
//   2.1. Find CSV files
//   2.2. Open files
//   2.3. Read values from images 1 and 2
// 3. Outputs
//   3.1. Print temperature difference statistics
//   3.2. Save results text file
//   3.3. Plot values
//   3.4. Save plot image
// 4. Close images
// ---------------------------------------------------------------------------------------------------------

// 1. Ask for the directory of files to process
	dir = getDirectory("Choose a Directory");

// 2. File processing
    list = getFileList(dir);
    firstfile=true;
    for (f=0; f<list.length; f++) {

// 2.1. Find CSV files
		iscsv=false;
		do {
			imageName=list[f];
			if( endsWith(imageName,"csv") ) iscsv=true;
			if( endsWith(imageName,"CSV") ) iscsv=true;
			if(iscsv==false) f++;
			if(f>=list.length) exit;
		} while (iscsv==false);
		path1 = dir+imageName;
		showProgress(f, list.length);

// 2.2. Open files
		setBatchMode(true);
	    run("Text Image... ", "open=["+path1+"]");
	    file1=File.name;
		path2 = substring(path1, 0, lastIndexOf(path1, ".")) + ".jpg_TEXT.txt";		// open corresponding IRimage text file
	    run("Text Image... ", "open=["+path2+"]");
	    file2=File.name;

// 2.3. Read values from images 1 and 2

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
		print("Excluding pixels with temperature below -40°C:", (1-(diffCount/(w*h)))*100,"%");
		print("Average temperature difference:", diffSum/diffCount,"°C");
		print("Temperature differences above 0.01°C:", diffAboveThreshold/diffCount*100,"%");

// 3.2. Save results text file
		logpath = substring(path1, 0, lastIndexOf(path1, ".")) + ".jpg_TESTRESULTS.txt";
		selectWindow("Log");
		saveAs("Text", logpath);

// 3.3. Plot values
		Plot.create("Plot", "X-axis Label", "Y-axis Label");
		Plot.setFrameSize(280, 280);
		Plot.setLimits(-100, 200, -100, 200);
		Plot.setXYLabels("Temperature, °C (FLIR Tools)", "Temperature, °C (IRimage)");
		Plot.drawLine(-100, -100, 200, 200);
		Plot.setColor("blue");
		Plot.add("circle", data1, data2);
		Plot.show();

// 3.4. Save plot image
		selectWindow("Plot");
		plotImage = substring(path1, 0, lastIndexOf(path1, ".")) + "_PLOT.png";
		saveAs("png", plotImage);

// 4. Close images
		run("Close All");
		selectWindow("Log");
		run("Close");
		setBatchMode(false);

    }
}
