clear all; clc;
on=1; off=0;

Movie = off;
PlotAll=off;

BarFontSize      = 18;
TitleFontSize    = 24;

FID=fopen('AridLands.dat', 'r');
A=fread(FID, 4, 'int32');

X=A(1);
Y=A(2);
Z=A(3);
EndTime=A(4);

popP=zeros(X,Y,'double');
popO=zeros(X,Y,'double');
popW=zeros(X,Y,'double');

% Get Screen dimensions and set Main Window Dimensions
x = get(0,'ScreenSize'); ScreenDim=x(3:4);
MainWindowDim=floor(ScreenDim.*[0.9 0.8]);

if Movie==on,
    writerObj = VideoWriter('AridLands.mp4', 'MPEG-4');
    open(writerObj);
end;

if PlotAll==on,
    MainWindowDim=[1920 818];
else
    MainWindowDim=[960 720];
end;

% The graph window is initiated, with specified dimensions.
Figure1=figure('Position',[(ScreenDim-MainWindowDim)/2 MainWindowDim],...
               'Color', 'white');

if PlotAll==on, 
    subplot('position',[0.02 0 0.30 0.95]);
end;
F1=imagesc(popP',[0 20]);
title('Plant density (g/m^2)','FontSize',TitleFontSize);  
colorbar('SouthOutside','FontSize',BarFontSize); 
colormap('default'); axis image;axis off;

if PlotAll==on,
    subplot('position',[0.35 0 0.30 0.95]);
    F2=imagesc(popO',[0 20]);
    title('Surface water (mm)','FontSize',TitleFontSize);  
    colorbar('SouthOutside','FontSize',BarFontSize);
    axis image; axis off;

    subplot('position',[0.68 0 0.30 0.95]);
    F3=imagesc(popW',[0 10]);
    title('Soil water (mm)','FontSize',TitleFontSize);    
    colorbar('SouthOutside','FontSize',BarFontSize);
    axis image; axis off;  
end

for x=1:Z,
    popP=reshape(fread(FID,X*Y,'float32'),X,Y);
    popO=reshape(fread(FID,X*Y,'float32'),X,Y);
    popW=reshape(fread(FID,X*Y,'float32'),X,Y);

    set(F1,'CData',popP');
    if PlotAll==on,
        set(F2,'CData',popO');
        set(F3,'CData',popW');  
    end;
    set(Figure1,'Name',['Timestep ' num2str(x/Z*EndTime) ' of ' num2str(EndTime)]); 

    drawnow; 
    
    if Movie==on,
         frame = getframe(Figure1);
         writeVideo(writerObj,frame);
    end

end;

fclose(FID);

if Movie==on,
    close(writerObj);
end;

disp('Done');beep;


