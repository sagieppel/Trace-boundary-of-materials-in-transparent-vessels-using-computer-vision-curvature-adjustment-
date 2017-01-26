function [MarkedImage, BinaryMaterialBoundaries]=Main_find_phase_boundary(Icolor,Iborder)
%Find phase boundary of solids liquid and  powder materials inside transperent container given in image Icolor
%use vessel curvature to adjust for reflections
%INPUT
%Icolor: color  image of tranperent veesel containing liquid solid or powder
%Iborder: binary edge image in the size of Icolor with the boundaries/contour of the glass vessel in Icolor marked 1 (all other pixels are 0) 

%OUTPUT
%MarkedImage image Is with the material boundaries marked on it in black
%BinaryMaterialBoundaries Binary edge image in size of Iborder with the material boundaries marked on it
%In addition the above two images are displayed on the screen

%Method Description
%Scan every two points on the transperent vessel contour  (Iborder) and find the best
%cut/path between this two points that is limited by some specific 
%constraint. The best cheapest legal path for all legal pair of points is
%considererd as phase boundary in the image

%Main input parameters
%Icl=Icolor: color  image of tranperent vessel containing liquid solid or powder
%IborIborder binary edge image in the size of Icolor with the boundaries/contour of the glass vessel in Icolor marked 1 (all other pixels are 0) 
%MaxAngAB (in degree) This the maximal angle of the line between the start point and end point of path(phase bondary)(A,B). Hence phase boundary can exist between two points A,B  only if the slop of the line that form AB have absolute angle smaller then MaxABAng  
%MaxPathAng (in degrees) This is the maximal angle between every point (C) on the path (phase boundary) and the start and end point A,B. Hence: The angle of slope of lines AC and BC (with the x axis) cant be larger then MaxPathAng (where A,B are the start and end point and C point on the path between A and B)
%Kvert the extra price you need to pay to discourage vertical propogation when calculating path. Hence in every point the path go from (X,Y) to (X,Y+/-1) the propogation price of this point is multiply by Kvert 
%VerticalMoves Max number of sequential vertical moves (x,y)->(x,y+/-1) the path allow to have (again vertical phase boundaries are are rare and this come to limit them)
%{
Main parameters used internaly (not as input)
Icol: Color image of the vessel containing the material.
I: Grayscale image of the vessel containing the material.
Iedge: Canny edge image of the vessel containing the material.
Hight, Width:  Height and width of of the image examined (I).

Ax,Ay, Bx,By: Coordinates of endpoints of the path that is explored in this step. This coordinates refer to the pixels in the image in which the path start (Ax,Ay) and end (Bx,By).
LegalPath: Binary image in the size of the image examined (I) in which all legal pixels in which the path currently explored can pass marked 1(green region in Figure 4) and the rest 0. 
LegalPathA: Binary image in the size of the image examined (I) in which all legal pixels in which the paths starting at point A can pass marked 1(green region in Figure 4) and the rest 0. 
LegalPathAB: Binary image in the size of the image examined (I) in which all legal pixels in which the paths starting from point A and ending at point B can pass marked 1(green region in Figure 4) and the rest 0. 
PathMap: Matrix in size of the image examined (I) in which every cell contains the cost of the path from start point A to this cell
BackX, BackY: Matrix in size of the image examined (I) in which every cell contains coordinates of the previous pixel in the path from the start point A to this cell. This matrix allows you to track all paths leading from A in the image.
HighPriceZone: Binary image with the region corresponding to the penalty zone in the paper marked 1(section 4.3.2) cost of paths in this pixel will be triple. Hence a binary image in size of  the image examined (I) where the pixels of the penalty zone marked 1 and the rest zero
BstPath: Binary image size of the image examined (I)  were the best path (hence material boundary) is marked with 1. In the end of the run this will contain the material boundary.

BstPrice: Cost of the best path (BstPath) found so far.

%}


