function FindLegalPathA()
%{
Description
Find the legal region in the image in which a path starting at point A can pass.
 It returns the binary image in the size of the examined image (I) were pixel in which the path can pass are marked 1 and illegal regions in which the path don’t allow to pass marked 0. 
All parameters are passed from and to this function are global. Therefore, it has no direct input or output. For more details on the main principles of this function see section 4 of the paper.
Input (global)
Ax,Ay: Coordinates of start point of the path that is explored in this step. This coordinates refer to the pixel in the image in which the path start (Ax,Ay).
%Ibor is the vessel contour (binary image) 
%Ifill is the vessel interior(binary image) 
Output (global)
LegalPathA: Binary image in the size of the image examined (I) in which all legal pixels in which the paths starting at point A can pass marked 1(green region in Figure 4) and the rest 0. 

%}
global Ifill LegalPathA  Ibor
LegalPathA=Ifill+Ibor; 
%-------------------------Use various of filter to remove pixels from LegalPathAB according to various constaints---------------------------------------------------
AngleFilterA(); %Filter paths with high angels slops
TopFilter(); % OPTIONal filter to area of the vessel  to Prevent path from gowin to close to avoid path contact with corck funnels and other covers 
%imshow((LegalPathA+Ifill)/2); pause;
BottumFilter(); % OPTIONal filter bottum area of the vessel Prevent path from gowin to close to the vessel floor and funnel
%imshow((LegalPathA+Ifill)/2); pause;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function AngleFilterA()
%Filter out all pixels  (C) for which the vector AC  have slope (tan) of more then TanMaxPathAng
global LegalPathA TanMaxPathAng Ax Ay MaxX MaxY MinY
for fx=Ax:1:MaxX% scan every colum between point A and the vessel max point
  LegalPathA(round(min([Ay+(fx-Ax)*TanMaxPathAng;  MaxY])+1):1:MaxY,fx)=0;%Empty all point in cloumn fx below minimal point
  LegalPathA(round(max([Ay-(fx-Ax)*TanMaxPathAng;  MinY])-1):-1:MinY,fx)=0;%Empty all point in cloumn fx above maximal point
end;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function TopFilter() 
% Filter up top TopPathLimit% pixels in the vessel  
%Top filter delete paths (pixels) in the top fraction of the vessel and is useful for cases such as bottles jars and so on were the top contain corks and cover that can induce false recognition.
global TopPathLimit LegalPathA MaxY MinY MinX MaxX
 if TopPathLimit>0 
    LegalPathA(MinY:1:round((MinY)+TopPathLimit*(MaxY-MinY)) ,  MinX:1:MaxX)=0; %Every  point above the top TopPathLimit percent of the vessel will be remove from the path
 end;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function BottumFilter() 
% Filter up bottum BottumPathLimit% pixels in the vessel 
%Bottom filter ignore paths in the bottom fraction of the vessel and is useful for cases such as chemical glassware such as  separatory funnel and chromatography column where the bottom contain funnels and valves that can induce false recognition.
global BottumPathLimit LegalPathA MaxY MinY MinX MaxX
 if BottumPathLimit>0 
    LegalPathA(round((MaxY)-BottumPathLimit*(MaxY-MinY)):1:MaxY ,  MinX:1:MaxX)=0; %Every  point below the top BottumPathLimit percent of the vessel will be remove from the path
 end;
end