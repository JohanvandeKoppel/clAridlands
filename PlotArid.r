# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Plotting script for the CUDA implementation of the                          #
# Arid bushlands patterns model of Rietkerk et al 2002                        #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

remove(list=ls()) # Remove all variables from memory

on=1;off=0;
setwd('/Simulations/OpenCL/clAridLands/clAridLands')

require(fields)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Program settings and parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

Movie=off
Wait=off
AllWindows=off
SmallMovie=off
DisplayEvolution=off
DPI=144

Width = 250*0.5

if (AllWindows==on){
  WinWidth = 1440
  WinHeight = 600
  if (SmallMovie==on){
    Resolution='960x400'  
  } else{
    Resolution="1440x600"
  }
}else {
  WinWidth = 960
  WinHeight = 720
  Resolution= '960x720'
}

# Graphical parameters & palette definitions
ColorPalette = function(x)rev(terrain.colors(x))
water.palette = colorRampPalette(c("white", "blue"))
ColorPalette = colorRampPalette(c("#cd9557", "#f8e29f", "#82A045", "#628239", "#506736","#385233"))

# The maximal value of P, O and W to be plotted. If one goes over that, the value is capped
PGraphMax = 20  
OGraphMax = 20
WGraphMax = 20

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reading the parameters from the data file and declaring variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

FID = file("AridLands.dat", "rb")

NX= readBin(FID, integer(), n = 1, endian = "little");
NY = readBin(FID, integer(), n = 1, endian = "little");
NumFrames = readBin(FID, integer(), n = 1, endian = "little");
EndTime = readBin(FID, integer(), n = 1, endian = "little");

P_in_Time = O_in_Time = W_in_Time = 1:NumFrames

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Opening a window and starting the display loop
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if (Movie==off) 
  quartz(width=WinWidth/DPI, height=WinHeight/DPI, dpi=DPI)