close all;
global I  Iedge Ifill TanMaxPathAng LegalPath LegalPathAB LegalPathA PathMap BackX BackY Icl Ibor Ax Ay Bx By  VerticalMoves Kvert Hight Width MaxX MaxY MinX MinY FilePath TopPathLimit BottumPathLimit
%Global variables mainly image and global properties properties that will be used trough various of functions. For simplicity most important variable will be used as Global intead of being transfer from funtion to function(SIMILAR TO CLASS variable in c++)

%====================intialize main paramters==============================================

if (nargin<1) Icolor=imread('Is.jpg'); end;
if (nargin<2) Iborder=imread('Ibor.tif'); end;




MaxAngAB=50;%50; For liquid And solids %10 for liquids only% %MaxAngAB (in degree) This the maximal angle of the line between the start point and end point of path(phase bondary)(A,B). Hence phase boundary can exist between two points A,B  only if the slop of the line that form AB have absolute angle smaller then MaxABAng  
MaxPathAng=65;%65 solids and liquids % 30 liquids only; Best for liquid And solids % max angel between start and end point (A,C) and every point in the path
VerticalMoves=3;%best   %1 %2  %1     %3; Best for liquid And solids % the Max number of sequential vertical steps that could be perform
Kvert=1.2;% The price of vertical move (x,y)->(x,y+/-1) will be multiple by this constant to discourage vertical propogation
TopPathLimit=0;%0.20;%;0.12; % Paths in the TopPathLimit  percent of the vessel will not be examine (The top of the vessel is of corck funnel or other covers which tend to give false postive)
BottumPathLimit=0.0;%0.1;%0.10; best for liquids % 0 best for solids%;The bottum BottumPathLimit% of the vessel will not be examine for phase boundary. The vessel floor can often conceived as the as phase boundary this is used  to prevent this (should be use only in case of transperent liquids otherwise best set to 0)
%===================Intialize image Paramters================================================================================================
Icl=Icolor;% color image
Ibor=Iborder;% Border image (boundary/contour of the vessel in the image marked in 1 in binary image)
I=double(rgb2gray(Icl));% Greyscale version of the image

if (size(Ibor)~=size(I)) I=imresize(I,size(Ibor)); end; %vessel border image and image must be the same size
[Hight,Width]=size(I);% image size   
[ConY,ConX]=find(Ibor); %arrays of x,y coordinates of vessel contour pixels

[AvWidth,MaxWidth]=VesselAvrgAndMaxWidth(ConY,ConX); % find average and maximal  vessel width and hight in pixels
MinPathDist=MaxWidth/3;%AvWidth/2; %the minimal horizontal distance between start and edning points (A,B) on the vessel contour that  will be explored for phase boundaries (Path between pair of points A,B will not be examine if the horizontal distance is smaller)
%***************high price zone and vessel curvature penalty*****************************************************************************
global HighPriceZone; % (use in PointPrice function) Area in the image around the vessel contur  where propogation of the path is given exra price (usually by multiplying by 3)
HighPriceZoneWidth=0.1; % width of the high price /penalty zone as fraction of the vessel minimum dimension
HighPriceZone=2.0*imdilate(Ibor,Circle(round(min((MaxY-MinY),(MaxX-MinX))*HighPriceZoneWidth))).*imfill(Ibor,'holes')+CreateCurvatureMap(Ibor); % map of extra price for boundary in various of image regions based on curvature of the vessel
%HighPriceZone=2.0*imdilate(Ibor,Circle(round(min((MaxY-MinY),(MaxX-MinX))*HighPriceZoneWidth))).*imfill(Ibor,'holes')+CreateCurvatureMap(Ibor); %BEST SO FAR +imfill(Ibor,'holes');%

