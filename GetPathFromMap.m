function  [BstPathAB]=GetPathFromMap()
%{
Given the previos location map (PrvMapX,PrvMapY which give the previous location on the path for eache pixel)
find the path from B two A
And write it as binary image (BstPathAB) where all points in the path marked 1 

Input (global)
BackX, BackY: Matrix in size of the image examined (I) in which every cell contains coordinates of the previous pixel in the path from the start point A to this cell. This matrix allows you to track all paths leading from A in the image.

Ax,Ay, Bx,By: Coordinates of endpoints of the path that is explored in this step. This coordinates refer to the pixels in the image in which the path start (Ax,Ay) and end (Bx,By).
Input
BstPathAB: Binary image size of the image examined (I)  where the path between points A and B is marked with 1. 

%}
global BackX BackY Ax Ay Bx By
x=Bx;
y=By;
BstPathAB=zeros(size(BackX));%binary image  where all points in the path marked 1
BstPathAB(y,x)=1;
%----------------------------------------------------------------------
while (x~=Ax || y~=Ay)
   xx=x;
    x=BackX(y,x);
   y=BackY(y,xx);
   BstPathAB(y,x)=1;
  
   %imshow(BstPathAB);pause();
end;
%----------------------------------------------------------------------

end

