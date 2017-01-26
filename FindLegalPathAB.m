function FindLegalPathAB()
%{
Description
Find the legal region in the image in which a path starting at point A  and ending at point B can pass. It returns the binary image in the size of the examined image (I) were pixel in which the path can pass are marked 1 (figure 4 green region) and illegal regions in which the path don’t allow to pass marked 0. All parameters are passed from and to this function are global. Therefore, it has no direct input or output. For more details on the main principles of this function see section 4 of the paper.
Input (global)
Ax,Ay, Bx,By: Coordinates of endpoints of the path that is explored in this step. This coordinates refer to the pixels in the image in which the path start (Ax,Ay) and end (Bx,By).
%Ibor is the vessel contour (binary) 
%Ifill is the vessel interior(binary) 
Output (global)
LegalPathAB: Binary image in the size of the image examined (I) in which all legal pixels in which the paths starting from point A and ending at point B can pass marked 1 and the rest 0. 
%}

global LegalPathAB LegalPathA 
LegalPathAB=LegalPathA;% The legal Path in respect to A as already been find all 

%-------------------------Use various of filter to remove pixels from LegalPathAB according to various constaints---------------------------------------------------
AngleFilter();%Filter paths with high angels slops
%imshow((LegalPath+Ifill)/2); pause;
FloorPathFilter(); %Filter flat paths that propogate along the vessel bottum or top (main cause for false negative)
%imshow((LegalPath+Ifill)/2); pause;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function AngleFilter()
%Filter out all pixels  (C) for which the vector AC  have slope (tan) of more then TanMaxPathAng
global LegalPathAB TanMaxPathAng Ax Ay Bx By MaxY MinY
for fx=Ax:1:Bx% scan every colum between point A and B
  LegalPathAB(round(min([Ay+(fx-Ax)*TanMaxPathAng; By+(Bx-fx)*TanMaxPathAng; MaxY])+1):1:MaxY,fx)=0;%Empty all point in cloumn fx below minimal point
  LegalPathAB(round(max([Ay-(fx-Ax)*TanMaxPathAng; By-(Bx-fx)*TanMaxPathAng; MinY])-1):-1: MinY,fx)=0;%Empty all point in cloumn fx above maximal point
end;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function FloorPathFilter()
%Remove point on paths flat paths that go alone the bottum or top of the vessel 
%Demand that if the horizontal distance of a point from the start or and point is dx, then the vertical distance of this point from bouttm or top of the vessel will be minimum dx*C (c~0.2) or some thershold  
global Ibor LegalPathAB TanMaxPathAng Ax Ay Bx By Hight MaxY MinY MinDy MinDyD
for fx=Ax+1:1:Bx-1 % scan every colum between point A and B
    dx=min(fx-Ax  ,Bx-fx);% minimal horizontal distance  for point from start end point
    dy=floor(min(dx*MinDy,MinDyD));% minimal vertial distance for legal distace for point from to /bottum of of the vessel
    Ymax=round(min([Ay+(fx-Ax)*TanMaxPathAng+dy; By+(Bx-fx)*TanMaxPathAng+dy; Hight]));%max y for scan in this raw
    Ymin=round(max([Ay-(fx-Ax)*TanMaxPathAng-dy; By-(Bx-fx)*TanMaxPathAng-dy; 1    ])); %min y for scan    in this raw
 %..................................remove points in the raw which are two close to vessel bottum...........................................................................................................................................................   
    for fy=Ymin:1:Ymax
        if (Ibor(fy,fx)==1) LegalPathAB(max(fy-dy,MinY):min(fy+dy,MaxY),fx)=0;end; % if found vessel edge point in column f delete all point in range yy above or below this point
    end;
 %.............................................................................................................................................................................................   
end;
end