for (jj in 0:(NumFrames-1)){  # Here the time loop starts 
  
   # If a movie is to be made, frames are written as jpegs
   if (Movie==on)
      jpeg(filename = sprintf("Images/Rplot%03d.jpeg",jj),
           width = WinWidth, height = WinHeight, 
           units = "px", pointsize = 24,
           quality = 100,
           bg = "white", res = NA,
           type = "quartz")  
   
   # Reading the data from the files
   Data_P = matrix(nrow=NY, ncol=NX, readBin(FID, numeric(), size=4, n = NX*NY, endian = "little"));
   Data_O = matrix(nrow=NY, ncol=NX, readBin(FID, numeric(), size=4, n = NX*NY, endian = "little"));
   Data_W = matrix(nrow=NY, ncol=NX, readBin(FID, numeric(), size=4, n = NX*NY, endian = "little"));
   
   # recording means values per recorded frame
   P_in_Time[jj+1] = mean(Data_P)
   O_in_Time[jj+1] = mean(Data_O)
   W_in_Time[jj+1] = mean(Data_W)
   
   if (AllWindows==on){
     
     # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
     # Displaying the 3 combined plots for P, O, and W
     # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
     
     # First figure, setting margin, plotting, and adding a title
     par(mar=c(1, 1, 3, 1), mfrow=c(1,3))
     
     image.plot(pmin(Data_P,PGraphMax), zlim=c(0,PGraphMax), xaxt="n", yaxt="n", horizontal = T,
                col = ColorPalette(255),asp=1, bty="n", useRaster=TRUE,
                legend.shrink = 0.93, legend.width = 0.5)  
     
     title(expression(bold(Vegetation~(~g~m^-2))), line=1.5)   
     
     # Second figure, seting margin, plotting, adding title and counter text 
     par(mar=c(mar=c(1, 1, 3, 1)))  
     
     image.plot(pmin(Data_O,OGraphMax), zlim=c(0,OGraphMax), xaxt='n', yaxt="n", horizontal = T,
                col = water.palette(255),asp=1, bty="n", useRaster=TRUE,
                legend.shrink = 0.93, legend.width = 0.5)  
     
     title(expression(bold(Surface~water~(mm))), line=1.5)  
     
     mtext(text=paste("Time : ",sprintf("%1.0f",(jj+1)/NumFrames*EndTime),
                      "of" ,sprintf("%1.0f",EndTime), "days"), 
           side=1, adj=0.5, line=5, cex=0.7)
     
     # Last figure, setting margin, plotting, and adding a title
     par(mar=c(mar=c(1, 1, 3, 1)))
     
     image.plot(pmin(Data_W,WGraphMax), zlim=c(0,WGraphMax), yaxt="n", xaxt="n", horizontal = T, 
                col = water.palette(255), asp=1, bty="n", useRaster=TRUE,
                legend.shrink = 0.93, legend.width = 0.5)  
       
     title(expression(bold(Soil~water~(mm))), line=1.5) 
     
     # Adding the scale bar and text
     axis(side=1, at=c(0.4,0.6), line=4.9, labels = c(0,Width/5), 
          cex.axis=1, tck = -0.02, mgp=c(3, .5, 0))
     
     mtext(text="Scale (m): ", side=1, adj=0.23, line=5, cex=0.7)
     
   }else{

     # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
     # Displaying the vegetation plot only
     # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
     
     # Seting margin, plotting, adding title and counter text 
     par(mar=c(1.5, 4, 2, 6) + 0.1)
     
     image.plot(pmin(Data_P,PGraphMax), zlim=c(0,PGraphMax), xaxt="n", yaxt="n",
                col = ColorPalette(255),asp=1, bty="n", useRaster=TRUE,
                legend.shrink = 0.95, legend.width = 1, axis.args=list(cex=0.2),
                legend.args=list(text=expression(Biomass~(~g~m^-2)),
                                 cex=1, line=0.5))  
     
     title('Arid vegetation', line=0.5, cex=0.7)   
     
     mtext(text=paste("Time : ",sprintf("%1.0f",(jj+1)/NumFrames*EndTime),
                      "of" ,sprintf("%1.0f",EndTime), "days"), 
           side=1, line=0, cex=1)
     
     # Adding the scale bar and text
     axis(side=1, at=c(0.8,1), line=0, labels = c(0,Width/5), 
          cex.axis=0.7, tck = -0.015, mgp=c(3, .25, 0))
     
     mtext(text="Scale (m)", side=1, adj=1.28, line=0, cex=1)
     
   }
   
   # Finishing JPEG, or updating graph
   if (Movie==on) dev.off() else { 
     dev.flush()
     dev.hold()
   }
   
   # For debugging, this lets you go frame by frame
   if (Wait==on){
     cat ("Press [enter] to continue, [q] to quit")
     line <- readline()
     if (line=='q'){ stop() }
   } 
}

# Closing Aridlands.dat 
close(FID)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Building the movie via ffmpeg
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if (Movie==on) { 
  
   # Building command line to run ffmpeg
   InFiles=paste(getwd(),"/Images/Rplot%03d.jpeg", sep="")
   OutFile="AridLands.mp4"
  
   CmdLine=sprintf("ffmpeg -y -r 25 -i %s -s %s -c:v libx264 -pix_fmt yuv420p -b:v 5000k %s", 
                   InFiles, Resolution, OutFile)
   
   # Executing the command
   cmd = system(CmdLine)
  
   # Unhash to immediately display the movie
   # if (cmd==0) try(system(paste("open ", paste(getwd(),"Mussels_PDE.mp4"))))
} 

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display the evolution in time if needed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if (DisplayEvolution==on){
  quartz(width=1920/DPI, height=800/DPI, dpi=DPI)
  
  plot(x=RecordTimes[-(NumFrames+1)],y=P_in_Time,type='l', bty='n', col='green', ylim=c(0,20),
       xlab='Time (days)', ylab='Biomass/mm water')
  lines(RecordTimes[-(NumFrames+1)],O_in_Time, col='cyan')
  lines(RecordTimes[-(NumFrames+1)],W_in_Time, col='darkblue')
}

system('say All ready')