%The CreateCurvatureMap is map of areas in the vessel in which the surface
%have sharp curvature given high numbers The vessel curvature is estimated
%using the boundary of the vessel in the image and the assumption the
%vessel is axisymmetric
%HighPriceZone is an area near the vessel contour where propogoation of the page will always have maximum price. This to prevent  path propogation along path boundary where edges are the strongest.
%{

rgb = label2rgb(gray2ind(uint8(HighPriceZone/max(max(HighPriceZone))*255),255),jet(255));
figure,imshow(rgb);
figure,imshow(uint8(HighPriceZone/max(max(HighPriceZone))*255));
imtool(HighPriceZone);
pause();
%}
%*********************************************************
Iedge=double(edge(I,'canny')); %Edge image of Is
 %global  IgrdX IgrdY;% X and Y Gradients in every point of the image some method to calculate path/phase boundary used by some methods to calculate path/phase boundary price 
%[IgrdY, IgrdX] = GetGradient1( I ,'simple' ); % Gradient map of Is (each cell 2d pixel with gradient y,x component) work in two mode 'simple' and 'soble'


PathAB=zeros(size(Iedge));% initialize path map (binary image were the path/phase boundary marked 1) 
BstPath=zeros(size(Iedge));% initialize best path map (binary image were the best  path marked 1) 
BestPathPrice=100000;% intiate best path price the lower the better the path/phase boundary
BstPrice=10000; % The price of the best cheapest path (phase boundary) found so far
Ifill=imfill(Ibor,'holes')-Ibor; %Binary image in size Is which every pixel inside the vessel boundary is 1 and the rest zero.
global MinDy MinDyD
MinDy=0.25;MinDyD=10; % see FloorPathFilter() and section 4.3.1. Flat path restraints of the paper
TanMaxAngAB=abs(tan(MaxAngAB*pi/180));%Max slop between start and end point tangens slope of the max angle between start and end point of path (phase boundary) 
TanMaxPathAng=abs(tan(MaxPathAng*pi/180));%Max slop between start and end point and any point on the path% tangens slope of the max angle between start and end point of path (phase boundary)
%===================Find phase boundaries================================================================================================
%====main loop scan every pair of points on the vessel contour and find cheapest rout between the this rout if the rout price is cheap enough use it as phase boundary

[Nb,yyy]=size(ConY);%Nb is the Number of edge points on the vessel boundary
for f1=1:1:Nb % scan every pair of points A,B on the vessel boundary and try to find path (phase boundary) with best price  between them
    disp(['Finished: ' num2str(f1/Nb*100,4) '% of Scan']);
    Ay=ConY(f1); Ax=ConX(f1);%start point of path (phase boundary)
    Bx=MaxX; % The path will be calcualte from Ax to Bx setting Bx to max X mean all possible paths from A to any possible B point will be calculated
    By=Ay;
  if (MaxX-Ax>MinPathDist) % Check if there are any possible path with minimal distance (MinPathDist)  leading from A to other point B on the vessel contour
     FindLegalPathA(); % find all legal paths to all point leading from Ax with underetmine ending point and put them in LegalPathA
   
     LegalPath=LegalPathA;% all pixels in which the path from A can propogate (binary image)
    % imshow((LegalPath+Ibor)/2);pause(0.01);
      GetPathPriceMap();% Find price for all paths leading from A (important function)
 
 %00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000  
 %-------------------------------------------------Scan All End point B for path --------------------------------------------------------------------------------------------------------------------------------------------------------      
    for f2=1:1:Nb %Loop scan paths from starting A to every possible point  B (end path postion)
     
   
      By=ConY(f2); Bx=ConX(f2);%B coordinate fo End Point  of path 
      if (PathMap(By,Bx)<10000 && Bx>Ax) BestPathPrice=PathMap(By,Bx)/(Bx-Ax); % if there is path between A and B 
      else BestPathPrice=1000000; end;
     
    
      %,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,   
     if abs(Ay-By)<abs((Ax-Bx)*TanMaxAngAB) && Bx-Ax>MinPathDist && BestPathPrice<(BstPrice)% If line between points A and B have slop with angel form angle smaller then the max path angle MaxAngAB  and in suffcient distance explore the cheapest path between A and B and if the path is cheaper the the privous best price (assuming there only one phase boundary)
   
         FindLegalPathAB(); % find all possible points on the image in which the path from Start to end Points (A,B) can propogate. Put it in  LegalPath (global variable) which is a binary image with all legal pixel for path marked 1
         [PathAB]=GetPathFromMap();%Find the path from A to B base on the price and back propogation map
         % imshow(PathAB+LegalPath,[0,2]);
          if sum(sum(PathAB.*~LegalPathAB))==0 % if the path from A to B dont exceed legal limits write it down as best path
              BstPath=PathAB;
              BstPrice=BestPathPrice;
                %***************************************************************************
