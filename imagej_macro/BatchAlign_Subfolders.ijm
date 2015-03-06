/*	
Aligns the stacks located in the subfolders of the specified folder.
User input:  - the names of the (3) channels  files. 
			 - the parent folder
The macros requires the plugin "MultiStackRegFix_s", a modification of the "MultiStackRegFix_"
Author:            Dmytro S. Lituiev, 2013, Zurich
Aknowledgements:   Hannes Vogler, for probation and bug report
*/

setBatchMode(true)
// print("\\Clear");

print("INFORMATION: this macros operates in two steps:")
print("1. Pre-smoothing and generation of alignment matrices. THIS STEP WILL BE SKIPPED IF a 'TransformationMatrices.txt' file ALREADY EXISTS in the sub-folder. The pre-smoothed movie is discarded after the matrices are generated")
print("2. Alignment of the channels using the matrices generated and saved in the corresponding subfolder in the step 1. THIS STEP WILL BE SKIPPED for those channels, whose aligned version '<channel name>-a.tif' ALREADY EXISTS in the sub-folder ")

channelNames = newArray("CFP", "FRET", "dsRed")
numberChannels = channelNames.length;

Dialog.create("Specify the channel names");
Dialog.addString("reference channel", channelNames[0]);
for (i = 2; i<=numberChannels; i++) { 
    Dialog.addString("channel " + i,  channelNames[i-1]);
};
Dialog.addMessage("If you need change the number of channels\n"+
" please enter the number below")
Dialog.addNumber("Number of channels (#)", 3);
Dialog.show();

numberChannels = Dialog.getNumber();

if  (numberChannels>3) {
    Dialog.create("Specify the channel names: DOES NOT WORK SO FAR");
    Dialog.addString("reference channel",  channelNames[0]);
    for (i = 2; i<=channelNames.length; i++) { 
        Dialog.addString("channel " + i,  channelNames[i-1]);
    };
    for (i = channelNames.length+1; i<=numberChannels; i++) { 
        Dialog.addString("channel " + i,  "");
    };
    Dialog.show();
};

// ======================================

ch = newArray(numberChannels);
for (i = 0; i<numberChannels; i++) {
    ch[i] =  Dialog.getString(); 
}
 
print("The reference channel is " + ch[0] );

dir1 = getDirectory("Choose Source Directory "); 
list = getFileList(dir1); 

// Array.sort(list);
// for (i=0; i<list.length; i++) print(list[i]);

for (i = 0; i<list.length; i++) { 	 
	 currRefStackPath = dir1+ substring(list[i], 0,  lengthOf(list[i])-1) ;
	 refStack = currRefStackPath +  File.separator + ch[0] + ".tif";
	 TrMatrixPath = currRefStackPath +  File.separator + "TransformationMatrices.txt";
	 // print(currRefStackPath);
	 if (File.isDirectory(currRefStackPath) && File.exists(refStack) && !File.exists(TrMatrixPath)) {
	            print( i + ": "+ currRefStackPath);
				// ================	
				/*				
				getRawStatistics(nPixels, mean, min, max);
				run("Find Maxima...", "noise="+max+" output=[Point Selection]");
				getSelectionBounds(x, y, w, h);
				print("coordinates=("+x+","+y+"), value="+getPixel(x,y)); 
				*/
				// ================	
				open(refStack);
				run("Gaussian Blur 3D...", "x=2 y=2 z=2");
				// ================				
                print("\\Update:" + i + ": " + " generating transformation matrices on " + ch[0] + "... ");
                StackRegParamSave =  "1 "+ currRefStackPath +  File.separator;
				run("MultiStackRegFix s", StackRegParamSave );			
				close();
				// ================	
				for (k = 0; i<ch.length; k++) {
                    alignWithMatrix(currRefStackPath, ch[k]);
				}
                // ================	
				print("\\Update:"+i + ": "+ currRefStackPath, " is completed"); 							
           } 
	else{ 
	    if (File.isDirectory(currRefStackPath) && !File.exists(refStack) && !File.exists(TrMatrixPath) )
			print(i + ": no reference channel can be found in "+ currRefStackPath);
		if (File.isDirectory(currRefStackPath) && File.exists(TrMatrixPath) )
		{  
			print(i + ": "+ currRefStackPath + " : the transformation matrix already exists");
    		// ================	
	    	for (k = 0; i<ch.length; k++) {
               alignWithMatrix(currRefStackPath, ch[k]);
			}
            print("\\Update:"+i + ": "+ currRefStackPath, " is completed"); 		
		};
    };
		
};

	print("end of the batch alignment");

	
 function alignWithMatrix(path, channel) {
 /* aligns the channel stack file located in 'path +"/"+channel+".tif"'
    given the transformation matrix in 'path +"/"+ "TransformationMatrices.txt"
 */
    TrMatrixPath = currRefStackPath +  File.separator + "TransformationMatrices.txt";
        if 	(File.exists(TrMatrixPath)){
		    chStack = currRefStackPath +  File.separator + channel + ".tif";
			if 	(File.exists(chStack) ) {				
			    print("\\Update:"+" ... aligning the " + channel + " channel in ` "+path + "`" );
				open(chStack);
				run("MultiStackRegFix s", "5 "+ TrMatrixPath );
				save(currRefStackPath +  File.separator + channel + "-a.tif");			
				close();
				}
			else {
			    print("\\Update:"+"Could not find the "+channel+" channel in " + path + "\n");
			    };
			}	else {
			print("\\Update:"+"Could not find the transformation matrix in " + path + "\n");
			};
 };
 
 function existsUnAlignedChannel(path, channel){
  /* returns true if the raw channel (with the suffix ".tif") exists 
     and the aligned channel (with the suffix "-a.tif") is missing
   */
 return (File.exists(currRefStackPath +  File.separator + channel+ ".tif")&& 
		    ! (File.exists(currRefStackPath +  File.separator + channel+ "-a.tif")));
 };
