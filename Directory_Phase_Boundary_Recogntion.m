function []=Directory_Phase_Boundary_Recogntion(SystemDir)
%For all jpg images in the input directory SystemDir find the boundary of the material in
%in the image and marked it on the image. The output file appear in the
%input director SystemDir
%in the vessel ( the border of the vessel in the image should have been
% Basically the  scan for all files with color jpg image (X.jpg) of the input
% directory
% and find files with equivalent name which end by _Border.tif (X_Border.tif) which give
% the vessel borders on the image and then transfer this to file to
%  Main_find_phase_boundary which recognize the material boundary and write
%  them as output files in the SystemDir input directory

close all;
 imtool close all; 
 global FilePath
if (nargin<1)
    clear all; % clear all variable from work space
    SystemDir='EXAMPLES'; 
end;
%'C:\Users\mithycow\Documents\Pictures used for liquid phase recogntion  experiments\One Phase';
%'C:\Users\mithycow\Documents\GOOD FOR USE SOLID IMAGES';
Slist = ls(SystemDir)%%Read list of files in System directory.Any image that will be added after this part (like image made by the programs will not be read to prevent endless loop
Ss=size(Slist);
%************************************************************************************************************************************************
for fs=1:Ss(1)% scan directory  all color image of the system (presumably i jpg format)
   close all;
   Slist(fs,:);
    if  ~isempty(strfind(Slist(fs,:),'.jpg')) || ~isempty(strfind(Slist(fs,:),'.JPG')) % if file is jpg image read this image and scan all template on this image
        Is=imread([SystemDir '\' Slist(fs,:)]);
      %  figure, imshow(Is);
 %-----------------------------------------------------------------------search for the matching border file for the image (presumably one that contain the same name with _border.tif ending)-----------------------------------------------------------------------------------------------------------------------------------------------        
 

 MainName= strrep(Slist(fs,1:length(Slist(fs,:))),'.jpg','');% remove the jpg from the file name
 MainName= strrep(MainName,'.JPG','');% remove the jpg from the file name
 MainName= strrep(MainName,' ','');% the file name contain many spaces which make it impossible to compare or use
            for ft=1:Ss(1)% scan directory 
              hh= strrep(Slist(ft,:),' ','');% the file name contain many spaces which make it impossible to compare or use
                    if  strcmp(hh,[ MainName '_BORDERS.tif']) || strcmp(hh,[ MainName '_BORDERS.TIF']) % if file is jpg image read this image and scan all template on this image
                            Iborder=imread([SystemDir '\' Slist(ft,:)]); % read the vessel border corresponding to the image border
                  %    figure, imshow(Iborder);
                  %    pause;
                           
                          disp(['started:' MainName]);
                          FilePath=[SystemDir '\' MainName]
                 %  two_directions_Main_find_phase_boundary(Is,Iborder);
                       Main_find_phase_boundary(Is,Iborder);
                             disp(['finished:' MainName]);
                        
                    end;
            end
%------------------------------------------------write best match for current image----------------------------------------------------------------------------------------
           
    end
%************************************************************************************************************************************************

end