%---------------------------------------The path from A to B found is illegal in compare to B. Calculate new  path price from A to  specically to B based on both A and  B constraints-------------------------------------------------------------------------------------------------------         
            
          else %Recalculate path from A to B based on legal limits from both A and B
              PathMapB=PathMap; % First backup previous path and backpropogation Map
              BackXB=BackX;
              BackYB=BackY;
          
              LegalPath=LegalPathAB;
              [BestPathPrice]=GetPathPriceMap(); %Find the cheapest legal path between poits A and B and retrun" it price BestPathPrice and the map of the path (path limited by constraint from both A and B)        
              if (PathMap(By,Bx)<10000 && Bx>Ax) % if there legal path from A to B 
                  BestPathPrice=BestPathPrice/(Bx-Ax); % divide by distance to balance for long paths which will always get higher prices
              else BestPathPrice=1000000; end;
               
   %.........................................................................................................................................      
       
         if (BestPathPrice<=BstPrice)%If the price of the path between the point A to B (AB) is lower then the treshhold accept it as real phase boundary 
            [BstPath]=GetPathFromMap();%Take previous location map PrvMap extract path between point A and B Bst Path is binary image or array of binary images each containing path between two points mark in ones
             BstPrice=BestPathPrice;%end;% update best path price if necssary
         end; 
        
         PathMap=PathMapB;%Restore path map from A
         BackX=BackXB;%Restore back propogation step map
         BackY=BackYB;
    %}
  %.........................................................................................................................................      
     end;
   %,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,   
     end;
  end;
  end;
end;
%==========================================================================end of both for loops ========================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% WRITE OUTPUT%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
            close all
          %  figure, imshow(I);
            %figure, imshow(PathMap.*(~BstPath) ,[min(PathMap(:)) max(PathMap(:))]);
         %   figure, imshow(double(~BstPath).*double(I),[0,255]);
         MarkedImage= uint8(double(~BstPath).*double(I));
         BinaryMaterialBoundaries=logical(BstPath+Ibor);
         %figure, imshow( BinaryMaterialBoundaries);
           %figure, imshow(  MarkedImage);
      
            %imwrite( uint8(double(~BstPath).*double(I)),[FilePath '_Marked1.tif']); %Write image with the path marked on it
           imwrite( uint8(double(~imdilate(BstPath,ones(2,2)).*double(I))),[FilePath '_Marked2.tif']); %Write image with the path marked on it
            %imwrite( uint8(double(~imdilate(BstPath,ones(3,3)).*double(I))),[FilePath '_Marked3.tif']); %Write image with the path marked on it
               
           imwrite( uint8(double(~BstPath+Ibor).*double(I)),[FilePath '_MarkedT1.tif']); %Write image with the path marked on it
          %  imwrite( uint8(double(~imdilate(BstPath+Ibor,ones(2,2)).*double(I))),[FilePath '_MarkedT2.tif']); %Write image with the path marked on it
         %  pause(0.3); 
            %imwrite( uint8(double(~imdilate(BstPath+Ibor,ones(3,3)).*double(I))),[FilePath '_MarkedT3.tif']); %Write image with the path marked on it
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
end